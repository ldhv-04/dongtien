# HANDOFF REPORT: REQUIREMENT R1 — SINGLE-PAYMENT OBLIGATIONS & ANTI-DOUBLE-TAP UX

**Agent**: `worker_m2`  
**Milestone**: M2 (Requirement R1)  
**Date**: 2026-10-28T02:39:00Z  
**Recipient**: `orchestrator_2` (`e84dfd06-a5ff-437b-948f-883d103ebdc9`)

---

## 1. Observation

1. **Recurrence Selector & Missing Date Picker in Add Modal**:
   - In `lib/features/plans/presentation/widgets/obligations_forecast_view.dart` (original lines 311–320): ChoiceChips rendered `['NONE', 'WEEKLY', 'MONTHLY', 'YEARLY']` defaulting to `'MONTHLY'`. Due date was hardcoded to `DateTime.now().add(const Duration(days: 7))` without any date picker.
2. **Unbounded Recurring Row Spawning & Lack of Idempotency Key**:
   - In `lib/features/plans/presentation/providers/plans_providers.dart`:
     - `createScheduledItem` (lines 260–288) accepted caller recurrence strings.
     - `markScheduledItemPaid` (lines 347–399) posted transactions without `idempotencyKey`, and lines 431–455 inserted a new recurring row whenever `item.recurrence != 'NONE'`.
3. **Missing Payment Confirmations & Next Income Action**:
   - In `ObligationsForecastView` (lines 213–223) and `DashboardScreen` (lines 115–119), tapping "Đã trả" immediately posted transactions without user confirmation.
   - In `UpcomingObligationsCard` (lines 47–72), `nextIncome` was rendered as read-only text without an action button.
4. **Omission of Completed Obligations History**:
   - In `ObligationsForecastView` (lines 154–166), items were filtered strictly with `items.where((i) => i.status == 'PENDING')`. Paid items (`status == 'PAID_OR_RECEIVED'`) were completely discarded.
5. **Missing In-Flight Tap Guards Across Modals**:
   - `_AddScheduledItemModal`, `_SetBudgetModal`, `AllocateModal`, `EnvelopeFormModal`, `ReleaseModal`, `TransferModal`, `AddEditAccountModal`, and `QuickAddModal` did not protect the keypad Done button and submission routines against rapid multi-taps.
6. **Toolchain & Quality Gates Execution**:
   - `dart format --output=none --set-exit-if-changed .` -> Code 0 (113 files, 0 changed).
   - `flutter analyze` -> Code 0 ("No issues found!").
   - `flutter test` -> Code 0 ("All 300 tests passed!").

---

## 2. Logic Chain

1. **Single-Payment Obligation Architecture**:
   - Per Requirement R1, every bill or planned income created by the user is a one-off obligation.
   - Removing the recurrence ChoiceChips in `_AddScheduledItemModal` and forcing `recurrence: const Value('NONE')` in `PlansController.createScheduledItem` guarantees that all newly created items have `recurrence == 'NONE'`.
   - Adding a `showDatePicker` allows users to select exact due dates with tabular date presentation (`dd/MM/yyyy`).
   - Removing recurring row insertion from `PlansController.markScheduledItemPaid` ensures that marking an item paid never spawns a subsequent occurrence.
2. **Double-Tap Protection & Idempotency**:
   - Providing `idempotencyKey: 'scheduled_pay_${item.id}'` in `markScheduledItemPaid` creates an unbreakable SQLite UNIQUE constraint guarantee at persistence time and ensures idempotent domain returns (`item.status != 'PENDING'` returns existing `paidTransactionId`).
   - Adding `_isSubmitting` guards across all modal submission routines (`if (_isSubmitting) return;`) and wiring `isSubmitting` / `isDoneEnabled` to `CustomKeypad` prevents concurrent database writes and premature navigation pops.
3. **Intentional Confirmation & History Transparency**:
   - Adding modal `AlertDialog` confirmation with tabular figures and clear prompts ("Bạn có chắc chắn muốn ghi nhận đã thanh toán hoá đơn / đã nhận khoản thu...?") prevents accidental financial ledger writes.
   - Partitioning obligations into pending and completed lists renders the lower "LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN" section with permanently disabled `OutlinedButton(onPressed: null, child: Text('Đã hoàn tất'))` and Semantics `btn_completed_obligation_${item.id}`.

---

## 3. Caveats

- **Existing Legacy Seed/Test Items**: Existing items previously created in SQLite databases with legacy recurrence strings (e.g. from earlier unit tests) are preserved in schema, but `markScheduledItemPaid` now suppresses recurring spawning for all items.
- **Horizon Cash Flow Forecast**: The cash flow forecaster continues to project future cash flows based on domain models without degradation.
- No other caveats.

---

## 4. Conclusion

Milestone M2 (Requirement R1) is completely and genuinely implemented:
- Single-payment conversion for bills and planned income is enforced at both UI and domain levels.
- Due date selection is provided via `showDatePicker`.
- Confirmation dialogs protect both Obligations view and Dashboard Upcoming Obligations card.
- Completed obligations appear in "LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN" with a permanently disabled "Đã hoàn tất" button.
- Deterministic idempotency key (`scheduled_pay_<id>`) guarantees payment idempotency.
- In-flight tap guards (`_isSubmitting`) are enforced across all modals and `CustomKeypad`.
- 10 new tests added; all 300 tests pass; static analysis has 0 issues; formatting is 100% clean.

---

## 5. Verification Method

To independently verify this implementation:

1. **Set Environment & Verify Formatting**:
   ```powershell
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
   dart format --output=none --set-exit-if-changed .
   ```
   *Expected*: Code 0, 0 changed.

2. **Run Static Analysis**:
   ```powershell
   flutter analyze
   ```
   *Expected*: Code 0, "No issues found!".

3. **Run M2 Specific Tests**:
   ```powershell
   flutter test test/unit/m2_r1_single_payment_plans_test.dart test/widget/m2_r1_obligations_ux_test.dart
   ```
   *Expected*: Code 0, 10 passed.

4. **Run Full Test Suite**:
   ```powershell
   flutter test
   ```
   *Expected*: Code 0, 300 passed.

5. **Inspect Modified Files**:
   - `lib/core/widgets/custom_keypad.dart`
   - `lib/features/plans/presentation/providers/plans_providers.dart`
   - `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`
   - `lib/features/plans/presentation/widgets/category_budgets_view.dart`
   - `lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart`
   - `lib/features/dashboard/presentation/dashboard_screen.dart`
   - `lib/features/envelopes/presentation/modals/allocate_modal.dart`
   - `lib/features/envelopes/presentation/modals/envelope_form_modal.dart`
   - `lib/features/envelopes/presentation/modals/release_modal.dart`
   - `lib/features/envelopes/presentation/modals/transfer_modal.dart`
   - `lib/features/accounts/presentation/add_edit_account_modal.dart`
   - `lib/features/transactions/presentation/quick_add_modal.dart`
