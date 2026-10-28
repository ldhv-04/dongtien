# Dispatch to explorer_survey_1

## Mission
Survey codebase for Requirement R1: Single-Payment Bills & Planned Income + Anti-Double-Tap UX.

## Inputs
- Authoritative request: `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (specifically ## 2026-10-28T00:39:16Z § R1)
- Project rules: `c:\Users\coihu12\Documents\App\AGENTS.md`
- Target code areas:
  - `lib/features/plans/` (Obligations tab, `_AddScheduledItemModal`, `PlansController`, scheduled items presentation & state)
  - `lib/features/dashboard/` (Upcoming Obligations card, "Đã trả" / "Đã nhận" actions)
  - `lib/domain/` & `lib/core/database/` (Scheduled items table, recurrence types, `markScheduledItemPaid`, idempotency key `scheduled_pay_<id>`)
  - All submission modals (`_AddScheduledItemModal`, `_SetBudgetModal`, `QuickAddModal`, envelope modals) & `CustomKeypad` for `_isSubmitting` / in-flight tap guards.

## Deliverables
Write your comprehensive investigation report to:
`c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_1\report.md`
and write your `handoff.md`.
Identify all affected files, line numbers, current behavior vs required behavior, and exact implementation recommendations.


## 2026-10-28T00:43:46Z
You are explorer_survey_1.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_1\
Read your dispatch instructions in: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_1\DISPATCH.md
Read the authoritative user request in: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md (under ## 2026-10-28T00:39:16Z § R1)
Read the system invariants in: c:\Users\coihu12\Documents\App\AGENTS.md

Your task is to thoroughly survey and investigate the codebase for Requirement R1:
1. Converting bills and planned income to single-payment one-off items (recurrence = 'NONE').
   - Check Add Scheduled Item modal in lib/features/plans/ (remove recurrence selector chips, date picker for due date).
   - Check ScheduledItems table, recurrence enum/types in domain and database.
2. Confirmation dialogs on "Đã trả" / "Đã nhận" (in Plans -> Obligations and Dashboard Upcoming card).
3. "Lịch sử đã thanh toán / Đã nhận" section on Obligations view with permanently disabled "Đã hoàn tất" button.
4. Deterministic idempotencyKey ('scheduled_pay_<id>') in markScheduledItemPaid.
5. In-flight tap guards (_isSubmitting) across all submission modals (_AddScheduledItemModal, _SetBudgetModal, QuickAddModal, envelope modals) and CustomKeypad Done actions.

Write your findings to: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_1\report.md
Write your handoff to: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_1\handoff.md
Send a completion message back to orchestrator_2 when finished.
