import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/budgeting/category_budget_progress.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/reports_settings/presentation/providers/reports_settings_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Adversarial Query Optimization & Execution Plan Checks', () {
    test('currentMonthlyBudgetSummary query utilizes SQLite indexes', () async {
      final now = DateTime.now();
      final yearMonth = now.year * 100 + now.month;
      final startMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final endMs = DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch;

      final planRows = await db.customSelect(
        '''
        EXPLAIN QUERY PLAN
        SELECT 
          b.category_id,
          c.name AS category_name,
          b.year_month,
          b.limit_vnd,
          b.alert_threshold_pct,
          COALESCE(spent.gross_expense, 0) AS gross_expense,
          COALESCE(spent.refund_credits, 0) AS refund_credits
        FROM category_budgets b
        JOIN categories c ON b.category_id = c.id
        LEFT JOIN (
          SELECT 
            p.category_id,
            SUM(p.debit_vnd) AS gross_expense,
            SUM(p.credit_vnd) AS refund_credits
          FROM journal_postings p
          JOIN journal_transactions t ON p.transaction_id = t.id
          WHERE t.occurred_at >= ? 
            AND t.occurred_at < ? 
            AND t.status = 'POSTED' 
            AND t.tx_type != 'REVERSAL'
            AND p.category_id IS NOT NULL
          GROUP BY p.category_id
        ) spent ON b.category_id = spent.category_id
        WHERE b.year_month = ?
        ORDER BY b.category_id ASC;
        ''',
        variables: [
          Variable.withInt(startMs),
          Variable.withInt(endMs),
          Variable.withInt(yearMonth),
        ],
      ).get();

      final planText =
          planRows.map((r) => r.data['detail'].toString()).join('\n');
      expect(
        planText.contains('idx_tx_occurred_at') ||
            planText.contains('idx_tx_status_type') ||
            planText.contains('USING INDEX'),
        isTrue,
        reason: 'Subquery must use SQLite index on transactions: $planText',
      );
      expect(
        planText.contains('idx_postings_tx') ||
            planText.contains('USING INDEX idx_postings_'),
        isTrue,
        reason: 'Postings must join using indexed foreign key: $planText',
      );
    });

    test(
        'reportsSummaryProvider queries utilize indexes without full-table scans',
        () async {
      final now = DateTime.now();
      final startMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final endMs = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999)
          .millisecondsSinceEpoch;
      final dateVars = [Variable.withInt(startMs), Variable.withInt(endMs)];

      // Query 1: Income
      final plan1 = await db.customSelect(
        '''
        EXPLAIN QUERY PLAN
        SELECT COALESCE(SUM(p.credit_vnd - p.debit_vnd), 0) AS total_income
        FROM journal_postings p
        JOIN journal_transactions t ON p.transaction_id = t.id
        JOIN ledger_accounts a ON p.account_id = a.id
        WHERE t.status = 'POSTED'
          AND t.tx_type = 'INCOME'
          AND t.occurred_at >= ? AND t.occurred_at <= ?
          AND a.kind = 'INCOME'
        ''',
        variables: dateVars,
      ).get();
      final planText1 =
          plan1.map((r) => r.data['detail'].toString()).join('\n');
      expect(
        planText1.contains('idx_tx_occurred_at') ||
            planText1.contains('idx_tx_status_type') ||
            planText1.contains('USING INDEX'),
        isTrue,
        reason: 'Income query must use index on transactions: $planText1',
      );

      // Query 2: Transfers
      final plan2 = await db.customSelect(
        '''
        EXPLAIN QUERY PLAN
        SELECT COALESCE(SUM(p.debit_vnd), 0) AS total_transfers
        FROM journal_postings p
        JOIN journal_transactions t ON p.transaction_id = t.id
        WHERE t.status = 'POSTED'
          AND t.tx_type IN ('TRANSFER', 'CREDIT_CARD_PAYMENT')
          AND t.occurred_at >= ? AND t.occurred_at <= ?
          AND p.debit_vnd > 0
        ''',
        variables: dateVars,
      ).get();
      final planText2 =
          plan2.map((r) => r.data['detail'].toString()).join('\n');
      expect(
        planText2.contains('idx_tx_occurred_at') ||
            planText2.contains('idx_tx_status_type') ||
            planText2.contains('USING INDEX'),
        isTrue,
        reason: 'Transfers query must use index on transactions: $planText2',
      );

      // Query 3: Category spending
      final plan3 = await db.customSelect(
        '''
        EXPLAIN QUERY PLAN
        SELECT 
          c.id AS category_id,
          c.name AS category_name,
          COALESCE(SUM(p.debit_vnd), 0) AS gross_expense,
          COALESCE(SUM(p.credit_vnd), 0) AS refund_credits
        FROM categories c
        JOIN journal_postings p ON c.id = p.category_id
        JOIN journal_transactions t ON p.transaction_id = t.id
        JOIN ledger_accounts a ON p.account_id = a.id
        WHERE t.status = 'POSTED'
          AND t.tx_type != 'REVERSAL'
          AND t.occurred_at >= ? AND t.occurred_at <= ?
          AND a.kind = 'EXPENSE'
          AND c.kind = 'EXPENSE'
          AND c.is_archived = 0
        GROUP BY c.id, c.name
        HAVING gross_expense > 0 OR refund_credits > 0
        ORDER BY c.id ASC
        ''',
        variables: dateVars,
      ).get();
      final planText3 =
          plan3.map((r) => r.data['detail'].toString()).join('\n');
      expect(
        planText3.contains('idx_tx_occurred_at') ||
            planText3.contains('idx_tx_status_type') ||
            planText3.contains('USING INDEX'),
        isTrue,
        reason:
            'Category spending query must use index on transactions: $planText3',
      );
    });
  });

  group('Empty Database & Boundary Resilience', () {
    test(
        'currentMonthlyBudgetSummaryProvider handles clean initial DB gracefully',
        () async {
      // Clean DB has seeded categories, but 0 budgets and 0 transactions
      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      expect(summary.categoryProgresses, isEmpty);
      expect(summary.totalLimitVnd.amount, equals(0));
      expect(summary.totalSpentVnd.amount, equals(0));
      expect(summary.overallSpentRatio, equals(0.0));
      expect(summary.exceededCount, equals(0));
      expect(summary.warningCount, equals(0));
    });

    test(
        'reportsSummaryProvider handles clean initial DB gracefully without throwing',
        () async {
      // Clean DB has 0 transactions
      final reports = await container.read(reportsSummaryProvider.future);
      expect(reports.spendingReport.categories, isEmpty);
      expect(reports.spendingReport.grossExpense.amount, equals(0));
      expect(reports.spendingReport.refundCredits.amount, equals(0));
      expect(reports.spendingReport.netExpense.amount, equals(0));
      expect(reports.spendingReport.recognizedIncome.amount, equals(0));
      expect(reports.spendingReport.savingsRate, isNull);
      expect(reports.spendingReport.savingsRateDisplay,
          equals('Chưa có thu nhập'));
      expect(reports.internalTransfersTotal.amount, equals(0));
      expect(reports.totalAssets.amount, equals(0));
      expect(reports.totalLiabilities.amount, equals(0));
      expect(reports.netWorth.amount, equals(0));
    });

    test(
        'currentMonthlyBudgetSummaryProvider with budgets but 0 transactions evaluates cleanly',
        () async {
      final now = DateTime.now();
      final yearMonth = now.year * 100 + now.month;

      final categories = await db.select(db.categories).get();
      final foodCat = categories.firstWhere((c) => c.kind == 'EXPENSE');

      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: foodCat.id,
              yearMonth: yearMonth,
              limitVnd: 5000000,
              alertThresholdPct: const Value(80),
            ),
          );

      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      expect(summary.categoryProgresses.length, equals(1));
      final progress = summary.categoryProgresses.first;
      expect(progress.categoryId, equals(foodCat.id));
      expect(progress.categoryName, equals(foodCat.name));
      expect(progress.limitVnd.amount, equals(5000000));
      expect(progress.spentVnd.amount, equals(0));
      expect(progress.remainingVnd.amount, equals(5000000));
      expect(progress.spentRatio, equals(0.0));
      expect(progress.isExceeded, isFalse);
    });
  });

  group('Transaction Semantics & Filtering Verifications', () {
    test(
        'REVERSAL, VOIDED, and SUPERSEDED transactions are strictly excluded from spending',
        () async {
      final now = DateTime.now();
      final yearMonth = now.year * 100 + now.month;
      final ts = now.millisecondsSinceEpoch;

      final bank = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Bank Test',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: ts,
            ),
          );
      final categories = await db.select(db.categories).get();
      final foodCat = categories.firstWhere((c) => c.kind == 'EXPENSE');

      // Add budget for food
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: foodCat.id,
              yearMonth: yearMonth,
              limitVnd: 2000000,
            ),
          );

      // 1. Valid POSTED expense: 300.000 ₫
      final tx1 = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              status: const Value('POSTED'),
              occurredAt: ts,
              createdAt: ts,
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: tx1,
              accountId: foodCat.ledgerAccountId,
              debitVnd: const Value(300000),
              categoryId: Value(foodCat.id),
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: tx1,
              accountId: bank,
              creditVnd: const Value(300000),
            ),
          );

      // 2. REVERSAL transaction (must be ignored)
      final txReversal = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'REVERSAL',
              status: const Value('POSTED'),
              occurredAt: ts,
              createdAt: ts,
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txReversal,
              accountId: bank,
              debitVnd: const Value(300000),
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txReversal,
              accountId: foodCat.ledgerAccountId,
              creditVnd: const Value(300000),
              categoryId: Value(foodCat.id),
            ),
          );

      // 3. VOIDED transaction (must be ignored)
      final txVoided = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              status: const Value('VOIDED'),
              occurredAt: ts,
              createdAt: ts,
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txVoided,
              accountId: foodCat.ledgerAccountId,
              debitVnd: const Value(500000),
              categoryId: Value(foodCat.id),
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txVoided,
              accountId: bank,
              creditVnd: const Value(500000),
            ),
          );

      // 4. SUPERSEDED transaction (must be ignored)
      final txSuperseded = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              status: const Value('SUPERSEDED'),
              occurredAt: ts,
              createdAt: ts,
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txSuperseded,
              accountId: foodCat.ledgerAccountId,
              debitVnd: const Value(700000),
              categoryId: Value(foodCat.id),
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txSuperseded,
              accountId: bank,
              creditVnd: const Value(700000),
            ),
          );

      // Verify currentMonthlyBudgetSummaryProvider sees ONLY the 300.000 ₫ expense
      final budgetSummary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      expect(budgetSummary.categoryProgresses.first.spentVnd.amount,
          equals(300000));
      expect(budgetSummary.totalSpentVnd.amount, equals(300000));

      // Verify reportsSummaryProvider sees ONLY the 300.000 ₫ expense
      final reports = await container.read(reportsSummaryProvider.future);
      expect(reports.spendingReport.grossExpense.amount, equals(300000));
      expect(reports.spendingReport.netExpense.amount, equals(300000));
    });

    test(
        'refund transactions offset gross expenses correctly in both providers',
        () async {
      final now = DateTime.now();
      final yearMonth = now.year * 100 + now.month;
      final ts = now.millisecondsSinceEpoch;

      final bank = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Bank Test',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: ts,
            ),
          );
      final categories = await db.select(db.categories).get();
      final shoppingCat =
          categories.firstWhere((c) => c.name.contains('Mua sắm'));

      // Budget: 1.000.000 ₫
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: shoppingCat.id,
              yearMonth: yearMonth,
              limitVnd: 1000000,
            ),
          );

      // Expense: 400.000 ₫
      final txExp = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              status: const Value('POSTED'),
              occurredAt: ts,
              createdAt: ts,
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txExp,
              accountId: shoppingCat.ledgerAccountId,
              debitVnd: const Value(400000),
              categoryId: Value(shoppingCat.id),
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txExp,
              accountId: bank,
              creditVnd: const Value(400000),
            ),
          );

      // Refund: 100.000 ₫ (credit to expense category, debit to bank)
      final txRef = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'REFUND',
              status: const Value('POSTED'),
              occurredAt: ts + 1000,
              createdAt: ts + 1000,
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txRef,
              accountId: bank,
              debitVnd: const Value(100000),
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txRef,
              accountId: shoppingCat.ledgerAccountId,
              creditVnd: const Value(100000),
              categoryId: Value(shoppingCat.id),
            ),
          );

      // Verify budget summary: spent = max(0, 400.000 - 100.000) = 300.000
      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      final p = summary.categoryProgresses.first;
      expect(p.spentVnd.amount, equals(300000));

      // Verify reports summary: gross = 400.000, refund = 100.000, net = 300.000
      final reports = await container.read(reportsSummaryProvider.future);
      expect(reports.spendingReport.grossExpense.amount, equals(400000));
      expect(reports.spendingReport.refundCredits.amount, equals(100000));
      expect(reports.spendingReport.netExpense.amount, equals(300000));
    });
  });

  group('Reactive Stream Observation', () {
    test(
        'currentMonthlyBudgetSummaryProvider stream emits when new budget or tx is added',
        () async {
      final now = DateTime.now();
      final yearMonth = now.year * 100 + now.month;
      final ts = now.millisecondsSinceEpoch;

      final emissions = <MonthlyBudgetSummary>[];
      final subscription = container.listen(
        currentMonthlyBudgetSummaryProvider,
        (previous, next) {
          next.whenData((summary) {
            emissions.add(summary);
          });
        },
      );

      // Allow initial emission
      await pumpEventQueue();
      expect(emissions.length, equals(1));
      expect(emissions.last.categoryProgresses, isEmpty);

      // Add a category budget
      final categories = await db.select(db.categories).get();
      final foodCat = categories.firstWhere((c) => c.kind == 'EXPENSE');
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: foodCat.id,
              yearMonth: yearMonth,
              limitVnd: 2000000,
            ),
          );

      await pumpEventQueue();
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.categoryProgresses.length, equals(1));
      expect(emissions.last.totalSpentVnd.amount, equals(0));

      // Post a transaction for that category
      final bank = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Bank Test',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: ts,
            ),
          );
      final tx = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              status: const Value('POSTED'),
              occurredAt: ts,
              createdAt: ts,
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: tx,
              accountId: foodCat.ledgerAccountId,
              debitVnd: const Value(150000),
              categoryId: Value(foodCat.id),
            ),
          );
      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: tx,
              accountId: bank,
              creditVnd: const Value(150000),
            ),
          );

      await pumpEventQueue();
      expect(emissions.last.totalSpentVnd.amount, equals(150000));
      expect(emissions.last.categoryProgresses.first.spentVnd.amount,
          equals(150000));

      subscription.close();
    });
  });

  group('Massive Volume Benchmark (Stress Test)', () {
    test(
        '1000 transactions and 2000 postings query executes in single-digit ms',
        () async {
      final now = DateTime.now();
      final yearMonth = now.year * 100 + now.month;
      final ts = now.millisecondsSinceEpoch;

      final bank = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Bank Benchmark',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: ts,
            ),
          );
      final categories = await db.select(db.categories).get();
      final foodCat = categories.firstWhere((c) => c.kind == 'EXPENSE');

      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: foodCat.id,
              yearMonth: yearMonth,
              limitVnd: 50000000,
            ),
          );

      // Insert 1000 transactions in a single batch transaction
      await db.transaction(() async {
        for (int i = 0; i < 1000; i++) {
          // Spread across 5 months (some inside this month, some outside)
          final offsetDays = (i % 150) - 75; // -75 to +74 days
          final txTs = DateTime.now()
              .add(Duration(days: offsetDays))
              .millisecondsSinceEpoch;

          final txId = await db.into(db.journalTransactions).insert(
                JournalTransactionsCompanion.insert(
                  txType: (i % 5 == 0) ? 'INCOME' : 'EXPENSE',
                  status: const Value('POSTED'),
                  occurredAt: txTs,
                  createdAt: txTs,
                ),
              );

          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: foodCat.ledgerAccountId,
                  debitVnd: const Value(50000),
                  categoryId: Value(foodCat.id),
                ),
              );
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: bank,
                  creditVnd: const Value(50000),
                ),
              );
        }
      });

      // Benchmark currentMonthlyBudgetSummaryProvider query
      final swBudget = Stopwatch()..start();
      final budgetSummary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      swBudget.stop();

      expect(budgetSummary.categoryProgresses.length, equals(1));
      expect(budgetSummary.categoryProgresses.first.spentVnd.amount,
          greaterThan(0));
      // Assert execution time is fast (under 100ms in debug VM, typically < 10ms)
      expect(
        swBudget.elapsedMilliseconds,
        lessThan(100),
        reason:
            'Budget summary must execute rapidly with indexes: ${swBudget.elapsedMilliseconds}ms',
      );

      // Benchmark reportsSummaryProvider query
      final swReports = Stopwatch()..start();
      final reports = await container.read(reportsSummaryProvider.future);
      swReports.stop();

      expect(reports.spendingReport.grossExpense.amount, greaterThan(0));
      expect(
        swReports.elapsedMilliseconds,
        lessThan(100),
        reason:
            'Reports summary must execute rapidly with indexes: ${swReports.elapsedMilliseconds}ms',
      );
    });
  });
}
