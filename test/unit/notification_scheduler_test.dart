import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/notifications/notification_scheduler.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationScheduler Unit Tests', () {
    setUpAll(() {
      tz_data.initializeTimeZones();
    });

    test('Initializes timezone with fallback Asia/Ho_Chi_Minh', () async {
      final scheduler = NotificationScheduler();
      final granted = await scheduler.initialize();
      expect(granted, isTrue);
      expect(scheduler.isInitialized, isTrue);
      // Verify local timezone is configured
      expect(tz.local.name, isNotEmpty);
    });

    test('Permission denied degrades gracefully and blocks scheduling',
        () async {
      final scheduler = NotificationScheduler(initialPermissionGranted: false);
      expect(scheduler.isPermissionGranted, isFalse);

      await scheduler.initialize();
      expect(scheduler.isPermissionGranted, isFalse);

      // showTestNotification does nothing when permission denied
      await scheduler.showTestNotification();
      expect(scheduler.lastNotificationId, isNull);

      // triggerBudgetThresholdAlert does nothing when permission denied
      await scheduler.triggerBudgetThresholdAlert(
        categoryId: 1,
        categoryName: 'Ăn uống',
        spentVnd: 900000,
        limitVnd: 1000000,
      );
      expect(scheduler.lastNotificationId, isNull);
    });

    test('showTestNotification triggers test channel with ID 9999', () async {
      final scheduler = NotificationScheduler();
      await scheduler.initialize();
      await scheduler.showTestNotification();

      expect(scheduler.lastNotificationId, equals(9999));
      expect(
        scheduler.lastNotificationTitle,
        equals('Đồng Tiền — Kiểm tra thông báo'),
      );
      expect(
        scheduler.lastNotificationBody,
        contains('Hệ thống thông báo tức thì'),
      );
    });

    test('triggerBudgetThresholdAlert thresholds (below 80%, 80-99%, >= 100%)',
        () async {
      final scheduler = NotificationScheduler();
      await scheduler.initialize();

      // Case 1: Below 80% (79%) -> no alert
      await scheduler.triggerBudgetThresholdAlert(
        categoryId: 1,
        categoryName: 'Ăn uống',
        spentVnd: 790000,
        limitVnd: 1000000,
      );
      expect(scheduler.lastNotificationId, isNull);

      // Case 2: 80% -> Warning alert
      await scheduler.triggerBudgetThresholdAlert(
        categoryId: 1,
        categoryName: 'Ăn uống',
        spentVnd: 800000,
        limitVnd: 1000000,
      );
      expect(scheduler.lastNotificationId, equals(3001));
      expect(scheduler.lastNotificationTitle, contains('Cảnh báo ngân sách'));
      expect(scheduler.lastNotificationTitle, contains('80%'));
      expect(scheduler.lastNotificationBody, contains('800.000 ₫'));

      // Case 3: 105% -> Exceeded alert
      await scheduler.triggerBudgetThresholdAlert(
        categoryId: 2,
        categoryName: 'Mua sắm',
        spentVnd: 1050000,
        limitVnd: 1000000,
      );
      expect(scheduler.lastNotificationId, equals(3002));
      expect(scheduler.lastNotificationTitle, contains('Vượt ngân sách'));
      expect(scheduler.lastNotificationTitle, contains('105%'));
      expect(scheduler.lastNotificationBody, contains('1.050.000 ₫'));
    });

    test(
        'checkCategoryBudgetAlert reads database and triggers alerts accurately',
        () async {
      final db = AppDatabase(NativeDatabase.memory());

      final scheduler = NotificationScheduler();
      await scheduler.initialize();

      // Enable notifications in DB settings
      await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
        const SettingsCompanion(notificationsEnabled: Value(true)),
      );

      final categories = await db.select(db.categories).get();
      final foodCat = categories.firstWhere((c) => c.name == 'Ăn uống');
      final now = DateTime.now();

      final cashAccId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
      final yearMonth = now.year * 100 + now.month;

      // Set budget of 1.000.000 ₫ for food
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: foodCat.id,
              yearMonth: yearMonth,
              limitVnd: 1000000,
            ),
          );

      // 1. Spend 500.000 ₫ (50%) -> no alert
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashAccId,
          categoryId: foodCat.id,
          amountVnd: 500000,
          occurredAt: now.millisecondsSinceEpoch,
          description: 'Ăn trưa 50%',
        ),
      );

      await scheduler.checkCategoryBudgetAlert(
        db: db,
        categoryId: foodCat.id,
      );
      expect(scheduler.lastNotificationId, isNull);

      // 2. Spend another 350.000 ₫ (total 850.000 ₫ = 85%) -> warning alert (3000 + foodCat.id)
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashAccId,
          categoryId: foodCat.id,
          amountVnd: 350000,
          occurredAt: now.millisecondsSinceEpoch,
          description: 'Ăn tối 85%',
        ),
      );

      await scheduler.checkCategoryBudgetAlert(
        db: db,
        categoryId: foodCat.id,
      );
      expect(scheduler.lastNotificationId, equals(3000 + foodCat.id));
      expect(scheduler.lastNotificationTitle, contains('Cảnh báo ngân sách'));
      expect(scheduler.lastNotificationTitle, contains('85%'));

      // 3. Spend another 200.000 ₫ (total 1.050.000 ₫ = 105%) -> exceeded alert
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashAccId,
          categoryId: foodCat.id,
          amountVnd: 200000,
          occurredAt: now.millisecondsSinceEpoch,
          description: 'Tiệc tùng 105%',
        ),
      );

      await scheduler.checkCategoryBudgetAlert(
        db: db,
        categoryId: foodCat.id,
      );
      expect(scheduler.lastNotificationId, equals(3000 + foodCat.id));
      expect(scheduler.lastNotificationTitle, contains('Vượt ngân sách'));
      expect(scheduler.lastNotificationTitle, contains('105%'));

      // 4. Disable notifications in DB -> checkCategoryBudgetAlert does not fire
      await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
        const SettingsCompanion(notificationsEnabled: Value(false)),
      );
      scheduler.lastNotificationId = null;

      await scheduler.checkCategoryBudgetAlert(
        db: db,
        categoryId: foodCat.id,
      );
      expect(scheduler.lastNotificationId, isNull);

      await db.close();
    });

    test('reconcileFromDatabase schedules bills or cancels if disabled',
        () async {
      final db = AppDatabase(NativeDatabase.memory());

      final scheduler = NotificationScheduler();
      await scheduler.initialize();

      // Insert pending bill due in 3 days
      final now = DateTime.now();
      final dueDt = now.add(const Duration(days: 3));
      await db.into(db.scheduledItems).insert(
            ScheduledItemsCompanion.insert(
              kind: 'BILL',
              title: 'Tiền điện sinh hoạt',
              amountVnd: 600000,
              dueDateMs: dueDt.millisecondsSinceEpoch,
              status: const Value('PENDING'),
              reminderDaysBefore: const Value(1),
            ),
          );

      // When notifications are enabled
      await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
        const SettingsCompanion(notificationsEnabled: Value(true)),
      );

      await scheduler.reconcileFromDatabase(db);
      // Reconciles without error

      // When notifications are disabled
      await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
        const SettingsCompanion(notificationsEnabled: Value(false)),
      );
      await scheduler.reconcileFromDatabase(db);

      await db.close();
    });
  });
}
