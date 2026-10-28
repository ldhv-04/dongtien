# Dispatch to worker_m2

## 2026-10-28T02:19:35Z

## Identity & Scope
- **Agent Name**: `worker_m2`
- **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m2\`
- **Milestone**: M2 (Single-Payment Obligations & Anti-Double-Tap UX — Requirement R1)

## Target Files
1. `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`
2. `lib/features/plans/presentation/widgets/category_budgets_view.dart`
3. `lib/features/plans/presentation/providers/plans_providers.dart`
4. `lib/features/dashboard/presentation/dashboard_screen.dart`
5. `lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart`
6. `lib/core/widgets/custom_keypad.dart`
7. `lib/features/transactions/presentation/quick_add_modal.dart`
8. `lib/features/envelopes/presentation/modals/allocate_modal.dart`
9. `lib/features/envelopes/presentation/modals/envelope_form_modal.dart`
10. `lib/features/envelopes/presentation/modals/release_modal.dart`
11. `lib/features/envelopes/presentation/modals/transfer_modal.dart`
12. `lib/features/accounts/presentation/add_edit_account_modal.dart`
13. `test/` (any updated or new unit/widget tests for R1)

## Inputs & Blueprints
Read the authoritative blueprints and exact code diff proposals in:
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_1\report.md` (§ 3 & § 4)
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_1\handoff.md`
- `c:\Users\coihu12\Documents\App\PROJECT.md`
- `c:\Users\coihu12\Documents\App\AGENTS.md`
- `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (## 2026-10-28T00:39:16Z § R1)

## Mandatory Tasks
1. **Single-Payment Transition**:
   - In `_AddScheduledItemModal` (`obligations_forecast_view.dart`): remove recurrence choice chips, default and lock recurrence to `'NONE'`. Add `showDatePicker` UI for due date. Add `_isSubmitting` guard.
   - In `plans_providers.dart`: in `createScheduledItem`, force `recurrence: const Value('NONE')`. In `markScheduledItemPaid`, remove/suppress recurring row insertion so marking paid never spawns a recurring item.
2. **Confirmation Dialogs**:
   - In `ObligationsForecastView`: show confirmation dialog before calling `markScheduledItemPaid`.
   - In `DashboardScreen` / `UpcomingObligationsCard`: show confirmation dialog on "Đã trả" / "Đã nhận". Add "Đã nhận" action button for `nextIncome` with matching confirmation dialog.
3. **Completed History Section**:
   - In `ObligationsForecastView`: partition items into `pending` (`status == 'PENDING'`) and `completed` (`status == 'PAID_OR_RECEIVED'`). Render lower section "LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN" with permanently disabled button (`onPressed: null`, label "Đã hoàn tất", Semantics `btn_completed_obligation_${item.id}`).
4. **Deterministic Idempotency Key**:
   - In `markScheduledItemPaid`: pass `idempotencyKey: 'scheduled_pay_${item.id}'` when posting transactions (income & expense).
5. **In-Flight Tap Guards (_isSubmitting)**:
   - Audit and harden `_SetBudgetModal`, `QuickAddModal`, `AllocateModal`, `EnvelopeFormModal`, `ReleaseModal`, `TransferModal`, `AddEditAccountModal` with `if (_isSubmitting) return;`.
   - Update `CustomKeypad` to support `isSubmitting` and `isDoneEnabled`.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Toolchain Environment
```powershell
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
```

## Quality Gates
Run:
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
Document exact results in your `handoff.md` and message orchestrator_2.
