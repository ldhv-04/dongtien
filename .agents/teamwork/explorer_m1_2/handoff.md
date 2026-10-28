# Comprehensive Investigation Report: R2 Full CRUD Edit & Delete on Financial Plans with Atomic Ledger Reversals

**Target Platform**: Android (`vn.dongtien`, `vi_VN`, Material 3, integer `VND` 64-bit)  
**Author**: Explorer 2  
**Date**: 2026-10-28T18:46:00Z  
**Scope**: Requirement R2 (Full CRUD on Financial Plans Screen across Tab 0: Ngân sách, Tab 1: Mục tiêu tiết kiệm, and Tab 2: Nghĩa vụ & Dự báo, including atomic ledger reversals for completed scheduled obligations).

---

## 1. Observation

### 1.1 Tab 0: Ngân sách (`CategoryBudgetsView` & `PlansController`)
- **File**: `lib/features/plans/presentation/widgets/category_budgets_view.dart`
  - Lines 107–187: In `CategoryBudgetsView`, active budget items are rendered via `summary.categoryProgresses.map(...)` wrapped in `Semantics(identifier: 'card_budget_${prog.categoryId}', ...)`. Tapping the card (`InkWell.onTap`) opens `_SetBudgetModal`. There are **no explicit Edit (`Sửa`) or Delete (`Xóa`) buttons** on the card.
  - Lines 216–323: `_SetBudgetModal` accepts `initialLimitVnd` and provides a `CustomKeypad` and "Lưu hạn mức" `ElevatedButton`. There is **no Delete button** inside `_SetBudgetModal`.
- **File**: `lib/features/plans/presentation/providers/plans_providers.dart`
  - Lines 129–171: `PlansController` implements `upsertCategoryBudget({required int categoryId, required int limitVnd, int? yearMonth, int alertThresholdPct = 80})`, which inserts or updates rows in `db.categoryBudgets`.
  - **Absence**: There is **no `deleteCategoryBudget` method** in `PlansController`.
- **File**: `lib/core/database/app_database.dart`
  - Lines 165–184: `CategoryBudgets` table schema:
    ```dart
    class CategoryBudgets extends Table {
      IntColumn get id => integer().autoIncrement()();
      IntColumn get categoryId => integer().references(Categories, #id, onDelete: KeyAction.cascade)();
      IntColumn get yearMonth => integer()();
      IntColumn get limitVnd => integer()();
      IntColumn get alertThresholdPct => integer().withDefault(const Constant(80))();
    }
    ```
    Constraint: `idx_category_budgets_unique` on `(categoryId, yearMonth)`.
  - Lines 266–270: `AppDatabase` registers only `LedgerDao` and `EnvelopeDao`. There is no separate `CategoryBudgetsDao` class; budget operations are performed directly on `db.categoryBudgets`.

### 1.2 Tab 1: Mục tiêu tiết kiệm (`SavingsGoalsView` & `Envelopes`)
- **File**: `lib/features/plans/presentation/widgets/savings_goals_view.dart`
  - Lines 48–77 & 152–221: `feasibilityEvaluationProvider` derives active goals from envelopes having `targetAmountVnd != null && targetAmountVnd > 0`. Each goal is displayed as `card_goal_${goal.id}` showing current vs target amount, progress bar, and required savings per month.
  - Lines 173–221: Each goal card contains only informational text and progress bar. There are **no Edit (`Sửa`) or Delete (`Xóa`) buttons** on `card_goal_${goal.id}`.
- **File**: `lib/features/envelopes/presentation/modals/envelope_form_modal.dart`
  - Lines 14–228: `EnvelopeFormModal` already accepts `final Envelope? editingEnvelope;`. When provided, it pre-populates `_nameController`, `_policy`, `_targetAmountVnd`, `_targetDate`, `_allowNegativeException`, and `_priority`. On submission, it invokes `envelopeController.updateEnvelope(...)`.
- **File**: `lib/core/database/daos/envelope_dao.dart` & `lib/core/database/app_database.dart`
  - Lines 135–160 (`app_database.dart`): `EnvelopeMovements.sourceEnvelopeId` and `destEnvelopeId` specify `onDelete: KeyAction.restrict`. Because SQLite enforces `PRAGMA foreign_keys = ON;`, hard deleting an envelope (`DELETE FROM envelopes WHERE id = ?`) that has movements throws a foreign key constraint violation.
  - Lines 107–127 (`app_database.dart`): `Envelopes.isArchived` defaults to `false`.
  - Lines 77–123 (`envelope_dao.dart`): `EnvelopeDao.release({required int envelopeId, required int amountVnd})` inserts an `EnvelopeMovement` (`RELEASE`) and decrements `reserved_balance_vnd` by `amountVnd`, which frees reserved funds back into `available_to_allocate` without creating general ledger postings.
  - **Absence**: `PlansController` lacks a dedicated `deleteSavingsGoal(int envelopeId)` method that orchestrates releasing positive reserves before archiving.

### 1.3 Tab 2: Nghĩa vụ & Dự báo (`ObligationsForecastView`, `UpcomingObligationsCard`, & `PlansController`)
- **File**: `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`
  - Lines 214–273: Pending items render with `btn_pay_obligation_${item.id}` ("Đã trả" / "Đã nhận"). There are **no Edit (`btn_edit_obligation_${item.id}`) or Delete (`btn_delete_obligation_${item.id}`) buttons**.
  - Lines 281–343: Completed items render under "LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN" with `btn_completed_obligation_${item.id}` ("Đã hoàn tất", disabled). There are **no Edit or Delete buttons**.
  - Lines 357–535: `_AddScheduledItemModal` is strictly for creation (`createScheduledItem`). It does not accept an existing item for editing and does not have a category picker.
- **File**: `lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart`
  - Lines 70–82 & 111–123: Renders pending obligations with `btn_pay_obligation_${id}`. Lacks Edit or Delete action callbacks.
- **File**: `lib/features/plans/presentation/providers/plans_providers.dart`
  - Lines 260–299: `createScheduledItem` inserts into `scheduledItems` (`recurrence: 'NONE'`, `status: 'PENDING'`).
  - Lines 303–461: `markScheduledItemPaid` runs in `db.transaction`, sets `status = 'PAID_OR_RECEIVED'`, posts a general ledger transaction (`paidTransactionId = createdTxId`), records `idempotencyKey = 'scheduled_pay_${item.id}'`, handles linked envelope spend, and reconciles notifications.
  - **Absence**: `PlansController` lacks `updateScheduledItem(...)` and `deleteScheduledItem(int scheduledItemId)`.
- **File**: `lib/core/database/daos/ledger_dao.dart`
  - Lines 219–331: `voidTransaction(int transactionId)` atomically marks target `status = 'VOIDED'`, posts a `REVERSAL` transaction with inverted postings (`debit` <-> `credit`), and inserts `REVERSAL` envelope movements restoring any deducted envelope reserve (`UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ?`).
  - Lines 341–380: `editTransaction(...)` voids the original transaction and posts a replacement transaction with status `'POSTED'`.

---

## 2. Logic Chain

```
[Observation 1.1] CategoryBudgetsView lacks delete/edit controls & PlansController lacks deleteCategoryBudget
  │
  ├─► Needs: CategoryBudgetsView cards must expose btn_edit_budget_<id> (open modal) and btn_delete_budget_<id> (confirm dialog)
  ├─► Needs: _SetBudgetModal must expose a Delete action when initialLimitVnd > 0
  └─► Needs: PlansController.deleteCategoryBudget(categoryId, {yearMonth}) executing SQLite DELETE on category_budgets

[Observation 1.2] Envelopes have KeyAction.restrict on movements; goals are envelopes with targetAmountVnd > 0
  │
  ├─► If envelope has reservedBalanceVnd > 0: Must invoke EnvelopeDao.release to refund reserves to available_to_allocate
  ├─► Hard DELETE would violate FK constraint if movements exist -> Archiving (isArchived = true, targetAmountVnd = null) is required
  ├─► EnvelopeFormModal already handles edit mode with editingEnvelope parameter
  └─► Needs: SavingsGoalsView cards must expose btn_edit_goal_<id> and btn_delete_goal_<id> with confirmation dialog

[Observation 1.3] ScheduledItems can be PENDING or PAID_OR_RECEIVED (linked to paidTransactionId)
  │
  ├─► If PENDING item is deleted: Remove scheduled_items row + reconcile notifications
  ├─► If PENDING item is edited: Update scheduled_items row + reconcile notifications
  ├─► If PAID_OR_RECEIVED item is deleted:
  │     1. Atomic db.transaction: call ledgerDao.voidTransaction(paidTransactionId)
  │     2. Inverts postings, restores liquid asset balance, restores linked envelope balance
  │     3. Delete scheduled_items row
  │     4. Reconcile notifications and budget alerts
  ├─► If PAID_OR_RECEIVED item is edited:
  │     1. Atomic db.transaction: call ledgerDao.voidTransaction(oldTxId)
  │     2. Post new transaction with updated amount/category/envelope and payKey = 'scheduled_pay_${id}_rev_${nowMs}'
  │     3. Update scheduled_items row (including paidTransactionId = newTxId)
  │     4. Reconcile notifications and budget alerts
  └─► Needs: UI cards on ObligationsForecastView (both sections) and UpcomingObligationsCard must expose btn_edit_obligation_<id> and btn_delete_obligation_<id>
```

---

## 3. Detailed Architecture & Technical Blueprint for R2

### 3.1 Tab 0: Ngân sách (Category Budgets)

#### 3.1.1 Controller Implementation (`PlansController`)
Add `deleteCategoryBudget` to `PlansController` in `lib/features/plans/presentation/providers/plans_providers.dart`:
```dart
/// Deletes a monthly category budget limit.
Future<void> deleteCategoryBudget({
  required int categoryId,
  int? yearMonth,
}) async {
  state = const AsyncValue.loading();
  try {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final defaultYm = now.year * 100 + now.month;
    final ym = yearMonth ?? defaultYm;

    await (db.delete(db.categoryBudgets)
          ..where((b) => b.categoryId.equals(categoryId) & b.yearMonth.equals(ym)))
        .go();

    state = const AsyncValue.data(null);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}
```

#### 3.1.2 UI Widget Updates (`CategoryBudgetsView`)
1. **On `card_budget_${prog.categoryId}`**:
   Add an actions footer below the progress and limit numbers:
   ```dart
   Row(
     mainAxisAlignment: MainAxisAlignment.end,
     children: [
       Semantics(
         identifier: 'btn_edit_budget_${prog.categoryId}',
         button: true,
         child: TextButton.icon(
           icon: const Icon(Icons.edit_outlined, size: 16),
           label: const Text('Sửa'),
           onPressed: () => _openSetBudgetSheet(
             context,
             prog.categoryId,
             prog.categoryName,
             initialLimit: prog.limitVnd.amount,
           ),
         ),
       ),
       AppSpacing.gapW8,
       Semantics(
         identifier: 'btn_delete_budget_${prog.categoryId}',
         button: true,
         child: TextButton.icon(
           icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textAccentRubyPrimary),
           label: const Text('Xóa', style: TextStyle(color: AppColors.textAccentRubyPrimary)),
           onPressed: () => _confirmAndDeleteBudget(
             context,
             ref,
             prog.categoryId,
             prog.categoryName,
             prog.yearMonth,
           ),
         ),
       ),
     ],
   )
   ```
2. **Confirmation Dialog `_confirmAndDeleteBudget`**:
   - Title: `Xác nhận xóa ngân sách`
   - Content: `Bạn có chắc chắn muốn xóa ngân sách cho danh mục "${categoryName}"? Lịch sử chi tiêu thực tế trong sổ cái vẫn được bảo toàn nguyên vẹn.`
   - Actions: `Hủy` (returns false), `Xóa` (calls `controller.deleteCategoryBudget(categoryId: categoryId, yearMonth: yearMonth)`).
3. **Inside `_SetBudgetModal`**:
   When `widget.initialLimitVnd > 0`, render a secondary delete button:
   ```dart
   Semantics(
     identifier: 'btn_delete_budget_${_selectedCategoryId}',
     button: true,
     child: TextButton.icon(
       icon: const Icon(Icons.delete_outline, color: AppColors.textAccentRubyPrimary),
       label: const Text('Xóa ngân sách này', style: TextStyle(color: AppColors.textAccentRubyPrimary)),
       onPressed: _isSubmitting ? null : () => _confirmAndDelete(context),
     ),
   )
   ```

---

### 3.2 Tab 1: Mục tiêu tiết kiệm (Savings Goals)

#### 3.2.1 Controller Implementation (`PlansController`)
Add `deleteSavingsGoal` to `PlansController`:
```dart
/// Deletes a savings goal envelope.
/// If reserved balance > 0, releases the balance back to liquid cash (available-to-allocate)
/// before archiving the envelope and clearing its target amount.
Future<void> deleteSavingsGoal(int envelopeId) async {
  state = const AsyncValue.loading();
  try {
    final db = ref.read(databaseProvider);
    final envelopeDao = ref.read(envelopeDaoProvider);

    await db.transaction(() async {
      final env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envelopeId)))
          .getSingle();

      // 1. Release reserved balance back to Available-to-Allocate if positive
      if (env.reservedBalanceVnd > 0) {
        await envelopeDao.release(
          envelopeId: envelopeId,
          amountVnd: env.reservedBalanceVnd,
        );
      }

      // 2. Archive envelope and reset target to null (decouples from feasibility advisor)
      await (db.update(db.envelopes)..where((e) => e.id.equals(envelopeId))).write(
        const EnvelopesCompanion(
          isArchived: Value(true),
          targetAmountVnd: Value(null),
          targetDateMs: Value(null),
        ),
      );
    });

    state = const AsyncValue.data(null);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}
```

#### 3.2.2 UI Widget Updates (`SavingsGoalsView`)
On each active goal card `card_goal_${goal.id}`:
1. **Edit Action**:
   ```dart
   Semantics(
     identifier: 'btn_edit_goal_${goal.id}',
     button: true,
     child: TextButton.icon(
       icon: const Icon(Icons.edit_outlined, size: 16),
       label: const Text('Sửa'),
       onPressed: () async {
         final envelopes = ref.read(envelopesStreamProvider).value ?? [];
         final env = envelopes.firstWhere((e) => e.id == goal.id);
         showModalBottomSheet<void>(
           context: context,
           isScrollControlled: true,
           backgroundColor: Colors.transparent,
           builder: (_) => EnvelopeFormModal(editingEnvelope: env),
         );
       },
     ),
   )
   ```
2. **Delete Action with Confirmation**:
   ```dart
   Semantics(
     identifier: 'btn_delete_goal_${goal.id}',
     button: true,
     child: TextButton.icon(
       icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textAccentRubyPrimary),
       label: const Text('Xóa', style: TextStyle(color: AppColors.textAccentRubyPrimary)),
       onPressed: () => _confirmAndDeleteGoal(context, ref, goal),
     ),
   )
   ```
3. **Confirmation Dialog `_confirmAndDeleteGoal`**:
   - If `goal.currentReserved.amount > 0`:
     `"Mục tiêu "${goal.name}" đang có ${VndFormatter.formatMoney(goal.currentReserved)} tiền bảo lưu. Khi xóa, toàn bộ số tiền này sẽ được giải phóng về tiền khả dụng (Available to Allocate). Bạn có chắc chắn muốn xóa không?"`
   - If `goal.currentReserved.amount == 0`:
     `"Bạn có chắc chắn muốn xóa mục tiêu "${goal.name}" không?"`
   - On confirm: calls `ref.read(plansControllerProvider.notifier).deleteSavingsGoal(goal.id)`.

---

### 3.3 Tab 2: Nghĩa vụ & Dự báo (Scheduled Obligations & Ledger Reversals)

#### 3.3.1 Controller Implementation (`PlansController`)

##### 1. `deleteScheduledItem` (Atomic Ledger Reversal when Completed)
```dart
/// Deletes a scheduled item.
/// If status is PAID_OR_RECEIVED, atomically voids and reverses the linked
/// journal transaction via LedgerDao.voidTransaction (inverting postings and
/// restoring any linked envelope SPEND balance) before deleting the scheduled item.
Future<void> deleteScheduledItem(int scheduledItemId) async {
  state = const AsyncValue.loading();
  try {
    final db = ref.read(databaseProvider);
    final dao = ref.read(ledgerDaoProvider);

    await db.transaction(() async {
      final item = await (db.select(db.scheduledItems)
            ..where((s) => s.id.equals(scheduledItemId)))
          .getSingleOrNull();

      if (item == null) return;

      // 1. If paid/received, void the ledger transaction
      if (item.status == 'PAID_OR_RECEIVED' && item.paidTransactionId != null) {
        final tx = await (db.select(db.journalTransactions)
              ..where((t) => t.id.equals(item.paidTransactionId!)))
            .getSingleOrNull();
        if (tx != null && tx.status == 'POSTED') {
          await dao.voidTransaction(item.paidTransactionId!);
        }
      }

      // 2. Delete the scheduled item row
      await (db.delete(db.scheduledItems)
            ..where((s) => s.id.equals(scheduledItemId)))
          .go();
    });

    // 3. Reconcile notifications
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.reconcileFromDatabase(db);

    state = const AsyncValue.data(null);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}
```

##### 2. `updateScheduledItem` (Atomic Ledger Re-posting when Completed)
```dart
/// Updates an existing scheduled item.
/// If status is PENDING, simply updates the scheduled item record.
/// If status is PAID_OR_RECEIVED, atomically:
///   1. Voids old paidTransactionId via LedgerDao.voidTransaction.
///   2. Posts the updated transaction with new amount/category/envelope and fresh idempotency key.
///   3. Updates scheduled item record with new values and new paidTransactionId.
Future<void> updateScheduledItem({
  required int scheduledItemId,
  required String kind,
  required String title,
  required int amountVnd,
  required DateTime dueDate,
  int? categoryId,
  int? linkedEnvelopeId,
  int reminderDaysBefore = 1,
}) async {
  state = const AsyncValue.loading();
  try {
    final db = ref.read(databaseProvider);
    final dao = ref.read(ledgerDaoProvider);

    int? alertCategoryId;

    await db.transaction(() async {
      final item = await (db.select(db.scheduledItems)
            ..where((s) => s.id.equals(scheduledItemId)))
          .getSingle();

      int? newPaidTxId = item.paidTransactionId;

      if (item.status == 'PAID_OR_RECEIVED') {
        // Step 1: Void the old transaction
        if (item.paidTransactionId != null) {
          final oldTx = await (db.select(db.journalTransactions)
                ..where((t) => t.id.equals(item.paidTransactionId!)))
              .getSingleOrNull();
          if (oldTx != null && oldTx.status == 'POSTED') {
            await dao.voidTransaction(item.paidTransactionId!);
          }
        }

        // Step 2: Determine account used in original transaction or fallback to liquid account
        int targetAccountId = 0;
        if (item.paidTransactionId != null) {
          final oldPostings = await (db.select(db.journalPostings)
                ..where((p) => p.transactionId.equals(item.paidTransactionId!)))
              .get();
          final assetLeg = oldPostings.firstWhereOrNull(
            (p) => kind == 'BILL' ? p.creditVnd > 0 : p.debitVnd > 0,
          );
          if (assetLeg != null) {
            targetAccountId = assetLeg.accountId;
          }
        }
        if (targetAccountId == 0) {
          final accounts = await dao.getAccountsWithBalances();
          final liquid = accounts.where((a) => a.isLiquid).toList();
          targetAccountId = liquid.isNotEmpty ? liquid.first.id : 1;
        }

        // Step 3: Resolve category
        int targetCategoryId = categoryId ?? (item.categoryId ?? 0);
        if (targetCategoryId == 0) {
          final cats = await (db.select(db.categories)
                ..where((c) => c.kind.equals(kind == 'PLANNED_INCOME' ? 'INCOME' : 'EXPENSE')))
              .get();
          if (kind == 'BILL') {
            final defaultCat = cats.firstWhereOrNull((c) => c.name == 'Hoá đơn & Tiện ích') ??
                cats.firstWhereOrNull((c) => c.name == 'Nhà cửa') ??
                cats.first;
            targetCategoryId = defaultCat.id;
          } else {
            final defaultCat = cats.firstWhereOrNull((c) => c.name == 'Lương') ?? cats.first;
            targetCategoryId = defaultCat.id;
          }
        }

        if (kind == 'BILL') {
          alertCategoryId = targetCategoryId;
        }

        // Step 4: Post new replacement transaction
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final revKey = 'scheduled_pay_${item.id}_rev_$nowMs';

        if (kind == 'PLANNED_INCOME') {
          newPaidTxId = await dao.postTransactionCommand(
            PostTransactionCommand.income(
              receivingAssetAccountId: targetAccountId,
              categoryId: targetCategoryId,
              amountVnd: amountVnd,
              occurredAt: nowMs,
              description: title,
              idempotencyKey: revKey,
            ),
          );
        } else {
          // BILL
          int? envelopeToLink = linkedEnvelopeId;
          int partialEnvelopeSpend = 0;
          if (envelopeToLink != null) {
            final env = await (db.select(db.envelopes)
                  ..where((e) => e.id.equals(envelopeToLink)))
                .getSingleOrNull();
            if (env != null) {
              if (env.reservedBalanceVnd >= amountVnd || env.allowNegativeException) {
                partialEnvelopeSpend = 0;
              } else {
                partialEnvelopeSpend = math.max(0, env.reservedBalanceVnd);
                envelopeToLink = null;
              }
            } else {
              envelopeToLink = null;
            }
          }

          newPaidTxId = await dao.postTransaction(
            txType: 'EXPENSE',
            description: title,
            occurredAt: nowMs,
            postings: PostingMatrix.buildExpense(
              sourceAccountId: targetAccountId,
              categoryId: targetCategoryId,
              amountVnd: amountVnd,
              envelopeId: envelopeToLink ?? linkedEnvelopeId,
            ),
            idempotencyKey: revKey,
            linkedEnvelopeId: envelopeToLink,
            envelopeMovementType: envelopeToLink != null ? 'SPEND' : null,
          );

          if (partialEnvelopeSpend > 0 && linkedEnvelopeId != null) {
            await db.into(db.envelopeMovements).insert(
                  EnvelopeMovementsCompanion.insert(
                    movementType: 'SPEND',
                    amountVnd: partialEnvelopeSpend,
                    sourceEnvelopeId: Value(linkedEnvelopeId),
                    linkedTransactionId: Value(newPaidTxId),
                    linkedObligationId: Value(item.id),
                    occurredAt: nowMs,
                  ),
                );
            await db.customUpdate(
              'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
              variables: [
                Variable.withInt(partialEnvelopeSpend),
                Variable.withInt(linkedEnvelopeId),
              ],
              updates: {db.envelopes},
            );
          }
        }
      }

      // Step 5: Update scheduled item record
      await (db.update(db.scheduledItems)..where((s) => s.id.equals(item.id))).write(
        ScheduledItemsCompanion(
          title: Value(title),
          kind: Value(kind),
          amountVnd: Value(amountVnd),
          dueDateMs: Value(dueDate.millisecondsSinceEpoch),
          anchorDayOfMonth: Value(dueDate.day),
          categoryId: Value(categoryId),
          linkedEnvelopeId: Value(linkedEnvelopeId),
          paidTransactionId: Value(newPaidTxId),
          reminderDaysBefore: Value(reminderDaysBefore),
        ),
      );
    });

    // Step 6: Reconcile notifications and threshold alerts
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.reconcileFromDatabase(db);
    if (alertCategoryId != null) {
      await scheduler.checkCategoryBudgetAlert(
        db: db,
        categoryId: alertCategoryId!,
      );
    }

    state = const AsyncValue.data(null);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}
```

#### 3.3.2 UI Widget Updates (`ObligationsForecastView` & `UpcomingObligationsCard`)

1. **Scheduled Item Modal (`_ScheduledItemModal`)**:
   Refactor `_AddScheduledItemModal` to accept an optional `ScheduledItem? editingItem`:
   - Title: `isEditing ? 'Chỉnh sửa lịch nghĩa vụ' : 'Thêm lịch nghĩa vụ / thu nhập'`
   - Includes Category Selector (`ChoiceChip` / `DropdownMenu`) matching kind (`EXPENSE` for `BILL`, `INCOME` for `PLANNED_INCOME`), defaulting cleanly.
   - Includes `_isSubmitting` double-tap guard.
   - Button: `isEditing ? 'Lưu thay đổi' : 'Lưu lịch'`
   - Submits to `controller.updateScheduledItem` or `controller.createScheduledItem`.

2. **Actions on Pending Cards (`ObligationsForecastView`)**:
   Add Edit & Delete buttons next to `btn_pay_obligation_${item.id}`:
   ```dart
   Row(
     mainAxisSize: MainAxisSize.min,
     children: [
       Semantics(
         identifier: 'btn_edit_obligation_${item.id}',
         button: true,
         child: IconButton(
           icon: const Icon(Icons.edit_outlined, size: 20),
           tooltip: 'Sửa',
           onPressed: () => _openEditModal(context, item),
         ),
       ),
       Semantics(
         identifier: 'btn_delete_obligation_${item.id}',
         button: true,
         child: IconButton(
           icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textAccentRubyPrimary),
           tooltip: 'Xóa',
           onPressed: () => _confirmAndDeletePending(context, ref, item),
         ),
       ),
       Semantics(
         identifier: 'btn_pay_obligation_${item.id}',
         button: true,
         child: OutlinedButton(
           onPressed: () => _confirmAndPay(context, ref, item),
           child: Text(isBill ? 'Đã trả' : 'Đã nhận'),
         ),
       ),
     ],
   )
   ```

3. **Actions on Completed Cards ("LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN")**:
   Add Edit & Delete buttons next to disabled `btn_completed_obligation_${item.id}`:
   ```dart
   Row(
     mainAxisSize: MainAxisSize.min,
     children: [
       Semantics(
         identifier: 'btn_edit_obligation_${item.id}',
         button: true,
         child: IconButton(
           icon: const Icon(Icons.edit_outlined, size: 20),
           tooltip: 'Sửa',
           onPressed: () => _openEditModal(context, item),
         ),
       ),
       Semantics(
         identifier: 'btn_delete_obligation_${item.id}',
         button: true,
         child: IconButton(
           icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textAccentRubyPrimary),
           tooltip: 'Xóa',
           onPressed: () => _confirmAndDeleteCompleted(context, ref, item),
         ),
       ),
       Semantics(
         identifier: 'btn_completed_obligation_${item.id}',
         button: true,
         enabled: false,
         child: const OutlinedButton(
           onPressed: null,
           child: Text('Đã hoàn tất'),
         ),
       ),
     ],
   )
   ```

4. **Confirmation Dialog for Completed Item Deletion**:
   - Title: `Xác nhận xóa & hoàn tác giao dịch`
   - Content: `Hoá đơn/Khoản thu này đã được ghi nhận vào sổ cái tài chính. Khi xóa, giao dịch thanh toán sẽ được hoàn tác tự động (hoàn lại tiền vào tài khoản và quỹ tiền bảo vệ liên quan). Bạn có chắc chắn muốn xóa không?`
   - Actions: `Hủy` (false), `Hoàn tác & Xóa` (calls `controller.deleteScheduledItem(item.id)`).

5. **`UpcomingObligationsCard` on Dashboard**:
   Expose Edit and Delete callbacks (`onEditObligation` and `onDeleteObligation`) on each obligation row:
   - Semantics: `btn_edit_obligation_${bill.id}` and `btn_delete_obligation_${bill.id}`.
   - When tapped, triggers the exact same modal/confirmation flow as on the Plans screen.

---

## 4. Caveats & Edge Conditions

1. **Foreign Key Integrity on Envelopes**:
   `EnvelopeMovements` maintains `KeyAction.restrict` on `sourceEnvelopeId` and `destEnvelopeId`. Deleting a savings goal MUST NEVER execute a raw `DELETE FROM envelopes`. Instead, it releases `reservedBalanceVnd` and sets `isArchived = true`, `targetAmountVnd = null`, preserving ledger integrity and foreign key constraints.
2. **Reversal Idempotency**:
   If an obligation's linked `paidTransactionId` was already manually voided or superseded via the Transactions tab Audit History, calling `deleteScheduledItem` checks `tx.status == 'POSTED'` before invoking `ledgerDao.voidTransaction` to avoid throwing `InvalidTransactionException`.
3. **Double-Tap Protection**:
   All delete dialog confirmations and modal submit buttons bind to `_isSubmitting` guards to prevent rapid multi-tap race conditions.

---

## 5. Conclusion

1. **Full CRUD Feasibility**:
   - Tab 0 (Budgets) requires adding `deleteCategoryBudget` to `PlansController` and attaching Edit/Delete buttons to `card_budget_<categoryId>` and `_SetBudgetModal`.
   - Tab 1 (Goals) requires adding `deleteSavingsGoal` to `PlansController`, which releases any positive reserve via `EnvelopeDao.release` before archiving, and attaching Edit/Delete buttons to `card_goal_<id>`.
   - Tab 2 (Obligations) requires adding `updateScheduledItem` and `deleteScheduledItem` to `PlansController`, providing full atomic ledger reversals via `ledgerDao.voidTransaction` for `PAID_OR_RECEIVED` items.
2. **Architecture Compliance**:
   - 100% compliant with AGENTS.md Invariant 1.2 (Integer VND 64-bit, Tabular figures) and Invariant 1.3 (Double-entry ledger equation of motion, audit-preserving reversals, virtual fund decoupling).
   - No external packages needed; standard Riverpod `AsyncNotifier` and existing `LedgerDao` methods are reused.

---

## 6. Verification Method

### 6.1 Unit & Database Automated Test Specifications

Create `test/unit/m2_r2_plans_crud_reversal_test.dart` and `test/widget/m2_r2_plans_crud_widget_test.dart`:

```dart
// Test 1: Category Budget CRUD
test('Category Budget CRUD in PlansController', () async {
  // 1. Create budget
  await controller.upsertCategoryBudget(categoryId: catId, limitVnd: 5000000);
  expect((await db.select(db.categoryBudgets).get()).length, 1);

  // 2. Edit budget
  await controller.upsertCategoryBudget(categoryId: catId, limitVnd: 6000000);
  final b1 = await db.select(db.categoryBudgets).getSingle();
  expect(b1.limitVnd, 6000000);

  // 3. Delete budget
  await controller.deleteCategoryBudget(categoryId: catId);
  expect((await db.select(db.categoryBudgets).get()).isEmpty, true);
});

// Test 2: Savings Goal Deletion Releases Reserved Balance
test('Deleting savings goal releases reserved funds to available-to-allocate', () async {
  // 1. Setup envelope with 1.000.000 ₫ reserved
  final envId = await db.into(db.envelopes).insert(
    EnvelopesCompanion.insert(name: 'Quỹ xe', policy: 'PROTECTED', targetAmountVnd: Value(10000000)),
  );
  await db.envelopeDao.allocate(envelopeId: envId, amountVnd: 1000000, totalLiquidAssetsVnd: 10000000);
  expect(await db.envelopeDao.getAvailableToAllocate(10000000), 9000000);

  // 2. Delete savings goal
  await controller.deleteSavingsGoal(envId);

  // 3. Verify reserved is 0, envelope is archived, and available-to-allocate restored to 10.000.000 ₫
  final env = await (db.select(db.envelopes)..where((e) => e.id.equals(envId))).getSingle();
  expect(env.reservedBalanceVnd, 0);
  expect(env.isArchived, true);
  expect(env.targetAmountVnd, isNull);
  expect(await db.envelopeDao.getAvailableToAllocate(10000000), 10000000);
});

// Test 3: Deleting Completed Obligation Atomically Voids Ledger Transaction
test('Deleting a PAID bill atomically voids ledger transaction and restores account and envelope balances', () async {
  // 1. Setup Bank = 10.000.000 ₫, Envelope = 1.000.000 ₫, Bill = 1.500.000 ₫ (linked to envelope)
  final billId = await controller.createScheduledItem(
    kind: 'BILL',
    title: 'Tiền bảo hiểm',
    amountVnd: 1500000,
    dueDate: DateTime(2026, 11, 10),
    categoryId: expenseCatId,
    linkedEnvelopeId: envId,
  );
  final txId = await controller.markScheduledItemPaid(scheduledItemId: billId);

  // Bank should be 8.500.000 ₫; Envelope reserve should be 0 ₫
  expect(await db.ledgerDao.getTotalLiquidAssets(), 8500000);
  var env = await (db.select(db.envelopes)..where((e) => e.id.equals(envId))).getSingle();
  expect(env.reservedBalanceVnd, 0);

  // 2. Delete the paid obligation
  await controller.deleteScheduledItem(billId);

  // 3. Verify:
  // - Original transaction txId status == 'VOIDED'
  final origTx = await (db.select(db.journalTransactions)..where((t) => t.id.equals(txId))).getSingle();
  expect(origTx.status, 'VOIDED');

  // - REVERSAL transaction created
  final reversals = await (db.select(db.journalTransactions)..where((t) => t.txType.equals('REVERSAL'))).get();
  expect(reversals.isNotEmpty, true);

  // - Bank balance fully restored to 10.000.000 ₫
  expect(await db.ledgerDao.getTotalLiquidAssets(), 10000000);

  // - Envelope reserve fully restored to 1.000.000 ₫
  env = await (db.select(db.envelopes)..where((e) => e.id.equals(envId))).getSingle();
  expect(env.reservedBalanceVnd, 1000000);

  // - Scheduled item row is deleted
  final item = await (db.select(db.scheduledItems)..where((s) => s.id.equals(billId))).getSingleOrNull();
  expect(item, isNull);
});

// Test 4: Editing Completed Obligation Voids Old and Posts New
test('Editing a PAID bill atomically voids old transaction and updates ledger with new amount', () async {
  // 1. Setup and pay bill of 1.000.000 ₫ -> Bank = 9.000.000 ₫
  final billId = await controller.createScheduledItem(
    kind: 'BILL',
    title: 'Tiền mạng',
    amountVnd: 1000000,
    dueDate: DateTime(2026, 11, 1),
    categoryId: expenseCatId,
  );
  final origTxId = await controller.markScheduledItemPaid(scheduledItemId: billId);
  expect(await db.ledgerDao.getTotalLiquidAssets(), 9000000);

  // 2. Edit bill to 1.500.000 ₫
  await controller.updateScheduledItem(
    scheduledItemId: billId,
    kind: 'BILL',
    title: 'Tiền mạng gói nâng cấp',
    amountVnd: 1500000,
    dueDate: DateTime(2026, 11, 1),
    categoryId: expenseCatId,
  );

  // 3. Verify:
  // - Old transaction voided
  final origTx = await (db.select(db.journalTransactions)..where((t) => t.id.equals(origTxId))).getSingle();
  expect(origTx.status, 'VOIDED');

  // - New transaction posted with 1.500.000 ₫
  final updatedBill = await (db.select(db.scheduledItems)..where((s) => s.id.equals(billId))).getSingle();
  expect(updatedBill.paidTransactionId, isNot(origTxId));
  expect(updatedBill.amountVnd, 1500000);

  // - Net liquid assets reflect exactly 1.500.000 ₫ deducted -> 8.500.000 ₫
  expect(await db.ledgerDao.getTotalLiquidAssets(), 8500000);
});
```

### 6.2 Test Command Execution
Run via PowerShell with environment configured:
```powershell
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path

dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test test/unit/m2_r2_plans_crud_reversal_test.dart test/widget/m2_r2_plans_crud_widget_test.dart
```
