# Forensic Integrity Audit Report: Milestone M2

**Target**: Milestone M2 (Pure Domain Engines, Drift DAOs, Accounting Truth, Invariant Suite)  
**Auditor**: `auditor_m2_2`  
**Date**: 2026-10-27T19:40:00Z  
**Verdict**: **CLEAN**

---

## 1. Observation

### Check 1: Pure Dart Layer Boundary
- **Inspection**: Grep across all 22 files in `lib/domain/` for `package:flutter`, `package:drift`, `package:flutter_riverpod`, and general `package:` imports.
- **Evidence**:
  - `import 'package:'` search in `lib/domain/` yielded only:
    `import 'package:dongtien/core/money/vnd_money.dart';`
  - Grep for `flutter`: 0 results.
  - Grep for `riverpod`: 0 results.
  - Grep for `drift`: Exactly 1 result in `recurrence_calculator.dart:6` as an English documentation word ("drift-free recurrence"), zero imports or annotations.
- **Result**: PASS. `lib/domain/` has zero dependencies on Flutter, Drift, or Riverpod.

### Check 2: Zero Floating-Point Currency
- **Inspection**: Grep search across `lib/` for `float` and `double`.
- **Evidence**:
  - `float`: 0 occurrences in `lib/`.
  - `double`: 0 occurrences used for monetary values. The only usages of `double` are:
    1. English docstring mentions of "double-entry" (`posting_matrix.dart:4`, `posting_leg.dart:3`, `account_kind.dart:1`, `transaction_type.dart:1`).
    2. Unitless ratios and percentages: `percentageOfTotal` (`category_spending_calculator.dart:47`), `savingsRate` (`category_spending_calculator.dart:72, 133`), `spentRatio` and `overallSpentRatio` (`category_budget_progress.dart:41, 83`), and `progressRatio` (`goal_calculator.dart:23`).
  - Database schema (`lib/core/database/app_database.dart`): Every currency column (`creditLimit`, `debitVnd`, `creditVnd`, `reservedBalanceVnd`, `targetAmountVnd`, `periodLimitVnd`, `amountVnd`, `limitVnd`, `minimumCashBufferVnd`) is defined as `IntColumn` (`integer()`).
  - Value object: `VndMoney` wraps `int amount` (64-bit integer whole VND) and enforces `maxSafeVnd = 9_000_000_000_000_000` (9 quadrillion VND).
- **Result**: PASS. Zero floating-point currency representation or calculation.

### Check 3: Zero Prohibited Packages
- **Inspection**: Verification of `pubspec.yaml` against the locked dependency whitelist from `AGENTS.md` §4.1 and forbidden packages matrix §4.2.
- **Evidence**:
  - `dependencies`: `flutter`, `flutter_localizations`, `flutter_riverpod: ^2.5.1`, `drift: ^2.20.0`, `drift_flutter: 0.2.0`, `sqlite3_flutter_libs: ^0.5.24`, `path_provider: ^2.1.4`, `path: ^1.9.0`, `flutter_local_notifications: ^17.2.3`, `timezone: ^0.9.4`, `flutter_timezone: ^3.0.1`, `intl: ^0.19.0`, `share_plus: ^10.0.0`, `file_picker: ^8.1.0`, `cryptography: ^2.7.0`.
  - `dev_dependencies`: `flutter_test`, `integration_test`, `flutter_lints: ^4.0.0`, `build_runner: ^2.4.12`, `drift_dev: ^2.20.0`.
  - Forbidden packages check: Zero `uuid`, zero `fl_chart`/`syncfusion`, zero `go_router`, zero `freezed`, zero `dio`/`http`, zero `firebase_*`, zero `flutter_secure_storage`, zero `sqlcipher`.
- **Result**: PASS. Exactly matches the locked whitelist.

### Check 4: Zero Cheating / Mock Facades
- **Inspection**: Search for `NotImplementedError`, `UnimplementedError`, `TODO`, `FIXME`, dummy constants, or fake return facades across `lib/domain/` and `lib/core/database/daos/`.
- **Evidence**:
  - Grep for `UnimplementedError`: 0 results.
  - Grep for `NotImplementedError`: 0 results.
  - Grep for `TODO`: 0 results.
  - Grep for pre-populated `.log` or `*result*` artifacts: 0 results.
  - Domain implementation analysis:
    - `PostingMatrix`: 9 authentic double-entry posting builders with pre-commit balance assertion.
    - `AvailableToAllocateCalculator`: Genuine arithmetic calculation: `total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd`.
    - `CategorySpendingCalculator`: Genuine net expense, net recovery, and savings rate derivation.
    - `CategoryBudgetTracker`: Genuine spending threshold and status evaluation.
    - `GoalCalculator`: Genuine ceiling integer division: `((shortfall) + remainingPeriods - 1) ~/ remainingPeriods`.
    - `FeasibilityAdvisor`: Genuine capacity evaluation and 3 algorithmic adjustments (extend deadline, lower target, pause lower priority).
    - `RecurrenceCalculator`: Drift-free leap year and calendar day anchor math: `min(anchor_day_of_month, daysInMonth(Y, M))`.
    - `CashFlowForecaster`: Step-by-step daily projection across 30/60/90 days with buffer breach detection.
    - `SafeToSpendCalculator`: Zero double-counting chronological allocation algorithm preserving negative deficits.
- **Result**: PASS. Authentic business logic and mathematical algorithms across all engines.

### Check 5: Accounting Truth & Double-Entry Invariants
- **Inspection**: Inspection of `LedgerAccounts` table, `LedgerDao`, and `EnvelopeDao`.
- **Evidence**:
  - Table `LedgerAccounts`: Contains `id`, `name`, `kind`, `isLiquid`, `creditLimit`, `isArchived`, `createdAt`. **Zero cached balance columns exist**.
  - Dynamic derivation: Account balances are dynamically computed on demand from `journal_postings`:
    - Normal Debit (Assets/Expenses): `SUM(debit_vnd) - SUM(credit_vnd)`
    - Normal Credit (Liabilities/Income/Equity): `SUM(credit_vnd) - SUM(debit_vnd)`
  - Posting equation of motion: `PostingMatrix.assertBalanced(postings)` verifies `SUM(debit_vnd) == SUM(credit_vnd)` before writing to SQLite.
  - Atomicity: Every journal write executes inside `db.transaction()`.
  - Single-sided constraint: `CONSTRAINT chk_posting_one_sided CHECK ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`.
  - Virtual funds decoupling: Envelopes allocations, releases, and transfers update `envelope_movements` and `envelopes.reserved_balance_vnd` only, creating **zero general ledger postings**.
  - Reversals & Edits: Voiding marks `VOIDED` and generates a `REVERSAL` transaction; editing marks `SUPERSEDED`, generates a `REVERSAL`, and posts the new transaction with `replaced_by_tx_id`.
  - Clean UI queries: Filter `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`.
- **Result**: PASS. Strict general ledger integrity and decoupling preserved.

### Check 6: Direct Toolchain Execution
- **Command 1**: `dart format --output=none --set-exit-if-changed .`
  - Output: `Formatted 41 files (0 changed) in 1.01 seconds.`
  - Exit code: `0`
- **Command 2**: `flutter analyze`
  - Output: `Analyzing App... No issues found! (ran in 1.2s)`
  - Exit code: `0`
- **Command 3**: `flutter test`
  - Output: `00:03 +253: All tests passed!`
  - Exit code: `0`
  - Breakdown: 105 database invariant tests (`test/database/`) + 148 pure unit domain tests (`test/unit/`) = 253 passed tests.

---

## 2. Logic Chain

1. **Layer Boundary Verification**:
   - Because `lib/domain/` contains zero package imports other than `package:dongtien/core/money/vnd_money.dart` (which is a pure Dart value type with only `show immutable` from `foundation.dart`), and contains zero imports of `flutter/*`, `drift/*`, or `flutter_riverpod/*`, the domain layer satisfies the Clean Architecture pure Dart boundary invariant.

2. **Currency Integrity Verification**:
   - Because all monetary attributes across database table schemas (`app_database.dart`), domain commands, and domain calculators use 64-bit integer VND (`int` or `VndMoney`), and zero currency fields use `double` or `float`, the application adheres strictly to the Vietnamese zero-decimal monetary invariant.

3. **Dependency Whitelist Verification**:
   - Because every entry in `pubspec.yaml` corresponds 1-to-1 with the whitelist in `AGENTS.md` §4.1, and none of the 8 strictly forbidden packages (`uuid`, chart libraries, `go_router`, `freezed`, `dio`/`http`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`) are present, the toolchain configuration is verified clean.

4. **Authenticity & Anti-Cheat Verification**:
   - Because exhaustive inspection of all domain engines revealed genuine mathematical algorithms (ceiling division, zero double-counting, chronological bill coverage, recurrence anchor preservation, dynamic ledger balance queries), and grep searches found zero mock facades, stubs, or pre-computed outputs, the implementation is authentic.

5. **Accounting Invariant Verification**:
   - Because the database schema has no cached balance columns, all postings enforce `SUM(debit) == SUM(credit)` within atomic SQLite transactions, and envelope movements generate zero ledger postings, the accounting truth invariant is fully preserved.

6. **Quality Gate Verification**:
   - Because `dart format`, `flutter analyze`, and `flutter test` executed directly and passed with exit code 0 across all 253 test cases, Milestone M2 meets all automated quality criteria.

---

## 3. Caveats

- **Scope Boundary**: Milestone M2 scope is restricted to Core Persistence, Pure Domain Engines, DAOs, and Invariant Tests. UI Presentation widgets (`lib/features/`) and Isolate encrypted backup services are scheduled for subsequent milestones (M3 and M4) per the project plan.
- No caveats regarding Milestone M2 code, tests, or integrity.

---

## 4. Conclusion

Milestone M2 demonstrates outstanding engineering quality, complete architectural compliance, authentic business logic, and rigorous test coverage. Zero integrity violations or deviations from project invariants were detected.

**Final Verdict**: **CLEAN**

---

## 5. Verification Method

To independently verify the audit conclusions, run the following commands in PowerShell from the project root:

```powershell
# Set path for current subshell
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd;" + $env:Path

# 1. Verify Dart formatting
dart format --output=none --set-exit-if-changed .

# 2. Verify static analysis
flutter analyze

# 3. Verify complete test suite (253 tests)
flutter test

# 4. Verify pure Dart domain boundary (should return 0 matches for flutter/drift/riverpod)
Get-ChildItem -Path "lib/domain" -Recurse -Filter "*.dart" | Select-String -Pattern "package:flutter/", "package:drift/", "package:flutter_riverpod/"

# 5. Verify zero float/double currency usage
Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | Select-String -Pattern "float "
```

Invalidation conditions:
- Any occurrence of `package:flutter/*`, `package:drift/*`, or `package:flutter_riverpod/*` in `lib/domain/`.
- Any use of `double` or `float` for monetary storage or calculation.
- Any failing test in `flutter test`.
- Any static analysis issue in `flutter analyze`.
