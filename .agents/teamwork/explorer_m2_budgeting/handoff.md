# HANDOFF REPORT: DOMAIN BUDGETING & SAVINGS GOALS ENGINES (M2)

> **Agent**: `explorer_m2_budgeting`  
> **Milestone**: M2 (Deterministic Domain Engines)  
> **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_budgeting`  
> **Target Package**: `dongtien` (`vn.dongtien`)  
> **Date**: 2026-10-27T18:57:00Z  

---

## 1. OBSERVATION

The following facts, contracts, and code structures were directly observed in the workspace:

### 1.1 Architectural Invariants & Clean Architecture (`AGENTS.md`)
- **Monetary Representation (lines 20-35)**:
  > "All monetary values are 64-bit signed integers (`int` in Dart) representing whole `VND`. Use the `VndMoney` value type from `lib/core/money/vnd_money.dart`... max_Safe_VND = 9_000_000_000_000_000. Any transaction, multiplication, or aggregation exceeding max_Safe_VND throws a `VndOverflowException`."
- **Layer Boundary (lines 100-112)**:
  > "Domain (`lib/domain/`): Pure Dart only. Zero imports from `package:flutter/*`, `package:drift/*`, or `package:flutter_riverpod/*`. Models are immutable plain Dart classes."
- **File Ownership & Phase Gate (lines 142-160)**:
  > "Sequential Gate Requirement: The Drift database schema (`app_database.g.dart`) and all pure domain engines MUST compile and pass 100% of unit and database invariant tests before parallel UI feature workers are spawned."

### 1.2 Mathematical Specifications (`docs/ARCHITECTURE_AND_RULES.md`)
- **Category Spending & Savings Rate (Section 7, lines 289-309)**:
  > "For any reporting interval $[start\_ms, end\_ms)$:  
  > - $\text{gross\_expense} = \sum \text{debit\_vnd on EXPENSE accounts}$  
  > - $\text{refund\_credits} = \sum \text{credit\_vnd on EXPENSE accounts}$  
  > - $\text{net\_expense} = \text{gross\_expense} - \text{refund\_credits}$  
  > - $\text{recognized\_income} = \sum (\text{credit\_vnd} - \text{debit\_vnd}) \text{ on INCOME accounts}$  
  > - $\text{net\_saving} = \text{recognized\_income} - \text{net\_expense}$  
  > 
  > **7.1 Net Recovery Handling**:  
  > If refunds in a period exceed gross expenses ($\text{net\_expense} < 0$), the category is marked as **'Thu hồi chi phí ròng'** (Net Recovery). For savings rate calculation: $\text{effective\_expense} = \max(0, \text{net\_expense})$.  
  > 
  > **7.2 Savings Rate Calculation**:  
  > - If $\text{recognized\_income} \le 0$: $\text{saving\_rate} = \text{null}$. UI renders `'Chưa có thu nhập'` (never displays `NaN`, `-Infinity`, or `0%`).  
  > - If $\text{recognized\_income} > 0$: $\text{saving\_rate} = \frac{\text{recognized\_income} - \max(0, \text{net\_expense})}{\text{recognized\_income}}$."

- **Savings Goals & Feasibility Advisor (Section 8, lines 311-329)**:
  > "**8.1 Ceiling Integer Division Math**:  
  > For a savings goal backed by an envelope with target $T$, current reserved balance $C$, and $N$ remaining budgeting periods:  
  > - If $C \ge T$: Status is `ACHIEVED`, $\text{required\_per\_period} = 0$.  
  > - If $N \le 0$ and $C < T$: Status is `OVERDUE`, $\text{shortfall} = T - C$ (no division by zero).  
  > - If $N > 0$ and $C < T$: $\text{required\_per\_period} = ((T - C) + N - 1) \mathbin{\sim/} N$.  
  > 
  > **8.2 Feasibility Advisor Engine**:  
  > If $\sum \text{required\_per\_period of all active goals} > \text{available\_to\_allocate}$ (or average monthly $\text{net\_saving}$):  
  > - Status is flagged as `INFEASIBLE`.  
  > - The UI displays 3 one-tap calculators:  
  >   1. **Extend Deadline**: $N' = \lceil (T - C) / \text{monthly\_capacity} \rceil$.  
  >   2. **Lower Target**: $T' = C + N \times \text{monthly\_capacity}$.  
  >   3. **Pause Goals**: Rank goals by `priority`, fund highest-priority goals first, and recommend pausing remaining goals."

### 1.3 Database Schema & Persistence Contract (`lib/core/database/app_database.dart`)
- **`Envelopes` Table (lines 104-124)**:
  `id` (int PK), `name` (text), `policy` (text: 'PROTECTED' | 'FLEXIBLE'), `reservedBalanceVnd` (int, default 0), `targetAmountVnd` (int nullable), `targetDateMs` (int nullable), `periodLimitVnd` (int nullable), `priority` (int, default 1, rank 1 = highest).
- **`CategoryBudgets` Table (lines 162-181)**:
  `id` (int PK), `categoryId` (int FK), `yearMonth` (int, e.g. 202610), `limitVnd` (int > 0), `alertThresholdPct` (int, default 80, 1..100). Constraint: unique(`categoryId`, `yearMonth`).
- **`Settings` Table (lines 222-246)**:
  `minimumCashBufferVnd` (int, default 0), `periodStartDay` (int 1..31).

### 1.4 Current State of `lib/domain/`
- Directory `lib/domain/` has not yet been populated with code. Milestone M2 is responsible for authoring the pure Dart domain engines.

---

## 2. LOGIC CHAIN

1. **Decoupling Domain from Persistence & Presentation**:
   Per Clean Architecture rules in `AGENTS.md` §2 and `PROJECT.md` §1, the domain services must operate exclusively on pure Dart data structures and `VndMoney`. They must receive raw financial figures or lightweight domain value objects, perform immutable math, and return typed results.

2. **Integer VND Safety & No Division by Zero**:
   Floating-point types (`double`) are strictly forbidden for monetary quantities (VND amounts). `double` is used exclusively for ratios/percentages (`savingsRate`, `spentPercentage`).
   Whenever dividing by remaining periods $N$, monthly capacity $M$, or budget limit $L$, the domain engines must guard against non-positive divisors:
   - For goal requirements, if $N \le 0$, the goal status transitions to `OVERDUE`, returning exact shortfall without dividing by zero.
   - For savings rate, if `recognizedIncome <= 0`, the engine returns `null` instead of performing division, preventing `NaN`, `Infinity`, or negative infinity.
   - For ceiling integer division, $\lceil A / B \rceil$ for integers $A \ge 0, B > 0$ is computed exactly as `((A) + B - 1) ~/ B`.

3. **Net Recovery Invariant**:
   If refunds exceed expenses in a period ($\text{net\_expense} < 0$), setting $\text{effective\_expense} = \max(0, \text{net\_expense}) = 0$ prevents the savings rate from artificially exceeding 100% or distorting budget progress calculations. Furthermore, the UI string `"Thu hồi chi phí ròng"` must be exposed deterministically on the category breakdown.

4. **Multi-Goal Prioritization for Feasibility**:
   When multiple savings goals exceed available monthly capacity, goals are prioritized by `priority` (lower integer = higher priority, e.g., 1 precedes 2). Goals with equal priority are ordered by closest deadline. Capacity is allocated sequentially; once capacity is exhausted, remaining goals are flagged for recommended pausing.

---

## 3. DETAILED IMPLEMENTATION BLUEPRINT

### 3.1 Category Spending & Savings Rate Engine
**File Path**: `lib/domain/budgeting/category_spending_calculator.dart`

#### Design & Contract:
```dart
import 'package:dongtien/core/money/vnd_money.dart';

/// Represents spending and refund data for a single expense category.
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

/// Breakdown of a category with its proportion of positive net expenses.
class CategorySpendingBreakdown {
  final CategorySpendingItem item;
  final double percentageOfTotal; // 0.0 to 1.0 (or 0.0 if total expense is 0)

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

/// Comprehensive financial spending and savings rate report.
class CategorySpendingReport {
  final VndMoney grossExpense;
  final VndMoney refundCredits;
  final VndMoney netExpense;
  final VndMoney effectiveExpense;
  final VndMoney recognizedIncome;
  final VndMoney netSaving;
  final double? savingsRate; // null if recognizedIncome <= 0; never NaN/Infinity/0%
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

  /// UI helper string for savings rate.
  /// Renders "Chưa có thu nhập" if savingsRate is null.
  String get savingsRateDisplay {
    if (savingsRate == null) {
      return 'Chưa có thu nhập';
    }
    final int pct = (savingsRate! * 100).round();
    return '$pct%';
  }
}

/// Pure domain calculator for category spending and savings rate.
class CategorySpendingCalculator {
  const CategorySpendingCalculator._();

  /// Calculates spending breakdown, net recovery, and savings rate.
  ///
  /// Invariants:
  /// - `net_expense = gross_expense - refund_credits`
  /// - `net_saving = recognized_income - net_expense`
  /// - If `net_expense < 0`, `isNetRecovery = true` and `effective_expense = max(0, net_expense)`
  /// - If `recognized_income <= 0`, `savingsRate = null` (never NaN/Infinity)
  /// - If `recognized_income > 0`, `savingsRate = (recognized_income - max(0, net_expense)) / recognized_income`
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
    final VndMoney totalEffective =
        totalNetRecovery ? VndMoney.zero : totalNet;

    // net_saving = recognized_income - net_expense
    final VndMoney totalNetSaving = recognizedIncome - totalNet;

    // Savings rate calculation
    double? rate;
    if (recognizedIncome.amount <= 0) {
      rate = null;
    } else {
      // (income - max(0, net_expense)) / income
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
```

---

### 3.2 Savings Goal Ceiling Division Engine
**File Path**: `lib/domain/budgeting/goal_calculator.dart`

#### Design & Contract:
```dart
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

/// Result of evaluating a savings goal requirement.
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

/// Pure domain calculator for savings goal ceiling integer division.
class GoalCalculator {
  const GoalCalculator._();

  /// Calculates the required periodic contribution using integer ceiling division.
  ///
  /// Invariants:
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
      throw ArgumentError.value(targetAmount, 'targetAmount', 'Target amount cannot be negative');
    }
    if (currentReserved.isNegative) {
      throw ArgumentError.value(currentReserved, 'currentReserved', 'Current reserved cannot be negative');
    }

    // 1. Achieved Check
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

    // Shortfall > 0
    final VndMoney shortfall = targetAmount - currentReserved;
    final double progress = targetAmount.isZero
        ? 1.0
        : (currentReserved.amount / targetAmount.amount);

    // 2. Overdue Check
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

    // 3. In Progress (Ceiling Integer Division)
    // Formula: ((T - C) + N - 1) ~/ N
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

  /// Helper to calculate remaining monthly periods from two dates.
  ///
  /// Evaluates full or partial calendar months between [currentDate] and [targetDate].
  /// Returns negative or zero if [targetDate] is in the past.
  static int calculateRemainingMonths(DateTime currentDate, DateTime targetDate) {
    final int yearDiff = targetDate.year - currentDate.year;
    final int monthDiff = targetDate.month - currentDate.month;
    final int totalMonths = yearDiff * 12 + monthDiff;

    // If target day has not passed in target month, count current month
    if (totalMonths == 0 && targetDate.isAfter(currentDate)) {
      return 1;
    }
    return totalMonths;
  }
}
```

---

### 3.3 Feasibility Advisor Engine
**File Path**: `lib/domain/budgeting/feasibility_advisor.dart`

#### Design & Contract:
```dart
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

/// Result of evaluating collective goals against available monthly savings capacity.
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

/// One-tap calculator recommendations when a plan is INFEASIBLE.
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
    // Exclude already achieved goals
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
        // Partially funded or recommend pause
        // In DongTien, if a goal cannot be fully funded per period, we recommend pausing it
        // so that higher-priority goals receive full funding without failure.
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
```

---

### 3.4 Category Budgets: Monthly Budget Progress Tracking
**File Path**: `lib/domain/budgeting/category_budget_tracker.dart`

#### Design & Contract:
```dart
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
  double get spentRatio => limitVnd.isZero
      ? 1.0
      : (spentVnd.amount / limitVnd.amount);

  /// Whole integer percentage of budget used (e.g. 75).
  int get spentPercentageInt => limitVnd.isZero
      ? 100
      : ((spentVnd.amount * 100) ~/ limitVnd.amount);

  /// Status of the budget.
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

/// Pure domain tracker for monthly category budgets.
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
      throw ArgumentError.value(limitVnd, 'limitVnd', 'Budget limit must be strictly positive (> 0 ₫)');
    }
    if (alertThresholdPct < 1 || alertThresholdPct > 100) {
      throw ArgumentError.value(alertThresholdPct, 'alertThresholdPct', 'Threshold must be between 1 and 100');
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
```

---

## 4. CONCRETE UNIT TEST PLAN

### 4.1 Unit Test Suite 1: `test/unit/category_spending_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/category_spending_calculator.dart';

void main() {
  group('CategorySpendingCalculator & Savings Rate Engine', () {
    test('Scenario 2 & 3 baseline: income 20M, expense 100k -> 99.5% savings rate', () {
      final items = [
        CategorySpendingItem(
          categoryId: 1,
          categoryName: 'Ăn uống',
          grossExpense: VndMoney(100000),
          refundCredits: VndMoney.zero,
        ),
      ];

      final report = CategorySpendingCalculator.calculate(
        categoryItems: items,
        recognizedIncome: VndMoney(20000000),
      );

      expect(report.grossExpense, equals(VndMoney(100000)));
      expect(report.refundCredits, equals(VndMoney.zero));
      expect(report.netExpense, equals(VndMoney(100000)));
      expect(report.effectiveExpense, equals(VndMoney(100000)));
      expect(report.recognizedIncome, equals(VndMoney(20000000)));
      expect(report.netSaving, equals(VndMoney(19900000)));
      expect(report.isNetRecovery, isFalse);
      expect(report.savingsRate, closeTo(0.995, 0.0001));
      expect(report.savingsRateDisplay, equals('100%')); // rounded for display
      expect(report.categories.first.percentageOfTotal, equals(1.0));
      expect(report.categories.first.recoveryLabel, isNull);
    });

    test('Zero expenses, positive income -> 100% savings rate', () {
      final report = CategorySpendingCalculator.calculate(
        categoryItems: [],
        recognizedIncome: VndMoney(15000000),
      );

      expect(report.netExpense, equals(VndMoney.zero));
      expect(report.effectiveExpense, equals(VndMoney.zero));
      expect(report.netSaving, equals(VndMoney(15000000)));
      expect(report.savingsRate, equals(1.0));
      expect(report.savingsRateDisplay, equals('100%'));
    });

    test('Scenario 8 refund handling: gross 600k, refund 50k -> net 550k', () {
      final items = [
        CategorySpendingItem(
          categoryId: 1,
          categoryName: 'Mua sắm',
          grossExpense: VndMoney(600000),
          refundCredits: VndMoney(50000),
        ),
      ];

      final report = CategorySpendingCalculator.calculate(
        categoryItems: items,
        recognizedIncome: VndMoney(20000000),
      );

      expect(report.grossExpense, equals(VndMoney(600000)));
      expect(report.refundCredits, equals(VndMoney(50000)));
      expect(report.netExpense, equals(VndMoney(550000)));
      expect(report.effectiveExpense, equals(VndMoney(550000)));
      expect(report.netSaving, equals(VndMoney(19450000)));
      expect(report.savingsRate, closeTo(19450000 / 20000000, 0.0001));
    });

    test('Net Recovery: refunds exceed gross expense -> labeled "Thu hồi chi phí ròng"', () {
      final items = [
        CategorySpendingItem(
          categoryId: 2,
          categoryName: 'Di chuyển',
          grossExpense: VndMoney(100000),
          refundCredits: VndMoney(300000), // 200k net recovery
        ),
      ];

      final report = CategorySpendingCalculator.calculate(
        categoryItems: items,
        recognizedIncome: VndMoney(20000000),
      );

      expect(report.netExpense, equals(VndMoney(-200000)));
      expect(report.isNetRecovery, isTrue);
      expect(report.effectiveExpense, equals(VndMoney.zero));
      expect(report.categories.first.isNetRecovery, isTrue);
      expect(report.categories.first.recoveryLabel, equals('Thu hồi chi phí ròng'));

      // Net saving increases with net recovery: 20M - (-200k) = 20.2M
      expect(report.netSaving, equals(VndMoney(20200000)));

      // Effective expense clamp to 0 ensures savings rate does not artificially exceed 100%
      expect(report.savingsRate, equals(1.0));
      expect(report.savingsRateDisplay, equals('100%'));
    });

    test('Zero income -> returns null, renders "Chưa có thu nhập", never NaN/Infinity/0%', () {
      final items = [
        CategorySpendingItem(
          categoryId: 1,
          categoryName: 'Ăn uống',
          grossExpense: VndMoney(500000),
          refundCredits: VndMoney.zero,
        ),
      ];

      final reportZeroIncome = CategorySpendingCalculator.calculate(
        categoryItems: items,
        recognizedIncome: VndMoney.zero,
      );

      expect(reportZeroIncome.savingsRate, isNull);
      expect(reportZeroIncome.savingsRateDisplay, equals('Chưa có thu nhập'));
      expect(reportZeroIncome.savingsRate?.isNaN ?? false, isFalse);
    });

    test('Negative income (corrections exceed income) -> returns null', () {
      final report = CategorySpendingCalculator.calculate(
        categoryItems: [],
        recognizedIncome: VndMoney(-1000000),
      );

      expect(report.savingsRate, isNull);
      expect(report.savingsRateDisplay, equals('Chưa có thu nhập'));
    });

    test('Dissaving: expense exceeds income -> negative savings rate', () {
      final items = [
        CategorySpendingItem(
          categoryId: 1,
          categoryName: 'Nhà cửa',
          grossExpense: VndMoney(15000000),
          refundCredits: VndMoney.zero,
        ),
      ];

      final report = CategorySpendingCalculator.calculate(
        categoryItems: items,
        recognizedIncome: VndMoney(10000000),
      );

      // (10M - 15M) / 10M = -0.5 (-50%)
      expect(report.savingsRate, equals(-0.5));
      expect(report.savingsRateDisplay, equals('-50%'));
      expect(report.netSaving, equals(VndMoney(-5000000)));
    });

    test('Multi-category percentage breakdown correctly ignores net recovery categories', () {
      final items = [
        CategorySpendingItem(
          categoryId: 1,
          categoryName: 'Ăn uống',
          grossExpense: VndMoney(800000),
          refundCredits: VndMoney.zero,
        ),
        CategorySpendingItem(
          categoryId: 2,
          categoryName: 'Mua sắm',
          grossExpense: VndMoney(200000),
          refundCredits: VndMoney.zero,
        ),
        CategorySpendingItem(
          categoryId: 3,
          categoryName: 'Di chuyển',
          grossExpense: VndMoney(50000),
          refundCredits: VndMoney(150000), // -100k net recovery
        ),
      ];

      final report = CategorySpendingCalculator.calculate(
        categoryItems: items,
        recognizedIncome: VndMoney(20000000),
      );

      expect(report.categories[0].percentageOfTotal, closeTo(0.8, 0.0001));
      expect(report.categories[1].percentageOfTotal, closeTo(0.2, 0.0001));
      expect(report.categories[2].percentageOfTotal, equals(0.0));
    });

    test('64-bit safe boundary: 9 quadrillion VND does not overflow', () {
      final items = [
        CategorySpendingItem(
          categoryId: 1,
          categoryName: 'Tài sản',
          grossExpense: VndMoney(1000000000000000), // 1 quadrillion
          refundCredits: VndMoney.zero,
        ),
      ];

      final report = CategorySpendingCalculator.calculate(
        categoryItems: items,
        recognizedIncome: VndMoney(9000000000000000), // 9 quadrillion
      );

      expect(report.netSaving, equals(VndMoney(8000000000000000)));
      expect(report.savingsRate, closeTo(8 / 9, 0.000001));
    });
  });
}
```

---

### 4.2 Unit Test Suite 2: `test/unit/goal_ceiling_division_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/goal_calculator.dart';

void main() {
  group('GoalCalculator Ceiling Integer Division Engine', () {
    test('Exact divisibility: 9M target, 0 reserved, 9 periods -> 1.000.000 ₫/period', () {
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(9000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 9,
      );

      expect(result.status, equals(GoalStatus.inProgress));
      expect(result.shortfall, equals(VndMoney(9000000)));
      expect(result.requiredPerPeriod, equals(VndMoney(1000000)));
      expect(result.progressRatio, equals(0.0));
    });

    test('Inexact divisibility with ceiling: 10M target, 0 reserved, 3 periods -> 3.333.334 ₫/period', () {
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 3,
      );

      // (10.000.000 + 3 - 1) ~/ 3 = 10.000.002 ~/ 3 = 3.333.334
      expect(result.status, equals(GoalStatus.inProgress));
      expect(result.shortfall, equals(VndMoney(10000000)));
      expect(result.requiredPerPeriod, equals(VndMoney(3333334)));

      // Verification: 3 * 3.333.334 = 10.000.002 >= 10.000.000 (Target guaranteed reached!)
      expect(result.requiredPerPeriod.amount * 3, greaterThanOrEqualTo(10000000));
    });

    test('Inexact divisibility with remainder 1: 10M target, 0 reserved, 7 periods -> 1.428.572 ₫', () {
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 7,
      );

      // (10.000.000 + 6) ~/ 7 = 10.000.006 ~/ 7 = 1.428.572
      expect(result.requiredPerPeriod, equals(VndMoney(1428572)));
      expect(result.requiredPerPeriod.amount * 7, greaterThanOrEqualTo(10000000));
    });

    test('Minimal unit: 1 VND target, 0 reserved, 100 periods -> 1 ₫/period', () {
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(1),
        currentReserved: VndMoney.zero,
        remainingPeriods: 100,
      );

      // (1 + 99) ~/ 100 = 1 ₫
      expect(result.requiredPerPeriod, equals(VndMoney(1)));
    });

    test('Single remaining period: N = 1 -> required equals exact shortfall', () {
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(6500000),
        remainingPeriods: 1,
      );

      expect(result.status, equals(GoalStatus.inProgress));
      expect(result.shortfall, equals(VndMoney(3500000)));
      expect(result.requiredPerPeriod, equals(VndMoney(3500000)));
    });

    test('Achieved target: C >= T -> status ACHIEVED, required = 0 ₫', () {
      final exact = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(10000000),
        remainingPeriods: 5,
      );
      expect(exact.status, equals(GoalStatus.achieved));
      expect(exact.requiredPerPeriod, equals(VndMoney.zero));
      expect(exact.shortfall, equals(VndMoney.zero));
      expect(exact.progressRatio, equals(1.0));

      final surplus = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(12000000),
        remainingPeriods: 2,
      );
      expect(surplus.status, equals(GoalStatus.achieved));
      expect(surplus.requiredPerPeriod, equals(VndMoney.zero));
      expect(surplus.progressRatio, equals(1.2));
    });

    test('Achieved target even when N <= 0', () {
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(5000000),
        currentReserved: VndMoney(5000000),
        remainingPeriods: 0,
      );
      expect(result.status, equals(GoalStatus.achieved));
      expect(result.requiredPerPeriod, equals(VndMoney.zero));
    });

    test('Overdue goal: N <= 0 and C < T -> status OVERDUE, shortfall = T - C, no division by zero', () {
      final zeroPeriods = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(4000000),
        remainingPeriods: 0,
      );
      expect(zeroPeriods.status, equals(GoalStatus.overdue));
      expect(zeroPeriods.shortfall, equals(VndMoney(6000000)));
      expect(zeroPeriods.requiredPerPeriod, equals(VndMoney(6000000)));

      final negativePeriods = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(4000000),
        remainingPeriods: -3,
      );
      expect(negativePeriods.status, equals(GoalStatus.overdue));
      expect(negativePeriods.shortfall, equals(VndMoney(6000000)));
      expect(negativePeriods.requiredPerPeriod, equals(VndMoney(6000000)));
    });

    test('Zero target and zero reserved -> status ACHIEVED', () {
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney.zero,
        currentReserved: VndMoney.zero,
        remainingPeriods: 10,
      );
      expect(result.status, equals(GoalStatus.achieved));
      expect(result.requiredPerPeriod, equals(VndMoney.zero));
      expect(result.progressRatio, equals(1.0));
    });

    test('calculateRemainingMonths helper handles future, same month, and past dates', () {
      final now = DateTime(2026, 10, 15);

      // Future date in Dec 2026
      expect(GoalCalculator.calculateRemainingMonths(now, DateTime(2026, 12, 31)), equals(2));

      // Same month future day
      expect(GoalCalculator.calculateRemainingMonths(now, DateTime(2026, 10, 25)), equals(1));

      // Past date
      expect(GoalCalculator.calculateRemainingMonths(now, DateTime(2026, 8, 15)), equals(-2));
    });
  });
}
```

---

### 4.3 Unit Test Suite 3: `test/unit/feasibility_advisor_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/feasibility_advisor.dart';
import 'package:dongtien/domain/budgeting/category_budget_tracker.dart';

void main() {
  group('FeasibilityAdvisor Engine & 3 One-Tap Calculators', () {
    test('Plan is FEASIBLE when total required <= monthly capacity', () {
      final goals = [
        ActiveGoalItem(
          id: 1,
          name: 'Quỹ khẩn cấp',
          targetAmount: VndMoney(12000000),
          currentReserved: VndMoney.zero,
          remainingPeriods: 6, // 2M/month
          priority: 1,
        ),
        ActiveGoalItem(
          id: 2,
          name: 'Mua xe máy',
          targetAmount: VndMoney(30000000),
          currentReserved: VndMoney.zero,
          remainingPeriods: 10, // 3M/month
          priority: 2,
        ),
      ];

      // Total required = 2M + 3M = 5M
      final eval = FeasibilityAdvisor.evaluatePlan(
        goals: goals,
        monthlyCapacity: VndMoney(5000000),
      );

      expect(eval.isFeasible, isTrue);
      expect(eval.isInfeasible, isFalse);
      expect(eval.totalRequiredPerPeriod, equals(VndMoney(5000000)));
      expect(eval.deficit, equals(VndMoney.zero));
    });

    test('Plan is INFEASIBLE when total required > monthly capacity', () {
      final goals = [
        ActiveGoalItem(
          id: 1,
          name: 'Quỹ khẩn cấp',
          targetAmount: VndMoney(12000000),
          currentReserved: VndMoney.zero,
          remainingPeriods: 6, // 2M/month
          priority: 1,
        ),
        ActiveGoalItem(
          id: 2,
          name: 'Mua xe máy',
          targetAmount: VndMoney(30000000),
          currentReserved: VndMoney.zero,
          remainingPeriods: 10, // 3M/month
          priority: 2,
        ),
      ];

      // Total required = 5M. Capacity = 3M. Deficit = 2M.
      final eval = FeasibilityAdvisor.evaluatePlan(
        goals: goals,
        monthlyCapacity: VndMoney(3000000),
      );

      expect(eval.isFeasible, isFalse);
      expect(eval.isInfeasible, isTrue);
      expect(eval.totalRequiredPerPeriod, equals(VndMoney(5000000)));
      expect(eval.deficit, equals(VndMoney(2000000)));
    });

    group('One-Tap Calculator 1: Extend Deadline', () {
      test('Exact division: 6M shortfall at 2M capacity -> 3 periods', () {
        final periods = FeasibilityAdvisor.calculateExtendedDeadline(
          targetAmount: VndMoney(10000000),
          currentReserved: VndMoney(4000000),
          allocatedMonthlyCapacity: VndMoney(2000000),
        );
        expect(periods, equals(3));
      });

      test('Inexact division with ceiling: 6M shortfall at 2.5M capacity -> 3 periods', () {
        final periods = FeasibilityAdvisor.calculateExtendedDeadline(
          targetAmount: VndMoney(10000000),
          currentReserved: VndMoney(4000000),
          allocatedMonthlyCapacity: VndMoney(2500000),
        );
        // (6.000.000 + 2.500.000 - 1) ~/ 2.500.000 = 8.499.999 ~/ 2.500.000 = 3 periods
        expect(periods, equals(3));
      });

      test('Already achieved -> 0 periods', () {
        final periods = FeasibilityAdvisor.calculateExtendedDeadline(
          targetAmount: VndMoney(10000000),
          currentReserved: VndMoney(10000000),
          allocatedMonthlyCapacity: VndMoney(1000000),
        );
        expect(periods, equals(0));
      });

      test('Throws on zero capacity when not achieved', () {
        expect(
          () => FeasibilityAdvisor.calculateExtendedDeadline(
            targetAmount: VndMoney(10000000),
            currentReserved: VndMoney(5000000),
            allocatedMonthlyCapacity: VndMoney.zero,
          ),
          throwsArgumentError,
        );
      });
    });

    group('One-Tap Calculator 2: Lower Target', () {
      test('Calculates achievable target within fixed periods', () {
        final target = FeasibilityAdvisor.calculateLoweredTarget(
          targetAmount: VndMoney(10000000),
          currentReserved: VndMoney(4000000),
          remainingPeriods: 2,
          allocatedMonthlyCapacity: VndMoney(2000000),
        );
        // T' = 4M + 2 * 2M = 8M
        expect(target, equals(VndMoney(8000000)));
      });

      test('Clamps to original target if capacity exceeds requirement', () {
        final target = FeasibilityAdvisor.calculateLoweredTarget(
          targetAmount: VndMoney(10000000),
          currentReserved: VndMoney(4000000),
          remainingPeriods: 5,
          allocatedMonthlyCapacity: VndMoney(2000000),
        );
        // 4M + 5 * 2M = 14M > 10M -> Clamps to 10M
        expect(target, equals(VndMoney(10000000)));
      });

      test('Clamps to current reserved if periods or capacity <= 0', () {
        final target = FeasibilityAdvisor.calculateLoweredTarget(
          targetAmount: VndMoney(10000000),
          currentReserved: VndMoney(4000000),
          remainingPeriods: 0,
          allocatedMonthlyCapacity: VndMoney(2000000),
        );
        expect(target, equals(VndMoney(4000000)));
      });
    });

    group('One-Tap Calculator 3: Pause Goals Prioritization', () {
      test('Funds highest priority first, recommends pausing remainder', () {
        final goals = [
          ActiveGoalItem(
            id: 1,
            name: 'Quỹ khẩn cấp (Rank 1)',
            targetAmount: VndMoney(12000000),
            currentReserved: VndMoney.zero,
            remainingPeriods: 4, // 3M/month
            priority: 1,
          ),
          ActiveGoalItem(
            id: 2,
            name: 'Sửa nhà (Rank 2)',
            targetAmount: VndMoney(10000000),
            currentReserved: VndMoney.zero,
            remainingPeriods: 5, // 2M/month
            priority: 2,
          ),
          ActiveGoalItem(
            id: 3,
            name: 'Du lịch (Rank 3)',
            targetAmount: VndMoney(10000000),
            currentReserved: VndMoney.zero,
            remainingPeriods: 5, // 2M/month
            priority: 3,
          ),
        ];

        // Total required = 3M + 2M + 2M = 7M. Capacity = 4M.
        final recommendations = FeasibilityAdvisor.recommendGoalPruning(
          goals: goals,
          monthlyCapacity: VndMoney(4000000),
        );

        expect(recommendations.length, equals(3));

        // Goal 1 (Priority 1) is fully funded with 3M
        expect(recommendations[0].goal.id, equals(1));
        expect(recommendations[0].shouldPause, isFalse);
        expect(recommendations[0].allocatedMonthly, equals(VndMoney(3000000)));

        // Goal 2 (Priority 2) gets 1M remaining capacity -> recommended pause
        expect(recommendations[1].goal.id, equals(2));
        expect(recommendations[1].shouldPause, isTrue);
        expect(recommendations[1].allocatedMonthly, equals(VndMoney(1000000)));
        expect(recommendations[1].unmetShortfall, equals(VndMoney(1000000)));

        // Goal 3 (Priority 3) gets 0 capacity -> recommended pause
        expect(recommendations[2].goal.id, equals(3));
        expect(recommendations[2].shouldPause, isTrue);
        expect(recommendations[2].allocatedMonthly, equals(VndMoney.zero));
        expect(recommendations[2].unmetShortfall, equals(VndMoney(2000000)));
      });
    });

    group('Category Budget Progress Tracking', () {
      test('Normal status when spent < alert threshold', () {
        final progress = CategoryBudgetTracker.evaluateCategoryBudget(
          categoryId: 1,
          categoryName: 'Ăn uống',
          yearMonth: 202610,
          limitVnd: VndMoney(5000000),
          grossExpense: VndMoney(3000000),
          refundCredits: VndMoney.zero,
          alertThresholdPct: 80,
        );

        expect(progress.spentVnd, equals(VndMoney(3000000)));
        expect(progress.remainingVnd, equals(VndMoney(2000000)));
        expect(progress.spentRatio, equals(0.6));
        expect(progress.spentPercentageInt, equals(60));
        expect(progress.status, equals(BudgetStatus.normal));
        expect(progress.isExceeded, isFalse);
      });

      test('Warning status when spent reaches threshold (80%)', () {
        final progress = CategoryBudgetTracker.evaluateCategoryBudget(
          categoryId: 1,
          categoryName: 'Ăn uống',
          yearMonth: 202610,
          limitVnd: VndMoney(5000000),
          grossExpense: VndMoney(4000000),
          refundCredits: VndMoney.zero,
          alertThresholdPct: 80,
        );

        expect(progress.spentRatio, equals(0.8));
        expect(progress.status, equals(BudgetStatus.warning));
        expect(progress.isExceeded, isFalse);
      });

      test('Exceeded status when spent > limit', () {
        final progress = CategoryBudgetTracker.evaluateCategoryBudget(
          categoryId: 1,
          categoryName: 'Ăn uống',
          yearMonth: 202610,
          limitVnd: VndMoney(5000000),
          grossExpense: VndMoney(5500000),
          refundCredits: VndMoney.zero,
          alertThresholdPct: 80,
        );

        expect(progress.spentVnd, equals(VndMoney(5500000)));
        expect(progress.remainingVnd, equals(VndMoney(-500000)));
        expect(progress.spentRatio, equals(1.1));
        expect(progress.status, equals(BudgetStatus.exceeded));
        expect(progress.isExceeded, isTrue);
      });

      test('Refund reduces budget spending', () {
        final progress = CategoryBudgetTracker.evaluateCategoryBudget(
          categoryId: 1,
          categoryName: 'Mua sắm',
          yearMonth: 202610,
          limitVnd: VndMoney(5000000),
          grossExpense: VndMoney(4200000),
          refundCredits: VndMoney(500000),
          alertThresholdPct: 80,
        );

        // Effective spent = 4.2M - 0.5M = 3.7M (74% -> normal)
        expect(progress.spentVnd, equals(VndMoney(3700000)));
        expect(progress.status, equals(BudgetStatus.normal));
      });

      test('Net recovery clamps effective budget spent to 0 ₫', () {
        final progress = CategoryBudgetTracker.evaluateCategoryBudget(
          categoryId: 1,
          categoryName: 'Mua sắm',
          yearMonth: 202610,
          limitVnd: VndMoney(5000000),
          grossExpense: VndMoney(200000),
          refundCredits: VndMoney(500000),
          alertThresholdPct: 80,
        );

        expect(progress.spentVnd, equals(VndMoney.zero));
        expect(progress.remainingVnd, equals(VndMoney(5000000)));
        expect(progress.spentRatio, equals(0.0));
        expect(progress.status, equals(BudgetStatus.normal));
      });
    });
  });
}
```

---

## 5. CAVEATS

1. **Pure Domain Boundary**: The models designed above contain zero Flutter and zero Drift dependencies. Persistence layer DAOs (in `lib/core/database/daos/`) will query raw sums (`SUM(debit_vnd)`, `SUM(credit_vnd)`) from SQLite and pass them as pure arguments into these domain calculators.
2. **Date Period Convention**: For goal periods, calendar months are used as the standard unit. In the date-based helper `calculateRemainingMonths`, day-of-month boundaries within the current month count as 1 period if the deadline is in the future.
3. **No Float for Currency**: At no point is a monetary value stored or converted to `double`. The only fields using `double` are rates/ratios (`savingsRate`, `spentRatio`, `percentageOfTotal`), and UI percentage displays use integer ceiling/rounding.

---

## 6. CONCLUSION

The domain budgeting and savings goals engines have been fully specified with exact mathematical models, boundary invariants, and exhaustive test suites:
- **`lib/domain/budgeting/category_spending_calculator.dart`**: Implements gross expenses, refund credits, net expense, net recovery (`effective_expense = max(0, net_expense)`), and `savingsRate` (returning `null` for zero/negative income, avoiding `NaN`).
- **`lib/domain/budgeting/goal_calculator.dart`**: Implements exact integer ceiling division `((T - C) + N - 1) ~/ N`, guaranteeing goals are achieved on time without 1-VND shortfalls, and handles `ACHIEVED` ($C \ge T$) and `OVERDUE` ($N \le 0$).
- **`lib/domain/budgeting/feasibility_advisor.dart`**: Flags collective goal feasibility against available capacity, and provides the 3 one-tap calculators (Extend Deadline, Lower Target, and Priority-based Goal Pruning).
- **`lib/domain/budgeting/category_budget_tracker.dart`**: Evaluates individual and aggregate monthly category budget progress, warning thresholds, and deficit tracking.
- **Test Suites**: 3 complete, deterministic unit test files designed and ready for execution.

---

## 7. VERIFICATION METHOD

### Independent Verification Commands:
```bash
# 1. Run unit tests once files are implemented by worker_m2_1:
flutter test test/unit/category_spending_test.dart
flutter test test/unit/goal_ceiling_division_test.dart
flutter test test/unit/feasibility_advisor_test.dart

# 2. Run static analysis across the entire project:
flutter analyze

# 3. Format check:
dart format --output=none --set-exit-if-changed .
```

### Invalidation Conditions:
- Any implementation in `lib/domain/budgeting/` that imports `package:flutter/*` or `package:drift/*`.
- Use of `double` or floating-point division for monetary VND values.
- `savingsRate` returning `0.0`, `double.nan`, or `double.infinity` when `recognizedIncome <= 0`.
- Floor division (`~/`) instead of ceiling division (`((T - C) + N - 1) ~/ N`) for savings goal periodic requirements.
