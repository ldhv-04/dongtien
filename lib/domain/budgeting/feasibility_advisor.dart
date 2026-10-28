import 'package:dongtien/core/money/vnd_money.dart';
import 'goal_calculator.dart';

/// Feasibility status of the collective savings goal plan.
enum FeasibilityStatus {
  feasible,
  infeasible,
}

/// An active goal input for feasibility analysis.
class ActiveGoalItem {
  final int id;
  final String name;
  final VndMoney targetAmount;
  final VndMoney currentReserved;
  final int remainingPeriods;
  final int priority; // 1 = highest, 2 = second, etc.
  final GoalEvaluationResult evaluation;

  ActiveGoalItem({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentReserved,
    required this.remainingPeriods,
    this.priority = 1,
  }) : evaluation = GoalCalculator.evaluateGoal(
          targetAmount: targetAmount,
          currentReserved: currentReserved,
          remainingPeriods: remainingPeriods,
        );

  VndMoney get requiredPerPeriod => evaluation.requiredPerPeriod;
  VndMoney get shortfall => evaluation.shortfall;
}

/// Recommendation for an individual goal in the pruning plan.
class GoalPruningAction {
  final ActiveGoalItem goal;
  final bool shouldPause;
  final VndMoney allocatedMonthly;
  final VndMoney unmetShortfall;

  const GoalPruningAction({
    required this.goal,
    required this.shouldPause,
    required this.allocatedMonthly,
    required this.unmetShortfall,
  });
}

/// Collective evaluation of active goals against available monthly savings capacity.
class FeasibilityEvaluation {
  final FeasibilityStatus status;
  final VndMoney totalRequiredPerPeriod;
  final VndMoney monthlyCapacity;
  final VndMoney deficit; // max(0, totalRequired - monthlyCapacity)
  final List<ActiveGoalItem> activeGoals;

  const FeasibilityEvaluation({
    required this.status,
    required this.totalRequiredPerPeriod,
    required this.monthlyCapacity,
    required this.deficit,
    required this.activeGoals,
  });

  bool get isFeasible => status == FeasibilityStatus.feasible;
  bool get isInfeasible => status == FeasibilityStatus.infeasible;
}

/// Pure Dart advisor offering 3 one-tap solutions when savings goals are INFEASIBLE.
class FeasibilityAdvisor {
  const FeasibilityAdvisor._();

  /// Evaluates whether the user's active goals can be sustained by their [monthlyCapacity].
  static FeasibilityEvaluation evaluatePlan({
    required List<ActiveGoalItem> goals,
    required VndMoney monthlyCapacity,
  }) {
    VndMoney totalRequired = VndMoney.zero;
    for (final goal in goals) {
      if (!goal.evaluation.isAchieved) {
        totalRequired += goal.requiredPerPeriod;
      }
    }

    if (totalRequired <= monthlyCapacity) {
      return FeasibilityEvaluation(
        status: FeasibilityStatus.feasible,
        totalRequiredPerPeriod: totalRequired,
        monthlyCapacity: monthlyCapacity,
        deficit: VndMoney.zero,
        activeGoals: goals,
      );
    } else {
      return FeasibilityEvaluation(
        status: FeasibilityStatus.infeasible,
        totalRequiredPerPeriod: totalRequired,
        monthlyCapacity: monthlyCapacity,
        deficit: totalRequired - monthlyCapacity,
        activeGoals: goals,
      );
    }
  }

  // ===========================================================================
  // 1. ONE-TAP CALCULATOR: EXTEND DEADLINE
  // ===========================================================================

  /// Calculates new periods N' needed to achieve target T with given [allocatedMonthlyCapacity].
  ///
  /// Formula:
  /// `N' = ceil((T - C) / allocatedMonthlyCapacity) = ((T - C) + capacity - 1) ~/ capacity`.
  /// Returns 0 if already achieved (C >= T).
  /// Throws [ArgumentError] if `allocatedMonthlyCapacity <= 0` and goal is not achieved.
  static int calculateExtendedDeadline({
    required VndMoney targetAmount,
    required VndMoney currentReserved,
    required VndMoney allocatedMonthlyCapacity,
  }) {
    if (currentReserved >= targetAmount) {
      return 0;
    }
    if (allocatedMonthlyCapacity.amount <= 0) {
      throw ArgumentError.value(
        allocatedMonthlyCapacity,
        'allocatedMonthlyCapacity',
        'Cannot calculate deadline extension with zero or negative monthly capacity',
      );
    }

    final int shortfallInt = (targetAmount - currentReserved).amount;
    final int capacityInt = allocatedMonthlyCapacity.amount;

    // Integer ceiling division
    return (shortfallInt + capacityInt - 1) ~/ capacityInt;
  }

  // ===========================================================================
  // 2. ONE-TAP CALCULATOR: LOWER TARGET
  // ===========================================================================

  /// Calculates achievable target T' within original [remainingPeriods] at [allocatedMonthlyCapacity].
  ///
  /// Formula:
  /// `T' = C + N * capacity`.
  /// Clamped to original [targetAmount] (never inflated above original target)
  /// and clamped to [currentReserved] (never lowered below current savings).
  static VndMoney calculateLoweredTarget({
    required VndMoney targetAmount,
    required VndMoney currentReserved,
    required int remainingPeriods,
    required VndMoney allocatedMonthlyCapacity,
  }) {
    if (currentReserved >= targetAmount) {
      return targetAmount;
    }
    if (remainingPeriods <= 0 || allocatedMonthlyCapacity.isNegative) {
      return currentReserved;
    }

    final VndMoney achievableAddition =
        allocatedMonthlyCapacity * remainingPeriods;
    final VndMoney newTarget = currentReserved + achievableAddition;

    if (newTarget > targetAmount) {
      return targetAmount;
    }
    if (newTarget < currentReserved) {
      return currentReserved;
    }
    return newTarget;
  }

  // ===========================================================================
  // 3. ONE-TAP CALCULATOR: PAUSE LOWER-PRIORITY GOALS
  // ===========================================================================

  /// Sorts goals by priority (rank 1 = highest, then closest deadline) and allocates
  /// available [monthlyCapacity] sequentially.
  ///
  /// Goals that cannot be fully funded are flagged with `shouldPause = true`.
  static List<GoalPruningAction> recommendGoalPruning({
    required List<ActiveGoalItem> goals,
    required VndMoney monthlyCapacity,
  }) {
    final unachieved = goals.where((g) => !g.evaluation.isAchieved).toList();

    // Sort by priority (ascending: 1, 2, 3...), then remainingPeriods ascending
    unachieved.sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      if (p != 0) return p;
      return a.remainingPeriods.compareTo(b.remainingPeriods);
    });

    int remainingCapacityVnd = monthlyCapacity.amount;
    final List<GoalPruningAction> actions = [];

    for (final goal in unachieved) {
      final int needed = goal.requiredPerPeriod.amount;

      if (remainingCapacityVnd >= needed) {
        // Fully fund
        actions.add(GoalPruningAction(
          goal: goal,
          shouldPause: false,
          allocatedMonthly: goal.requiredPerPeriod,
          unmetShortfall: VndMoney.zero,
        ));
        remainingCapacityVnd -= needed;
      } else if (remainingCapacityVnd > 0) {
        // Partially funded -> recommend pause to protect higher priority goals
        actions.add(GoalPruningAction(
          goal: goal,
          shouldPause: true,
          allocatedMonthly: VndMoney(remainingCapacityVnd),
          unmetShortfall: VndMoney(needed - remainingCapacityVnd),
        ));
        remainingCapacityVnd = 0;
      } else {
        // Zero capacity remaining -> Pause
        actions.add(GoalPruningAction(
          goal: goal,
          shouldPause: true,
          allocatedMonthly: VndMoney.zero,
          unmetShortfall: goal.requiredPerPeriod,
        ));
      }
    }

    return actions;
  }
}
