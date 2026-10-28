# UI/UX, Design System, Local Notifications & Security Specification Report

**Document**: `handoff.md`  
**Agent**: `spec_miner_survey_2` (UI/UX & Security Spec Miner)  
**Date**: 2026-10-27T10:15:00Z  
**Parent**: `orchestrator_1` (`4b707e3a-5355-44d8-b48d-d32bbd3220b1`)  
**Workspace**: `c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_2\`  
**Target Delivery Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_2\handoff.md`

---

## 1. Observation

Direct observations extracted from authoritative project resources:

1. **Authoritative Build Specification** (`build_spec/dongtien_build_spec.md`):
   - **Section 2 & 6.1**: Directs light-first Material 3 UI (`vi_VN` locale, integer `VND`, tabular figures `FontFeature.tabularFigures()`, `1.250.000 ₫` formatting, zero decimals). 4 primary bottom navigation tabs (`IndexedStack` + standard `Navigator`): `Tổng quan`, `Giao dịch`, `Quỹ tiền`, `Kế hoạch`. Secondary screens via AppBar: `Báo cáo`, `Cài đặt & Sao lưu`.
   - **Section 3**: Strictly locked dependencies: `flutter_riverpod` (standard Notifier), `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `intl`, `share_plus`, `file_picker`, `cryptography`. Strictly forbidden: `uuid`, chart libraries, `go_router`, `freezed`, `dio`/`http`, `firebase_*`, `flutter_secure_storage`, `sqlcipher`.
   - **Section 5.3 & 5.4**: Safe-to-Spend formula rendering: hero card with breakdown modal; exact negative shortfall rendered in red with component breakdown; daily allowance clamped to `0 ₫/ngày` if Safe-to-Spend `<= 0`. Savings goal feasibility flags `INFEASIBLE` with 3 one-tap calculators.
   - **Section 6.2 & 6.3**: Fast transaction entry with custom numeric keypad, segmented selector (`Chi tiêu`, `Thu nhập`, `Chuyển khoản`, `Trả thẻ`, `Hoàn tiền`), visual category grid, source/dest accounts, optional envelope. Deterministic `Semantics(identifier: ...)`. Compliant notifications declaring only `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`; scheduling via `AndroidScheduleMode.inexactAllowWhileIdle` (zero exact alarms).
   - **Section 7.1 & 7.2**: Android hardening: `android:allowBackup="false"`, `res/xml/data_extraction_rules.xml` excluding SQLite database. Cryptography off-main-thread inside `Isolate.run`: JSON outer wrapper `"magic": "DONGTIEN_ENC_V1"`, `PBKDF2-HMAC-SHA256` (120,000 iterations, 16-byte salt), `AES-256-GCM` (12-byte nonce, 16-byte MAC tag). 25 MB max size check, structural in-memory invariant validation, confirmation dialog, atomic restore inside `db.transaction()`.

2. **Visual Design Reference Images** (`docs/design_refs/`):
   - `Spacing.png`: 16-step spacing token scale `sp-0` (0px) through `sp-15` (128px).
   - `Untitled-1.png`: 4-column layout grid for mobile screens, top safe area padding, side margins, bottom gesture bar clearance.
   - `Untitled-2.png`: 7-tier typography scale (`Large Title` 32px/48px, `Title` 24px/36px, `Headline` 20px/30px, `Body` 16px/24px, `Subheadline` 14px/20px, `Footnote` 12px/16px, `Caption` 10px/14px) with Regular (400) and Medium (500) weights.
   - `Untitled-3.png`: Authoritative color system: 7 color families (Verdant, Sandstone, Marigold, Ember, Ruby, Charcoal, Neutral) with verbatim semantic tokens (Text, Surface, Fill, Border, Icon) and hex values.
   - `Untitled.png`: Remix Icon standard outline icons (24px) and 16 circular themed category icons.
   - `budget.png`: Overview dashboard layout, Safe-to-Spend balance hero, two-color spend/budget progress bar, "Spending Insight" comparative bar chart, "Expense Categories" list, "Cash Flow" net inflow/outflow, "Upcoming Bills" obligations, "Recent Transactions", "New" action modal sheet, and Category Detail screen.
   - `invest.png`: Portfolio diversity segmented bars, performance line graphs, list item metadata patterns, asset class cards.
   - `savings.png`: Goal cards (title, completion %, target amount, progress bar, saved amount), "Fund" / "Withdraw" action pills, Goal Detail screen with top wavy banner, lock icon for protected funds, and "Saving Insight" comparison card.
   - `wallet.png`: Account balance hero card, quick actions ("Fund", "Send", "Recieve"), and full-screen **Custom Numeric Keypad entry flow** (digits 0-9, backspace `< `, formatted amount display, dark verdant background with topographical lines, and Ember CTA button).

---

## 2. Logic Chain

1. **Design System Grounding**:
   - Because `Untitled-3.png`, `Spacing.png`, and `Untitled-2.png` provide explicit, pixel-exact design tokens, `DongTien` UI must strictly encode these exact tokens into `lib/app/theme/app_colors.dart`, `app_typography.dart`, and `app_spacing.dart`.
   - Because chart libraries are strictly forbidden, visual financial feedback (spending progress, cash flow, Safe-to-Spend breakdown, and forecast trends) must be implemented using custom Material 3 widgets, `LinearProgressIndicator`, custom painters, or row-based bar layouts.
   - Because tabular numerals prevent layout jitter during financial updates and align columns in day-grouped lists, all amount widgets must explicitly use `FontFeature.tabularFigures()`.

2. **Navigation Shell Simplicity & State Preservation**:
   - Because `go_router` is strictly forbidden and users frequently switch between tabs while reviewing finances, the top-level shell must use an `IndexedStack` hosting the 4 bottom tabs (`Tổng quan`, `Giao dịch`, `Quỹ tiền`, `Kế hoạch`).
   - Secondary destinations (`Báo cáo`, `Cài đặt & Sao lưu`, `Chi tiết Quỹ`, `Lịch sử chỉnh sửa`) must be pushed via standard `Navigator.push(context, MaterialPageRoute(...))` from AppBar actions or list items to preserve native Android back navigation and hero transitions.

3. **Transaction Entry Speed & Accuracy**:
   - Financial apps fail when transaction entry is slow. As demonstrated in `wallet.png`, opening the Quick-Add flow immediately focuses the amount with a large, error-proof custom numeric keypad (0-9, backspace).
   - Linking transactions to the double-entry ledger requires knowing the transaction type. A 5-segment selector (`Chi tiêu`, `Thu nhập`, `Chuyển khoản`, `Trả thẻ`, `Hoàn tiền`) cleanly adjusts the input form:
     - `Chi tiêu` / `Hoàn tiền`: requires Expense Category and Source Account; optional Envelope.
     - `Thu nhập`: requires Income Category and Destination Account.
     - `Chuyển khoản`: requires Source Asset Account and Destination Asset Account; disables Category.
     - `Trả thẻ`: requires Source Asset Account and Destination Liability Account; disables Category.
   - Idempotency guard: every open of the Quick-Add modal generates a new UUID-less deterministic or timestamp-based `idempotency_key` to prevent accidental double-posting on rapid button taps.

4. **Compliant Android Notification Architecture (Android 12–15+)**:
   - Modern Google Play policies heavily restrict `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`, rejecting financial apps that declare them without calendar/alarm clock exemptions.
   - Therefore, DongTien must declare *only* `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`, and use `AndroidScheduleMode.inexactAllowWhileIdle`.
   - This ensures alarms fire reliably during Android Doze mode while fully complying with Google Play policies.
   - If permission is denied (Scenario 15), the app degrades gracefully: zero crashes, zero blocking dialogues, and a helpful reminder banner inside Settings.

5. **Defense-in-Depth Android Hardening & Encrypted Backup**:
   - Financial privacy requires disabling automated cloud backup of SQLite files via `android:allowBackup="false"` and `data_extraction_rules.xml`.
   - Backup files contain complete user financial history. An outer authenticated wrapper (`magic: "DONGTIEN_ENC_V1"`) with `PBKDF2-HMAC-SHA256` (120,000 iterations) and `AES-256-GCM` provides cryptographic confidentiality and integrity.
   - Deriving PBKDF2 keys with 120,000 iterations takes 300–800ms of CPU time; executing this on the UI thread causes severe frame drops. Running the entire crypto and JSON pipeline inside `Isolate.run` guarantees 60fps UI smoothness.
   - Multi-stage safety checks (file size $\le 25\text{ MB}$, authentication before decryption, in-memory validation of double-entry invariants, explicit user confirmation dialog with record counts, and atomic SQLite transaction) guarantee that corrupt, tampered, or wrong-password backups (Scenario 14) can never corrupt existing user data.

---

## 3. Caveats

1. **Icon Set Translation**:
   - The design references use Remix Icons (`Untitled.png`). In Flutter, these map cleanly to standard Material Icons (`Icons.*`) or SVG assets. The icon mapping table below provides exact `Icons.*` equivalents for all reference icons so no external icon package is required.
2. **Android Inexact Alarm Drift**:
   - With `AndroidScheduleMode.inexactAllowWhileIdle`, notification delivery times may drift by $\pm 10-15$ minutes due to Android battery optimization batching. This is standard and expected for personal finance reminders (daily summaries and bill reminders do not require millisecond precision).
3. **Isolate Parameter Serialization**:
   - Dart's `Isolate.run` requires all passed parameters and returned objects to be sendable across isolate ports (primitive types, `Uint8List`, Maps, Lists, or basic DTOs). Database connection handles cannot be sent into isolates. Therefore, the isolate handles raw JSON decryption/encryption, while the SQLite database write occurs on the main isolate inside a single atomic `db.transaction()`.

---

## 4. Conclusion

The visual designs and requirements provide an airtight, consistent, and elegant foundation for DongTien. By locking down:
1. Exact design tokens (palette, typography, spacing, card shape, elevations).
2. Screen layouts, interactive components, and accessibility identifiers.
3. Compliant notification lifecycle and permission degradation.
4. Off-main-thread authenticated encrypted backup and restore with 6-stage validation gates.

Downstream feature agents can implement all UI screens, notifications, and security services without architectural ambiguity or design drift.

---

## 5. Verification Method

To independently verify the specifications documented in this report:

1. **Design Token Verification**:
   - Inspect `docs/design_refs/Spacing.png` to verify the 16-step spacing scale (0px to 128px).
   - Inspect `docs/design_refs/Untitled-2.png` to verify the 7 typography styles and sizes.
   - Inspect `docs/design_refs/Untitled-3.png` to verify the exact hex color codes for Verdant, Sandstone, Ember, Ruby, Marigold, Charcoal, and Neutral.
   - Inspect `docs/design_refs/wallet.png` to verify the custom numeric keypad layout and styling.

2. **Automated Acceptance & Scenario Tests**:
   - **Scenario 12 (Negative Safe-to-Spend)**: Assert hero card renders exact negative VND balance in red (`text-accent-ruby-primary` `#9A2329`) and daily allowance renders `0 ₫/ngày`.
   - **Scenario 13 (Encrypted Backup Round-Trip)**: Export encrypted backup, wipe state, restore with password $\rightarrow$ verify all balances, envelopes, budgets, and postings reconcile 100%.
   - **Scenario 14 (Tampered Backup / Wrong Password)**: Flip 1 byte in ciphertext or mac $\rightarrow$ verify `SecretBoxAuthenticationError` thrown inside `Isolate.run`, database untouched.
   - **Scenario 15 (Notification Permission Denied)**: Simulate permission rejection $\rightarrow$ verify app remains 100% operational, settings shows warning banner.

3. **Toolchain Verification Commands**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   flutter test --coverage
   flutter build apk --debug
   ```

---

## Features Discovered

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | Design System | Spacing Token Scale | 16-step spacing scale from `sp-0` (0px) to `sp-15` (128px) | Integer token index (0..15) | Pixel spacing value | Compilation error on invalid token | `Spacing.png` |
| 2 | Design System | Typography Scale | 7-tier scale (`Large Title` to `Caption`) with Regular & Medium weights | Text content, style token | Formatted Text widget | Font fallback to system sans-serif | `Untitled-2.png` |
| 3 | Design System | Tabular Numerals | Enforces fixed-width numerals for alignment | `FontFeature.tabularFigures()` | Jitter-free numeric rendering | Ignored if font lacks feature | `Untitled-2.png`, build spec §6.1 |
| 4 | Design System | Semantic Color Palette | 7 color families with semantic Text, Surface, Fill, Border, and Icon tokens | Semantic token enum/getter | Exact Hex Color (`Color(0xFF...)`) | Fallback to neutral colors | `Untitled-3.png` |
| 5 | Design System | Card Radius & Elevation | 16-24px rounded corners with low elevation/subtle outline border | Card content, radius parameter | Material 3 Card / Container | None | `budget.png`, `savings.png` |
| 6 | Navigation | 4 Bottom Navigation Tabs | Root navigation shell with `Tổng quan`, `Giao dịch`, `Quỹ tiền`, `Kế hoạch` | Tab index (0..3) | `IndexedStack` page view | Clamped to valid tab index range | build spec §6.1, `budget.png` |
| 7 | Navigation | Secondary Screen Routing | Pushes `Báo cáo`, `Cài đặt`, `Chi tiết Quỹ` via standard `Navigator` | Route push intent | New MaterialPageRoute screen | Logs error on invalid route | build spec §6.1 |
| 8 | Dashboard | Safe-to-Spend Hero Card | Primary financial anchor showing available spendable cash & daily rate | Safe-to-Spend integer VND | Formatted hero card, daily allowance | Displays exact deficit in red if $\le 0$ | build spec §5.3, 6.1 |
| 9 | Dashboard | Formula Breakdown Modal | Bottom sheet detailing: Liquid - Protected - Unfunded Bills - Buffer | Trigger tap on hero info icon | Modal sheet with line-item breakdown | None | build spec §5.3, 6.1 |
| 10 | Dashboard | Spending vs Budget Card | Today & month-to-date spending vs monthly category budgets | Postings aggregate, budget totals | Dual-progress bar, spend/limit | Warning tint if $>80\%$, danger if $>100\%$ | `budget.png`, build spec §6.1 |
| 11 | Dashboard | Upcoming Obligations Card | List of pending scheduled bills & next planned income with countdown | `scheduled_items` where status = PENDING | Obligation items with quick "Pay" button | None; empty state if no pending bills | `budget.png`, build spec §5.5 |
| 12 | Dashboard | Virtual Fund Progress Card | Compact progress meters for active Protected and Flexible envelopes | `envelopes` list with balances & targets | Mini cards with percentage and progress bar | None | `budget.png`, `savings.png` |
| 13 | Dashboard | Recent 5 Transactions | Quick glance at last 5 posted transactions with "Xem tất cả" link | Latest 5 `POSTED` transactions | Compact transaction items | Empty state placeholder if 0 tx | `budget.png`, build spec §6.1 |
| 14 | Transactions | Day-Grouped Transaction List | Chronological transactions grouped by calendar day with daily net totals | Transaction stream filtered by status/type | Sticky day headers + transaction items | Empty search/filter state | `budget.png`, build spec §6.1 |
| 15 | Transactions | Transaction Search & Filters | Search by note/merchant; filter by type, account, category, envelope, date | Search query, active filter chips | Filtered list of transactions | "Không tìm thấy giao dịch" empty state | `budget.png`, build spec §6.1 |
| 16 | Transactions | Account Management Header | Cards/chips showing Liquid Cash, Bank accounts, and Credit Card debt | Account balances aggregate | Account status cards with add/edit button | None | `wallet.png`, build spec §6.1 |
| 17 | Transactions | Audit History Sheet | Bottom sheet displaying full edit/void history and reversal postings | Transaction ID with audit trail | Reversal chain and superseded versions | "Chưa qua chỉnh sửa" if original | build spec §4.5, 6.1 |
| 18 | Quick-Add | Custom Numeric Keypad | Fast monetary input with 0-9 digits and backspace `<` | Keypad taps | Formatted VND amount string | Enforces $>0$ and $\le 9 \times 10^{15}$ | `wallet.png`, build spec §6.2 |
| 19 | Quick-Add | Segmented Transaction Type | 5 transaction types: Chi tiêu, Thu nhập, Chuyển khoản, Trả thẻ, Hoàn tiền | Segment selection | Dynamically adjusts required form fields | Disallows submission if accounts missing | build spec §4.3, 6.2 |
| 20 | Quick-Add | Visual Category Grid | Circular category icons for quick expense/income category tagging | Category tap | Selected category highlight | Hidden on transfer/card payment | `Untitled.png`, build spec §6.2 |
| 21 | Quick-Add | Account Selection Chips | Source and optional destination account selection chips | Account tap | Selected account badge | Warns if source == destination on transfer | build spec §4.3, 6.2 |
| 22 | Quick-Add | Envelope Progressive Disclosure | Optional dropdown/chip to link expense/refund to virtual fund | Envelope selection | Selected envelope badge | Warns if amount $>$ envelope balance | build spec §5.1, 6.2 |
| 23 | Virtual Funds | Fund Summary Bar | 3-part summary: Liquid Assets, Reserved Balance, Available to Allocate | Account balances, envelope sums | Metric header with Allocate/Transfer actions | Available-to-allocate can be negative | build spec §5.1, 6.1 |
| 24 | Virtual Funds | Protected vs Flexible Lists | Grouped envelopes by policy (`PROTECTED` vs `FLEXIBLE`) | Envelopes query | Categorized envelope cards with lock icon | None | `savings.png`, build spec §5.1 |
| 25 | Virtual Funds | Allocate / Transfer / Release | Modals to move virtual money between Available and Envelopes | Amount, source/destination envelope | DB `envelope_movements` record | Blocked if amount $>$ available-to-allocate | build spec §5.1 |
| 26 | Virtual Funds | Fund Detail & Movement History | Detailed screen showing envelope metrics and complete movement history | Envelope ID | Timeline of allocations, releases, spends | None | `savings.png`, build spec §6.1 |
| 27 | Plans | Category Budgets View | Monthly budget limits per expense category with visual thresholds | YearMonth, category limits | Progress bars (verdant $<80\%$, orange, red) | Flags overbudget categories | `budget.png`, build spec §6.1 |
| 28 | Plans | Savings Goals & Feasibility | Goal target, balance, deadline with ceiling division per period | Goal envelopes query | Feasibility status (`ACHIEVED`, `OVERDUE`) | Flags `INFEASIBLE` with 3 calculators | `savings.png`, build spec §5.4 |
| 29 | Plans | Feasibility One-Tap Calculators | (1) Extend deadline $N'$, (2) Lower target $T'$, (3) Pause low priority | Tap calculator action | Updated recommended plan parameters | None | build spec §5.4 |
| 30 | Plans | Scheduled Items & Obligations | Recurring bills and planned income management | `scheduled_items` records | Obligation list with status and recurrence | None | `budget.png`, build spec §5.5 |
| 31 | Plans | Month-End Drift Prevention | Recurrence anchor day 1..31 mapped via `min(anchor, daysInMonth)` | Anchor day, target year/month | Exact target date (Feb 28/29 $\rightarrow$ Mar 31) | None | build spec §5.5 |
| 32 | Plans | 30/60/90-Day Cash Forecast | Day-by-day cash balance projection with buffer breach detection | Liquid cash, pending bills, planned income | Projection timeline / chart | Highlights breach date if below buffer | build spec §5.5 |
| 33 | Reports | Financial Health Overview | Income, Gross Expense, Refunds, Net Expense, Transfers, Saving Rate | Date range filter, postings aggregate | Financial report cards and net saving | Shows "Chưa có thu nhập" if income $\le 0$ | build spec §5.2, 6.1 |
| 34 | Reports | Net Recovery Handling | Special display when refunds exceed gross expenses in period | Negative net expense | "Thu hồi chi phí ròng" card | Clamps effective expense to 0 for saving rate | build spec §5.2 |
| 35 | Reports | Net Worth Metric | Derives Net Worth = Total Liquid Assets - Total Liabilities (card debt) | Postings across asset and liability accounts | Formatted Net Worth display | Can be negative if debt exceeds assets | build spec §4.4, 6.1 |
| 36 | Settings | Financial Rules Configuration | Configures Minimum Cash Buffer (VND) and Period Start Day (1..31) | Integer buffer and day | Persisted in `settings` table | Validates day in 1..31, buffer $\ge 0$ | build spec §4.2, 6.1 |
| 37 | Settings | Notification Preferences | Configures daily reminder time (`HH:mm`) and toggle switch | Time picker, boolean toggle | Persisted in `settings` table | Prompts for system permission if disabled | build spec §4.2, 6.3 |
| 38 | Settings | CSV Export | Exports transactions and postings into standard CSV format | Export action tap | Triggers system share sheet (`share_plus`) | Shows snackbar error if file write fails | build spec §6.1 |
| 39 | Settings | Sample Data Generator | Generates realistic Vietnamese sample dataset for demonstration | User confirmation | Populates accounts, categories, tx, envelopes | Confirmation modal to avoid accidental run | build spec §6.1 |
| 40 | Settings | Reset Database | Clears all user data, restores initial 0 ₫ seeding and default categories | User confirmation | Fresh first-run state | Confirmation modal requiring explicit tap | build spec §6.1 |
| 41 | Accessibility | Semantics Identifiers | Attaches deterministic `identifier` tags to all primary UI components | `Semantics(identifier: '...')` | Automated test accessibility hooks | None | build spec §6.2 |
| 42 | Notifications | Inexact Local Reminders | Battery-friendly reminders using `inexactAllowWhileIdle` | Notification time and payload | Android system notification | Denied permissions handled gracefully | build spec §6.3 |
| 43 | Notifications | Daily Summary Notification | Reminds user at configured hour with today's spend & Safe-to-Spend | Scheduled daily time trigger | Notification item in notification shade | None | build spec §6.3 |
| 44 | Notifications | Upcoming Bill Reminder | Alerts user $N$ days before a scheduled bill due date | `due_date - reminder_days` | Notification item with bill name & amount | Cancelled if bill marked paid early | build spec §6.3 |
| 45 | Notifications | Budget Threshold Alert | Fires immediately when posted expense crosses 80% or 100% budget | Newly posted expense transaction | Immediate notification | Triggered only on threshold boundary crossing | build spec §6.3 |
| 46 | Security | Android Backup Disabling | Disables Android Auto-Backup and device-to-device database extraction | AndroidManifest & data_extraction_rules | Excludes SQLite directory from backup | None | build spec §7.1 |
| 47 | Security | Log Redaction | Redacts financial numbers, notes, and passwords in release/profile | Debug logger wrapper | Empty / sanitized log output | None | build spec §7.1 |
| 48 | Security | Isolate-Based Backup Export | Generates outer JSON with PBKDF2 (120k iterations) and AES-256-GCM | User password, DB data snapshot | Encrypted `.dongtien` JSON backup file | Throws if password empty | build spec §7.2 |
| 49 | Security | Backup File Size Guard | Rejects any imported backup file exceeding 25 MB before processing | File byte length | Throws `BackupSizeExceededException` | Halts restore immediately | build spec §7.2 |
| 50 | Security | Off-Main-Thread Decryption | Decrypts and authenticates backup envelope inside `Isolate.run` | Encrypted file content, password | Decrypted raw JSON string | Throws `SecretBoxAuthenticationError` | build spec §7.2 |
| 51 | Security | In-Memory Invariant Validation | Validates double-entry balance, FKs, and non-negative integers | Decrypted JSON data structures | Validated backup model object | Throws `BackupCorruptException` | build spec §7.2 |
| 52 | Security | Restore Confirmation Dialog | Shows backup creation date and record counts for user confirmation | Validated backup metadata | User dialog (Confirm / Cancel) | Cancelling preserves current DB | build spec §7.2 |
| 53 | Security | Atomic Database Restore | Replaces all database tables inside a single SQLite transaction | Validated backup models | Restored database state | Full rollback on any SQL error | build spec §7.2 |

---

## Edge Cases

| # | Feature | Input | Observed Behavior |
|---|---------|-------|-------------------|
| 1 | Safe-to-Spend | Liquid Assets < Protected Reserves + Unfunded Bills + Buffer | Does NOT clamp to 0. Displays exact negative deficit in red (`text-accent-ruby-primary`). Daily allowance displays `0 ₫/ngày`. Breakdown modal details the exact shortfall source. |
| 2 | Safe-to-Spend | Protected envelope linked to upcoming bill | Chronologically offsets bill amount against envelope balance so the bill is not subtracted twice (Zero double-subtraction invariant). |
| 3 | Safe-to-Spend | Flexible envelope linked to upcoming bill | Full bill amount is subtracted as an unfunded outflow, because flexible envelopes are not deducted in Protected Reserves. |
| 4 | Savings Goal Math | Goal balance $C \ge$ Target $T$ | Status displays `ACHIEVED` (`Đã hoàn thành`), required per period is `0 ₫`. |
| 5 | Savings Goal Math | Remaining periods $N \le 0$ and $C < T$ | Status displays `OVERDUE` (`Quá hạn`), shortfall is $T - C$. Avoids division by zero. |
| 6 | Savings Goal Math | Goal target $T = 10.000.000 ₫$, $C = 0 ₫$, $N = 3$ periods | Uses ceiling integer division: `((10000000 - 0) + 3 - 1) ~/ 3 = 3.333.334 ₫/kỳ`. Guaranteed to reach target by deadline. |
| 7 | Savings Goal Math | Total required savings exceed available capacity | Flags goal as `INFEASIBLE`. Displays feasibility advisor with 3 one-tap calculators (extend deadline, lower target, pause lower priority). |
| 8 | Month-End Recurrence | Monthly bill anchored on day 31 | In February (leap year 2028), schedules on Feb 29. In non-leap year (2027), schedules on Feb 28. In March, schedules back on Mar 31 without date drift. |
| 9 | Cash-Flow Forecast | Projected balance drops below Minimum Cash Buffer | Projection timeline flags the specific future date with an amber/red breach indicator and shows projected deficit amount. |
| 10 | Reports (Saving Rate) | Recognized income $\le 0$ | Displays `"Chưa có thu nhập"` instead of `NaN%`, `-Infinity%`, or throwing a division-by-zero error. |
| 11 | Reports (Net Recovery) | Refunds from prior period exceed current gross expenses ($Net < 0$) | Displays `"Thu hồi chi phí ròng"` with positive credit value. Clamps effective expense to `0 ₫` when computing saving rate. |
| 12 | Quick-Add Amount | User inputs `0 ₫` or taps submit with empty amount | Amount field displays warning outline, submit button remains disabled or shows error toast: "Số tiền phải lớn hơn 0 ₫". |
| 13 | Quick-Add Amount | User enters amount exceeding 64-bit safety threshold ($> 9 \times 10^{15}$) | Custom keypad disallows additional digits and displays maximum amount limit warning. |
| 14 | Quick-Add Idempotency | User rapidly taps "Lưu giao dịch" button 3 times | Idempotency guard ensures only one transaction record is committed; subsequent taps within the same submission are ignored. |
| 15 | Envelope Spending | Expense amount exceeds envelope reserved balance | If `allow_negative_exception == false`, transaction creation is blocked with deficit dialog. If user confirms negative exception, records explicit negative movement and reduces Available-to-Allocate. |
| 16 | Envelope Allocation | User attempts to allocate more than Available-to-Allocate | Allocate button is disabled, or validation error blocks action: "Không thể phân bổ vượt quá số tiền khả dụng". |
| 17 | Transaction List | Transaction was edited or voided | Main transaction list filters out `status = 'SUPERSEDED'`, `status = 'VOIDED'`, and `tx_type = 'REVERSAL'`. Only active `POSTED` transactions appear in the clean list. Audit History sheet shows full revision chain. |
| 18 | Internal Transfer | User selects identical source and destination account | Form validation marks destination account invalid and blocks submission: "Tài khoản nhận phải khác tài khoản gửi". |
| 19 | Notifications | User denies `POST_NOTIFICATIONS` permission (Scenario 15) | App does NOT crash. Scheduling methods silently catch permission errors and no-op. Settings screen displays informative banner with a button to open system app settings. |
| 20 | Notifications | Device reboots | Broadcast receiver catches `RECEIVE_BOOT_COMPLETED`, initializes timezone database, reads pending `scheduled_items`, and reschedules alarms via `inexactAllowWhileIdle`. |
| 21 | Encrypted Backup | File size exceeds 25 MB ($> 26.214.400$ bytes) | Immediate rejection before reading file into memory or invoking crypto isolate: throws `BackupSizeExceededException`. |
| 22 | Encrypted Backup | User enters wrong password or file has 1 tampered bit in ciphertext/mac (Scenario 14) | `AesGcm.with256Bits` throws `SecretBoxAuthenticationError` inside `Isolate.run`. Catch block safely reports "Mật khẩu không đúng hoặc tệp sao lưu đã bị thay đổi". SQLite database remains completely untouched. |
| 23 | Encrypted Backup | Malicious or corrupt backup contains unbalanced postings ($\sum Debit \ne \sum Credit$) | In-memory structural validation gate detects mismatch and throws `BackupCorruptException`. User is notified and restore is aborted without touching SQLite. |
| 24 | Encrypted Backup | In-memory validation passes, but power cut / DB error occurs during table insertion | Single SQLite `db.transaction()` rolls back automatically. Previous user data remains 100% preserved. |

---

## Detailed Specifications

### Chapter I: Design System & Tokens

#### 1. Spacing Tokens (`Spacing.png`)
Base grid unit: 4px.
```dart
class AppSpacing {
  static const double sp0 = 0.0;    // 0px
  static const double sp1 = 1.0;    // 1px  - hairline dividers
  static const double sp2 = 2.0;    // 2px  - subtle borders
  static const double sp3 = 4.0;    // 4px  - xs tight spacing
  static const double sp4 = 8.0;    // 8px  - sm component internal padding
  static const double sp5 = 12.0;   // 12px - md compact element gap
  static const double sp6 = 16.0;   // 16px - base card padding, standard screen margin
  static const double sp7 = 20.0;   // 20px - lg section spacing, screen margin
  static const double sp8 = 24.0;   // 24px - xl modal top padding
  static const double sp9 = 32.0;   // 32px - xxl major section separation
  static const double sp10 = 40.0;  // 40px - xxxl hero card vertical margins
  static const double sp11 = 48.0;  // 48px - touch target size, keypad button size
  static const double sp12 = 64.0;  // 64px - spacious layout separators
  static const double sp13 = 80.0;  // 80px - bottom bar clearance
  static const double sp14 = 96.0;  // 96px - hero display clearance
  static const double sp15 = 128.0; // 128px - maximum visual separator
}
```

#### 2. Typography Tokens (`Untitled-2.png`)
All amounts, currencies, percentages, and dates MUST specify `fontFeatures: [FontFeature.tabularFigures()]`.
```dart
class AppTypography {
  static const TextStyle largeTitle = TextStyle(
    fontSize: 32,
    height: 48 / 32, // 1.5
    letterSpacing: 0,
    fontWeight: FontWeight.w500, // Medium
  );

  static const TextStyle title = TextStyle(
    fontSize: 24,
    height: 36 / 24, // 1.5
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 20,
    height: 30 / 20, // 1.5
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 24 / 16, // 1.5
    letterSpacing: 0,
    fontWeight: FontWeight.w400, // Regular
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle subheadline = TextStyle(
    fontSize: 14,
    height: 20 / 14, // 1.43
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 12,
    height: 16 / 12, // 1.33
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    height: 14 / 10, // 1.4
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );
}
```

#### 3. Semantic Color Palette (`Untitled-3.png`)
Extracted verbatim from design reference token specifications:
```dart
class AppColors {
  // Text Tokens
  static const Color textPrimary = Color(0xFF4D4845);               // charcoal-16
  static const Color textSecondary = Color(0xFF65605C);             // charcoal-12
  static const Color textTertiary = Color(0xFF928F8B);              // charcoal-09
  static const Color textDisabled = Color(0xFFDBDBD8);              // charcoal-05
  static const Color textInverse = Color(0xFFFFFFFF);               // neutral-01
  static const Color textAccentVerdantPrimary = Color(0xFF215B44);   // verdant-14
  static const Color textAccentVerdantSecondary = Color(0xFF3D785F); // verdant-11
  static const Color textAccentSandstonePrimary = Color(0xFF764527); // sandstone-14
  static const Color textAccentSandstoneSecondary = Color(0xFF976035); // sandstone-11
  static const Color textAccentEmberPrimary = Color(0xFF8B3711);     // ember-14
  static const Color textAccentEmberSecondary = Color(0xFFB84B17);   // ember-11
  static const Color textAccentRubyPrimary = Color(0xFF9A2329);      // ruby-14 (danger/deficit)
  static const Color textAccentRubySecondary = Color(0xFFC9362B);    // ruby-11 (expense)
  static const Color textAccentMarigoldPrimary = Color(0xFF823F00);  // marigold-14
  static const Color textAccentMarigoldSecondary = Color(0xFFAC5500);// marigold-11

  // Surface Tokens
  static const Color surfacePrimary = Color(0xFFFFFFFF);            // neutral-01 (cards)
  static const Color surfaceSecondary = Color(0xFFF6F6F4);          // charcoal-01 (scaffold background)
  static const Color surfaceTertiary = Color(0xFFEFEFED);           // charcoal-03 (dividers/tracks)
  static const Color surfaceOverlay = Color(0x634D4845);            // alpha-09 (39% opacity)
  static const Color surfaceAccentVerdantPrimary = Color(0xFF3D785F); // verdant-11
  static const Color surfaceAccentVerdantSecondary = Color(0xFFF3F7F5); // verdant-01
  static const Color surfaceAccentSandstonePrimary = Color(0xFFD59D6F); // sandstone-09
  static const Color surfaceAccentSandstoneSecondary = Color(0xFFFDF6E4); // sandstone-01
  static const Color surfaceAccentEmberPrimary = Color(0xFFE86B1C); // ember-08
  static const Color surfaceAccentEmberSecondary = Color(0xFFFFF4F0); // ember-01
  static const Color surfaceAccentRubyPrimary = Color(0xFFE55959);  // ruby-11
  static const Color surfaceAccentRubySecondary = Color(0xFFFFF4F1); // ruby-01
  static const Color surfaceAccentMarigoldPrimary = Color(0xFFFFC542); // marigold-05
  static const Color surfaceAccentMarigoldSecondary = Color(0xFFFFF5E3); // marigold-01

  // Fill Tokens
  static const Color fillPrimary = Color(0xFFFFFFFF);               // neutral-01
  static const Color fillSecondary = Color(0xFFF6F6F4);             // charcoal-01
  static const Color fillTertiary = Color(0xFFEFEFED);              // charcoal-03
  static const Color fillAccentVerdantPrimary = Color(0xFF4E886F);   // verdant-10
  static const Color fillAccentVerdantSecondary = Color(0xFFF3F7F5); // verdant-01
  static const Color fillAccentSandstonePrimary = Color(0xFFF0AB59); // sandstone-07
  static const Color fillAccentSandstoneSecondary = Color(0xFFFDF6E4); // sandstone-01
  static const Color fillAccentEmberPrimary = Color(0xFFFD8240);     // ember-08 (CTA button)
  static const Color fillAccentEmberSecondary = Color(0xFFFFF4F0);   // ember-01
  static const Color fillAccentRubyPrimary = Color(0xFFF55D3E);      // ruby-09
  static const Color fillAccentRubySecondary = Color(0xFFFFF4F1);    // ruby-01
  static const Color fillAccentMarigoldPrimary = Color(0xFFFAA800);  // marigold-07
  static const Color fillAccentMarigoldSecondary = Color(0xFFFFF5E3);// marigold-01

  // Border Tokens
  static const Color borderPrimary = Color(0xFFF4F4F2);             // charcoal-02
  static const Color borderSecondary = Color(0xFFE7E7E4);           // charcoal-04
  static const Color borderInverse = Color(0xFF4D4845);             // charcoal-16
  static const Color borderAccentVerdant = Color(0xFF4E886F);       // verdant-10
  static const Color borderAccentSandstone = Color(0xFFF0AB59);     // sandstone-07
  static const Color borderAccentEmber = Color(0xFFFD8240);         // ember-08
  static const Color borderAccentRuby = Color(0xFFF55D3E);          // ruby-09
  static const Color borderAccentMarigold = Color(0xFFFAA800);      // marigold-07

  // Icon Tokens
  static const Color iconPrimary = Color(0xFF4D4845);               // charcoal-16
  static const Color iconSecondary = Color(0xFFA6A4A0);             // charcoal-08
  static const Color iconDisabled = Color(0xFFDBDBD8);              // charcoal-05
  static const Color iconInverse = Color(0xFFFFFFFF);               // neutral-01
  static const Color iconAccentVerdant = Color(0xFF4E886F);         // verdant-10
  static const Color iconAccentSandstone = Color(0xFFD99650);       // sandstone-08
  static const Color iconAccentEmber = Color(0xFFE86B1C);           // ember-09
  static const Color iconAccentRuby = Color(0xFFE0462F);            // ruby-10
  static const Color iconAccentMarigold = Color(0xFFEE8D00);        // marigold-08
}
```

#### 4. Card Radius, Elevation & Shape
- **Card Radius**: `BorderRadius.circular(16.0)` for standard cards; `BorderRadius.circular(20.0)` for large hero cards.
- **Modal Sheet Radius**: `BorderRadius.vertical(top: Radius.circular(24.0))`.
- **Button / Chip Radius**: `BorderRadius.circular(20.0)` or `StadiumBorder()`.
- **Elevations**: Flat Material 3 style: `elevation: 0`, using `border: Border.all(color: AppColors.borderSecondary, width: 1)` or subtle shadow `BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))`.

#### 5. Icon Mapping Table (Remix Icon to Flutter Material Icons)
| Visual Reference Icon (`Untitled.png`) | Semantic Meaning | Recommended Flutter Icon (`Icons.*`) |
|---|---|---|
| Home outline | Tổng quan (Dashboard) | `Icons.home_outlined` (active: `Icons.home`) |
| Wallet outline | Giao dịch / Tài khoản (Wallet) | `Icons.account_balance_wallet_outlined` (active: `Icons.account_balance_wallet`) |
| Sprout / Plant | Quỹ tiền (Virtual Funds / Savings) | `Icons.eco_outlined` (active: `Icons.eco`) |
| Pie chart outline | Kế hoạch (Plans & Budgets) | `Icons.pie_chart_outline` (active: `Icons.pie_chart`) |
| Bell outline | Thông báo (Notifications) | `Icons.notifications_none_outlined` |
| Filter icon | Bộ lọc giao dịch | `Icons.filter_list` |
| Magnifying glass | Tìm kiếm giao dịch | `Icons.search` |
| Plus (+) | Thêm mới (Quick-Add FAB) | `Icons.add` |
| Arrow up circle (green) | Tiền vào (Income / Deposit) | `Icons.arrow_downward` / `Icons.arrow_circle_down` |
| Arrow down circle (red) | Tiền ra (Expense / Send) | `Icons.arrow_upward` / `Icons.arrow_circle_up` |
| Lock outline | Quỹ bảo vệ (Protected Envelope) | `Icons.lock_outline` |
| Fork & bowl | Ăn uống (Food & Dining) | `Icons.restaurant` |
| Shopping basket | Mua sắm (Shopping) | `Icons.shopping_bag_outlined` |
| Car outline | Di chuyển (Transportation) | `Icons.directions_car_outlined` |
| House outline | Nhà cửa (Housing & Rent) | `Icons.home_work_outlined` |
| Bill / Document | Hoá đơn & Tiện ích (Utilities) | `Icons.receipt_long_outlined` |
| Umbrella | Quỹ khẩn cấp (Emergency fund) | `Icons.umbrella_outlined` |
| Calendar badge | Hoá đơn định kỳ (Scheduled item) | `Icons.calendar_month_outlined` |
| Target outline | Mục tiêu tiết kiệm (Savings goal) | `Icons.track_changes` / `Icons.flag_outlined` |

---

### Chapter II: Navigation Architecture & Routing Shell

```
[ MaterialApp ] (theme: Material 3, locale: vi_VN)
       │
       ▼
 [ MainNavigationShell ] ── IndexedStack (Preserves Scroll & State)
       │
       ├── Tab 0: DashboardScreen (Tổng quan)
       │     ├── AppBar Actions: [Báo cáo button], [Cài đặt button]
       │     └── Hero: SafeToSpendCard ── Tap ──> SafeToSpendBreakdownModal (BottomSheet)
       │
       ├── Tab 1: TransactionsScreen (Giao dịch)
       │     ├── SearchBar & FilterChips
       │     ├── AccountHeaderChips ── Tap ──> AccountManageSheet
       │     └── DayGroupedList ── Tap ──> TransactionDetailSheet ──> AuditHistorySheet
       │
       ├── Tab 2: VirtualFundsScreen (Quỹ tiền)
       │     ├── SummaryBar (Liquid, Reserved, Available)
       │     ├── Quick Actions: [Phân bổ], [Chuyển quỹ], [Giải phóng] (Modals)
       │     └── EnvelopeList (Protected & Flexible) ── Tap ──> FundDetailScreen (Push)
       │
       └── Tab 3: PlansScreen (Kế hoạch)
             └── SegmentedControl:
                   ├── (a) CategoryBudgetsView ── Tap ──> EditBudgetDialog
                   ├── (b) SavingsGoalsView ── FeasibilityAdvisorBanner ──> 3 Calculators
                   └── (c) ScheduledBillsForecastView ──> 30/60/90-Day CashFlowTimeline
       │
       ├── Global FAB: QuickAddModalSheet (Custom Numeric Keypad + Segmented Type)
       │
       └── Pushed Secondary Screens (via standard Navigator.push):
             ├── ReportsScreen (Báo cáo tổng hợp & Tài sản ròng)
             ├── SettingsScreen (Cài đặt, CSV Export, Sao lưu mã hoá, Khôi phục)
             └── FundDetailScreen (Lịch sử biến động quỹ)
```

---

### Chapter III: Screen-by-Screen Detailed UX Specifications

#### 1. `Tổng quan` (Dashboard)
- **Safe-to-Spend Hero Card**:
  - Container: background `surfaceAccentVerdantSecondary` (`#F3F7F5`) with decorative topographical border or verdant gradient; radius 20px; padding 20px.
  - Large Title: e.g. `1.250.000 ₫` in `AppTypography.largeTitle` with `FontFeature.tabularFigures()`.
  - Color rule: If Safe-to-Spend $> 0$, use `textAccentVerdantPrimary` (`#215B44`). If $\le 0$, use `textAccentRubyPrimary` (`#9A2329`).
  - Subtitle: `250.000 ₫/ngày (cho 5 ngày tới)`. If $\le 0$, display `0 ₫/ngày` in `textSecondary`.
  - Info button: `IconButton(icon: Icons.info_outline)` with `Semantics(identifier: 'btn_safe_to_spend_breakdown')`.
  - **Formula Breakdown Modal**:
    - Title: "Chi tiết Tiền an toàn để tiêu".
    - Formula row 1: `+ Tiền mặt & Ngân hàng: 15.000.000 ₫`.
    - Formula row 2: `- Dự trữ quỹ bảo vệ: 8.000.000 ₫` (list of protected envelopes).
    - Formula row 3: `- Nghĩa vụ chưa có quỹ dự phòng: 1.750.000 ₫` (list of pending bills minus linked envelope offsets).
    - Formula row 4: `- Ngưỡng đệm tiền mặt: 4.000.000 ₫`.
    - Formula result: `= Tiền an toàn: 1.250.000 ₫`.
- **Spending vs Budget Card**:
  - Header: "Chi tiêu tháng này".
  - Amount: `8.450.000 ₫ / 15.000.000 ₫` (56%).
  - Two-tone bar: Spent portion in `fillAccentEmberPrimary` (`#FD8240`), remaining track in `fillTertiary` (`#EFEFED`).
- **Upcoming Obligations & Next Income**:
  - Section header: "Nghĩa vụ sắp tới" with badge "2 khoản cần trả".
  - Item card: Category icon, Bill title, Due date (`Ngày mai` or `30/10`), Amount in bold VND.
  - Action button: "Đã trả" (checks off bill and records linked expense).
- **Virtual Fund Progress**:
  - Mini cards or horizontal scroll of top envelopes.
  - Shows name, icon, percentage progress, saved VND vs target VND.
- **Recent 5 Transactions**:
  - Section header: "Giao dịch gần đây" with "Xem tất cả" text button navigating to Tab 1.
  - List of 5 items: Category circular avatar, description/merchant, relative time, amount (`-50.000 ₫` in ruby red or `+5.000.000 ₫` in verdant green).
- **FAB**:
  - Anchored at bottom right, circular, background `fillAccentVerdantPrimary` (`#4E886F`), white `Icons.add`. `Semantics(identifier: 'fab_quick_add')`.

#### 2. `Giao dịch` (Transactions & Accounts)
- **Search & Filter Bar**:
  - Search field: `TextField` with `Icons.search` prefix, "Tìm kiếm theo nội dung, người nhận...".
  - Filter chips row:
    - Chip 1: `Tất cả` | `Chi tiêu` | `Thu nhập` | `Chuyển khoản` | `Trả thẻ` | `Hoàn tiền`.
    - Chip 2: Tài khoản (`Tiền mặt`, `Ngân hàng`, `Thẻ tín dụng`).
    - Chip 3: Khoảng thời gian (Tháng này, Tháng trước, Tuỳ chọn).
- **Account Management Header**:
  - Horizontal list of account cards:
    - `Tiền mặt`: `3.500.000 ₫`.
    - `Ngân hàng`: `26.400.000 ₫`.
    - `Thẻ tín dụng`: Dư nợ `500.000 ₫` (Hạn mức `20.000.000 ₫`).
  - Button `+ Thêm tài khoản` or chỉnh sửa số dư ban đầu.
- **Day-Grouped List**:
  - Header per day: `Thứ Ba, 27/10/2026` on left; daily net total on right: `Tổng: -350.000 ₫`.
  - Transaction item:
    - Left: Circular category icon (e.g. food, car, shopping).
    - Center: Description (e.g. "Cơm trưa"), subtext: account name + envelope name if linked.
    - Right: Amount formatted with tabular numerals (`-45.000 ₫`).
  - Tapping opens **Transaction Detail Sheet**:
    - Full details, postings debit/credit summary, button "Chỉnh sửa", button "Hủy giao dịch".
    - If transaction has edit/void history: button **"Lịch sử chỉnh sửa"** opens **Audit History Sheet**.
- **Audit History Bottom Sheet**:
  - Shows original transaction, voided timestamp, reversal posting details, and current replacement transaction. Complete transparency.

#### 3. Quick-Add Transaction UX (`wallet.png` reference)
- **Layout & Visual Design**:
  - Dark verdant header / background (`#215B44` or `#3D785F`) with topographical contours.
  - Close button (X) on top left.
  - Amount display: `0 ₫` default. Formatted in real-time as user taps numbers (`AppTypography.largeTitle`, white text).
- **Custom Numeric Keypad**:
  - 4 rows x 3 columns:
    ```
    [ 1 ]  [ 2 ]  [ 3 ]
    [ 4 ]  [ 5 ]  [ 6 ]
    [ 7 ]  [ 8 ]  [ 9 ]
    [   ]  [ 0 ]  [ < ]
    ```
  - Touch target size: min 48x48px (`AppSpacing.sp11`).
  - Numeric buttons have clear active feedback (ripple / opacity change).
  - Backspace button (`<`) removes last digit.
- **Segmented Selector**:
  - 5 options: `Chi tiêu` (default), `Thu nhập`, `Chuyển khoản`, `Trả thẻ`, `Hoàn tiền`.
- **Form Fields (Progressive Disclosure)**:
  - If `Chi tiêu`: Category Grid (Ăn uống, Di chuyển, Mua sắm...), Source Account (Tiền mặt, Ngân hàng, Thẻ tín dụng), optional Envelope chip, optional Note.
  - If `Thu nhập`: Income Category (Lương, Thưởng...), Destination Account.
  - If `Chuyển khoản`: Source Account $\rightarrow$ Destination Account. Category hidden.
  - If `Trả thẻ`: Source Liquid Account (Tiền mặt/Ngân hàng) $\rightarrow$ Destination Credit Card. Category hidden.
  - If `Hoàn tiền`: Category (refund credit), Receiving Account, optional original Envelope.
- **Submit Button**:
  - Ember pill button (`#FD8240`), label "Lưu giao dịch".
  - Attached with unique `idempotency_key`.

#### 4. `Quỹ tiền` (Virtual Funds / Envelopes)
- **Financial Metric Summary**:
  - Card with 3 columns:
    - `Tổng tiền mặt`: `29.900.000 ₫`.
    - `Đã dự trữ`: `15.000.000 ₫`.
    - `Khả dụng phân bổ`: `14.900.000 ₫` (highlighted in verdant green).
- **Quick Action Bar**:
  - 3 buttons: `Phân bổ` (Allocate), `Chuyển quỹ` (Transfer), `Giải phóng` (Release).
- **Sections**:
  - **Quỹ bảo vệ (Protected Envelopes)**: List of envelopes with policy `PROTECTED` (e.g. Quỹ khẩn cấp, Tiết kiệm nhà, Tiền thuê nhà). Each card shows lock icon, name, balance, target, progress bar.
  - **Quỹ linh hoạt (Flexible Envelopes)**: List of discretionary envelopes (e.g. Ăn chơi, Mua sắm cá nhân).
- **Fund Detail Screen (Pushed)**:
  - Large target & balance card.
  - Buttons: Phân bổ thêm, Rút bớt (Giải phóng), Chuyển sang quỹ khác.
  - Movement History: Complete log of `ALLOCATE`, `RELEASE`, `TRANSFER`, `SPEND`, `REFUND_RESTORE`, `REVERSAL`.

#### 5. `Kế hoạch` (Plans)
- Segmented subview control:
  - `(a) Ngân sách`: Category budgets list with month picker (`Tháng 10/2026`). Shows spent vs budget with colored threshold indicators ($<80\%$ green, $80-100\%$ orange, $>100\%$ red). Floating button "Thiết lập ngân sách".
  - `(b) Mục tiêu tiết kiệm`: Savings goals list. Each item shows target, deadline, monthly required savings computed via ceiling division: `((T - C) + N - 1) ~/ N`. Status badge (`Đã đạt`, `Quá hạn`, `Đang thực hiện`).
    - **Feasibility Advisor Banner**: If total monthly required savings exceeds available capacity, displays warning banner with 3 one-tap calculator actions:
      1. *Kéo dài thời hạn*: Calculates required new deadline months.
      2. *Giảm mục tiêu*: Calculates achievable target amount.
      3. *Tạm dừng mục tiêu*: Recommends lowest-priority goals to pause.
  - `(c) Nghĩa vụ & Dự báo`:
    - List of recurring bills and planned income.
    - Status: `PENDING` with button "Đánh dấu đã trả".
    - **30/60/90-Day Cash-Flow Projection Timeline**: Line chart / step chart projecting daily liquid assets into the future. Flags dates where balance drops below Minimum Cash Buffer.

#### 6. `Báo cáo` (Financial Reports Screen)
- Date range filter: `Tháng này` (default), `Tháng trước`, `Năm nay`, `Tuỳ chỉnh`.
- High-level KPI cards:
  - `Tổng thu nhập (Recognized Income)`: Green text.
  - `Chi tiêu gộp (Gross Expense)`: Red text.
  - `Hoàn tiền (Refunds)`: Neutral text.
  - `Chi tiêu ròng (Net Expense)`: `Gross - Refunds`. If negative, shows "Thu hồi chi phí ròng".
  - `Tỷ lệ tiết kiệm (Saving Rate)`: e.g. `45%`. If income $\le 0$, displays `"Chưa có thu nhập"`.
  - `Tài sản ròng (Net Worth)`: `Liquid Assets - Credit Card Liabilities`.
- Category Expense Breakdown: Custom row-based distribution bars sorted by expense amount.

#### 7. `Cài đặt & Sao lưu` (Settings & Backup Screen)
- **Nhóm Cấu hình tài chính**:
  - `Đệm tiền mặt tối thiểu`: Text field formatted in VND (e.g. `5.000.000 ₫`).
  - `Ngày bắt đầu chu kỳ`: Picker from 1 to 31 (default 1).
- **Nhóm Thông báo**:
  - Switch: `Bật thông báo nhắc nhở`.
  - Time picker: `Giờ thông báo hàng ngày` (default `20:00`).
  - System permission status badge: `Đã cấp quyền` / `Bị từ chối` (with button to open Android Settings).
- **Nhóm Dữ liệu & Sao lưu**:
  - `Xuất dữ liệu CSV`: Generates CSV and opens `share_plus` share sheet.
  - `Sao lưu mã hoá (.dongtien)`: Prompts for password, runs PBKDF2 + AES-GCM in isolate, exports encrypted file via share sheet.
  - `Khôi phục từ tệp sao lưu`: Opens `file_picker`, prompts for password, runs decryption & validation in isolate, displays confirmation dialog, and restores inside single DB transaction.
- **Nhóm Quản trị dữ liệu**:
  - `Tạo dữ liệu mẫu (Demo)`: Generates Vietnamese demo data (with confirmation modal).
  - `Xóa toàn bộ dữ liệu (Reset)`: Destructive action requiring confirmation dialog, resetting database to initial 0 ₫ seeding.

#### 8. Accessibility Semantics Specification (`Semantics`)
All interactive elements MUST have deterministic `Semantics(identifier: ...)`:
- Navigation:
  - `nav_tab_dashboard`
  - `nav_tab_transactions`
  - `nav_tab_funds`
  - `nav_tab_plans`
- Dashboard:
  - `hero_safe_to_spend`
  - `btn_safe_to_spend_breakdown`
  - `card_spending_vs_budget`
  - `fab_quick_add`
- Quick-Add Keypad:
  - `keypad_btn_0` through `keypad_btn_9`
  - `keypad_btn_backspace`
  - `input_amount_display`
  - `segment_expense`, `segment_income`, `segment_transfer`, `segment_card_payment`, `segment_refund`
  - `btn_submit_transaction`
- Transactions:
  - `input_search_tx`
  - `chip_filter_all`, `chip_filter_expense`, `chip_filter_income`
  - `btn_account_manage`
- Virtual Funds:
  - `card_summary_liquid`, `card_summary_reserved`, `card_summary_available`
  - `btn_allocate_fund`, `btn_transfer_fund`, `btn_release_fund`
- Plans:
  - `tab_category_budgets`, `tab_savings_goals`, `tab_scheduled_bills`
  - `btn_feasibility_advisor`
- Settings & Backup:
  - `input_cash_buffer`
  - `toggle_notifications`
  - `btn_export_csv`
  - `btn_encrypted_backup`
  - `btn_encrypted_restore`
  - `btn_generate_sample_data`
  - `btn_reset_database`

---

### Chapter IV: Compliant Local Notifications (Android 12–15+)

#### 1. Manifest Permissions
In `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Declare ONLY these two permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- STRICTLY PROHIBITED: Do NOT declare SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM -->
```

#### 2. Local Notifications Plugin Initialization & Channels
```dart
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel dailySummaryChannel = AndroidNotificationChannel(
  'dongtien_daily_summary',
  'Nhắc nhở hàng ngày',
  description: 'Thông báo tổng kết chi tiêu và tiền an toàn hàng ngày',
  importance: Importance.high,
);

const AndroidNotificationChannel obligationsChannel = AndroidNotificationChannel(
  'dongtien_obligations',
  'Hoá đơn & Nghĩa vụ tài chính',
  description: 'Nhắc nhở hoá đơn sắp đến hạn và mục tiêu tiết kiệm',
  importance: Importance.high,
);

const AndroidNotificationChannel budgetAlertsChannel = AndroidNotificationChannel(
  'dongtien_budget_alerts',
  'Cảnh báo ngân sách',
  description: 'Cảnh báo khi chi tiêu vượt quá 80% hoặc 100% ngân sách danh mục',
  importance: Importance.max,
);
```

#### 3. Scheduling Configuration
Must use `AndroidScheduleMode.inexactAllowWhileIdle`:
```dart
await flutterLocalNotificationsPlugin.zonedSchedule(
  notificationId,
  title,
  body,
  scheduledDate,
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
);
```

#### 4. Notification Triggers & Payloads
- **Trigger A: Daily Summary Reminder**:
  - Time: user-configured `daily_reminder_hour` and `daily_reminder_minute` (default 20:00).
  - Title: "Tổng kết tài chính hôm nay".
  - Body: "Hôm nay bạn đã chi ${todayExpense}. Tiền an toàn còn lại: ${safeToSpend}."
- **Trigger B: Upcoming Bill Reminder**:
  - Time: `due_date_ms - (reminder_days_before * 86400000)` at 09:00 AM.
  - Title: "Hoá đơn sắp đến hạn: ${bill.title}".
  - Body: "Khoản tiền ${bill.amount} đến hạn vào ${formattedDueDate}."
- **Trigger C: Budget Threshold Alerts (80% / 100%)**:
  - Fired immediately on transaction posting when spending crosses threshold.
  - 80% alert: "Cảnh báo ngân sách: Danh mục ${category.name} đã chi 80% hạn mức (${spent}/${limit})."
  - 100% alert: "Cảnh báo vượt ngân sách: Danh mục ${category.name} đã chi vượt ngân sách (${spent}/${limit})!"

#### 5. Scenario 15 Resilience (Permission Denied & System Settings)
- On app launch, query permission status via `flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()`.
- If permission is denied or revoked:
  - App continues running without exceptions.
  - All financial transactions and calculations work 100% normally.
  - Settings UI displays an alert card:
    "Quyền thông báo đang bị tắt. Nhấn vào đây để mở Cài đặt thiết bị và nhận nhắc nhở chi tiêu."

---

### Chapter V: Android Hardening & Isolate-Based Encrypted Backup/Restore

#### 1. Android Manifest Hardening & Data Extraction Rules
In `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:label="DongTien"
    android:allowBackup="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="@xml/backup_rules">
```

In `android/app/src/main/res/xml/data_extraction_rules.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <!-- Exclude app SQLite database and sensitive files from cloud backup -->
        <exclude path="databases" />
        <exclude path="app_flutter" />
    </cloud-backup>
    <device-to-device>
        <!-- Exclude database from device-to-device migration -->
        <exclude path="databases" />
        <exclude path="app_flutter" />
    </device-to-device>
</data-extraction-rules>
```

In `android/app/src/main/res/xml/backup_rules.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="database" path="." />
    <exclude domain="file" path="." />
</full-backup-content>
```

#### 2. Outer JSON Cryptographic Envelope
```json
{
  "magic": "DONGTIEN_ENC_V1",
  "formatVersion": 1,
  "schemaVersion": 1,
  "createdAtIso": "2026-10-27T10:15:00+07:00",
  "kdf": "PBKDF2-HMAC-SHA256",
  "kdfIterations": 120000,
  "saltB64": "vF3+9xL0pQ1kM8...",
  "cipher": "AES-256-GCM",
  "nonceB64": "k7Lm9P4qR1sT...",
  "ciphertextB64": "x9J2kL8mP0...",
  "macB64": "w3Er5Ty7Ui9O..."
}
```

#### 3. Off-Main-Thread Execution Architecture (`Isolate.run`)
Heavy cryptographic derivation and decryption must never block the UI thread:
```dart
// Backup Generation in Isolate
final String encryptedJson = await Isolate.run(() async {
  final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));

  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );
  final secretKey = await pbkdf2.deriveKeyFromPassword(
    password: password,
    nonce: salt,
  );

  final algorithm = AesGcm.with256Bits();
  final secretBox = await algorithm.encrypt(
    utf8.encode(plainJsonPayload),
    secretKey: secretKey,
    nonce: nonce,
  );

  return jsonEncode({
    "magic": "DONGTIEN_ENC_V1",
    "formatVersion": 1,
    "schemaVersion": 1,
    "createdAtIso": DateTime.now().toIso8601String(),
    "kdf": "PBKDF2-HMAC-SHA256",
    "kdfIterations": 120000,
    "saltB64": base64Encode(salt),
    "cipher": "AES-256-GCM",
    "nonceB64": base64Encode(nonce),
    "ciphertextB64": base64Encode(secretBox.cipherText),
    "macB64": base64Encode(secretBox.mac.bytes),
  });
});
```

#### 4. The 6-Stage Validation & Restore Pipeline
```
[ Step 1: File Size Check ]
  └─ If file.length > 25 MB (26,214,400 bytes) ──> Throw BackupSizeExceededException
           │
           ▼
[ Step 2: Outer JSON Header & Magic Check ]
  └─ If "magic" != "DONGTIEN_ENC_V1" or iterations < 100,000 ──> Throw InvalidBackupFormatException
           │
           ▼
[ Step 3: Off-Main-Thread Decryption (Isolate.run) ]
  ├─ Derive PBKDF2 key from password + saltB64
  ├─ Decrypt ciphertextB64 with nonceB64 & authenticate with macB64
  └─ If wrong password or tampered byte ──> SecretBoxAuthenticationError ──> Throw InvalidCredentialsException
           │
           ▼
[ Step 4: In-Memory Structural Invariant Validation ]
  ├─ Verify all 9 tables exist in decrypted JSON
  ├─ Invariant A: For every transaction, SUM(debit_vnd) == SUM(credit_vnd)
  ├─ Invariant B: All foreign keys resolve to valid entities
  ├─ Invariant C: All monetary amounts are integers >= 0
  └─ If any invariant fails ──> Throw BackupCorruptException (SQLite untouched)
           │
           ▼
[ Step 5: User Confirmation Dialog ]
  ├─ Display: createdAtIso, number of accounts, transactions, envelopes, budgets
  └─ Warning: "Khôi phục sẽ thay thế toàn bộ dữ liệu hiện tại." -> Cancel or Confirm
           │
           ▼
[ Step 6: Atomic Database Restore (Single db.transaction) ]
  ├─ Clear existing tables in reverse dependency order
  ├─ Insert validated records in topological order
  └─ If any SQL error occurs ──> Transaction rolls back completely (data intact)
```

---

## 6. Implementation Readiness & Feature Group Allocation

| Component | Target Implementation Directory | Sub-Agent Ownership |
|---|---|---|
| Design Tokens & Theme | `lib/app/theme/` (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`) | UI Track (Phase 3) |
| App Shell & Navigation | `lib/app/app.dart` (`IndexedStack` shell) | UI Track (Phase 3) |
| Dashboard Slice | `lib/features/dashboard/` | UI Track (Phase 3) |
| Transactions & Accounts | `lib/features/transactions/`, `lib/features/accounts/` | UI Track (Phase 3) |
| Virtual Funds (Envelopes) | `lib/features/envelopes/` | UI Track (Phase 3) |
| Plans (Budgets, Goals, Forecast) | `lib/features/plans/` | UI Track (Phase 4) |
| Reports & Settings | `lib/features/reports_settings/` | UI Track (Phase 4) |
| Local Notifications Service | `lib/core/notifications/` | UI/Core Track (Phase 4) |
| Hardened Crypto & Backup Service | `lib/core/security/` | Core Track (Phase 4) |
| Android Manifest & Rules | `android/app/src/main/` | Core Track (Phase 4) |
