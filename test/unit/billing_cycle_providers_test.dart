import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/budgeting/billing_cycle_calculator.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/dashboard/presentation/providers/safe_to_spend_provider.dart';
import 'package:dongtien/features/reports_settings/presentation/providers/reports_settings_providers.dart';
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
  group('R3: Billing Cycle Single Source of Truth Providers Test', () {
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
      await container.read(settingsStreamProvider.future);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
        'currentMonthlyBudgetSummaryProvider derives cycleLabel matching BillingCycleCalculator',
        () async {
      final now = DateTime.now();
      final expectedCycle = BillingCycleCalculator.calculate(now, 1);

      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      expect(summary.cycleLabel, equals(expectedCycle.formatCycleRange()));
      expect(summary.yearMonth, equals(expectedCycle.yearMonth));
    });

    test(
        'Updating periodStartDay to 15 reactively updates currentMonthlyBudgetSummaryProvider cycleLabel',
        () async {
      final now = DateTime.now();
      final expectedCycle15 = BillingCycleCalculator.calculate(now, 15);

      // Update periodStartDay to 15
      final settingsController =
          container.read(reportsSettingsControllerProvider.notifier);
      await settingsController.updatePeriodStartDay(15);
      await container.read(settingsStreamProvider.future);

      // Read updated summary
      final summary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      expect(summary.cycleLabel, equals(expectedCycle15.formatCycleRange()));
      expect(summary.yearMonth, equals(expectedCycle15.yearMonth));
    });

    test(
        'safeToSpendProvider respects periodStartDay and derives positive allowance',
        () async {
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

      // Await streams feeding safeToSpendProvider
      await container.read(liquidAssetsStreamProvider.future);
      await container.read(envelopesStreamProvider.future);
      await container.read(pendingBillsStreamProvider.future);
      await container.read(nextPlannedIncomeStreamProvider.future);

      final stsAsync = container.read(safeToSpendProvider);
      expect(stsAsync.hasValue, isTrue);
      final sts = stsAsync.value!;
      expect(sts.isDeficit, isFalse);
      expect(sts.safeToSpend.amount, greaterThan(0));
      expect(sts.daysRemaining, greaterThan(0));
    });

    test('reportsSummaryProvider derives cycle-aware currentPeriodMonth',
        () async {
      final report = await container.read(reportsSummaryProvider.future);

      final now = DateTime.now();
      final cycle = BillingCycleCalculator.calculate(now, 1);
      final expectedPeriod = cycle.isCalendarMonth
          ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
          : '${cycle.cycleStart.year}-${cycle.cycleStart.month.toString().padLeft(2, '0')} (${cycle.formatCycleRange()})';
      expect(report.currentPeriodMonth, equals(expectedPeriod));
    });
  });
}
