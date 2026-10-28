## 2026-10-28T18:40:10Z
You are Explorer 3 on Project Đồng Tiền.
Your working directory is: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_3`
All your intermediate progress and final report must be written inside your working directory (`progress.md`, `handoff.md`).

MANDATORY READING:
1. `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (Specifically read section `## 2026-10-28T18:36:33Z` and Requirement R3).
2. `c:\Users\coihu12\Documents\App\AGENTS.md` (Architectural invariants, integer VND, clean architecture rules).
3. `c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_3\SCOPE.md`

YOUR INVESTIGATION OBJECTIVE: R3 (Synchronize `periodStartDay` Across Dashboard, Plans, Notifications, Reports)
1. Inspect how `periodStartDay` is defined and stored:
   - Check `Settings` table in `lib/core/database/` and settings provider in `lib/features/reports_settings/`.
2. Design `lib/domain/budgeting/billing_cycle_calculator.dart`:
   - Pure Dart class (zero Flutter/Drift imports).
   - Input: `(DateTime referenceDate, int periodStartDay)` where `periodStartDay` is 1..28.
   - Outputs: `cycleStart` (00:00:00.000), `cycleEndExclusive`, `cycleEndInclusive` (23:59:59.999), `yearMonth` (`cycleStart.year * 100 + cycleStart.month`), and formatted cycle label (e.g. `15/10/2026 – 14/11/2026` or `15/10 – 14/11`).
   - Edge cases: reference date before vs on/after `periodStartDay`, leap years, month boundaries (Feb, Dec-Jan).
3. Inspect everywhere currently hardcoding `DateTime(now.year, now.month, 1)`:
   - `currentMonthlyBudgetSummaryProvider` in `lib/features/dashboard/presentation/providers/dashboard_providers.dart`: how to watch `settingsStreamProvider` (or `db.select(db.settings).watchSingle()`), compute `[cycleStart, cycleEndExclusive)`, match budgets where `b.year_month IN (activeCycleYearMonth, calendarYearMonth)`, and ensure `readsFrom` tables are complete.
   - `PlansController.upsertCategoryBudget` & `deleteCategoryBudget` in `lib/features/plans/presentation/providers/plans_providers.dart`.
   - `NotificationScheduler.checkCategoryBudgetAlert` in `lib/core/notifications/notification_scheduler.dart`.
   - `safeToSpendProvider` in `lib/features/dashboard/presentation/providers/safe_to_spend_provider.dart`.
   - `reportsSummaryProvider` in `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`.
   - `SpendingVsBudgetCard` and `CategoryBudgetsView` UI: displaying the active billing cycle date range (`Chu kỳ: DD/MM – DD/MM`) with `FontFeature.tabularFigures()`.

Deliverable:
Write a comprehensive report to `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_3\handoff.md` detailing:
- Exact algorithm and test cases for `BillingCycleCalculator`.
- Step-by-step changes for each provider, service, and UI widget.
- Verification plan.
Send a message back to the orchestrator when finished.
