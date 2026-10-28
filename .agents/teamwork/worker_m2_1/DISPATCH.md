## 2026-10-27T18:59:25Z
You are worker_m2_1.
Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m2_1

Read:
- c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_ledger\handoff.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_forecasting\handoff.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_budgeting\handoff.md
- c:\Users\coihu12\Documents\App\lib\core\database\app_database.dart
- c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Write ownership:
You exclusively own:
- `lib/domain/ledger/`
- `lib/domain/envelopes/`
- `lib/domain/budgeting/`
- `lib/domain/forecasting/`
- `lib/core/database/daos/`
- `lib/core/database/app_database.dart` (registering DAOs)
- `test/unit/`
- `test/database/`

Your tasks:
1. Implement pure Dart ledger domain in `lib/domain/ledger/`:
   - `account_kind.dart`, `transaction_type.dart`, `transaction_status.dart`, `posting_leg.dart`, `posting_matrix.dart`, `ledger_exceptions.dart`, `post_transaction_command.dart`.
   - Implement the 7 transaction types (9 execution patterns) asserting `SUM(debit_vnd) == SUM(credit_vnd)`.
   - Implement audit-preserving void/reversal and edit state transitions.
2. Implement pure Dart envelope domain in `lib/domain/envelopes/`:
   - `envelope_policy.dart`, `envelope_movement_type.dart`, `envelope_exceptions.dart`, `available_to_allocate.dart`.
   - Invariants: `amount_vnd <= max(0, available_to_allocate)` on ALLOCATE; spending deficit guard (`allow_negative_exception`).
3. Implement pure Dart budgeting domain in `lib/domain/budgeting/`:
   - `category_spending_calculator.dart` (gross, refund credits, net expense, recognized income, net saving, net recovery "Thu hồi chi phí ròng", null savings rate on non-positive income).
   - `goal_calculator.dart` (ceiling integer division `((T - C) + N - 1) ~/ N`, OVERDUE shortfall on non-positive N, ACHIEVED on C >= T).
   - `feasibility_advisor.dart` (Extend Deadline, Lower Target, Pause Goals with priority ranking).
   - `category_budget_progress.dart` (spent vs limit, percentage, status).
4. Implement pure Dart forecasting domain in `lib/domain/forecasting/`:
   - `safe_to_spend_calculator.dart` (chronological envelope allocation to pending bills, zero double-counting, exact negative integer VND on deficit with breakdown model, daily allowance integer division).
   - `recurrence_calculator.dart` (drift-free month-end recurrence `min(anchor_day, daysInMonth(Y, M))`).
   - `cash_flow_forecaster.dart` (30/60/90-day cash flow projection, warning indicators on buffer breach).
5. Implement Drift DAOs in `lib/core/database/daos/`:
   - `ledger_dao.dart`: `postTransaction`, `voidTransaction`, `editTransaction`, dynamic account balance derivation (Asset/Expense = Debit - Credit; Liability/Income/Equity = Credit - Debit), total liquid assets, net worth, and clean UI query filter (`WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`).
   - `envelope_dao.dart`: allocate, release, transfer, spend linkage, refund restore, reversal.
   - Register DAOs on `AppDatabase` in `lib/core/database/app_database.dart` and run `flutter pub run build_runner build --delete-conflicting-outputs` if needed.
6. Implement comprehensive tests:
   - `test/unit/safe_to_spend_test.dart`
   - `test/unit/recurrence_test.dart`
   - `test/unit/goal_ceiling_division_test.dart`
   - `test/unit/feasibility_advisor_test.dart`
   - `test/unit/category_spending_test.dart`
   - `test/database/ledger_service_test.dart`
   - `test/database/envelope_service_test.dart`
7. Execute verification:
   - `flutter test`
   - `flutter analyze`
   - `dart format --output=none --set-exit-if-changed .`
8. Write comprehensive handoff report to `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m2_1\handoff.md` and send completion message.
