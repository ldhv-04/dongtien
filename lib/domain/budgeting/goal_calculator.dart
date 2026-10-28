import 'package:dongtien/core/money/vnd_money.dart';

/// Lifecycle status of a savings goal.
enum GoalStatus {
  /// Target fully reserved: C >= T
  achieved,

  /// Target not yet reserved and periods remaining: N > 0 and C < T
  inProgress,

  /// Target not yet reserved and deadline passed: N <= 0 and C < T
  overdue,
}

/// Evaluation result of a savings goal requirement.
class GoalEvaluationResult {
  final VndMoney targetAmount;
  final VndMoney currentReserved;
  final int remainingPeriods;
  final GoalStatus status;
  final VndMoney shortfall;
  final VndMoney requiredPerPeriod;
  final double progressRatio; // 0.0 to 1.0+

  const GoalEvaluationResult({
    required this.targetAmount,
    required this.currentReserved,
    required this.remainingPeriods,
    required this.status,
    required this.shortfall,
    required this.requiredPerPeriod,
    required this.progressRatio,
  });

  bool get isAchieved => status == GoalStatus.achieved;
  bool get isOverdue => status == GoalStatus.overdue;
  bool get isInProgress => status == GoalStatus.inProgress;
}

/// Pure Dart domain calculator for savings goal ceiling integer division.
class GoalCalculator {
  const GoalCalculator._();

  /// Calculates the required periodic contribution using integer ceiling division.
  ///
  /// Mathematical specifications:
  /// - If `currentReserved >= targetAmount`:
  ///   `status = ACHIEVED`, `requiredPerPeriod = 0 ₫`, `shortfall = 0 ₫`.
  /// - If `remainingPeriods <= 0` and `currentReserved < targetAmount`:
  ///   `status = OVERDUE`, `shortfall = targetAmount - currentReserved`,
  ///   `requiredPerPeriod = shortfall` (immediate full payment required, no division by zero).
  /// - If `remainingPeriods > 0` and `currentReserved < targetAmount`:
  ///   `status = IN_PROGRESS`, `shortfall = targetAmount - currentReserved`,
  ///   `requiredPerPeriod = ((shortfall) + remainingPeriods - 1) ~/ remainingPeriods` (ceiling integer division).
  static GoalEvaluationResult evaluateGoal({
    required VndMoney targetAmount,
    required VndMoney currentReserved,
    required int remainingPeriods,
  }) {
    if (targetAmount.isNegative) {
      throw ArgumentError.value(
        targetAmount,
        'targetAmount',
        'Target amount cannot be negative',
      );
    }
    if (currentReserved.isNegative) {
      throw ArgumentError.value(
        currentReserved,
        'currentReserved',
        'Current reserved cannot be negative',
      );
    }

    // 1. Achieved Check (C >= T)
    if (currentReserved >= targetAmount) {
      final double progress = targetAmount.isZero
          ? 1.0
          : (currentReserved.amount / targetAmount.amount);
      return GoalEvaluationResult(
        targetAmount: targetAmount,
        currentReserved: currentReserved,
        remainingPeriods: remainingPeriods,
        status: GoalStatus.achieved,
        shortfall: VndMoney.zero,
        requiredPerPeriod: VndMoney.zero,
        progressRatio: progress,
      );
    }

    // Shortfall > 0 (C < T)
    final VndMoney shortfall = targetAmount - currentReserved;
    final double progress = targetAmount.isZero
        ? 1.0
        : (currentReserved.amount / targetAmount.amount);

    // 2. Overdue Check (N <= 0)
    if (remainingPeriods <= 0) {
      return GoalEvaluationResult(
        targetAmount: targetAmount,
        currentReserved: currentReserved,
        remainingPeriods: remainingPeriods,
        status: GoalStatus.overdue,
        shortfall: shortfall,
        requiredPerPeriod: shortfall,
        progressRatio: progress,
      );
    }

    // 3. In Progress (Ceiling Integer Division): ((T - C) + N - 1) ~/ N
    final int requiredInt =
        (shortfall.amount + remainingPeriods - 1) ~/ remainingPeriods;

    return GoalEvaluationResult(
      targetAmount: targetAmount,
      currentReserved: currentReserved,
      remainingPeriods: remainingPeriods,
      status: GoalStatus.inProgress,
      shortfall: shortfall,
      requiredPerPeriod: VndMoney(requiredInt),
      progressRatio: progress,
    );
  }

  /// Calculates remaining monthly periods between [currentDate] and [targetDate].
  ///
  /// Evaluates full or partial calendar months. Returns non-positive if [targetDate] is in the past.
  static int calculateRemainingMonths(
      DateTime currentDate, DateTime targetDate) {
    final int yearDiff = targetDate.year - currentDate.year;
    final int monthDiff = targetDate.month - currentDate.month;
    final int totalMonths = yearDiff * 12 + monthDiff;

    if (totalMonths == 0 && targetDate.isAfter(currentDate)) {
      return 1;
    }
    return totalMonths;
  }
}
