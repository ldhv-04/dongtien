# Handoff Report: R3 — Synchronize `periodStartDay` Across Dashboard, Plans, Notifications, and Reports

**Explorer ID**: `explorer_m1_3`  
**Milestone**: M1 (Investigation & Specification)  
**Objective**: Complete investigation, mathematical design, architecture mapping, and verification plan for Requirement R3.

---

## 1. Observation

Direct code audit of the workspace reveals the following exact locations and states:

### 1.1 Storage and Definition of `periodStartDay`
1. **Database Schema (`lib/core/database/app_database.dart:229, 245`)**:
   - `Settings` table defines `IntColumn get periodStartDay => integer().withDefault(const Constant(1))();`
   - Custom constraint enforces `CHECK (period_start_day >= 1 AND period_start_day <= 31)`.
   - Defaults to `1` (calendar month).
2. **Settings UI (`lib/features/reports_settings/presentation/settings_screen.dart:198-218`)**:
   - Dropdown allows user selection from `1` to `28`: `currentPeriodDay.clamp(1, 28)` and `List.generate(28, (i) => i + 1)`.
   - Calls `reportsSettingsControllerProvider.notifier.updatePeriodStartDay(val)`.
3. **Settings Controller (`lib/features/reports_settings/presentation/providers/reports_settings_providers.dart:182-196`)**:
   - Validates `if (day < 1 || day > 28) throw ArgumentError('Period start day must be between 1 and 28');`
   - Writes `SettingsCompanion(periodStartDay: Value(day))` to row `id = 1`.
   - Invalidates `settingsStreamProvider` and `reportsSummaryProvider`.
   - **Gap observed**: It does NOT invalidate `currentMonthlyBudgetSummaryProvider`.

### 1.2 Hardcoded Calendar Month Boundaries Identified Across Codebase
A full audit for calendar-month hardcoding (`DateTime(now.year, now.month, 1)` and `now.year * 100 + now.month`) revealed 5 specific locations:

1. **`currentMonthlyBudgetSummaryProvider` (`lib/features/dashboard/presentation/providers/dashboard_providers.dart:86-140`)**:
   - Line 89: `final now = DateTime.now();`
   - Line 90: `final yearMonth = now.year * 100 + now.month;`
   - Line 93: `final startOfMonthMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;`
   - Line 95: `final endOfMonthMs = DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch;`
   - Line 122: `WHERE b.year_month = ?` (exact match on `yearMonth`)
   - Lines 134-139: `readsFrom: { db.categoryBudgets, db.categories, db.journalPostings, db.journalTransactions }`
   - **Gaps observed**:
     - `periodStartDay` is completely ignored.
     - `db.settings` is NOT included in `readsFrom`.
     - `settingsStreamProvider` is not watched.
     - Does not support fallback matching for budgets created before changing `periodStartDay`.
2. **`safeToSpendProvider` (`lib/features/dashboard/presentation/providers/safe_to_spend_provider.dart:69-72`)**:
   - Lines 69-72: When `nextIncome == null`:
     ```dart
     final lastDay = DateTime(now.year, now.month + 1, 0).day;
     horizonDate = DateTime(now.year, now.month, lastDay, 23, 59, 59);
     ```
   - **Gap observed**: Hardcodes end of calendar month instead of active billing cycle end date.
3. **`PlansController.upsertCategoryBudget` (`lib/features/plans/presentation/providers/plans_providers.dart:139-140`)**:
   - Line 140: `final ym = yearMonth ?? (now.year * 100 + now.month);`
   - **Gap observed**: Falls back to calendar `YYYYMM` instead of current billing cycle `yearMonth`.
   - Note: `deleteCategoryBudget` does not exist yet (part of R2/R3).
4. **`NotificationScheduler.checkCategoryBudgetAlert` (`lib/core/notifications/notification_scheduler.dart:264-293`)**:
   - Line 265: `final yearMonth = now.year * 100 + now.month;`
   - Line 274: `final startOfMonthMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;`
   - Line 275: `final endOfMonthMs = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;`
   - **Gap observed**: Loads `settings` at line 250, but ignores `settings.periodStartDay`.
5. **`reportsSummaryProvider` (`lib/features/reports_settings/presentation/providers/reports_settings_providers.dart:36-46`)**:
   - Line 37: `final periodMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';`
   - Line 39: `final startOfMonthMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;`
   - Line 40: `final endOfMonthMs = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;`
   - **Gap observed**: Computes income, transfers, and category spending over calendar month instead of billing cycle.
6. **UI Cards (`SpendingVsBudgetCard.dart` & `CategoryBudgetsView.dart`)**:
   - `SpendingVsBudgetCard` does not display any cycle date range or label.
   - `CategoryBudgetsView` shows `'Tổng ngân sách tháng này'` with no cycle date range.

---

## 2. Logic Chain

From the observations above, we establish the step-by-step logic required to synchronize `periodStartDay` reliably:

### 2.1 The Mathematical Anchor & Domain Invariant
1. In Vietnam personal finance and payroll practices, salary and billing cycles frequently begin on days like the 5th, 10th, 15th, 20th, or 25th rather than day 1.
2. Every calendar month has at least 28 days (including non-leap February). By bounding `periodStartDay` strictly to `1..28`:
   - Day `periodStartDay` is mathematically guaranteed to exist in EVERY month.
   - Zero calendar-drift anomalies or missing-day clipping can ever occur.
3. For any `referenceDate` and `periodStartDay \in [1, 28]`:
   - If `periodStartDay == 1`:
     - `cycleStart` = `DateTime(referenceDate.year, referenceDate.month, 1, 0, 0, 0, 0)`
     - `cycleEndExclusive` = `DateTime(referenceDate.year, referenceDate.month + 1, 1, 0, 0, 0, 0)`
   - If `periodStartDay > 1`:
     - If `referenceDate.day >= periodStartDay`:
       - The active cycle started in the current month on day `periodStartDay`.
       - `cycleStart` = `DateTime(referenceDate.year, referenceDate.month, periodStartDay, 0, 0, 0, 0)`
       - `cycleEndExclusive` = `DateTime(nextYear, nextMonth, periodStartDay, 0, 0, 0, 0)`
     - If `referenceDate.day < periodStartDay`:
       - The active cycle started in the previous month on day `periodStartDay`.
       - `cycleStart` = `DateTime(prevYear, prevMonth, periodStartDay, 0, 0, 0, 0)`
       - `cycleEndExclusive` = `DateTime(referenceDate.year, referenceDate.month, periodStartDay, 0, 0, 0, 0)`
   - `cycleEndInclusive` is always:
     `DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 23, 59, 59, 999)` where `dayBefore = cycleEndExclusive.subtract(Duration(days: 1))`.
   - `yearMonth` is deterministic: `cycleStart.year * 100 + cycleStart.month`.

### 2.2 Preserving User Budgets Across Cycle Transitions (Graceful Fallback)
1. When a user creates a budget on Oct 1 with default `periodStartDay = 1`, the budget row is stored with `year_month = 202610`.
2. If the user later changes `periodStartDay = 15` on Oct 10:
   - The active cycle now runs from Sep 15 to Oct 15 (`yearMonth = 202609`).
   - If the query only looked for `year_month = 202609`, the user's previously set budget for October would suddenly vanish!
3. Therefore, queries for active budgets must search:
   `WHERE b.year_month IN (activeCycleYearMonth, calendarYearMonth)`
   and deduplicate by `category_id` in Dart, giving precedence to `activeCycleYearMonth`.
   If a budget exists for `activeCycleYearMonth`, it is used. If not, the `calendarYearMonth` budget serves as a seamless fallback.

---

## 3. Caveats

1. **`Settings` Table Constraint**:
   The table custom constraint in `app_database.dart` currently allows `period_start_day >= 1 AND period_start_day <= 31`. The UI and `BillingCycleCalculator` strictly enforce `1..28` to eliminate month-end drift in February. `BillingCycleCalculator.calculate` should validate `1 <= periodStartDay <= 28`. If a value > 28 is encountered in legacy data, `periodStartDay.clamp(1, 28)` ensures crash-free safety.
2. **Reactivity**:
   In Riverpod, watching `settingsStreamProvider` in `currentMonthlyBudgetSummaryProvider` and `safeToSpendProvider` ensures immediate reactive recomputation whenever `periodStartDay` changes. In addition, including `db.settings` in Drift's `readsFrom` table set guarantees that Drift's underlying SQLite table stream fires automatically on any `settings` table update.
3. **No Drift / Flutter in Domain**:
   `BillingCycleCalculator` must reside in `lib/domain/budgeting/billing_cycle_calculator.dart` and import zero Flutter or Drift libraries, preserving Clean Architecture rule AGENTS.md §2.

---

## 4. Conclusion & Proposed Implementation Plan

### 4.1 New Domain Engine: `BillingCycleCalculator`
**Target File**: `lib/domain/budgeting/billing_cycle_calculator.dart` (NEW FILE)

```dart
/// Pure Dart value object representing an active billing cycle.
class BillingCycle {
  final DateTime cycleStart;
  final DateTime cycleEndExclusive;
  final DateTime cycleEndInclusive;
  final int yearMonth;
  final int periodStartDay;

  const BillingCycle({
    required this.cycleStart,
    required this.cycleEndExclusive,
    required this.cycleEndInclusive,
    required this.yearMonth,
    required this.periodStartDay,
  });

  bool get isCalendarMonth => periodStartDay == 1;

  /// Formatted cycle range: e.g. "15/10 – 14/11" or "01/10 – 31/10".
  /// Spanning years: "15/12/2026 – 14/01/2027".
  String formatCycleRange({bool includeYear = false}) {
    final startDay = cycleStart.day.toString().padLeft(2, '0');
    final startMonth = cycleStart.month.toString().padLeft(2, '0');
    final endDay = cycleEndInclusive.day.toString().padLeft(2, '0');
    final endMonth = cycleEndInclusive.month.toString().padLeft(2, '0');

    if (includeYear || cycleStart.year != cycleEndInclusive.year) {
      return '$startDay/$startMonth/${cycleStart.year} – $endDay/$endMonth/${cycleEndInclusive.year}';
    }
    return '$startDay/$startMonth – $endDay/$endMonth';
  }

  /// Label for reports screen period header.
  String get reportPeriodLabel {
    final ymLabel =
        '${cycleStart.month.toString().padLeft(2, '0')}/${cycleStart.year}';
    if (isCalendarMonth) {
      return ymLabel;
    }
    return '$ymLabel (${formatCycleRange()})';
  }
}

/// Pure Dart calculator for billing cycles.
class BillingCycleCalculator {
  const BillingCycleCalculator._();

  static BillingCycle calculate(DateTime referenceDate, int periodStartDay) {
    if (periodStartDay < 1 || periodStartDay > 28) {
      throw ArgumentError.value(
        periodStartDay,
        'periodStartDay',
        'Billing cycle start day must be between 1 and 28',
      );
    }

    int startYear = referenceDate.year;
    int startMonth = referenceDate.month;

    if (periodStartDay > 1 && referenceDate.day < periodStartDay) {
      if (startMonth == 1) {
        startYear -= 1;
        startMonth = 12;
      } else {
        startMonth -= 1;
      }
    }

    final cycleStart =
        DateTime(startYear, startMonth, periodStartDay, 0, 0, 0, 0);

    int endYear = startYear;
    int endMonth = startMonth + 1;
    if (endMonth > 12) {
      endYear += 1;
      endMonth = 1;
    }
    final cycleEndExclusive =
        DateTime(endYear, endMonth, periodStartDay, 0, 0, 0, 0);

    final dayBefore = cycleEndExclusive.subtract(const Duration(days: 1));
    final cycleEndInclusive = DateTime(
      dayBefore.year,
      dayBefore.month,
      dayBefore.day,
      23,
      59,
      59,
      999,
    );

    final yearMonth = startYear * 100 + startMonth;

    return BillingCycle(
      cycleStart: cycleStart,
      cycleEndExclusive: cycleEndExclusive,
      cycleEndInclusive: cycleEndInclusive,
      yearMonth: yearMonth,
      periodStartDay: periodStartDay,
    );
  }
}
```

### 4.2 Domain Model Extension: `MonthlyBudgetSummary`
**Target File**: `lib/domain/budgeting/category_budget_progress.dart`
- Add `final String cycleLabel;` (default `''`) to `MonthlyBudgetSummary`.
- Add `String cycleLabel = ''` parameter to `CategoryBudgetTracker.evaluateSummary`.

### 4.3 Provider Updates

#### A. `currentMonthlyBudgetSummaryProvider` (`lib/features/dashboard/presentation/providers/dashboard_providers.dart`)
```dart
final currentMonthlyBudgetSummaryProvider =
    StreamProvider<MonthlyBudgetSummary>((ref) {
  final db = ref.watch(databaseProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final periodStartDay = (settingsAsync.value?.periodStartDay ?? 1).clamp(1, 28);

  final now = DateTime.now();
  final cycle = BillingCycleCalculator.calculate(now, periodStartDay);
  final activeCycleYearMonth = cycle.yearMonth;
  final calendarYearMonth = now.year * 100 + now.month;

  final startMs = cycle.cycleStart.millisecondsSinceEpoch;
  final endMs = cycle.cycleEndExclusive.millisecondsSinceEpoch;

  const query = '''
SELECT 
  b.category_id,
  c.name AS category_name,
  b.year_month,
  b.limit_vnd,
  b.alert_threshold_pct,
  COALESCE(spent.gross_expense, 0) AS gross_expense,
  COALESCE(spent.refund_credits, 0) AS refund_credits
FROM category_budgets b
JOIN categories c ON b.category_id = c.id
LEFT JOIN (
  SELECT 
    p.category_id,
    SUM(p.debit_vnd) AS gross_expense,
    SUM(p.credit_vnd) AS refund_credits
  FROM journal_postings p
  JOIN journal_transactions t ON p.transaction_id = t.id
  WHERE t.occurred_at >= ? 
    AND t.occurred_at < ? 
    AND t.status = 'POSTED' 
    AND t.tx_type != 'REVERSAL'
    AND p.category_id IS NOT NULL
  GROUP BY p.category_id
) spent ON b.category_id = spent.category_id
WHERE b.year_month IN (?, ?)
ORDER BY b.category_id ASC;
''';

  return db
      .customSelect(
        query,
        variables: [
          Variable.withInt(startMs),
          Variable.withInt(endMs),
          Variable.withInt(activeCycleYearMonth),
          Variable.withInt(calendarYearMonth),
        ],
        readsFrom: {
          db.settings,
          db.categoryBudgets,
          db.categories,
          db.journalPostings,
          db.journalTransactions,
        },
      )
      .watch()
      .map((rows) {
        final Map<int, CategoryBudgetProgress> progressesByCat = {};
        for (final row in rows) {
          final catId = row.read<int>('category_id');
          final rowYm = row.read<int>('year_month');
          if (progressesByCat.containsKey(catId) &&
              progressesByCat[catId]!.yearMonth == activeCycleYearMonth) {
            continue;
          }
          final progress = CategoryBudgetTracker.evaluateCategoryBudget(
            categoryId: catId,
            categoryName: row.read<String>('category_name'),
            yearMonth: rowYm,
            limitVnd: VndMoney(row.read<int>('limit_vnd')),
            grossExpense: VndMoney(row.read<int>('gross_expense')),
            refundCredits: VndMoney(row.read<int>('refund_credits')),
            alertThresholdPct: row.read<int>('alert_threshold_pct'),
          );
          if (rowYm == activeCycleYearMonth || !progressesByCat.containsKey(catId)) {
            progressesByCat[catId] = progress;
          }
        }

        return CategoryBudgetTracker.evaluateSummary(
          yearMonth: activeCycleYearMonth,
          categoryProgresses: progressesByCat.values.toList(),
          cycleLabel: cycle.formatCycleRange(),
        );
      });
});
```

#### B. `safeToSpendProvider` (`lib/features/dashboard/presentation/providers/safe_to_spend_provider.dart`)
```dart
  final now = DateTime.now();
  final nextIncome = nextIncomeAsync.value;
  final DateTime horizonDate;
  if (nextIncome != null) {
    horizonDate = DateTime.fromMillisecondsSinceEpoch(nextIncome.dueDateMs);
  } else {
    final periodStartDay = (settings?.periodStartDay ?? 1).clamp(1, 28);
    final cycle = BillingCycleCalculator.calculate(now, periodStartDay);
    horizonDate = cycle.cycleEndInclusive;
  }
```

#### C. `PlansController` (`lib/features/plans/presentation/providers/plans_providers.dart`)
1. In `upsertCategoryBudget`:
   ```dart
   final db = ref.read(databaseProvider);
   final now = DateTime.now();
   int ym = yearMonth ?? 0;
   if (yearMonth == null) {
     final settings = await (db.select(db.settings)..where((s) => s.id.equals(1))).getSingleOrNull();
     final periodStartDay = (settings?.periodStartDay ?? 1).clamp(1, 28);
     ym = BillingCycleCalculator.calculate(now, periodStartDay).yearMonth;
   }
   ```
2. In `deleteCategoryBudget`:
   ```dart
   Future<void> deleteCategoryBudget(int categoryId, {int? yearMonth}) async {
     state = const AsyncValue.loading();
     try {
       final db = ref.read(databaseProvider);
       final now = DateTime.now();
       int ym = yearMonth ?? 0;
       if (yearMonth == null) {
         final settings = await (db.select(db.settings)..where((s) => s.id.equals(1))).getSingleOrNull();
         final periodStartDay = (settings?.periodStartDay ?? 1).clamp(1, 28);
         ym = BillingCycleCalculator.calculate(now, periodStartDay).yearMonth;
       }

       await (db.delete(db.categoryBudgets)
             ..where((b) =>
                 b.categoryId.equals(categoryId) & b.yearMonth.equals(ym)))
           .go();
       state = const AsyncValue.data(null);
     } catch (e, st) {
       state = AsyncValue.error(e, st);
       rethrow;
     }
   }
   ```

#### D. `NotificationScheduler.checkCategoryBudgetAlert` (`lib/core/notifications/notification_scheduler.dart`)
```dart
  final now = DateTime.now();
  final periodStartDay = (settings.periodStartDay).clamp(1, 28);
  final cycle = BillingCycleCalculator.calculate(now, periodStartDay);
  final activeCycleYearMonth = cycle.yearMonth;
  final calendarYearMonth = now.year * 100 + now.month;

  var budget = await (db.select(db.categoryBudgets)
        ..where((b) =>
            b.categoryId.equals(categoryId) &
            b.yearMonth.equals(activeCycleYearMonth)))
      .getSingleOrNull();
  if (budget == null && activeCycleYearMonth != calendarYearMonth) {
    budget = await (db.select(db.categoryBudgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              b.yearMonth.equals(calendarYearMonth)))
        .getSingleOrNull();
  }
  if (budget == null || budget.limitVnd <= 0) return;

  final startMs = cycle.cycleStart.millisecondsSinceEpoch;
  final endMs = cycle.cycleEndInclusive.millisecondsSinceEpoch;

  final rows = await db.customSelect(
    '''
    SELECT COALESCE(SUM(p.debit_vnd), 0) - COALESCE(SUM(p.credit_vnd), 0) AS net_spent
    FROM journal_postings p
    JOIN journal_transactions t ON p.transaction_id = t.id
    WHERE p.category_id = ?
      AND t.occurred_at >= ? AND t.occurred_at <= ?
      AND t.status = 'POSTED' AND t.tx_type != 'REVERSAL'
    ''',
    variables: [
      Variable.withInt(categoryId),
      Variable.withInt(startMs),
      Variable.withInt(endMs),
    ],
    readsFrom: {db.journalPostings, db.journalTransactions},
  ).get();
```

#### E. `reportsSummaryProvider` (`lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`)
```dart
  final settings = await (db.select(db.settings)..where((s) => s.id.equals(1))).getSingleOrNull();
  final periodStartDay = (settings?.periodStartDay ?? 1).clamp(1, 28);
  final now = DateTime.now();
  final cycle = BillingCycleCalculator.calculate(now, periodStartDay);

  final startMs = cycle.cycleStart.millisecondsSinceEpoch;
  final endMs = cycle.cycleEndInclusive.millisecondsSinceEpoch;

  final dateVars = [
    Variable.withInt(startMs),
    Variable.withInt(endMs),
  ];

  final periodMonth = cycle.isCalendarMonth
      ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
      : '${cycle.cycleStart.year}-${cycle.cycleStart.month.toString().padLeft(2, '0')} (${cycle.formatCycleRange()})';
```
And in `updatePeriodStartDay`:
```dart
ref.invalidate(settingsStreamProvider);
ref.invalidate(reportsSummaryProvider);
ref.invalidate(currentMonthlyBudgetSummaryProvider);
```

#### F. UI Presentation Updates
1. **`SpendingVsBudgetCard`** (`lib/features/dashboard/presentation/widgets/spending_vs_budget_card.dart`):
   Display `Chu kỳ: ${summary.cycleLabel}` below `CHI TIÊU & NGÂN SÁCH THÁNG` with tabular figures:
   ```dart
   if (summary.cycleLabel.isNotEmpty) ...[
     const SizedBox(height: 2),
     Text(
       'Chu kỳ: ${summary.cycleLabel}',
       style: AppTypography.caption.copyWith(
         color: AppColors.textSecondary,
         fontFeatures: const [FontFeature.tabularFigures()],
       ),
     ),
   ],
   ```
2. **`CategoryBudgetsView`** (`lib/features/plans/presentation/widgets/category_budgets_view.dart`):
   Display `Chu kỳ: ${summary.cycleLabel}` below `Tổng ngân sách tháng này` with tabular figures:
   ```dart
   if (summary.cycleLabel.isNotEmpty) ...[
     const SizedBox(height: 2),
     Text(
       'Chu kỳ: ${summary.cycleLabel}',
       style: VndFormatter.withTabularFigures(
         AppTypography.caption.copyWith(
           color: AppColors.textSecondary,
         ),
       ),
     ),
   ],
   ```

---

## 5. Verification Method

### 5.1 Automated Unit Tests (`test/unit/billing_cycle_calculator_test.dart`)
1. Test all 9 boundary conditions:
   - Day 1 (standard calendar month)
   - Day 15 reference on or after anchor
   - Day 15 reference before anchor
   - Exact anchor boundary (`referenceDate.day == periodStartDay`)
   - December to January transition
   - January before anchor (resolving to previous year December)
   - Day 28 in February non-leap (2026)
   - Day 28 in February leap year (2028)
   - Input validation (`ArgumentError` for `day < 1 || day > 28`)
2. Verify `formatCycleRange()` and `reportPeriodLabel`.

### 5.2 Provider Reactive Tests (`test/unit/billing_cycle_providers_test.dart`)
1. Create in-memory `AppDatabase`.
2. Seed settings with `periodStartDay = 15`.
3. Add expense transaction on Day 10 (previous cycle) and Day 18 (active cycle).
4. Verify `currentMonthlyBudgetSummaryProvider` spending excludes the Day 10 transaction.
5. Update `periodStartDay` to 1 in settings.
6. Verify `currentMonthlyBudgetSummaryProvider` immediately shifts to calendar month window and includes the Day 10 transaction.
7. Verify `safeToSpendProvider` with `nextIncome == null` produces `horizonDate` equal to `cycleEndInclusive`.
8. Verify `reportsSummaryProvider` aggregates income, expenses, and net spending bounded by `[cycleStart, cycleEndInclusive]`.

### 5.3 Widget Tests (`test/widget/billing_cycle_ui_test.dart`)
1. Verify `SpendingVsBudgetCard` displays `'Chu kỳ: 15/10 – 14/11'` with `FontFeature.tabularFigures()`.
2. Verify `CategoryBudgetsView` displays `'Chu kỳ: 15/10 – 14/11'` with `FontFeature.tabularFigures()`.

### 5.4 Full Suite Command Execution
```bash
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
flutter test
```
All existing 308 tests plus the new unit, provider, and widget tests must pass with 100% green status.
