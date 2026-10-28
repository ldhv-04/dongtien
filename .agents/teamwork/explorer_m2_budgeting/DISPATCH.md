## 2026-10-27T18:51:51Z
You are explorer_m2_budgeting.
Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_budgeting
Read:
- c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md (Sections 7 and 8)
- c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart

Investigate and produce a detailed implementation blueprint for:
1. Category Spending & Savings Rate engine in `lib/domain/budgeting/category_spending_calculator.dart`:
   - gross_expense, refund_credits, net_expense = gross_expense - refund_credits, recognized_income, net_saving = recognized_income - net_expense.
   - Net Recovery handling: if net_expense < 0, label as "Thu hồi chi phí ròng", and use effective_expense = max(0, net_expense).
   - Savings rate: if income <= 0, return null (UI renders "Chưa có thu nhập", never NaN/Infinity/0%); if income > 0, return (income - max(0, net_expense)) / income.
2. Savings Goal Ceiling Division engine in `lib/domain/budgeting/goal_calculator.dart`:
   - Target T, current reserved C, remaining periods N.
   - If C >= T: ACHIEVED, required = 0.
   - If N <= 0 and C < T: OVERDUE, shortfall = T - C.
   - If N > 0 and C < T: required per period = ((T - C) + N - 1) ~/ N (ceiling integer division).
3. Feasibility Advisor engine in `lib/domain/budgeting/feasibility_advisor.dart`:
   - Flags INFEASIBLE if sum of required per period > available capacity (or average monthly net saving).
   - 3 one-tap calculators:
     * Extend Deadline: N' = ceil((T - C) / monthly_capacity)
     * Lower Target: T' = C + N * monthly_capacity
     * Pause Goals: prioritize goals by rank, fund highest first, recommend pausing remainder.
4. Category Budgets: monthly budget progress tracking (spent vs limit, percentage, status).
5. Concrete unit test plan for `test/unit/category_spending_test.dart`, `test/unit/goal_ceiling_division_test.dart`, and `test/unit/feasibility_advisor_test.dart`.

Write your complete report to:
c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_budgeting\handoff.md
Notify orchestrator when done.
