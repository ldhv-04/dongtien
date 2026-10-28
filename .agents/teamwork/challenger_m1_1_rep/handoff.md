# Empirical Challenge & Stress-Test Handoff Report: Milestone M1 Database Optimization & Bugfix Review

**Agent**: `challenger_m1_1_rep`  
**Role**: Empirical Challenger (critic, specialist)  
**Date**: 2026-10-28T02:10:00Z  
**Verdict**: **APPROVE**  
**Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_1_rep\`  
**Target Handoff Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_1_rep\handoff.md`  

---

## 1. Observation

### 1.1 Implementation Code Review & Verification
1. **Target File**: `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
   - **Lines 97–124**:
     ```sql
     SELECT 
       b.category_id,
       c.name AS category_name,
       b.year_month,
       b.limit_vnd,
       b.alert_threshold_pct,
       COALESCE(spent.gross_expense, 0) AS gross_expense,
       COALESCE(spent.refund_credits, 0) AS refund_credits
     FROM category_budgets b
     JOIN categories c ON b.category_id = c.id
     LEFT JOIN (
       SELECT 
         p.category_id,
         SUM(p.debit_vnd) AS gross_expense,
         SUM(p.credit_vnd) AS refund_credits
       FROM journal_postings p
       JOIN journal_transactions t ON p.transaction_id = t.id
       WHERE t.occurred_at >= ? 
         AND t.occurred_at < ? 
         AND t.status = 'POSTED' 
         AND t.tx_type != 'REVERSAL'
         AND p.category_id IS NOT NULL
       GROUP BY p.category_id
     ) spent ON b.category_id = spent.category_id
     WHERE b.year_month = ?
     ORDER BY b.category_id ASC;
     ```
   - **Direct Observations**:
     - Single-quoted SQL literals `'POSTED'` and `'REVERSAL'` are used, completely resolving `SqliteException(1): no such column: POSTED`.
     - Reversal transactions (`t.tx_type != 'REVERSAL'`) and superseded/voided transactions (`t.status = 'POSTED'`) are strictly excluded.
     - Replaced the previous $1 + 2N$ iterative query waterfall with a single aggregated SQLite `JOIN ... GROUP BY` query.
     - Correctly configured `readsFrom: {db.categoryBudgets, db.categories, db.journalPostings, db.journalTransactions}` to trigger reactive stream updates whenever any budget or transaction changes.

2. **Target File**: `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`
   - **Lines 52–124**:
     - Query 1: Bounded recognized income query (`t.status = 'POSTED' AND t.tx_type = 'INCOME' AND t.occurred_at >= ? AND t.occurred_at <= ? AND a.kind = 'INCOME'`).
     - Query 2: Bounded internal transfers query (`t.status = 'POSTED' AND t.tx_type IN ('TRANSFER', 'CREDIT_CARD_PAYMENT') AND t.occurred_at >= ? AND t.occurred_at <= ? AND p.debit_vnd > 0`).
     - Query 3: Bounded category spending query (`t.status = 'POSTED' AND t.tx_type != 'REVERSAL' AND t.occurred_at >= ? AND t.occurred_at <= ? AND a.kind = 'EXPENSE' AND c.kind = 'EXPENSE' AND c.is_archived = 0 GROUP BY c.id, c.name HAVING gross_expense > 0 OR refund_credits > 0`).
   - **Direct Observations**:
     - The previous in-memory full-table scan (`await db.select(db.journalPostings).get()`) was completely eliminated.
     - All calculations are delegated to the SQLite engine, bounded by `t.occurred_at >= ? AND t.occurred_at <= ?`.

### 1.2 Empirical Stress-Testing Execution
We executed direct empirical verification and adversarial stress harnesses:

1. **Adversarial Query Optimization & Execution Plan Checks (`test/database/adversarial_query_optimization_test.dart`)**:
   - `EXPLAIN QUERY PLAN` on `currentMonthlyBudgetSummary`: Confirmed SQLite indexes `idx_tx_occurred_at`, `idx_postings_tx`, and `idx_category_budgets_unique` are utilized without full table scans.
   - `EXPLAIN QUERY PLAN` on `reportsSummaryProvider` queries: Confirmed use of `idx_tx_occurred_at` and `idx_postings_tx`.
   - Massive volume stress benchmark: 1,000 transactions and 2,000 postings query executes in single-digit milliseconds.
   - Result: Passed 9/9 tests.

2. **M1 SQL Edge Conditions & Invariants Harness (`test/database/m1_sql_edge_conditions_challenge_test.dart`)**:
   - **Challenge 1**: Zero budgets & zero spending return empty summary without crash.
   - **Challenge 2**: Net recovery edge case where refund credits exceed gross expense (`refundCredits > grossExpense` -> `netExpense = -50.000 ₫`): Spent amount correctly clamps to `0 ₫` in category budget tracker, and reports summary flags `isNetRecovery = true` with `"Thu hồi chi phí ròng"`.
   - **Challenge 3**: Multi-edit chain and voiding isolation: Voided (`status = 'VOIDED'`), superseded (`status = 'SUPERSEDED'`), and reversal (`tx_type = 'REVERSAL'`) transactions are strictly isolated from category spending aggregates.
   - **Challenge 4**: Exact millisecond boundary partitioning: Transactions at `startOfMonthMs - 1` and `startNextMonthMs` are strictly excluded; transactions at `startOfMonthMs` and `endOfMonthMs` are strictly included.
   - **Challenge 5**: Reactive stream multi-table triggers: `currentMonthlyBudgetSummaryProvider` stream immediately re-emits when a budget is inserted, an expense is posted, a refund is posted, or a budget limit is updated.
   - Result: Passed 6/6 tests.

3. **Complete Project Test Suite Execution**:
   - Command: `flutter test`
   - Result: **All 290 tests passed** with 0 failures in 7 seconds.

4. **Static Analysis & Formatting Gates**:
   - `dart format --output=none --set-exit-if-changed .` -> Exit 0 (111 files verified).
   - `flutter analyze` -> Exit 0 ("No issues found!").

---

## 2. Logic Chain

1. **Elimination of `SqliteException(1)`**:
   - *Observation*: Pre-existing code used `AND t.status = "POSTED"`. SQLite standard syntax treats double quotes as column identifiers, causing `no such column: POSTED`.
   - *Fix Verification*: Worker M1 changed `"POSTED"` to `'POSTED'`. Empirically verified across both test harnesses; zero SQLite syntax errors occur.
2. **Double-Entry Ledger Integrity & Reversal Exclusion**:
   - *Observation*: Ledger reversals invert debit/credit legs to preserve audit history. Without `AND t.tx_type != 'REVERSAL'`, reversals would be counted in spending queries.
   - *Fix Verification*: Tested in Challenge 3: after voiding Tx 1 (500k), only Tx 2 (700k) is reflected in spending. The reversal transaction is strictly excluded.
3. **Waterfall Elimination & Index Utilization**:
   - *Observation*: Previous code executed $1 + 2N$ queries inside an `asyncMap` loop, causing noticeable latency on dashboard load.
   - *Fix Verification*: The single `JOIN ... LEFT JOIN ... GROUP BY` query executes in 1 round-trip. `EXPLAIN QUERY PLAN` proves that `idx_tx_occurred_at` and `idx_postings_tx` are used. In the 1,000-transaction benchmark, execution completes in single-digit milliseconds.
4. **Memory Scalability**:
   - *Observation*: Previous code loaded all postings into Dart heap via `db.select(db.journalPostings).get()`. With thousands of transactions, this would cause memory pressure on low-end Android devices.
   - *Fix Verification*: Postings are filtered and aggregated directly in SQLite using `WHERE t.occurred_at >= ? AND t.occurred_at <= ?`. Dart heap receives only the aggregated category rows.
5. **Quality Gate Compliance**:
   - *Observation*: `dart format`, `flutter analyze`, and `flutter test` all exit with code 0 across all 290 tests.

---

## 3. Caveats

- **Riverpod StreamProvider Pre-warming**: In un-pumped headless Dart VM unit tests without an active widget tree (`container.read(reportsSummaryProvider.future)`), stream providers (`settingsStreamProvider`, `recentTransactionsStreamProvider`) should be pre-warmed via `await container.read(...streamProvider.future)` or listened to via `container.listen()` to prevent timeouts. This is standard Riverpod test harness behavior and does not affect production Flutter widget execution where `ref.watch()` automatically manages subscriptions.

---

## 4. Conclusion

**Verdict: APPROVE**

Worker M1's modifications to `lib/features/dashboard/presentation/providers/dashboard_providers.dart` and `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`:
- Completely fix `SqliteException(1)` with standard single-quoted SQL literals.
- Successfully eliminate N+1 query loops and full-table memory scans.
- Strictly adhere to double-entry ledger invariants, audit history preservation, and boundary conditions.
- Pass 100% of the project's 290 automated tests with zero analyzer warnings or formatting issues.

---

## 5. Verification Method

To independently verify the empirical results:

1. **Run full automated test suite**:
   ```powershell
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
   flutter test
   ```
   *Expected outcome*: `All tests passed! (+290)` with exit code 0.

2. **Run adversarial stress test suites individually**:
   ```powershell
   flutter test test/database/adversarial_query_optimization_test.dart
   flutter test test/database/m1_sql_edge_conditions_challenge_test.dart
   ```
   *Expected outcome*: All 15 adversarial tests pass with exit code 0.

3. **Verify static analysis and formatting**:
   ```powershell
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   ```
   *Expected outcome*: 0 formatted files changed, "No issues found!".
