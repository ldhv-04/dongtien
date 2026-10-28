import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../database/app_database.dart';
import '../money/vnd_formatter.dart';

/// Compliant Android 12-15+ local reminder scheduler using `inexactAllowWhileIdle`.
/// Degrades gracefully without error when `POST_NOTIFICATIONS` is denied or unavailable.
class NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _permissionGranted = true;

  NotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    bool initialPermissionGranted = true,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _permissionGranted = initialPermissionGranted;

  bool get isPermissionGranted => _permissionGranted;

  /// Explicitly sets permission state (used when permission is denied by OS or in Scenario 15 tests).
  void setPermissionGranted(bool granted) {
    _permissionGranted = granted;
  }

  Future<bool> initialize() async {
    if (_initialized) return _permissionGranted;
    try {
      tz_data.initializeTimeZones();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // Graceful degradation on desktop/test hosts or when permission denied
      _initialized = false;
    }
    return _permissionGranted;
  }

  /// Reconciles and reschedules daily reminders and upcoming bill reminders.
  /// Never throws even if `POST_NOTIFICATIONS` is denied.
  Future<void> reconcileAndSchedule({
    required Setting settings,
    required List<ScheduledItem> pendingItems,
  }) async {
    if (!settings.notificationsEnabled || !_permissionGranted) {
      try {
        if (_initialized) {
          await _plugin.cancelAll();
        }
      } catch (_) {}
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
      if (!_initialized) return;
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

      await _plugin.show(
        3000 + categoryId,
        title,
        body,
        alertDetails,
      );
    } catch (_) {}
  }
}
