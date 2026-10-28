# HANDOFF REPORT: REQUIREMENT R1 CODEBASE SURVEY & ARCHITECTURE PLAN

**Agent**: `explorer_survey_1`  
**Recipient**: `orchestrator_2` / `worker_m1`  
**Date**: 2026-10-28T00:53:00Z  
**Target Requirement**: R1 (Single-Payment Bills & Planned Income + Anti-Double-Tap UX)  
**Detailed Report**: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_1\report.md`

---

## 1. Observation

1. **`_AddScheduledItemModal` in `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`**:
   - Line 252: `String _recurrence = 'MONTHLY';` defaults to monthly recurrence.
   - Lines 311–320: Wrap with ChoiceChips `['NONE', 'WEEKLY', 'MONTHLY', 'YEARLY']` allows selecting recurrence.
   - Line 254: `final DateTime _dueDate = DateTime.now().add(const Duration(days: 7));` is immutable with no date picker.
   - Lines 359, 367, 376–390: `_submit()` and button have NO `_isSubmitting` variable or guard.
2. **`ObligationsForecastView` in `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`**:
   - Lines 156, 167–228: Only renders `items.where((i) => i.status == 'PENDING')`. Any item with `status == 'PAID_OR_RECEIVED'` is completely hidden.
   - Lines 213–223: OutlinedButton directly calls `markScheduledItemPaid` with no confirmation dialog.
3. **`UpcomingObligationsCard` & `DashboardScreen` in `lib/features/dashboard/presentation/`**:
   - `upcoming_obligations_card.dart` line 99: OutlinedButton directly calls `onPayObligation(bill.id)`.
   - `dashboard_screen.dart` lines 115–119: Directly executes `markScheduledItemPaid` with no confirmation dialog.
   - `upcoming_obligations_card.dart` lines 47–71: `nextIncome` is rendered as static text with no action button.
4. **`PlansController.markScheduledItemPaid` & `createScheduledItem` in `lib/features/plans/presentation/providers/plans_providers.dart`**:
   - Lines 260–288: `createScheduledItem` allows passing `String recurrence = 'NONE'` and writes `recurrence: Value(recurrence)`.
   - Lines 351–359: `PostTransactionCommand.income` does NOT provide an `idempotencyKey`.
   - Lines 386–398: `dao.postTransaction` does NOT provide an `idempotencyKey`.
   - Lines 432–455: `if (item.recurrence != 'NONE')` automatically computes `nextDue` and inserts a new recurring row into `scheduledItems`.
5. **Modal Submission Guards (`_isSubmitting`)**:
   - `_SetBudgetModal` (`category_budgets_view.dart` lines 231–315): No `_isSubmitting` flag.
   - `AllocateModal` (`allocate_modal.dart` line 152): `_submit()` does not check `if (_isSubmitting) return;` or `if (isOver) return;`.
   - `EnvelopeFormModal` (`envelope_form_modal.dart` line 186): `_submit()` does not check `if (_isSubmitting) return;`.
   - `ReleaseModal` (`release_modal.dart` line 155): `_submit()` does not check `if (_isSubmitting) return;` or `if (isBlocked) return;`.
   - `TransferModal` (`transfer_modal.dart` line 176): `_submit()` does not check `if (_isSubmitting) return;` or `if (isBlocked) return;`.
   - `AddEditAccountModal` (`add_edit_account_modal.dart` line 207): `_submit()` does not check `if (_isSubmitting) return;`.
   - `CustomKeypad` (`custom_keypad.dart` lines 10–20, 66–84): Has no parameter or mechanism to disable Done button during async submission.
6. **Tool Commands and Results**:
   - `flutter test` ran 275 tests and passed 100% (exit code 0).
   - `flutter analyze` analyzed App with 0 issues found (exit code 0).

---

## 2. Logic Chain

1. From Observation 1, because `_recurrence` defaulted to `'MONTHLY'` with selector chips, bills and incomes were created as recurring items rather than one-off single-occurrence items. Removing the chips and forcing `recurrence = 'NONE'` prevents recurrence at the source.
2. From Observation 1, because `_dueDate` was hardcoded to `now + 7 days` without a date picker, users could not specify when their one-off bill or income is actually due. Adding a standard Material `showDatePicker` resolves this.
3. From Observation 2 & 3, financial transactions in DongTien are immutable ledger entries. Executing `markScheduledItemPaid` without confirmation causes accidental, irreversible writes on unintentional taps. Adding confirmation dialogs on both the Plans Obligations view and Dashboard Upcoming card ensures intentional actions.
4. From Observation 2, when an item is marked paid, its status becomes `'PAID_OR_RECEIVED'`. Because `ObligationsForecastView` only queried `status == 'PENDING'`, paid items vanished completely with no audit record for the user. Splitting the query into pending obligations and a "Lịch sử đã thanh toán / Đã nhận" section with a disabled "Đã hoàn tất" button (`onPressed: null`) provides clear completed history and prevents duplicate payment taps.
5. From Observation 4 and `app_database.dart` line 59, `journal_transactions.idempotency_key` is `UNIQUE`. Passing deterministic `idempotencyKey: 'scheduled_pay_${item.id}'` in `markScheduledItemPaid` guarantees that concurrent or repeated execution attempts will be rejected by SQLite and cannot create duplicate ledger transactions. Removing the recurring row insertion in lines 432–455 ensures items are settled strictly once.
6. From Observation 1, 5, and the keypad audit, because modal submit methods (`_submit()`) and the keypad Done button lacked in-flight submission checks, rapid taps triggered concurrent database writes and popped the screen multiple times (`Navigator.pop()` called on an already dismissed route). Adding `if (_isSubmitting) return;` across all modals and adding `isSubmitting`/`isDoneEnabled` to `CustomKeypad` completely eliminates this class of race conditions.

---

## 3. Caveats

- In `UpcomingObligationsCard` on the Dashboard, `nextIncome` is currently rendered as an informational box without an action button. In the implementation plan, adding an OutlinedButton "Đã nhận" (with matching confirmation dialog) provides feature symmetry with the "Đã trả" button on pending bills.
- `RecurrenceCalculator` and its associated unit tests (`test/unit/recurrence_test.dart`, `test/unit/m2_adversarial_stress_test.dart`) test anchor-day month-end recurrence arithmetic. These pure domain tests should remain untouched, as they verify core forecasting logic and Scenario 15 compliance.
- No other areas of the application are blocked.

---

## 4. Conclusion

Requirement R1 is completely scoped and ready for implementation. The changes are localized across 7 files:
1. `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`: Remove recurrence chips, add date picker, add confirmation dialog, render completed history section with disabled button, add `_isSubmitting` guard.
2. `lib/features/plans/presentation/providers/plans_providers.dart`: Lock `createScheduledItem` to `recurrence: const Value('NONE')`, pass `idempotencyKey: 'scheduled_pay_${item.id}'` in `markScheduledItemPaid`, and do not spawn recurring rows.
3. `lib/features/dashboard/presentation/dashboard_screen.dart` & `upcoming_obligations_card.dart`: Add confirmation dialog before executing payment, add "Đã nhận" action button for `nextIncome`.
4. `lib/features/plans/presentation/widgets/category_budgets_view.dart`: Add `_isSubmitting` guard to `_SetBudgetModal`.
5. `lib/features/envelopes/presentation/modals/` (`allocate_modal.dart`, `envelope_form_modal.dart`, `release_modal.dart`, `transfer_modal.dart`): Add entry guards `if (_isSubmitting) return;` to `_submit()`.
6. `lib/features/accounts/presentation/add_edit_account_modal.dart`: Add entry guard `if (_isSubmitting) return;` to `_submit()`.
7. `lib/core/widgets/custom_keypad.dart`: Add `isSubmitting` / `isDoneEnabled` properties to suppress Done actions during in-flight submissions.

---

## 5. Verification Method

To verify the implementation once applied:

1. **Static Analysis & Formatting**:
   ```powershell
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   ```
   Must exit with code 0 (zero issues).

2. **Automated Unit & Widget Tests**:
   ```powershell
   flutter test
   ```
   Must pass 100% of existing 275 tests and new scenario tests:
   - Creating a bill or income verifies `recurrence == 'NONE'`.
   - Date picker successfully updates due date.
   - Calling `markScheduledItemPaid` creates exactly one ledger transaction with `idempotency_key == 'scheduled_pay_<id>'` and sets status `'PAID_OR_RECEIVED'` without inserting a new scheduled item.
   - Calling `markScheduledItemPaid` a second time with the same ID returns existing transaction ID without duplicate write.
   - Tapping "Đã trả" or "Đã nhận" displays the confirmation dialog; dismissing does not post; confirming posts the transaction.
   - Obligations view displays completed items in "Lịch sử đã thanh toán / Đã nhận" with disabled button.
   - Rapid double-tapping on modal submit or keypad Done does not trigger duplicate writes or multiple pops.
