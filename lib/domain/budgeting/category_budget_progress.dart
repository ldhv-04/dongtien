import 'package:dongtien/core/money/vnd_money.dart';

/// Health status of a monthly category budget.
enum BudgetStatus {
  /// Spent < alertThresholdPct (e.g. < 80%)
  normal,

  /// alertThresholdPct <= Spent <= 100%
  warning,

  /// Spent > 100%
  exceeded,
}

/// Evaluation of an individual category's budget progress in a month.
class CategoryBudgetProgress {
  final int categoryId;
  final String categoryName;
  final int yearMonth; // e.g. 202610
  final VndMoney limitVnd;
  final VndMoney spentVnd; // max(0, net_expense)
  final int alertThresholdPct; // default 80 (1..100)

  const CategoryBudgetProgress({
    required this.categoryId,
    required this.categoryName,
    required this.yearMonth,
    required this.limitVnd,
    required this.spentVnd,
    this.alertThresholdPct = 80,
  });

  /// Remaining spendable amount = limitVnd - spentVnd.
  /// Can be negative if over budget.
  VndMoney get remainingVnd => limitVnd - spentVnd;

  /// True if spending exceeded the budget limit.
  bool get isExceeded => spentVnd > limitVnd;

  /// Spending progress ratio (e.g. 0.75 for 75%).
  double get spentRatio =>
      limitVnd.isZero ? 1.0 : (spentVnd.amount / limitVnd.amount);

  /// Whole integer percentage of budget used (e.g. 75).
  int get spentPercentageInt =>
      limitVnd.isZero ? 100 : ((spentVnd.amount * 100) ~/ limitVnd.amount);

  /// Status of the budget based on the alert threshold.
  BudgetStatus get status {
    if (spentVnd > limitVnd) {
      return BudgetStatus.exceeded;
    }
    final int thresholdVnd = (limitVnd.amount * alertThresholdPct) ~/ 100;
    if (spentVnd.amount >= thresholdVnd) {
      return BudgetStatus.warning;
    }
    return BudgetStatus.normal;
  }
}

/// Aggregated monthly budget progress across all categories.
class MonthlyBudgetSummary {
  final int yearMonth;
  final List<CategoryBudgetProgress> categoryProgresses;

  const MonthlyBudgetSummary({
    required this.yearMonth,
    required this.categoryProgresses,
  });

  VndMoney get totalLimitVnd => categoryProgresses.fold(
        VndMoney.zero,
        (acc, b) => acc + b.limitVnd,
      );

  VndMoney get totalSpentVnd => categoryProgresses.fold(
        VndMoney.zero,
        (acc, b) => acc + b.spentVnd,
      );

  VndMoney get totalRemainingVnd => totalLimitVnd - totalSpentVnd;

  double get overallSpentRatio => totalLimitVnd.isZero
      ? 0.0
      : (totalSpentVnd.amount / totalLimitVnd.amount);

  int get exceededCount =>
      categoryProgresses.where((b) => b.status == BudgetStatus.exceeded).length;

  int get warningCount =>
      categoryProgresses.where((b) => b.status == BudgetStatus.warning).length;
}

/// Pure Dart domain tracker for monthly category budgets.
class CategoryBudgetTracker {
  const CategoryBudgetTracker._();

  /// Evaluates progress for an individual category budget.
  ///
  /// Effective spent is computed as `max(0, netExpense)` where
  /// `netExpense = grossExpense - refundCredits`.
  static CategoryBudgetProgress evaluateCategoryBudget({
    required int categoryId,
    required String categoryName,
    required int yearMonth,
    required VndMoney limitVnd,
    required VndMoney grossExpense,
    required VndMoney refundCredits,
    int alertThresholdPct = 80,
  }) {
    if (limitVnd.amount <= 0) {
      throw ArgumentError.value(
        limitVnd,
        'limitVnd',
        'Budget limit must be strictly positive (> 0 ₫)',
      );
    }
    if (alertThresholdPct < 1 || alertThresholdPct > 100) {
      throw ArgumentError.value(
        alertThresholdPct,
        'alertThresholdPct',
        'Threshold must be between 1 and 100',
      );
    }

    final VndMoney netExpense = grossExpense - refundCredits;
    final VndMoney effectiveSpent =
        netExpense.isNegative ? VndMoney.zero : netExpense;

    return CategoryBudgetProgress(
      categoryId: categoryId,
      categoryName: categoryName,
      yearMonth: yearMonth,
      limitVnd: limitVnd,
      spentVnd: effectiveSpent,
      alertThresholdPct: alertThresholdPct,
    );
  }

  /// Evaluates the aggregated monthly budget summary.
  static MonthlyBudgetSummary evaluateSummary({
    required int yearMonth,
    required List<CategoryBudgetProgress> categoryProgresses,
  }) {
    return MonthlyBudgetSummary(
      yearMonth: yearMonth,
      categoryProgresses: categoryProgresses,
    );
  }
}
