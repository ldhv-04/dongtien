import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/budgeting/category_budget_progress.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:dongtien/domain/ledger/posting_leg.dart';
import 'package:dongtien/domain/ledger/posting_matrix.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/reports_settings/presentation/providers/reports_settings_providers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int cashAccountId;
  late int categoryEatId; // Ăn uống (Expense Category)
  late int categoryMoveId; // Di chuyển (Expense Category)
  late int yearMonth;
  late int startOfMonthMs;
  late int endOfMonthMs;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    // Pre-warm reactive stream providers to prevent unpumped FutureProvider timeouts
    await container.read(accountsWithBalancesStreamProvider.future);
    await container.read(recentTransactionsStreamProvider.future);
    await container.read(settingsStreamProvider.future);

    final now = DateTime.now();
    yearMonth = now.year * 100 + now.month;
    startOfMonthMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    endOfMonthMs = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    // Create Cash asset account
    cashAccountId = await db.into(db.ledgerAccounts).insert(
          LedgerAccountsCompanion.insert(
            name: 'Tiền mặt',
            kind: 'ASSET_CASH',
            isLiquid: const drift.Value(true),
            createdAt: now.millisecondsSinceEpoch,
          ),
        );

    // Initial asset balance: 50.000.000 VND
    await db.ledgerDao.postTransactionCommand(
      PostTransactionCommand.openingAsset(
        assetAccountId: cashAccountId,
        amountVnd: 50000000,
        occurredAt: startOfMonthMs,
      ),
    );

    // Query seeded categories
    final allCats = await db.select(db.categories).get();
    categoryEatId = allCats.firstWhere((c) => c.name == 'Ăn uống').id;
    categoryMoveId = allCats.firstWhere((c) => c.name == 'Di chuyển').id;
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('M1 SQL Challenge 1: Zero Budgets & Zero Spending Edge Conditions', () {
    test('Zero budgets configured returns empty summary without error',
        () async {
      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);

      expect(summary.yearMonth, equals(yearMonth));
      expect(summary.categoryProgresses, isEmpty);
      expect(summary.totalLimitVnd.amount, equals(0));
      expect(summary.totalSpentVnd.amount, equals(0));
      expect(summary.totalRemainingVnd.amount, equals(0));
      expect(summary.overallSpentRatio, equals(0.0));
      expect(summary.exceededCount, equals(0));
      expect(summary.warningCount, equals(0));
    });

    test('Budgets configured with ZERO category spending evaluate cleanly',
        () async {
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: categoryEatId,
              yearMonth: yearMonth,
              limitVnd: 5000000,
              alertThresholdPct: const drift.Value(80),
            ),
          );
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: categoryMoveId,
              yearMonth: yearMonth,
              limitVnd: 2000000,
              alertThresholdPct: const drift.Value(90),
            ),
          );

      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);

      expect(summary.categoryProgresses.length, equals(2));

      final eatProgress = summary.categoryProgresses
          .firstWhere((p) => p.categoryId == categoryEatId);
      expect(eatProgress.categoryName, equals('Ăn uống'));
      expect(eatProgress.limitVnd.amount, equals(5000000));
      expect(eatProgress.spentVnd.amount, equals(0));
      expect(eatProgress.remainingVnd.amount, equals(5000000));
      expect(eatProgress.status, equals(BudgetStatus.normal));
      expect(eatProgress.isExceeded, isFalse);

      final moveProgress = summary.categoryProgresses
          .firstWhere((p) => p.categoryId == categoryMoveId);
      expect(moveProgress.categoryName, equals('Di chuyển'));
      expect(moveProgress.limitVnd.amount, equals(2000000));
      expect(moveProgress.spentVnd.amount, equals(0));
      expect(moveProgress.remainingVnd.amount, equals(2000000));

      expect(summary.totalLimitVnd.amount, equals(7000000));
      expect(summary.totalSpentVnd.amount, equals(0));
      expect(summary.totalRemainingVnd.amount, equals(7000000));
      expect(summary.overallSpentRatio, equals(0.0));

      // Reports summary with zero spending in period
      final reports = await container.read(reportsSummaryProvider.future);
      expect(reports.spendingReport.categories, isEmpty);
      expect(reports.spendingReport.grossExpense.amount, equals(0));
      expect(reports.spendingReport.refundCredits.amount, equals(0));
      expect(reports.spendingReport.netExpense.amount, equals(0));
      expect(reports.internalTransfersTotal.amount, equals(0));
    });
  });

  group('M1 SQL Challenge 2: Multiple Refunds Exceeding Gross Expense', () {
    test(
        'Refund credits greater than gross expense yield 0 spent in budget and net recovery in reports',
        () async {
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: categoryEatId,
              yearMonth: yearMonth,
              limitVnd: 3000000,
              alertThresholdPct: const drift.Value(80),
            ),
          );

      final txTime = startOfMonthMs + 100000;

      // 1. Post Gross Expense: 200.000 VND
      await db.ledgerDao.postTransaction(
        txType: 'EXPENSE',
        description: 'Bữa trưa',
        occurredAt: txTime,
        postings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 200000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 200000,
          ),
        ],
      );

      // 2. Post Refund 1: 150.000 VND
      await db.ledgerDao.postTransaction(
        txType: 'REFUND',
        description: 'Hoàn tiền 1',
        occurredAt: txTime + 1000,
        postings: [
          PostingLeg.debit(
            accountId: cashAccountId,
            amountVnd: 150000,
          ),
          PostingLeg.credit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 150000,
            categoryId: categoryEatId,
          ),
        ],
      );

      // 3. Post Refund 2: 100.000 VND (Total refunds = 250.000 VND > 200.000 VND)
      await db.ledgerDao.postTransaction(
        txType: 'REFUND',
        description: 'Hoàn tiền 2',
        occurredAt: txTime + 2000,
        postings: [
          PostingLeg.debit(
            accountId: cashAccountId,
            amountVnd: 100000,
          ),
          PostingLeg.credit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 100000,
            categoryId: categoryEatId,
          ),
        ],
      );

      // Verify in currentMonthlyBudgetSummaryProvider
      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      final progress = summary.categoryProgresses
          .firstWhere((p) => p.categoryId == categoryEatId);

      // Net expense is negative (-50.000), effective spent is clamped to 0
      expect(progress.spentVnd.amount, equals(0));
      expect(progress.remainingVnd.amount, equals(3000000));
      expect(progress.status, equals(BudgetStatus.normal));
      expect(summary.totalSpentVnd.amount, equals(0));

      // Verify in reportsSummaryProvider
      final reports = await container.read(reportsSummaryProvider.future);
      expect(reports.spendingReport.categories.length, equals(1));
      final catItem = reports.spendingReport.categories.first;
      expect(catItem.categoryId, equals(categoryEatId));
      expect(catItem.grossExpense.amount, equals(200000));
      expect(catItem.refundCredits.amount, equals(250000));
      expect(catItem.netExpense.amount, equals(-50000));
      expect(reports.spendingReport.grossExpense.amount, equals(200000));
      expect(reports.spendingReport.refundCredits.amount, equals(250000));
      expect(reports.spendingReport.netExpense.amount, equals(-50000));
      expect(reports.spendingReport.isNetRecovery, isTrue);
    });
  });

  group('M1 SQL Challenge 3: Voided & Superseded Audit Isolation', () {
    test(
        'REVERSAL, VOIDED, and SUPERSEDED records are strictly excluded from aggregates',
        () async {
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: categoryEatId,
              yearMonth: yearMonth,
              limitVnd: 5000000,
              alertThresholdPct: const drift.Value(80),
            ),
          );

      final txTime = startOfMonthMs + 50000;

      // 1. Post Tx 1: Expense 500.000 VND
      final tx1Id = await db.ledgerDao.postTransaction(
        txType: 'EXPENSE',
        description: 'Chi tiêu 1',
        occurredAt: txTime,
        postings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 500000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 500000,
          ),
        ],
      );

      // 2. Post Tx 2: Expense 700.000 VND
      final tx2Id = await db.ledgerDao.postTransaction(
        txType: 'EXPENSE',
        description: 'Chi tiêu 2',
        occurredAt: txTime + 1000,
        postings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 700000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 700000,
          ),
        ],
      );

      final sub =
          container.listen(currentMonthlyBudgetSummaryProvider, (_, __) {});

      // Verify before void/edit
      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      expect(summary.categoryProgresses.first.spentVnd.amount, equals(1200000));

      // 3. VOID Tx 1
      await db.ledgerDao.voidTransaction(tx1Id);
      await pumpEventQueue();

      // Verify after void: Tx 1 (500k) should be excluded, and its reversal also excluded
      // Remaining is only Tx 2 (700k)
      final afterVoid =
          container.read(currentMonthlyBudgetSummaryProvider).value!;
      expect(
          afterVoid.categoryProgresses.first.spentVnd.amount, equals(700000));

      // 4. EDIT Tx 2 to 900.000 VND
      await db.ledgerDao.editTransaction(
        originalTxId: tx2Id,
        txType: 'EXPENSE',
        description: 'Chi tiêu 2 (đã sửa)',
        occurredAt: txTime + 2000,
        newPostings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 900000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 900000,
          ),
        ],
      );
      await pumpEventQueue();

      // Verify after edit: Tx 2 is SUPERSEDED (excluded), Reversal is REVERSAL (excluded),
      // Replacement is POSTED (900k)
      final afterEdit =
          container.read(currentMonthlyBudgetSummaryProvider).value!;
      expect(
          afterEdit.categoryProgresses.first.spentVnd.amount, equals(900000));
      expect(afterEdit.categoryProgresses.first.remainingVnd.amount,
          equals(4100000));

      sub.close();

      // Check reportsSummaryProvider
      final reports = await container.refresh(reportsSummaryProvider.future);
      expect(reports.spendingReport.grossExpense.amount, equals(900000));
      expect(reports.spendingReport.refundCredits.amount, equals(0));
      expect(reports.spendingReport.netExpense.amount, equals(900000));
    });
  });

  group('M1 SQL Challenge 4: Exact Millisecond Month Boundary Partitioning',
      () {
    test(
        'Transactions at startOfMonthMs - 1 and startNextMonthMs are strictly excluded; startOfMonthMs and endOfMonthMs are strictly included',
        () async {
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: categoryEatId,
              yearMonth: yearMonth,
              limitVnd: 10000000,
              alertThresholdPct: const drift.Value(80),
            ),
          );

      final nextMonthMs =
          DateTime(DateTime.now().year, DateTime.now().month + 1, 1)
              .millisecondsSinceEpoch;

      // Tx A: Last millisecond of PREVIOUS month (startOfMonthMs - 1) -> EXCLUDED
      await db.ledgerDao.postTransaction(
        txType: 'EXPENSE',
        description: 'Tháng trước',
        occurredAt: startOfMonthMs - 1,
        postings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 111000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 111000,
          ),
        ],
      );

      // Tx B: EXACT First millisecond of CURRENT month (startOfMonthMs) -> INCLUDED
      await db.ledgerDao.postTransaction(
        txType: 'EXPENSE',
        description: 'Đầu tháng này',
        occurredAt: startOfMonthMs,
        postings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 222000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 222000,
          ),
        ],
      );

      // Tx C: EXACT Last millisecond of CURRENT month (endOfMonthMs) -> INCLUDED
      await db.ledgerDao.postTransaction(
        txType: 'EXPENSE',
        description: 'Cuối tháng này',
        occurredAt: endOfMonthMs,
        postings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 333000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 333000,
          ),
        ],
      );

      // Tx D: EXACT First millisecond of NEXT month (nextMonthMs) -> EXCLUDED
      await db.ledgerDao.postTransaction(
        txType: 'EXPENSE',
        description: 'Đầu tháng sau',
        occurredAt: nextMonthMs,
        postings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 444000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 444000,
          ),
        ],
      );

      // In currentMonthlyBudgetSummaryProvider:
      // Should contain EXACTLY Tx B (222.000) + Tx C (333.000) = 555.000 VND
      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      expect(summary.categoryProgresses.first.spentVnd.amount, equals(555000));
      expect(summary.categoryProgresses.first.remainingVnd.amount,
          equals(9445000));

      // In reportsSummaryProvider:
      // Should contain EXACTLY Tx B (222.000) + Tx C (333.000) = 555.000 VND
      final reports = await container.read(reportsSummaryProvider.future);
      expect(reports.spendingReport.grossExpense.amount, equals(555000));
      expect(reports.spendingReport.netExpense.amount, equals(555000));
    });
  });

  group('M1 SQL Challenge 5: Reactive Stream Updates Across Multi-Table Writes',
      () {
    test(
        'currentMonthlyBudgetSummaryProvider emits immediately on budget creation, expense write, refund write, and limit update',
        () async {
      final emissions = <MonthlyBudgetSummary>[];
      final subscription = container.listen(
        currentMonthlyBudgetSummaryProvider,
        (_, next) {
          next.whenData((s) => emissions.add(s));
        },
      );

      // 1. Initial emission: 0 budgets
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emissions.length, equals(1));
      expect(emissions.last.categoryProgresses, isEmpty);

      // 2. Insert Category Budget for categoryEatId
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: categoryEatId,
              yearMonth: yearMonth,
              limitVnd: 4000000,
              alertThresholdPct: const drift.Value(80),
            ),
          );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.categoryProgresses.length, equals(1));
      expect(emissions.last.categoryProgresses.first.limitVnd.amount,
          equals(4000000));
      expect(
          emissions.last.categoryProgresses.first.spentVnd.amount, equals(0));

      // 3. Post Expense of 1.000.000 VND
      await db.ledgerDao.postTransaction(
        txType: 'EXPENSE',
        description: 'Tiệc tối',
        occurredAt: startOfMonthMs + 1000,
        postings: [
          PostingLeg.debit(
            accountId: PostingMatrix.defaultExpenseAccountId,
            amountVnd: 1000000,
            categoryId: categoryEatId,
          ),
          PostingLeg.credit(
            accountId: cashAccountId,
            amountVnd: 1000000,
          ),
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emissions.last.categoryProgresses.first.spentVnd.amount,
          equals(1000000));
      expect(emissions.last.categoryProgresses.first.remainingVnd.amount,
          equals(3000000));

      // 4. Update Budget Limit from 4.000.000 to 6.000.000 VND
      await (db.update(db.categoryBudgets)
            ..where((b) =>
                b.categoryId.equals(categoryEatId) &
                b.yearMonth.equals(yearMonth)))
          .write(
        const CategoryBudgetsCompanion(limitVnd: drift.Value(6000000)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emissions.last.categoryProgresses.first.limitVnd.amount,
          equals(6000000));
      expect(emissions.last.categoryProgresses.first.spentVnd.amount,
          equals(1000000));
      expect(emissions.last.categoryProgresses.first.remainingVnd.amount,
          equals(5000000));

      subscription.close();
    });
  });
}
