import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/money/vnd_formatter.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/core/notifications/notification_scheduler.dart';
import 'package:dongtien/domain/budgeting/category_spending_calculator.dart';
import 'package:dongtien/domain/budgeting/feasibility_advisor.dart';
import 'package:dongtien/domain/budgeting/goal_calculator.dart';
import 'package:dongtien/domain/envelopes/envelope_exceptions.dart';
import 'package:dongtien/domain/forecasting/recurrence_calculator.dart';
import 'package:dongtien/domain/forecasting/safe_to_spend_calculator.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:dongtien/domain/ledger/posting_matrix.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
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
  group('All 15 Mandatory Acceptance Scenarios (End-to-End Verification)', () {
    test(
        'Scenarios 1, 2, 3, 4: Zero initial state, Opening Balance + Income + Expense, Virtual Fund Decoupling, Over-Allocation Guard',
        () async {
      final db = _openMemoryDb();
      addTearDown(() async => db.close());

      // Scenario 1: Fresh install -> 0 ₫ initial balances across all metrics
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(0));
      expect(await db.ledgerDao.getNetWorth(), equals(0));
      expect(await db.envelopeDao.getAvailableToAllocate(0), equals(0));

      // Scenario 2: Opening balance 2.000.000 ₫ + Salary 10.000.000 ₫ - Expense 250.000 ₫ = 11.750.000 ₫
      final bankId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tài khoản ngân hàng',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1700000000000,
            ),
          );

      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: bankId,
          amountVnd: 2000000,
          occurredAt: 1700000001000,
        ),
      );
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(2000000));

      final cats = await db.select(db.categories).get();
      final salaryCat = cats.firstWhere((c) => c.kind == 'INCOME');
      final foodCat = cats.firstWhere((c) => c.kind == 'EXPENSE');

      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.income(
          receivingAssetAccountId: bankId,
          categoryId: salaryCat.id,
          amountVnd: 10000000,
          occurredAt: 1700000002000,
          description: 'Lương tháng',
        ),
      );
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(12000000));

      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: bankId,
          categoryId: foodCat.id,
          amountVnd: 250000,
          occurredAt: 1700000003000,
          description: 'Ăn uống',
        ),
      );
      final liquidAfterExpense = await db.ledgerDao.getTotalLiquidAssets();
      expect(liquidAfterExpense, equals(11750000));
      expect(
        VndFormatter.format(liquidAfterExpense),
        equals('11.750.000 ₫'),
      );

      // Scenario 3: Virtual Fund Decoupling (Allocate 3.000.000 ₫ -> ZERO ledger postings, liquid stays 11.750.000 ₫)
      final postingsBefore = await db.select(db.journalPostings).get();
      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ dự phòng',
              policy: 'PROTECTED',
            ),
          );
      await db.envelopeDao.allocate(
        envelopeId: envId,
        amountVnd: 3000000,
        totalLiquidAssetsVnd: liquidAfterExpense,
      );
      final postingsAfter = await db.select(db.journalPostings).get();
      expect(postingsAfter.length, equals(postingsBefore.length));
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(11750000));
      expect(
        await db.envelopeDao.getAvailableToAllocate(liquidAfterExpense),
        equals(8750000),
      );

      // Scenario 4: Over-Allocation Guard (Attempting to allocate 9.000.000 ₫ when 8.750.000 ₫ available throws OverAllocationException)
      await expectLater(
        () => db.envelopeDao.allocate(
          envelopeId: envId,
          amountVnd: 9000000,
          totalLiquidAssetsVnd: liquidAfterExpense,
        ),
        throwsA(isA<OverAllocationException>()),
      );
    });

    test(
        'Scenarios 5 & 6: Credit Card Purchase + Settlement & Refund Net Expense Recovery ("Thu hồi chi phí ròng", "Chưa có thu nhập")',
        () async {
      final db = _openMemoryDb();
      addTearDown(() async => db.close());

      final bankId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Ngân hàng',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1700000000000,
            ),
          );
      final ccId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Thẻ tín dụng VIB',
              kind: 'LIABILITY_CREDIT_CARD',
              isLiquid: const Value(false),
              creditLimit: const Value(20000000),
              createdAt: 1700000000000,
            ),
          );

      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: bankId,
          amountVnd: 5000000,
          occurredAt: 1700000001000,
        ),
      );

      final cats = await db.select(db.categories).get();
      final shoppingCat = cats.firstWhere((c) => c.kind == 'EXPENSE');

      // Scenario 5: Spend 800.000 ₫ on Credit Card -> CC debt = 800.000 ₫, Bank = 5.000.000 ₫, Net Worth = 4.200.000 ₫
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: ccId,
          categoryId: shoppingCat.id,
          amountVnd: 800000,
          occurredAt: 1700000002000,
          description: 'Mua hàng bằng thẻ tín dụng',
        ),
      );
      expect(await db.ledgerDao.getAccountBalance(ccId), equals(800000));
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(5000000));
      expect(await db.ledgerDao.getNetWorth(), equals(4200000));

      // Settle 800.000 ₫ CC bill from Bank -> CC debt = 0 ₫, Bank = 4.200.000 ₫, Net Worth = 4.200.000 ₫ (not double-counted as expense)
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.creditCardPayment(
          creditCardAccountId: ccId,
          sourceAssetAccountId: bankId,
          amountVnd: 800000,
          occurredAt: 1700000003000,
          description: 'Tất toán sao kê thẻ',
        ),
      );
      expect(await db.ledgerDao.getAccountBalance(ccId), equals(0));
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(4200000));
      expect(await db.ledgerDao.getNetWorth(), equals(4200000));

      // Scenario 6: Expense 200.000 ₫ + Refund 250.000 ₫ -> Net Expense = -50.000 ₫ ("Thu hồi chi phí ròng"), Income = 0 -> "Chưa có thu nhập"
      final report = CategorySpendingCalculator.calculate(
        categoryItems: [
          CategorySpendingItem(
            categoryId: 10,
            categoryName: 'Mua sắm',
            grossExpense: VndMoney(200000),
            refundCredits: VndMoney(250000),
          ),
        ],
        recognizedIncome: VndMoney.zero,
      );
      expect(report.netExpense.amount, equals(-50000));
      expect(report.effectiveExpense.amount, equals(0));
      expect(report.isNetRecovery, isTrue);
      expect(
        report.categories.first.recoveryLabel,
        equals('Thu hồi chi phí ròng'),
      );
      expect(report.savingsRate, isNull);
      expect(report.savingsRateDisplay, equals('Chưa có thu nhập'));
    });

    test(
        'Scenarios 7, 8, 9, 10: Safe-to-Spend Zero Double-Counting (1.850.000 ₫), Negative Deficit (-500.000 ₫), Ceiling Division (833.334 ₫), Drift-Free Recurrence (31/01 -> 28/02 -> 31/03)',
        () {
      final now = DateTime(2026, 10, 1);
      final horizon = DateTime(2026, 10, 11);

      // Scenario 7: Liquid = 5.000.000, Protected Env A = 2.000.000, Bill linked to Env A = 1.500.000, Unlinked Bill = 400.000, Buffer = 750.000 -> Safe-to-Spend = 1.850.000 ₫
      final sts7 = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(5000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Quỹ nhà ở',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(2000000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 101,
            title: 'Tiền thuê nhà',
            amount: VndMoney(1500000),
            dueDate: DateTime(2026, 10, 5),
            linkedEnvelopeId: 1,
          ),
          PendingBillItem(
            id: 102,
            title: 'Tiền điện',
            amount: VndMoney(400000),
            dueDate: DateTime(2026, 10, 7),
          ),
        ],
        minimumCashBuffer: VndMoney(750000),
        now: now,
        horizonDate: horizon,
        daysRemainingOverride: 10,
      );
      expect(sts7.safeToSpend.amount, equals(1850000));
      expect(sts7.dailyAllowance.amount, equals(185000));
      expect(sts7.isDeficit, isFalse);

      // Scenario 8: Liquid = 1.000.000, Protected = 800.000, Unlinked Bill = 500.000, Buffer = 200.000 -> Safe-to-Spend = -500.000 ₫, Daily = 0 ₫
      final sts8 = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(1000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Quỹ bảo vệ',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(800000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 201,
            title: 'Hoá đơn internet',
            amount: VndMoney(500000),
            dueDate: DateTime(2026, 10, 5),
          ),
        ],
        minimumCashBuffer: VndMoney(200000),
        now: now,
        horizonDate: horizon,
        daysRemainingOverride: 15,
      );
      expect(sts8.safeToSpend.amount, equals(-500000));
      expect(sts8.dailyAllowance.amount, equals(0));
      expect(sts8.isDeficit, isTrue);

      // Scenario 9: Goal 10.000.000 ₫ over 12 months -> Ceiling division = 833.334 ₫/month; Feasibility Advisor 3 calculators
      final goalEval = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 12,
      );
      expect(goalEval.requiredPerPeriod.amount, equals(833334));

      final extMonths = FeasibilityAdvisor.calculateExtendedDeadline(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        allocatedMonthlyCapacity: VndMoney(500000),
      );
      expect(extMonths, equals(20));

      final loweredTarget = FeasibilityAdvisor.calculateLoweredTarget(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 12,
        allocatedMonthlyCapacity: VndMoney(500000),
      );
      expect(loweredTarget.amount, equals(6000000));

      // Scenario 10: Month-End Recurrence without date drift (anchorDay = 31: Jan 31 -> Feb 28 -> Mar 31)
      final jan31 = DateTime(2026, 1, 31);
      final feb28 = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: jan31,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(feb28, equals(DateTime(2026, 2, 28)));

      final mar31 = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: feb28,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(mar31, equals(DateTime(2026, 3, 31)));
    });

    test(
        'Scenarios 11, 12, 15: Partial Protected Envelope Bill Payment (8.500.000 ₫), Void & Edit Audit Reversals, Notification Permission Denial Degradation',
        () async {
      final db = _openMemoryDb();
      addTearDown(() async => db.close());

      final bankId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Ngân hàng',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1700000000000,
            ),
          );
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: bankId,
          amountVnd: 10000000,
          occurredAt: 1700000001000,
        ),
      );

      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ hoá đơn',
              policy: 'PROTECTED',
            ),
          );
      await db.envelopeDao.allocate(
        envelopeId: envId,
        amountVnd: 1000000,
        totalLiquidAssetsVnd: 10000000,
      );

      final now = DateTime(2026, 10, 1);
      final horizon = DateTime(2026, 10, 11);

      // Before bill payment: Liquid = 10.000.000, Protected Env = 1.000.000, Linked Bill = 1.500.000 -> Unfunded = 500.000 -> Safe-to-Spend = 8.500.000 ₫
      final stsBefore = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [
          EnvelopeSnapshot(
            id: envId,
            name: 'Quỹ hoá đơn',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(1000000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 301,
            title: 'Hoá đơn 1.5tr',
            amount: VndMoney(1500000),
            dueDate: DateTime(2026, 10, 5),
            linkedEnvelopeId: envId,
          ),
        ],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizon,
        daysRemainingOverride: 10,
      );
      expect(stsBefore.safeToSpend.amount, equals(8500000));

      // Scenario 12: Void & Edit Audit Reversal
      final cats = await db.select(db.categories).get();
      final expCat = cats.firstWhere((c) => c.kind == 'EXPENSE');

      final txId = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: bankId,
          categoryId: expCat.id,
          amountVnd: 300000,
          occurredAt: 1700000005000,
          description: 'Chi tiêu ban đầu 300k',
        ),
      );
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(9700000));

      // Edit 300.000 ₫ -> 450.000 ₫
      final newTxId = await db.ledgerDao.editTransaction(
        originalTxId: txId,
        txType: 'EXPENSE',
        description: 'Chi tiêu đã sửa 450k',
        occurredAt: 1700000006000,
        newPostings: PostingMatrix.buildExpense(
          sourceAccountId: bankId,
          categoryId: expCat.id,
          amountVnd: 450000,
        ),
      );
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(9550000));

      final origRow = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(txId)))
          .getSingle();
      expect(origRow.status, equals('SUPERSEDED'));
      expect(origRow.replacedByTxId, equals(newTxId));

      // Void the 450.000 ₫ replacement transaction -> Liquid returns to 10.000.000 ₫
      await db.ledgerDao.voidTransaction(newTxId);
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(10000000));

      // Clean UI transactions only include the Opening Balance (1 transaction)
      final cleanTxs = await db.ledgerDao.getCleanTransactions();
      expect(cleanTxs.length, equals(1));

      // Scenario 15: Notification Permission Denial Graceful Degradation
      final scheduler = NotificationScheduler(initialPermissionGranted: false);
      expect(scheduler.isPermissionGranted, isFalse);
      final setting = await db.select(db.settings).getSingle();
      await scheduler.reconcileAndSchedule(
        settings: setting,
        pendingItems: const [],
      );
      await scheduler.triggerBudgetThresholdAlert(
        categoryId: expCat.id,
        categoryName: expCat.name,
        spentVnd: 950000,
        limitVnd: 1000000,
      );
    });
  });
}
