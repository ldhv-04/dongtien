# DESIGN SYSTEM & ACCEPTANCE TEST PLAN — ĐỒNG TIỀN

> **Authoritative UI/UX Design System Tokens, Screen Map, Accessibility Identifiers & 15 Acceptance Test Scenarios**  
> Application: **Đồng Tiền** (`vn.dongtien`)  
> Target Platform: Android (Offline-First, Material 3, `vi_VN` Locale)

---

## 1. DESIGN SYSTEM TOKENS (EXTRACTED FROM `design_refs/`)

The design system is extracted directly from the pixel specifications in `docs/design_refs/`. It establishes an intentional, calm, and trustworthy aesthetic tailored to the Vietnamese culture and currency.

### 1.1 Spacing Token Scale (`Spacing.png`)
Base grid unit: 4px. All component margins, padding, and layout gutters MUST map to these tokens:

| Token | Pixels | Semantic Usage |
|---|---|---|
| `AppSpacing.sp0` | `0.0` | Zero margin / reset |
| `AppSpacing.sp1` | `1.0` | Hairline dividers, subtle card borders |
| `AppSpacing.sp2` | `2.0` | Active indicator stroke, focus outlines |
| `AppSpacing.sp3` | `4.0` | Extra-small tight gaps (e.g. icon-to-badge, dense metadata) |
| `AppSpacing.sp4` | `8.0` | Small gaps, internal chip padding, list item vertical padding |
| `AppSpacing.sp5` | `12.0` | Medium compact gap, form field vertical margin |
| `AppSpacing.sp6` | `16.0` | Standard card internal padding, screen side margins |
| `AppSpacing.sp7` | `20.0` | Section spacing, hero card internal padding |
| `AppSpacing.sp8` | `24.0` | Major card separation, bottom sheet top header padding |
| `AppSpacing.sp9` | `32.0` | Screen section separation, empty state vertical clearance |
| `AppSpacing.sp10` | `40.0` | Hero card vertical margins, modal action clearance |
| `AppSpacing.sp11` | `48.0` | Minimum touch target size, keypad button diameter |
| `AppSpacing.sp12` | `64.0` | Spacious layout separators, bottom scroll padding |
| `AppSpacing.sp13` | `80.0` | Bottom navigation bar clearance padding |
| `AppSpacing.sp14` | `96.0` | Hero balance display vertical clearance |
| `AppSpacing.sp15` | `128.0` | Maximum visual breathing room |

```dart
class AppSpacing {
  static const double sp0 = 0.0;
  static const double sp1 = 1.0;
  static const double sp2 = 2.0;
  static const double sp3 = 4.0;
  static const double sp4 = 8.0;
  static const double sp5 = 12.0;
  static const double sp6 = 16.0;
  static const double sp7 = 20.0;
  static const double sp8 = 24.0;
  static const double sp9 = 32.0;
  static const double sp10 = 40.0;
  static const double sp11 = 48.0;
  static const double sp12 = 64.0;
  static const double sp13 = 80.0;
  static const double sp14 = 96.0;
  static const double sp15 = 128.0;
}
```

---

### 1.2 Typography Tokens (`Untitled-2.png`)
All text widgets displaying monetary figures (`VndMoney`), percentages, or dates MUST explicitly include `fontFeatures: [FontFeature.tabularFigures()]` to ensure fixed-width numerical glyphs and eliminate layout jitter.

| Typography Tier | Font Size | Line Height | Relative Height | Weight | Typical Application |
|---|---|---|---|---|---|
| `Large Title` | 32px | 48px | 1.50 | Medium (w500) | Hero Safe-to-Spend balance, Keypad amount display |
| `Title` | 24px | 36px | 1.50 | Medium (w500) | Screen titles, Fund total balance |
| `Headline` | 20px | 30px | 1.50 | Medium (w500) | Card headers, Modal sheet titles |
| `Body` | 16px | 24px | 1.50 | Regular (w400) | Transaction descriptions, list items, input fields |
| `Body Medium` | 16px | 24px | 1.50 | Medium (w500) | Emphasis in body, primary button text |
| `Subheadline` | 14px | 20px | 1.43 | Regular (w400) | Account names, filter chips, category subtext |
| `Footnote` | 12px | 16px | 1.33 | Regular (w400) | Timestamps, secondary metadata, helper text |
| `Caption` | 10px | 14px | 1.40 | Regular (w400) | Category icon labels, micro badges |

```dart
class AppTypography {
  static const TextStyle largeTitle = TextStyle(
    fontSize: 32,
    height: 48 / 32,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle title = TextStyle(
    fontSize: 24,
    height: 36 / 24,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 20,
    height: 30 / 20,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle subheadline = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w400,
  );
}
```

---

### 1.3 Semantic Color Palette (`Untitled-3.png`)
Extracted verbatim from the design reference token specifications across the 7 color families:

```dart
class AppColors {
  // Text Tokens
  static const Color textPrimary = Color(0xFF4D4845);               // charcoal-16
  static const Color textSecondary = Color(0xFF65605C);             // charcoal-12
  static const Color textTertiary = Color(0xFF928F8B);              // charcoal-09
  static const Color textDisabled = Color(0xFFDBDBD8);              // charcoal-05
  static const Color textInverse = Color(0xFFFFFFFF);               // neutral-01
  static const Color textAccentVerdantPrimary = Color(0xFF215B44);   // verdant-14 (Safe-to-Spend positive)
  static const Color textAccentVerdantSecondary = Color(0xFF3D785F); // verdant-11 (Income text)
  static const Color textAccentSandstonePrimary = Color(0xFF764527); // sandstone-14
  static const Color textAccentSandstoneSecondary = Color(0xFF976035); // sandstone-11
  static const Color textAccentEmberPrimary = Color(0xFF8B3711);     // ember-14
  static const Color textAccentEmberSecondary = Color(0xFFB84B17);   // ember-11
  static const Color textAccentRubyPrimary = Color(0xFF9A2329);      // ruby-14 (Deficit / Overbudget danger)
  static const Color textAccentRubySecondary = Color(0xFFC9362B);    // ruby-11 (Expense text)
  static const Color textAccentMarigoldPrimary = Color(0xFF823F00);  // marigold-14
  static const Color textAccentMarigoldSecondary = Color(0xFFAC5500);// marigold-11 (Warning text)

  // Surface Tokens
  static const Color surfacePrimary = Color(0xFFFFFFFF);            // neutral-01 (Card backgrounds)
  static const Color surfaceSecondary = Color(0xFFF6F6F4);          // charcoal-01 (Scaffold background)
  static const Color surfaceTertiary = Color(0xFFEFEFED);           // charcoal-03 (Dividers, track fill)
  static const Color surfaceOverlay = Color(0x634D4845);            // alpha-09 (Modal barrier 39%)
  static const Color surfaceAccentVerdantPrimary = Color(0xFF3D785F); // verdant-11
  static const Color surfaceAccentVerdantSecondary = Color(0xFFF3F7F5); // verdant-01 (Hero card background)
  static const Color surfaceAccentSandstonePrimary = Color(0xFFD59D6F); // sandstone-09
  static const Color surfaceAccentSandstoneSecondary = Color(0xFFFDF6E4); // sandstone-01
  static const Color surfaceAccentEmberPrimary = Color(0xFFE86B1C); // ember-08
  static const Color surfaceAccentEmberSecondary = Color(0xFFFFF4F0); // ember-01
  static const Color surfaceAccentRubyPrimary = Color(0xFFE55959);  // ruby-11
  static const Color surfaceAccentRubySecondary = Color(0xFFFFF4F1); // ruby-01 (Deficit card background)
  static const Color surfaceAccentMarigoldPrimary = Color(0xFFFFC542); // marigold-05
  static const Color surfaceAccentMarigoldSecondary = Color(0xFFFFF5E3); // marigold-01

  // Fill Tokens
  static const Color fillPrimary = Color(0xFFFFFFFF);               // neutral-01
  static const Color fillSecondary = Color(0xFFF6F6F4);             // charcoal-01
  static const Color fillTertiary = Color(0xFFEFEFED);              // charcoal-03
  static const Color fillAccentVerdantPrimary = Color(0xFF4E886F);   // verdant-10 (FAB & Save button)
  static const Color fillAccentVerdantSecondary = Color(0xFFF3F7F5); // verdant-01
  static const Color fillAccentSandstonePrimary = Color(0xFFF0AB59); // sandstone-07
  static const Color fillAccentSandstoneSecondary = Color(0xFFFDF6E4); // sandstone-01
  static const Color fillAccentEmberPrimary = Color(0xFFFD8240);     // ember-08 (CTA buttons)
  static const Color fillAccentEmberSecondary = Color(0xFFFFF4F0);   // ember-01
  static const Color fillAccentRubyPrimary = Color(0xFFF55D3E);      // ruby-09 (Danger buttons)
  static const Color fillAccentRubySecondary = Color(0xFFFFF4F1);    // ruby-01
  static const Color fillAccentMarigoldPrimary = Color(0xFFFAA800);  // marigold-07 (Warning progress)
  static const Color fillAccentMarigoldSecondary = Color(0xFFFFF5E3);// marigold-01

  // Border Tokens
  static const Color borderPrimary = Color(0xFFF4F4F2);             // charcoal-02
  static const Color borderSecondary = Color(0xFFE7E7E4);           // charcoal-04 (Standard card border)
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

---

### 1.4 Card Radius, Elevation & Shape
- **Standard Card Radius**: `BorderRadius.circular(16.0)` with border `Border.all(color: AppColors.borderSecondary, width: 1.0)`. Elevation = 0.
- **Hero Card Radius**: `BorderRadius.circular(20.0)`.
- **Modal Sheet Radius**: `BorderRadius.vertical(top: Radius.circular(24.0))`.
- **Action Buttons & Chips**: `BorderRadius.circular(20.0)` or `StadiumBorder()`.

---

### 1.5 Remix Icon to Flutter Material Icons Mapping (`Untitled.png`)

| Semantic Function | Reference Icon | Recommended Material Icon (`Icons.*`) |
|---|---|---|
| Tab 0: Tổng quan | Home Outline | `Icons.home_outlined` (active: `Icons.home`) |
| Tab 1: Giao dịch | Wallet Outline | `Icons.account_balance_wallet_outlined` (active: `Icons.account_balance_wallet`) |
| Tab 2: Quỹ tiền | Sprout / Seedling | `Icons.eco_outlined` (active: `Icons.eco`) |
| Tab 3: Kế hoạch | Pie Chart Outline | `Icons.pie_chart_outline` (active: `Icons.pie_chart`) |
| Notifications | Bell Outline | `Icons.notifications_none_outlined` |
| Filter Actions | Filter Lines | `Icons.filter_list` |
| Search Bar | Magnifying Glass | `Icons.search` |
| Quick-Add FAB | Plus Sign | `Icons.add` |
| Protected Fund | Lock Outline | `Icons.lock_outline` |
| Flexible Fund | Sparkles / Sliders | `Icons.tune_outlined` |
| Category: Ăn uống | Bowl & Chopsticks | `Icons.restaurant` |
| Category: Di chuyển | Car Outline | `Icons.directions_car_outlined` |
| Category: Hoá đơn | Receipt Document | `Icons.receipt_long_outlined` |
| Category: Nhà cửa | House Outline | `Icons.home_work_outlined` |
| Category: Mua sắm | Shopping Bag | `Icons.shopping_bag_outlined` |
| Category: Y tế | Hospital Cross | `Icons.local_hospital_outlined` |
| Category: Lương | Work Briefcase | `Icons.work_outline` |
| Category: Thưởng | Gift Box | `Icons.card_giftcard_outlined` |

---

## 2. CUSTOM NUMERIC KEYPAD SPECIFICATION (`wallet.png`)

Fast transaction entry is critical for personal finance usability. Opening the Quick-Add modal sheet focuses the custom numeric keypad immediately.

### 2.1 Keypad Layout & Dimensions
- **Grid Layout**: 4 rows $\times$ 3 columns.
  ```text
  ┌───────┬───────┬───────┐
  │   1   │   2   │   3   │
  ├───────┼───────┼───────┤
  │   4   │   5   │   6   │
  ├───────┼───────┼───────┤
  │   7   │   8   │   9   │
  ├───────┼───────┼───────┤
  │       │   0   │   <   │
  └───────┴───────┴───────┘
  ```
- **Button Dimensions**: Minimum touch target of 48x48px (`AppSpacing.sp11`), recommended 64px width $\times$ 56px height.
- **Topographical Theme**: Background `surfaceAccentVerdantPrimary` (`#3D785F`) or dark verdant (`#215B44`). Text in `textInverse` (`#FFFFFF`).
- **Backspace Key (`<`)**: Clears the rightmost digit. If amount reaches 0, displays `0 ₫`.
- **Formatted Display**: The entered number formats dynamically in real-time as whole VND (e.g., `1` $\to$ `1 ₫`, `10` $\to$ `10 ₫`, `1000` $\to$ `1.000 ₫`, `1250000` $\to$ `1.250.000 ₫`).

### 2.2 Segmented Type Selector & Progressive Form Fields
Located immediately below the amount display:
- **Segments**: `Chi tiêu` (Expense, default) | `Thu nhập` (Income) | `Chuyển khoản` (Transfer) | `Trả thẻ` (Card Payment) | `Hoàn tiền` (Refund).
- **Dynamic Field Display**:
  - `Chi tiêu`: Category Grid (Expense), Source Account chip (`Tiền mặt`/`Ngân hàng`/`Thẻ tín dụng`), optional Envelope chip, optional Note.
  - `Thu nhập`: Category Grid (Income), Destination Account chip (`Tiền mặt`/`Ngân hàng`).
  - `Chuyển khoản`: Source Account chip $\to$ Destination Account chip. Category hidden.
  - `Trả thẻ`: Source Liquid Account chip $\to$ Destination Credit Card chip. Category hidden.
  - `Hoàn tiền`: Category Grid (Expense), Receiving Account chip, optional Envelope restore chip.
- **Submit CTA**: Full-width Ember pill button (`AppColors.fillAccentEmberPrimary` `#FD8240`), label "Lưu giao dịch". Attached with a unique client `idempotency_key`.

---

## 3. SCREEN MAP & NAVIGATION ARCHITECTURE

```text
                     [ MaterialApp ] (vi_VN, Material 3)
                            │
                            ▼
      [ MainNavigationShell ] (IndexedStack preserves state)
        ├── Tab 0: DashboardScreen (Tổng quan)
        │     ├── SafeToSpendHeroCard ──> [BottomSheet: SafeToSpendBreakdownModal]
        │     ├── SpendingVsBudgetCard
        │     ├── UpcomingObligationsCard
        │     ├── VirtualFundsProgressCard
        │     ├── RecentTransactionsList
        │     └── AppBar Actions ──> [Push: ReportsScreen], [Push: SettingsScreen]
        │
        ├── Tab 1: TransactionsScreen (Giao dịch)
        │     ├── SearchBar & FilterChips
        │     ├── AccountManagementHeader (Cash, Bank, Cards)
        │     └── DayGroupedTransactionList ──> [BottomSheet: TransactionDetailSheet]
        │                                             └──> [BottomSheet: AuditHistorySheet]
        │
        ├── Tab 2: VirtualFundsScreen (Quỹ tiền)
        │     ├── MetricSummaryBar (Liquid, Reserved, Available)
        │     ├── QuickActions: [Modal: Allocate], [Modal: Transfer], [Modal: Release]
        │     └── EnvelopesList (Protected & Flexible) ──> [Push: FundDetailScreen]
        │
        ├── Tab 3: PlansScreen (Kế hoạch)
        │     └── SegmentedSubviews:
        │           ├── (a) CategoryBudgetsView ──> [Dialog: EditBudgetDialog]
        │           ├── (b) SavingsGoalsView ──> [FeasibilityAdvisorBanner]
        │           │                                └──> [3 One-Tap Calculators]
        │           └── (c) ObligationsForecastView ──> [30/60/90-Day CashFlowTimeline]
        │
        └── Global Floating Action Button: QuickAddModalSheet (Keypad + Form)
```

---

## 4. SEMANTICS IDENTIFIER MAP FOR AUTOMATED TESTING

Every interactive element and primary summary card MUST attach a deterministic `Semantics` widget using these exact identifiers:

### 4.1 Navigation & Shell
- `nav_tab_dashboard`: Bottom navigation item for "Tổng quan"
- `nav_tab_transactions`: Bottom navigation item for "Giao dịch"
- `nav_tab_funds`: Bottom navigation item for "Quỹ tiền"
- `nav_tab_plans`: Bottom navigation item for "Kế hoạch"
- `btn_appbar_reports`: AppBar action to open Reports screen
- `btn_appbar_settings`: AppBar action to open Settings screen
- `fab_quick_add`: Floating action button opening Quick-Add modal

### 4.2 Dashboard (`Tổng quan`)
- `hero_safe_to_spend`: Hero card container for Safe-to-Spend
- `text_safe_to_spend_amount`: Text displaying the Safe-to-Spend VND amount
- `text_daily_allowance`: Text displaying daily allowance rate (e.g. `250.000 ₫/ngày`)
- `btn_safe_to_spend_breakdown`: Info button opening formula breakdown modal
- `modal_safe_to_spend_breakdown`: Formula breakdown bottom sheet container
- `card_spending_vs_budget`: Spending vs monthly budget card
- `card_upcoming_obligations`: Pending bills and planned income card
- `btn_pay_obligation_<id>`: Quick "Đã trả" action button for a scheduled bill

### 4.3 Custom Numeric Keypad & Quick-Add
- `modal_quick_add`: Quick-add modal sheet container
- `input_amount_display`: Formatted VND amount display
- `keypad_btn_0` through `keypad_btn_9`: Numeric keypad buttons
- `keypad_btn_backspace`: Backspace button (`<`)
- `segment_expense`: Segment button for "Chi tiêu"
- `segment_income`: Segment button for "Thu nhập"
- `segment_transfer`: Segment button for "Chuyển khoản"
- `segment_card_payment`: Segment button for "Trả thẻ"
- `segment_refund`: Segment button for "Hoàn tiền"
- `chip_category_<id>`: Category selection chip
- `chip_source_account_<id>`: Source account selection chip
- `chip_dest_account_<id>`: Destination account selection chip
- `chip_envelope_<id>`: Optional envelope selection chip
- `btn_submit_transaction`: "Lưu giao dịch" submit button

### 4.4 Transactions & Accounts
- `input_search_tx`: Search text field
- `chip_filter_all`, `chip_filter_expense`, `chip_filter_income`: Filter chips
- `card_account_<id>`: Account balance card
- `btn_manage_accounts`: Button to open account management drawer/sheet
- `item_transaction_<id>`: Day-grouped transaction row
- `sheet_transaction_detail`: Transaction detail bottom sheet
- `btn_void_transaction`: "Hủy giao dịch" action button
- `btn_edit_transaction`: "Chỉnh sửa" action button
- `btn_audit_history`: "Lịch sử chỉnh sửa" button
- `sheet_audit_history`: Audit history revision chain bottom sheet

### 4.5 Virtual Funds (`Quỹ tiền`)
- `card_summary_liquid`: Summary card for Liquid Assets
- `card_summary_reserved`: Summary card for Total Reserved Balance
- `card_summary_available`: Summary card for Available-to-Allocate
- `btn_allocate_fund`: Quick action "Phân bổ"
- `btn_transfer_fund`: Quick action "Chuyển quỹ"
- `btn_release_fund`: Quick action "Giải phóng"
- `card_envelope_<id>`: Envelope card item
- `screen_fund_detail`: Fund detail screen container

### 4.6 Plans (`Kế hoạch`)
- `tab_category_budgets`: Sub-segment "Ngân sách"
- `tab_savings_goals`: Sub-segment "Mục tiêu tiết kiệm"
- `tab_scheduled_bills`: Sub-segment "Nghĩa vụ & Dự báo"
- `card_budget_<id>`: Category budget card with progress bar
- `card_goal_<id>`: Savings goal card
- `banner_feasibility_advisor`: Feasibility warning banner
- `btn_advisor_extend_deadline`: One-tap calculator to extend deadline
- `btn_advisor_lower_target`: One-tap calculator to lower target
- `btn_advisor_pause_goals`: One-tap calculator to pause low-priority goals
- `timeline_cash_flow_forecast`: Cash flow forecast timeline widget

### 4.7 Settings & Backup
- `input_cash_buffer`: Input field for Minimum Cash Buffer
- `input_period_start_day`: Picker for period boundary day
- `toggle_notifications`: Switch toggle for notifications
- `btn_export_csv`: "Xuất CSV" button
- `btn_encrypted_backup`: "Sao lưu mã hoá" button
- `btn_encrypted_restore`: "Khôi phục dữ liệu" button
- `btn_generate_sample_data`: "Tạo dữ liệu mẫu" demo button
- `btn_reset_database`: "Xóa toàn bộ dữ liệu" reset button

---

## 5. COMPLIANT LOCAL NOTIFICATIONS SPECIFICATION

### 5.1 Android Permissions & Inexact Scheduling
- **Manifest Permissions**:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
  ```
  *(Zero declaration of `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` to guarantee Google Play compliance).*
- **Scheduling API**:
  ```dart
  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle
  ```

### 5.2 Notification Channels
1. `dongtien_daily_summary`: "Nhắc nhở hàng ngày" (Importance: High)
2. `dongtien_obligations`: "Hoá đơn & Nghĩa vụ tài chính" (Importance: High)
3. `dongtien_budget_alerts`: "Cảnh báo ngân sách" (Importance: Max)

### 5.3 Triggers & Dynamic Content
- **Daily Summary**: Triggered at user-configured time (`HH:mm`, default `20:00`). Content: "Hôm nay bạn đã chi ${todayExpense}. Tiền an toàn còn lại: ${safeToSpend}."
- **Upcoming Bill**: Triggered `reminder_days_before` at 09:00 AM. Content: "Hoá đơn sắp đến hạn: ${bill.title} (${bill.amount}) vào ngày ${dueDate}."
- **Budget Thresholds (80% / 100%)**: Triggered immediately when a posted expense pushes a category over 80% or 100% of its monthly limit.

### 5.4 Graceful Degradation (Scenario 15)
If `POST_NOTIFICATIONS` is denied by the user:
- The app operates with 100% functionality. Zero crashes, zero blocked transactions.
- Settings screen displays a non-blocking informational card: "Quyền thông báo đang bị tắt. Nhấn vào đây để mở Cài đặt thiết bị."

---

## 6. DETAILED ACCEPTANCE TEST MATRIX (THE 15 MANDATORY SCENARIOS)

Every automated scenario must assert exact database values and mathematical equations.

---

### Scenario 1: Opening Asset (`10.000.000 ₫`)
- **Objective**: Verify that initializing starting cash establishes liquid assets without fabricating operating income.
- **Preconditions**: Fresh database, zero transactions.
- **Action**: Post `OPENING_BALANCE` of `10.000.000 ₫` to `ASSET_CASH`.
- **Postings**:
  - Debit: `ASSET_CASH` = `10.000.000 ₫`
  - Credit: `EQUITY_OPENING` = `10.000.000 ₫`
- **Assertions**:
  - `ledger_accounts.ASSET_CASH.balance == 10000000`
  - `total_liquid_assets == 10000000`
  - `recognized_income == 0` (Operating income is strictly 0 ₫)
  - `net_expense == 0`
  - `net_worth == 10000000`
  - `available_to_allocate == 10000000` (buffer = 0 ₫)
  - `Safe-to-Spend == 10000000`

---

### Scenario 2: Salary (`20.000.000 ₫`)
- **Objective**: Verify that salary income increases liquid assets and operating income, resulting in a 100% savings rate when net expenses are zero.
- **Preconditions**: State from Scenario 1 (`total_liquid_assets = 10.000.000 ₫`).
- **Action**: Post `INCOME` of `20.000.000 ₫` to `ASSET_BANK` linked to Category `Lương`.
- **Postings**:
  - Debit: `ASSET_BANK` = `20.000.000 ₫`
  - Credit: `INCOME` (`Lương`) = `20.000.000 ₫`
- **Assertions**:
  - `ledger_accounts.ASSET_BANK.balance == 20000000`
  - `total_liquid_assets == 30000000` (10M + 20M)
  - `recognized_income == 20000000`
  - `net_expense == 0`
  - `net_saving == 20000000`
  - `saving_rate == 1.0` (100%)
  - `Safe-to-Spend == 30000000`

---

### Scenario 3: Cash Expense (`100.000 ₫`)
- **Objective**: Verify that a cash purchase decreases liquid assets and increases net expenses.
- **Preconditions**: State from Scenario 2 (`total_liquid_assets = 30.000.000 ₫`).
- **Action**: Post `EXPENSE` of `100.000 ₫` via `ASSET_CASH` for Category `Ăn uống` (no envelope).
- **Postings**:
  - Debit: `EXPENSE` (`Ăn uống`) = `100.000 ₫`
  - Credit: `ASSET_CASH` = `100.000 ₫`
- **Assertions**:
  - `ledger_accounts.ASSET_CASH.balance == 9900000` (10.000.000 - 100.000)
  - `total_liquid_assets == 29900000` (9.9M + 20M)
  - `gross_expense == 100000`
  - `net_expense == 100000`
  - `recognized_income == 20000000`
  - `net_saving == 19900000`
  - `saving_rate == 0.995` (`(20.000.000 - 100.000) / 20.000.000 = 99.5%`)
  - `Safe-to-Spend == 29900000`

---

### Scenario 4: Internal Transfer (`2.000.000 ₫`)
- **Objective**: Verify that shifting cash between bank and cash accounts does not alter total liquid assets, income, or expenses.
- **Preconditions**: State from Scenario 3 (`ASSET_CASH = 9.9M ₫`, `ASSET_BANK = 20M ₫`).
- **Action**: Post `INTERNAL_TRANSFER` of `2.000.000 ₫` from `ASSET_BANK` to `ASSET_CASH`.
- **Postings**:
  - Debit: `ASSET_CASH` = `2.000.000 ₫`
  - Credit: `ASSET_BANK` = `2.000.000 ₫`
- **Assertions**:
  - `ledger_accounts.ASSET_CASH.balance == 11900000` (9.9M + 2M)
  - `ledger_accounts.ASSET_BANK.balance == 18000000` (20M - 2M)
  - `total_liquid_assets == 29900000` (UNCHANGED)
  - `recognized_income == 20000000` (UNCHANGED)
  - `net_expense == 100000` (UNCHANGED)
  - `Safe-to-Spend == 29900000` (UNCHANGED)

---

### Scenario 5: Virtual Fund Allocation (`1.000.000 ₫` to Protected Fund)
- **Objective**: Verify that allocating cash into a virtual envelope reserves funds conceptually without creating ledger postings, while reducing Safe-to-Spend.
- **Preconditions**: State from Scenario 4 (`total_liquid_assets = 29.900.000 ₫`).
- **Action**: Allocate `1.000.000 ₫` into Protected Envelope "Quỹ Khẩn Cấp" (`policy = PROTECTED`).
- **Movements**:
  - Insert `envelope_movements`: `movement_type = ALLOCATE`, `dest_envelope_id = envelope.id`, `amount_vnd = 1.000.000 ₫`.
  - Zero journal postings.
- **Assertions**:
  - `total_liquid_assets == 29900000` (UNCHANGED)
  - `net_expense == 100000` (UNCHANGED)
  - `recognized_income == 20000000` (UNCHANGED)
  - `envelope.reserved_balance_vnd == 1000000`
  - `available_to_allocate == 28900000` (decreased by 1.000.000 ₫)
  - `Safe-to-Spend == 28900000` (decreased by 1.000.000 ₫)

---

### Scenario 6: Credit-Card Purchase (`500.000 ₫`)
- **Objective**: Verify that purchasing on credit increases liabilities and expenses without immediately reducing liquid cash assets.
- **Preconditions**: State from Scenario 5 (`total_liquid_assets = 29.900.000 ₫`).
- **Action**: Post `EXPENSE` of `500.000 ₫` via `LIABILITY_CREDIT_CARD` for Category `Mua sắm`.
- **Postings**:
  - Debit: `EXPENSE` (`Mua sắm`) = `500.000 ₫`
  - Credit: `LIABILITY_CREDIT_CARD` = `500.000 ₫`
- **Assertions**:
  - `ledger_accounts.LIABILITY_CREDIT_CARD.balance == 500000` (Credit debt)
  - `total_liquid_assets == 29900000` (UNCHANGED)
  - `gross_expense == 600000` (100k + 500k)
  - `net_expense == 600000` (increased by 500.000 ₫)
  - `net_worth == 29400000` (Assets 29.9M - Liabilities 0.5M)

---

### Scenario 7: Credit-Card Payment (`500.000 ₫`)
- **Objective**: Verify that paying down credit card balance reduces liquid cash and debt, and is NEVER counted as an operating expense.
- **Preconditions**: State from Scenario 6 (`card debt = 500.000 ₫`, `ASSET_BANK = 18.000.000 ₫`).
- **Action**: Post `CREDIT_CARD_PAYMENT` of `500.000 ₫` from `ASSET_BANK` to `LIABILITY_CREDIT_CARD`.
- **Postings**:
  - Debit: `LIABILITY_CREDIT_CARD` = `500.000 ₫`
  - Credit: `ASSET_BANK` = `500.000 ₫`
- **Assertions**:
  - `ledger_accounts.LIABILITY_CREDIT_CARD.balance == 0` (debt cleared)
  - `ledger_accounts.ASSET_BANK.balance == 17500000` (18.000.000 - 500.000)
  - `total_liquid_assets == 29400000` (decreased by 500.000 ₫)
  - `gross_expense == 600000` (UNCHANGED)
  - `net_expense == 600000` (**STRICTLY UNCHANGED** — payment is not an expense)
  - `net_worth == 29400000` (UNCHANGED)

---

### Scenario 8: Refund (`50.000 ₫`)
- **Objective**: Verify that a refund restores liquid cash and decreases net expense, restoring linked envelope balance if applicable.
- **Preconditions**: State from Scenario 7 (`net_expense = 600.000 ₫`, `ASSET_BANK = 17.500.000 ₫`).
- **Action**: Post `REFUND` of `50.000 ₫` for Category `Mua sắm` receiving into `ASSET_BANK`.
- **Postings**:
  - Debit: `ASSET_BANK` = `50.000 ₫`
  - Credit: `EXPENSE` (`Mua sắm`) = `50.000 ₫`
- **Assertions**:
  - `ledger_accounts.ASSET_BANK.balance == 17550000` (17.5M + 50k)
  - `total_liquid_assets == 29450000` (increased by 50.000 ₫)
  - `gross_expense == 600000`
  - `refund_credits == 50000`
  - `net_expense == 550000` (decreased by 50.000 ₫)
  - If linked to an envelope, envelope reserve balance increases by `50.000 ₫` via `REFUND_RESTORE`.

---

### Scenario 9: Edit & Void Transaction
- **Objective**: Verify that voiding and editing insert balancing reversals, reconcile account balances, and filter cleanly in default UI lists.
- **Part A (Void)**:
  - Create transaction $T_1$: Expense `100.000 ₫` from `ASSET_CASH`.
  - Void $T_1$:
    - $T_1.\text{status}$ becomes `VOIDED`.
    - Reversal $R_1$ inserted (`reverses_tx_id = T1.id`, `status = POSTED`, Debit `ASSET_CASH` 100k, Credit `EXPENSE` 100k).
  - Assertions:
    - `SUM(debit_vnd) == SUM(credit_vnd)` across all postings.
    - `ASSET_CASH` balance returns exactly to pre-$T_1$ value.
    - Default UI query (`WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`) returns neither $T_1$ nor $R_1$.
- **Part B (Edit)**:
  - Create transaction $T_2$: Expense `200.000 ₫` from `ASSET_CASH`.
  - Edit $T_2$ to `250.000 ₫`:
    - $T_2.\text{status}$ becomes `SUPERSEDED`, `replaced_by_tx_id = T3.id`.
    - Reversal $R_2$ inserted (`reverses_tx_id = T2.id`).
    - New transaction $T_3$ created (`status = POSTED`, amount = `250.000 ₫`).
  - Assertions:
    - Net effect on `ASSET_CASH` balance is exactly `-250.000 ₫`.
    - Default UI list shows only $T_3$.
    - Audit history sheet for $T_3$ lists $T_2$, $R_2$, and $T_3$ in order.

---

### Scenario 10: Duplicate Submission Guard (Idempotency Key)
- **Objective**: Verify that submitting identical idempotency keys twice creates exactly one database transaction.
- **Action**:
  - Submit transaction with `idempotency_key = "idemp-001"` and amount `500.000 ₫`.
  - Immediately submit identical transaction with `idempotency_key = "idemp-001"`.
- **Assertions**:
  - Second submission is intercepted; returns existing transaction without error or duplicate postings.
  - Exactly 1 record exists in `journal_transactions` with `idempotency_key = "idemp-001"`.
  - Ledger account balances reflect exactly 1 transaction amount (`500.000 ₫`).

---

### Scenario 11: Scheduled Bill (`1.500.000 ₫`) & Payment (Zero Double Counting)
- **Objective**: Verify that pending bills linked to protected envelopes are not subtracted twice in Safe-to-Spend, and transition cleanly upon payment.
- **Setup**:
  - `total_liquid_assets = 10.000.000 ₫`, buffer = 0 ₫.
  - Protected envelope "Điện Nước" has `reserved_balance_vnd = 1.000.000 ₫`.
  - Create pending `BILL` "Tiền Điện" for `1.500.000 ₫` linked to "Điện Nước".
- **Pending Phase Assertions**:
  - Protected envelope covers `1.000.000 ₫`.
  - Unfunded Committed Outflows == `500.000 ₫` (`1.500.000 - 1.000.000`).
  - Protected Reserves == `1.000.000 ₫`.
  - Safe-to-Spend == `10.000.000 - 1.000.000 - 500.000 = 8.500.000 ₫`. (Zero double-counting).
- **Payment Phase Action**: Mark bill as paid.
  - Generates posted `EXPENSE` transaction for `1.500.000 ₫`.
  - `scheduled_item.status = PAID_OR_RECEIVED`, `paid_transaction_id = tx.id`.
  - Envelope movement `SPEND` consumes `1.000.000 ₫` from "Điện Nước".
- **Post-Payment Assertions**:
  - `total_liquid_assets == 8500000` (10M - 1.5M).
  - Protected envelope balance == `0 ₫`.
  - Unfunded pending bills == `0 ₫` (bill is now paid).
  - Safe-to-Spend == `8500000 ₫` (matches cash, zero double subtraction).

---

### Scenario 12: Negative Safe-to-Spend Handling
- **Objective**: Verify that when reserves, obligations, and buffer exceed liquid assets, the exact negative shortfall is calculated and rendered without clamping to 0.
- **Setup**:
  - `total_liquid_assets = 2.000.000 ₫`.
  - Protected Reserves == `1.500.000 ₫`.
  - Unfunded Bills == `1.000.000 ₫`.
  - Minimum Cash Buffer == `1.000.000 ₫`.
- **Calculation**:
  $$\text{Safe-to-Spend} = 2.000.000 - 1.500.000 - 1.000.000 - 1.000.000 = -1.500.000 \text{ ₫}$$
- **Assertions**:
  - `SafeToSpendResult.safeToSpendVnd == -1500000` (NOT clamped to 0).
  - `SafeToSpendResult.isDeficit == true`.
  - `SafeToSpendResult.dailyAllowanceVnd == 0` (`0 ₫/ngày`).
  - Shortfall breakdown components match: Liquid `+2.0M`, Protected `-1.5M`, Bills `-1.0M`, Buffer `-1.0M`.
  - Hero card renders `-1.500.000 ₫` in red (`AppColors.textAccentRubyPrimary`).

---

### Scenario 13: Encrypted Backup & Restore Round-Trip
- **Objective**: Verify that exporting an encrypted backup, resetting database state, and restoring produces an exact bit-for-bit duplicate of all financial records.
- **Preconditions**: Populated database with accounts, categories, transactions, postings, envelopes, movements, budgets, scheduled items, settings.
- **Action**:
  - Export backup via `Isolate.run` with password `"MatKhauManh#2026"`.
  - Verify outer JSON envelope: `"magic": "DONGTIEN_ENC_V1"`, `kdfIterations = 120000`, 16-byte salt, 12-byte nonce, 16-byte MAC.
  - Reset / wipe SQLite database to initial state.
  - Restore backup via `Isolate.run` with password `"MatKhauManh#2026"`.
- **Assertions**:
  - Decryption succeeds; structural invariants pass (`SUM(debit) == SUM(credit)` for every tx, FK integrity passes).
  - Database restored atomically inside single `db.transaction()`.
  - All 9 tables contain exact pre-wipe records and derived account balances match bit-for-bit.

---

### Scenario 14: Tampered Backup / Wrong Password Rejection
- **Objective**: Verify that corrupt backups, tampered ciphertexts, or wrong passwords are safely rejected off-main-thread without touching the SQLite database.
- **Part A (Tampered Ciphertext)**:
  - Generate valid backup. Invert 1 single bit in `ciphertextB64` or `macB64`.
  - Attempt restore inside `Isolate.run`.
  - Assertions: `AesGcm` throws `SecretBoxAuthenticationError`. SQLite database is never touched. Existing data remains 100% intact.
- **Part B (Wrong Password)**:
  - Attempt restore of valid backup using password `"SaiMatKhau"`.
  - Assertions: Throws `InvalidCredentialsException`. SQLite database untouched.

---

### Scenario 15: Notification Permission Denied & Month-End Recurrence
- **Objective**: Verify that the application remains fully functional when notification permissions are denied, and that month-end recurring bills anchored to day 31 preserve their anchor across February.
- **Part A (Permission Denied)**:
  - Simulate `POST_NOTIFICATIONS` denied.
  - Assertions: All transaction additions, budget queries, and envelope operations succeed without error; Settings displays informative warning card.
- **Part B (Drift-Free Recurrence)**:
  - Create recurring monthly bill with `anchor_day_of_month = 31` starting Jan 31.
  - Advance to February (non-leap year, 28 days): Generated due date == `Feb 28`.
  - Advance to March (31 days): Generated due date == `Mar 31` (returns to 31 without drift).
  - Advance to April (30 days): Generated due date == `Apr 30`.
  - Advance to May (31 days): Generated due date == `May 31`.
  - Assertions: `scheduled_items.anchor_day_of_month` remains `31` across all cycles; dates match `min(anchor_day_of_month, daysInMonth(Y, M))`.

---

## 7. AUTOMATED VERIFICATION STRATEGY & TOOLCHAIN GATES

```text
       Unit Tests (test/unit/)
         ├── VndMoney arithmetic & overflow guard
         ├── Safe-to-Spend calculator & zero double-counting
         ├── Savings goals ceiling division & feasibility
         └── Encrypted backup PBKDF2/AES-GCM isolate crypto
                     │
                     ▼
       Database Tests (test/database/)
         ├── Drift SQLite in-memory instance
         ├── PRAGMA foreign_keys = ON;
         ├── Double-entry balanced posting invariant
         ├── Dynamic account balance derivation
         ├── Audit-preserving void and edit reversal engine
         └── Multi-table atomic restore transaction
                     │
                     ▼
       Widget & Component Tests (test/widget/)
         ├── Custom numeric keypad input & backspace
         ├── Hero Safe-to-Spend display & breakdown modal
         ├── Day-grouped transaction feed & filter chips
         └── Virtual fund allocation & progress bars
                     │
                     ▼
       End-to-End Acceptance Tests (integration_test/ & maestro/)
         └── Scenarios 1 through 15 executed end-to-end
```

### 7.1 Mandatory Toolchain Quality Gate Commands
```bash
# 1. Format verification
dart format --output=none --set-exit-if-changed .

# 2. Static analysis
flutter analyze

# 3. Automated test coverage
flutter test --coverage

# 4. Debug APK compilation
flutter build apk --debug
```
*Pass Criteria*: All 4 commands exit with code 0.
