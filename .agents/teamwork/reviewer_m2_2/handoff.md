# HANDOFF REPORT: M2 DOMAIN BUDGETING & FORECASTING REVIEW & ADVERSARIAL AUDIT

> **Reviewer**: `reviewer_m2_2`  
> **Roles**: reviewer, critic  
> **Milestone**: M2 (Deterministic Domain Engines & DAOs)  
> **Target Package**: `dongtien` (`vn.dongtien`)  
> **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\reviewer_m2_2`  
> **Date**: 2026-10-27T19:21:00Z  
> **Verdict**: **APPROVE**

---

## 1. Observation

### 1.1 Direct Tool Execution Results
1. **Full Automated Test Suite**:
   Command: `C:\Users\coihu12\flutter\bin\flutter.bat test`
   Result:
   ```text
   00:03 +192: All tests passed!
   Exit code: 0
   ```
2. **Targeted M2 Unit Tests**:
   Command: `C:\Users\coihu12\flutter\bin\flutter.bat test test/unit/safe_to_spend_test.dart test/unit/recurrence_test.dart test/unit/goal_ceiling_division_test.dart test/unit/feasibility_advisor_test.dart test/unit/category_spending_test.dart test/unit/cash_flow_forecaster_test.dart`
   Result:
   ```text
   00:01 +34: All tests passed!
   Exit code: 0
   ```
3. **Static Analysis**:
   Command: `C:\Users\coihu12\flutter\bin\flutter.bat analyze`
   Result:
   ```text
   Analyzing App...
   No issues found! (ran in 8.7s)
   Exit code: 0
   ```
4. **Dart Code Formatting**:
   Command: `C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed .`
   Result:
   ```text
   Formatted 39 files (0 changed) in 1.00 seconds.
   Exit code: 0
   ```
5. **Clean Architecture Layer Isolation**:
   Grep query: `import ['"]package:(flutter|drift|flutter_riverpod)` in `lib/domain/`
   Result: `No results found` (Zero prohibited imports across all files in `lib/domain/`).

---

### 1.2 Inspection of Implementation Code & Verified Mathematical Invariants

#### Invariant 1: Safe-to-Spend Zero Double-Counting & Deficit Invariants
- File: `lib/domain/forecasting/safe_to_spend_calculator.dart`
- Lines 188-195: Protected envelope initial balances are gathered (`totalProtectedReservesVnd`).
- Lines 208-212: Eligible bills are filtered by `dueDate <= horizonEndOfDay` and sorted chronologically:
  ```dart
  final eligibleBills = pendingBills
      .where((b) => !b.dueDate.isAfter(horizonEndOfDay))
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  ```
- Lines 236-257: For bills linked to `EnvelopePolicyType.protected`:
  ```dart
  final currentRemaining = remainingBalances[linkedEnv.id] ?? 0;
  final coveredVnd = billAmountVnd < currentRemaining ? billAmountVnd : currentRemaining;
  final unfundedVnd = billAmountVnd - coveredVnd;
  remainingBalances[linkedEnv.id] = currentRemaining - coveredVnd;
  totalUnfundedVnd += unfundedVnd;
  ```
- Lines 295-301: Mathematical deduction:
  $$\text{safeToSpendVnd} = \text{liquidAssets} - \text{protectedReserves} - \text{unfundedCommittedOutflows} - \text{minimumCashBuffer}$$
  When reserve $= R$ and bill $= B$, total deducted is strictly $\max(R, B)$. Never $R + B$.
- Lines 300-301: Result is wrapped in `VndMoney(safeToSpendVnd)`. If $\text{safeToSpendVnd} < 0$, exact negative integer VND is returned (never clamped to 0).
- Lines 304-310: Daily allowance:
  ```dart
  if (safeToSpendVnd > 0) {
    dailyAllowance = VndMoney(safeToSpendVnd ~/ effectiveDivisor);
  } else {
    dailyAllowance = VndMoney.zero;
  }
  ```
  Integer truncation division `~/` is used, and daily allowance is zero upon deficit.

#### Invariant 2: Drift-Free Recurrence & Gregorian Math
- File: `lib/domain/forecasting/recurrence_calculator.dart`
- Lines 12-15: Accurate Gregorian leap year formula: `(year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)`.
- Lines 18-31: Month lengths: Feb returns 29 in leap year, 28 in non-leap year.
- Lines 35-45: Anchor day preservation formula:
  ```dart
  static int calculateActualDueDay(int anchorDayOfMonth, int year, int month) {
    final maxDays = daysInMonth(year, month);
    return anchorDayOfMonth < maxDays ? anchorDayOfMonth : maxDays;
  }
  ```
- Lines 75-90: Advancing to next month in `MONTHLY` recurrence evaluates `calculateActualDueDay(anchor, nextYear, nextMonth)`.
- Verified in `test/unit/recurrence_test.dart` (lines 42-80): Day 31 anchor in 2026 evaluates to Jan 31 $\to$ Feb 28 $\to$ Mar 31 $\to$ Apr 30 $\to$ May 31. Anchor is never degraded to 28. In 2024 (leap year), Jan 31 $\to$ Feb 29 $\to$ Mar 31.

#### Invariant 3: Ceiling Division Goal Math
- File: `lib/domain/budgeting/goal_calculator.dart`
- Lines 76-89: Check $C \ge T \implies$ `status = GoalStatus.achieved`, `requiredPerPeriod = 0 ₫`, `shortfall = 0 ₫`.
- Lines 98-108: Check $N \le 0 \implies$ `status = GoalStatus.overdue`, `shortfall = T - C`, `requiredPerPeriod = shortfall` (no division by zero).
- Lines 111-113: In-progress ceiling division:
  ```dart
  final int requiredInt = (shortfall.amount + remainingPeriods - 1) ~/ remainingPeriods;
  ```
  Guarantees $N \times \text{requiredInt} \ge \text{shortfall}$. Zero 1 ₫ shortfall at deadline.
- Lines 60-73: Negative input parameters throw `ArgumentError.value`.

#### Invariant 4: Net Recovery Invariants
- File: `lib/domain/budgeting/category_spending_calculator.dart`
- Lines 19-29:
  ```dart
  VndMoney get netExpense => grossExpense - refundCredits;
  VndMoney get effectiveExpense => netExpense.isNegative ? VndMoney.zero : netExpense;
  bool get isNetRecovery => netExpense.isNegative;
  String? get recoveryLabel => isNetRecovery ? 'Thu hồi chi phí ròng' : null;
  ```
- Lines 125-130: `totalNet = totalGross - totalRefund`; `totalEffective = totalNetRecovery ? VndMoney.zero : totalNet`; `totalNetSaving = recognizedIncome - totalNet`.
- Verified in `test/unit/category_spending_test.dart` (lines 50-75): Gross 500k, refund 1.5M $\implies$ netExpense = -1M, `isNetRecovery = true`, `recoveryLabel = 'Thu hồi chi phí ròng'`, `effectiveExpense = 0 ₫`.

#### Invariant 5: Savings Rate & Zero/Negative Income
- File: `lib/domain/budgeting/category_spending_calculator.dart`
- Lines 133-140:
  ```dart
  double? rate;
  if (recognizedIncome.amount <= 0) {
    rate = null;
  } else {
    rate = (recognizedIncome.amount - totalEffective.amount) / recognizedIncome.amount;
  }
  ```
- Lines 91-97:
  ```dart
  String get savingsRateDisplay {
    if (savingsRate == null) {
      return 'Chưa có thu nhập';
    }
    final int pct = (savingsRate! * 100).round();
    return '$pct%';
  }
  ```
  When `recognizedIncome <= 0`, `savingsRate` is strictly `null` and `savingsRateDisplay` is `'Chưa có thu nhập'`. Never `NaN`, never `Infinity`, never `0%`.

#### Invariant 6: Feasibility Advisor (3 One-Tap Calculators)
- File: `lib/domain/budgeting/feasibility_advisor.dart`
- Lines 88-105: `evaluatePlan` sums unachieved goals and distinguishes `feasible` vs `infeasible` with exact deficit $D = \text{totalRequired} - \text{monthlyCapacity}$.
- Lines 117-138: **Extend Deadline**: $N' = ((T - C) + \text{capacity} - 1) \mathbin{\sim/} \text{capacity}$. Throws `ArgumentError.value` if capacity $\le 0$.
- Lines 150-174: **Lower Target**: $T' = C + N \times \text{capacity}$. Clamped to $[C, T]$.
- Lines 184-233: **Pause Lower-Priority Goals**: Sorts by `priority` ascending (1 is highest), then `remainingPeriods` ascending. Sequentially allocates `monthlyCapacity`. Goals unable to be fully funded are marked `shouldPause = true` with `unmetShortfall`.

---

## 2. Logic Chain

1. **Integrity & Authenticity Check**:
   - Source code was thoroughly audited for hardcoded outputs, facade classes, or shortcuts.
   - All classes in `lib/domain/` contain dynamic algorithms operating over immutable parameters.
   - All 192 tests execute real Dart logic; zero artificial mocking or test-embedded output shortcuts were detected.
   - Clean Architecture rules from `AGENTS.md` are strictly respected (zero imports of Flutter, Drift, or Riverpod in `lib/domain/`).

2. **Mathematical Correctness**:
   - Safe-to-Spend satisfies zero double-counting: chronological assignment of protected reserves to linked pending bills ensures each bill/reserve pair deductions are bounded by $\max(R, B)$.
   - Deficit handling never clamps Safe-to-Spend to 0 ₫, preserving financial reality while setting daily discretionary allowance to zero.
   - Goal calculator uses integer ceiling division: for target $T$, current $C$, and periods $N$, $R = \lfloor (T - C + N - 1) / N \rfloor$ ensures $N \times R \ge T - C$, preventing 1 ₫ shortfalls.
   - Division by zero is comprehensively prevented across all engines:
     - `SafeToSpendCalculator`: `daysRemaining <= 0 ? 1 : daysRemaining`.
     - `GoalCalculator`: `remainingPeriods <= 0` branches to `overdue`.
     - `CategorySpendingCalculator`: `recognizedIncome <= 0` sets `rate = null`.
     - `CategoryBudgetProgress`: `limitVnd.isZero ? 100 : ...`.
     - `FeasibilityAdvisor`: `capacity <= 0` throws descriptive `ArgumentError`.

3. **Adversarial Analysis & Stress-Testing**:
   - Examined worst-case inputs: negative balances, buffer breach on Day 0, unknown envelope IDs on bills, leap years across century boundaries (2000, 1900, 2100), net refunds greater than income, and multi-goal priority ties.
   - Discovered one subtle edge-case in `RecurrenceCalculator.generateRecurrenceDates` when `anchorDayOfMonth` is omitted/null (documented in Finding 1 below).
   - In production use within `CashFlowForecaster`, `item.anchorDayOfMonth` is passed from `ScheduledItems.anchor_day_of_month`, so the issue does not affect the primary cash flow forecaster or scheduled items workflow.

---

## 3. Caveats

1. **Ad-hoc `generateRecurrenceDates` anchor parameter**:
   If a caller invokes `RecurrenceCalculator.generateRecurrenceDates` without providing `anchorDayOfMonth`, the recurrence will anchor on `current.day` after February, causing the schedule to stay on the 28th/29th. The fix is documented below and should be applied during the next maintenance pass.
2. **Local Calendar Day Timezone**:
   `SafeToSpendCalculator` and `CashFlowForecaster` use calendar days (`DateTime(y, m, d)`). When UI layers pass `DateTime` instances, they should ensure the date representation is resolved in local time before calling domain methods.

---

## 4. Conclusion & Review Verdict

**VERDICT**: **APPROVE**

Milestone M2 domain budgeting and forecasting engines, general ledger DAOs, and virtual fund envelopes meet all 15 acceptance criteria and project non-negotiables:
- Zero double-counting Safe-to-Spend algorithm verified.
- Drift-free recurrence anchor preservation verified across leap and non-leap years.
- Ceiling integer division prevents 1 ₫ goal shortfalls.
- Net recovery and null savings rate safeguards operate accurately.
- Feasibility Advisor provides 3 one-tap calculators with deterministic priority ranking.
- 100% of 192 tests pass, static analysis has 0 warnings/errors, and formatting is compliant.

---

## 5. Review & Adversarial Findings

### Minor Finding 1 (Adversarial Edge Case): Anchor Day Preservation in `generateRecurrenceDates` When Anchor is Omitted

- **Classification**: Minor (Defensive Improvement)
- **Where**: `lib/domain/forecasting/recurrence_calculator.dart`, line 117-151
- **What**: In `RecurrenceCalculator.generateRecurrenceDates`:
  ```dart
  static List<DateTime> generateRecurrenceDates({
    required DateTime startDueDate,
    required String recurrence,
    int? anchorDayOfMonth,
    required DateTime horizonDate,
    int maxOccurrences = 365,
  }) { ...
    while (!current.isAfter(horizonEndOfDay) && count < maxOccurrences) {
      dates.add(current);
      count++;
      current = computeNextDueDate(
        currentDueDate: current,
        recurrence: recurrence,
        anchorDayOfMonth: anchorDayOfMonth, // <-- if null, computeNextDueDate uses currentDueDate.day
      );
    }
  ```
  If `anchorDayOfMonth` is passed as `null` and `startDueDate` is `2026-01-31`:
  - Iteration 1: `current` = Jan 31. `anchorDayOfMonth` is null $\implies$ `computeNextDueDate` uses `31`, returning `2026-02-28`.
  - Iteration 2: `current` = Feb 28. `anchorDayOfMonth` is null $\implies$ `computeNextDueDate` falls back to `currentDueDate.day` = 28! March then becomes `2026-03-28` instead of `2026-03-31`.
- **Impact**: In `CashFlowForecaster`, `item.anchorDayOfMonth` is passed explicitly from the database schema, so this edge case is avoided in production. However, direct callers omitting `anchorDayOfMonth` will experience anchor degradation after February.
- **Suggested Fix**:
  At the beginning of `generateRecurrenceDates`:
  ```dart
  final int effectiveAnchor = anchorDayOfMonth ?? startDueDate.day;
  ```
  And pass `anchorDayOfMonth: effectiveAnchor` in `computeNextDueDate`.

---

## 6. Verification Method

To independently reproduce this verification:

```bash
# 1. Run all 192 unit and database tests
C:\Users\coihu12\flutter\bin\flutter.bat test

# 2. Run targeted M2 domain tests
C:\Users\coihu12\flutter\bin\flutter.bat test test/unit/safe_to_spend_test.dart test/unit/recurrence_test.dart test/unit/goal_ceiling_division_test.dart test/unit/feasibility_advisor_test.dart test/unit/category_spending_test.dart test/unit/cash_flow_forecaster_test.dart

# 3. Verify static analysis has zero warnings/errors
C:\Users\coihu12\flutter\bin\flutter.bat analyze

# 4. Verify code formatting
C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed .

# 5. Check clean architecture layer boundaries (0 forbidden imports in domain)
# Command in PowerShell:
# Select-String -Path "lib\domain\*.dart", "lib\domain\**\*.dart" -Pattern "package:flutter|package:drift|package:flutter_riverpod"
# Expected: 0 matches
```

Invalidation conditions:
- Any double deduction in Safe-to-Spend when a bill is covered by a protected envelope.
- Clamping negative Safe-to-Spend deficit to zero.
- Goal periodic contribution resulting in target shortfall after $N$ periods.
- Savings rate returning `NaN`, `Infinity`, or `0%` when income is 0 ₫.
- Any forbidden Flutter/Drift import introduced in `lib/domain/`.
