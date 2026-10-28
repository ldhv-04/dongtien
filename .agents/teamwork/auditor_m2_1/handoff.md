# FORENSIC AUDIT REPORT: MILESTONE M2 (DETERMINISTIC DOMAIN ENGINES & DAOS)

> **Auditor**: `auditor_m2_1`  
> **Archetype**: forensic_auditor  
> **Roles**: critic, specialist, auditor  
> **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\auditor_m2_1`  
> **Target**: Milestone M2  
> **Integrity Mode**: Development (per `ORIGINAL_REQUEST.md` line 8)  
> **Verdict**: **CLEAN**  

---

## 1. Observation

### 1.1 Pure Dart Layer Boundary Verification (`lib/domain/`)
- **Requirement**: `lib/domain/` must contain zero imports from `package:flutter/*`, `package:drift/*`, or `package:flutter_riverpod/*`.
- **Search Evidence**:
  - `grep "package:flutter"` in `lib/domain/`: 0 matches found.
  - `grep "package:drift"` in `lib/domain/`: 0 matches found.
  - `grep "riverpod"` in `lib/domain/`: 0 matches found.
- **Direct Inspection of All Imports in `lib/domain/`**:
  All 18 `.dart` files in `lib/domain/` import exclusively internal relative domain files or `package:dongtien/core/money/vnd_money.dart`. No UI, state, or database packages are imported.

### 1.2 Zero Floating-Point Currency Verification
- **Requirement**: Zero `double` or `float` types used for monetary amounts or storage.
- **Search Evidence**:
  - `grep "float"` in `lib/`: 0 matches.
  - `grep "real("` in `lib/core/database/`: 0 matches.
  - `grep "double"` in `lib/`: 13 matches identified. Every match corresponds to:
    1. Comments explaining "double-entry" ledger principles (4 occurrences in `transaction_type.dart:1`, `account_kind.dart:1`, `posting_matrix.dart:4`, `posting_leg.dart:3`).
    2. Ratios and percentages for UI progress indicators and savings rates (9 occurrences: `percentageOfTotal` 0.0..1.0 in `category_spending_calculator.dart:47`, `savingsRate` in `category_spending_calculator.dart:72`, `spentRatio` in `category_budget_progress.dart:41`, `progressRatio` in `goal_calculator.dart:23`).
  - Monetary values across all models, DTOs, calculators, and database tables are strictly 64-bit integers (`int`) or the `VndMoney` value type.

### 1.3 Locked Dependencies & Banned Package Audit (`pubspec.yaml`)
- **Requirement**: Zero forbidden packages (`uuid`, chart packages, `go_router`, `freezed`, `dio`/`http`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`).
- **Inspection of `pubspec.yaml`**:
  - `dependencies`: `flutter`, `flutter_localizations`, `flutter_riverpod` (^2.5.1), `drift` (^2.20.0), `drift_flutter` (0.2.0), `sqlite3_flutter_libs` (^0.5.24), `path_provider` (^2.1.4), `path` (^1.9.0), `flutter_local_notifications` (^17.2.3), `timezone` (^0.9.4), `flutter_timezone` (^3.0.1), `intl` (^0.19.0), `share_plus` (^10.0.0), `file_picker` (^8.1.0), `cryptography` (^2.7.0).
  - `dev_dependencies`: `flutter_test`, `integration_test`, `flutter_lints` (^4.0.0), `build_runner` (^2.4.12), `drift_dev` (^2.20.0).
  - Zero forbidden packages are present.

### 1.4 Accounting Truth & Dynamic Balance Invariants
- **Database Schema Table `LedgerAccounts`** (`lib/core/database/app_database.dart:12-25`):
  Columns: `id`, `name`, `kind`, `isLiquid`, `creditLimit`, `isArchived`, `createdAt`.
  Direct observation: **Zero cached balance columns exist**.
- **Table `JournalPostings`** (`lib/core/database/app_database.dart:83-102`):
  Table constraint: `chk_posting_one_sided CHECK ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`.
- **Dynamic Balance Derivation** (`lib/core/database/daos/ledger_dao.dart:353-375`):
  Derives account balance dynamically from postings:
  `SELECT COALESCE(SUM(debit_vnd), 0) AS total_debit, COALESCE(SUM(credit_vnd), 0) AS total_credit FROM journal_postings WHERE account_id = ?`
  Returns `kind.isDebitNormal ? (debit - credit) : (credit - debit)`.
- **Pre-Commit Invariant Assertion** (`lib/core/database/daos/ledger_dao.dart:81`):
  `PostingMatrix.assertBalanced(postings)` is invoked before opening or committing the database transaction.

### 1.5 Authentic Business Logic vs. Cheating / Facades
- **No Pre-populated Artifacts**: Workspace was searched for `.log`, `.txt`, `.result`, `.output` artifacts. Zero pre-existing results or fake attestations found.
- **No Stub Errors or Facades**: Zero occurrences of `UnimplementedError`, `NotImplementedError`, `TODO`, or `FIXME` in `lib/`.
- **Mathematical Soundness Verified in Domain Calculators**:
  - `SafeToSpendCalculator` (`lib/domain/forecasting/safe_to_spend_calculator.dart`): Chronologically allocates protected envelope reserves to pending bills to eliminate double-counting. Exactly preserves negative deficit amounts (never clamped to 0 ₫).
  - `GoalCalculator` (`lib/domain/budgeting/goal_calculator.dart`): Uses ceiling integer division `((shortfall.amount + remainingPeriods - 1) ~/ remainingPeriods)` to prevent 1 ₫ shortfalls.
  - `RecurrenceCalculator` (`lib/domain/forecasting/recurrence_calculator.dart`): Uses `min(anchor_day_of_month, daysInMonth(Y, M))` with full Gregorian leap-year handling, preventing day-31 degradation in February.
  - `CategorySpendingCalculator` (`lib/domain/budgeting/category_spending_calculator.dart`): Accurately computes net recovery ("Thu hồi chi phí ròng") on negative net expense and returns `null` for savings rate when income <= 0 ₫.
  - `EnvelopeDao` (`lib/core/database/daos/envelope_dao.dart`): Allocations, releases, and transfers create `envelope_movements` and update envelope balances while generating **zero journal postings**.

### 1.6 Direct Verification Toolchain Execution
1. **Formatting Gate**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
   - Exit code: `0`
   - Output: `Formatted 39 files (0 changed) in 1.04 seconds.`
2. **Static Analysis Gate**:
   ```bash
   flutter analyze
   ```
   - Exit code: `0`
   - Output: `Analyzing App... No issues found! (ran in 32.0s)`
3. **Automated Test Suite Gate**:
   ```bash
   flutter test --coverage
   ```
   - Exit code: `0`
   - Output: `00:05 +192: All tests passed!` (192 tests executed across unit and database suites, 0 failed).

---

## 2. Logic Chain

1. **Layer Boundary Isolation (Observation 1.1)**:
   The domain models and calculation engines in `lib/domain/` contain no references to Flutter UI widgets, Riverpod state management, or Drift database queries. Therefore, domain calculations are completely isolated, highly testable, and adhere to Clean Architecture boundaries.
2. **Monetary Integrity (Observation 1.2)**:
   Because all currency fields are 64-bit integers (`int`) or `VndMoney` (with 9 quadrillion VND overflow protection) and floating-point types are strictly confined to dimensionless ratios (0.0..1.0), floating-point arithmetic drift and rounding anomalies are mathematically impossible in this system.
3. **Dependency Compliance (Observation 1.3)**:
   The `pubspec.yaml` manifest contains solely the approved dependencies from `AGENTS.md` §4.1. No forbidden packages (`uuid`, `dio`, `go_router`, `fl_chart`, etc.) exist, ensuring 100% offline security and build stability.
4. **Relational Accounting Truth (Observation 1.4)**:
   Because `LedgerAccounts` contains no mutable balance column and balances are computed on demand by summing immutable journal postings, balance drift and desynchronization are structurally prevented. All posted transactions enforce `SUM(debit) == SUM(credit)`.
5. **Absence of Facades & Authentic Algorithms (Observation 1.5)**:
   Code inspection and tests show genuine implementations: ceiling integer division, chronological envelope bill coverage, drift-free month-end recurrence, and decoupled virtual fund movements. Zero dummy stubs or hardcoded mocks exist.
6. **Toolchain Execution (Observation 1.6)**:
   `dart format`, `flutter analyze`, and `flutter test --coverage` all exited with code 0. All 192 tests pass without regressions.

---

## 3. Caveats

- **Scope Boundary**: Milestone M2 covers pure domain engines, DAOs, and persistence integration. UI presentation screens, bottom navigation tabs, and isolate-based backup encryption belong to subsequent milestones (M3 and M4) and will be audited in their respective phases.
- **Local Database Environment**: Tests were executed against SQLite in-memory databases with `PRAGMA foreign_keys = ON;`. Android SQLite integration will be tested during emulator verification in M5.

---

## 4. Conclusion

**Verdict: CLEAN**

Milestone M2 strictly satisfies all architectural invariants, accounting rules, and coding standards:
- Pure Dart domain boundary in `lib/domain/` is 100% clean (zero framework imports).
- Currency arithmetic is 100% integer VND with zero floating-point money.
- Dependencies in `pubspec.yaml` adhere strictly to the approved whitelist.
- Dynamic balance derivation and double-entry invariants are enforced without cached balance columns.
- All algorithms are genuine, robust, and mathematically verified.
- Static analysis has 0 warnings, formatting is compliant, and 192/192 automated tests pass.

The work product is approved without reservations.

---

## 5. Verification Method

To independently reproduce the audit results:

```bash
# 1. Verify code formatting
C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed .

# 2. Run static analysis
C:\Users\coihu12\flutter\bin\flutter.bat analyze

# 3. Run complete test suite with coverage
C:\Users\coihu12\flutter\bin\flutter.bat test --coverage

# 4. Search lib/domain/ for forbidden imports (should return 0 matches)
grep -rn "package:flutter" lib/domain/
grep -rn "package:drift" lib/domain/
grep -rn "package:flutter_riverpod" lib/domain/
```

**Invalidation Conditions**:
- Any transaction accepted where `SUM(debit) != SUM(credit)`.
- Any mutable balance column added to `ledger_accounts`.
- Any virtual envelope movement producing journal ledger postings.
- Safe-to-Spend clamping negative balances to zero.
- Recurrence on day 31 degrading to day 28 in March.
