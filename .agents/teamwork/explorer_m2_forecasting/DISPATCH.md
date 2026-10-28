## 2026-10-27T18:51:51Z

You are explorer_m2_forecasting.
Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_forecasting
Read:
- c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md (Sections 6 and 9)
- c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart

Investigate and produce a detailed implementation blueprint for:
1. Safe-to-Spend pure Dart domain engine in `lib/domain/forecasting/safe_to_spend_calculator.dart`:
   - Formula: Safe-to-Spend = Liquid Assets - Protected Reserves - Unfunded Committed Outflows - Minimum Cash Buffer.
   - Zero double-counting chronological algorithm:
     * Allocate protected envelope balances to linked pending bills sorted chronologically by due date.
     * Case A: No linked envelope -> unfunded = bill.amount.
     * Case B: Linked to PROTECTED envelope -> covered = min(bill.amount, remaining_balance), unfunded = bill.amount - covered, remaining_balance -= covered.
     * Case C: Linked to FLEXIBLE envelope -> unfunded = bill.amount.
   - Exact integer VND arithmetic (VndMoney); NEVER clamp to zero; return exact negative amount on deficit with detailed breakdown model.
   - Daily allowance integer division: Safe-to-Spend ~/ max(1, days_remaining) if positive, else 0 ₫/ngày.
2. Drift-free Month-End Recurrence engine in `lib/domain/forecasting/recurrence_calculator.dart`:
   - actual_due_day = min(anchor_day_of_month, daysInMonth(Y, M)).
   - Handles Feb 28/29 leap years, April 30, and restores to 31 in March/May without anchor degradation.
3. Cash Flow Forecast engine in `lib/domain/forecasting/cash_flow_forecaster.dart`:
   - 30/60/90-day cash flow projection: starting balance total_liquid_assets, chronological step evaluation with PLANNED_INCOME and PENDING_BILL.
   - Deficit warning flags when balance falls below minimum cash buffer.
4. Obligation conversion: marking scheduled_item as paid -> inserts real transaction, updates status to PAID_OR_RECEIVED, advances next recurrence.
5. Concrete unit test plan for `test/unit/safe_to_spend_test.dart` and `test/unit/recurrence_test.dart`.

Write your complete report to:
c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_forecasting\handoff.md
Notify orchestrator when done.
