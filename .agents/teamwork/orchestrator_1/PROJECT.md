# Project: DongTien (Production-Ready Offline-First Personal Finance App)

## Architecture
- **Architecture Pattern**: Clean Architecture with strict separation between:
  1. **Presentation / UI** (`lib/features/`, `lib/app/theme/`, `lib/core/widgets/`): Zero business logic or raw SQL. Driven by Riverpod `Notifier` / `AsyncNotifier`.
  2. **Domain Logic** (`lib/domain/`): Pure Dart domain services, zero Flutter or database imports. Handcrafted immutable models, integer arithmetic guards.
  3. **Core & Persistence** (`lib/core/database/`, `lib/core/money/`, `lib/core/security/`, `lib/core/notifications/`): Drift SQLite with `PRAGMA foreign_keys = ON;`, `VndMoney` 64-bit integer, Isolate-based AES-256-GCM authenticated encryption, and inexact local reminders.
- **Data Flow**:
  - UI triggers Intent -> Riverpod Notifier invokes Pure Domain Service -> Domain Service validates invariants -> Drift DAO executes atomic `db.transaction()` -> State streams update UI reactively.
- **Data Model**:
  - Double-entry general ledger decoupled from virtual fund envelopes.
  - Balances derived dynamically across postings (reversals offset superseded postings).

---

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Toolchain Audit & Environment Assessment | Audit git, flutter, dart, adb, java and workspace setup | M0 | explorer_survey_3 |
| 2 | Lean Documentation: AGENTS.md | Project invariants and file-ownership rules | M0 | build_spec §1.5 |
| 3 | Lean Documentation: docs/ARCHITECTURE_AND_RULES.md | Double-entry rules, envelope linkage, Safe-to-Spend math, security/KDF spec | M0 | build_spec §1.5 |
| 4 | Lean Documentation: docs/DESIGN_AND_TEST_PLAN.md | Design tokens from design_refs/, screen map, and 15 acceptance matrices | M0 | build_spec §1.5 |
| 5 | Flutter Scaffolding & Directory Structure | Initialize Flutter package `dongtien` (`vn.dongtien`) preserving existing docs | M1 | explorer_survey_3, build_spec §2 |
| 6 | Locked pubspec.yaml Dependencies | Riverpod, Drift, sqlite3, path_provider, crypto, intl; zero forbidden deps | M1 | build_spec §3 |
| 7 | Monetary Representation: VndMoney | 64-bit signed integer (`int`) whole VND, zero decimals, overflow guard (9 quadrillion VND) | M1 | spec_miner_survey_1, build_spec §4.1 |
| 8 | Currency Formatter (vi_VN) | Formats whole VND with dot separator (`1.250.000 ₫`) and tabular figures | M1 | spec_miner_survey_1, build_spec §4.1 |
| 9 | Drift Database: Table ledger_accounts | 6 account kinds, is_liquid flag, credit limit, archived flag | M1 | spec_miner_survey_1, build_spec §4.2 |
| 10 | Drift Database: Table categories | Income/Expense categories linked to ledger accounts with icon and color | M1 | spec_miner_survey_1, build_spec §4.2 |
| 11 | Drift Database: Table journal_transactions | Transactions with status (POSTED, SUPERSEDED, VOIDED), idempotency_key, FK reversal pointers | M1 | spec_miner_survey_1, build_spec §4.2 |
| 12 | Drift Database: Table journal_postings | Balanced debits and credits with category and envelope FKs | M1 | spec_miner_survey_1, build_spec §4.2 |
| 13 | Drift Database: Table envelopes | Virtual fund reserves with policy (PROTECTED, FLEXIBLE), targets, rollover | M1 | spec_miner_survey_1, build_spec §4.2 |
| 14 | Drift Database: Table envelope_movements | 6 movement types (ALLOCATE, RELEASE, TRANSFER, SPEND, REFUND_RESTORE, REVERSAL) | M1 | spec_miner_survey_1, build_spec §4.2 |
| 15 | Drift Database: Table category_budgets | Monthly caps per category with alert threshold, unique (category_id, year_month) | M1 | spec_miner_survey_1, build_spec §4.2 |
| 16 | Drift Database: Table scheduled_items | Bills & planned income with anchor_day_of_month (1..31) for drift-free recurrence | M1 | spec_miner_survey_1, build_spec §4.2 |
| 17 | Drift Database: Table settings | Singleton configuration (id=1): minimum buffer, period start day, reminder time | M1 | spec_miner_survey_1, build_spec §4.2 |
| 18 | Foreign Key Integrity & Pragma | `PRAGMA foreign_keys = ON;` in beforeOpen migration strategy | M1 | spec_miner_survey_1, build_spec §4.2 |
| 19 | Default Vietnamese Seed Data | Seed 8 Vietnamese categories and EQUITY_OPENING account with 0 ₫ balances | M1 | spec_miner_survey_1, build_spec §4.2 |
| 20 | Code Generation (drift_dev) | Build runner for Drift table and database generation (`app_database.g.dart`) | M1 | explorer_survey_3, build_spec §3 |
| 21 | Double-Entry Posting Matrix | Debit/Credit balance rules for 7 transaction types inside db.transaction() | M2 | spec_miner_survey_1, build_spec §4.3 |
| 22 | Double-Entry Balance Invariant | Pre-commit validation ensuring `SUM(debit_vnd) == SUM(credit_vnd)` | M2 | spec_miner_survey_1, build_spec §4.3 |
| 23 | Atomic Envelope Movement Linkage | Automatically record envelope SPEND / REFUND_RESTORE on linked expense/refund | M2 | spec_miner_survey_1, build_spec §4.3 |
| 24 | Dynamic Account Balance Derivation | Sum postings across all transactions without mutable cached balance | M2 | spec_miner_survey_1, build_spec §4.4 |
| 25 | Total Liquid Assets Derivation | Sum balances of active accounts where `is_liquid == true` | M2 | spec_miner_survey_1, build_spec §5.1 |
| 26 | Audit-Preserving Void Engine | Mark target VOIDED and insert REVERSAL transaction + offsetting envelope movement | M2 | spec_miner_survey_1, build_spec §4.5 |
| 27 | Audit-Preserving Edit Engine | Mark target SUPERSEDED, insert REVERSAL, and insert new POSTED transaction | M2 | spec_miner_survey_1, build_spec §4.5 |
| 28 | Clean UI Filtering Logic | Query transactions `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'` | M2 | spec_miner_survey_1, build_spec §4.5 |
| 29 | Available-to-Allocate Engine | Total Liquid Assets - Total Envelope Reserves - Minimum Cash Buffer | M2 | spec_miner_survey_1, build_spec §5.1 |
| 30 | Envelope Over-Allocation Guard | Block allocations exceeding Available-to-Allocate | M2 | spec_miner_survey_1, build_spec §5.1 |
| 31 | Envelope Spending Deficit Guard | Block spending > envelope balance unless explicit exception confirmed | M2 | spec_miner_survey_1, build_spec §5.1 |
| 32 | Category Spending & Refund Accounting | Gross expense, refund credits, net expense, net recovery handling | M2 | spec_miner_survey_1, build_spec §5.2 |
| 33 | Savings Rate Engine | Correct calculation; returns null ("Chưa có thu nhập") if income <= 0 | M2 | spec_miner_survey_1, build_spec §5.2 |
| 34 | Safe-to-Spend Zero Double-Counting Engine | Liquid Assets - Protected Reserves - Unfunded Outflows - Buffer | M2 | spec_miner_survey_1, build_spec §5.3 |
| 35 | Safe-to-Spend Negative Deficit Breakdown | Never clamps to 0; reports exact negative deficit and zero daily rate | M2 | spec_miner_survey_1, build_spec §5.3 |
| 36 | Savings Goals Ceiling Division | `((T - C) + N - 1) ~/ N`, status ACHIEVED / OVERDUE | M2 | spec_miner_survey_1, build_spec §5.4 |
| 37 | Feasibility Advisor Engine | Flag INFEASIBLE and compute 3 one-tap adjustments (extend, lower, pause) | M2 | spec_miner_survey_1, build_spec §5.4 |
| 38 | Drift-Free Month-End Recurrence | `min(anchor_day, daysInMonth(Y, M))` preserving 31st across Feb | M2 | spec_miner_survey_1, build_spec §5.5 |
| 39 | 30/60/90-Day Cash Flow Forecast | Project daily closing balances, highlight dates falling below buffer | M2 | spec_miner_survey_1, build_spec §5.5 |
| 40 | Idempotency Key Guard | Reject duplicate submissions with identical idempotency_key | M2 | spec_miner_survey_1, build_spec §4.2 |
| 41 | Design Tokens: Spacing Scale | 16-step spacing scale `sp0` through `sp15` (0px to 128px) | M3 | spec_miner_survey_2, Spacing.png |
| 42 | Design Tokens: Typography Scale | 7-tier scale with tabular figures `FontFeature.tabularFigures()` | M3 | spec_miner_survey_2, Untitled-2.png |
| 43 | Design Tokens: Semantic Palette | Verdant, Sandstone, Ember, Ruby, Marigold, Charcoal, Neutral tokens | M3 | spec_miner_survey_2, Untitled-3.png |
| 44 | Design Tokens: Card & Shape | 16-24px rounded corners, subtle outline borders | M3 | spec_miner_survey_2, budget.png |
| 45 | Navigation Shell | 4 bottom tabs with `IndexedStack` + standard `Navigator` | M3 | spec_miner_survey_2, build_spec §6.1 |
| 46 | Dashboard: Safe-to-Spend Hero Card | Primary card with spendable amount, daily rate, and breakdown modal | M3 | spec_miner_survey_2, build_spec §6.1 |
| 47 | Dashboard: Spending vs Budget | Spending progress against monthly budgets with warning tints | M3 | spec_miner_survey_2, build_spec §6.1 |
| 48 | Dashboard: Upcoming Obligations | Pending bills and next income with quick pay action | M3 | spec_miner_survey_2, build_spec §6.1 |
| 49 | Dashboard: Fund Progress & Recent 5 Tx | Mini fund progress cards and recent 5 transactions list | M3 | spec_miner_survey_2, build_spec §6.1 |
| 50 | Transactions: Day-Grouped List | Sticky calendar day headers with daily net total | M3 | spec_miner_survey_2, build_spec §6.1 |
| 51 | Transactions: Search & Filter Bar | Search by note/merchant; filter chips for type, account, category, date | M3 | spec_miner_survey_2, build_spec §6.1 |
| 52 | Transactions: Account Management | Liquid Cash, Bank, and Credit Card accounts cards/drawer | M3 | spec_miner_survey_2, build_spec §6.1 |
| 53 | Transactions: Audit History Sheet | Bottom sheet displaying full revision and reversal chain | M3 | spec_miner_survey_2, build_spec §4.5 |
| 54 | Quick-Add: Custom Numeric Keypad | Digits 0-9, backspace, formatted display, quick amounts | M3 | spec_miner_survey_2, wallet.png |
| 55 | Quick-Add: Segmented Type Selector | Chi tiêu, Thu nhập, Chuyển khoản, Trả thẻ, Hoàn tiền | M3 | spec_miner_survey_2, build_spec §6.2 |
| 56 | Quick-Add: Category Grid & Account Chips | Visual category picker and source/dest account chips | M3 | spec_miner_survey_2, build_spec §6.2 |
| 57 | Virtual Funds: Summary & Progress | Liquid Assets, Reserved, Available-to-allocate bar | M3 | spec_miner_survey_2, build_spec §6.1 |
| 58 | Virtual Funds: Protected & Flexible Lists | Grouped envelope cards with lock icon and progress | M3 | spec_miner_survey_2, savings.png |
| 59 | Virtual Funds: Allocate / Transfer / Release | Modals for moving virtual money between reserves | M3 | spec_miner_survey_2, build_spec §5.1 |
| 60 | Virtual Funds: Fund Detail Screen | Metric details and chronological movement history | M3 | spec_miner_survey_2, savings.png |
| 61 | Plans: Category Budgets Segment | Monthly spending limits, progress bars, alert thresholds | M4 | spec_miner_survey_2, build_spec §6.1 |
| 62 | Plans: Savings Goals Segment | Target, deadline, ceiling contribution, feasibility advisor | M4 | spec_miner_survey_2, build_spec §5.4 |
| 63 | Plans: Feasibility Calculators UI | 3 one-tap actions (extend deadline, lower target, pause) | M4 | spec_miner_survey_2, build_spec §5.4 |
| 64 | Plans: Obligations & Cash Flow Forecast | Scheduled bills, planned income, 30/60/90-day balance chart | M4 | spec_miner_survey_2, build_spec §5.5 |
| 65 | Reports: Financial Health & Net Worth | Income, Gross Expense, Refunds, Net Expense, Net Worth, Saving Rate | M4 | spec_miner_survey_2, build_spec §6.1 |
| 66 | Settings: Cash Buffer & Period Start | Configure minimum buffer VND and period boundary day | M4 | spec_miner_survey_2, build_spec §6.1 |
| 67 | Settings: CSV Export | Export transactions to CSV via `share_plus` | M4 | spec_miner_survey_2, build_spec §6.1 |
| 68 | Settings: Sample Data Generator & Reset | Explicit actions to generate sample data or reset to 0 ₫ | M4 | spec_miner_survey_2, build_spec §6.1 |
| 69 | Compliant Local Notifications | Inexact scheduling (`inexactAllowWhileIdle`), POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED | M4 | spec_miner_survey_2, build_spec §6.3 |
| 70 | Notification Triggers | Daily summary, upcoming bills, 80%/100% budget alerts | M4 | spec_miner_survey_2, build_spec §6.3 |
| 71 | Notification Graceful Degradation | Degrades gracefully without crash when permission denied | M4 | spec_miner_survey_2, build_spec §6.3 |
| 72 | Android Hardening | `android:allowBackup="false"`, `data_extraction_rules.xml` | M4 | spec_miner_survey_2, build_spec §7.1 |
| 73 | Isolate Encrypted Backup Export | Outer JSON `magic: DONGTIEN_ENC_V1`, PBKDF2 (120k iter), AES-256-GCM | M4 | spec_miner_survey_2, build_spec §7.2 |
| 74 | Isolate Encrypted Backup Restore | 25MB check, authentication before DB, memory invariant check, atomic restore | M4 | spec_miner_survey_2, build_spec §7.2 |
| 75 | Tampered Backup Rejection | Rejects wrong password or modified byte without touching DB | M4 | spec_miner_survey_2, build_spec §7.2 |
| 76 | Semantics Accessibility Identifiers | `Semantics(identifier: '...')` on all buttons, inputs, cards | M4 | spec_miner_survey_2, build_spec §6.2 |
| 77 | Automated Scenario 1 (Opening Asset) | Liquid asset = 10.000.000 ₫; operating income = 0 ₫ | M5 | build_spec §8 |
| 78 | Automated Scenario 2 (Salary) | Liquid asset = 30.000.000 ₫; recognized income = 20.000.000 ₫ | M5 | build_spec §8 |
| 79 | Automated Scenario 3 (Cash Expense) | Liquid asset = 29.900.000 ₫; net expense = 100.000 ₫ | M5 | build_spec §8 |
| 80 | Automated Scenario 4 (Internal Transfer) | Total liquid assets unchanged (29.900.000 ₫); income/expense unchanged | M5 | build_spec §8 |
| 81 | Automated Scenario 5 (Virtual Fund Allocation) | Reserve = 1.000.000 ₫; Safe-to-Spend decreases by 1.000.000 ₫; liquid assets unchanged | M5 | build_spec §8 |
| 82 | Automated Scenario 6 (Credit Card Purchase) | Net expense increases by 500.000 ₫; card liability = 500.000 ₫; liquid assets unchanged | M5 | build_spec §8 |
| 83 | Automated Scenario 7 (Credit Card Payment) | Liquid assets decrease by 500.000 ₫; card liability = 0 ₫; net expense unchanged | M5 | build_spec §8 |
| 84 | Automated Scenario 8 (Refund) | Net expense decreases by 50.000 ₫; receiving asset increases; envelope restored | M5 | build_spec §8 |
| 85 | Automated Scenario 9 (Edit & Void Transaction) | Reversals balance, accounts reconcile, UI hides superseded/reversal noise | M5 | build_spec §8 |
| 86 | Automated Scenario 10 (Duplicate Submission Guard) | Identical idempotency_key creates exactly one transaction | M5 | build_spec §8 |
| 87 | Automated Scenario 11 (Scheduled Bill & Payment) | Deducted in Safe-to-Spend before payment; linked to real tx after payment | M5 | build_spec §8 |
| 88 | Automated Scenario 12 (Negative Safe-to-Spend) | Returns exact negative VND shortfall; renders in red with breakdown | M5 | build_spec §8 |
| 89 | Automated Scenario 13 (Encrypted Backup Roundtrip) | Export, wipe, restore -> all balances, envelopes, budgets match pre-wipe | M5 | build_spec §8 |
| 90 | Automated Scenario 14 (Tampered Backup Rejection) | Flip 1 byte or wrong password -> restore rejects safely, DB untouched | M5 | build_spec §8 |
| 91 | Automated Scenario 15 (Permission Denied & Month-End) | App functional without notification permission; Feb 28/29 to Mar 31 recurrence | M5 | build_spec §8 |
| 92 | Quality Gate: Format Verification | `dart format --output=none --set-exit-if-changed .` exits with 0 | M5 | build_spec §8 |
| 93 | Quality Gate: Static Analysis | `flutter analyze` exits with 0 (zero issues) | M5 | build_spec §8 |
| 94 | Quality Gate: Automated Test Coverage | `flutter test --coverage` passes 100% of unit, db, and widget tests | M5 | build_spec §8 |
| 95 | Quality Gate: Verified APK Build | `flutter build apk --debug` succeeds and produces APK | M5 | build_spec §8 |

---

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M0 | Audit, Toolchain & Lean Docs | Environment assessment, AGENTS.md, docs/ARCHITECTURE_AND_RULES.md, docs/DESIGN_AND_TEST_PLAN.md | none | DONE |
| M1 | Scaffold & Drift Database Schema | Flutter project init, locked dependencies, VndMoney, 9 Drift tables, FKs, Vietnamese seeding, code gen | M0 | DONE |
| M2 | Deterministic Domain Engines | Double-entry posting service, envelope linkage, reversal/edit engine, Safe-to-Spend, Feasibility, Forecast | M1 | DONE |
| M3 | Design System & Core Features | Tokens, 4-tab navigation shell, Dashboard, Transactions & Accounts, Virtual Funds, Keypad entry | M2 | IN_PROGRESS |
| M4 | Advanced Features, Backup & Hardening | Plans & Forecast, Reports, Settings, Notifications, Isolate AES-GCM Backup/Restore, Android hardening | M3 | PLANNED |
| M5 | Verification & Acceptance Gates | 15 acceptance scenarios, full test suite pass, format, analyze, and verified debug APK | M4 | PLANNED |

---

## Interface Contracts

### 1. `lib/core/money/vnd_money.dart`
- **Class**: `VndMoney`
- **Fields**: `final int amount` (whole VND)
- **Constants**: `static const int maxSafeVnd = 9000000000000000;`
- **Methods**:
  - `VndMoney(int amount)`: throws `ArgumentError` if amount is negative where positive is required, throws `VndOverflowException` if `amount.abs() > maxSafeVnd`.
  - `VndMoney operator +(VndMoney other)`
  - `VndMoney operator -(VndMoney other)`
  - `VndMoney operator *(int factor)`
  - `VndMoney operator ~/(int divisor)`
  - `String formatVnd({bool showSign = false})`: returns e.g. `1.250.000 ₫`, `0 ₫`, `-500.000 ₫`.

### 2. `lib/core/database/app_database.dart`
- **Class**: `AppDatabase` extends `_$AppDatabase`
- **Tables**: `LedgerAccounts`, `Categories`, `JournalTransactions`, `JournalPostings`, `Envelopes`, `EnvelopeMovements`, `CategoryBudgets`, `ScheduledItems`, `Settings`
- **Migration**: `beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON;'); ... }`
- **Seeding**: Seeds initial 8 categories and `EQUITY_OPENING` account inside `onCreate`.

### 3. `lib/domain/ledger/ledger_service.dart`
- **Method**: `Future<JournalTransaction> postTransaction(PostTransactionCommand cmd)`
  - Executes inside `db.transaction()`
  - Asserts `SUM(debit_vnd) == SUM(credit_vnd)`
  - If `cmd.envelopeId != null`, creates atomic `EnvelopeMovement`
- **Method**: `Future<void> voidTransaction(int transactionId)`
  - Marks target `VOIDED`
  - Inserts `REVERSAL` transaction with inverted postings
  - Offsets any linked envelope movement
- **Method**: `Future<JournalTransaction> editTransaction(int originalTxId, PostTransactionCommand newTxCmd)`
  - Voids original with `SUPERSEDED`
  - Inserts reversal
  - Inserts new `POSTED` transaction with `replaced_by_tx_id` pointer
- **Method**: `Stream<int> watchAccountBalance(int accountId)`
  - Sums debits - credits (Assets/Expenses) or credits - debits (Liabilities/Income/Equity)

### 4. `lib/domain/forecasting/safe_to_spend_calculator.dart`
- **Function**: `SafeToSpendResult calculateSafeToSpend({required int liquidAssetsVnd, required int protectedReservesVnd, required List<PendingBillAllocation> pendingBills, required int minimumBufferVnd, required DateTime now, required DateTime horizonDate})`
  - Zero double-counting formula: allocates protected envelopes chronologically to linked bills.
  - Returns `SafeToSpendResult(safeToSpendVnd, dailyAllowanceVnd, isDeficit, breakdown)`.

### 5. `lib/core/security/encrypted_backup_service.dart`
- **Method**: `Future<String> exportBackupToJson({required AppDatabase db, required String password})`
  - Gathers all table rows
  - Calls `Isolate.run` with payload and password
  - Derives PBKDF2 key (120,000 iterations, 16-byte random salt)
  - Encrypts via `AesGcm.with256Bits` (12-byte random nonce, 16-byte MAC)
  - Returns outer JSON string with `magic: "DONGTIEN_ENC_V1"`
- **Method**: `Future<BackupValidationResult> validateAndRestoreBackup({required AppDatabase db, required String jsonContent, required String password})`
  - Verifies file size <= 25MB
  - Calls `Isolate.run` to authenticate & decrypt (throws `SecretBoxAuthenticationError` if tampered or wrong password)
  - Validates in-memory structural invariants (`SUM(debit) == SUM(credit)`, FK integrity)
  - Inside `db.transaction()`, replaces data atomically.

---

## Code Layout
```text
c:\Users\coihu12\Documents\App\
├── lib/
│   ├── app/
│   │   ├── app.dart                   # MaterialApp, Theme, vi_VN localization, Navigation shell
│   │   └── theme/
│   │       ├── app_colors.dart        # Semantic color tokens from Untitled-3.png
│   │       ├── app_typography.dart    # 7 typography scales with tabular figures
│   │       └── app_spacing.dart       # 16-step spacing scale from Spacing.png
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart      # Drift database definition, tables, migrations
│   │   │   ├── app_database.g.dart    # Generated Drift code
│   │   │   └── daos/                  # DAOs for ledger, envelopes, plans, settings
│   │   ├── money/
│   │   │   ├── vnd_money.dart         # VndMoney value type, overflow guard
│   │   │   └── vnd_formatter.dart     # vi_VN number formatting
│   │   ├── security/
│   │   │   ├── encrypted_backup_service.dart  # Isolate PBKDF2 + AES-GCM
│   │   │   └── backup_payload_models.dart     # Backup DTOs & invariants
│   │   ├── notifications/
│   │   │   └── notification_scheduler.dart    # Timezone-aware inexact reminders
│   │   └── widgets/                   # Custom numeric keypad, M3 progress bar, cards
│   ├── domain/
│   │   ├── ledger/                    # Posting engine, dynamic balance, reversal/edit
│   │   ├── envelopes/                 # Virtual fund allocation, available-to-allocate
│   │   ├── budgeting/                 # Category budgets, savings goal ceiling math, feasibility
│   │   └── forecasting/               # Safe-to-Spend formula, month-end recurrence, forecast
│   ├── features/
│   │   ├── dashboard/                 # Tổng quan screen & Riverpod controllers
│   │   ├── transactions/              # Giao dịch CRUD, quick-add modal, filters, audit history
│   │   ├── accounts/                  # Cash, Bank, Credit Card management
│   │   ├── envelopes/                 # Quỹ tiền, fund detail, allocate/transfer/release
│   │   ├── plans/                     # Kế hoạch (budgets, goals, obligations, forecast)
│   │   └── reports_settings/          # Báo cáo, Cài đặt, CSV export, backup/restore UI
│   └── main.dart
├── test/
│   ├── unit/                          # VndMoney, Safe-to-Spend, Feasibility, Crypto tests
│   ├── database/                      # Drift memory DB, FK, Posting balance, Reversals
│   └── widget/                        # Dashboard cards, keypad input, transaction filters
├── integration_test/                  # 15 mandatory acceptance scenario flows
├── maestro/                           # Declarative YAML E2E test flows
├── docs/
│   ├── ARCHITECTURE_AND_RULES.md      # Consolidated architecture, ADRs & rules
│   └── DESIGN_AND_TEST_PLAN.md        # Extracted design tokens & test matrix
└── AGENTS.md                          # Subagent invariants & file ownership rules
```
