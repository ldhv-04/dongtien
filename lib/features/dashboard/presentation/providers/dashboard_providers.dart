import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/envelope_dao.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../domain/budgeting/billing_cycle_calculator.dart';
import '../../../../domain/budgeting/category_budget_progress.dart';

// Database & DAOs
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final ledgerDaoProvider = Provider<LedgerDao>((ref) {
  return ref.watch(databaseProvider).ledgerDao;
});

final envelopeDaoProvider = Provider<EnvelopeDao>((ref) {
  return ref.watch(databaseProvider).envelopeDao;
});

// Streams
final liquidAssetsStreamProvider = StreamProvider<int>((ref) {
  return ref.watch(ledgerDaoProvider).watchTotalLiquidAssets();
});

final accountsWithBalancesStreamProvider =
    StreamProvider<List<AccountWithBalance>>((ref) {
  return ref.watch(ledgerDaoProvider).watchAccountsWithBalances();
});

final envelopesStreamProvider = StreamProvider<List<Envelope>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.envelopes)..where((e) => e.isArchived.equals(false)))
      .watch();
});

final settingsStreamProvider = StreamProvider<Setting>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.settings).watchSingle();
});

final pendingBillsStreamProvider = StreamProvider<List<ScheduledItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.scheduledItems)
        ..where((s) => s.kind.equals('BILL') & s.status.equals('PENDING'))
        ..orderBy([(s) => OrderingTerm(expression: s.dueDateMs)]))
      .watch();
});

final nextPlannedIncomeStreamProvider = StreamProvider<ScheduledItem?>((ref) {
  final db = ref.watch(databaseProvider);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  return (db.select(db.scheduledItems)
        ..where((s) =>
            s.kind.equals('PLANNED_INCOME') &
            s.status.equals('PENDING') &
            s.dueDateMs.isBiggerOrEqualValue(nowMs))
        ..orderBy([(s) => OrderingTerm(expression: s.dueDateMs)])
        ..limit(1))
      .watchSingleOrNull();
});

final recentTransactionsStreamProvider =
    StreamProvider<List<JournalTransaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.journalTransactions)
        ..where((t) =>
            t.status.equals('POSTED') & t.txType.equals('REVERSAL').not())
        ..orderBy([
          (t) =>
              OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
        ])
        ..limit(5))
      .watch();
});

/// Category budget summary for the active billing cycle.
///
/// Executes a SINGLE aggregated SQLite JOIN ... GROUP BY query with zero N+1 latency,
/// correct single-quoted SQL literals ('POSTED', 'REVERSAL'), and reactive observation
/// across settings, category_budgets, categories, journal_postings, and journal_transactions.
final currentMonthlyBudgetSummaryProvider =
    StreamProvider<MonthlyBudgetSummary>((ref) {
  final db = ref.watch(databaseProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final periodStartDay =
      (settingsAsync.value?.periodStartDay ?? 1).clamp(1, 28);

  final now = DateTime.now();
  final cycle = BillingCycleCalculator.calculate(now, periodStartDay);
  final activeCycleYearMonth = cycle.yearMonth;
  final calendarYearMonth = now.year * 100 + now.month;

  final startMs = cycle.cycleStart.millisecondsSinceEpoch;
  final endMs = cycle.cycleEndExclusive.millisecondsSinceEpoch;

  const query = '''
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
WHERE b.year_month IN (?, ?)
ORDER BY b.category_id ASC;
''';

  return db
      .customSelect(
        query,
        variables: [
          Variable.withInt(startMs),
          Variable.withInt(endMs),
          Variable.withInt(activeCycleYearMonth),
          Variable.withInt(calendarYearMonth),
        ],
        readsFrom: {
          db.settings,
          db.categoryBudgets,
          db.categories,
          db.journalPostings,
          db.journalTransactions,
        },
      )
      .watch()
      .map((rows) {
        final Map<int, CategoryBudgetProgress> progressesByCat = {};
        for (final row in rows) {
          final catId = row.read<int>('category_id');
          final rowYm = row.read<int>('year_month');
          if (progressesByCat.containsKey(catId) &&
              progressesByCat[catId]!.yearMonth == activeCycleYearMonth) {
            continue;
          }
          final progress = CategoryBudgetTracker.evaluateCategoryBudget(
            categoryId: catId,
            categoryName: row.read<String>('category_name'),
            yearMonth: rowYm,
            limitVnd: VndMoney(row.read<int>('limit_vnd')),
            grossExpense: VndMoney(row.read<int>('gross_expense')),
            refundCredits: VndMoney(row.read<int>('refund_credits')),
            alertThresholdPct: row.read<int>('alert_threshold_pct'),
          );
          if (rowYm == activeCycleYearMonth ||
              !progressesByCat.containsKey(catId)) {
            progressesByCat[catId] = progress;
          }
        }

        return CategoryBudgetTracker.evaluateSummary(
          yearMonth: activeCycleYearMonth,
          categoryProgresses: progressesByCat.values.toList(),
          cycleLabel: cycle.formatCycleRange(),
        );
      });
});
