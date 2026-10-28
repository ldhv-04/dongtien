import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/envelope_dao.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../core/money/vnd_money.dart';
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

/// Category budget summary for the current month.
final currentMonthlyBudgetSummaryProvider =
    StreamProvider<MonthlyBudgetSummary>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final yearMonth = now.year * 100 + now.month;

  final startOfMonthMs =
      DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  final endOfMonthMs =
      DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch;

  final budgetsQuery = db.select(db.categoryBudgets)
    ..where((b) => b.yearMonth.equals(yearMonth));

  return budgetsQuery.watch().asyncMap((budgets) async {
    final List<CategoryBudgetProgress> progresses = [];

    for (final b in budgets) {
      final category = await (db.select(db.categories)
            ..where((c) => c.id.equals(b.categoryId)))
          .getSingleOrNull();
      final catName = category?.name ?? 'Danh mục ${b.categoryId}';

      final result = await db.customSelect(
        'SELECT COALESCE(SUM(p.debit_vnd), 0) AS gross_expense, '
        'COALESCE(SUM(p.credit_vnd), 0) AS refund_credits '
        'FROM journal_postings p '
        'JOIN journal_transactions t ON p.transaction_id = t.id '
        'WHERE p.category_id = ? AND t.occurred_at >= ? AND t.occurred_at < ? '
        'AND t.status = "POSTED"',
        variables: [
          Variable.withInt(b.categoryId),
          Variable.withInt(startOfMonthMs),
          Variable.withInt(endOfMonthMs),
        ],
        readsFrom: {db.journalPostings, db.journalTransactions},
      ).getSingle();

      final gross = result.read<int>('gross_expense');
      final refund = result.read<int>('refund_credits');

      progresses.add(CategoryBudgetTracker.evaluateCategoryBudget(
        categoryId: b.categoryId,
        categoryName: catName,
        yearMonth: yearMonth,
        limitVnd: VndMoney(b.limitVnd),
        grossExpense: VndMoney(gross),
        refundCredits: VndMoney(refund),
        alertThresholdPct: b.alertThresholdPct,
      ));
    }

    return CategoryBudgetTracker.evaluateSummary(
      yearMonth: yearMonth,
      categoryProgresses: progresses,
    );
  });
});
