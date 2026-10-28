# HANDOFF REPORT: M2 PURE DART DOMAIN ENGINES & DRIFT DAOS

> **Worker**: `worker_m2_1`  
> **Roles**: implementer, qa  
> **Milestone**: M2 (Deterministic Domain Engines & DAOs)  
> **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m2_1`  
> **Timestamp**: 2026-10-27T19:15:00Z  

---

## 1. Observation

### 1.1 Codebase & Schema Context
- **Database Schema**: Directly verified `lib/core/database/app_database.dart` contains tables:
  - `LedgerAccounts`: checks `kind IN ('ASSET_CASH', 'ASSET_BANK', 'LIABILITY_CREDIT_CARD', 'INCOME', 'EXPENSE', 'EQUITY_OPENING')`.
  - `Categories`: links to `LedgerAccounts.id` (`onDelete: KeyAction.restrict`), checks `kind IN ('INCOME', 'EXPENSE')`.
  - `JournalTransactions`: checks `tx_type IN ('OPENING_BALANCE', 'INCOME', 'EXPENSE', 'TRANSFER', 'CREDIT_CARD_PAYMENT', 'REFUND', 'REVERSAL')` and `status IN ('POSTED', 'SUPERSEDED', 'VOIDED')`.
  - `JournalPostings`: table constraint `CONSTRAINT chk_posting_one_sided CHECK ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`.
  - `Envelopes`: checks `policy IN ('PROTECTED', 'FLEXIBLE')`.
  - `EnvelopeMovements`: checks `amount_vnd > 0` and `movement_type IN ('ALLOCATE', 'RELEASE', 'TRANSFER', 'SPEND', 'REFUND_RESTORE', 'REVERSAL')`.
  - `CategoryBudgets`: composite unique index `(category_id, year_month)`.
  - `ScheduledItems`: checks `kind IN ('BILL', 'PLANNED_INCOME')` and `status IN ('PENDING', 'PAID_OR_RECEIVED', 'SKIPPED')`.
  - `Settings`: singleton row `CHECK (id == 1)`.

### 1.2 Implemented Domain Files
We implemented pure Dart domain services with zero Flutter/Drift imports in `lib/domain/`:
1. `lib/domain/ledger/`:
   - `account_kind.dart`: `AccountKind` enum with classification properties (`isLiquid`, `isDebitNormal`, `isCreditNormal`) and `fromDbValue`.
   - `transaction_type.dart`: `TransactionType` enum matching the 7 database types and `fromDbValue`.
   - `transaction_status.dart`: `TransactionStatus` enum (`posted`, `superseded`, `voided`).
   - `posting_leg.dart`: `PostingLeg` immutable value object enforcing single-sidedness, positive amounts, and `invert()`.
   - `posting_matrix.dart`: `PostingMatrix` pure Dart engine enforcing `SUM(debit_vnd) == SUM(credit_vnd)` across all 7 transaction types (9 execution patterns).
   - `ledger_exceptions.dart`: `UnbalancedTransactionException`, `InvalidTransactionException`, `AccountKindMismatchException`.
   - `post_transaction_command.dart`: `PostTransactionCommand` DTOs and factories for all 7 transaction types.
2. `lib/domain/envelopes/`:
   - `envelope_policy.dart`: `EnvelopePolicy` enum (`protected`, `flexible`).
   - `envelope_movement_type.dart`: `EnvelopeMovementType` enum (`allocate`, `release`, `transfer`, `spend`, `refundRestore`, `reversal`).
   - `envelope_exceptions.dart`: `OverAllocationException`, `SpendingDeficitException`, `InvalidEnvelopeOperationException`.
   - `available_to_allocate.dart`: `AvailableToAllocateCalculator` (`total_liquid - total_reserves - minimum_buffer`), with allocation, spending deficit, and transfer guards.
3. `lib/domain/budgeting/`:
   - `category_spending_calculator.dart`: `CategorySpendingCalculator`, `CategorySpendingItem`, `CategorySpendingReport` computing gross, refund credits, net expense, recognized income, net saving, net recovery ("Thu hồi chi phí ròng"), and null savings rate when income <= 0 ₫.
   - `goal_calculator.dart`: `GoalCalculator`, `GoalEvaluationResult` computing integer ceiling division `((T - C) + N - 1) ~/ N`, OVERDUE status on non-positive N, and ACHIEVED on C >= T.
   - `feasibility_advisor.dart`: `FeasibilityAdvisor` implementing plan evaluation and 3 one-tap solutions: Extend Deadline, Lower Target, and Pause Lower-Priority Goals with priority ranking.
   - `category_budget_progress.dart`: `CategoryBudgetTracker`, `CategoryBudgetProgress`, `MonthlyBudgetSummary` tracking spent vs limit, percentages, and warning/exceeded statuses.
4. `lib/domain/forecasting/`:
   - `safe_to_spend_calculator.dart`: `SafeToSpendCalculator` implementing chronological protected envelope coverage of pending bills, zero double-counting, exact negative integer VND on deficit with full breakdown model, and daily allowance integer division.
   - `recurrence_calculator.dart`: `RecurrenceCalculator` implementing drift-free month-end recurrence `min(anchor_day, daysInMonth(Y, M))` with Gregorian leap year support.
   - `cash_flow_forecaster.dart`: `CashFlowForecaster` projecting 30/60/90-day cash flow points with buffer breach indicators.

### 1.3 Implemented Drift DAOs
1. `lib/core/database/daos/ledger_dao.dart`:
   - `postTransaction` and `postTransactionCommand`: enforces balanced postings in atomic SQLite transaction; creates linked SPEND or REFUND_RESTORE movements and updates envelope balances.
   - `voidTransaction`: marks target VOIDED, inserts REVERSAL transaction with inverted postings, and offsets linked envelope movements.
   - `editTransaction`: marks original SUPERSEDED with `replaced_by_tx_id`, inserts reversal transaction, and posts replacement transaction.
   - Dynamic balance queries: `getAccountBalance`, `watchAccountsWithBalances`, `getAccountsWithBalances`, `watchTotalLiquidAssets`, `getTotalLiquidAssets`, `watchNetWorth`, `getNetWorth`. Zero cached balance columns.
   - Clean UI queries: `watchCleanTransactions` and `getCleanTransactions` filtering `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`.
2. `lib/core/database/daos/envelope_dao.dart`:
   - `getAvailableToAllocate`: computes available funds dynamically.
   - `allocate`, `release`, `transfer`: executes virtual fund movements while generating ZERO journal postings.
   - `watchAllEnvelopes`, `getAllEnvelopes`, `getEnvelopeById`, `watchMovementsForEnvelope`, `getMovementsForEnvelope`.
3. Registered DAOs in `lib/core/database/app_database.dart` (`daos: [LedgerDao, EnvelopeDao]`).
   - Ran `build_runner` generating `lib/core/database/app_database.g.dart`, `lib/core/database/daos/ledger_dao.g.dart`, and `lib/core/database/daos/envelope_dao.g.dart`.

### 1.4 Test Suite & Quality Verification Results
- **Unit & Database Tests**:
  - `test/unit/safe_to_spend_test.dart` (7 tests)
  - `test/unit/recurrence_test.dart` (8 tests)
  - `test/unit/goal_ceiling_division_test.dart` (6 tests)
  - `test/unit/feasibility_advisor_test.dart` (4 tests)
  - `test/unit/category_spending_test.dart` (5 tests)
  - `test/unit/ledger_envelope_test.dart` (12 tests)
  - `test/unit/cash_flow_forecaster_test.dart` (3 tests)
  - `test/database/ledger_service_test.dart` (8 tests)
  - `test/database/envelope_service_test.dart` (6 tests)
- **Execution Command**:
  ```text
  flutter test
  00:02 +192: All tests passed!
  ```
  Total: 192 passed, 0 failed.
- **Static Analysis Command**:
  ```text
  flutter analyze
  No issues found! (ran in 7.6s)
  ```
  Exit code 0.
- **Code Formatting Command**:
  ```text
  dart format --output=none --set-exit-if-changed .
  Formatted 39 files (0 changed) in 0.98 seconds.
  ```
  Exit code 0.

---

## 2. Logic Chain

1. **Pure Dart Domain Engine Isolation**:
   - `lib/domain/` has zero dependencies on Flutter widgets, Drift tables, or Riverpod providers.
   - Inputs and outputs are strictly pure Dart primitives and `VndMoney`.
   - This prevents UI logic and database drivers from leaking into business calculations, guaranteeing that financial formulas can be tested independently of platform channels or SQLite runtimes.

2. **Monetary & General Ledger Invariants**:
   - All transactions pass through `PostingMatrix.assertBalanced(postings)`, asserting $\sum \text{debit\_vnd} == \sum \text{credit\_vnd}$ before hitting SQLite.
   - SQLite table constraint `chk_posting_one_sided` guarantees each posting leg is strictly one-sided (`debit > 0 ^ credit > 0`).
   - In Credit Card Payments (`Pattern 6`), Debit is `LIABILITY_CREDIT_CARD` and Credit is `ASSET_CASH/BANK`. It never touches an expense account or creates envelope movements, ensuring settlements are never misconstrued as operating expenses.
   - Account balances are derived dynamically from postings (`Asset/Expense = Debit - Credit`, `Liability/Income/Equity = Credit - Debit`). Zero cached columns prevents synchronization drift during edits or voids.

3. **Virtual Fund Decoupling**:
   - Envelope allocations, releases, and transfers update `envelopes.reserved_balance_vnd` and append records to `envelope_movements`.
   - They generate ZERO general ledger postings and do not modify liquid asset balances or net worth.
   - `AvailableToAllocateCalculator.validateAllocation` blocks over-allocation if `amount > max(0, availableToAllocate)`.

4. **Zero Double-Counting Safe-to-Spend**:
   - Naive subtraction of protected envelope reserves and pending bills causes double deduction.
   - `SafeToSpendCalculator` chronologically assigns protected reserves to linked pending bills first (`covered = min(bill.amount, remaining_reserve)`, `unfunded = bill.amount - covered`).
   - `Safe-to-Spend = Liquid Assets - Protected Reserves - Unfunded Bills - Buffer`.
   - The total deduction for a bill linked to a protected envelope is strictly bounded by $\max(\text{reserve}, \text{bill})$. No double-counting occurs.
   - Insolvency returns exact negative integer VND (never clamped to zero) while daily discretionary allowance is zero.

5. **Drift-Free Recurrence & Ceiling Division**:
   - Recurrence uses `min(anchor_day, daysInMonth(Y, M))`. An item anchored on day 31 evaluated in February (28 days) produces Feb 28; when advancing to March, it schedules on March 31 without anchor degradation.
   - Goal periodic contribution uses integer ceiling division: `((T - C) + N - 1) ~/ N`. This guarantees the target is reached within $N$ periods without a 1 ₫ rounding shortfall.

6. **Audit-Preserving Void & Edit History**:
   - Voids update `status = 'VOIDED'` and create a `REVERSAL` transaction with swapped debit/credit legs and offsetting envelope movements.
   - Edits update `status = 'SUPERSEDED'`, set `replaced_by_tx_id`, and post the new transaction.
   - The UI query `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'` cleanly presents active transactions without cluttering user feeds.

---

## 3. Caveats

1. **SQLite In-Memory vs Disk Persistence**:
   Unit tests and DAO tests were executed against SQLite in-memory databases with `PRAGMA foreign_keys = ON;`. In production on Android, `driftDatabase(name: 'dongtien_db')` writes to private sandboxed app storage. Foreign keys are asserted in `MigrationStrategy.beforeOpen`.
2. **Horizon Date Timezone Resolution**:
   `SafeToSpendCalculator` evaluates bills due on or before `horizonDate` up to 23:59:59.999. In feature presentation screens, date filters should use calendar-day resolution in local time.
3. **No External Chart Dependencies**:
   As required by `AGENTS.md`, no chart packages were imported. The data structures produced by `CategorySpendingCalculator`, `CashFlowForecaster`, and `CategoryBudgetTracker` are ready for downstream presentation widgets (`CustomPainter`, Material 3 progress bars).

---

## 4. Conclusion

Milestone M2 is 100% complete:
1. All pure Dart domain engines for ledger, envelopes, budgeting, and forecasting are implemented, fully tested, and verified.
2. Drift DAOs `LedgerDao` and `EnvelopeDao` are implemented, registered on `AppDatabase`, and verified against all 15 acceptance criteria.
3. Complete test suite with 192 automated tests passes with 100% success rate, static analysis has 0 warnings/errors, and formatting is compliant.
4. Downstream parallel UI feature workers can now consume these domain models and DAOs with complete confidence in mathematical correctness and database invariants.

---

## 5. Verification Method

To independently verify all work:

```bash
# 1. Run full test suite (unit and database tests)
C:\Users\coihu12\flutter\bin\flutter.bat test

# 2. Run static analysis across the entire project
C:\Users\coihu12\flutter\bin\flutter.bat analyze

# 3. Verify format compliance
C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed .

# 4. Check that lib/domain has zero package:flutter or package:drift imports
# Expected: 0 matches
```

Invalidation conditions:
- Any transaction where $\sum \text{debit} \ne \sum \text{credit}$ is accepted.
- Any credit card payment transaction that touches an expense account.
- Any virtual envelope allocation that creates journal postings.
- Safe-to-Spend double-counting a bill covered by a protected envelope.
- Day 31 recurrence degrading to day 28 in March.
- Goal integer division leaving a shortfall at target deadline.
