import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/plans/presentation/providers/plans_providers.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openMemoryDb() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
    ),
  );
}

void main() {
  group('M2 R2: Plans CRUD Symmetry & Atomic Ledger Reversals', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = _openMemoryDb();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          ledgerDaoProvider.overrideWithValue(db.ledgerDao),
          envelopeDaoProvider.overrideWithValue(db.envelopeDao),
        ],
      );
      // Ensure settings and categories are ready
      await container.read(settingsStreamProvider.future);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('Category Budget CRUD: Upsert and Delete', () async {
      final controller = container.read(plansControllerProvider.notifier);
      final categories = await db.select(db.categories).get();
      final cat = categories.firstWhere((c) => c.name == 'Ăn uống');

      // 1. Create category budget
      await controller.upsertCategoryBudget(
        categoryId: cat.id,
        limitVnd: 5000000,
        alertThresholdPct: 85,
      );

      var budgets = await db.select(db.categoryBudgets).get();
      expect(budgets.length, equals(1));
      expect(budgets.first.categoryId, equals(cat.id));
      expect(budgets.first.limitVnd, equals(5000000));
      expect(budgets.first.alertThresholdPct, equals(85));

      // 2. Update category budget
      await controller.upsertCategoryBudget(
        categoryId: cat.id,
        limitVnd: 6000000,
        alertThresholdPct: 90,
      );

      budgets = await db.select(db.categoryBudgets).get();
      expect(budgets.length, equals(1));
      expect(budgets.first.limitVnd, equals(6000000));
      expect(budgets.first.alertThresholdPct, equals(90));

      // 3. Delete category budget
      await controller.deleteCategoryBudget(categoryId: cat.id);

      budgets = await db.select(db.categoryBudgets).get();
      expect(budgets, isEmpty);
    });

    test('Savings Goal Delete: Releases positive reserve and archives envelope',
        () async {
      final controller = container.read(plansControllerProvider.notifier);

      // 1. Seed liquid cash: 10.000.000 ₫
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 10000000,
          occurredAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // 2. Create goal envelope with 2.000.000 ₫ allocated
      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Mua xe mới',
              policy: 'PROTECTED',
              targetAmountVnd: const Value(50000000),
              targetDateMs: Value(DateTime(2027, 1, 1).millisecondsSinceEpoch),
              reservedBalanceVnd: const Value(2000000),
            ),
          );

      // Initial available to allocate: 10M - 2M = 8M
      var avail = await db.envelopeDao.getAvailableToAllocate(10000000);
      expect(avail, equals(8000000));

      // 3. Delete savings goal
      await controller.deleteSavingsGoal(envId);

      // Envelope should be archived, target null, reserve 0
      final env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.isArchived, isTrue);
      expect(env.targetAmountVnd, isNull);
      expect(env.reservedBalanceVnd, equals(0));

      // Available to allocate should be fully restored to 10M
      avail = await db.envelopeDao.getAvailableToAllocate(10000000);
      expect(avail, equals(10000000));

      // Verify envelope movement was RELEASE
      final movements = await (db.select(db.envelopeMovements)
            ..where((m) => m.sourceEnvelopeId.equals(envId)))
          .get();
      expect(
          movements.any(
              (m) => m.movementType == 'RELEASE' && m.amountVnd == 2000000),
          isTrue);
    });

    test(
        'Completed Obligation Delete: Atomically voids ledger transaction and restores liquid balance',
        () async {
      final controller = container.read(plansControllerProvider.notifier);

      // 1. Seed liquid cash: 10.000.000 ₫
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tài khoản ngân hàng',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 10000000,
          occurredAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final categories = await db.select(db.categories).get();
      final housingCat = categories.firstWhere((c) => c.name == 'Nhà cửa');

      // 2. Create bill and pay it
      final now = DateTime.now();
      final billId = await controller.createScheduledItem(
        kind: 'BILL',
        title: 'Tiền thuê trọ',
        amountVnd: 2500000,
        dueDate: DateTime(now.year, now.month, 10),
        categoryId: housingCat.id,
      );

      final txId =
          await controller.markScheduledItemPaid(scheduledItemId: billId);
      expect(txId, greaterThan(0));

      // Liquid balance after payment: 10M - 2.5M = 7.5M
      var liquid = await db.ledgerDao.getTotalLiquidAssets();
      expect(liquid, equals(7500000));

      // 3. Delete the completed scheduled obligation
      await controller.deleteScheduledItem(billId);

      // Verify row is deleted from scheduled_items
      final remainingItems = await (db.select(db.scheduledItems)
            ..where((s) => s.id.equals(billId)))
          .get();
      expect(remainingItems, isEmpty);

      // Verify original transaction is VOIDED
      final origTx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(txId)))
          .getSingle();
      expect(origTx.status, equals('VOIDED'));

      // Verify a REVERSAL transaction was created
      final reversals = await (db.select(db.journalTransactions)
            ..where((t) =>
                t.txType.equals('REVERSAL') & t.reversesTxId.equals(txId)))
          .get();
      expect(reversals.length, equals(1));
      expect(reversals.first.status, equals('POSTED'));

      // Verify liquid balance is restored to 10.000.000 ₫
      liquid = await db.ledgerDao.getTotalLiquidAssets();
      expect(liquid, equals(10000000));
    });

    test(
        'Completed Obligation Delete with Linked Envelope: Restores both liquid cash and envelope reserve',
        () async {
      final controller = container.read(plansControllerProvider.notifier);

      // 1. Seed liquid cash: 10.000.000 ₫
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 10000000,
          occurredAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // 2. Create envelope with 3.000.000 ₫
      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ Điện nước',
              policy: 'FLEXIBLE',
              reservedBalanceVnd: const Value(3000000),
            ),
          );

      // 3. Create bill of 1.000.000 ₫ linked to envelope
      final now = DateTime.now();
      final billId = await controller.createScheduledItem(
        kind: 'BILL',
        title: 'Tiền điện tháng 10',
        amountVnd: 1000000,
        dueDate: DateTime(now.year, now.month, 12),
        linkedEnvelopeId: envId,
      );

      // 4. Pay the bill
      final txId =
          await controller.markScheduledItemPaid(scheduledItemId: billId);
      expect(txId, greaterThan(0));

      // Liquid balance: 9.000.000 ₫
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(9000000));

      // Envelope balance: 3M - 1M = 2.000.000 ₫
      var env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(2000000));

      // 5. Delete the completed bill
      await controller.deleteScheduledItem(billId);

      // Liquid balance restored: 10.000.000 ₫
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(10000000));

      // Envelope reserve restored: 3.000.000 ₫
      env = await (db.select(db.envelopes)..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(3000000));

      // Verify envelope movement was REVERSAL
      final restoreMovements = await (db.select(db.envelopeMovements)
            ..where((m) =>
                m.destEnvelopeId.equals(envId) &
                m.movementType.equals('REVERSAL')))
          .get();
      expect(restoreMovements.length, equals(1));
      expect(restoreMovements.first.amountVnd, equals(1000000));
    });

    test(
        'Completed Obligation Edit: Atomically voids old tx and posts new tx with fresh idempotency key',
        () async {
      final controller = container.read(plansControllerProvider.notifier);

      // 1. Seed liquid cash: 20.000.000 ₫
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 20000000,
          occurredAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final categories = await db.select(db.categories).get();
      final housingCat = categories.firstWhere((c) => c.name == 'Nhà cửa');
      final shoppingCat = categories.firstWhere((c) => c.name == 'Mua sắm');

      // 2. Create bill for 3.000.000 ₫ (Housing) and pay it
      final now = DateTime.now();
      final billId = await controller.createScheduledItem(
        kind: 'BILL',
        title: 'Tiền đồ gia dụng',
        amountVnd: 3000000,
        dueDate: DateTime(now.year, now.month, 15),
        categoryId: housingCat.id,
      );

      final txId1 =
          await controller.markScheduledItemPaid(scheduledItemId: billId);
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(17000000));

      // 3. Edit completed bill: change amount to 5.000.000 ₫ and category to Mua sắm
      final originalItem = await (db.select(db.scheduledItems)
            ..where((s) => s.id.equals(billId)))
          .getSingle();

      await controller.updateScheduledItem(
        scheduledItemId: originalItem.id,
        kind: originalItem.kind,
        title: originalItem.title,
        amountVnd: 5000000,
        dueDate: DateTime.fromMillisecondsSinceEpoch(originalItem.dueDateMs),
        categoryId: shoppingCat.id,
        linkedEnvelopeId: originalItem.linkedEnvelopeId,
      );

      // Verify original tx is VOIDED
      final oldTx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(txId1)))
          .getSingle();
      expect(oldTx.status, equals('VOIDED'));

      // Verify new item state
      final itemAfter = await (db.select(db.scheduledItems)
            ..where((s) => s.id.equals(billId)))
          .getSingle();
      expect(itemAfter.amountVnd, equals(5000000));
      expect(itemAfter.categoryId, equals(shoppingCat.id));
      expect(itemAfter.paidTransactionId, isNotNull);
      expect(itemAfter.paidTransactionId, isNot(equals(txId1)));

      // Verify new transaction idempotency key contains 'rev_'
      final newTx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(itemAfter.paidTransactionId!)))
          .getSingle();
      expect(newTx.idempotencyKey, contains('_rev_'));

      // Verify liquid balance is 20M - 5M = 15.000.000 ₫
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(15000000));

      // Verify new debit posting is on Mua sắm (shoppingCat)
      final newPostings = await (db.select(db.journalPostings)
            ..where(
                (p) => p.transactionId.equals(itemAfter.paidTransactionId!)))
          .get();
      final debitPosting = newPostings.firstWhere((p) => p.debitVnd > 0);
      expect(debitPosting.categoryId, equals(shoppingCat.id));
      expect(debitPosting.debitVnd, equals(5000000));
    });
  });
}
