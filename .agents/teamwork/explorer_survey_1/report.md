# SURVEY REPORT: REQUIREMENT R1 — SINGLE-PAYMENT BILLS & PLANNED INCOME + ANTI-DOUBLE-TAP UX

**Author**: `explorer_survey_1`  
**Date**: 2026-10-28T00:52:00Z  
**Target Requirement**: ## 2026-10-28T00:39:16Z § R1 (`ORIGINAL_REQUEST.md`)  
**Project Invariants Reference**: `AGENTS.md`  

---

## 1. Executive Summary

Requirement R1 addresses critical usability and data-integrity behaviors surrounding scheduled financial obligations (bills and planned income) and multi-tap race conditions in modal sheets:
1. **Single-Payment Transition**: Converting bills (`BILL`) and planned income (`PLANNED_INCOME`) from recurring items to strictly single-occurrence items (`recurrence = 'NONE'`) that can be paid or received at most once. Removing recurrence selector chips from the creation modal, adding a date picker for due date selection, and preventing `markScheduledItemPaid` from spawning any recurring next-occurrence row.
2. **Confirmation Dialogs**: Requiring explicit user confirmation before executing "Đã trả" (bill) or "Đã nhận" (income) both in the Plans Obligations tab and on the Dashboard Upcoming Obligations card.
3. **Completed History Section**: Rendering a dedicated "Lịch sử đã thanh toán / Đã nhận" section on the Obligations view with a permanently disabled "Đã hoàn tất" button (`onPressed: null`) so completed items can never be re-triggered.
4. **Deterministic Idempotency Key**: Enforcing `idempotencyKey = 'scheduled_pay_<id>'` when posting real ledger transactions via `markScheduledItemPaid`, leveraging SQLite's UNIQUE constraint on `journal_transactions.idempotency_key` to make duplicate ledger entries impossible.
5. **In-Flight Tap Guards (`_isSubmitting`)**: Auditing and hardening all modal sheets (`_AddScheduledItemModal`, `_SetBudgetModal`, `QuickAddModal`, `AllocateModal`, `EnvelopeFormModal`, `ReleaseModal`, `TransferModal`, `AddEditAccountModal`) and `CustomKeypad` Done actions against rapid double taps.

The entire existing test suite (275 tests) and static analysis currently pass with zero issues. This report specifies the exact locations, root causes, and verbatim code proposals for seamless implementation.

---

## 2. File & Component Survey Matrix

| Target Component | File Path | Current Status | Required Change |
|---|---|---|---|
| **Add Scheduled Item Modal** | `lib/features/plans/presentation/widgets/obligations_forecast_view.dart` (lines 248–391) | Has recurrence chips (`['NONE', 'WEEKLY', 'MONTHLY', 'YEARLY']`), defaults to `'MONTHLY'`. Due date is fixed at `now + 7 days` with no date picker. No `_isSubmitting` guard. | Remove recurrence chips, lock recurrence to `'NONE'`. Add `showDatePicker` UI for due date. Add `_isSubmitting` guard to prevent double-tap writes. |
| **Obligations Active & History Lists** | `lib/features/plans/presentation/widgets/obligations_forecast_view.dart` (lines 154–233) | Only filters `status == 'PENDING'`. Completed items (`PAID_OR_RECEIVED`) are completely omitted. Tapping "Đã trả"/"Đã nhận" executes immediately without confirmation. | Add confirmation dialog before payment. Add second section "LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN" for `status == 'PAID_OR_RECEIVED'` with permanently disabled "Đã hoàn tất" button (`onPressed: null`). |
| **Dashboard Upcoming Card** | `lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart` & `dashboard_screen.dart` (lines 112–120) | Tapping "Đã trả" immediately executes payment without confirmation. `nextIncome` is text-only without action button. | Show confirmation dialog before executing payment. Add "Đã nhận" button for `nextIncome` with matching confirmation dialog. |
| **Scheduled Item Creation & Payment Engine** | `lib/features/plans/presentation/providers/plans_providers.dart` (lines 260–458) | `createScheduledItem` allows custom recurrence. `markScheduledItemPaid` does NOT pass `idempotencyKey`. It spawns a new row if `recurrence != 'NONE'`. | Lock `createScheduledItem` to `recurrence: const Value('NONE')`. Pass deterministic `idempotencyKey: 'scheduled_pay_${item.id}'` to `dao.postTransactionCommand` and `dao.postTransaction`. Prevent spawning new recurring rows. |
| **Set Monthly Budget Modal** | `lib/features/plans/presentation/widgets/category_budgets_view.dart` (lines 216–315) | Has NO `_isSubmitting` guard. Rapid double tap triggers concurrent `upsertCategoryBudget` and multiple `Navigator.pop()`. | Add `bool _isSubmitting = false;`, guard `_submit()`, disable button and keypad Done while submitting. |
| **Quick Add Transaction Modal** | `lib/features/transactions/presentation/quick_add_modal.dart` (lines 434–464, 541–653) | Has `_isSubmitting` on button, but keypad Done does not check deficit block. | Ensure `_handleSubmit` validates deficit guard and blocks keypad Done when `_isSubmitting`. |
| **Envelope Allocation Modal** | `lib/features/envelopes/presentation/modals/allocate_modal.dart` (lines 125, 136, 152–163) | Has `_isSubmitting`, but `_submit()` does not check `if (_isSubmitting) return;` at entry. Keypad Done bypasses guard. | Add `if (_isSubmitting || isOver || _selectedEnvelopeId == null || _amountVnd <= 0) return;` at top of `_submit()`. |
| **Envelope Form Modal** | `lib/features/envelopes/presentation/modals/envelope_form_modal.dart` (lines 168, 176, 186–220) | Has `_isSubmitting`, but `_submit()` does not check `if (_isSubmitting) return;` at entry. Keypad Done bypasses guard. | Add `if (_isSubmitting || name.isEmpty) return;` at top of `_submit()`. |
| **Envelope Release Modal** | `lib/features/envelopes/presentation/modals/release_modal.dart` (lines 128, 139, 155–166) | Has `_isSubmitting`, but `_submit()` does not check `if (_isSubmitting) return;` at entry. Keypad Done bypasses guard. | Add `if (_isSubmitting || isBlocked || _selectedEnvelopeId == null || _amountVnd <= 0) return;` at top of `_submit()`. |
| **Envelope Transfer Modal** | `lib/features/envelopes/presentation/modals/transfer_modal.dart` (lines 147, 158, 176–188) | Has `_isSubmitting`, but `_submit()` does not check `if (_isSubmitting) return;` at entry. Keypad Done bypasses guard. | Add `if (_isSubmitting || isBlocked || _sourceId == null || _destId == null || _sourceId == _destId || _amountVnd <= 0) return;` at top of `_submit()`. |
| **Account Form Modal** | `lib/features/accounts/presentation/add_edit_account_modal.dart` (lines 184, 196, 207–232) | Has `_isSubmitting`, but `_submit()` does not check `if (_isSubmitting) return;` at entry. Keypad Done bypasses guard. | Add `if (_isSubmitting || name.isEmpty) return;` at top of `_submit()`. |
| **Custom Keypad Widget** | `lib/core/widgets/custom_keypad.dart` (lines 10–20, 66–84) | `CustomKeypad` does not accept `isSubmitting` or `isDoneEnabled`. Done button triggers `onDonePressed()` unconditionally. | Add optional `bool isSubmitting = false;` and `bool? isDoneEnabled;` to `CustomKeypad` and suppress Done callback when disabled/submitting. |

---

## 3. Detailed Investigation Findings by Sub-Topic

### 3.1 Sub-Topic 1: Single-Payment One-Off Items (`recurrence = 'NONE'`)

#### Direct Observations
- **Database Schema**:
  In `lib/core/database/app_database.dart` (lines 190–220):
  ```dart
  class ScheduledItems extends Table {
    IntColumn get id => integer().autoIncrement()();
    TextColumn get kind => text()(); // 'BILL' or 'PLANNED_INCOME'
    TextColumn get title => text()();
    IntColumn get amountVnd => integer()();
    IntColumn get dueDateMs => integer()();
    TextColumn get recurrence => text().withDefault(const Constant('NONE'))();
    IntColumn get anchorDayOfMonth => integer().nullable()();
    ...
    TextColumn get status => text().withDefault(const Constant('PENDING'))();
    IntColumn get paidTransactionId => integer().nullable().references(JournalTransactions, #id, ...);
  }
  ```
  The table column defaults to `'NONE'`, but allows `'NONE', 'WEEKLY', 'MONTHLY', 'YEARLY'`.
- **Add Modal**:
  In `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`:
  - Line 252: `String _recurrence = 'MONTHLY';`
  - Lines 311–320:
    ```dart
    Wrap(
      spacing: AppSpacing.sp4,
      children: ['NONE', 'WEEKLY', 'MONTHLY', 'YEARLY'].map((rec) {
        return ChoiceChip(
          label: Text(rec),
          selected: _recurrence == rec,
          onSelected: (_) => setState(() => _recurrence = rec),
        );
      }).toList(),
    )
    ```
  - Line 254: `final DateTime _dueDate = DateTime.now().add(const Duration(days: 7));`
    Due date is not editable via any picker; it is always fixed to `now + 7 days`.
- **Controller & Recurring Spawning**:
  In `lib/features/plans/presentation/providers/plans_providers.dart`:
  - Lines 260–295: `createScheduledItem` takes `String recurrence = 'NONE'` and writes `recurrence: Value(recurrence)`.
  - Lines 432–455: In `markScheduledItemPaid`:
    ```dart
    if (item.recurrence != 'NONE') {
      final currentDue = DateTime.fromMillisecondsSinceEpoch(item.dueDateMs);
      final nextDue = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: currentDue,
        recurrence: item.recurrence,
        anchorDayOfMonth: item.anchorDayOfMonth,
      );
      await db.into(db.scheduledItems).insert(...);
    }
    ```
    If `item.recurrence != 'NONE'`, it spawns a new scheduled item row.

#### Logic Chain
1. User creates a bill or planned income intending to track a specific due date.
2. Because `_recurrence` defaulted to `'MONTHLY'` with selector chips, recurring items were created and then spawned new records indefinitely upon being marked paid.
3. Furthermore, users could not choose the actual due date of the bill/income because there was no date picker.
4. Setting `recurrence = 'NONE'` unconditionally on all newly created items, removing the recurrence choice chips, adding a date picker, and eliminating/preventing recurring row spawning in `markScheduledItemPaid` satisfies the exact user requirement:
   > "Every bill (`BILL`) or planned income (`PLANNED_INCOME`) added by the user must be a single-occurrence item (`recurrence = 'NONE'`) that can be paid or received at most once."

---

### 3.2 Sub-Topic 2: Confirmation Dialogs on "Đã trả" / "Đã nhận"

#### Direct Observations
- **Plans Tab (Obligations)**:
  In `lib/features/plans/presentation/widgets/obligations_forecast_view.dart` (lines 213–223):
  ```dart
  Semantics(
    identifier: 'btn_pay_obligation_${item.id}',
    button: true,
    child: OutlinedButton(
      onPressed: () {
        ref.read(plansControllerProvider.notifier).markScheduledItemPaid(
              scheduledItemId: item.id,
            );
      },
      child: Text(isBill ? 'Đã trả' : 'Đã nhận'),
    ),
  )
  ```
  Tapping the button immediately executes `markScheduledItemPaid` with zero user confirmation.
- **Dashboard Tab (Upcoming Obligations)**:
  In `lib/features/dashboard/presentation/dashboard_screen.dart` (lines 115–119):
  ```dart
  onPayObligation: (billId) {
    ref.read(plansControllerProvider.notifier).markScheduledItemPaid(scheduledItemId: billId);
  }
  ```
  And in `lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart` (lines 98–105):
  ```dart
  OutlinedButton(
    onPressed: () => onPayObligation(bill.id),
    ...
    child: const Text('Đã trả'),
  )
  ```
  Neither location prompts the user for confirmation. An accidental finger tap immediately posts a permanent general ledger transaction and moves money.

#### Logic Chain
1. Financial transactions in DongTien are immutable double-entry records (`status = 'POSTED'`). Accidental clicks create unwanted real ledger expense/income transactions.
2. A confirmation dialog asking "Bạn có chắc chắn muốn ghi nhận đã trả/đã nhận [tên] với số tiền [số tiền]?" ensures deliberate user intent.
3. The confirmation dialog must be present in both access points: Plans -> Obligations tab and Dashboard -> Upcoming card.

---

### 3.3 Sub-Topic 3: "Lịch sử đã thanh toán / Đã nhận" Section with Disabled Button

#### Direct Observations
- In `lib/features/plans/presentation/widgets/obligations_forecast_view.dart` (lines 154–166):
  ```dart
  itemsAsync.when(
    data: (items) {
      final pending = items.where((i) => i.status == 'PENDING').toList();
      if (pending.isEmpty) {
        return const Text('Chưa có hoá đơn hoặc thu nhập dự kiến nào.');
      }
      return Column(children: pending.map((item) { ... }).toList());
    }
  )
  ```
- Any item with `status == 'PAID_OR_RECEIVED'` is discarded and completely invisible to the user.
- Users have no visibility into what bills have been settled or when they were settled.

#### Logic Chain
1. When an item is paid, its status is updated in SQLite: `status = 'PAID_OR_RECEIVED'`.
2. Dividing `items` into `pending` (`status == 'PENDING'`) and `completed` (`status == 'PAID_OR_RECEIVED'`) allows rendering:
   - Upper Section: Active/Pending obligations with "Đã trả" / "Đã nhận" action buttons.
   - Lower Section: "LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN" with completed obligations.
3. In the history section, each item displays a permanently disabled button (`onPressed: null`) with label `"Đã hoàn tất"` and semantics identifier `btn_completed_obligation_${item.id}`. This guarantees that paid items can never be tapped again.

---

### 3.4 Sub-Topic 4: Deterministic Idempotency Key (`scheduled_pay_<id>`)

#### Direct Observations
- **Database Schema**:
  In `lib/core/database/app_database.dart` (line 59):
  ```dart
  TextColumn get idempotencyKey => text().nullable().unique()();
  ```
  The `journal_transactions` table has a `UNIQUE` constraint on `idempotency_key`. Attempting to insert a duplicate key throws a `SqliteException` and rolls back the SQLite transaction.
- **Current `markScheduledItemPaid`**:
  In `lib/features/plans/presentation/providers/plans_providers.dart`:
  - Line 351: For `PLANNED_INCOME`:
    ```dart
    createdTxId = await dao.postTransactionCommand(
      PostTransactionCommand.income(
        receivingAssetAccountId: targetAccountId,
        categoryId: targetCategoryId,
        amountVnd: item.amountVnd,
        occurredAt: nowMs,
        description: item.title,
      ),
    );
    ```
    No `idempotencyKey` is provided.
  - Line 386: For `BILL`:
    ```dart
    createdTxId = await dao.postTransaction(
      txType: 'EXPENSE',
      description: item.title,
      occurredAt: nowMs,
      postings: PostingMatrix.buildExpense(...),
      linkedEnvelopeId: envelopeToLink,
      envelopeMovementType: envelopeToLink != null ? 'SPEND' : null,
    );
    ```
    No `idempotencyKey` is provided.

#### Logic Chain
1. If two execution requests hit `markScheduledItemPaid` concurrently for the same `scheduledItemId` before the first transaction commits `status = 'PAID_OR_RECEIVED'`, two distinct expense/income transactions with different IDs would be posted.
2. Supplying `idempotencyKey: 'scheduled_pay_${item.id}'` ensures:
   - At the domain/controller level, `item.status != 'PENDING'` returns the existing `paidTransactionId`.
   - At the SQLite persistence level, even under concurrent thread execution, the second write will violate the `UNIQUE` constraint on `journal_transactions.idempotency_key`. Duplicate transactions are mathematically and structurally impossible.

---

### 3.5 Sub-Topic 5: In-Flight Tap Guards Across All Modals & `CustomKeypad`

#### Direct Observations
- **Audit of All Submission Modals**:
  1. `_AddScheduledItemModal` (`obligations_forecast_view.dart`): **NO** `_isSubmitting` variable. Rapid multiple taps on button or keypad Done execute multiple inserts.
  2. `_SetBudgetModal` (`category_budgets_view.dart`): **NO** `_isSubmitting` variable. Rapid multiple taps execute concurrent `upsertCategoryBudget` and multiple `Navigator.pop()`.
  3. `QuickAddModal` (`quick_add_modal.dart`): Has `_isSubmitting = false`, but keypad Done does not check deficit blocking.
  4. `AllocateModal` (`allocate_modal.dart`): Has `_isSubmitting`, but `_submit()` on line 152 does NOT check `if (_isSubmitting) return;` at entry. Pressing Done on `CustomKeypad` bypasses the button's `_isSubmitting` disabled state.
  5. `EnvelopeFormModal` (`envelope_form_modal.dart`): Has `_isSubmitting`, but `_submit()` on line 186 does NOT check `if (_isSubmitting) return;` at entry. Keypad Done bypasses the guard.
  6. `ReleaseModal` (`release_modal.dart`): Has `_isSubmitting`, but `_submit()` on line 155 does NOT check `if (_isSubmitting) return;` at entry. Keypad Done bypasses the guard.
  7. `TransferModal` (`transfer_modal.dart`): Has `_isSubmitting`, but `_submit()` on line 176 does NOT check `if (_isSubmitting) return;` at entry. Keypad Done bypasses the guard.
  8. `AddEditAccountModal` (`add_edit_account_modal.dart`): Has `_isSubmitting`, but `_submit()` on line 207 does NOT check `if (_isSubmitting) return;` at entry. Keypad Done bypasses the guard.
  9. `CustomKeypad` (`custom_keypad.dart`): Done button (`keypad_btn_done`) calls `onDonePressed()` directly on every tap with no parameter to disable or indicate submission.

#### Logic Chain
1. When an async DB write is in progress, the UI remains responsive for several milliseconds. If the user double-taps the submit button or Done button on the numeric keypad:
   - Two write commands are fired.
   - When the first completes, `Navigator.pop()` pops the modal.
   - When the second completes, `Navigator.pop()` pops the underlying screen (e.g. closing the Plans or Transactions tab)!
2. Every modal must guard its submission logic by checking `if (_isSubmitting) return;` immediately at the top of `_submit()`, setting `_isSubmitting = true`, and resetting it in `finally`.
3. `CustomKeypad` should support an optional `isSubmitting` / `isDoneEnabled` flag so the Done button is visually and functionally disabled while submitting.

---

## 4. Concrete Implementation Proposals (Diff Blueprints)

### 4.1 `PlansController.createScheduledItem` & `markScheduledItemPaid`
**File**: `lib/features/plans/presentation/providers/plans_providers.dart`

```dart
<<<< CURRENT: lines 260-288
  Future<int> createScheduledItem({
    required String kind, // 'BILL' or 'PLANNED_INCOME'
    required String title,
    required int amountVnd,
    required DateTime dueDate,
    String recurrence = 'NONE',
    int? anchorDayOfMonth,
    int? categoryId,
    int? linkedEnvelopeId,
    int reminderDaysBefore = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final id = await db.into(db.scheduledItems).insert(
            ScheduledItemsCompanion.insert(
              kind: kind,
              title: title,
              amountVnd: amountVnd,
              dueDateMs: dueDate.millisecondsSinceEpoch,
              recurrence: Value(recurrence),
              anchorDayOfMonth: Value(anchorDayOfMonth ?? dueDate.day),
==== PROPOSED: Force recurrence = 'NONE'
  Future<int> createScheduledItem({
    required String kind, // 'BILL' or 'PLANNED_INCOME'
    required String title,
    required int amountVnd,
    required DateTime dueDate,
    String recurrence = 'NONE',
    int? anchorDayOfMonth,
    int? categoryId,
    int? linkedEnvelopeId,
    int reminderDaysBefore = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final id = await db.into(db.scheduledItems).insert(
            ScheduledItemsCompanion.insert(
              kind: kind,
              title: title,
              amountVnd: amountVnd,
              dueDateMs: dueDate.millisecondsSinceEpoch,
              recurrence: const Value('NONE'), // Strictly single-payment
              anchorDayOfMonth: Value(anchorDayOfMonth ?? dueDate.day),
>>>>
```

```dart
<<<< CURRENT: lines 347-399
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        int createdTxId;

        if (item.kind == 'PLANNED_INCOME') {
          createdTxId = await dao.postTransactionCommand(
            PostTransactionCommand.income(
              receivingAssetAccountId: targetAccountId,
              categoryId: targetCategoryId,
              amountVnd: item.amountVnd,
              occurredAt: nowMs,
              description: item.title,
            ),
          );
        } else {
          // BILL payment
          ...
          createdTxId = await dao.postTransaction(
            txType: 'EXPENSE',
            description: item.title,
            occurredAt: nowMs,
            postings: PostingMatrix.buildExpense(...),
            linkedEnvelopeId: envelopeToLink,
            envelopeMovementType: envelopeToLink != null ? 'SPEND' : null,
          );
==== PROPOSED: Add deterministic payKey = 'scheduled_pay_${item.id}'
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final payKey = 'scheduled_pay_${item.id}';
        int createdTxId;

        if (item.kind == 'PLANNED_INCOME') {
          createdTxId = await dao.postTransactionCommand(
            PostTransactionCommand.income(
              receivingAssetAccountId: targetAccountId,
              categoryId: targetCategoryId,
              amountVnd: item.amountVnd,
              occurredAt: nowMs,
              description: item.title,
              idempotencyKey: payKey,
            ),
          );
        } else {
          // BILL payment
          ...
          createdTxId = await dao.postTransaction(
            txType: 'EXPENSE',
            description: item.title,
            occurredAt: nowMs,
            postings: PostingMatrix.buildExpense(...),
            idempotencyKey: payKey,
            linkedEnvelopeId: envelopeToLink,
            envelopeMovementType: envelopeToLink != null ? 'SPEND' : null,
          );
>>>>
```

And in lines 431–455 of `plans_providers.dart`: Remove or guard recurring insertion so marking paid never spawns a new row.

---

### 4.2 `_AddScheduledItemModal` & `ObligationsForecastView`
**File**: `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`

1. In `_AddScheduledItemModalState`:
   - Replace `final DateTime _dueDate` with mutable `DateTime _dueDate = DateTime.now().add(const Duration(days: 7));`.
   - Remove `String _recurrence = 'MONTHLY';`.
   - Remove recurrence `Wrap` chips (lines 311–320).
   - Insert Due Date picker row:
     ```dart
     Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(
           'Hạn: ${_dueDate.day.toString().padLeft(2, '0')}/${_dueDate.month.toString().padLeft(2, '0')}/${_dueDate.year}',
           style: VndFormatter.withTabularFigures(AppTypography.bodyMedium),
         ),
         TextButton.icon(
           onPressed: _isSubmitting
               ? null
               : () async {
                   final now = DateTime.now();
                   final picked = await showDatePicker(
                     context: context,
                     initialDate: _dueDate,
                     firstDate: now.subtract(const Duration(days: 365)),
                     lastDate: now.add(const Duration(days: 365 * 5)),
                   );
                   if (picked != null) {
                     setState(() => _dueDate = picked);
                   }
                 },
           icon: const Icon(Icons.calendar_today, size: 16),
           label: const Text('Chọn ngày'),
         ),
       ],
     ),
     ```
   - Add `bool _isSubmitting = false;`.
   - In `_submit()`:
     ```dart
     Future<void> _submit() async {
       if (_isSubmitting) return;
       final title = _titleController.text.trim();
       if (title.isEmpty || _amountVnd <= 0) return;

       setState(() => _isSubmitting = true);
       try {
         await ref.read(plansControllerProvider.notifier).createScheduledItem(
               kind: _kind,
               title: title,
               amountVnd: _amountVnd,
               dueDate: _dueDate,
               recurrence: 'NONE',
               anchorDayOfMonth: _dueDate.day,
               linkedEnvelopeId: _linkedEnvelopeId,
             );
         if (mounted) Navigator.of(context).pop();
       } finally {
         if (mounted) setState(() => _isSubmitting = false);
       }
     }
     ```
   - On `ElevatedButton`: `onPressed: (_amountVnd <= 0 || _isSubmitting) ? null : _submit`.
   - On `CustomKeypad`: `onDonePressed: _isSubmitting ? () {} : _submit` (or pass `isSubmitting: _isSubmitting`).

2. In `ObligationsForecastView`:
   - Add helper method for confirmation:
     ```dart
     Future<void> _confirmAndPay(
       BuildContext context,
       WidgetRef ref,
       ScheduledItem item,
     ) async {
       final isBill = item.kind == 'BILL';
       final confirmed = await showDialog<bool>(
         context: context,
         builder: (ctx) => AlertDialog(
           title: Text(isBill ? 'Xác nhận thanh toán' : 'Xác nhận đã nhận'),
           content: Text(
             'Bạn có chắc chắn muốn ghi nhận ${isBill ? 'đã thanh toán hoá đơn' : 'đã nhận khoản thu'} '
             '"${item.title}" với số tiền ${VndFormatter.format(item.amountVnd)}?',
             style: VndFormatter.withTabularFigures(AppTypography.bodyMedium),
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(ctx).pop(false),
               child: const Text('Hủy'),
             ),
             ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: isBill
                     ? AppColors.fillAccentRubyPrimary
                     : AppColors.fillAccentVerdantPrimary,
                 foregroundColor: AppColors.textInverse,
               ),
               onPressed: () => Navigator.of(ctx).pop(true),
               child: Text(isBill ? 'Đã trả' : 'Đã nhận'),
             ),
           ],
         ),
       );

       if (confirmed == true && context.mounted) {
         await ref
             .read(plansControllerProvider.notifier)
             .markScheduledItemPaid(scheduledItemId: item.id);
       }
     }
     ```
   - On pending items: wire `onPressed: () => _confirmAndPay(context, ref, item)`.
   - Partition `items`:
     ```dart
     final pending = items.where((i) => i.status == 'PENDING').toList();
     final completed = items.where((i) => i.status == 'PAID_OR_RECEIVED').toList();
     ```
   - Add "LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN" section with permanently disabled `OutlinedButton(onPressed: null, child: Text('Đã hoàn tất'))` and Semantics `btn_completed_obligation_${item.id}`.

---

### 4.3 Dashboard Upcoming Card & Screen
**Files**: `lib/features/dashboard/presentation/dashboard_screen.dart` & `upcoming_obligations_card.dart`

1. In `UpcomingObligationsCard`:
   - For `nextIncome`, add action button:
     ```dart
     Semantics(
       identifier: 'btn_pay_obligation_${nextIncome!.id}',
       button: true,
       child: OutlinedButton(
         onPressed: () => onPayObligation(nextIncome!.id),
         style: OutlinedButton.styleFrom(
           padding: const EdgeInsets.symmetric(horizontal: 12),
           minimumSize: const Size(64, 32),
         ),
         child: const Text('Đã nhận'),
       ),
     )
     ```
2. In `DashboardScreen` (line 115):
   ```dart
   UpcomingObligationsCard(
     pendingBills: pendingBillsAsync.value ?? [],
     nextIncome: nextIncomeAsync.value,
     onPayObligation: (itemId) async {
       // Look up item from pending bills or next income
       final item = (pendingBillsAsync.value ?? []).where((b) => b.id == itemId).firstOrNull ??
           (nextIncomeAsync.value?.id == itemId ? nextIncomeAsync.value : null);
       if (item == null) return;

       final isBill = item.kind == 'BILL';
       final confirmed = await showDialog<bool>(
         context: context,
         builder: (ctx) => AlertDialog(
           title: Text(isBill ? 'Xác nhận thanh toán' : 'Xác nhận đã nhận'),
           content: Text(
             'Bạn có chắc chắn muốn ghi nhận ${isBill ? 'đã thanh toán hoá đơn' : 'đã nhận khoản thu'} '
             '"${item.title}" với số tiền ${VndFormatter.format(item.amountVnd)}?',
             style: VndFormatter.withTabularFigures(AppTypography.bodyMedium),
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(ctx).pop(false),
               child: const Text('Hủy'),
             ),
             ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: isBill
                     ? AppColors.fillAccentRubyPrimary
                     : AppColors.fillAccentVerdantPrimary,
                 foregroundColor: AppColors.textInverse,
               ),
               onPressed: () => Navigator.of(ctx).pop(true),
               child: Text(isBill ? 'Đã trả' : 'Đã nhận'),
             ),
           ],
         ),
       );

       if (confirmed == true && mounted) {
         await ref
             .read(plansControllerProvider.notifier)
             .markScheduledItemPaid(scheduledItemId: itemId);
       }
     },
   )
   ```

---

### 4.4 `_SetBudgetModal`
**File**: `lib/features/plans/presentation/widgets/category_budgets_view.dart`

```dart
class _SetBudgetModalState extends ConsumerState<_SetBudgetModal> {
  late int _selectedCategoryId;
  late int _limitVnd;
  bool _isSubmitting = false; // Add guard

  ...

  Future<void> _submit() async {
    if (_isSubmitting || _limitVnd <= 0) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(plansControllerProvider.notifier).upsertCategoryBudget(
            categoryId: _selectedCategoryId,
            limitVnd: _limitVnd,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  ...
  onPressed: (_limitVnd <= 0 || _isSubmitting) ? null : _submit,
```

---

### 4.5 Envelope Modals, Account Modal, & `CustomKeypad`
1. **`AllocateModal`**:
   Add `if (_isSubmitting || isOver || _selectedEnvelopeId == null || _amountVnd <= 0) return;` at line 153.
2. **`EnvelopeFormModal`**:
   Add `if (_isSubmitting || name.isEmpty) return;` at line 188.
3. **`ReleaseModal`**:
   Add `if (_isSubmitting || isBlocked || _selectedEnvelopeId == null || _amountVnd <= 0) return;` at line 156.
4. **`TransferModal`**:
   Add `if (_isSubmitting || isBlocked || _sourceId == null || _destId == null || _sourceId == _destId || _amountVnd <= 0) return;` at line 177.
5. **`AddEditAccountModal`**:
   Add `if (_isSubmitting || name.isEmpty) return;` at line 209.
6. **`CustomKeypad`**:
   Add `final bool isSubmitting;` (default `false`) and `final bool? isDoneEnabled;`.
   In `_buildBottomRow()`:
   ```dart
   _KeypadButton(
     semanticId: 'keypad_btn_done',
     icon: Icons.check,
     label: 'Xong',
     isAction: true,
     isEnabled: !isSubmitting && (isDoneEnabled ?? true),
     onTap: () {
       if (isSubmitting || !(isDoneEnabled ?? true)) return;
       HapticFeedback.mediumImpact();
       onDonePressed();
     },
   )
   ```

---

## 5. Architectural Invariants & Verification Plan

1. **Integer VND 64-Bit & Tabular Figures**:
   - All amounts in confirmation dialogs and completed history lists use `VndFormatter.format(...)` and `VndFormatter.withTabularFigures(...)`.
2. **Double-Entry Ledger Integrity**:
   - `markScheduledItemPaid` creates standard `EXPENSE` or `INCOME` journal entries inside `db.transaction()`, ensuring `SUM(debit_vnd) == SUM(credit_vnd)`.
3. **Idempotency Guard**:
   - Verified by passing `idempotencyKey: 'scheduled_pay_<id>'` and asserting that calling `markScheduledItemPaid` a second time for the same item returns existing `paidTransactionId` without throwing or creating duplicate entries.
4. **No SQLite String Delimiter Bugs**:
   - String literals in any queries use standard single quotes (`'PENDING'`, `'PAID_OR_RECEIVED'`).
5. **Test Strategy**:
   - Run `flutter test` across existing suite.
   - Add new unit/widget tests for:
     - `createScheduledItem` forces `recurrence == 'NONE'`.
     - `markScheduledItemPaid` has deterministic idempotency key and does not spawn new recurring row.
     - Confirmation dialog displays and can confirm or cancel.
     - Completed history section renders with disabled "Đã hoàn tất" button.
     - Rapid double tap is blocked by `_isSubmitting`.
