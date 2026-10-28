import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/security/backup_payload_models.dart';
import '../../../../core/security/encrypted_backup_service.dart';
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

  // Watch streams so any transaction/account/setting mutation triggers recomputation
  ref.watch(accountsWithBalancesStreamProvider);
  ref.watch(recentTransactionsStreamProvider);
  ref.watch(settingsStreamProvider);

  final now = DateTime.now();
  final periodMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final startOfMonthMs =
      DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  final endOfMonthMs = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999)
      .millisecondsSinceEpoch;

  final categories = await db.select(db.categories).get();
  final postedTxs = await (db.select(db.journalTransactions)
        ..where((t) =>
            t.status.equals('POSTED') &
            t.txType.isNotValue('REVERSAL') &
            t.occurredAt.isBetweenValues(startOfMonthMs, endOfMonthMs)))
      .get();

  final txById = {for (final tx in postedTxs) tx.id: tx};
  final allPostings = await db.select(db.journalPostings).get();
  final accounts = await db.select(db.ledgerAccounts).get();
  final accountKindById = {for (final a in accounts) a.id: a.kind};

  int recognizedIncomeVnd = 0;
  int internalTransfersVnd = 0;
  final grossByCategory = <int, int>{};
  final refundByCategory = <int, int>{};

  for (final tx in postedTxs) {
    if (tx.txType == 'TRANSFER' || tx.txType == 'CREDIT_CARD_PAYMENT') {
      final txPostings =
          allPostings.where((p) => p.transactionId == tx.id && p.debitVnd > 0);
      for (final p in txPostings) {
        internalTransfersVnd += p.debitVnd;
      }
    }
  }

  for (final p in allPostings) {
    final tx = txById[p.transactionId];
    if (tx == null) continue;

    final accKind = accountKindById[p.accountId];
    if (accKind == 'INCOME' && tx.txType == 'INCOME') {
      recognizedIncomeVnd += (p.creditVnd - p.debitVnd);
    } else if (accKind == 'EXPENSE' && p.categoryId != null) {
      final catId = p.categoryId!;
      if (p.debitVnd > 0) {
        grossByCategory[catId] = (grossByCategory[catId] ?? 0) + p.debitVnd;
      }
      if (p.creditVnd > 0) {
        refundByCategory[catId] = (refundByCategory[catId] ?? 0) + p.creditVnd;
      }
    }
  }

  final expenseCategories =
      categories.where((c) => c.kind == 'EXPENSE' && !c.isArchived).toList();
  final categoryItems = <CategorySpendingItem>[];
  for (final cat in expenseCategories) {
    final gross = grossByCategory[cat.id] ?? 0;
    final refund = refundByCategory[cat.id] ?? 0;
    if (gross > 0 || refund > 0) {
      categoryItems.add(
        CategorySpendingItem(
          categoryId: cat.id,
          categoryName: cat.name,
          grossExpense: VndMoney(gross),
          refundCredits: VndMoney(refund),
        ),
      );
    }
  }

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
