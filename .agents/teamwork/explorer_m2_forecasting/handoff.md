# HANDOFF REPORT — FORECASTING & SAFE-TO-SPEND DOMAIN BLUEPRINT

**Agent**: `explorer_m2_forecasting`  
**Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_forecasting`  
**Target Milestone**: M2 — Deterministic Domain Engines  
**Target Scope**:
1. `lib/domain/forecasting/safe_to_spend_calculator.dart`
2. `lib/domain/forecasting/recurrence_calculator.dart`
3. `lib/domain/forecasting/cash_flow_forecaster.dart`
4. Obligation conversion workflow & ledger linkage
5. Unit test suites in `test/unit/safe_to_spend_test.dart` and `test/unit/recurrence_test.dart`

---

## 1. OBSERVATION

We conducted a forensic code and architecture review of the project repository, specifications, and data models:

### 1.1 Invariants & Architecture Rules
1. **Zero Double-Counting Safe-to-Spend**:
   - `docs/ARCHITECTURE_AND_RULES.md:251-286`:
     $$\text{Safe-to-Spend} = \text{Liquid Assets} - \text{Protected Reserves} - \text{Unfunded Committed Outflows} - \text{Minimum Cash Buffer}$$
   - `docs/ARCHITECTURE_AND_RULES.md:260-275`:
     "For all `scheduled_items` with $\text{kind} = \text{'BILL'}$ and $\text{status} = \text{'PENDING'}$ due $\le \text{horizon\_date}$:
     - For each distinct `PROTECTED` envelope, initialize: $\text{remaining\_balance} = \max(0, \text{envelope.reserved\_balance\_vnd})$
     - Iterate through pending bills sorted chronologically by $\text{due\_date\_ms}$:
       * Case A: Bill has no linked envelope ($\text{linked\_envelope\_id} == \text{null}$): $\text{unfunded} = \text{bill.amount\_vnd}$
       * Case B: Bill linked to a `PROTECTED` envelope: $\text{covered} = \min(\text{bill.amount\_vnd}, \text{remaining\_balance})$, $\text{unfunded} = \text{bill.amount\_vnd} - \text{covered}$, $\text{remaining\_balance} -= \text{covered}$
       * Case C: Bill linked to a `FLEXIBLE` envelope: $\text{unfunded} = \text{bill.amount\_vnd}$"
   - `docs/ARCHITECTURE_AND_RULES.md:278-286`:
     "Never Clamp to Zero: If the sum of reserves, unfunded bills, and buffer exceeds liquid assets, Safe-to-Spend returns an exact negative integer (e.g., `-1.500.000 ₫`)."
     "Daily Discretionary Allowance: When $\text{Safe-to-Spend} > 0$: $\text{daily\_allowance} = \text{Safe-to-Spend} \mathbin{\sim/} \max(1, \text{days\_remaining})$; When $\text{Safe-to-Spend} \le 0$: $\text{daily\_allowance} = 0 \text{ ₫/ngày}$."

2. **Drift-Free Month-End Recurrence**:
   - `docs/ARCHITECTURE_AND_RULES.md:333-339`:
     $$\text{actual\_due\_day} = \min(\text{anchor\_day\_of\_month}, \text{daysInMonth}(Y, M))$$
     "A bill anchored to day 31 evaluated in February (28 days) produces February 28. Evaluated in February of a leap year (29 days) produces February 29. In March (31 days), it automatically schedules on March 31 without anchor degradation."
   - `lib/core/database/app_database.dart:211`:
     `CHECK (anchor_day_of_month IS NULL OR (anchor_day_of_month >= 1 AND anchor_day_of_month <= 31))`
     `CHECK (recurrence IN ('NONE', 'WEEKLY', 'MONTHLY', 'YEARLY'))`

3. **Obligation Conversion**:
   - `docs/ARCHITECTURE_AND_RULES.md:340-345`:
     "When marking a `scheduled_item` as paid:
     1. Insert real `journal_transaction` (`tx_type = EXPENSE` or `INCOME`, `paid_transaction_id = tx.id`).
     2. Update `scheduled_item`: set $\text{status} = \text{'PAID\_OR\_RECEIVED'}$.
     3. Advance next recurrence instance. Paid items are excluded from future forecast outflows."
   - `docs/DESIGN_AND_TEST_PLAN.md:607-627` (Scenario 11):
     "Before payment, deducted in Safe-to-Spend (respecting linked protected envelope without double subtraction). After marking paid, linked to real expense transaction and never counted twice."

4. **Cash Flow Forecast**:
   - `docs/ARCHITECTURE_AND_RULES.md:346-351`:
     "Starting balance: $\text{Balance}_0 = \text{total\_liquid\_assets}$. Day $k$ balance: $\text{Balance}_k = \text{Balance}_{k-1} + \sum \text{PLANNED\_INCOME}_k - \sum \text{PENDING\_BILL}_k$. Date warning: If $\text{Balance}_k < \text{minimum\_cash\_buffer\_vnd}$, flag day $k$ with an alert indicator and show the projected deficit."

5. **Currency Representation (`VndMoney`)**:
   - `lib/core/money/vnd_money.dart:23-209`:
     Stores 64-bit signed `int amount` (whole VND, zero floating point). Max safe VND is $9 \times 10^{15}$. Provides arithmetic operators (`+`, `-`, `*`, `~/`) and comparison operators (`<`, `<=`, `>`, `>=`). Negation is supported (`-amount`).

---

## 2. LOGIC CHAIN

1. **Decoupling and Zero Double-Counting Guarantee**:
   - Observation: When a user allocates $1.000.000 ₫$ into a Protected Envelope ("Điện Nước"), `Protected Reserves` increases by $1.000.000 ₫$, which reduces `Safe-to-Spend` by $1.000.000 ₫$ (Scenario 5).
   - If a pending bill for electricity ("Tiền Điện") of $1.500.000 ₫$ is also linked to "Điện Nước", naive subtraction of both would deduct $1.000.000 ₫ + 1.500.000 ₫ = 2.500.000 ₫$.
   - By sorting pending bills chronologically and subtracting envelope coverage first:
     $$\text{covered} = \min(1.500.000, 1.000.000) = 1.000.000 \text{ ₫}$$
     $$\text{unfunded} = 1.500.000 - 1.000.000 = 500.000 \text{ ₫}$$
     $$\text{remaining\_reserve} = 1.000.000 - 1.000.000 = 0 \text{ ₫}$$
     Total subtracted = $\text{Protected Reserve } (1.000.000) + \text{Unfunded Bill } (500.000) = 1.500.000 \text{ ₫}$.
   - Result: Exactly $1.500.000 ₫$ is reserved/subtracted, eliminating double subtraction mathematically.
   - For multiple bills linked to the same protected envelope, chronological sorting ensures earlier bills consume the reserve first, leaving later bills to account for only the true remaining unfunded excess.

2. **Negative Safe-to-Spend Handling**:
   - When liabilities, protected reserves, and minimum cash buffer exceed liquid assets:
     $$\text{Safe-to-Spend} = 2.000.000 - 1.500.000 - 1.000.000 - 1.000.000 = -1.500.000 \text{ ₫}$$
   - Clamping to `0 ₫` hides insolvency from the user. Returning exact negative `VndMoney(-1500000)` allows UI to render red warning deficit and breakdown modal.
   - Daily allowance must be non-negative: when $\text{Safe-to-Spend} \le 0$, spending allowance per day is strictly $0 \text{ ₫/ngày}$. Division by zero is prevented by $\max(1, \text{days\_remaining})$.

3. **Drift-Free Recurrence Invariant**:
   - Naive month incrementation fails in Dart: `DateTime(2026, 2, 31)` silently wraps to `2026-03-03`.
   - Storing `anchor_day_of_month` in SQLite preserves user intent.
   - Gregorian leap year check: `(year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)`.
   - For any month $(Y, M)$, $\text{actual\_due\_day} = \min(\text{anchor}, \text{daysInMonth}(Y, M))$.
   - In 2026: Jan 31 $\to$ Feb 28 $\to$ Mar 31 $\to$ Apr 30 $\to$ May 31. The anchor `31` never degrades.

4. **Obligation Payment Lifecycle & Anti-Double Counting**:
   - Marking a scheduled item as paid inserts a real ledger transaction, updates `scheduled_items.status = 'PAID_OR_RECEIVED'`, and records `paid_transaction_id`.
   - Because Safe-to-Spend queries only `status == 'PENDING'`, the paid obligation immediately drops out of `Unfunded Committed Outflows`. Liquid assets simultaneously decrease via the ledger expense posting.
   - Next occurrence is created with `status = 'PENDING'` for the next period, ensuring seamless continuity.

---

## 3. CAVEATS

1. **Horizon Date Boundary**:
   - If no planned income is scheduled, the default horizon is the end of the current budgeting period (`period_start_day` to next `period_start_day`).
   - Overdue pending bills (`dueDate < now`) must be included in `unfundedCommittedOutflows` because they are real unpaid obligations due immediately.
2. **Timezone & Date-Only Comparison**:
   - Dates for daily discretionary allowance and bill eligibility should be compared at calendar day resolution (ignoring hour/minute/second offsets) to avoid off-by-one errors across midnight boundaries.
3. **Pure Dart Constraint**:
   - `lib/domain/forecasting/` must not import Drift, SQLite, Flutter UI widgets, or Riverpod. All data passed to the domain calculators must be pure Dart primitives or `VndMoney`.

---

## 4. CONCLUSION & DETAILED IMPLEMENTATION BLUEPRINT

### 4.1 Component Architecture & File Layout
```text
lib/domain/forecasting/
├── safe_to_spend_calculator.dart   # Pure Dart Zero Double-Counting engine & breakdown
├── recurrence_calculator.dart      # Pure Dart drift-free month-end recurrence engine
├── cash_flow_forecaster.dart       # Pure Dart 30/60/90-day cash flow projection engine
└── obligation_conversion_service.dart # Workflow contract for paying scheduled items
test/unit/
├── safe_to_spend_test.dart         # Unit tests covering Scenarios 5, 11, 12, edge cases
├── recurrence_test.dart            # Unit tests covering Scenario 15B, leap years, anchor preservation
└── cash_flow_forecast_test.dart    # Unit tests covering 30/60/90-day balance timelines & deficit flags
```

---

### 4.2 Blueprint 1: `lib/domain/forecasting/safe_to_spend_calculator.dart`

```dart
import 'package:dongtien/core/money/vnd_money.dart';

/// Policy governing how an envelope interacts with Safe-to-Spend.
enum EnvelopePolicyType {
  protected,
  flexible;

  static EnvelopePolicyType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'PROTECTED':
        return EnvelopePolicyType.protected;
      case 'FLEXIBLE':
        return EnvelopePolicyType.flexible;
      default:
        throw ArgumentError('Invalid envelope policy: $val');
    }
  }
}

/// Snapshot of an active virtual fund envelope.
class EnvelopeSnapshot {
  final int id;
  final String name;
  final EnvelopePolicyType policy;
  final VndMoney reservedBalance;

  const EnvelopeSnapshot({
    required this.id,
    required this.name,
    required this.policy,
    required this.reservedBalance,
  });
}

/// Representation of a pending bill obligation.
class PendingBillItem {
  final int id;
  final String title;
  final VndMoney amount;
  final DateTime dueDate;
  final int? linkedEnvelopeId;

  const PendingBillItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.linkedEnvelopeId,
  });
}

/// Detailed allocation tracking for an individual pending bill.
class BillAllocationDetail {
  final int billId;
  final String title;
  final VndMoney amount;
  final DateTime dueDate;
  final int? linkedEnvelopeId;
  final EnvelopePolicyType? linkedEnvelopePolicy;
  final VndMoney coveredAmount;
  final VndMoney unfundedAmount;

  const BillAllocationDetail({
    required this.billId,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.linkedEnvelopeId,
    this.linkedEnvelopePolicy,
    required this.coveredAmount,
    required this.unfundedAmount,
  });
}

/// Detailed coverage tracking for an individual protected envelope.
class EnvelopeCoverageDetail {
  final int envelopeId;
  final String envelopeName;
  final VndMoney initialReservedBalance;
  final VndMoney allocatedToBills;
  final VndMoney remainingProtectedReserve;

  const EnvelopeCoverageDetail({
    required this.envelopeId,
    required this.envelopeName,
    required this.initialReservedBalance,
    required this.allocatedToBills,
    required this.remainingProtectedReserve,
  });
}

/// Complete structural breakdown of the Safe-to-Spend formula.
class SafeToSpendBreakdown {
  final VndMoney liquidAssets;
  final VndMoney protectedReserves;
  final VndMoney unfundedCommittedOutflows;
  final VndMoney minimumCashBuffer;
  final List<BillAllocationDetail> billAllocations;
  final List<EnvelopeCoverageDetail> envelopeCoverages;

  const SafeToSpendBreakdown({
    required this.liquidAssets,
    required this.protectedReserves,
    required this.unfundedCommittedOutflows,
    required this.minimumCashBuffer,
    required this.billAllocations,
    required this.envelopeCoverages,
  });
}

/// Result of the Safe-to-Spend calculation.
class SafeToSpendResult {
  /// Spendable amount in VND. May be negative (NEVER clamped to zero).
  final VndMoney safeToSpend;

  /// Daily discretionary allowance: Safe-to-Spend ~/ max(1, daysRemaining) if positive, else 0 ₫.
  final VndMoney dailyAllowance;

  /// True if safeToSpend < 0 (user is in deficit).
  final bool isDeficit;

  /// Number of days remaining in the evaluation horizon.
  final int daysRemaining;

  /// Full transparent breakdown for the UI breakdown modal.
  final SafeToSpendBreakdown breakdown;

  const SafeToSpendResult({
    required this.safeToSpend,
    required this.dailyAllowance,
    required this.isDeficit,
    required this.daysRemaining,
    required this.breakdown,
  });

  int get safeToSpendVnd => safeToSpend.amount;
  int get dailyAllowanceVnd => dailyAllowance.amount;
}

/// Pure Dart calculator implementing the Zero Double-Counting Safe-to-Spend algorithm.
class SafeToSpendCalculator {
  const SafeToSpendCalculator._();

  /// Calculates Safe-to-Spend from [now] to [horizonDate].
  ///
  /// Formula:
  /// Safe-to-Spend = Liquid Assets - Protected Reserves - Unfunded Committed Outflows - Minimum Cash Buffer
  ///
  /// Zero Double-Counting Algorithm:
  /// 1. Protected envelopes cover linked pending bills in chronological due-date order.
  /// 2. Case A (No linked envelope): unfunded = bill.amount.
  /// 3. Case B (Linked to PROTECTED envelope):
  ///    covered = min(bill.amount, remaining_balance)
  ///    unfunded = bill.amount - covered
  ///    remaining_balance -= covered
  /// 4. Case C (Linked to FLEXIBLE envelope): unfunded = bill.amount.
  /// 5. Daily allowance: Safe-to-Spend ~/ max(1, daysRemaining) if safeToSpend > 0, else 0 ₫/ngày.
  static SafeToSpendResult calculate({
    required VndMoney liquidAssets,
    required List<EnvelopeSnapshot> envelopes,
    required List<PendingBillItem> pendingBills,
    required VndMoney minimumCashBuffer,
    required DateTime now,
    required DateTime horizonDate,
    int? daysRemainingOverride,
  }) {
    // 1. Calculate days remaining
    final int daysRemaining;
    if (daysRemainingOverride != null) {
      daysRemaining = daysRemainingOverride > 0 ? daysRemainingOverride : 1;
    } else {
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      final horizonDateOnly = DateTime(horizonDate.year, horizonDate.month, horizonDate.day);
      final diff = horizonDateOnly.difference(nowDateOnly).inDays;
      daysRemaining = diff <= 0 ? 1 : diff;
    }

    // 2. Map envelopes and initialize remaining balances for PROTECTED envelopes
    final Map<int, EnvelopeSnapshot> envelopeMap = {
      for (final env in envelopes) env.id: env,
    };

    final Map<int, int> remainingBalances = {};
    int totalProtectedReservesVnd = 0;

    for (final env in envelopes) {
      if (env.policy == EnvelopePolicyType.protected) {
        final bal = env.reservedBalance.amount > 0 ? env.reservedBalance.amount : 0;
        remainingBalances[env.id] = bal;
        totalProtectedReservesVnd += bal;
      }
    }
    final VndMoney protectedReserves = VndMoney(totalProtectedReservesVnd);

    // 3. Filter pending bills due on or before horizonDate, sorted chronologically
    final horizonEndOfDay = DateTime(
      horizonDate.year,
      horizonDate.month,
      horizonDate.day,
      23,
      59,
      59,
      999,
    );

    final eligibleBills = pendingBills
        .where((b) => !b.dueDate.isAfter(horizonEndOfDay))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // 4. Chronological allocation across pending bills (Zero Double-Counting)
    final List<BillAllocationDetail> billAllocations = [];
    int totalUnfundedVnd = 0;
    final Map<int, int> envelopeAllocatedMap = {};

    for (final bill in eligibleBills) {
      final billAmountVnd = bill.amount.amount;
      final linkedEnvId = bill.linkedEnvelopeId;
      final linkedEnv = linkedEnvId != null ? envelopeMap[linkedEnvId] : null;

      if (linkedEnv == null) {
        // Case A: No linked envelope
        billAllocations.add(BillAllocationDetail(
          billId: bill.id,
          title: bill.title,
          amount: bill.amount,
          dueDate: bill.dueDate,
          linkedEnvelopeId: null,
          linkedEnvelopePolicy: null,
          coveredAmount: VndMoney.zero,
          unfundedAmount: bill.amount,
        ));
        totalUnfundedVnd += billAmountVnd;
      } else if (linkedEnv.policy == EnvelopePolicyType.protected) {
        // Case B: Linked to PROTECTED envelope
        final currentRemaining = remainingBalances[linkedEnv.id] ?? 0;
        final coveredVnd = billAmountVnd < currentRemaining ? billAmountVnd : currentRemaining;
        final unfundedVnd = billAmountVnd - coveredVnd;

        remainingBalances[linkedEnv.id] = currentRemaining - coveredVnd;
        envelopeAllocatedMap[linkedEnv.id] = (envelopeAllocatedMap[linkedEnv.id] ?? 0) + coveredVnd;

        billAllocations.add(BillAllocationDetail(
          billId: bill.id,
          title: bill.title,
          amount: bill.amount,
          dueDate: bill.dueDate,
          linkedEnvelopeId: linkedEnv.id,
          linkedEnvelopePolicy: EnvelopePolicyType.protected,
          coveredAmount: VndMoney(coveredVnd),
          unfundedAmount: VndMoney(unfundedVnd),
        ));
        totalUnfundedVnd += unfundedVnd;
      } else {
        // Case C: Linked to FLEXIBLE envelope
        billAllocations.add(BillAllocationDetail(
          billId: bill.id,
          title: bill.title,
          amount: bill.amount,
          dueDate: bill.dueDate,
          linkedEnvelopeId: linkedEnv.id,
          linkedEnvelopePolicy: EnvelopePolicyType.flexible,
          coveredAmount: VndMoney.zero,
          unfundedAmount: bill.amount,
        ));
        totalUnfundedVnd += billAmountVnd;
      }
    }

    final VndMoney unfundedCommittedOutflows = VndMoney(totalUnfundedVnd);

    // 5. Envelope coverage details
    final List<EnvelopeCoverageDetail> coverageDetails = [];
    for (final env in envelopes) {
      if (env.policy == EnvelopePolicyType.protected) {
        final initialBal = env.reservedBalance.amount > 0 ? env.reservedBalance.amount : 0;
        final allocated = envelopeAllocatedMap[env.id] ?? 0;
        final rem = initialBal - allocated;
        coverageDetails.add(EnvelopeCoverageDetail(
          envelopeId: env.id,
          envelopeName: env.name,
          initialReservedBalance: VndMoney(initialBal),
          allocatedToBills: VndMoney(allocated),
          remainingProtectedReserve: VndMoney(rem),
        ));
      }
    }

    // 6. Safe-to-Spend arithmetic: Liquid Assets - Protected Reserves - Unfunded Outflows - Buffer
    final int safeToSpendVnd = liquidAssets.amount -
        protectedReserves.amount -
        unfundedCommittedOutflows.amount -
        minimumCashBuffer.amount;

    final VndMoney safeToSpend = VndMoney(safeToSpendVnd);
    final bool isDeficit = safeToSpendVnd < 0;

    // 7. Daily allowance integer division
    final int effectiveDivisor = daysRemaining > 0 ? daysRemaining : 1;
    final VndMoney dailyAllowance;
    if (safeToSpendVnd > 0) {
      dailyAllowance = VndMoney(safeToSpendVnd ~/ effectiveDivisor);
    } else {
      dailyAllowance = VndMoney.zero;
    }

    return SafeToSpendResult(
      safeToSpend: safeToSpend,
      dailyAllowance: dailyAllowance,
      isDeficit: isDeficit,
      daysRemaining: effectiveDivisor,
      breakdown: SafeToSpendBreakdown(
        liquidAssets: liquidAssets,
        protectedReserves: protectedReserves,
        unfundedCommittedOutflows: unfundedCommittedOutflows,
        minimumCashBuffer: minimumCashBuffer,
        billAllocations: billAllocations,
        envelopeCoverages: coverageDetails,
      ),
    );
  }
}
```

---

### 4.3 Blueprint 2: `lib/domain/forecasting/recurrence_calculator.dart`

```dart
/// Pure Dart calculator for recurrence schedules with anchor preservation.
class RecurrenceCalculator {
  const RecurrenceCalculator._();

  /// Determines if a Gregorian [year] is a leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Returns the number of days in [month] of [year] (1..12).
  static int daysInMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Month must be between 1 and 12');
    }
    if (month == 2) {
      return isLeapYear(year) ? 29 : 28;
    }
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month];
  }

  /// Calculates the actual day of month preserving the anchor without degradation:
  /// actual_due_day = min(anchor_day_of_month, daysInMonth(Y, M)).
  static int calculateActualDueDay(int anchorDayOfMonth, int year, int month) {
    if (anchorDayOfMonth < 1 || anchorDayOfMonth > 31) {
      throw ArgumentError.value(
        anchorDayOfMonth,
        'anchorDayOfMonth',
        'Anchor day must be between 1 and 31',
      );
    }
    final maxDays = daysInMonth(year, month);
    return anchorDayOfMonth < maxDays ? anchorDayOfMonth : maxDays;
  }

  /// Computes the next due date given the [currentDueDate], [recurrence], and optional [anchorDayOfMonth].
  ///
  /// Recurrence options:
  /// - `NONE`: throws [ArgumentError] (no next due date).
  /// - `WEEKLY`: adds 7 calendar days.
  /// - `MONTHLY`: advances to next month using `calculateActualDueDay(anchor, nextYear, nextMonth)`.
  /// - `YEARLY`: advances to next year using `calculateActualDueDay(anchor, nextYear, currentMonth)`.
  static DateTime computeNextDueDate({
    required DateTime currentDueDate,
    required String recurrence,
    int? anchorDayOfMonth,
  }) {
    final cleanRecurrence = recurrence.trim().toUpperCase();
    final anchor = anchorDayOfMonth ?? currentDueDate.day;

    switch (cleanRecurrence) {
      case 'WEEKLY':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month,
          currentDueDate.day + 7,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
          currentDueDate.millisecond,
        );

      case 'MONTHLY':
        final int nextYear = currentDueDate.month == 12 ? currentDueDate.year + 1 : currentDueDate.year;
        final int nextMonth = currentDueDate.month == 12 ? 1 : currentDueDate.month + 1;
        final int actualDay = calculateActualDueDay(anchor, nextYear, nextMonth);
        return DateTime(
          nextYear,
          nextMonth,
          actualDay,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
          currentDueDate.millisecond,
        );

      case 'YEARLY':
        final int nextYear = currentDueDate.year + 1;
        final int actualDay = calculateActualDueDay(anchor, nextYear, currentDueDate.month);
        return DateTime(
          nextYear,
          currentDueDate.month,
          actualDay,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
          currentDueDate.millisecond,
        );

      case 'NONE':
        throw ArgumentError('Cannot compute next due date for non-recurring item (NONE)');

      default:
        throw ArgumentError('Unsupported recurrence type: $recurrence');
    }
  }

  /// Generates a list of all future occurrence dates up to [horizonDate].
  static List<DateTime> generateRecurrenceDates({
    required DateTime startDueDate,
    required String recurrence,
    int? anchorDayOfMonth,
    required DateTime horizonDate,
    int maxOccurrences = 365,
  }) {
    if (recurrence.trim().toUpperCase() == 'NONE') {
      return [startDueDate];
    }

    final List<DateTime> dates = [];
    DateTime current = startDueDate;
    int count = 0;

    final horizonEndOfDay = DateTime(
      horizonDate.year,
      horizonDate.month,
      horizonDate.day,
      23,
      59,
      59,
      999,
    );

    while (!current.isAfter(horizonEndOfDay) && count < maxOccurrences) {
      dates.add(current);
      count++;
      current = computeNextDueDate(
        currentDueDate: current,
        recurrence: recurrence,
        anchorDayOfMonth: anchorDayOfMonth,
      );
    }

    return dates;
  }
}
```

---

### 4.4 Blueprint 3: `lib/domain/forecasting/cash_flow_forecaster.dart`

```dart
import 'package:dongtien/core/money/vnd_money.dart';
import 'recurrence_calculator.dart';

enum ScheduledItemKind {
  bill,
  plannedIncome;

  static ScheduledItemKind fromString(String val) {
    switch (val.toUpperCase()) {
      case 'BILL':
        return ScheduledItemKind.bill;
      case 'PLANNED_INCOME':
        return ScheduledItemKind.plannedIncome;
      default:
        throw ArgumentError('Invalid scheduled item kind: $val');
    }
  }
}

/// Domain model of a scheduled obligation or planned income.
class ForecastScheduledItem {
  final int id;
  final ScheduledItemKind kind;
  final String title;
  final VndMoney amount;
  final DateTime dueDate;
  final String recurrence;
  final int? anchorDayOfMonth;
  final String status;

  const ForecastScheduledItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.recurrence,
    this.anchorDayOfMonth,
    required this.status,
  });
}

/// A single day's projected cash flow data point.
class CashFlowTimelinePoint {
  final DateTime date;
  final VndMoney startingBalance;
  final VndMoney projectedInflows;
  final VndMoney projectedOutflows;
  final VndMoney netChange;
  final VndMoney closingBalance;
  final bool isBufferBreached;
  final VndMoney deficitAmount;
  final List<String> eventTitles;

  const CashFlowTimelinePoint({
    required this.date,
    required this.startingBalance,
    required this.projectedInflows,
    required this.projectedOutflows,
    required this.netChange,
    required this.closingBalance,
    required this.isBufferBreached,
    required this.deficitAmount,
    required this.eventTitles,
  });
}

/// Comprehensive result of 30/60/90-day cash flow forecast.
class CashFlowForecastResult {
  final VndMoney startingBalance;
  final VndMoney endingBalance;
  final VndMoney lowestBalance;
  final DateTime lowestBalanceDate;
  final VndMoney totalInflows;
  final VndMoney totalOutflows;
  final VndMoney netCashFlow;
  final bool hasDeficit;
  final DateTime? firstDeficitDate;
  final VndMoney maxDeficitAmount;
  final List<CashFlowTimelinePoint> dailyPoints;

  const CashFlowForecastResult({
    required this.startingBalance,
    required this.endingBalance,
    required this.lowestBalance,
    required this.lowestBalanceDate,
    required this.totalInflows,
    required this.totalOutflows,
    required this.netCashFlow,
    required this.hasDeficit,
    this.firstDeficitDate,
    required this.maxDeficitAmount,
    required this.dailyPoints,
  });
}

/// Pure Dart cash flow projection engine.
class CashFlowForecaster {
  const CashFlowForecaster._();

  /// Projects daily balances for [horizonDays] (30, 60, or 90 days) starting from [startDate].
  static CashFlowForecastResult project({
    required VndMoney startingLiquidAssets,
    required VndMoney minimumCashBuffer,
    required List<ForecastScheduledItem> scheduledItems,
    required DateTime startDate,
    required int horizonDays,
  }) {
    if (horizonDays <= 0) {
      throw ArgumentError.value(horizonDays, 'horizonDays', 'Horizon days must be > 0');
    }

    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endDay = DateTime(startDate.year, startDate.month, startDate.day + horizonDays - 1);

    // 1. Expand recurring and one-off items into discrete daily event buckets
    final Map<int, List<ForecastScheduledItem>> eventsByDayOffset = {};

    for (final item in scheduledItems) {
      if (item.status != 'PENDING') {
        continue; // Paid or skipped items are excluded from future forecast
      }

      final dates = RecurrenceCalculator.generateRecurrenceDates(
        startDueDate: item.dueDate,
        recurrence: item.recurrence,
        anchorDayOfMonth: item.anchorDayOfMonth,
        horizonDate: endDay,
      );

      for (final dt in dates) {
        final dtDay = DateTime(dt.year, dt.month, dt.day);
        final offset = dtDay.difference(startDay).inDays;
        if (offset >= 0 && offset < horizonDays) {
          eventsByDayOffset.putIfAbsent(offset, () => []).add(item);
        }
      }
    }

    // 2. Iterate step-by-step through each calendar day
    final List<CashFlowTimelinePoint> points = [];
    VndMoney currentBalance = startingLiquidAssets;
    VndMoney lowestBal = startingLiquidAssets;
    DateTime lowestBalDate = startDay;
    DateTime? firstDeficitDate;
    VndMoney maxDeficit = VndMoney.zero;
    int totalInflowVnd = 0;
    int totalOutflowVnd = 0;

    for (int dayIdx = 0; dayIdx < horizonDays; dayIdx++) {
      final currentDayDate = DateTime(startDay.year, startDay.month, startDay.day + dayIdx);
      final dayEvents = eventsByDayOffset[dayIdx] ?? const [];

      int dayInflowsVnd = 0;
      int dayOutflowsVnd = 0;
      final List<String> titles = [];

      for (final event in dayEvents) {
        titles.add(event.title);
        if (event.kind == ScheduledItemKind.plannedIncome) {
          dayInflowsVnd += event.amount.amount;
        } else {
          dayOutflowsVnd += event.amount.amount;
        }
      }

      totalInflowVnd += dayInflowsVnd;
      totalOutflowVnd += dayOutflowsVnd;

      final VndMoney dayInflows = VndMoney(dayInflowsVnd);
      final VndMoney dayOutflows = VndMoney(dayOutflowsVnd);
      final VndMoney netChange = dayInflows - dayOutflows;
      final VndMoney closingBalance = currentBalance + netChange;

      final bool isBufferBreached = closingBalance < minimumCashBuffer;
      final VndMoney deficit = isBufferBreached
          ? (minimumCashBuffer - closingBalance)
          : VndMoney.zero;

      if (isBufferBreached) {
        firstDeficitDate ??= currentDayDate;
        if (deficit > maxDeficit) {
          maxDeficit = deficit;
        }
      }

      if (closingBalance < lowestBal) {
        lowestBal = closingBalance;
        lowestBalDate = currentDayDate;
      }

      points.add(CashFlowTimelinePoint(
        date: currentDayDate,
        startingBalance: currentBalance,
        projectedInflows: dayInflows,
        projectedOutflows: dayOutflows,
        netChange: netChange,
        closingBalance: closingBalance,
        isBufferBreached: isBufferBreached,
        deficitAmount: deficit,
        eventTitles: titles,
      ));

      currentBalance = closingBalance;
    }

    final VndMoney totalInflows = VndMoney(totalInflowVnd);
    final VndMoney totalOutflows = VndMoney(totalOutflowVnd);
    final VndMoney netCashFlow = totalInflows - totalOutflows;

    return CashFlowForecastResult(
      startingBalance: startingLiquidAssets,
      endingBalance: currentBalance,
      lowestBalance: lowestBal,
      lowestBalanceDate: lowestBalDate,
      totalInflows: totalInflows,
      totalOutflows: totalOutflows,
      netCashFlow: netCashFlow,
      hasDeficit: firstDeficitDate != null,
      firstDeficitDate: firstDeficitDate,
      maxDeficitAmount: maxDeficit,
      dailyPoints: points,
    );
  }
}
```

---

### 4.5 Blueprint 4: Obligation Conversion Workflow & Ledger Integration

When an obligation is marked as paid, the persistence layer executes this atomic workflow inside `db.transaction()`:

```text
[ User initiates "Đã thanh toán" ]
               │
               ▼
┌──────────────────────────────────────────────┐
│ Verify Scheduled Item                        │
│ Assert item.status == 'PENDING'              │
└──────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ 1. Post Real Journal Transaction             │
│   - tx_type = 'EXPENSE' (if BILL)            │
│               'INCOME' (if PLANNED_INCOME)   │
│   - Debit & Credit legs balanced             │
│   - occurred_at = paidDate                   │
│ 2. Linked Envelope SPEND Movement            │
│   - If item.linked_envelope_id != null:      │
│     Insert 'SPEND' envelope_movement         │
│     Update envelope.reserved_balance_vnd     │
└──────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ 3. Update Scheduled Item                     │
│   - status = 'PAID_OR_RECEIVED'              │
│   - paid_transaction_id = tx.id              │
└──────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ 4. Recurrence Advancement                    │
│   - If recurrence != 'NONE':                 │
│     Compute next due date via                │
│     RecurrenceCalculator.computeNextDueDate()│
│     Insert new PENDING scheduled_items row   │
│     with same anchor_day_of_month            │
└──────────────────────────────────────────────┘
```

#### Invariant Verification:
1. **Zero Double-Counting**:
   - Before payment: Item is `PENDING` $\to$ counted in Safe-to-Spend `unfundedCommittedOutflows`.
   - After payment: Item is `PAID_OR_RECEIVED` $\to$ excluded from Safe-to-Spend. Liquid assets drop by transaction amount. Next recurring item is scheduled in the future period.
   - Result: Obligation is never counted twice.

---

### 4.6 Blueprint 5: Concrete Unit Test Plan

#### Test File 1: `test/unit/safe_to_spend_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/forecasting/safe_to_spend_calculator.dart';

void main() {
  group('SafeToSpendCalculator Tests', () {
    final now = DateTime(2026, 10, 27);
    final horizon = DateTime(2026, 10, 31);

    test('Scenario 1 Base: Liquid assets only, zero envelopes, zero buffer', () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [],
        pendingBills: [],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizon,
      );

      expect(result.safeToSpend.amount, 10000000);
      expect(result.isDeficit, isFalse);
      expect(result.breakdown.protectedReserves.amount, 0);
      expect(result.breakdown.unfundedCommittedOutflows.amount, 0);
    });

    test('Scenario 5: Protected envelope deduction', () {
      final env = EnvelopeSnapshot(
        id: 1,
        name: 'Quỹ khẩn cấp',
        policy: EnvelopePolicyType.protected,
        reservedBalance: VndMoney(1000000),
      );

      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(29900000),
        envelopes: [env],
        pendingBills: [],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizon,
      );

      expect(result.safeToSpend.amount, 28900000);
      expect(result.breakdown.protectedReserves.amount, 1000000);
    });

    test('Flexible envelope is NOT deducted from Safe-to-Spend', () {
      final env = EnvelopeSnapshot(
        id: 2,
        name: 'Quỹ ăn chơi',
        policy: EnvelopePolicyType.flexible,
        reservedBalance: VndMoney(2000000),
      );

      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [env],
        pendingBills: [],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizon,
      );

      expect(result.safeToSpend.amount, 10000000);
      expect(result.breakdown.protectedReserves.amount, 0);
    });

    test('Scenario 11: Pending Bill linked to Protected Envelope (Zero Double Counting)', () {
      final protectedEnv = EnvelopeSnapshot(
        id: 1,
        name: 'Điện Nước',
        policy: EnvelopePolicyType.protected,
        reservedBalance: VndMoney(1000000),
      );

      final bill = PendingBillItem(
        id: 101,
        title: 'Tiền Điện',
        amount: VndMoney(1500000),
        dueDate: DateTime(2026, 10, 29),
        linkedEnvelopeId: 1,
      );

      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [protectedEnv],
        pendingBills: [bill],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizon,
      );

      // Protected envelope covers 1.000.000 ₫; unfunded is 500.000 ₫
      expect(result.breakdown.protectedReserves.amount, 1000000);
      expect(result.breakdown.unfundedCommittedOutflows.amount, 500000);
      expect(result.safeToSpend.amount, 8500000); // 10M - 1M - 500k = 8.5M
    });

    test('Multiple bills linked to the same protected envelope exhaust reserve chronologically', () {
      final protectedEnv = EnvelopeSnapshot(
        id: 1,
        name: 'Điện Nước',
        policy: EnvelopePolicyType.protected,
        reservedBalance: VndMoney(1000000),
      );

      final bill1 = PendingBillItem(
        id: 101,
        title: 'Tiền Nước',
        amount: VndMoney(600000),
        dueDate: DateTime(2026, 10, 28),
        linkedEnvelopeId: 1,
      );

      final bill2 = PendingBillItem(
        id: 102,
        title: 'Tiền Điện',
        amount: VndMoney(700000),
        dueDate: DateTime(2026, 10, 30),
        linkedEnvelopeId: 1,
      );

      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [protectedEnv],
        pendingBills: [bill2, bill1], // Pass unordered to test sorting
        now: now,
        horizonDate: horizon,
        minimumCashBuffer: VndMoney.zero,
      );

      // bill1 (600k) covered completely; remaining envelope balance = 400k
      // bill2 (700k) covered 400k; unfunded = 300k
      // Total unfunded = 300k
      // Total subtracted = 1M (reserve) + 300k (unfunded) = 1.3M (matches 600k + 700k)
      expect(result.breakdown.unfundedCommittedOutflows.amount, 300000);
      expect(result.safeToSpend.amount, 8700000);
    });

    test('Scenario 12: Negative Safe-to-Spend & Deficit Breakdown', () {
      final protectedEnv = EnvelopeSnapshot(
        id: 1,
        name: 'Dự phòng',
        policy: EnvelopePolicyType.protected,
        reservedBalance: VndMoney(1500000),
      );

      final bill = PendingBillItem(
        id: 1,
        title: 'Tiền mạng',
        amount: VndMoney(1000000),
        dueDate: DateTime(2026, 10, 28),
        linkedEnvelopeId: null,
      );

      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(2000000),
        envelopes: [protectedEnv],
        pendingBills: [bill],
        minimumCashBuffer: VndMoney(1000000),
        now: now,
        horizonDate: horizon,
        daysRemainingOverride: 5,
      );

      // 2.000.000 - 1.500.000 - 1.000.000 - 1.000.000 = -1.500.000 ₫
      expect(result.safeToSpend.amount, -1500000);
      expect(result.isDeficit, isTrue);
      expect(result.dailyAllowance.amount, 0); // 0 ₫/ngày on deficit
    });

    test('Daily allowance calculation with integer division', () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [],
        pendingBills: [],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizon,
        daysRemainingOverride: 3,
      );

      expect(result.safeToSpend.amount, 10000000);
      expect(result.dailyAllowance.amount, 3333333); // 10.000.000 ~/ 3
    });

    test('Bills beyond horizon date are excluded', () {
      final billBeyond = PendingBillItem(
        id: 999,
        title: 'Tháng sau',
        amount: VndMoney(5000000),
        dueDate: DateTime(2026, 11, 15),
        linkedEnvelopeId: null,
      );

      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [],
        pendingBills: [billBeyond],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizon,
      );

      expect(result.safeToSpend.amount, 10000000);
      expect(result.breakdown.unfundedCommittedOutflows.amount, 0);
    });
  });
}
```

---

#### Test File 2: `test/unit/recurrence_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/domain/forecasting/recurrence_calculator.dart';

void main() {
  group('RecurrenceCalculator Tests', () {
    test('daysInMonth handles regular months and leap years correctly', () {
      expect(RecurrenceCalculator.daysInMonth(2026, 1), 31);
      expect(RecurrenceCalculator.daysInMonth(2026, 2), 28); // 2026 non-leap
      expect(RecurrenceCalculator.daysInMonth(2028, 2), 29); // 2028 leap
      expect(RecurrenceCalculator.daysInMonth(2000, 2), 29); // 2000 leap (div 400)
      expect(RecurrenceCalculator.daysInMonth(2100, 2), 28); // 2100 non-leap (div 100 not 400)
      expect(RecurrenceCalculator.daysInMonth(2026, 4), 30);
    });

    test('Scenario 15 Part B: Day 31 anchor preserved across February and into March', () {
      const anchor = 31;

      // 1. Jan 31 -> Feb 28 (2026, non-leap year)
      final janDate = DateTime(2026, 1, 31, 9, 0);
      final febDate = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: janDate,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: anchor,
      );
      expect(febDate, DateTime(2026, 2, 28, 9, 0));

      // 2. Feb 28 -> Mar 31 (Restores to 31 with zero anchor degradation!)
      final marDate = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: febDate,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: anchor,
      );
      expect(marDate, DateTime(2026, 3, 31, 9, 0));

      // 3. Mar 31 -> Apr 30
      final aprDate = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: marDate,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: anchor,
      );
      expect(aprDate, DateTime(2026, 4, 30, 9, 0));

      // 4. Apr 30 -> May 31
      final mayDate = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: aprDate,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: anchor,
      );
      expect(mayDate, DateTime(2026, 5, 31, 9, 0));
    });

    test('Scenario 15 Part B: Leap year 2028 February schedules on Feb 29 and restores to Mar 31', () {
      const anchor = 31;
      final janDate2028 = DateTime(2028, 1, 31);
      final febDate2028 = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: janDate2028,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: anchor,
      );
      expect(febDate2028, DateTime(2028, 2, 29));

      final marDate2028 = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: febDate2028,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: anchor,
      );
      expect(marDate2028, DateTime(2028, 3, 31));
    });

    test('Weekly recurrence adds exactly 7 days', () {
      final date = DateTime(2026, 10, 10, 10, 0);
      final next = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: date,
        recurrence: 'WEEKLY',
      );
      expect(next, DateTime(2026, 10, 17, 10, 0));
    });

    test('Yearly recurrence on Feb 29 leap year advances to Feb 28 in non-leap years', () {
      final leapYearDate = DateTime(2028, 2, 29);
      final nextYear = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: leapYearDate,
        recurrence: 'YEARLY',
        anchorDayOfMonth: 29,
      );
      expect(nextYear, DateTime(2029, 2, 28));
    });

    test('Year boundary rollover in December', () {
      final decDate = DateTime(2026, 12, 31);
      final nextYearJan = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: decDate,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(nextYearJan, DateTime(2027, 1, 31));
    });
  });
}
```

---

## 5. VERIFICATION METHOD

To independently verify the implementation blueprint and ensure that downstream implementation passes all quality gates:

1. **Unit Test Execution**:
   Once the implementer creates the domain files in `lib/domain/forecasting/` and unit test files in `test/unit/`:
   ```bash
   flutter test test/unit/safe_to_spend_test.dart
   flutter test test/unit/recurrence_test.dart
   ```
   *Expected Output*: All test assertions pass with zero failures.

2. **Full Test Suite & Quality Gates**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   flutter test --coverage
   ```
   *Expected Output*: Exit code 0 across formatting, static analysis, and test execution.

3. **Scenario Coverage Inspection**:
   - Check Scenario 5 (Protected Envelope allocation).
   - Check Scenario 11 (Scheduled Bill 1.5M with 1.0M Protected Envelope).
   - Check Scenario 12 (Negative Safe-to-Spend deficit calculation and daily allowance 0 ₫).
   - Check Scenario 15 (Drift-Free Recurrence from Jan 31 to Feb 28/29 to Mar 31).

4. **Invalidation Conditions**:
   - Any use of floating-point `double` or `float` for currency.
   - Any clamping of `Safe-to-Spend` to zero on deficit.
   - Any date drift where `anchor_day_of_month = 31` becomes 28 in March.
   - Any double subtraction of a pending bill whose linked protected envelope was already deducted.
