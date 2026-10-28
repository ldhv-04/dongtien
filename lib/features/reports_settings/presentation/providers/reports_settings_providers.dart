import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/notifications/notification_scheduler.dart';
import '../../../../core/security/backup_payload_models.dart';
import '../../../../core/security/encrypted_backup_service.dart';
import '../../../../domain/budgeting/billing_cycle_calculator.dart';
import '../../../../domain/budgeting/category_spending_calculator.dart';
import '../../../../domain/ledger/account_kind.dart';
import '../../../../domain/ledger/post_transaction_command.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// Aggregated model for the Reports (`Báo cáo`) screen.
class ReportsSummaryData {
  final String currentPeriodMonth;
  final CategorySpendingReport spendingReport;
  final VndMoney internalTransfersTotal;
  final VndMoney totalAssets;
  final VndMoney totalLiabilities;
  final VndMoney netWorth;

  const ReportsSummaryData({
    required this.currentPeriodMonth,
    required this.spendingReport,
    required this.internalTransfersTotal,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });
}

/// Reactive provider computing the Reports summary for the current period and Net Worth.
final reportsSummaryProvider = FutureProvider<ReportsSummaryData>((ref) async {
  final db = ref.watch(databaseProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final periodStartDay =
      (settingsAsync.value?.periodStartDay ?? 1).clamp(1, 28);

  final now = DateTime.now();
  final cycle = BillingCycleCalculator.calculate(now, periodStartDay);

  final startMs = cycle.cycleStart.millisecondsSinceEpoch;
  final endMs = cycle.cycleEndInclusive.millisecondsSinceEpoch;

  final dateVars = [
    Variable.withInt(startMs),
    Variable.withInt(endMs),
  ];

  final periodMonth = cycle.isCalendarMonth
      ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
      : '${cycle.cycleStart.year}-${cycle.cycleStart.month.toString().padLeft(2, '0')} (${cycle.formatCycleRange()})';

  // 1. Bounded recognized income query
  final incomeRow = await db
      .customSelect(
        '''
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
        readsFrom: {
          db.journalPostings,
          db.journalTransactions,
          db.ledgerAccounts
        },
      )
      .getSingle();
  final recognizedIncomeVnd = incomeRow.read<int>('total_income');

  // 2. Bounded internal transfers query
  final transfersRow = await db
      .customSelect(
        '''
    SELECT COALESCE(SUM(p.debit_vnd), 0) AS total_transfers
    FROM journal_postings p
    JOIN journal_transactions t ON p.transaction_id = t.id
    WHERE t.status = 'POSTED'
      AND t.tx_type IN ('TRANSFER', 'CREDIT_CARD_PAYMENT')
      AND t.occurred_at >= ? AND t.occurred_at <= ?
      AND p.debit_vnd > 0
    ''',
        variables: dateVars,
        readsFrom: {db.journalPostings, db.journalTransactions},
      )
      .getSingle();
  final internalTransfersVnd = transfersRow.read<int>('total_transfers');

  // 3. Bounded category spending query
  final catSpendingRows = await db
      .customSelect(
        '''
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
        readsFrom: {
          db.categories,
          db.journalPostings,
          db.journalTransactions,
          db.ledgerAccounts
        },
      )
      .get();

  final categoryItems = catSpendingRows.map((r) {
    return CategorySpendingItem(
      categoryId: r.read<int>('category_id'),
      categoryName: r.read<String>('category_name'),
      grossExpense: VndMoney(r.read<int>('gross_expense')),
      refundCredits: VndMoney(r.read<int>('refund_credits')),
    );
  }).toList();

  final spendingReport = CategorySpendingCalculator.calculate(
    categoryItems: categoryItems,
    recognizedIncome: VndMoney(recognizedIncomeVnd),
  );

  // Compute Total Assets, Total Liabilities, and Net Worth across all active accounts
  int totalAssetsVnd = 0;
  int totalLiabilitiesVnd = 0;
  final accountsWithBalances = await db.ledgerDao.getAccountsWithBalances();
  for (final acc in accountsWithBalances) {
    if (acc.kind == AccountKind.assetCash ||
        acc.kind == AccountKind.assetBank) {
      totalAssetsVnd += acc.balanceVnd;
    } else if (acc.kind == AccountKind.liabilityCreditCard) {
      totalLiabilitiesVnd += acc.balanceVnd;
    }
  }

  return ReportsSummaryData(
    currentPeriodMonth: periodMonth,
    spendingReport: spendingReport,
    internalTransfersTotal: VndMoney(internalTransfersVnd),
    totalAssets: VndMoney(totalAssetsVnd),
    totalLiabilities: VndMoney(totalLiabilitiesVnd),
    netWorth: VndMoney(totalAssetsVnd - totalLiabilitiesVnd),
  );
});

/// Controller for Settings, CSV export, Encrypted Backup/Restore, Sample Data, and Reset.
class ReportsSettingsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> updateMinimumCashBuffer(int bufferVnd) async {
    if (bufferVnd < 0) {
      throw ArgumentError('Minimum cash buffer must be >= 0');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
        SettingsCompanion(
          minimumCashBufferVnd: Value(bufferVnd),
        ),
      );
      ref.invalidate(settingsStreamProvider);
      ref.invalidate(reportsSummaryProvider);
    });
  }

  Future<void> updatePeriodStartDay(int day) async {
    if (day < 1 || day > 28) {
      throw ArgumentError('Period start day must be between 1 and 28');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
        SettingsCompanion(
          periodStartDay: Value(day),
        ),
      );
      ref.invalidate(settingsStreamProvider);
      ref.invalidate(reportsSummaryProvider);
      ref.invalidate(currentMonthlyBudgetSummaryProvider);
    });
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
        SettingsCompanion(
          notificationsEnabled: Value(enabled),
        ),
      );
      ref.invalidate(settingsStreamProvider);

      final scheduler = ref.read(notificationSchedulerProvider);
      if (enabled) {
        await scheduler.initialize();
        await scheduler.reconcileFromDatabase(_db);
      } else {
        await scheduler.cancelAll();
      }
    });
  }

  /// Generates a UTF-8 CSV string of all posted journal transactions.
  Future<String> exportCsv() async {
    final txs = await (_db.select(_db.journalTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .get();
    final postings = await _db.select(_db.journalPostings).get();
    final accounts = await _db.select(_db.ledgerAccounts).get();
    final categories = await _db.select(_db.categories).get();

    final accNameById = {for (final a in accounts) a.id: a.name};
    final catNameById = {for (final c in categories) c.id: c.name};

    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Ngay_Gio,Loai_Giao_Dich,Trang_Thai,So_Tien_VND,Tai_Khoan,Danh_Muc,Ghi_Chu',
    );

    for (final tx in txs) {
      final txPostings =
          postings.where((p) => p.transactionId == tx.id).toList();
      final totalDebit = txPostings.fold<int>(0, (sum, p) => sum + p.debitVnd);
      final primaryAccNames = txPostings
          .map((p) => accNameById[p.accountId] ?? '')
          .where((n) => n.isNotEmpty)
          .toSet()
          .join(' -> ');
      final catId = txPostings
          .map((p) => p.categoryId)
          .firstWhere((id) => id != null, orElse: () => null);
      final catName = catId != null ? (catNameById[catId] ?? '') : '';
      final dt =
          DateTime.fromMillisecondsSinceEpoch(tx.occurredAt).toIso8601String();
      final escapedNote = tx.description.replaceAll('"', '""');
      buffer.writeln(
        '${tx.id},"$dt","${tx.txType}","${tx.status}",$totalDebit,"$primaryAccNames","$catName","$escapedNote"',
      );
    }

    return buffer.toString();
  }

  /// Exports all 9 tables into an AES-256-GCM encrypted backup JSON string.
  Future<String> exportEncryptedBackup(String password) async {
    return EncryptedBackupService.exportBackupToJson(
      db: _db,
      password: password,
    );
  }

  /// Validates and atomically restores an encrypted backup JSON string.
  Future<BackupValidationResult> restoreEncryptedBackup({
    required String jsonContent,
    required String password,
  }) async {
    final result = await EncryptedBackupService.validateAndRestoreBackup(
      db: _db,
      jsonContent: jsonContent,
      password: password,
    );
    _invalidateAllProviders();
    return result;
  }

  /// Populates realistic Vietnamese sample transactions, allocations, budgets, and bills.
  Future<void> generateSampleData() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final accounts = await _db.select(_db.ledgerAccounts).get();
      final categories = await _db.select(_db.categories).get();
      final envelopes = await _db.select(_db.envelopes).get();

      int bankAccId;
      final existingBanks =
          accounts.where((a) => a.kind == 'ASSET_BANK' && !a.isArchived);
      if (existingBanks.isNotEmpty) {
        bankAccId = existingBanks.first.id;
      } else {
        bankAccId = await _db.into(_db.ledgerAccounts).insert(
              LedgerAccountsCompanion.insert(
                name: 'Tài khoản ngân hàng mẫu',
                kind: 'ASSET_BANK',
                isLiquid: const Value(true),
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
      }

      final salaryCat = categories.firstWhere(
        (c) => c.kind == 'INCOME',
        orElse: () => categories.first,
      );
      final foodCat = categories.firstWhere(
        (c) => c.kind == 'EXPENSE',
        orElse: () => categories.last,
      );

      final now = DateTime.now();
      final tsBase = now.millisecondsSinceEpoch;

      // 1. Sample Salary Income: 15.000.000 ₫
      await _db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.income(
          receivingAssetAccountId: bankAccId,
          categoryId: salaryCat.id,
          amountVnd: 15000000,
          occurredAt: tsBase - 3600000,
          description: 'Lương tháng mẫu',
          idempotencyKey: 'sample_income_$tsBase',
        ),
      );

      // 2. Sample Food Expense: 450.000 ₫
      await _db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: bankAccId,
          categoryId: foodCat.id,
          amountVnd: 450000,
          occurredAt: tsBase - 1800000,
          description: 'Đi chợ tuần mẫu',
          idempotencyKey: 'sample_expense_$tsBase',
        ),
      );

      // 3. Allocate 2.000.000 ₫ to an Emergency Envelope
      int targetEnvId;
      if (envelopes.isNotEmpty) {
        targetEnvId = envelopes.first.id;
      } else {
        targetEnvId = await _db.into(_db.envelopes).insert(
              EnvelopesCompanion.insert(
                name: 'Quỹ dự phòng khẩn cấp',
                policy: 'PROTECTED',
                targetAmountVnd: const Value(10000000),
              ),
            );
      }

      final totalLiquid = await _db.ledgerDao.getTotalLiquidAssets();
      await _db.envelopeDao.allocate(
        envelopeId: targetEnvId,
        amountVnd: 2000000,
        totalLiquidAssetsVnd: totalLiquid,
      );

      // 4. Upsert Category Budget for Food: 4.000.000 ₫
      final yearMonth = now.year * 100 + now.month;
      final existingBudget = await (_db.select(_db.categoryBudgets)
            ..where((b) =>
                b.categoryId.equals(foodCat.id) &
                b.yearMonth.equals(yearMonth)))
          .getSingleOrNull();
      if (existingBudget == null) {
        await _db.into(_db.categoryBudgets).insert(
              CategoryBudgetsCompanion.insert(
                categoryId: foodCat.id,
                yearMonth: yearMonth,
                limitVnd: 4000000,
              ),
            );
      }

      _invalidateAllProviders();
    });
  }

  /// Resets all database tables and restores clean Vietnamese default seed data (`0 ₫` balances).
  Future<void> resetDatabaseToZero() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db.transaction(() async {
        await _db.customUpdate(
          'UPDATE journal_transactions SET reverses_tx_id = NULL, replaced_by_tx_id = NULL',
          updates: {_db.journalTransactions},
        );
        await _db.delete(_db.envelopeMovements).go();
        await _db.delete(_db.journalPostings).go();
        await _db.delete(_db.scheduledItems).go();
        await _db.delete(_db.categoryBudgets).go();
        await _db.delete(_db.journalTransactions).go();
        await _db.delete(_db.envelopes).go();
        await _db.delete(_db.categories).go();
        await _db.delete(_db.ledgerAccounts).go();
        await _db.delete(_db.settings).go();

        await seedInitialData(_db);
      });
      _invalidateAllProviders();
    });
  }

  void _invalidateAllProviders() {
    ref.invalidate(accountsWithBalancesStreamProvider);
    ref.invalidate(liquidAssetsStreamProvider);
    ref.invalidate(envelopesStreamProvider);
    ref.invalidate(recentTransactionsStreamProvider);
    ref.invalidate(pendingBillsStreamProvider);
    ref.invalidate(nextPlannedIncomeStreamProvider);
    ref.invalidate(settingsStreamProvider);
    ref.invalidate(currentMonthlyBudgetSummaryProvider);
    ref.invalidate(reportsSummaryProvider);
  }
}

final reportsSettingsControllerProvider =
    AutoDisposeAsyncNotifierProvider<ReportsSettingsController, void>(
  ReportsSettingsController.new,
);
