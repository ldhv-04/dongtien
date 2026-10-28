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


## 2026-10-28T00:39:16Z

Fix and optimize the **Đồng Tiền** (`vn.dongtien`) offline-first Android personal finance app across four areas: (1) convert scheduled bills and planned income to strictly single-payment one-off items with confirmation dialogs, completed history state, and anti-double-tap protection, (2) fix and thoroughly verify Android 14 on-screen push notifications (`POST_NOTIFICATIONS` runtime permission, local timezone initialization, budget alert triggers, and an in-app test notification button), (3) fix the `SqliteException(1)` crash when creating category budgets (`"POSTED"` double-quoted identifier bug in SQLite `customSelect`), and (4) optimize database query performance (eliminating N+1 and full-table memory scans) and reduce APK installation size from ~104 MB to lean release builds (~18–22 MB per ABI) and install onto the running Android 14 emulator.

Working directory: `c:\Users\coihu12\Documents\App`
Integrity mode: `development`

## Requirements

### R1. Single-Payment Bills & Planned Income + Anti-Double-Tap UX
- Every bill (`BILL`) or planned income (`PLANNED_INCOME`) added by the user must be a single-occurrence item (`recurrence = 'NONE'`) that can be paid or received **at most once**. Remove recurrence selector chips from the Add Scheduled Item modal so every created item is strictly one-time (if a new bill/income arises later, the user creates a new item), and allow selecting the due date via a date picker.
- When the user taps **`Đã trả`** or **`Đã nhận`** (either in the Plans -> Obligations tab or on the Dashboard Upcoming Obligations card), show a confirmation dialog before executing payment. Once confirmed and paid, move the item to a **"Lịch sử đã thanh toán / Đã nhận"** section on the Obligations view with a permanently disabled **`Đã hoàn tất`** button so it can never be tapped again, and enforce a deterministic `idempotencyKey` (`scheduled_pay_<id>`) in `markScheduledItemPaid` so duplicate ledger transactions are impossible.
- Add `_isSubmitting` / in-flight tap guards across all submission modals (`_AddScheduledItemModal`, `_SetBudgetModal`, `QuickAddModal`, envelope modals) and `CustomKeypad` Done actions so rapid multiple taps never trigger duplicate database writes or multiple `Navigator.pop()` calls.

### R2. On-Screen Notification Delivery & Verification
- Update `NotificationScheduler` (`lib/core/notifications/notification_scheduler.dart`) to initialize the device's real local timezone via `flutter_timezone` (`tz.setLocalLocation`, with fallback to `Asia/Ho_Chi_Minh`) and request Android 13/14+ runtime `POST_NOTIFICATIONS` permission via `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`.
- Expose a shared Riverpod provider for `NotificationScheduler`, wire automatic scheduling/alerting when notifications are toggled in Settings, when scheduled bills are added/paid, and when an expense causes a category budget to cross 80% or 100%, and add a **"Gửi thông báo kiểm tra ngay"** (`Semantics` identifier `btn_test_notification`) button in `SettingsScreen` that fires an immediate high-priority on-screen notification banner.

### R3. Fix `SqliteException(1)` on Category Budget Creation
- Fix the SQLite query failure in `currentMonthlyBudgetSummaryProvider` (`lib/features/dashboard/presentation/providers/dashboard_providers.dart`) where `AND t.status = "POSTED"` uses double quotes (rejected by SQLite `SQLITE_DQS=0` as `SqliteException(1): no such column: POSTED`) by using single-quoted string literals `'POSTED'` and `'REVERSAL'`.
- Audit all raw SQL queries (`customSelect`, `customUpdate`, `customStatement`) across the codebase to ensure single-quoted string literals and accurate transaction status filtering.

### R4. System Query Optimization & APK Size Reduction
- Replace the N+1 query loop in `currentMonthlyBudgetSummaryProvider` with a single aggregated SQLite `JOIN ... GROUP BY` query, and replace the full-table `db.select(db.journalPostings).get()` memory load in `reportsSummaryProvider` with bounded SQLite queries.
- Configure `android/app/build.gradle` and `android/app/proguard-rules.pro` with R8 code shrinking (`minifyEnabled true`) and resource shrinking (`shrinkResources true`), build split-per-ABI release APKs (`flutter build apk --release --split-per-abi --tree-shake-icons`) so the installable APK size drops from ~104 MB to ~16–22 MB (`app-arm64-v8a-release.apk` for physical phones and `app-x86_64-release.apk` for the PC Android 14 emulator), update `Launch_DongTien_Emulator.bat`, and if the `DongTien_Pixel_API34` emulator is connected via `adb`, install the new APK onto it.

## Verification Resources
- Existing project rules & invariants: `c:\Users\coihu12\Documents\App\AGENTS.md`
- Existing test suite: `test/unit/`, `test/database/`, `test/widget/`
- Toolchain environment variables required on this Windows machine:
  - `$env:JAVA_HOME = "C:\Users\coihu12\jdk17"`
  - `$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"`
  - Prepend `C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools` to `$env:Path`.

## Acceptance Criteria

### Bug Fixes & Functional Verification
- [ ] Creating and updating any category budget in `CategoryBudgetsView` / `PlansController.upsertCategoryBudget` succeeds with zero `SqliteException(1)` errors, and `currentMonthlyBudgetSummaryProvider` streams the updated budget summary in a single SQLite query.
- [ ] Every newly created bill or planned income has `recurrence == 'NONE'`, requires confirmation before marking paid/received, transitions to `PAID_OR_RECEIVED` without spawning any new recurring row, and appears in the completed history section with a disabled button.
- [ ] Rapid double-tapping on payment buttons or modal submit buttons is blocked by in-flight submission guards and idempotency keys, producing at most 1 database record.
- [ ] `NotificationScheduler` requests Android runtime notification permission, initializes local timezone, triggers immediate notifications via the Settings test button and budget threshold alerts (80%/100%), and passes unit/widget tests.

### Quality Gates & APK Size Optimization
- [ ] `dart format --output=none --set-exit-if-changed .` exits with code 0.
- [ ] `flutter analyze` exits with code 0 (zero issues).
- [ ] `flutter test` passes 100% of existing and newly added tests.
- [ ] `flutter build apk --release --split-per-abi --tree-shake-icons` succeeds and produces `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` and `build/app/outputs/flutter-apk/app-x86_64-release.apk`, each under 30 MB (down from 104 MB).


## 2026-10-28T18:36:33Z

Fix three critical functional bugs in the **Đồng Tiền** (`vn.dongtien`) offline-first Android personal finance application and produce an updated split-ABI release APK:
1. **Resolve Scheduled Obligations (`BILL` / `PLANNED_INCOME`) vs. Category Budgets (`Ngân sách`) & Envelopes (`Quỹ tiền`) conflict (Option B)**: Allow explicit category selection when creating/editing scheduled bills and planned income (defaulting to `Hoá đơn & Tiện ích` for `BILL` and `Lương` for `PLANNED_INCOME`), remove the broken `cats.first.id` (`Ăn uống`) fallback in `PlansController.markScheduledItemPaid`, and ensure paying a bill (e.g., 3,500,000 ₫ rent) ONLY affects its explicitly selected category and NEVER deducts from an unrelated category budget or unlinked virtual fund envelope (e.g., 3,000,000 ₫ `Ăn uống`).
2. **Add unified Edit (`Sửa`) & Delete (`Xóa`) capabilities** across all item widgets created on the Financial Plans (`Kế hoạch tài chính`) screen (Category Budgets, Savings Goals, and Scheduled Bills/Planned Income — including atomic ledger reversal if a completed obligation is edited or deleted).
3. **Synchronize `periodStartDay` (`Ngày bắt đầu chu kỳ tháng`)** from `Cài đặt & Sao lưu` across the Dashboard (`Tổng quan`), Category Budgets (`Ngân sách`), Safe-to-Spend horizon, Notifications, and Reports (`Báo cáo`) so custom billing cycles (days 1–28) take effect immediately everywhere.

Working directory: `c:\Users\coihu12\Documents\App`
Integrity mode: `development`

## Environment & Toolchain Notes
When running Flutter, Dart, Gradle, or ADB commands on this Windows machine, always configure environment variables in the shell session:
- `$env:JAVA_HOME = "C:\Users\coihu12\jdk17"`
- `$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"`
- `$env:ANDROID_SDK_ROOT = "C:\Users\coihu12\Android\Sdk"`
- `$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path`
Read and strictly obey all architectural invariants in `c:\Users\coihu12\Documents\App\AGENTS.md`.

## Requirements

### R1. Explicit Category Selection & Isolation for Scheduled Obligations (`Hoá đơn & Thu nhập`) vs. Category Budgets (`Ngân sách`) & Envelopes (`Quỹ tiền`) — Option B
Currently:
- `_AddScheduledItemModal` in `lib/features/plans/presentation/widgets/obligations_forecast_view.dart` does not let the user pick a `categoryId` (`categoryId` is left `null`).
- `PlansController.markScheduledItemPaid` in `lib/features/plans/presentation/providers/plans_providers.dart` falls back to `cats.first.id` when `item.categoryId == null`. Because the first seeded `EXPENSE` category in `app_database.dart` is `Ăn uống` (Food), paying ANY scheduled bill (e.g., `Tiền nhà 3.500.000 ₫`) posts an `EXPENSE` transaction under `Ăn uống`, which immediately deducts `3.500.000 ₫` from the user's `Ăn uống` Category Budget (`3.000.000 ₫`)!

**Required Fix (Option B)**:
1. **Explicit Category Picker in Scheduled Item Modal**:
   - In `_AddScheduledItemModal` (and when editing a scheduled item) in `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`, display a clear Category selector (`Danh mục`) filtered by kind (`EXPENSE` categories when `_kind == 'BILL'`, `INCOME` categories when `_kind == 'PLANNED_INCOME'`).
   - Default the selected category for `BILL` to `Hoá đơn & Tiện ích` (or `Nhà cửa` if `Hoá đơn & Tiện ích` is absent, NEVER `Ăn uống` by silent fallback), and for `PLANNED_INCOME` to `Lương`.
   - Pass the selected `categoryId` to `createScheduledItem` / `updateScheduledItem` and display the category name on each scheduled item card in `ObligationsForecastView` and `UpcomingObligationsCard`.
2. **Eliminate Silent `cats.first` Fallback in `markScheduledItemPaid`**:
   - In `PlansController.markScheduledItemPaid`, if an existing legacy scheduled item has `categoryId == null`, resolve the default category for `BILL` specifically to `Hoá đơn & Tiện ích` (matching `c.name == 'Hoá đơn & Tiện ích'`), NEVER `cats.first` (`Ăn uống`).
   - Ensure paying a scheduled bill ONLY records expense spending against its explicitly assigned `categoryId` (and ONLY deducts from a virtual fund envelope if `linkedEnvelopeId` was explicitly chosen by the user; default `linkedEnvelopeId` is `null` / `Không liên kết quỹ`).
   - Thus, creating a `Tiền nhà 3.500.000 ₫` bill (under `Nhà cửa` or `Hoá đơn & Tiện ích`) and a `3.000.000 ₫` `Ăn uống` budget (or `Ăn uống` envelope) and marking the bill `Đã trả` will leave `Ăn uống` spent at `0 ₫` (and `Ăn uống` envelope untouched).

### R2. Full Edit (`Sửa`) & Delete (`Xóa`) Support Across All Widgets on the Financial Plans (`Kế hoạch tài chính`) Screen
Every item widget created on the `Kế hoạch tài chính` screen (`lib/features/plans/`) must have clear, accessible **Edit (`Sửa`)** and **Delete (`Xóa`)** actions with confirmation dialogs before deletion and `_isSubmitting` double-tap guards:
1. **Tab 0 — Ngân sách (`CategoryBudgetsView` & `PlansController`)**:
   - Add `deleteCategoryBudget(int categoryId, {int? yearMonth})` in `PlansController`.
   - On each active budget card (`card_budget_<categoryId>`) and inside `_SetBudgetModal`, provide both **Edit (`Sửa`)** (to change the category budget limit) and **Delete (`Xóa`)** (with confirmation dialog to remove the budget limit for that category, plus `Semantics` identifiers `btn_edit_budget_<categoryId>` and `btn_delete_budget_<categoryId>`).
2. **Tab 1 — Mục tiêu (`SavingsGoalsView` & `PlansController`)**:
   - Add `updateSavingsGoal` and `deleteSavingsGoal` in `PlansController` (or reuse/enhance `EnvelopeFormModal` and `EnvelopeDao`: if the envelope has `reservedBalanceVnd > 0`, deleting the goal/envelope releases its reserved balance back to available liquid cash before archiving/deleting or clearing its target, with a clear confirmation dialog).
   - On each goal card (`card_goal_<id>`), provide **Edit (`Sửa`)** (`btn_edit_goal_<id>`, opening `EnvelopeFormModal` pre-populated with the existing envelope/goal data so name, target amount, target date, policy, and priority can be edited) and **Delete (`Xóa`)** (`btn_delete_goal_<id>`, with confirmation dialog).
3. **Tab 2 — Nghĩa vụ & Dự báo (`ObligationsForecastView`, `UpcomingObligationsCard`, & `PlansController`)**:
   - Add `updateScheduledItem(...)` and `deleteScheduledItem(int scheduledItemId)` in `PlansController`.
   - Support editing and deleting **both `PENDING` items and `PAID_OR_RECEIVED` history items**:
     - For `PENDING` items: `updateScheduledItem` updates title, kind, amountVnd, dueDate, categoryId, and linkedEnvelopeId, and reconciles notifications. `deleteScheduledItem` deletes the row and reconciles notifications.
     - For `PAID_OR_RECEIVED` items:
       - If deleted (`deleteScheduledItem`): atomically void/reverse its linked ledger transaction (`paidTransactionId`) via `ledgerDao.voidTransaction` (which posts an audit-preserving `REVERSAL` transaction and restores any linked envelope `SPEND` movement back to `envelopes.reserved_balance_vnd`), then delete the `scheduled_items` row.
       - If edited (`updateScheduledItem`): atomically void/reverse the old `paidTransactionId` via `ledgerDao.voidTransaction` and post the updated transaction (with a fresh deterministic idempotency key such as `'scheduled_pay_${item.id}_rev_${nowMs}'`) so account balances, category budgets, and envelope balances reflect the edited amount/category/kind accurately.
   - Expose clear Edit (`btn_edit_obligation_<id>`) and Delete (`btn_delete_obligation_<id>`) buttons on every scheduled item card in `ObligationsForecastView` (both pending and completed sections) and allow editing/deleting from `UpcomingObligationsCard` on the Dashboard.

### R3. Synchronize Monthly Cycle Start Day (`periodStartDay`) Across Dashboard, Plans, Notifications, and Reports
Currently, `setting.periodStartDay` (1–28) in `Settings` can be updated in `Cài đặt & Sao lưu`, but `DashboardScreen`, `currentMonthlyBudgetSummaryProvider`, `safeToSpendProvider`, `PlansController.upsertCategoryBudget`, `NotificationScheduler.checkCategoryBudgetAlert`, and `reportsSummaryProvider` all hardcode calendar month boundaries `DateTime(now.year, now.month, 1)`.
1. **Pure Domain Billing Cycle Calculator**:
   - Create a pure Dart utility in `lib/domain/budgeting/billing_cycle_calculator.dart` (zero Flutter/Drift imports) that given `(DateTime referenceDate, int periodStartDay)` computes:
     - `cycleStart`: Exact start `DateTime` of the current billing cycle containing `referenceDate` (at `00:00:00.000`). For example, if `periodStartDay = 15`:
       - When `referenceDate` is Oct 29, 2026 (`day >= 15`), the active cycle is **Oct 15, 2026 00:00:00** to **Nov 15, 2026 00:00:00** (exclusive), or inclusive end **Nov 14, 2026 23:59:59.999**, with cycle `yearMonth = 202610`.
       - When `referenceDate` is Oct 10, 2026 (`day < 15`), the active cycle is **Sep 15, 2026 00:00:00** to **Oct 15, 2026 00:00:00** (exclusive), with cycle `yearMonth = 202609`.
     - `cycleEndExclusive` & `cycleEndInclusive`: Exact end `DateTime` of the active billing cycle.
     - `yearMonth`: Deterministic `YYYYMM` integer identifier for the cycle (`cycleStart.year * 100 + cycleStart.month`).
     - Formatted Vietnamese cycle label (e.g., `15/10/2026 – 14/11/2026` or short `15/10 – 14/11`) for UI display.
2. **Wire All Providers & UI to `periodStartDay`**:
   - `currentMonthlyBudgetSummaryProvider` (`dashboard_providers.dart`): Reactively watch `settingsStreamProvider` (or `db.select(db.settings).watchSingle()`), compute `[cycleStart, cycleEndExclusive)` and `yearMonth` via `BillingCycleCalculator`, and query `category_budgets` and `journal_transactions` for that cycle window. Ensure `readsFrom` includes `db.settings`, `db.categoryBudgets`, `db.categories`, `db.journalPostings`, and `db.journalTransactions`. Also gracefully match `category_budgets` rows where `b.year_month IN (activeCycleYearMonth, calendarYearMonth)` (deduplicated by `category_id` preferring `activeCycleYearMonth`) so budgets created before changing `periodStartDay` remain visible immediately!
   - `PlansController.upsertCategoryBudget` & `deleteCategoryBudget` (`plans_providers.dart`) and `NotificationScheduler.checkCategoryBudgetAlert` (`notification_scheduler.dart`): Read `setting.periodStartDay` from `db.settings` and use `BillingCycleCalculator` so created/deleted budgets and threshold alerts use the exact same cycle window and `yearMonth`.
   - `safeToSpendProvider` (`safe_to_spend_provider.dart`): When `nextIncome == null`, use the active billing cycle's `cycleEndInclusive` (derived from `setting.periodStartDay` via `BillingCycleCalculator`) instead of hardcoded calendar month-end `DateTime(now.year, now.month + 1, 0)`.
   - `SpendingVsBudgetCard` (Dashboard) and `CategoryBudgetsView` (Plans): Display the active billing cycle date range (e.g. `Chu kỳ: DD/MM – DD/MM`) with `FontFeature.tabularFigures()` so the user immediately sees the synchronized period on the Dashboard (`Tổng quan`) and Plans (`Kế hoạch`) screens after changing `Ngày bắt đầu chu kỳ tháng` in `Cài đặt & Sao lưu`.
   - `reportsSummaryProvider` (`reports_settings_providers.dart`): Query `db.settings` for `periodStartDay` and compute `[cycleStart, cycleEndInclusive]` and `currentPeriodMonth` label via `BillingCycleCalculator` so the Reports screen (`Báo cáo`) is also 100% synchronized.

### R4. Updated Release APK Build & Full Quality Gate Verification
- Run `dart format`, `flutter analyze`, and `flutter test` until 100% green.
- Build the updated R8-shrunk split-per-ABI release APKs (`flutter build apk --release --split-per-abi --tree-shake-icons`) and verify that `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` and `build/app/outputs/flutter-apk/app-x86_64-release.apk` are freshly generated.

## Acceptance Criteria

### Static Analysis & Formatting
- [ ] `dart format --output=none --set-exit-if-changed .` exits with code 0.
- [ ] `flutter analyze` exits with code 0 (zero errors, zero warnings, zero lints).

### Functional & Regression Verification
- [ ] **R1 Verification (Obligation vs. Budget Conflict Fixed)**: Automated test proving that creating a `3.500.000 ₫` bill (`Tiền nhà`, default `Hoá đơn & Tiện ích` or `Nhà cửa` category) and a `3.000.000 ₫` `Ăn uống` category budget (and/or `3.000.000 ₫` `Ăn uống` envelope), then marking the `Tiền nhà` bill as `Đã trả`, leaves the `Ăn uống` category budget spent at `0 ₫` (and `Ăn uống` envelope balance at `3.000.000 ₫`), while only increasing spending on the bill's selected category.
- [ ] **R2 Verification (Plans CRUD + Ledger Reversal)**: Automated tests verifying Edit and Delete on:
  - Category Budgets (`upsertCategoryBudget`, `deleteCategoryBudget`)
  - Savings Goals (`EnvelopeFormModal` edit mode / `updateSavingsGoal`, `deleteSavingsGoal`)
  - Scheduled Items (`updateScheduledItem`, `deleteScheduledItem` for both `PENDING` and `PAID_OR_RECEIVED` items, verifying that deleting or editing a `PAID_OR_RECEIVED` item atomically reverses/updates the linked general ledger transaction and restores liquid account & envelope balances).
- [ ] **R3 Verification (Billing Cycle `periodStartDay` Sync)**: Automated unit and provider/widget tests verifying `BillingCycleCalculator` across `periodStartDay` values (e.g., day 1, day 15, day 28) and proving that updating `periodStartDay` in `Settings` immediately updates the cycle window in `currentMonthlyBudgetSummaryProvider`, `safeToSpendProvider`, `reportsSummaryProvider`, and the Dashboard UI.
- [ ] **R4 Verification (All Tests & Release APK)**: `flutter test` passes 100% of unit, database, and widget tests, and `flutter build apk --release --split-per-abi --tree-shake-icons` succeeds with updated APK binaries in `build/app/outputs/flutter-apk/`.
