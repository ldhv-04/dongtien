import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/plans/presentation/providers/plans_providers.dart';
import 'package:drift/drift.dart';
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
  group('R1: Scheduled Obligations Category Selection & Isolation', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          ledgerDaoProvider.overrideWithValue(db.ledgerDao),
          envelopeDaoProvider.overrideWithValue(db.envelopeDao),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'Paying Tiền nhà (3.500.000 ₫) under Nhà cửa leaves Ăn uống budget at 0 ₫ spent and Ăn uống envelope untouched',
      () async {
        // 1. Seed initial liquid cash: 10.000.000 ₫ in Tiền mặt
        final cashAccountId = await db.into(db.ledgerAccounts).insert(
              LedgerAccountsCompanion.insert(
                name: 'Tiền mặt',
                kind: 'ASSET_CASH',
                isLiquid: const Value(true),
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
        await db.ledgerDao.postTransactionCommand(
          PostTransactionCommand.openingAsset(
            assetAccountId: cashAccountId,
            amountVnd: 10000000,
            occurredAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        // 2. Fetch categories
        final categories = await db.select(db.categories).get();
        final foodCat = categories.firstWhere((c) => c.name == 'Ăn uống');
        final housingCat = categories.firstWhere((c) => c.name == 'Nhà cửa');
        final utilitiesCat =
            categories.firstWhere((c) => c.name == 'Hoá đơn & Tiện ích');

        // 3. Set up 'Ăn uống' Category Budget for 3.000.000 ₫
        final controller = container.read(plansControllerProvider.notifier);
        await controller.upsertCategoryBudget(
          categoryId: foodCat.id,
          limitVnd: 3000000,
        );

        // 4. Create an 'Ăn uống' virtual fund envelope with 3.000.000 ₫ reserved
        final foodEnvelopeId = await db.into(db.envelopes).insert(
              EnvelopesCompanion.insert(
                name: 'Quỹ Ăn uống',
                policy: 'FLEXIBLE',
                reservedBalanceVnd: const Value(3000000),
              ),
            );

        // 5. Create scheduled bill for 'Tiền nhà' (3.500.000 ₫) under 'Nhà cửa'
        final now = DateTime.now();
        final billId = await controller.createScheduledItem(
          kind: 'BILL',
          title: 'Tiền nhà tháng 11',
          amountVnd: 3500000,
          dueDate: DateTime(now.year, now.month, 15),
          categoryId: housingCat.id,
          linkedEnvelopeId: null, // Not linked to any envelope
        );

        // 6. Pay the bill
        final txId =
            await controller.markScheduledItemPaid(scheduledItemId: billId);
        expect(txId, greaterThan(0));

        // 7. Verify ledger postings: Debit is on Nhà cửa, NOT Ăn uống
        final postings = await (db.select(db.journalPostings)
              ..where((p) => p.transactionId.equals(txId)))
            .get();
        final debitPosting = postings.firstWhere((p) => p.debitVnd > 0);
        expect(debitPosting.categoryId, equals(housingCat.id));
        expect(debitPosting.debitVnd, equals(3500000));

        // 8. Verify Ăn uống Category Budget is 0 ₫ spent
        await container.read(settingsStreamProvider.future);
        final budgetSummary =
            await container.read(currentMonthlyBudgetSummaryProvider.future);
        final foodBudget = budgetSummary.categoryProgresses
            .firstWhere((i) => i.categoryId == foodCat.id);
        expect(foodBudget.spentVnd.amount, equals(0));
        expect(foodBudget.remainingVnd.amount, equals(3000000));
        expect(foodBudget.isExceeded, isFalse);

        // 9. Verify Ăn uống Envelope balance is untouched (3.000.000 ₫)
        final foodEnv = await (db.select(db.envelopes)
              ..where((e) => e.id.equals(foodEnvelopeId)))
            .getSingle();
        expect(foodEnv.reservedBalanceVnd, equals(3000000));

        // 10. Verify legacy fallback: bill with categoryId == null defaults to Hoá đơn & Tiện ích
        final legacyBillId = await controller.createScheduledItem(
          kind: 'BILL',
          title: 'Hoá đơn internet cũ',
          amountVnd: 250000,
          dueDate: DateTime(now.year, now.month, 20),
          categoryId: null,
        );
        final legacyTxId = await controller.markScheduledItemPaid(
            scheduledItemId: legacyBillId);
        final legacyPostings = await (db.select(db.journalPostings)
              ..where((p) => p.transactionId.equals(legacyTxId)))
            .get();
        final legacyDebit = legacyPostings.firstWhere((p) => p.debitVnd > 0);
        expect(legacyDebit.categoryId, equals(utilitiesCat.id));
        expect(legacyDebit.categoryId, isNot(equals(foodCat.id)));

        // Food budget spent still exactly 0 ₫
        final budgetSummaryAfterLegacy =
            await container.read(currentMonthlyBudgetSummaryProvider.future);
        final foodBudgetAfter = budgetSummaryAfterLegacy.categoryProgresses
            .firstWhere((i) => i.categoryId == foodCat.id);
        expect(foodBudgetAfter.spentVnd.amount, equals(0));
      },
    );

    test(
        'Receiving PLANNED_INCOME defaults to Lương category and increases cash',
        () async {
      await container.read(settingsStreamProvider.future);
      final categories = await db.select(db.categories).get();
      final salaryCat = categories.firstWhere((c) => c.name == 'Lương');
      final foodCat = categories.firstWhere((c) => c.name == 'Ăn uống');

      final controller = container.read(plansControllerProvider.notifier);
      final now = DateTime.now();

      final incomeId = await controller.createScheduledItem(
        kind: 'PLANNED_INCOME',
        title: 'Lương tháng này',
        amountVnd: 15000000,
        dueDate: DateTime(now.year, now.month, 5),
        categoryId: null, // null defaults to Lương
      );

      final initialLiquid = await db.ledgerDao.getTotalLiquidAssets();
      final txId =
          await controller.markScheduledItemPaid(scheduledItemId: incomeId);
      expect(txId, greaterThan(0));

      final finalLiquid = await db.ledgerDao.getTotalLiquidAssets();
      expect(finalLiquid - initialLiquid, equals(15000000));

      // Verify postings
      final postings = await (db.select(db.journalPostings)
            ..where((p) => p.transactionId.equals(txId)))
          .get();
      final creditPosting = postings.firstWhere((p) => p.creditVnd > 0);
      expect(creditPosting.categoryId, equals(salaryCat.id));
      expect(creditPosting.categoryId, isNot(equals(foodCat.id)));
    });
  });
}
