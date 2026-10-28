import 'package:dongtien/core/money/vnd_money.dart';

/// Spending and refund records for a single expense category.
class CategorySpendingItem {
  final int categoryId;
  final String categoryName;
  final VndMoney grossExpense;
  final VndMoney refundCredits;

  const CategorySpendingItem({
    required this.categoryId,
    required this.categoryName,
    required this.grossExpense,
    required this.refundCredits,
  });

  /// Net expense = gross_expense - refund_credits.
  /// Can be negative if refunds exceed gross spending.
  VndMoney get netExpense => grossExpense - refundCredits;

  /// Effective expense clamped to zero: max(0, net_expense).
  VndMoney get effectiveExpense =>
      netExpense.isNegative ? VndMoney.zero : netExpense;

  /// True when refunds exceed gross expenses in this category.
  bool get isNetRecovery => netExpense.isNegative;

  /// Standard Vietnamese UI label for net recovery.
  String? get recoveryLabel => isNetRecovery ? 'Thu hồi chi phí ròng' : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySpendingItem &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          grossExpense == other.grossExpense &&
          refundCredits == other.refundCredits;

  @override
  int get hashCode => Object.hash(categoryId, grossExpense, refundCredits);
}

/// Breakdown of a category with its proportion of total positive net expenses.
class CategorySpendingBreakdown {
  final CategorySpendingItem item;
  final double percentageOfTotal; // 0.0 to 1.0

  const CategorySpendingBreakdown({
    required this.item,
    required this.percentageOfTotal,
  });

  int get categoryId => item.categoryId;
  String get categoryName => item.categoryName;
  VndMoney get grossExpense => item.grossExpense;
  VndMoney get refundCredits => item.refundCredits;
  VndMoney get netExpense => item.netExpense;
  VndMoney get effectiveExpense => item.effectiveExpense;
  bool get isNetRecovery => item.isNetRecovery;
  String? get recoveryLabel => item.recoveryLabel;
}

/// Comprehensive category spending and savings rate calculation report.
class CategorySpendingReport {
  final VndMoney grossExpense;
  final VndMoney refundCredits;
  final VndMoney netExpense;
  final VndMoney effectiveExpense;
  final VndMoney recognizedIncome;
  final VndMoney netSaving;
  final double?
      savingsRate; // null if recognizedIncome <= 0; never NaN/Infinity/0%
  final bool isNetRecovery;
  final List<CategorySpendingBreakdown> categories;

  const CategorySpendingReport({
    required this.grossExpense,
    required this.refundCredits,
    required this.netExpense,
    required this.effectiveExpense,
    required this.recognizedIncome,
    required this.netSaving,
    required this.savingsRate,
    required this.isNetRecovery,
    required this.categories,
  });

  /// Formatted UI display for savings rate.
  /// Renders "Chưa có thu nhập" if savingsRate is null.
  String get savingsRateDisplay {
    if (savingsRate == null) {
      return 'Chưa có thu nhập';
    }
    final int pct = (savingsRate! * 100).round();
    return '$pct%';
  }
}

/// Pure Dart domain calculator for category spending, net recovery, and savings rate.
class CategorySpendingCalculator {
  const CategorySpendingCalculator._();

  /// Calculates spending breakdown, net recovery, and savings rate.
  ///
  /// Mathematical specifications:
  /// - `net_expense = gross_expense - refund_credits`
  /// - `net_saving = recognized_income - net_expense`
  /// - If `net_expense < 0`, `isNetRecovery = true` and `effective_expense = max(0, net_expense)`
  /// - If `recognized_income <= 0`, `savingsRate = null` (never NaN/Infinity)
  /// - If `recognized_income > 0`:
  ///   `savingsRate = (recognized_income - max(0, net_expense)) / recognized_income`
  static CategorySpendingReport calculate({
    required List<CategorySpendingItem> categoryItems,
    required VndMoney recognizedIncome,
  }) {
    VndMoney totalGross = VndMoney.zero;
    VndMoney totalRefund = VndMoney.zero;

    for (final item in categoryItems) {
      totalGross += item.grossExpense;
      totalRefund += item.refundCredits;
    }

    final VndMoney totalNet = totalGross - totalRefund;
    final bool totalNetRecovery = totalNet.isNegative;
    final VndMoney totalEffective = totalNetRecovery ? VndMoney.zero : totalNet;

    // net_saving = recognized_income - net_expense
    final VndMoney totalNetSaving = recognizedIncome - totalNet;

    // Savings rate calculation
    double? rate;
    if (recognizedIncome.amount <= 0) {
      rate = null;
    } else {
      // (recognized_income - max(0, net_expense)) / recognized_income
      rate = (recognizedIncome.amount - totalEffective.amount) /
          recognizedIncome.amount;
    }

    // Category percentage breakdown based on positive effective expense
    int totalPositiveCategoryVnd = 0;
    for (final item in categoryItems) {
      totalPositiveCategoryVnd += item.effectiveExpense.amount;
    }

    final List<CategorySpendingBreakdown> breakdowns = [];
    for (final item in categoryItems) {
      double pct = 0.0;
      if (totalPositiveCategoryVnd > 0 && !item.isNetRecovery) {
        pct = item.effectiveExpense.amount / totalPositiveCategoryVnd;
      }
      breakdowns.add(CategorySpendingBreakdown(
        item: item,
        percentageOfTotal: pct,
      ));
    }

    return CategorySpendingReport(
      grossExpense: totalGross,
      refundCredits: totalRefund,
      netExpense: totalNet,
      effectiveExpense: totalEffective,
      recognizedIncome: recognizedIncome,
      netSaving: totalNetSaving,
      savingsRate: rate,
      isNetRecovery: totalNetRecovery,
      categories: breakdowns,
    );
  }
}
