# Handoff Report — Milestone M1: Core Foundation & Drift Database Schema

**Agent**: `worker_m1_1`  
**Role**: Core Foundation & Drift Database Engineer  
**Milestone**: M1 (Scaffold & Drift Database Schema)  
**Date**: 2026-10-28T01:08:00Z  
**Target Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1_1\handoff.md`  

---

## 1. Observation

### 1.1 Toolchain & Environment Provisioning
1. **Initial PATH State**:
   Executing `flutter --version` and `dart --version` initially returned `CommandNotFoundException` (not recognized in default system PATH).
2. **Provisioning Actions**:
   - `Google.DartSDK` (v3.13.7) was provisioned via `winget install Google.DartSDK --silent`.
   - `Git.MinGit` (v2.56.0.4) was provisioned via `winget install Git.MinGit --silent`.
   - `Flutter SDK` (v3.24.5-stable, Dart 3.5.4) was downloaded from Google storage (`flutter_windows_3.24.5-stable.zip`, 1,033,788,155 bytes) and extracted to `C:\Users\coihu12\flutter` via native Windows `tar -xf`.
   - Both `C:\Users\coihu12\flutter\bin` and `C:\Users\coihu12\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd` were appended to the persistent User PATH registry variable.
   - Analytics and telemetry were completely disabled:
     ```text
     flutter --disable-analytics
     dart --disable-analytics
     Output: Analytics reporting disabled.
     ```

### 1.2 Dependencies & Whitelist Verification (`pubspec.yaml`)
Target file: `c:\Users\coihu12\Documents\App\pubspec.yaml`
1. Locked dependency whitelist contains exclusively approved runtime packages:
   `flutter_riverpod: ^2.5.1`, `drift: ^2.20.0`, `drift_flutter: 0.2.0`, `sqlite3_flutter_libs: ^0.5.24`, `path_provider: ^2.1.4`, `path: ^1.9.0`, `flutter_local_notifications: ^17.2.3`, `timezone: ^0.9.4`, `flutter_timezone: ^3.0.1`, `intl: ^0.19.0`, `share_plus: ^10.0.0`, `file_picker: ^8.1.0`, `cryptography: ^2.7.0`.
2. Dev dependencies:
   `flutter_test`, `integration_test`, `flutter_lints: ^4.0.0`, `build_runner: ^2.4.12`, `drift_dev: ^2.20.0`.
3. Forbidden packages audit:
   Searching `pubspec.yaml` confirms zero forbidden packages (`uuid`, `fl_chart`, `go_router`, `freezed`, `dio`/`http`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`).
4. Running `flutter pub get` exited with code 0 (`Changed 122 dependencies!`).

### 1.3 Static Analysis Rules (`analysis_options.yaml`)
Target file: `c:\Users\coihu12\Documents\App\analysis_options.yaml`
Configured with `include: package:flutter_lints/flutter.yaml`, `exclude: ["**/*.g.dart"]`, `strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`, and clean linter rules.

### 1.4 Core Monetary Engine (`lib/core/money/`)
Target files:
- `c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart`
- `c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart`

Implemented:
- `VndMoney`: 64-bit signed integer (`amount: int`), zero fractional decimals, whole VND.
- Overflow guard: `maxSafeVnd = 9_000_000_000_000_000` (9 quadrillion VND), `minSafeVnd = -9_000_000_000_000_000`. Boundary violations throw `VndOverflowException`.
- Constructors: `VndMoney(int amount)`, `VndMoney.positive(int amount)`, `VndMoney.nonNegative(int amount)`.
- Operators: `+`, `-`, `*`, `~/`, unary `-`, `<`, `<=`, `>`, `>=`, `==`, `hashCode`, `compareTo`.
- `VndFormatter`: Dot grouping thousands separator, space + `₫` suffix (e.g. `1.250.000 ₫`, `0 ₫`, `-500.000 ₫`, `+20.000.000 ₫`). Typography helper `FontFeature.tabularFigures()`. Robust integer parser handling dots, spaces, and non-breaking spaces.

### 1.5 Drift Database Schema & Seeding (`lib/core/database/`)
Target files:
- `c:\Users\coihu12\Documents\App\lib\core\database\app_database.dart`
- `c:\Users\coihu12\Documents\App\lib\core\database\app_database.g.dart`

Implemented:
1. All 9 Drift tables:
   - `LedgerAccounts`: `id`, `name`, `kind`, `isLiquid`, `creditLimit`, `isArchived`, `createdAt`. CHECK on `kind`.
   - `Categories`: `id`, `name`, `kind`, `ledgerAccountId` (FK -> `ledger_accounts.id` RESTRICT), `iconCode`, `colorHex`, `isDefault`, `isArchived`. CHECK on `kind`.
   - `JournalTransactions`: `id`, `txType`, `status`, `description`, `occurredAt`, `createdAt`, `idempotencyKey` (unique nullable), `reversesTxId` (FK SET NULL), `replacedByTxId` (FK SET NULL). CHECK on `txType`, `status`. Indexes on `(status, tx_type)` and `occurred_at`.
   - `JournalPostings`: `id`, `transactionId` (FK CASCADE), `accountId` (FK RESTRICT), `debitVnd`, `creditVnd`, `categoryId` (FK SET NULL), `envelopeId` (FK SET NULL). CHECK `(debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0)`.
   - `Envelopes`: `id`, `name`, `policy`, `reservedBalanceVnd`, `allowNegativeException`, `targetAmountVnd`, `targetDateMs`, `periodLimitVnd`, `rolloverEnabled`, `priority`, `isArchived`. CHECK on `policy`.
   - `EnvelopeMovements`: `id`, `movementType`, `amountVnd`, `sourceEnvelopeId` (FK RESTRICT), `destEnvelopeId` (FK RESTRICT), `linkedTransactionId` (FK SET NULL), `linkedObligationId` (FK SET NULL), `occurredAt`. CHECK `amount_vnd > 0`.
   - `CategoryBudgets`: `id`, `categoryId` (FK CASCADE), `yearMonth`, `limitVnd`, `alertThresholdPct`. UNIQUE index on `(category_id, year_month)`. CHECK `limit_vnd > 0`, `alert_threshold_pct` 1..100.
   - `ScheduledItems`: `id`, `kind`, `title`, `amountVnd`, `dueDateMs`, `recurrence`, `anchorDayOfMonth`, `categoryId` (FK SET NULL), `linkedEnvelopeId` (FK SET NULL), `status`, `paidTransactionId` (FK SET NULL), `reminderDaysBefore`. CHECK `amount_vnd > 0`, `anchor_day_of_month` 1..31 or NULL, `reminder_days_before >= 0`.
   - `Settings`: `id` (PK), `minimumCashBufferVnd`, `periodStartDay`, `dailyReminderHour`, `dailyReminderMinute`, `notificationsEnabled`, `schemaVersion`. CHECK `id == 1`.
2. `MigrationStrategy.beforeOpen`: `await customStatement('PRAGMA foreign_keys = ON;');`.
3. `MigrationStrategy.onCreate`: Seeds 3 system accounts (`id = 1: Vốn ban đầu (EQUITY_OPENING)`, `id = 2: Thu nhập (INCOME)`, `id = 3: Chi tiêu (EXPENSE)`), 8 default Vietnamese categories (Lương, Thưởng, Ăn uống, Di chuyển, Hoá đơn & Tiện ích, Nhà cửa, Mua sắm, Y tế), and singleton `Settings` row (`id = 1`). Postings and transactions are strictly 0 records (0 ₫ initial balances, zero fake transactions).
4. Code Generation: Executing `dart run build_runner build --delete-conflicting-outputs` generated `app_database.g.dart` (858 outputs, 1714 actions, 0 warnings).

### 1.6 Verification Execution Results
1. **Dart Formatting Check**:
   ```powershell
   dart format --output=none --set-exit-if-changed .
   ```
   *Output*: `Formatted 6 files (0 changed) in 0.76 seconds.`  
   *Exit code*: `0` (Zero unformatted lines).

2. **Static Analysis**:
   ```powershell
   flutter analyze
   ```
   *Output*: `No issues found! (ran in 10.8s)`  
   *Exit code*: `0` (Zero errors, zero warnings, zero lints).

3. **Automated Test Suite with Coverage**:
   ```powershell
   flutter test --coverage
   ```
   *Output*:
   ```text
   00:01 +44: All tests passed!
   ```
   *Exit code*: `0`. All 44 tests passed (30 unit tests in `vnd_money_test.dart` + 14 database tests in `app_database_test.dart`). `coverage/lcov.info` generated (42,651 bytes).

4. **Independent Python / SQLite Invariant Probes**:
   - `spec_miner_m1_2/test_m1_drift_schema_probe.py`: Exited with code 0 (`ALL DRIFT SCHEMA & RELATIONAL INVARIANT PROBES PASSED 100%!`).
   - `explorer_m1_3/test_sqlite_simulation.py`: Exited with code 0 (`ALL SQLITE IN-MEMORY INVARIANTS AND TEST SCENARIOS VERIFIED 100% SUCCESSFULLY!`).

---

## 2. Logic Chain

1. **Dependency Integrity (Observation 1.2)**:
   - *Requirement*: Section 3 of `dongtien_build_spec.md` and Section 4 of `AGENTS.md` strictly forbid 8 packages (`uuid`, `fl_chart`, `go_router`, `freezed`, `dio`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`) and define a locked whitelist.
   - *Implementation*: `pubspec.yaml` was authored with only the whitelisted dependencies. `drift_flutter` was pinned to `0.2.0` to match `drift: 2.23.1` (resolved by Flutter 3.24.5's analyzer 6.7.0), resolving symbol compatibility while preserving exact functionality.
   - *Result*: `flutter pub get` completed cleanly without dependency conflicts.

2. **Monetary Precision & Overflow Safety (Observation 1.4)**:
   - *Requirement*: 64-bit integer whole VND, zero floats, overflow guard at `±9_000_000_000_000_000 ₫`, dot grouping, and `FontFeature.tabularFigures()`.
   - *Implementation*: `VndMoney` wraps `int amount` with range checks `[-maxSafeVnd, maxSafeVnd]`. All operators check for overflow before returning instances. `VndFormatter` formats with regex dot-separators and provides `withTabularFigures(TextStyle)`.
   - *Result*: Verified by 30 unit tests testing arithmetic, negative balances, overflow boundaries, zero behavior, formatting, and string parsing.

3. **Relational Invariants & Accounting Truth (Observation 1.5)**:
   - *Requirement*: Double-entry ledger with 9 tables, FK enforcement on open, single-sided posting check, single-row settings check (`id == 1`), unique category budget index, and drift-free anchor day recurrence (1..31).
   - *Implementation*: All 9 tables define SQLite DDL constraints via `customConstraints`. `PRAGMA foreign_keys = ON;` is executed in `MigrationStrategy.beforeOpen`.
   - *Result*: Tested against SQLite 3.50.4 in-memory native database. Orphan inserts to categories and postings are blocked by RESTRICT and CASCADE policies; two-sided or zero postings fail the check constraint; duplicate budgets fail the unique index; settings row with `id != 1` or duplicate inserts are blocked.

4. **Initial Zero Balances & Vietnamese Seeding (Observation 1.5)**:
   - *Requirement*: 3 system accounts, 8 default Vietnamese categories with design-token icons and hex colors, settings id=1, and strictly 0 ₫ initial balances with zero fake transactions.
   - *Implementation*: `seedInitialData(AppDatabase db)` executes inside `MigrationStrategy.onCreate`, inserting the 3 accounts and 8 categories without inserting any journal transactions or postings. Account balances are dynamically derived via SQL aggregate queries ($\sum \text{debit} - \sum \text{credit}$).
   - *Result*: Fresh database tests confirm all 3 accounts, 8 categories, and settings exist, while `journal_transactions` and `journal_postings` are empty, yielding exactly 0 ₫ balances.

---

## 3. Caveats

1. **Host Environment PATH**: Flutter SDK was installed to `C:\Users\coihu12\flutter\bin` and Git to `C:\Users\coihu12\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd`. While persisted to the Windows User PATH registry, active subshells spawned in existing processes might require `$env:Path = "C:\Users\coihu12\flutter\bin;..." + $env:Path` if the parent process has not reloaded environment variables.
2. **Android SDK / NDK**: Milestone M1 does not require native Android compilation (APK build is verified in Milestone M5); however, standard Flutter and Dart unit/database tests compile and execute 100% on native Windows host runners.
3. **No other caveats.**

---

## 4. Conclusion

Milestone M1 (Scaffold & Drift Database Schema) is **100% complete, verified, and locked**:
- `pubspec.yaml` and `analysis_options.yaml` adhere strictly to the locked whitelist and formatting rules.
- `lib/core/money/vnd_money.dart` and `lib/core/money/vnd_formatter.dart` deliver safe 64-bit integer currency logic and vi_VN tabular formatting.
- `lib/core/database/app_database.dart` and `lib/core/database/app_database.g.dart` provide all 9 Drift tables, relational constraints, foreign keys, migrations, and Vietnamese seeding.
- 44 automated tests pass with 100% success rate, zero analyze issues, and zero formatting errors.

---

## 5. Verification Method

To independently verify Milestone M1 artifacts:

1. **Format Check**:
   ```powershell
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd;" + $env:Path
   dart format --output=none --set-exit-if-changed .
   ```
   *Expected Result*: Exits with code 0 (0 changed).

2. **Static Analysis**:
   ```powershell
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd;" + $env:Path
   flutter analyze
   ```
   *Expected Result*: `No issues found! (ran in 10.8s)`, exit code 0.

3. **Automated Unit & Database Tests**:
   ```powershell
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd;" + $env:Path
   flutter test --coverage
   ```
   *Expected Result*: `All tests passed!`, 44 passed, 0 failed, exit code 0.

4. **Drift Code Generation Verification**:
   ```powershell
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd;" + $env:Path
   dart run build_runner build --delete-conflicting-outputs
   ```
   *Expected Result*: `Succeeded after ... with 858 outputs (1714 actions)`, exit code 0.

5. **Invalidation Conditions**:
   - Any test failure in `test/unit/vnd_money_test.dart` or `test/database/app_database_test.dart`.
   - Any presence of forbidden packages in `pubspec.yaml`.
   - Floating-point representations used for monetary amounts.
   - Any transaction or posting created during database seeding.
