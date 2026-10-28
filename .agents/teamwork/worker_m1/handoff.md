# HANDOFF REPORT — Milestone M1: Database Bug Fixes & Query Optimization

**Agent**: `worker_m1`  
**Milestone**: M1 (Database Bug Fixes & Query Optimization)  
**Parent Orchestrator**: `e84dfd06-a5ff-437b-948f-883d103ebdc9`  
**Date**: 2026-10-28  

---

## 1. Observation

### 1.1 Invariant Bug in `currentMonthlyBudgetSummaryProvider`
- **File**: `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- **Pre-existing Code (Lines 96–138)**:
  ```dart
  return budgetsQuery.watch().asyncMap((budgets) async {
    for (final b in budgets) {
      final category = await (db.select(db.categories)..where((c) => c.id.equals(b.categoryId))).getSingleOrNull();
      final result = await db.customSelect(
        '... AND t.status = "POSTED"',
        variables: [Variable.withInt(b.categoryId), Variable.withInt(startOfMonthMs), Variable.withInt(endOfMonthMs)],
        readsFrom: {db.journalPostings, db.journalTransactions},
      ).getSingle();
      ...
    }
  });
  ```
- **Observations**:
  1. The raw SQL string literal `"POSTED"` was enclosed in double quotes. In ANSI SQL and SQLite with standard configuration (or `SQLITE_DQS=0`), double quotes denote column identifiers. SQLite aborted with `SqliteException(1): no such column: POSTED`.
  2. The query omitted `AND t.tx_type != 'REVERSAL'`. Reversals were not properly excluded from the spending aggregation.
  3. The implementation executed $1 + 2N$ sequential database queries per emission inside an `asyncMap` loop ($1$ for budgets, plus $1$ category fetch and $1$ spending query for each of $N$ budgets).
  4. Only `budgetsQuery.watch()` was observed, so changes to `journal_postings` or `journal_transactions` did not trigger reactive re-emissions.

### 1.2 Full-Table Scan in `reportsSummaryProvider`
- **File**: `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`
- **Pre-existing Code (Lines 56–91)**:
  ```dart
  final allPostings = await db.select(db.journalPostings).get();
  ```
- **Observations**:
  1. `await db.select(db.journalPostings).get()` loaded every row of `journal_postings` across the entire history of the app into Dart memory.
  2. In-memory loops filtered and aggregated recognized income, internal transfers, and category expenses in Dart heap rather than using SQLite indexing and aggregate operators (`SUM`, `GROUP BY`, `HAVING`).

### 1.3 Verification Tool Execution
- **Commands & Toolchain**:
  - `$env:JAVA_HOME = "C:\Users\coihu12\jdk17"`
  - `$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"`
  - `$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path`
  - `dart format --output=none --set-exit-if-changed .` $\rightarrow$ Exit 0 (0 changed across 109 files).
  - `flutter analyze` $\rightarrow$ Exit 0 ("No issues found! (ran in 1.9s)").
  - `flutter test` $\rightarrow$ Exit 0 ("All tests passed! +275").

---

## 2. Logic Chain

1. **Fixing `SqliteException(1)` & Ledger Isolation**:
   - Replaced `"POSTED"` with standard single-quoted SQL literal `'POSTED'`.
   - Added `AND t.tx_type != 'REVERSAL'` to ensure voided transactions and audit reversals do not skew monthly category spending figures.

2. **Eliminating N+1 Waterfall in `currentMonthlyBudgetSummaryProvider`**:
   - Replaced the $1 + 2N$ loop with a single aggregated SQLite query:
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
   - Configured `readsFrom: {db.categoryBudgets, db.categories, db.journalPostings, db.journalTransactions}` to ensure any insertion or alteration in budgets, categories, or transactions immediately emits the updated `MonthlyBudgetSummary`.
   - Replaced `asyncMap` with synchronous `map` to prevent out-of-order race conditions.

3. **Eliminating Full-Table Scan in `reportsSummaryProvider`**:
   - Replaced `await db.select(db.journalPostings).get()` and Dart nested filtering with 3 bounded SQLite queries bounded by `t.occurred_at >= ? AND t.occurred_at <= ?`:
     - Query 1: Bounded recognized income (`t.tx_type = 'INCOME' AND a.kind = 'INCOME'`).
     - Query 2: Bounded internal transfers (`t.tx_type IN ('TRANSFER', 'CREDIT_CARD_PAYMENT') AND p.debit_vnd > 0`).
     - Query 3: Bounded category spending (`a.kind = 'EXPENSE' AND c.kind = 'EXPENSE' AND c.is_archived = 0 GROUP BY c.id, c.name HAVING gross_expense > 0 OR refund_credits > 0`).
   - All aggregations are computed directly within SQLite engine utilizing existing indexes (`idx_tx_occurred_at`, `idx_postings_tx`, `idx_postings_acc`), avoiding full-table memory allocation.

---

## 3. Caveats

- No caveats. All changes strictly modify only the two assigned provider files (`lib/features/dashboard/presentation/providers/dashboard_providers.dart` and `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`). All domain models and ledger invariants were preserved intact.

---

## 4. Conclusion

- Milestone M1 tasks are 100% complete:
  - `SqliteException(1)` is eliminated.
  - The N+1 query loop in `currentMonthlyBudgetSummaryProvider` is replaced with a single aggregated SQLite `JOIN ... GROUP BY` query.
  - The full-table memory scan in `reportsSummaryProvider` is replaced with 3 bounded, index-optimized SQLite queries.
  - Formatting, static analysis, and all 275 tests pass with zero warnings or errors.

---

## 5. Verification Method

To independently verify the implementation:

1. **Verify Formatting**:
   ```powershell
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
   dart format --output=none --set-exit-if-changed .
   ```
   *Expected*: Code 0, 0 files changed.

2. **Verify Static Analysis**:
   ```powershell
   flutter analyze
   ```
   *Expected*: Code 0, "No issues found!".

3. **Verify Test Suite**:
   ```powershell
   flutter test
   ```
   *Expected*: Code 0, all 275 unit, database, and widget tests pass.

4. **Verify Diff Scoping**:
   ```powershell
   git status --short
   ```
   *Expected*: In `lib/`, only `dashboard_providers.dart` and `reports_settings_providers.dart` are modified.
