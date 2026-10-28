# BUILD SPEC — DONGTIEN (LOCAL-FIRST PERSONAL FINANCE APP)

## 0. ROLE, OBJECTIVE & TEAMWORK EXECUTION MODEL
Act as a Principal Flutter Architect, Financial-Domain Engineer, QA Automation Lead, and Mobile Security Reviewer. Deliver a production-ready, offline-first Android personal finance application (`DongTien`) for a single user in Vietnam.

### MVP Non-Negotiables
- **Offline & Local-First**: Single user; zero accounts, backend, cloud sync, analytics, ads, AI APIs, or bank scraping.
- **Locale & Currency**: Vietnamese UI (`vi_VN`), currency `VND` stored strictly as 64-bit integers (`int`), never `double`. Device-local timezone.
- **Accounting Truth**: Double-entry general ledger (`journal_transactions` + `journal_postings`) decoupled from Virtual Funds (`envelopes` + `envelope_movements`). Virtual allocations reserve liquid cash conceptually; they never fabricate income, expense, or asset transfers.
- **End-to-End Delivery**: Produce complete runnable source code, Drift migrations, unit/DB/widget/integration/Maestro tests, `README.md`, and a verified APK. No mocked screens, disconnected buttons, or `TODO`s in financial paths.

### Antigravity Teamwork Preview — Workstream & Ownership Rules
When executing via Antigravity Teamwork Preview, partition tasks strictly by architectural layer to eliminate file lock contention and schema drift:
1. **Sequential Gate (Phase 0 & Phase 1–2 — Architect / Core Track)**:
   - Owns `pubspec.yaml`, `lib/core/database/`, `lib/domain/`, `lib/core/money/`, `lib/core/security/`, and `AGENTS.md`.
   - Must freeze and test the Drift database schema (`app_database.dart` + generated `app_database.g.dart`) and pure-Dart domain engines **before** parallel UI feature agents start.
2. **Parallel Feature Track (Phase 3–4 — UI / Feature Agents)**:
   - After Phase 2 passes all unit/DB invariants, parallelize UI features strictly across isolated directories under `lib/features/<feature_name>/`.
   - Shared theme/components in `lib/app/theme/` and `lib/core/widgets/` must be locked before spawning parallel screen implementations.
   - Feature agents must NEVER modify `lib/core/database/` or `lib/domain/` formulas without escalating to the Core Track.
3. **Verification Track (Continuous & Phase 5–6 — QA Agent)**:
   - Owns `test/unit/`, `test/database/`, `test/widget/`, `integration_test/`, and `maestro/`.
   - Runs quality gates after each phase merge.

---

## 1. WORKSPACE, TOOLCHAIN & DESIGN REFERENCE AUDIT (FIRST TASK)
1. **Inspect Workspace**: Check Git status, existing folders, and instructions. Preserve existing work.
2. **Inspect Local Design References**: Read all visual references and templates placed in `design_refs/` (or `docs/design_refs/`). Extract layout hierarchy, component patterns, color/spacing tokens, and quick-entry flows. Do NOT attempt to scrape external Figma or Play Store URLs.
3. **Audit Environment**: Run `git --version`, `flutter --version`, `dart --version`, `flutter doctor -v`, `adb version`, `adb devices`, `java -version`.
4. **Toolchain Policy**:
   - Use existing Flutter stable SDK, Android Studio bundled JDK, Android SDK Platform-Tools, and emulator images.
   - Install only missing required prerequisites without `sudo`, destructive commands, or unreviewed shell pipes.
   - Install Maestro CLI only if compatible with host OS; otherwise rely on `integration_test` on emulator and document the CLI status.
5. **Lean Documentation Output**: Instead of generating 8 separate markdown files, consolidate pre-code documentation into exactly 2 high-density files to preserve context window for code:
   - `docs/ARCHITECTURE_AND_RULES.md`: Double-entry rules, envelope linkage, Safe-to-Spend math, security/KDF spec, and ADRs.
   - `docs/DESIGN_AND_TEST_PLAN.md`: Design tokens extracted from `design_refs/`, screen map, and the 15 acceptance test matrices.
   - `AGENTS.md`: Concise project invariants and file-ownership rules for sub-agents.

---

## 2. ARCHITECTURE & DIRECTORY STRUCTURE
Enforce strict separation between UI, State (`flutter_riverpod`), Pure Domain Logic, and Persistence (`drift`). UI widgets must contain zero financial arithmetic or SQL queries.

```text
lib/
  app/
    app.dart                  # MaterialApp, localization, routing shell
    theme/                    # Design tokens (colors, typography, spacing) from design_refs/
  core/
    database/                 # Drift tables, DAOs, migrations, database provider
    money/                    # VndMoney value type, integer arithmetic guards, vi_VN formatter
    security/                 # Isolate-based AES-GCM + PBKDF2 backup encryption & staging restore
    notifications/            # Timezone-aware inexact local reminder scheduler
    widgets/                  # Reusable atomic Material 3 components
  domain/
    ledger/                   # Double-entry posting engine, account balance & reversal logic
    envelopes/                # Virtual fund allocation, spending linkage & available-to-allocate
    budgeting/                # Category period budgets, savings goal math & feasibility check
    forecasting/              # Safe-to-Spend calculator, recurrence engine & cash-flow projection
  features/
    dashboard/                # Tong quan screen & controllers
    transactions/             # Giao dich CRUD, quick-add sheet, search/filter, audit trail view
    accounts/                 # Cash, bank & credit card management
    envelopes/                # Quy tien (protected & flexible envelopes)
    plans/                    # Ke hoach: budgets, savings goals & scheduled obligations
    reports_settings/         # Financial reports, CSV export, encrypted backup/restore, settings
  main.dart
test/
  unit/                       # Pure domain math & invariant tests
  database/                   # Drift transaction, foreign-key, migration & restore tests
  widget/                     # Component & screen state tests
integration_test/             # End-to-end emulator flows
maestro/                      # Declarative E2E YAML flows
docs/
```

---

## 3. LOCKED DEPENDENCY POLICY
Verify compatibility with the active Flutter/Dart SDK before resolving. Commit `pubspec.lock`.

- **Runtime Dependencies ONLY**:
  - `flutter_riverpod`: Standard `Notifier` / `AsyncNotifier` providers (no `riverpod_generator` to avoid build_runner bottlenecks).
  - `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider`, `path`: Type-safe SQLite persistence.
  - `flutter_local_notifications`, `timezone`, `flutter_timezone`: Local scheduled notifications.
  - `intl`: `vi_VN` date and currency formatting.
  - `share_plus`, `file_picker`: User-initiated backup export/import.
  - `cryptography`: Authenticated encryption (`AesGcm.with256Bits`) and KDF (`Pbkdf2`).
- **Dev Dependencies ONLY**:
  - `flutter_test`, `integration_test` (SDK), `drift_dev`, `build_runner`, `flutter_lints`.
- **Strictly Forbidden**: `uuid`, chart libraries (use custom Material 3 progress bars/canvas), `go_router` (use clean `IndexedStack` + standard `Navigator`), `freezed`, `dio`/`http`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`.

---

## 4. DATABASE SCHEMA & DOUBLE-ENTRY LEDGER INVARIANTS (LOWEST-RISK DESIGN)

### 4.1 Monetary Representation
- Store all monetary values as `int` representing whole `VND` (e.g., `150000` = `150.000 ₫`).
- Enforce `amount > 0` on all entry commands and guard against 64-bit overflow (`max_Safe_VND = 9_000_000_000_000_000`).

### 4.2 Drift Tables & Constraints
Enable `PRAGMA foreign_keys = ON;` inside `MigrationStrategy.beforeOpen`.
1. `ledger_accounts`:
   - `id` (PK, integer autoIncrement), `name` (text), `kind` (`ASSET_CASH`, `ASSET_BANK`, `LIABILITY_CREDIT_CARD`, `INCOME`, `EXPENSE`, `EQUITY_OPENING`), `is_liquid` (bool: true only for `ASSET_CASH` and `ASSET_BANK`), `credit_limit` (int, default 0, informational only), `is_archived` (bool), `created_at` (int epoch ms).
2. `categories`:
   - `id` (PK), `name` (text), `kind` (`INCOME`, `EXPENSE`), `ledger_account_id` (FK -> `ledger_accounts.id`), `icon_code` (int), `color_hex` (text), `is_default` (bool), `is_archived` (bool).
3. `journal_transactions`:
   - `id` (PK), `tx_type` (`OPENING_BALANCE`, `INCOME`, `EXPENSE`, `TRANSFER`, `CREDIT_CARD_PAYMENT`, `REFUND`, `REVERSAL`), `status` (`POSTED`, `SUPERSEDED`, `VOIDED`), `description` (text), `occurred_at` (int epoch ms), `created_at` (int), `idempotency_key` (text unique nullable), `reverses_tx_id` (FK nullable -> `journal_transactions.id`), `replaced_by_tx_id` (FK nullable -> `journal_transactions.id`).
4. `journal_postings`:
   - `id` (PK), `transaction_id` (FK -> `journal_transactions.id`), `account_id` (FK -> `ledger_accounts.id`), `debit_vnd` (int >= 0), `credit_vnd` (int >= 0), `category_id` (FK nullable -> `categories.id`), `envelope_id` (FK nullable -> `envelopes.id`).
   - Constraint: `(debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0)`.
5. `envelopes` (Virtual Funds):
   - `id` (PK), `name` (text), `policy` (`PROTECTED`, `FLEXIBLE`), `reserved_balance_vnd` (int >= 0, derived/reconciled with movements), `allow_negative_exception` (bool, default false), `target_amount_vnd` (int nullable), `target_date_ms` (int nullable), `period_limit_vnd` (int nullable), `rollover_enabled` (bool), `priority` (int default 1), `is_archived` (bool).
6. `envelope_movements`:
   - `id` (PK), `movement_type` (`ALLOCATE`, `RELEASE`, `TRANSFER`, `SPEND`, `REFUND_RESTORE`, `REVERSAL`), `amount_vnd` (int > 0), `source_envelope_id` (FK nullable -> `envelopes.id`), `dest_envelope_id` (FK nullable -> `envelopes.id`), `linked_transaction_id` (FK nullable -> `journal_transactions.id`), `linked_obligation_id` (FK nullable -> `scheduled_items.id`), `occurred_at` (int).
7. `category_budgets`:
   - `id` (PK), `category_id` (FK -> `categories.id`), `year_month` (int, e.g., `202610`), `limit_vnd` (int > 0), `alert_threshold_pct` (int default 80). Unique index on `(category_id, year_month)`.
8. `scheduled_items` (Obligations & Planned Income):
   - `id` (PK), `kind` (`BILL`, `PLANNED_INCOME`), `title` (text), `amount_vnd` (int > 0), `due_date_ms` (int), `recurrence` (`NONE`, `WEEKLY`, `MONTHLY`, `YEARLY`), `anchor_day_of_month` (int nullable, 1..31 for drift-free month-end handling), `category_id` (FK nullable -> `categories.id`), `linked_envelope_id` (FK nullable -> `envelopes.id`), `status` (`PENDING`, `PAID_OR_RECEIVED`, `SKIPPED`), `paid_transaction_id` (FK nullable -> `journal_transactions.id`), `reminder_days_before` (int default 1).
9. `settings`:
   - Single-row configuration (`id = 1`): `minimum_cash_buffer_vnd` (int default 0), `period_start_day` (int default 1), `daily_reminder_hour` (int default 20), `daily_reminder_minute` (int default 0), `notifications_enabled` (bool default false), `schema_version` (int).

### 4.3 Double-Entry Posting Matrix & Envelope Atomic Linkage
Every write operation must execute inside a single `db.transaction(() async { ... })`. Before committing, verify `SUM(debit_vnd) == SUM(credit_vnd)` across all postings of the transaction.

| Operation | Debit (`debit_vnd`) | Credit (`credit_vnd`) | Atomic Envelope Effect (`envelope_movements`) |
| :--- | :--- | :--- | :--- |
| **Opening Balance (Asset)** | `ASSET_CASH` or `ASSET_BANK` | `EQUITY_OPENING` | None |
| **Opening Balance (Card Debt)** | `EQUITY_OPENING` | `LIABILITY_CREDIT_CARD` | None |
| **Income (Salary, etc.)** | `ASSET_CASH` or `ASSET_BANK` | `INCOME` (linked to Category) | None |
| **Cash/Bank Expense** | `EXPENSE` (linked to Category) | `ASSET_CASH` or `ASSET_BANK` | If `envelope_id != null`: insert `SPEND` (`source_envelope_id = envelope_id`) decreasing envelope balance |
| **Credit Card Purchase** | `EXPENSE` (linked to Category) | `LIABILITY_CREDIT_CARD` | If `envelope_id != null`: insert `SPEND` (`source_envelope_id = envelope_id`) decreasing envelope balance |
| **Credit Card Payment** | `LIABILITY_CREDIT_CARD` | `ASSET_CASH` or `ASSET_BANK` | None (Never counted as an expense) |
| **Internal Transfer** | Destination `ASSET_*` | Source `ASSET_*` | None |
| **Refund** | Receiving `ASSET_*` or `LIABILITY_CREDIT_CARD` | `EXPENSE` (linked to Category) | If original/selected `envelope_id != null`: insert `REFUND_RESTORE` (`dest_envelope_id = envelope_id`) |
| **Envelope Allocate / Release / Transfer** | None (Zero ledger postings) | None (Zero ledger postings) | Insert `ALLOCATE` (`dest`), `RELEASE` (`source`), or `TRANSFER` (`source` -> `dest`) |

### 4.4 Account Balance Derivation
Never store mutable cached balances on `ledger_accounts`. Derive balances via SQL aggregation over **all** `journal_postings` (since reversals offset superseded postings):
- **Asset & Expense normal balance (Debit)**: `SUM(debit_vnd) - SUM(credit_vnd)`.
- **Liability, Income & Equity normal balance (Credit)**: `SUM(credit_vnd) - SUM(debit_vnd)`.

### 4.5 Audit-Preserving Reversal & Clean UI Filtering
- **Void / Delete Transaction**: Inside a DB transaction, verify the target transaction is `POSTED`. Update target `status = VOIDED`. Insert a new `journal_transaction` (`tx_type = REVERSAL`, `status = POSTED`, `reverses_tx_id = target.id`) containing exact inverted postings (`debit <-> credit`). If the target had an `envelope_movement`, insert an offsetting `REVERSAL` movement restoring/reversing the envelope delta.
- **Edit Transaction**: Execute the Void/Reversal step above (`status = SUPERSEDED`), then insert the newly edited `journal_transaction` (`status = POSTED`) and link `replaced_by_tx_id = new_tx.id` on the original row.
- **Clean UI Rule**: Transaction lists and period category summaries query `WHERE tx.status = 'POSTED' AND tx.tx_type != 'REVERSAL'` so edited/voided pairs never clutter the user's daily view, while account balance queries sum across all postings so the ledger remains mathematically exact. Provide a "Lịch sử chỉnh sửa" (Audit History) bottom sheet on edited transactions.

---

## 5. DETERMINISTIC FINANCIAL ALGORITHMS

### 5.1 Available-to-Allocate & Virtual Fund Rules
- `total_liquid_assets = SUM(balance of ASSET_CASH and ASSET_BANK where is_liquid == true)` (Credit limits and credit card liabilities are strictly excluded).
- `total_envelope_reserves = SUM(reserved_balance_vnd of active envelopes)`.
- `available_to_allocate = total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd`.
- Block `ALLOCATE` commands if `amount > max(0, available_to_allocate)`.
- When spending from an envelope where `amount > envelope.reserved_balance_vnd`: block by default unless `allow_negative_exception == true` is explicitly confirmed by the user; if allowed, record the deficit explicitly and reduce `available_to_allocate`.

### 5.2 Category Spending, Refunds & Savings Rate
- For a given date range `[start_ms, end_ms)`:
  - `gross_expense = SUM(debit_vnd on EXPENSE accounts)`.
  - `refund_credits = SUM(credit_vnd on EXPENSE accounts)`.
  - `net_expense = gross_expense - refund_credits`.
  - `recognized_income = SUM(credit_vnd - debit_vnd on INCOME accounts)`.
- **Edge-Case Handling**:
  - If `net_expense < 0` (refunds from prior periods exceed current period gross spending), display `net_expense` clearly as a net recovery (`Thu hồi chi phí ròng`) and use `effective_expense = max(0, net_expense)` when computing `saving_rate`.
  - `net_saving = recognized_income - net_expense`.
  - If `recognized_income <= 0`, `saving_rate = null` (display `"Chưa có thu nhập"` instead of `NaN`/`Infinity`). Otherwise `saving_rate = ( recognized_income - max(0, net_expense) ) / recognized_income`.

### 5.3 Safe-to-Spend (Zero Double-Counting Formula)
Calculate Safe-to-Spend from `now` until `horizon_date` (next scheduled `PLANNED_INCOME` date, or end of current budgeting period if no income is scheduled):
$$\text{Safe-to-Spend} = \text{Liquid Assets} - \text{Protected Reserves} - \text{Unfunded Committed Outflows} - \text{Minimum Cash Buffer}$$
- `Liquid Assets`: `total_liquid_assets` (`ASSET_CASH` + `ASSET_BANK`).
- `Protected Reserves`: `SUM(max(0, reserved_balance_vnd))` of all active envelopes with `policy == PROTECTED`. (Envelopes with `policy == FLEXIBLE` are discretionary and NOT subtracted here).
- `Unfunded Committed Outflows`: For each `PENDING` `BILL` due on or before `horizon_date`:
  - If `linked_envelope_id == null`: `unfunded_amount = bill.amount_vnd`.
  - If `linked_envelope_id` points to a `PROTECTED` envelope: allocate that envelope's `reserved_balance_vnd` across its linked pending bills in chronological order; only the portion exceeding the envelope's reserved balance counts toward `Unfunded Committed Outflows` (`max(0, bill.amount_vnd - remaining_linked_envelope_balance)`). This guarantees zero double-subtraction.
  - If `linked_envelope_id` points to a `FLEXIBLE` envelope: `unfunded_amount = bill.amount_vnd` (since flexible envelopes were not subtracted in `Protected Reserves`).
- **Negative Safe-to-Spend**: Never clamp `Safe-to-Spend` to `0`. If negative, display the exact deficit in red with a breakdown of which component caused the shortfall. Daily discretionary allowance displays `0 ₫/ngày` when `Safe-to-Spend <= 0`.

### 5.4 Savings Goals & Feasibility
- Each savings goal is backed by a dedicated `PROTECTED` envelope.
- Given target $T$, current balance $C$, and remaining periods $N$:
  - If $C \ge T$: status is `ACHIEVED` (`required_per_period = 0`).
  - If $N \le 0$ and $C < T$: status is `OVERDUE` (`shortfall = T - C`, no division by zero).
  - If $N > 0$ and $C < T$: `required_per_period = ((T - C) + N - 1) ~/ N` (ceiling integer division in VND so the goal is guaranteed to be met by the deadline, with the final period taking the exact remainder).
- **Feasibility Warning**: If `SUM(required_per_period of all active goals)` exceeds `available_to_allocate` (or average monthly `net_saving`), flag as `INFEASIBLE` and offer 3 concrete one-tap calculators: (1) Extend deadline to $N'$ months, (2) Lower target $T'$, or (3) Pause lower-priority goals.

### 5.5 Month-End Recurrence & Cash-Flow Forecast
- When generating the next occurrence of a `MONTHLY` scheduled item anchored on day $d \in \{29, 30, 31\}$ for target month $(Y, M)$:
  - `actual_due_day = min(anchor_day_of_month, daysInMonth(Y, M))` (e.g., anchor `31` becomes `28`/`29` in February, and returns to `31` in March—zero date drift).
- When marking a `scheduled_item` as paid/received:
  - Create and link the real `journal_transaction` (`paid_transaction_id = tx.id`), set `status = PAID_OR_RECEIVED`, and advance/insert the next recurrence item. Never count a paid obligation as both a pending forecast outflow and a posted transaction.
- **Forecast Engine**: Project day-by-day balances for the next 30/60/90 days starting from `total_liquid_assets`, applying `PENDING` `BILL`s (labeled as committed outflows) and `PLANNED_INCOME` (labeled distinctly as estimated inflows). Highlight the exact date if projected liquid cash drops below `minimum_cash_buffer_vnd`.

---

## 6. UI/UX, DESIGN SYSTEM (`design_refs/`) & LOCAL NOTIFICATIONS

### 6.1 Design System & Navigation
- Base all color tokens, typography scale, card elevations, and spacing on the visual references inside `design_refs/`. Document the extracted palette and component rules in `docs/DESIGN_AND_TEST_PLAN.md`.
- Light-first, calm Material 3 aesthetic optimized for Vietnamese (`vi_VN`) and `VND` numbers (use tabular figures `FontFeature.tabularFigures()`, format as `1.250.000 ₫`, no decimals).
- **4 Primary Bottom Navigation Destinations**:
  1. `Tổng quan` (Dashboard): Priority order -> (1) Safe-to-Spend hero card with formula breakdown modal, (2) Spending today & this month vs budget, (3) Upcoming obligations & next planned income, (4) Protected & flexible fund progress, (5) Recent 5 transactions. Primary FAB opens Quick-Add Transaction.
  2. `Giao dịch` (Transactions): Chronological list grouped by day with daily net total, search bar, filter chips (type, account, category, envelope, date range), and account management header/drawer (`Cash`, `Bank`, `Credit Card`).
  3. `Quỹ tiền` (Virtual Funds): Summary of `Liquid Assets`, `Reserved`, and `Available to Allocate`; list of `Protected` and `Flexible` envelopes; quick Allocate / Transfer / Release actions; Fund Detail screen with movement history.
  4. `Kế hoạch` (Plans): Segmented view for (a) Monthly Category Budgets, (b) Savings Goals with feasibility advisor, and (c) Scheduled Bills & Planned Income + 30-day Cash-Flow Forecast.
- **Secondary Screens (via AppBar action on `Tổng quan` or `Kế hoạch`)**:
  - `Báo cáo` (Reports): Income, Gross Expense, Refunds, Net Expense, Transfers, Saving Rate, and Net Worth (`Total Assets - Total Liabilities`).
  - `Cài đặt & Sao lưu` (Settings & Backup): Minimum cash buffer, period boundary day, notification toggles, CSV export, Encrypted JSON Backup/Restore, and explicit "Tạo dữ liệu mẫu" / "Xóa dữ liệu" actions.
- **First-Run State**: Seed standard Vietnamese categories (`Ăn uống`, `Di chuyển`, `Hoá đơn & Tiện ích`, `Nhà cửa`, `Mua sắm`, `Y tế`, `Lương`, `Thưởng`) and required system ledger accounts (`EQUITY_OPENING`), with `0 ₫` balances and zero fake transactions.

### 6.2 Fast Transaction Entry UX
- Open with custom numeric keypad / amount input focused first, segmented selector (`Chi tiêu` | `Thu nhập` | `Chuyển khoản` | `Trả thẻ` | `Hoàn tiền`), visual category grid, source/destination account chips, and progressive disclosure for optional `Quỹ tiền (Envelope)` and `Ghi chú`.
- Attach deterministic `Semantics(identifier: ...)` labels to all primary inputs, buttons, and summary cards for automated testing.

### 6.3 Low-Risk Local Notifications (Android 12–15+ Compliant)
- **Permissions**: Declare only `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` and `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>`. Do **NOT** declare `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`.
- **Scheduling Mode**: Use `AndroidScheduleMode.inexactAllowWhileIdle`.
- **Triggers**:
  1. Daily summary reminder at user-configured `HH:mm`.
  2. Upcoming bill reminders (`due_date - reminder_days_before`) and savings goal reminders.
  3. Immediate in-app / local notification when a posted expense pushes a category budget across its `80%` or `100%` threshold.
- **Reschedule Hook**: Reconcile and reschedule pending notifications on app launch and after any obligation/setting mutation. If notification permission is denied, degrade gracefully and show a non-blocking banner in Settings.

---

## 7. SECURITY, PRIVACY & ISOLATE-BASED ENCRYPTED BACKUP

### 7.1 Android Hardening
- Store SQLite database strictly inside the app-private directory.
- Disable cloud auto-backup of raw financial files: set `android:allowBackup="false"` in `AndroidManifest.xml` and configure `res/xml/data_extraction_rules.xml` to exclude the database directory from cloud backup and device-to-device transfer.
- Never log transaction amounts, descriptions, or backup passwords to `debugPrint` / Logcat in release or profile builds.

### 7.2 Off-Main-Thread Authenticated Encryption (`Isolate.run`)
All backup encryption, decryption, KDF derivation, and JSON serialization must execute inside `await Isolate.run(() async { ... })` to prevent UI frame drops.
- **Envelope Format (`JSON` outer wrapper)**:
  ```json
  {
    "magic": "DONGTIEN_ENC_V1",
    "formatVersion": 1,
    "schemaVersion": 1,
    "createdAtIso": "2026-10-27T23:59:00+07:00",
    "kdf": "PBKDF2-HMAC-SHA256",
    "kdfIterations": 120000,
    "saltB64": "<16-byte-random-salt>",
    "cipher": "AES-256-GCM",
    "nonceB64": "<12-byte-random-nonce>",
    "ciphertextB64": "<encrypted-payload>",
    "macB64": "<16-byte-gcm-tag>"
  }
  ```
- **Validation & Atomic Restore**:
  1. Reject files larger than `25 MB`.
  2. Verify outer JSON headers, derive key via `Pbkdf2`, and authenticate/decrypt via `AesGcm.with256Bits()`. Any wrong password, modified byte, or truncated tag throws `SecretBoxAuthenticationError` and aborts before touching SQLite.
  3. Parse inner payload and validate structural invariants in memory: every transaction's postings satisfy `SUM(debit) == SUM(credit)`, all foreign keys resolve, and all amounts are non-negative integers.
  4. Require explicit user confirmation dialog showing backup timestamp and record counts.
  5. Inside a single exclusive `db.transaction()`, clear existing tables and insert validated records. If any SQL error occurs, roll back automatically so existing data remains intact.

---

## 8. PHASED EXECUTION & AUTOMATED QUALITY GATES

Execute sequentially across Phases 0–2, parallelize UI slices in Phase 3–4 if using Teamwork Preview, and converge in Phase 5–6:
- **Phase 0 — Audit & Spec Lock**: Audit workspace, toolchain, and `design_refs/`. Write `AGENTS.md`, `docs/ARCHITECTURE_AND_RULES.md`, and `docs/DESIGN_AND_TEST_PLAN.md`.
- **Phase 1 — Scaffold & Core Infrastructure**: Initialize Flutter project, configure `pubspec.yaml`, implement `VndMoney`, and build Drift schema + code generation (`dart run build_runner build --delete-conflicting-outputs`).
- **Phase 2 — Domain Engines & DB Invariant Tests**: Implement double-entry ledger service, reversal/edit engine, envelope movement service, Safe-to-Spend, goal math, and recurrence forecast. **Gate**: Pass 100% of unit and database invariant tests before starting UI.
- **Phase 3 — Design System & Core Feature Slices**: Implement theme tokens from `design_refs/`, navigation shell, `Tổng quan` (Dashboard), `Giao dịch` (Transactions + Accounts), and `Quỹ tiền` (Envelopes).
- **Phase 4 — Plans, Reports, Notifications & Backup**: Implement `Kế hoạch` (Budgets, Goals, Obligations, Forecast), `Báo cáo`, `Cài đặt`, Isolate-based Encrypted Backup/Restore, CSV export, and local reminders.
- **Phase 5 — Automated Acceptance & E2E Hardening**: Execute all 15 acceptance scenarios below plus edge cases.

### Required Acceptance Scenarios (Must Assert Exact Values in Automated Tests)
1. **Opening Asset (`10.000.000 ₫`)**: Liquid asset = `10.000.000 ₫`; operating income = `0 ₫`.
2. **Salary (`20.000.000 ₫`)**: Liquid asset = `30.000.000 ₫`; recognized income = `20.000.000 ₫`.
3. **Cash Expense (`100.000 ₫`)**: Liquid asset = `29.900.000 ₫`; net expense = `100.000 ₫`.
4. **Internal Transfer (`2.000.000 ₫`)**: Total liquid assets unchanged (`29.900.000 ₫`); income/expense unchanged.
5. **Virtual Fund Allocation (`1.000.000 ₫` to Protected Fund)**: Actual liquid assets (`29.900.000 ₫`) and net expense (`100.000 ₫`) unchanged; protected reserve = `1.000.000 ₫`; Safe-to-Spend decreases by `1.000.000 ₫`.
6. **Credit-Card Purchase (`500.000 ₫`)**: Net expense increases by `500.000 ₫`; card liability = `500.000 ₫`; liquid assets unchanged (`29.900.000 ₫`).
7. **Credit-Card Payment (`500.000 ₫`)**: Liquid assets decrease by `500.000 ₫`; card liability = `0 ₫`; net expense does NOT increase.
8. **Refund (`50.000 ₫`)**: Receiving asset increases (or card liability decreases) by `50.000 ₫`; net expense decreases by `50.000 ₫` (and linked envelope restores `50.000 ₫` if applicable).
9. **Edit & Void Transaction**: Reversal postings balance `SUM(debit) == SUM(credit)`; account balances, reports, and envelope reserves reconcile; default UI list hides superseded/reversal noise.
10. **Duplicate Submission Guard**: Submitting identical `idempotency_key` twice creates exactly one transaction.
11. **Scheduled Bill (`1.500.000 ₫`) & Payment**: Before payment, deducted in Safe-to-Spend (respecting linked protected envelope without double subtraction). After marking paid, linked to real expense transaction and never counted twice.
12. **Negative Safe-to-Spend**: When protected reserves + unfunded bills + buffer exceed liquid assets, exact negative VND shortfall and breakdown are returned and rendered.
13. **Encrypted Backup & Restore Round-Trip**: Export encrypted backup, wipe/reset state, restore with password -> all account balances, postings, envelopes, budgets, and obligations match pre-wipe state.
14. **Tampered Backup / Wrong Password**: Flip 1 byte in `ciphertextB64` or `macB64` or pass wrong password -> restore rejects safely inside Isolate and leaves existing SQLite data untouched.
15. **Notification Permission Denied & Month-End Recurrence**: App remains fully functional when `POST_NOTIFICATIONS` is denied; a monthly bill anchored on day `31` schedules on `28/29 Feb` and returns to `31 Mar` without drift.

### Mandatory Final Verification Commands
Run and record exact output in the final delivery report:
```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
flutter build apk --debug
```
If an Android emulator is active, also run `flutter test integration_test` and any `maestro test maestro/` flows, capturing verification evidence.
