# Original User Request

## Initial Request — 2026-10-27T10:03:08Z

Build `DongTien`, a production-ready, offline-first Android personal finance application in Flutter (`vi_VN` locale, integer `VND` currency) featuring a double-entry general ledger decoupled from virtual funds (envelopes), deterministic Safe-to-Spend & forecasting algorithms, a Material 3 UI based on local design references, and isolate-based AES-256-GCM encrypted backup/restore.

Working directory: c:\Users\coihu12\Documents\App
Integrity mode: development

Reference specification & design assets:
- Full build specification: `c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md`
- Visual design references: `c:\Users\coihu12\Documents\App\docs\design_refs\` (`budget.png`, `invest.png`, `savings.png`, `Spacing.png`, `Untitled.png`, `Untitled-1.png`, `Untitled-2.png`, `Untitled-3.png`, `wallet.png`)

## Requirements

### R1. Audit, Toolchain & Lean Documentation (`Phase 0`)
Inspect the workspace (`c:\Users\coihu12\Documents\App`), audit the local environment (`git`, `flutter`, `dart`, `flutter doctor -v`, `adb`, `java`), and inspect all visual references in `docs/design_refs/`. Consolidate pre-code documentation into:
- `AGENTS.md`: Concise project invariants and file-ownership rules.
- `docs/ARCHITECTURE_AND_RULES.md`: Double-entry rules, envelope linkage, Safe-to-Spend math, security/KDF spec, and ADRs.
- `docs/DESIGN_AND_TEST_PLAN.md`: Design tokens extracted from `docs/design_refs/`, screen map, and the 15 acceptance test matrices.

### R2. Architecture, Locked Dependencies & Double-Entry Drift Database (`Phase 1`)
Enforce strict separation between UI, State (`flutter_riverpod` standard `Notifier`/`AsyncNotifier`), Pure Domain Logic (`lib/domain/`), and Persistence (`drift` in `lib/core/database/`).
- Use only the locked dependencies specified in Section 3 of `build_spec/dongtien_build_spec.md` (`flutter_riverpod`, `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider`, `path`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `intl`, `share_plus`, `file_picker`, `cryptography`; dev: `flutter_test`, `integration_test`, `drift_dev`, `build_runner`, `flutter_lints`). Do not use forbidden packages (`uuid`, chart libraries, `go_router`, `freezed`, `dio`/`http`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`).
- Store all monetary values as 64-bit integers (`int`) in whole `VND` (`VndMoney` value type, `max_Safe_VND = 9_000_000_000_000_000`).
- Implement all 9 Drift tables with `PRAGMA foreign_keys = ON`: `ledger_accounts`, `categories`, `journal_transactions`, `journal_postings`, `envelopes`, `envelope_movements`, `category_budgets`, `scheduled_items`, and `settings`.
- Seed default Vietnamese categories (`Ăn uống`, `Di chuyển`, `Hoá đơn & Tiện ích`, `Nhà cửa`, `Mua sắm`, `Y tế`, `Lương`, `Thưởng`) and required system ledger accounts (`EQUITY_OPENING`) on first run with `0 ₫` balances and zero fake transactions.

### R3. Deterministic Financial Domain Engines (`Phase 2`)
Implement and unit-test all pure domain and database services in `lib/domain/`:
- **Double-Entry Posting & Atomic Envelope Linkage**: Every write executes inside a single `db.transaction()`, verifying `SUM(debit_vnd) == SUM(credit_vnd)` and atomically writing any linked `envelope_movements` (`ALLOCATE`, `RELEASE`, `TRANSFER`, `SPEND`, `REFUND_RESTORE`, `REVERSAL`) per the Posting Matrix in Section 4.3.
- **Account Balance Derivation**: Never store mutable cached balances on `ledger_accounts`; derive Asset/Expense (`SUM(debit) - SUM(credit)`) and Liability/Income/Equity (`SUM(credit) - SUM(debit)`) across all postings.
- **Audit-Preserving Reversal & Edit Engine**: Voiding/deleting marks `status = VOIDED` and inserts a `REVERSAL` transaction with inverted postings and offsetting envelope movements. Editing marks `status = SUPERSEDED`, inserts a `REVERSAL`, and inserts the new `POSTED` transaction (`replaced_by_tx_id`). Default UI lists filter `status = 'POSTED' AND tx_type != 'REVERSAL'`, while providing an Audit History ("Lịch sử chỉnh sửa") sheet.
- **Available-to-Allocate & Virtual Fund Rules**: `available_to_allocate = total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd`. Block over-allocation and block envelope overspending unless `allow_negative_exception == true` is confirmed.
- **Category Spending, Refunds & Savings Rate**: Handle net recovery (`net_expense < 0` -> `"Thu hồi chi phí ròng"`) and zero income (`recognized_income <= 0` -> `"Chưa có thu nhập"`, never `NaN`/`Infinity`).
- **Safe-to-Spend (Zero Double-Counting Formula)**: `Liquid Assets - Protected Reserves - Unfunded Committed Outflows - Minimum Cash Buffer`. Allocate a `PROTECTED` envelope's balance across its linked pending bills chronologically so only the unfunded excess is subtracted. Never clamp negative Safe-to-Spend to `0`; display exact deficit in red with breakdown (`0 ₫/ngày` daily allowance when `<= 0`).
- **Savings Goals & Feasibility Advisor**: Ceiling integer division `((T - C) + N - 1) ~/ N`, status (`ACHIEVED`, `OVERDUE`, `INFEASIBLE`), and 3 one-tap calculators (extend deadline, lower target, pause lower-priority goals).
- **Month-End Recurrence & 30/60/90-Day Cash-Flow Forecast**: Anchor day `1..31` with `min(anchor_day_of_month, daysInMonth(Y, M))` so day 31 becomes Feb 28/29 and returns to Mar 31 without drift. Project daily balances and highlight dates dropping below `minimum_cash_buffer_vnd`.

### R4. UI/UX Feature Slices, Design System & Local Notifications (`Phase 3 & Phase 4`)
Implement a light-first Material 3 UI (`vi_VN`, tabular numerals `FontFeature.tabularFigures()`, `1.250.000 ₫` formatting) matching the tokens in `docs/design_refs/` with `Semantics(identifier: ...)` on primary interactive and summary elements:
- **4 Bottom Navigation Tabs** (`IndexedStack` + standard `Navigator`):
  1. `Tổng quan` (Dashboard): Safe-to-Spend hero card + formula breakdown modal, today/monthly spending vs budget, upcoming obligations & next planned income, protected & flexible fund progress, recent 5 transactions, and Quick-Add FAB.
  2. `Giao dịch` (Transactions & Accounts): Day-grouped list with daily net total, search bar, filter chips (type, account, category, envelope, date range), Audit History sheet, Quick-Add modal with custom numeric keypad & segmented selector (`Chi tiêu` | `Thu nhập` | `Chuyển khoản` | `Trả thẻ` | `Hoàn tiền`), and Account management (`Cash`, `Bank`, `Credit Card`).
  3. `Quỹ tiền` (Virtual Funds): Summary of `Liquid Assets`, `Reserved`, and `Available to Allocate`; `Protected` and `Flexible` envelopes list; quick Allocate / Transfer / Release actions; Fund Detail screen with movement history.
  4. `Kế hoạch` (Plans): Segmented view for (a) Monthly Category Budgets, (b) Savings Goals with feasibility advisor, and (c) Scheduled Bills & Planned Income + 30/60/90-day Cash-Flow Forecast.
- **Secondary Screens**:
  - `Báo cáo` (Reports): Income, Gross Expense, Refunds, Net Expense, Transfers, Saving Rate, and Net Worth (`Total Assets - Total Liabilities`).
  - `Cài đặt & Sao lưu` (Settings & Backup): Minimum cash buffer, period boundary day, notification toggles, CSV export, Encrypted JSON Backup/Restore, and explicit "Tạo dữ liệu mẫu" / "Xóa dữ liệu" actions.
- **Compliant Local Notifications**: Declare only `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` (no exact alarm permissions), schedule via `AndroidScheduleMode.inexactAllowWhileIdle`, trigger daily summary, upcoming bill/goal reminders, and `80%`/`100%` budget threshold alerts, and degrade gracefully if permission is denied.

### R5. Android Hardening & Isolate-Based Encrypted Backup/Restore (`Phase 4`)
- Set `android:allowBackup="false"` in `AndroidManifest.xml` and configure `res/xml/data_extraction_rules.xml` to exclude the SQLite database directory.
- Implement off-main-thread backup & restore inside `Isolate.run` using outer JSON envelope `"magic": "DONGTIEN_ENC_V1"`, `PBKDF2-HMAC-SHA256` (`120000` iterations, 16-byte random salt), and `AES-256-GCM` (12-byte random nonce, 16-byte GCM MAC tag).
- Enforce `25 MB` max file size, authenticate/decrypt before touching SQLite, validate inner payload invariants in memory (`SUM(debit) == SUM(credit)`, FKs, non-negative integers), require user confirmation dialog with timestamp & record counts, and restore atomically inside a single `db.transaction()`.

## Acceptance Criteria

### Automated Invariant & Scenario Suite (15 Mandatory Scenarios)
- [ ] **Scenario 1 — Opening Asset (`10.000.000 ₫`)**: Liquid asset = `10.000.000 ₫`; operating income = `0 ₫`.
- [ ] **Scenario 2 — Salary (`20.000.000 ₫`)**: Liquid asset = `30.000.000 ₫`; recognized income = `20.000.000 ₫`.
- [ ] **Scenario 3 — Cash Expense (`100.000 ₫`)**: Liquid asset = `29.900.000 ₫`; net expense = `100.000 ₫`.
- [ ] **Scenario 4 — Internal Transfer (`2.000.000 ₫`)**: Total liquid assets unchanged (`29.900.000 ₫`); income/expense unchanged.
- [ ] **Scenario 5 — Virtual Fund Allocation (`1.000.000 ₫` to Protected Fund)**: Actual liquid assets (`29.900.000 ₫`) and net expense (`100.000 ₫`) unchanged; protected reserve = `1.000.000 ₫`; Safe-to-Spend decreases by `1.000.000 ₫`.
- [ ] **Scenario 6 — Credit-Card Purchase (`500.000 ₫`)**: Net expense increases by `500.000 ₫`; card liability = `500.000 ₫`; liquid assets unchanged (`29.900.000 ₫`).
- [ ] **Scenario 7 — Credit-Card Payment (`500.000 ₫`)**: Liquid assets decrease by `500.000 ₫`; card liability = `0 ₫`; net expense does NOT increase.
- [ ] **Scenario 8 — Refund (`50.000 ₫`)**: Receiving asset increases (or card liability decreases) by `50.000 ₫`; net expense decreases by `50.000 ₫` (and linked envelope restores `50.000 ₫` if applicable).
- [ ] **Scenario 9 — Edit & Void Transaction**: Reversal postings balance `SUM(debit) == SUM(credit)`; account balances, reports, and envelope reserves reconcile; default UI list hides superseded/reversal noise.
- [ ] **Scenario 10 — Duplicate Submission Guard**: Submitting identical `idempotency_key` twice creates exactly one transaction.
- [ ] **Scenario 11 — Scheduled Bill (`1.500.000 ₫`) & Payment**: Before payment, deducted in Safe-to-Spend (respecting linked protected envelope without double subtraction). After marking paid, linked to real expense transaction and never counted twice.
- [ ] **Scenario 12 — Negative Safe-to-Spend**: When protected reserves + unfunded bills + buffer exceed liquid assets, exact negative VND shortfall and breakdown are returned and rendered.
- [ ] **Scenario 13 — Encrypted Backup & Restore Round-Trip**: Export encrypted backup, wipe/reset state, restore with password -> all account balances, postings, envelopes, budgets, and obligations match pre-wipe state.
- [ ] **Scenario 14 — Tampered Backup / Wrong Password**: Flip 1 byte in `ciphertextB64` or `macB64` or pass wrong password -> restore rejects safely inside Isolate and leaves existing SQLite data untouched.
- [ ] **Scenario 15 — Notification Permission Denied & Month-End Recurrence**: App remains fully functional when `POST_NOTIFICATIONS` is denied; a monthly bill anchored on day `31` schedules on `28/29 Feb` and returns to `31 Mar` without drift.

### Build, Lint, Format & Verification Gates
- [ ] `AGENTS.md`, `docs/ARCHITECTURE_AND_RULES.md`, `docs/DESIGN_AND_TEST_PLAN.md`, and `README.md` exist and are complete.
- [ ] `dart format --output=none --set-exit-if-changed .` exits with code 0.
- [ ] `flutter analyze` exits with code 0 (zero issues).
- [ ] `flutter test --coverage` passes 100% of unit, database, and widget tests covering all 15 acceptance scenarios.
- [ ] `flutter build apk --debug` succeeds and produces a verified APK.
- [ ] Integration tests (`integration_test/`) and Maestro flows (`maestro/`) are written, and executed if an emulator is available.
