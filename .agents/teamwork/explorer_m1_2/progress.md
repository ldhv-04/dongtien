# Progress Log - Explorer 2 (R2 Investigation)

Last visited: 2026-10-28T18:48:30Z

## Status
- [x] Initialized DISPATCH.md and BRIEFING.md
- [x] Read `ORIGINAL_REQUEST.md` (R2 focus), `AGENTS.md`, and `orchestrator_3/SCOPE.md`
- [x] Deep dive Tab 0 (Ngân sách - Category Budgets)
  - Inspected `CategoryBudgetsView`, `_SetBudgetModal`, `currentMonthlyBudgetSummaryProvider`, `CategoryBudgets` schema.
  - Formulated `deleteCategoryBudget` implementation for `PlansController`.
  - Designed UI controls for Edit (`btn_edit_budget_<categoryId>`) and Delete (`btn_delete_budget_<categoryId>`) with confirmation dialogs.
- [x] Deep dive Tab 1 (Mục tiêu tiết kiệm - Savings Goals / Envelopes)
  - Inspected `SavingsGoalsView`, `EnvelopeFormModal`, `EnvelopeDao`, `EnvelopeRepository`, `EnvelopeController`.
  - Analyzed foreign key restrictions (`EnvelopeMovements.sourceEnvelopeId` / `destEnvelopeId` with `KeyAction.restrict`).
  - Designed `deleteSavingsGoal` ensuring any `reservedBalanceVnd > 0` is released back to liquid cash via `EnvelopeDao.release` before archiving.
  - Designed UI controls for Edit (`btn_edit_goal_<id>`) and Delete (`btn_delete_goal_<id>`).
- [x] Deep dive Tab 2 (Nghĩa vụ & Dự báo - Scheduled Items & Ledger Reversal)
  - Inspected `ObligationsForecastView`, `UpcomingObligationsCard`, `_AddScheduledItemModal`, `PlansController.markScheduledItemPaid`, and `LedgerDao.voidTransaction` / `editTransaction`.
  - Traced full atomic reversal flow for completed scheduled items (`PAID_OR_RECEIVED`):
    - Deleting: Atomically void/reverse `paidTransactionId` (offsetting postings, restoring liquid account and envelope reserves), then delete scheduled item.
    - Editing: Atomically void/reverse old transaction, post new transaction with deterministic key (`scheduled_pay_<id>_rev_<timestamp>`), and update scheduled item.
  - Designed unified `_ScheduledItemModal` supporting both Add and Edit with explicit Category picker and in-flight guards.
  - Added Edit (`btn_edit_obligation_<id>`) and Delete (`btn_delete_obligation_<id>`) buttons on pending and completed cards.
- [x] Synthesize findings & test specifications into `handoff.md`
- [x] Update `BRIEFING.md`
- [x] Ready to send handoff message to orchestrator
