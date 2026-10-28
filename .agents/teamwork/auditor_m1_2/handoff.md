# Milestone M1 Forensic Integrity Audit Report

## 1. Observation

### 1.1 Scope of Audit
- Work products audited:
  - `c:\Users\coihu12\Documents\App\pubspec.yaml`
  - `c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart`
  - `c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart`
  - `c:\Users\coihu12\Documents\App\lib\core\database\app_database.dart`
  - `c:\Users\coihu12\Documents\App\lib\core\database\app_database.g.dart`
  - `c:\Users\coihu12\Documents\App\test\unit\vnd_money_test.dart`
  - `c:\Users\coihu12\Documents\App\test\unit\vnd_money_adversarial_test.dart`
  - `c:\Users\coihu12\Documents\App\test\database\app_database_test.dart`
  - `c:\Users\coihu12\Documents\App\test\database\adversarial_schema_test.dart`
- Reference rules & invariants:
  - `c:\Users\coihu12\Documents\App\AGENTS.md`
  - `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md`

### 1.2 Direct Observations & Evidence

#### Check 1: Zero Floating-Point Currency
- Search query for `double` and `float` across `lib/` (case-insensitive):
  - 0 occurrences of `double` in `lib/`.
  - 0 occurrences of `float` in `lib/`.
- `VndMoney` (`lib/core/money/vnd_money.dart`):
  - Field: `final int amount;` (line 35) representing whole VND.
  - Constants: `static const int maxSafeVnd = 9000000000000000;`, `static const int minSafeVnd = -9000000000000000;` (lines 26, 29).
  - Arithmetic operators: `+`, `-`, `*`, `~/`, unary `-` operate strictly on `int` with overflow guards throwing `VndOverflowException`. Zero floating-point division `/` operator exposed.
- `AppDatabase` (`lib/core/database/app_database.dart`):
  - All monetary columns use `IntColumn`: `creditLimit` (line 14), `debitVnd` (line 86), `creditVnd` (line 87), `reservedBalanceVnd` (line 108), `targetAmountVnd` (line 112), `periodLimitVnd` (line 114), `amountVnd` (lines 135, 191), `limitVnd` (line 172), `minimumCashBufferVnd` (line 224).
  - Zero double/real/float SQLite types.

#### Check 2: Zero Prohibited Packages & Whitelist Compliance
- `pubspec.yaml` dependencies:
  - Production: `flutter`, `flutter_localizations`, `flutter_riverpod: ^2.5.1`, `drift: ^2.20.0`, `drift_flutter: 0.2.0`, `sqlite3_flutter_libs: ^0.5.24`, `path_provider: ^2.1.4`, `path: ^1.9.0`, `flutter_local_notifications: ^17.2.3`, `timezone: ^0.9.4`, `flutter_timezone: ^3.0.1`, `intl: ^0.19.0`, `share_plus: ^10.0.0`, `file_picker: ^8.1.0`, `cryptography: ^2.7.0`.
  - Dev: `flutter_test`, `integration_test`, `flutter_lints: ^4.0.0`, `build_runner: ^2.4.12`, `drift_dev: ^2.20.0`.
- Verified absence of forbidden dependencies:
  - `uuid`: ABSENT
  - `fl_chart`, `syncfusion_flutter_charts`, etc.: ABSENT
  - `go_router`: ABSENT
  - `freezed`, `riverpod_generator`: ABSENT
  - `dio`, `http`: ABSENT
  - `firebase_*`: ABSENT
  - `flutter_secure_storage`: ABSENT
  - `sqlcipher`: ABSENT

#### Check 3: Zero Cheating, Hardcoded Mocks, or Facade Implementations
- `VndMoney` and `VndFormatter`: Fully functional logic. Dot grouping regex `(\d{1,3})(?=(\d{3})+(?!\d))` properly formats numbers (e.g. `1.250.000 ₫`). `parse()` and `tryParse()` validate sign uniqueness and reject malformed inputs (`--1000`, `++1000`).
- No hardcoded test responses or facade stubs found.
- Zero pre-populated test artifacts, logs, or results predating execution.

#### Check 4: Database Schema Integrity
- Foreign Key Pragma: `app_database.dart` lines 270-272:
  ```dart
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON;');
  },
  ```
- Dynamic Balance Principle:
  - `LedgerAccounts` table has columns `id`, `name`, `kind`, `isLiquid`, `creditLimit`, `isArchived`, `createdAt`.
  - Zero cached balance column (`balance`, `current_balance`, etc.). All account balances are derived dynamically via sum of postings.
- Seed Balances:
  - `seedInitialData(this)` creates system accounts (`EQUITY_OPENING` id 1, `INCOME` id 2, `EXPENSE` id 3), 8 categories, and singleton settings (`id: 1`).
  - Zero journal transactions or postings are created on startup.
  - Derived balance across all accounts is strictly `0 ₫`.
- Table CHECK constraints:
  - `LedgerAccounts`: `CHECK (kind IN ('ASSET_CASH', 'ASSET_BANK', 'LIABILITY_CREDIT_CARD', 'INCOME', 'EXPENSE', 'EQUITY_OPENING'))`
  - `Categories`: `CHECK (kind IN ('INCOME', 'EXPENSE'))`
  - `JournalTransactions`: `CHECK (tx_type IN ('OPENING_BALANCE', 'INCOME', 'EXPENSE', 'TRANSFER', 'CREDIT_CARD_PAYMENT', 'REFUND', 'REVERSAL'))`, `CHECK (status IN ('POSTED', 'SUPERSEDED', 'VOIDED'))`
  - `JournalPostings`: `CONSTRAINT chk_posting_one_sided CHECK ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`
  - `Envelopes`: `CHECK (policy IN ('PROTECTED', 'FLEXIBLE'))`
  - `EnvelopeMovements`: `CHECK (amount_vnd > 0)`, `CHECK (movement_type IN ('ALLOCATE', 'RELEASE', 'TRANSFER', 'SPEND', 'REFUND_RESTORE', 'REVERSAL'))`
  - `CategoryBudgets`: `CHECK (limit_vnd > 0)`, `CHECK (alert_threshold_pct >= 1 AND alert_threshold_pct <= 100)`
  - `ScheduledItems`: `CHECK (amount_vnd > 0)`, `CHECK (anchor_day_of_month IS NULL OR (anchor_day_of_month >= 1 AND anchor_day_of_month <= 31))`, `CHECK (reminder_days_before >= 0)`, enums for `kind`, `recurrence`, `status`
  - `Settings`: `CHECK (id == 1)`, `CHECK (minimum_cash_buffer_vnd >= 0)`, `CHECK (period_start_day >= 1 AND period_start_day <= 31)`, `CHECK (daily_reminder_hour >= 0 AND daily_reminder_hour <= 23)`, `CHECK (daily_reminder_minute >= 0 AND daily_reminder_minute <= 59)`

#### Check 5: Direct Test & Tool Execution
1. `flutter test test/unit/vnd_money_test.dart`
   - Output: `00:00 +33: All tests passed!` (Exit code: 0)
2. `flutter test test/unit/vnd_money_adversarial_test.dart`
   - Output: `00:00 +28: All tests passed!` (Exit code: 0)
3. `flutter test test/database/app_database_test.dart`
   - Output: `00:00 +14: All tests passed!` (Exit code: 0)
4. `flutter test test/database/adversarial_schema_test.dart`
   - Output: `00:00 +44: All tests passed!` (Exit code: 0)
5. Total test count across all suites:
   - Output: `00:00 +119: All tests passed!` (Exit code: 0)
6. `flutter analyze`
   - Output: `No issues found! (ran in 9.6s)` (Exit code: 0)
7. `dart format --output=none --set-exit-if-changed .`
   - Output: `Formatted 8 files (0 changed) in 0.84 seconds.` (Exit code: 0)

---

## 2. Logic Chain

1. **Monetary Safety**: In Vietnam, currency is exclusively integer VND with zero decimal subdivisions. The codebase completely omits `double` and `float`, modeling all monetary values as 64-bit signed `int` with an explicit overflow guard at 9 quadrillion VND (`9.000.000.000.000.000 ₫`). `VndMoney` enforces strict integer arithmetic with truncation `~/`, preventing precision drift.
2. **Dependency Fortress**: The project enforces an offline-first architecture with zero remote network calls, zero third-party telemetry, zero external chart packages, and zero non-standard state generators. Inspection of `pubspec.yaml` demonstrates exact adherence to the allowed whitelist with 0 prohibited packages.
3. **Double-Entry & Dynamic Balance**: The persistence layer establishes 9 Drift tables with `PRAGMA foreign_keys = ON;`. The `LedgerAccounts` table intentionally omits any cached balance columns, enforcing dynamic derivation of balances from postings. Postings enforce single-sided non-zero debits or credits via SQLite CHECK constraints.
4. **Initial State Integrity**: Fresh database creation populates the 3 core system accounts (`EQUITY_OPENING`, `INCOME`, `EXPENSE`), 8 Vietnamese categories, and the singleton settings row with zero transactions and zero postings, verifying that the initial account balances are strictly `0 ₫`.
5. **Empirical Verification**: All 119 unit, database, and adversarial tests pass without failures or mocks, static analysis reports 0 issues, and formatting is 100% compliant.

---

## 3. Caveats

- **Scope Boundary**: This audit specifically covered Milestone M1 deliverables (Scaffolding, locked dependencies, VndMoney, VndFormatter, AppDatabase Drift schema, seed data, and unit/database test suites).
- **Subsequent Milestones**: Business logic services (Milestone M2 double-entry posting matrix, envelope linkage, Safe-to-Spend calculator, encrypted backup isolate) are planned for subsequent milestones and were not part of M1 scope.

---

## 4. Conclusion

The Milestone M1 deliverables strictly fulfill all non-negotiable architectural invariants and acceptance requirements. Zero integrity violations or unauthorized shortcuts were detected.

**Final Verdict**: **CLEAN**

---

## 5. Verification Method

To independently reproduce the audit results, execute the following commands in `c:\Users\coihu12\Documents\App`:

```powershell
$env:PATH = "C:\Users\coihu12\flutter\bin;" + $env:PATH

# 1. Run unit test suites
flutter test test/unit/vnd_money_test.dart
flutter test test/unit/vnd_money_adversarial_test.dart

# 2. Run database schema and adversarial constraint test suites
flutter test test/database/app_database_test.dart
flutter test test/database/adversarial_schema_test.dart

# 3. Run static analysis
flutter analyze

# 4. Run format verification
& "C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe" format --output=none --set-exit-if-changed .
```

Invalidation conditions:
- Any test failure in the 119 test cases.
- Any non-zero exit code from `flutter analyze` or `dart format`.
- Any introduction of `double`/`float` in monetary representation or cached balance columns in `ledger_accounts`.
