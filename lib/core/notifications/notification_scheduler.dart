import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/budgeting/billing_cycle_calculator.dart';
import '../database/app_database.dart';
import '../money/vnd_formatter.dart';

/// Riverpod provider for the shared [NotificationScheduler] instance.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler();
});

/// Compliant Android 12-15+ local reminder scheduler using `inexactAllowWhileIdle`.
/// Degrades gracefully without error when `POST_NOTIFICATIONS` is denied or unavailable.
class NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _permissionGranted = true;

  // Observability properties for verification and diagnostics
  int? lastNotificationId;
  String? lastNotificationTitle;
  String? lastNotificationBody;

  NotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    bool initialPermissionGranted = true,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _permissionGranted = initialPermissionGranted;

  bool get isPermissionGranted => _permissionGranted;
  bool get isInitialized => _initialized;

  /// Explicitly sets permission state (used when permission is denied by OS or in Scenario 15 tests).
  void setPermissionGranted(bool granted) {
    _permissionGranted = granted;
  }

  Future<bool> initialize() async {
    if (_initialized) return _permissionGranted;
    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(seconds: 1));
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {
        // Graceful fallback to default/UTC
      }
    }

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);
    } catch (_) {
      // Degrades gracefully on desktop/test environments
    }
    _initialized = true;

    // Request Android 13/14+ runtime notification permission
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin
            .requestNotificationsPermission()
            .timeout(const Duration(seconds: 1));
        if (granted != null) {
          _permissionGranted = granted;
        }
      }
    } catch (_) {
      // Degrades gracefully on desktop/test environments
    }

    return _permissionGranted;
  }

  /// Cancels all scheduled and active notifications.
  Future<void> cancelAll() async {
    try {
      if (_initialized) {
        await _plugin.cancelAll();
      }
    } catch (_) {}
  }

  /// Reconciles settings and pending bills from the database and updates schedules.
  Future<void> reconcileFromDatabase(AppDatabase db) async {
    try {
      final settings = await (db.select(db.settings)
            ..where((s) => s.id.equals(1)))
          .getSingleOrNull();
      if (settings == null) return;
      if (!settings.notificationsEnabled || !_permissionGranted) {
        await cancelAll();
        return;
      }
      final pendingItems = await (db.select(db.scheduledItems)
            ..where((s) => s.status.equals('PENDING') & s.kind.equals('BILL')))
          .get();
      await reconcileAndSchedule(
        settings: settings,
        pendingItems: pendingItems,
      );
    } catch (_) {}
  }

  /// Reconciles and reschedules daily reminders and upcoming bill reminders.
  /// Never throws even if `POST_NOTIFICATIONS` is denied.
  Future<void> reconcileAndSchedule({
    required Setting settings,
    required List<ScheduledItem> pendingItems,
  }) async {
    if (!settings.notificationsEnabled || !_permissionGranted) {
      await cancelAll();
      return;
    }

    try {
      if (!_initialized) {
        await initialize();
      }
      if (!_initialized) return;

      await _plugin.cancelAll();

      // 1. Schedule daily summary reminder using inexactAllowWhileIdle
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDaily = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        settings.dailyReminderHour,
        settings.dailyReminderMinute,
      );
      if (scheduledDaily.isBefore(now)) {
        scheduledDaily = scheduledDaily.add(const Duration(days: 1));
      }

      const dailyDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'dongtien_daily_summary',
          'Nhắc nhở hàng ngày',
          channelDescription: 'Nhắc nhở ghi chép chi tiêu hàng ngày',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      await _plugin.zonedSchedule(
        1000,
        'Đồng Tiền — Tổng kết hôm nay',
        'Hãy kiểm tra số dư Safe-to-Spend và ghi nhận chi tiêu trong ngày.',
        scheduledDaily,
        dailyDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 2. Schedule upcoming bill reminders
      const billDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'dongtien_obligations',
          'Hoá đơn & Nghĩa vụ tài chính',
          channelDescription: 'Nhắc nhở hoá đơn sắp đến hạn',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      for (final item in pendingItems) {
        if (item.kind != 'BILL' || item.status != 'PENDING') continue;
        final dueDt = DateTime.fromMillisecondsSinceEpoch(item.dueDateMs);
        final remindDt =
            dueDt.subtract(Duration(days: item.reminderDaysBefore));
        final tzRemind = tz.TZDateTime.from(
          DateTime(remindDt.year, remindDt.month, remindDt.day, 9, 0),
          tz.local,
        );
        if (tzRemind.isAfter(now)) {
          await _plugin.zonedSchedule(
            2000 + item.id,
            'Hoá đơn sắp đến hạn: ${item.title}',
            'Số tiền: ${VndFormatter.format(item.amountVnd)}',
            tzRemind,
            billDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (_) {
      // Never block financial operations if OS notification scheduling fails
    }
  }

  /// Displays an immediate high-priority on-screen test notification banner.
  Future<void> showTestNotification() async {
    if (!_permissionGranted) return;
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized || !_permissionGranted) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'dongtien_test_channel',
        'Thông báo kiểm tra',
        channelDescription: 'Kênh kiểm tra thông báo tức thì trên thiết bị',
        importance: Importance.max,
        priority: Priority.max,
      );
      const details = NotificationDetails(android: androidDetails);
      const id = 9999;
      const title = 'Đồng Tiền — Kiểm tra thông báo';
      const body =
          'Hệ thống thông báo tức thì hoạt động bình thường trên thiết bị!';

      lastNotificationId = id;
      lastNotificationTitle = title;
      lastNotificationBody = body;

      await _plugin.show(
        id,
        title,
        body,
        details,
      );
    } catch (_) {}
  }

  /// Checks monthly net spending for a category against its budget and triggers alerts if >= 80% or >= 100%.
  /// Uses single-quoted 'POSTED' and 'REVERSAL' in SQLite queries.
  Future<void> checkCategoryBudgetAlert({
    required AppDatabase db,
    required int categoryId,
  }) async {
    try {
      final settings = await (db.select(db.settings)
            ..where((s) => s.id.equals(1)))
          .getSingleOrNull();
      if (settings == null ||
          !settings.notificationsEnabled ||
          !_permissionGranted) {
        return;
      }

      final category = await (db.select(db.categories)
            ..where((c) => c.id.equals(categoryId)))
          .getSingleOrNull();
      if (category == null) return;

      final now = DateTime.now();
      final periodStartDay = (settings.periodStartDay).clamp(1, 28);
      final cycle = BillingCycleCalculator.calculate(now, periodStartDay);
      final activeCycleYearMonth = cycle.yearMonth;
      final calendarYearMonth = now.year * 100 + now.month;

      var budget = await (db.select(db.categoryBudgets)
            ..where((b) =>
                b.categoryId.equals(categoryId) &
                b.yearMonth.equals(activeCycleYearMonth)))
          .getSingleOrNull();
      if (budget == null && activeCycleYearMonth != calendarYearMonth) {
        budget = await (db.select(db.categoryBudgets)
              ..where((b) =>
                  b.categoryId.equals(categoryId) &
                  b.yearMonth.equals(calendarYearMonth)))
            .getSingleOrNull();
      }
      if (budget == null || budget.limitVnd <= 0) return;

      final startMs = cycle.cycleStart.millisecondsSinceEpoch;
      final endMs = cycle.cycleEndInclusive.millisecondsSinceEpoch;

      final rows = await db.customSelect(
        '''
        SELECT COALESCE(SUM(p.debit_vnd), 0) - COALESCE(SUM(p.credit_vnd), 0) AS net_spent
        FROM journal_postings p
        JOIN journal_transactions t ON p.transaction_id = t.id
        WHERE p.category_id = ?
          AND t.occurred_at >= ? AND t.occurred_at <= ?
          AND t.status = 'POSTED' AND t.tx_type != 'REVERSAL'
        ''',
        variables: [
          Variable.withInt(categoryId),
          Variable.withInt(startMs),
          Variable.withInt(endMs),
        ],
        readsFrom: {db.journalPostings, db.journalTransactions},
      ).get();

      if (rows.isEmpty) return;
      final netSpent = rows.first.read<int>('net_spent');
      if (netSpent < (budget.limitVnd * 80) ~/ 100) return;

      await triggerBudgetThresholdAlert(
        categoryId: categoryId,
        categoryName: category.name,
        spentVnd: netSpent,
        limitVnd: budget.limitVnd,
      );
    } catch (_) {}
  }

  /// Triggers an immediate budget alert when a category crosses 80% or 100%.
  Future<void> triggerBudgetThresholdAlert({
    required int categoryId,
    required String categoryName,
    required int spentVnd,
    required int limitVnd,
  }) async {
    if (!_permissionGranted || limitVnd <= 0) return;
    final pct = (spentVnd * 100) ~/ limitVnd;
    if (pct < 80) return;

    try {
      if (!_initialized) {
        await initialize();
      }
      if (!_initialized || !_permissionGranted) return;
      const alertDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'dongtien_budget_alerts',
          'Cảnh báo ngân sách',
          channelDescription: 'Cảnh báo vượt ngưỡng 80% hoặc 100% ngân sách',
          importance: Importance.max,
          priority: Priority.max,
        ),
      );
      final title = pct >= 100
          ? 'Vượt ngân sách danh mục $categoryName ($pct%)'
          : 'Cảnh báo ngân sách $categoryName ($pct%)';
      final body =
          'Đã chi ${VndFormatter.format(spentVnd)} / ${VndFormatter.format(limitVnd)}';

      final id = 3000 + categoryId;
      lastNotificationId = id;
      lastNotificationTitle = title;
      lastNotificationBody = body;

      await _plugin.show(
        id,
        title,
        body,
        alertDetails,
      );
    } catch (_) {}
  }
}
