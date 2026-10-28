## 2026-10-28T18:40:10Z
You are Explorer 2 on Project Đồng Tiền.
Your working directory is: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_2`
All your intermediate progress and final report must be written inside your working directory (`progress.md`, `handoff.md`).

MANDATORY READING:
1. `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (Specifically read section `## 2026-10-28T18:36:33Z` and Requirement R2).
2. `c:\Users\coihu12\Documents\App\AGENTS.md` (Architectural invariants, integer VND, clean architecture rules).
3. `c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_3\SCOPE.md`

YOUR INVESTIGATION OBJECTIVE: R2 (Full CRUD Edit & Delete on Financial Plans Screen with Atomic Ledger Reversals)
1. Inspect Tab 0 (Ngân sách):
   - `lib/features/plans/presentation/widgets/category_budgets_view.dart` & `lib/features/plans/presentation/providers/plans_providers.dart`.
   - Inspect how category budgets are created/updated via `_SetBudgetModal` / `upsertCategoryBudget`.
   - How to add Edit (`Sửa`) and Delete (`Xóa`) actions with confirmation dialogs and Semantics identifiers (`btn_edit_budget_<categoryId>`, `btn_delete_budget_<categoryId>`).
   - How `deleteCategoryBudget` should be implemented in `PlansController` and `CategoryBudgetsDao`.
2. Inspect Tab 1 (Mục tiêu tiết kiệm):
   - `lib/features/plans/presentation/widgets/savings_goals_view.dart`, `lib/features/envelopes/presentation/widgets/envelope_form_modal.dart`, and `EnvelopesDao`.
   - How to provide Edit (`Sửa`, `btn_edit_goal_<id>`) opening `EnvelopeFormModal` pre-populated, and Delete (`Xóa`, `btn_delete_goal_<id>`) with confirmation dialog.
   - What happens if the goal/envelope has `reservedBalanceVnd > 0`: how to release reserved balance back to liquid cash before deletion or archiving.
3. Inspect Tab 2 (Nghĩa vụ & Dự báo):
   - `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`, `UpcomingObligationsCard`, and `PlansController`.
   - For `PENDING` items: how `updateScheduledItem` and `deleteScheduledItem` should work.
   - For `PAID_OR_RECEIVED` items:
     - Deleting: How to atomically void/reverse the linked transaction (`paidTransactionId`) via `ledgerDao.voidTransaction` (offsetting postings, restoring envelope balance), and delete the scheduled item.
     - Editing: How to atomically void/reverse the old transaction and post the updated transaction with a fresh deterministic idempotency key.
   - Check confirmation dialogs and double-tap `_isSubmitting` guards.

Deliverable:
Write a comprehensive report to `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_2\handoff.md` detailing:
- Exact data flow, DAO methods, controller methods, and UI widget changes for Tab 0, Tab 1, and Tab 2.
- Exact transaction reversal flow for completed scheduled items.
- Test specifications to verify full CRUD and atomic ledger reversals.
Send a message back to the orchestrator when finished.
