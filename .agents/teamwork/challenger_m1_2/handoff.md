# Handoff Report — Milestone M1 Drift Schema, Invariant & Constraint Stress-Tester

**Agent**: `challenger_m1_2` (Milestone M1 Challenger)  
**Role**: Empirical Challenger (critic, specialist)  
**Handoff Type**: Hard  
**Verdict**: **APPROVE**  
**Date**: 2026-10-27T18:14:00Z  

---

## 1. Observation

### 1.1 Test Suite Executions and Tool Commands

1. **Existing Baseline Test Suite**:
   Command:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/database/app_database_test.dart
   ```
   Output:
   ```text
   00:00 +0: loading C:/Users/coihu12/Documents/App/test/database/app_database_test.dart
   00:00 +0: 1. Drift Fresh Database Initialization & Vietnamese Seeding fresh database creates all 9 tables
   00:00 +1: 1. Drift Fresh Database Initialization & Vietnamese Seeding 3 system accounts are seeded with correct attributes
   00:00 +2: 1. Drift Fresh Database Initialization & Vietnamese Seeding 8 default Vietnamese categories are seeded with correct icons, colors, and FKs
   00:00 +3: 1. Drift Fresh Database Initialization & Vietnamese Seeding singleton settings row is initialized with id = 1 and default values
   00:00 +4: 1. Drift Fresh Database Initialization & Vietnamese Seeding initial state has strictly 0 transactions and 0 ₫ balances
   00:00 +5: 2. Foreign Key Enforcement (PRAGMA foreign_keys = ON;) inserting category with non-existent ledger_account_id throws SqliteException
   00:00 +6: 2. Foreign Key Enforcement (PRAGMA foreign_keys = ON;) inserting journal posting with non-existent transaction_id throws SqliteException
   00:00 +7: 2. Foreign Key Enforcement (PRAGMA foreign_keys = ON;) inserting journal posting with non-existent account_id throws SqliteException
   00:00 +8: 3. Journal Postings Constraints & Balanced Double-Entry Postings inserting posting with debit > 0 AND credit > 0 throws SqliteException (CHECK constraint)
   00:00 +9: 3. Journal Postings Constraints & Balanced Double-Entry Postings inserting posting with debit == 0 AND credit == 0 throws SqliteException (CHECK constraint)
   00:00 +10: 3. Journal Postings Constraints & Balanced Double-Entry Postings balanced transaction insertion and dynamic account balance derivation succeeds
   00:00 +11: 4. Unique Constraints & Relational Integrity idempotency_key rejects duplicate non-null submissions
   00:00 +12: 4. Unique Constraints & Relational Integrity multiple null idempotency_key transactions are permitted
   00:00 +13: 4. Unique Constraints & Relational Integrity composite unique (category_id, year_month) on category_budgets is enforced
   00:00 +14: All tests passed!
   ```

2. **Adversarial Stress Test Suite Implementation**:
   File: `test/database/adversarial_schema_test.dart` (44 comprehensive stress tests partitioned across 7 adversarial domains).
   Command:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/database/adversarial_schema_test.dart
   ```
   Output:
   ```text
   00:00 +0: loading C:/Users/coihu12/Documents/App/test/database/adversarial_schema_test.dart
   00:00 +0: Group 1: Foreign Key Enforcement & Violations inserting posting with invalid account_id throws SqliteException
   00:00 +1: Group 1: Foreign Key Enforcement & Violations inserting posting with invalid transaction_id throws SqliteException
   00:00 +2: Group 1: Foreign Key Enforcement & Violations inserting posting with invalid category_id throws SqliteException
   00:00 +3: Group 1: Foreign Key Enforcement & Violations inserting posting with invalid envelope_id throws SqliteException
   00:00 +4: Group 1: Foreign Key Enforcement & Violations inserting category with invalid ledger_account_id throws SqliteException
   00:00 +5: Group 1: Foreign Key Enforcement & Violations inserting category_budgets with invalid category_id throws SqliteException
   00:00 +6: Group 1: Foreign Key Enforcement & Violations inserting envelope_movements with invalid source_envelope_id throws SqliteException
   00:00 +7: Group 1: Foreign Key Enforcement & Violations inserting envelope_movements with invalid dest_envelope_id throws SqliteException
   00:00 +8: Group 1: Foreign Key Enforcement & Violations inserting envelope_movements with invalid linked_transaction_id throws SqliteException
   00:00 +9: Group 1: Foreign Key Enforcement & Violations inserting scheduled_items with invalid category_id or linked_envelope_id throws SqliteException
   00:00 +10: Group 1: Foreign Key Enforcement & Violations inserting journal_transactions with invalid reverses_tx_id throws SqliteException
   00:00 +11: Group 1: Foreign Key Enforcement & Violations inserting journal_transactions with invalid replaced_by_tx_id throws SqliteException
   00:00 +12: Group 2: Journal Postings CHECK Constraints inserting posting with debit > 0 AND credit > 0 throws SqliteException
   00:00 +13: Group 2: Journal Postings CHECK Constraints inserting posting with debit == 0 AND credit == 0 throws SqliteException
   00:00 +14: Group 2: Journal Postings CHECK Constraints inserting posting with negative debit throws SqliteException
   00:00 +15: Group 2: Journal Postings CHECK Constraints inserting posting with negative credit throws SqliteException
   00:00 +16: Group 2: Journal Postings CHECK Constraints valid one-sided debit posting succeeds
   00:00 +17: Group 2: Journal Postings CHECK Constraints valid one-sided credit posting succeeds
   00:00 +18: Group 3: Unique Constraints duplicate (category_id, year_month) in category_budgets throws SqliteException
   00:00 +19: Group 3: Unique Constraints different year_month for same category is permitted in category_budgets
   00:00 +20: Group 3: Unique Constraints different category for same year_month is permitted in category_budgets
   00:00 +21: Group 3: Unique Constraints duplicate non-null idempotency_key throws SqliteException
   00:00 +22: Group 3: Unique Constraints multiple null idempotency_key transactions are permitted
   00:00 +23: Group 4: Settings Table Singleton & Bounds Constraints inserting second row with id = 2 into settings throws SqliteException
   00:00 +24: Group 4: Settings Table Singleton & Bounds Constraints inserting duplicate row with id = 1 into settings throws SqliteException
   00:00 +25: Group 4: Settings Table Singleton & Bounds Constraints updating settings with invalid minimum_cash_buffer_vnd < 0 throws SqliteException
   00:00 +26: Group 4: Settings Table Singleton & Bounds Constraints updating settings with period_start_day outside 1..31 throws SqliteException
   00:00 +27: Group 4: Settings Table Singleton & Bounds Constraints updating settings with daily_reminder_hour outside 0..23 throws SqliteException
   00:00 +28: Group 4: Settings Table Singleton & Bounds Constraints updating settings with daily_reminder_minute outside 0..59 throws SqliteException
   00:00 +29: Group 5: Seeding Immutability & Zero Balances EQUITY_OPENING and default system accounts have strictly 0 ₫ derived balance
   00:00 +30: Group 5: Seeding Immutability & Zero Balances all 8 default Vietnamese categories have strictly 0 ₫ spending and 0 transactions
   00:00 +31: Group 5: Seeding Immutability & Zero Balances clean initial state contains zero records in operational tables
   00:00 +32: Group 6: Table Enum & Value CHECK Constraints Stress-Testing ledger_accounts rejects invalid kind
   00:00 +33: Group 6: Table Enum & Value CHECK Constraints Stress-Testing categories rejects invalid kind
   00:00 +34: Group 6: Table Enum & Value CHECK Constraints Stress-Testing journal_transactions rejects invalid tx_type and status
   00:00 +35: Group 6: Table Enum & Value CHECK Constraints Stress-Testing envelopes rejects invalid policy
   00:00 +36: Group 6: Table Enum & Value CHECK Constraints Stress-Testing envelope_movements rejects amount_vnd <= 0
   00:00 +37: Group 6: Table Enum & Value CHECK Constraints Stress-Testing envelope_movements rejects invalid movement_type
   00:00 +38: Group 6: Table Enum & Value CHECK Constraints Stress-Testing category_budgets rejects limit_vnd <= 0 and alert_threshold outside 1..100
   00:00 +39: Group 6: Table Enum & Value CHECK Constraints Stress-Testing scheduled_items rejects invalid amount_vnd, anchor_day, and enums
   00:00 +40: Group 7: Referential Actions & Cascades deleting journal transaction cascades and deletes postings
   00:00 +41: Group 7: Referential Actions & Cascades deleting ledger account referenced by posting throws SqliteException (RESTRICT)
   00:00 +42: Group 7: Referential Actions & Cascades deleting category referenced by posting sets category_id to NULL (SET NULL)
   00:00 +43: Group 7: Referential Actions & Cascades deleting category cascades and deletes associated category_budgets
   00:00 +44: All tests passed!
   ```

3. **Combined Database Test Execution**:
   Command:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/database/
   ```
   Result: **58/58 tests passed** with zero failures.

4. **Static Analysis & Format Verification**:
   Command:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" analyze test/database/adversarial_schema_test.dart
   ```
   Output: `No issues found! (ran in 10.9s)`
   Command:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe" format --output=none --set-exit-if-changed test/database/adversarial_schema_test.dart
   ```
   Output: `Formatted 1 file (0 changed) in 0.30 seconds.` (Exit code 0).

---

## 2. Logic Chain

1. **Foreign Key Enforcement**:
   - In `lib/core/database/app_database.dart` (lines 269–272), `MigrationStrategy.beforeOpen` executes `PRAGMA foreign_keys = ON;`.
   - Empirically observed: When attempting to insert invalid foreign keys into `journal_postings.account_id`, `journal_postings.transaction_id`, `journal_postings.category_id`, `journal_postings.envelope_id`, `categories.ledger_account_id`, `category_budgets.category_id`, `envelope_movements.source_envelope_id`, `envelope_movements.dest_envelope_id`, `envelope_movements.linked_transaction_id`, `scheduled_items.category_id`, `scheduled_items.linked_envelope_id`, `journal_transactions.reverses_tx_id`, or `journal_transactions.replaced_by_tx_id`, SQLite raises `SqliteException: FOREIGN KEY constraint failed` in 100% of cases.

2. **Journal Postings CHECK Constraint**:
   - In `lib/core/database/app_database.dart` (lines 96–98), `JournalPostings.customConstraints` defines:
     `CONSTRAINT chk_posting_one_sided CHECK ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`
   - Empirically observed: Postings with `debit_vnd > 0 AND credit_vnd > 0`, `debit_vnd == 0 AND credit_vnd == 0`, negative debit values, or negative credit values immediately fail with `SqliteException: CHECK constraint failed`. Valid one-sided debit or credit postings succeed.

3. **Unique Constraints**:
   - In `lib/core/database/app_database.dart` (lines 162–166), `@TableIndex(name: 'idx_category_budgets_unique', columns: {#categoryId, #yearMonth}, unique: true)` guards `CategoryBudgets`.
   - In lines 56, `idempotencyKey => text().nullable().unique()()` guards `JournalTransactions`.
   - Empirically observed: Attempting to insert duplicate `(categoryId, yearMonth)` or duplicate non-null `idempotencyKey` triggers `SqliteException: UNIQUE constraint failed`. Multiple null `idempotencyKey` values are properly accepted without collision.

4. **Settings Singleton & Bounds Constraints**:
   - In `lib/core/database/app_database.dart` (lines 235–246), `Settings` defines primary key `{id}` and custom constraints `CHECK (id == 1)`, `CHECK (minimum_cash_buffer_vnd >= 0)`, `CHECK (period_start_day >= 1 AND period_start_day <= 31)`, `CHECK (daily_reminder_hour >= 0 AND daily_reminder_hour <= 23)`, `CHECK (daily_reminder_minute >= 0 AND daily_reminder_minute <= 59)`.
   - Empirically observed: Inserting a second row (`id = 2`) triggers `SqliteException: CHECK constraint failed: id == 1`. Inserting a duplicate (`id = 1`) triggers `SqliteException: UNIQUE constraint failed: settings.id`. Updating any configuration value out of valid bounds throws `SqliteException: CHECK constraint failed`.

5. **Seeding Immutability & Zero Balances**:
   - In `lib/core/database/app_database.dart` (lines 284–420), `seedInitialData` seeds exactly 3 system accounts (`EQUITY_OPENING` id 1, `INCOME` id 2, `EXPENSE` id 3), 8 default Vietnamese categories, and 1 settings record.
   - Empirically observed: Initial queries against `journal_transactions`, `journal_postings`, `envelopes`, `envelope_movements`, `category_budgets`, and `scheduled_items` return 0 rows. Derived balances for all 3 system accounts and all 8 categories across all postings evaluate strictly to `0 ₫`.

6. **Referential Actions Integrity**:
   - `onDelete: KeyAction.cascade` on `JournalPostings.transactionId` correctly cascades deletion of postings when their transaction is deleted.
   - `onDelete: KeyAction.restrict` on `JournalPostings.accountId` correctly aborts deletion of accounts with postings.
   - `onDelete: KeyAction.setNull` on `JournalPostings.categoryId` correctly nullifies foreign key pointers upon category removal.
   - `onDelete: KeyAction.cascade` on `CategoryBudgets.categoryId` correctly cleans up budget rows upon category removal.

---

## 3. Caveats

No caveats. All schema constraints, relational foreign keys, CHECK constraints, unique constraints, and seed invariants specified in `build_spec/dongtien_build_spec.md`, `AGENTS.md`, and `docs/ARCHITECTURE_AND_RULES.md` were directly executed and empirically verified.

---

## 4. Conclusion

**Verdict: APPROVE**

The Milestone M1 Drift database schema (`lib/core/database/app_database.dart`, `app_database.g.dart`) complies 100% with all architectural invariants and SQLite relational constraints. All 44 adversarial stress tests and 14 original database tests pass cleanly without errors, warnings, or formatting lints. The database layer is verified ready for Milestone M2 pure domain engines.

---

## 5. Verification Method

To independently verify the empirical stress tests:

1. **Run all database tests**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/database/
   ```
   *Expected outcome*: 58 tests pass with exit code 0.

2. **Run adversarial stress test suite individually**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" test test/database/adversarial_schema_test.dart
   ```
   *Expected outcome*: 44 tests pass with exit code 0.

3. **Verify static analysis and formatting**:
   ```powershell
   & "C:\Users\coihu12\flutter\bin\flutter.bat" analyze test/database/adversarial_schema_test.dart
   & "C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe" format --output=none --set-exit-if-changed test/database/adversarial_schema_test.dart
   ```
   *Expected outcome*: Zero analysis issues, 0 formatting changes.

4. **Invalidation condition**: Any modification to `lib/core/database/app_database.dart` that disables `PRAGMA foreign_keys = ON;`, removes `chk_posting_one_sided`, alters `CHECK (id == 1)` on settings, relaxes composite unique constraints on budgets, or seeds non-zero initial postings would cause immediate test failures.
