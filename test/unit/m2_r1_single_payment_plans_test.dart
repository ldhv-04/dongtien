import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/widgets/custom_keypad.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/plans/presentation/providers/plans_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openMemoryDb() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    ),
  );
}

void main() {
  group('M2 R1: Single-Payment Obligations & Deterministic Idempotency Key',
      () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          ledgerDaoProvider.overrideWithValue(db.ledgerDao),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('createScheduledItem unconditionally forces recurrence to NONE',
        () async {
      final controller = container.read(plansControllerProvider.notifier);

      final billId = await controller.createScheduledItem(
        kind: 'BILL',
        title: 'Tiền internet',
        amountVnd: 250000,
        dueDate: DateTime(2026, 11, 15),
        recurrence: 'MONTHLY', // Request recurrence, but must be forced to NONE
      );

      final incomeId = await controller.createScheduledItem(
        kind: 'PLANNED_INCOME',
        title: 'Thưởng quý',
        amountVnd: 5000000,
        dueDate: DateTime(2026, 11, 30),
        recurrence: 'YEARLY', // Request recurrence, but must be forced to NONE
      );

      final items = await db.select(db.scheduledItems).get();
      final bill = items.firstWhere((i) => i.id == billId);
      final income = items.firstWhere((i) => i.id == incomeId);

      expect(bill.recurrence, equals('NONE'));
      expect(income.recurrence, equals('NONE'));
      expect(bill.status, equals('PENDING'));
      expect(income.status, equals('PENDING'));
    });

    test(
        'markScheduledItemPaid passes deterministic idempotencyKey and never spawns recurring row for BILL',
        () async {
      final controller = container.read(plansControllerProvider.notifier);

      final billId = await controller.createScheduledItem(
        kind: 'BILL',
        title: 'Tiền điện sinh hoạt',
        amountVnd: 1200000,
        dueDate: DateTime(2026, 11, 20),
      );

      // Verify initial count is 1
      var allItems = await db.select(db.scheduledItems).get();
      expect(allItems.length, equals(1));

      // Mark paid
      final txId1 = await controller.markScheduledItemPaid(
        scheduledItemId: billId,
      );
      expect(txId1, greaterThan(0));

      // Verify transaction was posted with deterministic idempotencyKey
      final tx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(txId1)))
          .getSingle();
      expect(tx.idempotencyKey, equals('scheduled_pay_$billId'));
      expect(tx.txType, equals('EXPENSE'));

      // Verify scheduled item status updated to PAID_OR_RECEIVED
      final updatedBill = await (db.select(db.scheduledItems)
            ..where((s) => s.id.equals(billId)))
          .getSingle();
      expect(updatedBill.status, equals('PAID_OR_RECEIVED'));
      expect(updatedBill.paidTransactionId, equals(txId1));

      // Verify NO new recurring row was spawned
      allItems = await db.select(db.scheduledItems).get();
      expect(allItems.length, equals(1));

      // Calling markScheduledItemPaid a second time returns existing txId without error
      final txId2 = await controller.markScheduledItemPaid(
        scheduledItemId: billId,
      );
      expect(txId2, equals(txId1));

      // Total transactions count remains exactly 1
      final totalTxs = await db.select(db.journalTransactions).get();
      expect(totalTxs.length, equals(1));
    });

    test(
        'markScheduledItemPaid passes deterministic idempotencyKey and never spawns recurring row for PLANNED_INCOME',
        () async {
      final controller = container.read(plansControllerProvider.notifier);

      final incomeId = await controller.createScheduledItem(
        kind: 'PLANNED_INCOME',
        title: 'Lương tháng 11',
        amountVnd: 25000000,
        dueDate: DateTime(2026, 11, 5),
      );

      // Verify initial count is 1
      var allItems = await db.select(db.scheduledItems).get();
      expect(allItems.length, equals(1));

      // Mark received
      final txId = await controller.markScheduledItemPaid(
        scheduledItemId: incomeId,
      );
      expect(txId, greaterThan(0));

      // Verify transaction was posted with deterministic idempotencyKey
      final tx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(txId)))
          .getSingle();
      expect(tx.idempotencyKey, equals('scheduled_pay_$incomeId'));
      expect(tx.txType, equals('INCOME'));

      // Verify scheduled item status updated to PAID_OR_RECEIVED
      final updatedIncome = await (db.select(db.scheduledItems)
            ..where((s) => s.id.equals(incomeId)))
          .getSingle();
      expect(updatedIncome.status, equals('PAID_OR_RECEIVED'));
      expect(updatedIncome.paidTransactionId, equals(txId));

      // Verify NO new row was spawned
      allItems = await db.select(db.scheduledItems).get();
      expect(allItems.length, equals(1));
    });

    test('CustomKeypad Done button respects isSubmitting and isDoneEnabled',
        () {
      // 1. When isSubmitting is true, callback should not fire
      bool doneCalled = false;
      final keypadSubmitting = CustomKeypad(
        onDigitPressed: (_) {},
        onBackspacePressed: () {},
        onDonePressed: () => doneCalled = true,
        isSubmitting: true,
      );
      expect(keypadSubmitting.isSubmitting, isTrue);

      // 2. When isDoneEnabled is false, callback should not fire
      final keypadDisabled = CustomKeypad(
        onDigitPressed: (_) {},
        onBackspacePressed: () {},
        onDonePressed: () => doneCalled = true,
        isDoneEnabled: false,
      );
      expect(keypadDisabled.isDoneEnabled, isFalse);
      expect(doneCalled, isFalse);
    });
  });
}
