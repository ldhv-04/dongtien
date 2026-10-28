import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/category_budget_progress.dart';
import 'package:dongtien/domain/budgeting/category_spending_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategorySpendingCalculator — Net Recovery & Savings Rate Invariants',
      () {
    test(
        'Standard spending report computes gross, refund, net, and savings rate',
        () {
      final food = CategorySpendingItem(
        categoryId: 1,
        categoryName: 'Ăn uống',
        grossExpense: VndMoney(3000000),
        refundCredits: VndMoney(500000), // Net = 2.500.000 ₫
      );

      final travel = CategorySpendingItem(
        categoryId: 2,
        categoryName: 'Di chuyển',
        grossExpense: VndMoney(1500000),
        refundCredits: VndMoney.zero, // Net = 1.500.000 ₫
      );

      final report = CategorySpendingCalculator.calculate(
        categoryItems: [food, travel],
        recognizedIncome: VndMoney(10000000), // 10.000.000 ₫
      );

      expect(report.grossExpense, equals(VndMoney(4500000)));
      expect(report.refundCredits, equals(VndMoney(500000)));
      expect(report.netExpense, equals(VndMoney(4000000)));
      expect(report.effectiveExpense, equals(VndMoney(4000000)));
      expect(report.netSaving, equals(VndMoney(6000000))); // 10M - 4M = 6M
      expect(report.isNetRecovery, isFalse);

      // Savings rate = (10M - 4M) / 10M = 0.6 (60%)
      expect(report.savingsRate, closeTo(0.60, 0.001));
      expect(report.savingsRateDisplay, equals('60%'));

      // Category proportions: total positive = 4M. Food = 2.5M / 4M = 62.5%
      expect(report.categories[0].percentageOfTotal, closeTo(0.625, 0.001));
      expect(report.categories[1].percentageOfTotal, closeTo(0.375, 0.001));
    });

    test(
        'Section 7.1: Net Recovery (Refunds > Expenses) sets Thu hồi chi phí ròng',
        () {
      final shopping = CategorySpendingItem(
        categoryId: 3,
        categoryName: 'Mua sắm',
        grossExpense: VndMoney(500000),
        refundCredits:
            VndMoney(1500000), // Refund > Gross -> Net = -1.000.000 ₫
      );

      expect(shopping.isNetRecovery, isTrue);
      expect(shopping.recoveryLabel, equals('Thu hồi chi phí ròng'));
      expect(shopping.effectiveExpense, equals(VndMoney.zero));

      final report = CategorySpendingCalculator.calculate(
        categoryItems: [shopping],
        recognizedIncome: VndMoney(5000000),
      );

      expect(report.isNetRecovery, isTrue);
      expect(report.netExpense, equals(VndMoney(-1000000)));
      // Effective expense is clamped to 0 ₫ so savings rate does NOT exceed 100%
      expect(report.effectiveExpense, equals(VndMoney.zero));
      // Net saving increases by refund: 5M - (-1M) = 6M
      expect(report.netSaving, equals(VndMoney(6000000)));
      expect(report.savingsRate, equals(1.0)); // 100%
      expect(report.savingsRateDisplay, equals('100%'));
    });

    test(
        'Section 7.2: Zero or negative income returns null savings rate with Chưa có thu nhập',
        () {
      final food = CategorySpendingItem(
        categoryId: 1,
        categoryName: 'Ăn uống',
        grossExpense: VndMoney(1000000),
        refundCredits: VndMoney.zero,
      );

      // 1. Zero income
      final zeroIncomeReport = CategorySpendingCalculator.calculate(
        categoryItems: [food],
        recognizedIncome: VndMoney.zero,
      );
      expect(zeroIncomeReport.savingsRate, isNull);
      expect(zeroIncomeReport.savingsRateDisplay, equals('Chưa có thu nhập'));

      // 2. Negative income (e.g. adjustments)
      final negativeIncomeReport = CategorySpendingCalculator.calculate(
        categoryItems: [food],
        recognizedIncome: VndMoney(-500000),
      );
      expect(negativeIncomeReport.savingsRate, isNull);
      expect(
          negativeIncomeReport.savingsRateDisplay, equals('Chưa có thu nhập'));
    });
  });

  group('CategoryBudgetTracker — Thresholds & Warning States', () {
    test('Normal, warning, and exceeded status based on 80% threshold', () {
      // Normal: 50% spent
      final normal = CategoryBudgetTracker.evaluateCategoryBudget(
        categoryId: 1,
        categoryName: 'Ăn uống',
        yearMonth: 202610,
        limitVnd: VndMoney(4000000),
        grossExpense: VndMoney(2000000),
        refundCredits: VndMoney.zero,
        alertThresholdPct: 80,
      );
      expect(normal.status, equals(BudgetStatus.normal));
      expect(normal.isExceeded, isFalse);
      expect(normal.remainingVnd, equals(VndMoney(2000000)));
      expect(normal.spentPercentageInt, equals(50));

      // Warning: 85% spent (>= 80%)
      final warning = CategoryBudgetTracker.evaluateCategoryBudget(
        categoryId: 1,
        categoryName: 'Ăn uống',
        yearMonth: 202610,
        limitVnd: VndMoney(4000000),
        grossExpense: VndMoney(3400000),
        refundCredits: VndMoney.zero,
        alertThresholdPct: 80,
      );
      expect(warning.status, equals(BudgetStatus.warning));
      expect(warning.isExceeded, isFalse);
      expect(warning.remainingVnd, equals(VndMoney(600000)));
      expect(warning.spentPercentageInt, equals(85));

      // Exceeded: 110% spent (> 100%)
      final exceeded = CategoryBudgetTracker.evaluateCategoryBudget(
        categoryId: 1,
        categoryName: 'Ăn uống',
        yearMonth: 202610,
        limitVnd: VndMoney(4000000),
        grossExpense: VndMoney(4500000),
        refundCredits: VndMoney(100000), // Net = 4.4M > 4.0M
        alertThresholdPct: 80,
      );
      expect(exceeded.status, equals(BudgetStatus.exceeded));
      expect(exceeded.isExceeded, isTrue);
      expect(exceeded.remainingVnd, equals(VndMoney(-400000)));
      expect(exceeded.spentPercentageInt, equals(110));
    });

    test('MonthlyBudgetSummary aggregates multiple category budgets', () {
      final b1 = CategoryBudgetTracker.evaluateCategoryBudget(
        categoryId: 1,
        categoryName: 'Ăn uống',
        yearMonth: 202610,
        limitVnd: VndMoney(5000000),
        grossExpense: VndMoney(4200000), // 84% -> Warning
        refundCredits: VndMoney.zero,
      );

      final b2 = CategoryBudgetTracker.evaluateCategoryBudget(
        categoryId: 2,
        categoryName: 'Mua sắm',
        yearMonth: 202610,
        limitVnd: VndMoney(2000000),
        grossExpense: VndMoney(2500000), // 125% -> Exceeded
        refundCredits: VndMoney.zero,
      );

      final summary = CategoryBudgetTracker.evaluateSummary(
        yearMonth: 202610,
        categoryProgresses: [b1, b2],
      );

      expect(summary.totalLimitVnd, equals(VndMoney(7000000)));
      expect(summary.totalSpentVnd, equals(VndMoney(6700000)));
      expect(summary.totalRemainingVnd, equals(VndMoney(300000)));
      expect(summary.warningCount, equals(1));
      expect(summary.exceededCount, equals(1));
    });
  });
}
