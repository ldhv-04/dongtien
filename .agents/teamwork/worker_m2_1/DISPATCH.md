## 2026-10-28T18:49:23Z
You are the Lead Implementation Worker on Project Đồng Tiền.
Your working directory is: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m2_1`.
All your intermediate logs and handoff report must be written inside your working directory (`progress.md`, `handoff.md`).

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY READING:
1. `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (Specifically section `## 2026-10-28T18:36:33Z` and Requirements R1, R2, R3, R4).
2. `c:\Users\coihu12\Documents\App\AGENTS.md` (All architectural invariants, tabular figures, integer VND 64-bit, double-entry ledger invariants).
3. `c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_3\SCOPE.md`
4. The 3 authoritative Explorer handoff reports:
   - `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_1\handoff.md` (R1 blueprints, controller changes, test code)
   - `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_2\handoff.md` (R2 blueprints, atomic ledger reversals, UI buttons & dialogs, test code)
   - `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_3\handoff.md` (R3 BillingCycleCalculator, provider sync, UI cycle labels, test code)

ENVIRONMENT & POWERSHELL EXECUTION:
When running any Dart, Flutter, Gradle, or ADB commands in powershell, always execute:
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path

IMPLEMENTATION TASKS:
1. Implement `lib/domain/budgeting/billing_cycle_calculator.dart` (pure Dart, zero Flutter/Drift imports) and extend `MonthlyBudgetSummary` with `cycleLabel` in `lib/domain/budgeting/category_budget_progress.dart`.
2. Update `lib/features/plans/presentation/providers/plans_providers.dart`:
   - R1: Eliminate `cats.first.id` fallback in `markScheduledItemPaid`. Strictly resolve explicit `item.categoryId`, or fallback to `Hoá đơn & Tiện ích` (never `Ăn uống`), ensuring paying a bill only affects its assigned category budget and envelope.
   - R2: Implement `deleteCategoryBudget(int categoryId, {int? yearMonth})`, `deleteSavingsGoal(int envelopeId)` (with `release` on positive reserve), `deleteScheduledItem(int scheduledItemId)` (with atomic `ledgerDao.voidTransaction` for `PAID_OR_RECEIVED` items), and `updateScheduledItem(...)` (with atomic void of old tx + re-post of new tx + row update).
   - R3: Use `BillingCycleCalculator` for default `yearMonth` in `upsertCategoryBudget` and `deleteCategoryBudget`.
3. Update `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`:
   - R1: Add Category selector to `_AddScheduledItemModal`, defaulted by kind. Display category name on scheduled cards.
   - R2: Add Edit & Delete buttons on pending and completed cards with confirmation dialogs and Semantics identifiers (`btn_edit_obligation_<id>`, `btn_delete_obligation_<id>`). Refactor `_AddScheduledItemModal` to accept optional `existingItem` for edit support.
4. Update `lib/features/plans/presentation/widgets/category_budgets_view.dart`:
   - R2: Add Edit (`btn_edit_budget_<categoryId>`) and Delete (`btn_delete_budget_<categoryId>`) actions on `card_budget_<categoryId>` and `_SetBudgetModal` with confirmation dialogs.
   - R3: Display `Chu kỳ: ${summary.cycleLabel}` with `FontFeature.tabularFigures()`.
5. Update `lib/features/plans/presentation/widgets/savings_goals_view.dart`:
   - R2: Add Edit (`btn_edit_goal_<id>`) opening `EnvelopeFormModal` pre-populated, and Delete (`btn_delete_goal_<id>`) with confirmation dialog.
6. Update `lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart`:
   - R1: Render category name on bill rows.
   - R2: Add Edit & Delete callbacks/buttons (`btn_edit_obligation_<id>`, `btn_delete_obligation_<id>`).
7. Update `lib/features/dashboard/presentation/widgets/spending_vs_budget_card.dart`:
   - R3: Display `Chu kỳ: ${summary.cycleLabel}` with `FontFeature.tabularFigures()`.
8. Update `lib/features/dashboard/presentation/providers/dashboard_providers.dart` & `safe_to_spend_provider.dart`:
   - R3: `currentMonthlyBudgetSummaryProvider` watches `settingsStreamProvider`, derives cycle, queries `WHERE b.year_month IN (activeCycleYearMonth, calendarYearMonth)`, adds `db.settings` to `readsFrom`, deduplicates in Dart.
   - R3: `safeToSpendProvider` uses `cycle.cycleEndInclusive` when `nextIncome == null`.
9. Update `lib/core/notifications/notification_scheduler.dart` & `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`:
   - R3: In `checkCategoryBudgetAlert` and `reportsSummaryProvider`, use `BillingCycleCalculator` and bound queries by `[cycleStartMs, cycleEndMs]`. In `updatePeriodStartDay`, invalidate `currentMonthlyBudgetSummaryProvider`.
10. Add automated tests covering:
    - R1 isolation: `test/unit/m3_r1_scheduled_obligations_isolation_test.dart`
    - R2 CRUD & Reversals: `test/unit/m2_r2_plans_crud_reversal_test.dart`
    - R3 Billing Cycle: `test/unit/billing_cycle_calculator_test.dart` and `test/unit/billing_cycle_providers_test.dart`
    - Widget tests: `test/widget/m2_r2_plans_crud_widget_test.dart` and `test/widget/billing_cycle_ui_test.dart`
11. Verification & Build:
    - Run `dart format --output=none --set-exit-if-changed .`
    - Run `flutter analyze` (must exit 0)
    - Run `flutter test` (all tests must pass 100%)
    - Run `flutter build apk --release --split-per-abi --tree-shake-icons` (verify `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` and `build/app/outputs/flutter-apk/app-x86_64-release.apk` are generated).

Deliverable:
Write a comprehensive handoff report to `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m2_1\handoff.md` with full verification details, test logs, and APK file sizes. Send a message to the orchestrator when complete.
