# AGENTS.md — DONGTIEN SYSTEM INVARIANTS & AGENT RULES

> **Authoritative Rules for Subagents, Architects, Feature Leads, and QA Engineers.**  
> Application: **Đồng Tiền** (`dongtien` package, `vn.dongtien`)  
> Target Platform: Android (Offline-First, Material 3, `vi_VN` Locale)

---

## 1. PROJECT NON-NEGOTIABLES & ARCHITECTURAL INVARIANTS

Every agent contributing to this repository must preserve these non-negotiable invariants without exception:

### 1.1 Offline-First & Privacy Fortress
- **Zero Remote Dependencies**: The application operates 100% offline. Zero remote accounts, zero backend servers, zero cloud sync, zero telemetry, zero analytics SDKs, zero third-party ads, zero AI APIs, and zero bank scraping.
- **Android Sandbox Hardening**: All application data lives exclusively in private app storage. Cloud auto-backup is disabled via `android:allowBackup="false"` in `AndroidManifest.xml` and `res/xml/data_extraction_rules.xml`.
- **Zero Log Leakage**: Financial numbers, personal notes, and backup passwords must NEVER be printed to `debugPrint` or Android Logcat in release or profile builds.

### 1.2 Monetary & Arithmetic Integrity (Integer VND 64-Bit)
- **No Floating-Point Currency**: Monetary amounts must NEVER be stored, calculated, or passed as `double` or `float`. In Vietnam, currency is whole Vietnamese Dong (`VND`) with zero fractional subdivisions (hào/xu are obsolete).
- **Underlying Representation**: All monetary values are 64-bit signed integers (`int` in Dart) representing whole `VND`.
- **Value Object**: Use the `VndMoney` value type from `lib/core/money/vnd_money.dart`.
- **64-Bit Overflow Guard**:
  $$\text{max\_Safe\_VND} = 9\,000\,000\,000\,000\,000 \quad (9 \text{ quadrillion VND})$$
  Any transaction, multiplication, or aggregation exceeding `max_Safe_VND` throws a `VndOverflowException`.
- **Input Validation**: All transaction creation commands must enforce `amount > 0`.
- **Formatting Specification (`vi_VN`)**:
  - Thousands separator: dot (`.`).
  - Currency symbol: space followed by `₫` (e.g., `1.250.000 ₫`, `0 ₫`, `-500.000 ₫`).
  - Typography requirement: Every widget displaying monetary numbers, percentages, or dates MUST specify `fontFeatures: [FontFeature.tabularFigures()]` to prevent layout jitter during dynamic updates.

### 1.3 Accounting Truth & Virtual Fund Decoupling
- **Double-Entry General Ledger**: Persistence layer maintains an immutable double-entry ledger (`journal_transactions` and `journal_postings`).
- **Equation of Motion**: Every journal transaction must execute inside an atomic SQLite transaction (`db.transaction()`) and satisfy the pre-commit invariant:
  $$\sum \text{debit\_vnd} == \sum \text{credit\_vnd}$$
- **Virtual Funds (Envelopes) Decoupled**: Virtual fund envelopes (`envelopes` and `envelope_movements`) represent conceptual cash reserves. Virtual allocations (`ALLOCATE`, `RELEASE`, `TRANSFER`) NEVER generate general ledger postings. They do not alter liquid asset balances, income, or expenses.
- **Dynamic Balance Derivation**: No mutable cached balance columns exist on `ledger_accounts`. Account balances are derived dynamically across all postings:
  - Asset & Expense: $\sum \text{debit} - \sum \text{credit}$
  - Liability, Income & Equity: $\sum \text{credit} - \sum \text{debit}$
- **Audit-Preserving Reversals**: Voiding or editing never hard-deletes journal records. Reversal transactions (`REVERSAL`) offset original postings. Clean UI queries filter `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`.

---

## 2. ARCHITECTURAL LAYER BOUNDARIES & CODE LAYOUT

Code layout follows strict Clean Architecture principles. UI widgets must contain zero financial math and zero raw database queries.

```text
c:\Users\coihu12\Documents\App\
├── lib/
│   ├── app/                          # Application bootstrap, routing shell & theme
│   │   ├── app.dart                  # MaterialApp, vi_VN localization, IndexedStack shell
│   │   └── theme/                    # Design tokens extracted from design_refs/
│   │       ├── app_colors.dart       # Verbatim 7 color families from Untitled-3.png
│   │       ├── app_typography.dart   # 7 typography scales with tabular figures
│   │       └── app_spacing.dart      # 16-step spacing scale from Spacing.png
│   ├── core/                         # Infrastructure & platform adapters
│   │   ├── database/                 # Drift database definition, tables, migrations & DAOs
│   │   │   ├── app_database.dart     # SQLite database with PRAGMA foreign_keys = ON;
│   │   │   ├── app_database.g.dart   # Generated Drift code (drift_dev)
│   │   │   └── daos/                 # Domain-partitioned DAOs
│   │   ├── money/                    # Monetary types & formatting
│   │   │   ├── vnd_money.dart        # VndMoney value type & overflow guard
│   │   │   └── vnd_formatter.dart    # vi_VN dot separator & tabular figures formatter
│   │   ├── security/                 # Cryptography & backup isolation
│   │   │   ├── encrypted_backup_service.dart # Isolate.run PBKDF2 + AES-256-GCM
│   │   │   └── backup_payload_models.dart    # Outer JSON DTOs & validation
│   │   ├── notifications/            # Android 12-15+ compliant reminders
│   │   │   └── notification_scheduler.dart   # InexactAllowWhileIdle scheduler
│   │   └── widgets/                  # Reusable atomic presentation components
│   │       ├── custom_keypad.dart    # Custom numeric keypad from wallet.png
│   │       └── progress_bar.dart     # Material 3 two-tone budget progress bar
│   ├── domain/                       # Pure Dart domain services (Zero Flutter/Drift imports)
│   │   ├── ledger/                   # Posting matrix, dynamic balance, reversal/edit engine
│   │   ├── envelopes/                # Virtual fund allocations, available-to-allocate
│   │   ├── budgeting/                # Category budgets, ceiling division goal math & advisor
│   │   └── forecasting/              # Safe-to-Spend zero double-counting, month-end recurrence
│   ├── features/                     # Feature slices (Presentation & Riverpod State)
│   │   ├── dashboard/                # Tab 0: Safe-to-Spend hero, spending vs budget, upcoming
│   │   ├── transactions/             # Tab 1: Day-grouped list, filters, audit history, quick-add
│   │   ├── accounts/                 # Cash, bank, and credit card management
│   │   ├── envelopes/                # Tab 2: Quỹ tiền, fund detail, allocate/transfer/release
│   │   ├── plans/                    # Tab 3: Budgets, savings goals, cash flow forecast
│   │   └── reports_settings/         # Secondary: Reports, CSV export, encrypted backup/restore
│   └── main.dart                     # App entry point
├── test/
│   ├── unit/                         # Pure Dart tests (VndMoney, Safe-to-Spend, Feasibility, Crypto)
│   ├── database/                     # Drift in-memory tests (FKs, balanced tx, reversals, restore)
│   └── widget/                       # Component & UI screen tests
├── integration_test/                 # 15 mandatory acceptance scenarios on Android emulator
├── maestro/                          # Declarative E2E YAML test flows
├── docs/                             # Authoritative technical documentation
│   ├── ARCHITECTURE_AND_RULES.md     # Consolidated architecture, ledger rules, formulas & ADRs
│   ├── DESIGN_AND_TEST_PLAN.md       # Extracted design tokens, screen map & test matrix
│   └── design_refs/                  # Reference UI mockups & token spec PNGs
├── build_spec/                       # Original build specification
└── AGENTS.md                         # Subagent invariants & ownership rules (this file)
```

### Layer Dependency Rules
1. **Domain (`lib/domain/`)**: Pure Dart only. Zero imports from `package:flutter/*`, `package:drift/*`, or `package:flutter_riverpod/*`. Models are immutable plain Dart classes.
2. **Core Persistence (`lib/core/database/`)**: Imports Drift. Implements DAOs and runs inside `db.transaction()`. Implements `MigrationStrategy.beforeOpen` asserting `PRAGMA foreign_keys = ON;`.
3. **Features (`lib/features/`)**: Driven by Riverpod standard `Notifier` and `AsyncNotifier`. Feature widgets consume domain entities via Riverpod providers and invoke domain use cases. No raw SQL or financial logic inside UI files.
4. **App Theme & Shell (`lib/app/`)**: Provides `MaterialApp`, `IndexedStack` for the 4 bottom tabs, and standard `Navigator` routing. Imports tokens from `lib/app/theme/`.

---

## 3. FILE-OWNERSHIP RULES FOR SEQUENTIAL & PARALLEL PHASES

To eliminate file lock contention and schema drift during multi-agent execution, follow these ownership boundaries:

### Phase 0: Audit, Toolchain & Documentation Lock (Current Phase)
- **Exclusive Owner**: `worker_m0_1` (Lean Documentation Author & Architect).
- **Files Owned**:
  - `AGENTS.md`
  - `docs/ARCHITECTURE_AND_RULES.md`
  - `docs/DESIGN_AND_TEST_PLAN.md`
- **Output**: Complete, authoritative, high-density specifications matching the 15 acceptance criteria.

### Phase 1 & 2: Core Foundation & Pure Domain Engines (Sequential Gate)
- **Exclusive Owner**: Core Architect Track (`worker_m1_1`, `worker_m2_1`).
- **Files Owned**:
  - `pubspec.yaml`, `pubspec.lock`
  - `lib/core/money/` (`vnd_money.dart`, `vnd_formatter.dart`)
  - `lib/core/database/` (`app_database.dart`, `tables/`, `daos/`, migrations)
  - `lib/core/security/` (`encrypted_backup_service.dart`, `backup_payload_models.dart`)
  - `lib/domain/` (`ledger/`, `envelopes/`, `budgeting/`, `forecasting/`)
  - `test/unit/`, `test/database/`
- **Sequential Gate Requirement**: The Drift database schema (`app_database.g.dart`) and all pure domain engines MUST compile and pass 100% of unit and database invariant tests **before** parallel UI feature workers are spawned.

### Phase 3 & 4: Parallel UI & Feature Slices
- **Parallel Workers**: Partitioned strictly by isolated directory:
  - Worker A (`worker_m3_ui_core`): `lib/app/`, `lib/app/theme/`, `lib/core/widgets/`, `lib/features/dashboard/`.
  - Worker B (`worker_m3_transactions`): `lib/features/transactions/`, `lib/features/accounts/`.
  - Worker C (`worker_m3_envelopes`): `lib/features/envelopes/`.
  - Worker D (`worker_m4_plans`): `lib/features/plans/`, `lib/core/notifications/`.
  - Worker E (`worker_m4_reports_settings`): `lib/features/reports_settings/`, `android/`.
- **Cross-Layer Mutation Ban**: Parallel feature workers must NEVER modify `lib/core/database/` or `lib/domain/` code. If a domain or database contract requires adjustment, it must be escalated to the Core Architect.

### Phase 5 & 6: Verification & Hardening Track
- **Exclusive Owner**: QA & Forensic Auditor Track (`worker_m5_qa`).
- **Files Owned**: `integration_test/`, `maestro/`, `test/widget/`.
- **Responsibility**: End-to-end execution of the 15 mandatory acceptance scenarios, coverage reporting, static analysis, and debug APK build verification.

### Teamwork Workspace File Discipline
- Subagents own and write ONLY to their assigned workspace directory (`.agents/teamwork/<agent_folder>/`) or their explicit target files.
- `.agents/teamwork/` must NEVER contain application source code, tests, or mock data.
- Never name any file `AGENTS.md` or `GEMINI.md` inside `.agents/teamwork/` (they load as persistent rules).

---

## 4. LOCKED DEPENDENCY WHITELIST & STRICTLY FORBIDDEN PACKAGES

To guarantee stability, zero dependency churn, offline privacy, and native build reliability, dependencies are locked to this strict whitelist:

### 4.1 Approved Dependency Whitelist (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management (Standard Notifier / AsyncNotifier)
  flutter_riverpod: ^2.5.1

  # Persistence & Type-safe SQLite
  drift: ^2.20.0
  drift_flutter: ^0.2.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

  # Scheduled Local Reminders & Timezone
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
  flutter_timezone: ^3.0.1

  # Localization & Formatting
  intl: ^0.19.0

  # Export & Import File Bridge
  share_plus: ^10.0.0
  file_picker: ^8.1.0

  # Authenticated Cryptography (PBKDF2-HMAC-SHA256, AES-256-GCM)
  cryptography: ^2.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.12
  drift_dev: ^2.20.0
```

### 4.2 Forbidden Packages Compliance Matrix

| Forbidden Package | Severity | Rationale & Mandatory Architecture Alternative |
|---|---|---|
| `uuid` | **STRICTLY FORBIDDEN** | SQLite auto-increment integer IDs (`int` PK) and deterministic epoch millisecond timestamps provide reliable identity without package bloat. |
| `fl_chart`, `syncfusion_flutter_charts`, etc. | **STRICTLY FORBIDDEN** | External chart packages introduce breaking API churn and layout jank. Use custom Material 3 progress bars, row bars, and `CustomPainter` canvas widgets. |
| `go_router` | **STRICTLY FORBIDDEN** | Fragile deep-linking and state loss on tab switches. Use `IndexedStack` for the 4 bottom tabs and standard `Navigator.push` for secondary screens. |
| `freezed` / `riverpod_generator` | **STRICTLY FORBIDDEN** | Heavy `build_runner` code generation latency and runtime overhead. All domain models and `VndMoney` are handcrafted immutable Dart classes. Standard `Notifier` / `AsyncNotifier` is used. |
| `dio` / `http` | **STRICTLY FORBIDDEN** | 100% offline-first application. Zero network requests or remote APIs permitted. |
| `firebase_*` | **STRICTLY FORBIDDEN** | No remote telemetry, crashlytics, or cloud sync. Absolute user privacy. |
| `flutter_secure_storage` | **STRICTLY FORBIDDEN** | Avoids Android KeyStore keystore-loss edge cases. App settings live in SQLite `settings` table; encrypted backup files are secured by user-provided password. |
| `sqlcipher` | **STRICTLY FORBIDDEN** | Prone to Android NDK / architecture build failures. Standard SQLite via `drift_flutter` + `sqlite3_flutter_libs` is rock solid; backups are independently AES-GCM encrypted. |

---

## 5. QUALITY GATES & CODING STANDARDS

Before any phase or subagent handoff is declared complete, all code must pass these mandatory quality gates:

### 5.1 Static Analysis & Formatting Gates
1. **Formatting**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
   Must exit with code 0 (zero unformatted lines).
2. **Static Analysis**:
   ```bash
   flutter analyze
   ```
   Must exit with code 0 (zero errors, zero warnings, zero lints).

### 5.2 Test Coverage & Verification Gates
3. **Automated Test Suite**:
   ```bash
   flutter test --coverage
   ```
   Must pass 100% of unit, database, and widget tests covering all 15 mandatory acceptance scenarios.
4. **Production Debug APK Build**:
   ```bash
   flutter build apk --debug
   ```
   Must succeed and produce a verified APK binary in `build/app/outputs/flutter-apk/app-debug.apk`.

### 5.3 Concrete Implementation Standards
- **Tabular Numerals**: Every `Text` widget displaying money (`VndMoney`), percentages, or dates must include:
  ```dart
  style: textStyle.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  )
  ```
- **SQLite Relational Integrity**:
  ```dart
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON;');
  }
  ```
- **Accessibility & Automation Hooks**: Every button, input field, and summary card MUST attach a deterministic `Semantics` widget with an identifier from `docs/DESIGN_AND_TEST_PLAN.md`:
  ```dart
  Semantics(
    identifier: 'btn_safe_to_spend_breakdown',
    button: true,
    child: ...
  )
  ```
- **Idempotency Guard**: Every transaction submission command must supply an `idempotency_key` to prevent duplicate submissions on double-taps.
- **Never Hardcode / Never Cheat**:
  - Do NOT hardcode test results or expected strings in source code.
  - Do NOT create dummy/facade implementations that fake business logic.
  - Every calculation must be live and derive from actual state.
- **Explicit Category Selection & No Silent Category Fallback (`cats.first`)**:
  - NEVER fall back to an arbitrary category such as `categories.first` (which defaults to `Ăn uống` / Food) when creating or paying a scheduled obligation (`BILL` / `PLANNED_INCOME`) or posting any transaction.
  - Creating or editing a scheduled obligation (`BILL` / `PLANNED_INCOME`) MUST allow the user to explicitly select its category (defaulting to `Hoá đơn & Tiện ích` for `BILL` and `Lương` for `PLANNED_INCOME`), and paying a scheduled bill MUST only affect the budget of its explicitly assigned category (and NEVER deduct from unrelated category budgets or virtual fund envelopes like `Ăn uống`).
- **Single Source of Truth for Billing Cycle Window (`periodStartDay`)**:
  - NEVER hardcode `DateTime(now.year, now.month, 1)` for monthly budgets, Safe-to-Spend horizons, or financial reports.
  - Every period-bound query and provider (`currentMonthlyBudgetSummaryProvider`, `safeToSpendProvider`, `reportsSummaryProvider`, `checkCategoryBudgetAlert`, `upsertCategoryBudget`) MUST reactively watch `settingsStreamProvider` and compute the active billing cycle window `[cycleStart, cycleEnd)` and cycle `yearMonth` identifier using `setting.periodStartDay` (1–28).
- **Full CRUD Symmetry & Atomic Ledger Reversal on Financial Plan Widgets**:
  - Every user-created entity widget on Financial Plans (`CategoryBudgets`, `SavingsGoals`, `ScheduledItems`) MUST provide both Edit (`Sửa`) and Delete (`Xóa`) actions with confirmation dialogs and `_isSubmitting` double-tap guards.
  - Deleting or editing a `PAID_OR_RECEIVED` scheduled obligation MUST atomically reverse (`voidTransaction`) or supersede its linked `paidTransactionId` in `journal_transactions` and restore any linked virtual envelope balance.

