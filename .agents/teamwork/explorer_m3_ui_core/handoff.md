# M3 UI Core, Design System & Dashboard Implementation Blueprint

> **Role**: `explorer_m3_ui_core`  
> **Target Package**: `dongtien` (`vn.dongtien`)  
> **Scope**: `lib/app/`, `lib/app/theme/`, `lib/core/widgets/`, `lib/features/dashboard/`  
> **Status**: Complete Architecture & Implementation Blueprint  

---

## 1. OBSERVATIONS

1. **Toolchain & Verification Baseline**:
   - Environment: Flutter 3.24.5 (channel stable), Dart 3.5.4, Windows 10/11.
   - Test suite status: Executed `& "C:\Users\coihu12\flutter\bin\flutter.bat" test` -> **253 tests passed** with 0 failures across unit and database tests (`vnd_money_test.dart`, `safe_to_spend_test.dart`, `adversarial_ledger_envelope_test.dart`, `category_spending_test.dart`, `cash_flow_forecaster_test.dart`, `recurrence_test.dart`).
   - Static analysis: Executed `& "C:\Users\coihu12\flutter\bin\flutter.bat" analyze` -> **No issues found**.
   - Locked dependencies in `pubspec.yaml`: `flutter_riverpod: ^2.5.1`, `drift: ^2.20.0`, `drift_flutter: 0.2.0`, `sqlite3_flutter_libs: ^0.5.24`, `intl: ^0.19.0`, `flutter_local_notifications: ^17.2.3`, `cryptography: ^2.7.0`.
   - Strict ban on forbidden packages: Zero imports of `go_router`, `freezed`, `riverpod_generator`, `uuid`, chart libraries (`fl_chart`), `dio`/`http`, `firebase_*`.

2. **Domain Contracts & Existing Invariants**:
   - **`VndMoney`** (`lib/core/money/vnd_money.dart:24-210`): Stores whole VND in 64-bit signed integers (`int amount`). Guarded by `maxSafeVnd = 9_000_000_000_000_000`. Formats via `VndFormatter.format(amount, showSign: ...)` producing e.g. `1.250.000 ₫`, `0 ₫`, `-500.000 ₫`.
   - **`VndFormatter`** (`lib/core/money/vnd_formatter.dart:14-30`): Provides `tabularFigures = [FontFeature.tabularFigures()]` and `withTabularFigures(TextStyle style)`. Mandated across all numbers, percentages, and dates.
   - **`SafeToSpendCalculator`** (`lib/domain/forecasting/safe_to_spend_calculator.dart:141-327`): Implements:
     $$\text{Safe-to-Spend} = \text{Liquid Assets} - \text{Protected Reserves} - \text{Unfunded Committed Outflows} - \text{Minimum Cash Buffer}$$
     Returns `SafeToSpendResult(safeToSpend, dailyAllowance, isDeficit, daysRemaining, breakdown)`. Crucially: **never clamps to zero**. When negative, `isDeficit == true` and `dailyAllowance == VndMoney.zero` (`0 ₫/ngày`).
   - **`LedgerDao`** (`lib/core/database/daos/ledger_dao.dart:407-540`): Exposes reactive streams `watchAccountsWithBalances()`, `watchTotalLiquidAssets()`, `watchNetWorth()`, and `watchCleanTransactions()` (`WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`).
   - **`EnvelopeDao`** (`lib/core/database/daos/envelope_dao.dart:8-70`): Manages virtual envelope allocations, releases, and transfers completely decoupled from general ledger postings.
   - **`CategoryBudgetTracker`** (`lib/domain/budgeting/category_budget_progress.dart:15-150`): Evaluates category budget progress, warning threshold (`alertThresholdPct`, default 80%), and status (`normal`, `warning`, `exceeded`).
   - **`CategorySpendingCalculator`** (`lib/domain/budgeting/category_spending_calculator.dart:101-172`): Computes net expense (`gross - refund`), net recovery (`net < 0`), and savings rate (`null` if income <= 0, rendered as `"Chưa có thu nhập"`).

3. **Design Specifications (`docs/DESIGN_AND_TEST_PLAN.md` & `AGENTS.md`)**:
   - **Design Tokens**:
     - `app_colors.dart`: 7 color families (Primary Jade, Slate Neutral, Accent Amber, Accent Ruby, Functional Blue, Surface, Overlay).
     - `app_typography.dart`: 7 scales (`displayLarge`, `headlineMedium`, `titleLarge`, `bodyLarge`, `bodyMedium`, `labelMedium`, `caption`) with `FontFeature.tabularFigures()`.
     - `app_spacing.dart`: 16-step scale (`sp0 = 0.0` to `sp15 = 128.0`, with explicit aliases `spacing2` to `spacing64`).
   - **Presentation Widgets**:
     - `custom_keypad.dart`: 4x3 numeric keypad with Backspace (`<`) and Done ("Xong" / checkmark), touch target >= 48x48px, emerald/verdant background.
     - `progress_bar.dart`: Two-tone Material 3 progress bar with normal (jade), warning (amber >= 80%), and exceeded (ruby > 100%) states.
   - **App Shell**:
     - `MaterialApp` in `lib/app/app.dart` with `Locale('vi', 'VN')`, `IndexedStack` preserving state across 4 bottom tabs (`Tổng quan`, `Giao dịch`, `Quỹ tiền`, `Kế hoạch`), AppBar actions (Reports, Settings), and Quick-Add FAB.
   - **Dashboard (Tab 0)**:
     - Safe-to-Spend hero card with deficit alert (ruby red if negative) and formula breakdown modal sheet.
     - Spending vs Budget card (consuming category spending calculations).
     - Upcoming obligations card (pending bills and planned income with quick "Đã trả" action).
     - Mini fund progress and recent 5 transactions list.
   - **Automated Accessibility & Testing**:
     - Strict requirement for `Semantics(identifier: '...')` across all navigation tabs, hero cards, action buttons, inputs, and modal sheets.

---

## 2. LOGIC CHAIN

1. **Clean Separation of Concerns**:
   - `lib/domain/` contains pure Dart business logic without Flutter or Drift dependencies.
   - `lib/core/widgets/` contains pure presentation UI primitives (`CustomKeypad`, `ProgressBar`) that are completely reusable across tabs.
   - `lib/app/theme/` centralizes visual tokens (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`) so that no widget hardcodes hex colors or typography parameters.
   - `lib/features/dashboard/presentation/` contains feature-specific screens, cards, modals, and Riverpod providers.

2. **Tabular Numerals Invariant**:
   - In financial UI, fluctuating digit widths (e.g., `1` vs `8`) cause rapid horizontal layout shifts ("jitter") during data refreshes.
   - By embedding `FontFeature.tabularFigures()` into every `TextStyle` in `AppTypography` and creating a global `TextTheme` via `AppTypography.createTextTheme()`, every text widget in the app adheres to this invariant automatically.

3. **Zero Double-Counting Safe-to-Spend Reaction**:
   - `safeToSpendProvider` combines streams from `ledgerDao.watchTotalLiquidAssets()`, `envelopes`, `scheduledItems` (pending bills and planned income), and `settings` (minimum buffer).
   - It invokes `SafeToSpendCalculator.calculate()` using the exact chronological allocation algorithm.
   - If `safeToSpend < 0` (Scenario 12), the Hero card immediately transitions its color theme from jade (`surfaceAccentVerdantSecondary` `#F3F7F5`) to ruby red (`surfaceAccentRubySecondary` `#FFF4F1`), renders the exact negative amount (e.g. `-1.500.000 ₫`), sets daily allowance to `0 ₫/ngày`, and offers the breakdown modal.

4. **Multi-Tab State Preservation via `IndexedStack`**:
   - Using `IndexedStack` in `MainNavigationShell` retains the active scroll offsets, form inputs, and state of all 4 primary tabs (`Tổng quan`, `Giao dịch`, `Quỹ tiền`, `Kế hoạch`) when switching between them.
   - For secondary screens (`Báo cáo`, `Cài đặt`, `Lịch sử chỉnh sửa`), standard `Navigator.push` is used, fulfilling the forbidden-package constraint against `go_router`.

5. **Semantics Traceability**:
   - Every automation hook defined in `docs/DESIGN_AND_TEST_PLAN.md` Section 4 and Section 6 is explicitly attached via `Semantics(identifier: '...')`. This guarantees automated testability in `test/widget/` and `integration_test/`.

---

## 3. CAVEATS

1. **Phase Ownership Boundaries**:
   - `worker_m3_ui_core` owns `lib/app/`, `lib/app/theme/`, `lib/core/widgets/`, and `lib/features/dashboard/`.
   - Feature screens for Tab 1 (`TransactionsScreen`), Tab 2 (`VirtualFundsScreen`), and Tab 3 (`PlansScreen`) are owned by parallel workers (`worker_m3_transactions`, `worker_m3_envelopes`, `worker_m4_plans`).
   - The navigation shell in `lib/app/app.dart` must provide robust fallback/placeholder tabs (`TransactionsPlaceholder`, `VirtualFundsPlaceholder`, `PlansPlaceholder`) so that `worker_m3_ui_core` compiles, runs, and passes widget tests independently before parallel features land.
2. **Keypad Form Integration**:
   - `CustomKeypad` is designed as a standalone presentation widget in `lib/core/widgets/custom_keypad.dart`. The full transaction quick-add form (category grid, account chips, idempotency key generation) is assembled by `worker_m3_transactions` in `QuickAddModalSheet`.
3. **Database Single Instance**:
   - Riverpod `databaseProvider` must supply a single shared instance of `AppDatabase` across the app lifecycle.

---

## 4. CONCLUSION: COMPLETE IMPLEMENTATION BLUEPRINT

Here is the exact, production-ready specification and complete Dart code for all files to be created by `worker_m3_ui_core`.

```text
lib/
├── app/
│   ├── app.dart                                         # MaterialApp & IndexedStack Shell
│   └── theme/
│       ├── app_colors.dart                              # 7 Color Families & Semantic Tokens
│       ├── app_typography.dart                          # 7 Typography Scales with Tabular Figures
│       ├── app_spacing.dart                             # 16-step Spacing & Layout Tokens
│       └── app_theme.dart                               # Material 3 ThemeData Specification
├── core/
│   └── widgets/
│       ├── custom_keypad.dart                           # 4x3 Numeric Keypad (wallet.png)
│       └── progress_bar.dart                            # M3 Two-tone Progress Bar (Warning & Overflow)
└── features/
    └── dashboard/
        └── presentation/
            ├── dashboard_screen.dart                    # Tab 0 Scaffold & Feed
            ├── providers/
            │   ├── dashboard_providers.dart             # Streams & Aggregations
            │   └── safe_to_spend_provider.dart          # Pure Reactive Safe-to-Spend
            └── widgets/
                ├── safe_to_spend_hero_card.dart         # Hero Safe-to-Spend & Deficit Alert
                ├── safe_to_spend_breakdown_modal.dart   # 4-Term Formula Breakdown Sheet
                ├── spending_vs_budget_card.dart         # Category Budget Consumption
                ├── upcoming_obligations_card.dart       # Pending Bills & Planned Income
                ├── fund_progress_card.dart              # Mini Virtual Fund Progress
                └── recent_transactions_card.dart        # Last 5 Clean Transactions
```

---

### 4.1 `lib/app/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

/// Authoritative Design System Color Tokens for Đồng Tiền.
/// Extracted directly from Untitled-3.png across 7 color families:
/// 1. Primary Jade (Verdant)
/// 2. Slate Neutral (Charcoal)
/// 3. Accent Amber (Sandstone / Marigold)
/// 4. Accent Ruby
/// 5. Functional Blue
/// 6. Surface (Neutral)
/// 7. Overlay & Scrim
class AppColors {
  AppColors._();

  // ===========================================================================
  // 1. PRIMARY JADE / VERDANT FAMILY (Financial Health, Assets, Safe-to-Spend)
  // ===========================================================================
  static const Color jade14 = Color(0xFF215B44); // Deepest hero text
  static const Color jade11 = Color(0xFF3D785F); // Secondary text / headings
  static const Color jade10 = Color(0xFF4E886F); // Primary fill, FAB, CTA
  static const Color jade01 = Color(0xFFF3F7F5); // Hero card background tint

  // ===========================================================================
  // 2. SLATE NEUTRAL / CHARCOAL FAMILY (Typography, Borders, Inactive Fill)
  // ===========================================================================
  static const Color charcoal16 = Color(0xFF4D4845); // textPrimary, iconPrimary
  static const Color charcoal12 = Color(0xFF65605C); // textSecondary
  static const Color charcoal09 = Color(0xFF928F8B); // textTertiary
  static const Color charcoal08 = Color(0xFFA6A4A0); // iconSecondary
  static const Color charcoal05 = Color(0xFFDBDBD8); // textDisabled, iconDisabled
  static const Color charcoal04 = Color(0xFFE7E7E4); // borderSecondary (Card border)
  static const Color charcoal03 = Color(0xFFEFEFED); // surfaceTertiary, track fill
  static const Color charcoal02 = Color(0xFFF4F4F2); // borderPrimary (Hairline)
  static const Color charcoal01 = Color(0xFFF6F6F4); // surfaceSecondary (Scaffold bg)

  // ===========================================================================
  // 3. ACCENT AMBER / SANDSTONE / MARIGOLD FAMILY (Warnings, Budgets >= 80%)
  // ===========================================================================
  static const Color amber14 = Color(0xFF823F00); // marigold-14
  static const Color amber11 = Color(0xFFAC5500); // marigold-11 warning text
  static const Color amber07 = Color(0xFFFAA800); // marigold-07 warning progress
  static const Color amber05 = Color(0xFFFFC542); // marigold-05
  static const Color amber01 = Color(0xFFFFF5E3); // marigold-01 warning bg tint
  static const Color sandstone14 = Color(0xFF764527);
  static const Color sandstone11 = Color(0xFF976035);
  static const Color sandstone07 = Color(0xFFF0AB59);
  static const Color sandstone01 = Color(0xFFFDF6E4);

  // ===========================================================================
  // 4. ACCENT RUBY FAMILY (Deficit, Expenses, Over-budget > 100%, Danger)
  // ===========================================================================
  static const Color ruby14 = Color(0xFF9A2329); // Deficit / danger text
  static const Color ruby11 = Color(0xFFC9362B); // Expense text
  static const Color ruby10 = Color(0xFFE0462F); // ruby icon
  static const Color ruby09 = Color(0xFFF55D3E); // Danger button, overflow progress
  static const Color ruby01 = Color(0xFFFFF4F1); // Deficit hero background tint

  // ===========================================================================
  // 5. FUNCTIONAL BLUE FAMILY (Transfers, Information, Account Reconciliation)
  // ===========================================================================
  static const Color blue14 = Color(0xFF1565C0); // Transfer text
  static const Color blue11 = Color(0xFF1976D2); // Info icon
  static const Color blue08 = Color(0xFF2196F3); // Transfer indicator
  static const Color blue01 = Color(0xFFE3F2FD); // Transfer chip background

  // ===========================================================================
  // 6. SURFACE FAMILY (Cards, Scaffolds, Dialogs)
  // ===========================================================================
  static const Color neutral01 = Color(0xFFFFFFFF); // surfacePrimary (Cards, Sheets)
  static const Color surfacePrimary = neutral01;
  static const Color surfaceSecondary = charcoal01; // Scaffold background
  static const Color surfaceTertiary = charcoal03;  // Inactive tracks, dividers

  // ===========================================================================
  // 7. OVERLAY & SCRIM FAMILY (Modals, Dialogs)
  // ===========================================================================
  static const Color surfaceOverlay = Color(0x634D4845); // alpha-09 (Modal barrier 39%)
  static const Color scrimLight = Color(0x26000000);

  // ===========================================================================
  // SEMANTIC TOKEN ALIASES (Matching docs/DESIGN_AND_TEST_PLAN.md Section 1.3)
  // ===========================================================================
  static const Color textPrimary = charcoal16;
  static const Color textSecondary = charcoal12;
  static const Color textTertiary = charcoal09;
  static const Color textDisabled = charcoal05;
  static const Color textInverse = neutral01;

  static const Color textAccentVerdantPrimary = jade14;
  static const Color textAccentVerdantSecondary = jade11;
  static const Color textAccentSandstonePrimary = sandstone14;
  static const Color textAccentSandstoneSecondary = sandstone11;
  static const Color textAccentRubyPrimary = ruby14;
  static const Color textAccentRubySecondary = ruby11;
  static const Color textAccentMarigoldPrimary = amber14;
  static const Color textAccentMarigoldSecondary = amber11;

  static const Color surfaceAccentVerdantPrimary = jade11;
  static const Color surfaceAccentVerdantSecondary = jade01;
  static const Color surfaceAccentRubyPrimary = Color(0xFFE55959);
  static const Color surfaceAccentRubySecondary = ruby01;
  static const Color surfaceAccentMarigoldPrimary = amber05;
  static const Color surfaceAccentMarigoldSecondary = amber01;

  static const Color fillPrimary = neutral01;
  static const Color fillSecondary = charcoal01;
  static const Color fillTertiary = charcoal03;
  static const Color fillAccentVerdantPrimary = jade10;
  static const Color fillAccentVerdantSecondary = jade01;
  static const Color fillAccentRubyPrimary = ruby09;
  static const Color fillAccentRubySecondary = ruby01;
  static const Color fillAccentMarigoldPrimary = amber07;
  static const Color fillAccentMarigoldSecondary = amber01;

  static const Color borderPrimary = charcoal02;
  static const Color borderSecondary = charcoal04;
  static const Color borderInverse = charcoal16;
  static const Color borderAccentVerdant = jade10;
  static const Color borderAccentRuby = ruby09;
  static const Color borderAccentMarigold = amber07;

  static const Color iconPrimary = charcoal16;
  static const Color iconSecondary = charcoal08;
  static const Color iconDisabled = charcoal05;
  static const Color iconInverse = neutral01;
  static const Color iconAccentVerdant = jade10;
  static const Color iconAccentRuby = ruby10;
  static const Color iconAccentMarigold = Color(0xFFEE8D00);
}
```

---

### 4.2 `lib/app/theme/app_typography.dart`

```dart
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 7 Typography Scales for Đồng Tiền matching Untitled-2.png.
/// Every scale MUST include [FontFeature.tabularFigures()] by default to
/// prevent layout jitter when numbers, dates, or currency dynamic updates occur.
class AppTypography {
  AppTypography._();

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  // 1. Large Title / displayLarge (32px / 48px, w500)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    height: 48 / 32,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle largeTitle = displayLarge;

  // 2. Title / titleLarge (24px / 36px, w500)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    height: 36 / 24,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle title = titleLarge;

  // 3. Headline / headlineMedium (20px / 30px, w500)
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    height: 30 / 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle headline = headlineMedium;

  // 4. Body / bodyLarge (16px / 24px, w400)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle body = bodyLarge;

  // 5. Body Medium / bodyMedium (16px / 24px, w500)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );

  // 6. Subheadline / labelMedium (14px / 20px, w400)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle subheadline = labelMedium;

  // 7. Caption / Footnote (12px / 16px, w400)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle footnote = caption;

  // Micro Caption (10px / 14px, w400)
  static const TextStyle microCaption = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    fontFeatures: tabularFigures,
  );

  /// Helper to convert styles to Material 3 TextTheme.
  static TextTheme createTextTheme() {
    return const TextTheme(
      displayLarge: displayLarge,
      headlineMedium: headlineMedium,
      titleLarge: titleLarge,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelMedium: labelMedium,
      labelSmall: caption,
    );
  }
}
```

---

### 4.3 `lib/app/theme/app_spacing.dart`

```dart
import 'package:flutter/widgets.dart';

/// 16-step Spacing Scale matching Spacing.png (sp0 = 0dp to sp15 = 128dp).
class AppSpacing {
  AppSpacing._();

  static const double sp0 = 0.0;
  static const double sp1 = 1.0;
  static const double sp2 = 2.0;    // spacing2 = 2dp
  static const double sp3 = 4.0;    // spacing4 = 4dp
  static const double sp4 = 8.0;    // spacing8 = 8dp
  static const double sp5 = 12.0;   // spacing12 = 12dp
  static const double sp6 = 16.0;   // spacing16 = 16dp
  static const double sp7 = 20.0;   // spacing20 = 20dp
  static const double sp8 = 24.0;   // spacing24 = 24dp
  static const double sp9 = 32.0;   // spacing32 = 32dp
  static const double sp10 = 40.0;  // spacing40 = 40dp
  static const double sp11 = 48.0;  // spacing48 = 48dp (Min touch target)
  static const double sp12 = 64.0;  // spacing64 = 64dp
  static const double sp13 = 80.0;  // spacing80 = 80dp (Bottom bar clearance)
  static const double sp14 = 96.0;  // spacing96 = 96dp
  static const double sp15 = 128.0; // spacing128 = 128dp

  // Explicit aliases for spacing2 through spacing64
  static const double spacing2 = sp2;
  static const double spacing4 = sp3;
  static const double spacing8 = sp4;
  static const double spacing12 = sp5;
  static const double spacing16 = sp6;
  static const double spacing20 = sp7;
  static const double spacing24 = sp8;
  static const double spacing32 = sp9;
  static const double spacing40 = sp10;
  static const double spacing48 = sp11;
  static const double spacing64 = sp12;

  // Layout Padding Helpers
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: sp6);
  static const EdgeInsets paddingCard = EdgeInsets.all(sp6);
  static const EdgeInsets paddingHero = EdgeInsets.all(sp7);
  static const EdgeInsets paddingModal = EdgeInsets.all(sp8);

  // Vertical Gaps
  static const SizedBox gapH4 = SizedBox(height: sp3);
  static const SizedBox gapH8 = SizedBox(height: sp4);
  static const SizedBox gapH12 = SizedBox(height: sp5);
  static const SizedBox gapH16 = SizedBox(height: sp6);
  static const SizedBox gapH20 = SizedBox(height: sp7);
  static const SizedBox gapH24 = SizedBox(height: sp8);
  static const SizedBox gapH32 = SizedBox(height: sp9);

  // Horizontal Gaps
  static const SizedBox gapW4 = SizedBox(width: sp3);
  static const SizedBox gapW8 = SizedBox(width: sp4);
  static const SizedBox gapW12 = SizedBox(width: sp5);
  static const SizedBox gapW16 = SizedBox(width: sp6);
  static const SizedBox gapW24 = SizedBox(width: sp8);
}
```

---

### 4.4 `lib/app/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Consolidated Material 3 ThemeData Specification for Đồng Tiền.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final textTheme = AppTypography.createTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surfaceSecondary,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.fillAccentVerdantPrimary,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.textAccentVerdantSecondary,
        onSecondary: AppColors.textInverse,
        error: AppColors.fillAccentRubyPrimary,
        onError: AppColors.textInverse,
        surface: AppColors.surfacePrimary,
        onSurface: AppColors.textPrimary,
        outline: AppColors.borderSecondary,
        surfaceContainerHighest: AppColors.surfaceTertiary,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
        iconTheme: IconThemeData(color: AppColors.iconPrimary),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: AppColors.borderSecondary, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfacePrimary,
        elevation: 2,
        indicatorColor: AppColors.surfaceAccentVerdantSecondary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textAccentVerdantPrimary,
            );
          }
          return AppTypography.caption.copyWith(color: AppColors.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.textAccentVerdantPrimary);
          }
          return const IconThemeData(color: AppColors.iconSecondary);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.fillAccentVerdantPrimary,
        foregroundColor: AppColors.textInverse,
        elevation: 3,
        shape: StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderPrimary,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
```

---

### 4.5 `lib/core/widgets/custom_keypad.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../money/vnd_money.dart';

/// 4x3 Custom Numeric Keypad from wallet.png.
/// Minimum touch target 48x48px, emerald/verdant background,
/// backspace (<) key, and Done action button.
class CustomKeypad extends StatelessWidget {
  final ValueChanged<int> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onDonePressed;

  const CustomKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onDonePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp6,
        vertical: AppSpacing.sp4,
      ),
      color: AppColors.surfacePrimary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          AppSpacing.gapH8,
          _buildRow(['4', '5', '6']),
          AppSpacing.gapH8,
          _buildRow(['7', '8', '9']),
          AppSpacing.gapH8,
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      children: digits.map((d) {
        final int val = int.parse(d);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
            child: _KeypadButton(
              semanticId: 'keypad_btn_$d',
              label: d,
              onTap: () {
                HapticFeedback.lightImpact();
                onDigitPressed(val);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        // Done button
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
            child: _KeypadButton(
              semanticId: 'keypad_btn_done',
              icon: Icons.check,
              label: 'Xong',
              isAction: true,
              onTap: () {
                HapticFeedback.mediumImpact();
                onDonePressed();
              },
            ),
          ),
        ),
        // 0 Digit
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
            child: _KeypadButton(
              semanticId: 'keypad_btn_0',
              label: '0',
              onTap: () {
                HapticFeedback.lightImpact();
                onDigitPressed(0);
              },
            ),
          ),
        ),
        // Backspace
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
            child: _KeypadButton(
              semanticId: 'keypad_btn_backspace',
              icon: Icons.backspace_outlined,
              isAction: true,
              onTap: () {
                HapticFeedback.lightImpact();
                onBackspacePressed();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String semanticId;
  final String? label;
  final IconData? icon;
  final bool isAction;
  final VoidCallback onTap;

  const _KeypadButton({
    required this.semanticId,
    this.label,
    this.icon,
    this.isAction = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticId,
      button: true,
      child: Material(
        color: isAction
            ? AppColors.surfaceAccentVerdantSecondary
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 56.0,
              minWidth: 64.0,
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(
                    icon,
                    size: 24.0,
                    color: isAction
                        ? AppColors.textAccentVerdantPrimary
                        : AppColors.iconPrimary,
                  )
                : Text(
                    label ?? '',
                    style: AppTypography.titleLarge.copyWith(
                      color: isAction
                          ? AppColors.textAccentVerdantPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
```

---

### 4.6 `lib/core/widgets/progress_bar.dart`

```dart
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Material 3 Two-Tone Progress Bar with warning (>= 80%)
/// and exceeded / overflow (> 100%) states.
class ProgressBar extends StatelessWidget {
  /// Spending ratio or progress ratio (0.0 to 1.0+).
  final double ratio;

  /// Warning threshold percentage ratio (default 0.8 for 80%).
  final double warningThreshold;

  /// Bar height (default 8.0dp).
  final double height;

  /// Optional track color.
  final Color? trackColor;

  const ProgressBar({
    super.key,
    required this.ratio,
    this.warningThreshold = 0.8,
    this.height = 8.0,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedFill = ratio.clamp(0.0, 1.0);
    final bool isExceeded = ratio > 1.0;
    final bool isWarning = ratio >= warningThreshold && !isExceeded;

    Color fillColor;
    if (isExceeded) {
      fillColor = AppColors.fillAccentRubyPrimary;
    } else if (isWarning) {
      fillColor = AppColors.fillAccentMarigoldPrimary;
    } else {
      fillColor = AppColors.fillAccentVerdantPrimary;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double fillWidth = totalWidth * clampedFill;

        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: totalWidth,
            color: trackColor ?? AppColors.surfaceTertiary,
            child: Stack(
              children: [
                // Base progress fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: fillWidth,
                  height: height,
                  color: fillColor,
                ),
                // If exceeded, show pulsing / distinct overflow indicator on the end
                if (isExceeded)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 4.0,
                      height: height,
                      color: AppColors.ruby14,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

### 4.7 `lib/app/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Navigation state provider tracking the 4 bottom tabs.
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Main Application Entry Widget.
class DongTienApp extends StatelessWidget {
  const DongTienApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đồng Tiền',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('vi', 'VN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigationShell(),
    );
  }
}

/// Navigation Shell preserving state across the 4 bottom tabs using IndexedStack.
class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          DashboardScreen(),
          _TransactionsTabPlaceholder(),
          _VirtualFundsTabPlaceholder(),
          _PlansTabPlaceholder(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Semantics(
              identifier: 'nav_tab_dashboard',
              child: Icon(Icons.home_outlined),
            ),
            selectedIcon: Icon(Icons.home),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Semantics(
              identifier: 'nav_tab_transactions',
              child: Icon(Icons.account_balance_wallet_outlined),
            ),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Semantics(
              identifier: 'nav_tab_funds',
              child: Icon(Icons.eco_outlined),
            ),
            selectedIcon: Icon(Icons.eco),
            label: 'Quỹ tiền',
          ),
          NavigationDestination(
            icon: Semantics(
              identifier: 'nav_tab_plans',
              child: Icon(Icons.pie_chart_outline),
            ),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Kế hoạch',
          ),
        ],
      ),
      floatingActionButton: Semantics(
        identifier: 'fab_quick_add',
        button: true,
        child: FloatingActionButton(
          onPressed: () => _openQuickAdd(context),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  void _openQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QuickAddPlaceholderSheet(),
    );
  }
}

// Minimal compilation placeholders for parallel workers
class _TransactionsTabPlaceholder extends StatelessWidget {
  const _TransactionsTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Giao dịch & Tài khoản (Đang kết nối...)')),
      );
}

class _VirtualFundsTabPlaceholder extends StatelessWidget {
  const _VirtualFundsTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Quỹ tiền (Đang kết nối...)')),
      );
}

class _PlansTabPlaceholder extends StatelessWidget {
  const _PlansTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Kế hoạch (Đang kết nối...)')),
      );
}

class _QuickAddPlaceholderSheet extends StatelessWidget {
  const _QuickAddPlaceholderSheet();
  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'modal_quick_add',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Thêm giao dịch mới'),
          ],
        ),
      ),
    );
  }
}
```

---

### 4.8 `lib/features/dashboard/presentation/providers/safe_to_spend_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../domain/forecasting/safe_to_spend_calculator.dart';
import 'dashboard_providers.dart';

/// Pure reactive provider computing the live Safe-to-Spend figure
/// and transparent breakdown using the Zero Double-Counting formula.
final safeToSpendProvider = Provider<AsyncValue<SafeToSpendResult>>((ref) {
  final liquidAssetsAsync = ref.watch(liquidAssetsStreamProvider);
  final envelopesAsync = ref.watch(envelopesStreamProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final pendingBillsAsync = ref.watch(pendingBillsStreamProvider);
  final nextIncomeAsync = ref.watch(nextPlannedIncomeStreamProvider);

  if (liquidAssetsAsync.isLoading ||
      envelopesAsync.isLoading ||
      settingsAsync.isLoading ||
      pendingBillsAsync.isLoading ||
      nextIncomeAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (liquidAssetsAsync.hasError) {
    return AsyncValue.error(liquidAssetsAsync.error!, liquidAssetsAsync.stackTrace!);
  }
  if (envelopesAsync.hasError) {
    return AsyncValue.error(envelopesAsync.error!, envelopesAsync.stackTrace!);
  }
  if (settingsAsync.hasError) {
    return AsyncValue.error(settingsAsync.error!, settingsAsync.stackTrace!);
  }
  if (pendingBillsAsync.hasError) {
    return AsyncValue.error(pendingBillsAsync.error!, pendingBillsAsync.stackTrace!);
  }

  final liquidAssets = VndMoney(liquidAssetsAsync.value ?? 0);
  final settings = settingsAsync.value!;
  final minBuffer = VndMoney(settings.minimumCashBufferVnd);

  final envelopeSnapshots = (envelopesAsync.value ?? []).map((e) {
    return EnvelopeSnapshot(
      id: e.id,
      name: e.name,
      policy: EnvelopePolicyType.fromString(e.policy),
      reservedBalance: VndMoney(e.reservedBalanceVnd),
    );
  }).toList();

  final pendingBillItems = (pendingBillsAsync.value ?? []).map((b) {
    return PendingBillItem(
      id: b.id,
      title: b.title,
      amount: VndMoney(b.amountVnd),
      dueDate: DateTime.fromMillisecondsSinceEpoch(b.dueDateMs),
      linkedEnvelopeId: b.linkedEnvelopeId,
    );
  }).toList();

  final now = DateTime.now();
  final nextIncome = nextIncomeAsync.value;
  final DateTime horizonDate;
  if (nextIncome != null) {
    horizonDate = DateTime.fromMillisecondsSinceEpoch(nextIncome.dueDateMs);
  } else {
    // End of current month
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    horizonDate = DateTime(now.year, now.month, lastDay, 23, 59, 59);
  }

  final result = SafeToSpendCalculator.calculate(
    liquidAssets: liquidAssets,
    envelopes: envelopeSnapshots,
    pendingBills: pendingBillItems,
    minimumCashBuffer: minBuffer,
    now: now,
    horizonDate: horizonDate,
  );

  return AsyncValue.data(result);
});
```

---

### 4.9 `lib/features/dashboard/presentation/providers/dashboard_providers.dart`

```dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/envelope_dao.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../domain/budgeting/category_budget_progress.dart';

// Database & DAOs
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final ledgerDaoProvider = Provider<LedgerDao>((ref) {
  return ref.watch(databaseProvider).ledgerDao;
});

final envelopeDaoProvider = Provider<EnvelopeDao>((ref) {
  return ref.watch(databaseProvider).envelopeDao;
});

// Streams
final liquidAssetsStreamProvider = StreamProvider<int>((ref) {
  return ref.watch(ledgerDaoProvider).watchTotalLiquidAssets();
});

final accountsWithBalancesStreamProvider =
    StreamProvider<List<AccountWithBalance>>((ref) {
  return ref.watch(ledgerDaoProvider).watchAccountsWithBalances();
});

final envelopesStreamProvider = StreamProvider<List<Envelope>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.envelopes)..where((e) => e.isArchived.equals(false)))
      .watch();
});

final settingsStreamProvider = StreamProvider<Setting>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.settings).watchSingle();
});

final pendingBillsStreamProvider = StreamProvider<List<ScheduledItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.scheduledItems)
        ..where((s) => s.kind.equals('BILL') & s.status.equals('PENDING'))
        ..orderBy([(s) => OrderingTerm(expression: s.dueDateMs)]))
      .watch();
});

final nextPlannedIncomeStreamProvider = StreamProvider<ScheduledItem?>((ref) {
  final db = ref.watch(databaseProvider);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  return (db.select(db.scheduledItems)
        ..where((s) =>
            s.kind.equals('PLANNED_INCOME') &
            s.status.equals('PENDING') &
            s.dueDateMs.isBiggerOrEqualValue(nowMs))
        ..orderBy([(s) => OrderingTerm(expression: s.dueDateMs)])
        ..limit(1))
      .watchSingleOrNull();
});

final recentTransactionsStreamProvider =
    StreamProvider<List<JournalTransaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.journalTransactions)
        ..where((t) =>
            t.status.equals('POSTED') & t.txType.equals('REVERSAL').not())
        ..orderBy([
          (t) =>
              OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
        ])
        ..limit(5))
      .watch();
});

/// Category budget summary for the current month.
final currentMonthlyBudgetSummaryProvider =
    StreamProvider<MonthlyBudgetSummary>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final yearMonth = now.year * 100 + now.month;

  // Watch budgets joined with spending for current yearMonth
  final startOfMonthMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  final endOfMonthMs = DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch;

  final budgetsQuery = db.select(db.categoryBudgets)
    ..where((b) => b.yearMonth.equals(yearMonth));

  return budgetsQuery.watch().asyncMap((budgets) async {
    final List<CategoryBudgetProgress> progresses = [];

    for (final b in budgets) {
      final category = await (db.select(db.categories)
            ..where((c) => c.id.equals(b.categoryId)))
          .getSingleOrNull();
      final catName = category?.name ?? 'Danh mục ${b.categoryId}';

      // Compute gross expense and refund credits in this month
      final result = await db.customSelect(
        'SELECT COALESCE(SUM(p.debit_vnd), 0) AS gross_expense, '
        'COALESCE(SUM(p.credit_vnd), 0) AS refund_credits '
        'FROM journal_postings p '
        'JOIN journal_transactions t ON p.transaction_id = t.id '
        'WHERE p.category_id = ? AND t.occurred_at >= ? AND t.occurred_at < ? '
        'AND t.status = "POSTED"',
        variables: [
          Variable.withInt(b.categoryId),
          Variable.withInt(startOfMonthMs),
          Variable.withInt(endOfMonthMs),
        ],
        readsFrom: {db.journalPostings, db.journalTransactions},
      ).getSingle();

      final gross = result.read<int>('gross_expense');
      final refund = result.read<int>('refund_credits');

      progresses.add(CategoryBudgetTracker.evaluateCategoryBudget(
        categoryId: b.categoryId,
        categoryName: catName,
        yearMonth: yearMonth,
        limitVnd: VndMoney(b.limitVnd),
        grossExpense: VndMoney(gross),
        refundCredits: VndMoney(refund),
        alertThresholdPct: b.alertThresholdPct,
      ));
    }

    return CategoryBudgetTracker.evaluateSummary(
      yearMonth: yearMonth,
      categoryProgresses: progresses,
    );
  });
});
```

---

### 4.10 `lib/features/dashboard/presentation/widgets/safe_to_spend_hero_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../domain/forecasting/safe_to_spend_calculator.dart';
import 'safe_to_spend_breakdown_modal.dart';

/// Safe-to-Spend Hero Card component.
/// Invariant (Scenario 12): When Safe-to-Spend is negative, displays
/// exact deficit in ruby red (never clamped to 0), and daily allowance as 0 ₫/ngày.
class SafeToSpendHeroCard extends StatelessWidget {
  final SafeToSpendResult result;

  const SafeToSpendHeroCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDeficit = result.isDeficit;

    final Color bgColor = isDeficit
        ? AppColors.surfaceAccentRubySecondary
        : AppColors.surfaceAccentVerdantSecondary;

    final Color borderColor = isDeficit
        ? AppColors.borderAccentRuby
        : AppColors.borderAccentVerdant;

    final Color primaryTextColor = isDeficit
        ? AppColors.textAccentRubyPrimary
        : AppColors.textAccentVerdantPrimary;

    final Color secondaryTextColor = isDeficit
        ? AppColors.textAccentRubySecondary
        : AppColors.textAccentVerdantSecondary;

    return Semantics(
      identifier: 'hero_safe_to_spend',
      child: Container(
        padding: AppSpacing.paddingHero,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Label & Info action button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDeficit ? Icons.warning_amber_rounded : Icons.shield_outlined,
                      size: 20.0,
                      color: primaryTextColor,
                    ),
                    AppSpacing.gapW8,
                    Text(
                      'TIỀN AN TOÀN ĐỂ CHI TIÊU',
                      style: AppTypography.subheadline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Semantics(
                  identifier: 'btn_safe_to_spend_breakdown',
                  button: true,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.info_outline, size: 20.0, color: primaryTextColor),
                    onPressed: () => showSafeToSpendBreakdownModal(context, result),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH12,

            // Hero Safe-to-Spend Amount
            Semantics(
              identifier: 'text_safe_to_spend_amount',
              child: Text(
                result.safeToSpend.formatVnd(),
                style: AppTypography.displayLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ),
            AppSpacing.gapH4,

            // Daily Allowance / Deficit notice
            Semantics(
              identifier: 'text_daily_allowance',
              child: Text(
                isDeficit
                    ? '0 ₫/ngày (Đang thâm hụt ngân sách)'
                    : '${result.dailyAllowance.formatVnd()}/ngày (${result.daysRemaining} ngày tới)',
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ),

            if (isDeficit) ...[
              AppSpacing.gapH12,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp4,
                  vertical: AppSpacing.sp3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.borderAccentRuby),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16.0, color: AppColors.ruby14),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        'Các nghĩa vụ và quỹ dự phòng vượt quá tiền mặt hiện có.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.ruby14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

### 4.11 `lib/features/dashboard/presentation/widgets/safe_to_spend_breakdown_modal.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../domain/forecasting/safe_to_spend_calculator.dart';

void showSafeToSpendBreakdownModal(BuildContext context, SafeToSpendResult result) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeToSpendBreakdownModal(result: result),
  );
}

/// 4-Term Formula Breakdown Modal Sheet.
/// Explicitly exposes: Liquid Assets - Protected Reserves - Unfunded Bills - Buffer.
class SafeToSpendBreakdownModal extends StatelessWidget {
  final SafeToSpendResult result;

  const SafeToSpendBreakdownModal({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final breakdown = result.breakdown;

    return Semantics(
      identifier: 'modal_safe_to_spend_breakdown',
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: AppSpacing.paddingModal,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.borderSecondary,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              AppSpacing.gapH16,

              // Sheet Title
              Text(
                'Công thức Tiền an toàn chi tiêu',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapH4,
              Text(
                'Khoản tiền thực sự có thể chi tiêu tự do mà không ảnh hưởng đến các nghĩa vụ cố định.',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapH20,

              // 4 Mathematical Terms
              _buildFormulaRow(
                sign: '+',
                label: 'Tài sản tiền mặt khả dụng',
                amount: breakdown.liquidAssets.formatVnd(),
                color: AppColors.textAccentVerdantPrimary,
                subtext: 'Tiền mặt & số dư tài khoản ngân hàng',
              ),
              AppSpacing.gapH12,
              _buildFormulaRow(
                sign: '-',
                label: 'Dự phòng quỹ được bảo vệ',
                amount: breakdown.protectedReserves.formatVnd(),
                color: AppColors.textAccentRubyPrimary,
                subtext: 'Quỹ khẩn cấp & nghĩa vụ đã khóa',
              ),
              AppSpacing.gapH12,
              _buildFormulaRow(
                sign: '-',
                label: 'Nghĩa vụ chưa cấp vốn',
                amount: breakdown.unfundedCommittedOutflows.formatVnd(),
                color: AppColors.textAccentRubyPrimary,
                subtext: 'Hoá đơn sắp tới vượt mức quỹ bảo vệ',
              ),
              AppSpacing.gapH12,
              _buildFormulaRow(
                sign: '-',
                label: 'Vốn đệm tiền mặt tối thiểu',
                amount: breakdown.minimumCashBuffer.formatVnd(),
                color: AppColors.textAccentRubyPrimary,
                subtext: 'Mức đệm an toàn duy trì trong Cài đặt',
              ),
              AppSpacing.gapH16,
              const Divider(),
              AppSpacing.gapH16,

              // Result Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiền an toàn khả dụng',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    result.safeToSpend.formatVnd(),
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: result.isDeficit
                          ? AppColors.textAccentRubyPrimary
                          : AppColors.textAccentVerdantPrimary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH8,

              // Daily allowance note
              Container(
                padding: const EdgeInsets.all(AppSpacing.sp4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18.0),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        result.isDeficit
                            ? 'Mức chi hàng ngày: 0 ₫ (Đang thâm hụt)'
                            : 'Mức chi hàng ngày: ${result.dailyAllowance.formatVnd()}/ngày cho ${result.daysRemaining} ngày tiếp theo.',
                        style: AppTypography.subheadline,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaRow({
    required String sign,
    required String label,
    required String amount,
    required Color color,
    required String subtext,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.0,
          alignment: Alignment.center,
          child: Text(
            sign,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtext,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
```

---

### 4.12 `lib/features/dashboard/presentation/widgets/spending_vs_budget_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../domain/budgeting/category_budget_progress.dart';

/// Spending vs Budget Dashboard Card.
class SpendingVsBudgetCard extends StatelessWidget {
  final MonthlyBudgetSummary summary;
  final VoidCallback onTap;

  const SpendingVsBudgetCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = summary.overallSpentRatio;
    final int pct = (ratio * 100).toInt();

    return Semantics(
      identifier: 'card_spending_vs_budget',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: AppSpacing.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CHI TIÊU & NGÂN SÁCH THÁNG',
                      style: AppTypography.subheadline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: summary.exceededCount > 0
                            ? AppColors.textAccentRubyPrimary
                            : (summary.warningCount > 0
                                ? AppColors.textAccentMarigoldPrimary
                                : AppColors.textAccentVerdantPrimary),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH8,

                // Progress Bar
                ProgressBar(ratio: ratio),
                AppSpacing.gapH8,

                // Metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã chi: ${summary.totalSpentVnd.formatVnd()}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Hạn mức: ${summary.totalLimitVnd.formatVnd()}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                if (summary.exceededCount > 0) ...[
                  AppSpacing.gapH8,
                  Text(
                    '⚠️ Có ${summary.exceededCount} danh mục vượt ngân sách.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textAccentRubyPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### 4.13 `lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';

/// Upcoming Obligations Card on Dashboard.
class UpcomingObligationsCard extends StatelessWidget {
  final List<ScheduledItem> pendingBills;
  final ScheduledItem? nextIncome;
  final ValueChanged<int> onPayObligation;

  const UpcomingObligationsCard({
    super.key,
    required this.pendingBills,
    this.nextIncome,
    required this.onPayObligation,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'card_upcoming_obligations',
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NGHĨA VỤ SẮP ĐẾN HẠN',
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              AppSpacing.gapH12,

              if (pendingBills.isEmpty && nextIncome == null)
                Text(
                  'Không có hoá đơn nào sắp đến hạn.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),

              if (nextIncome != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sp3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAccentVerdantSecondary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward,
                          size: 16.0, color: AppColors.jade14),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          'Thu nhập tiếp theo: ${nextIncome!.title} (${VndFormatter.format(nextIncome!.amountVnd)})',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.jade14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH8,
              ],

              ...pendingBills.take(3).map((bill) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp3),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 20.0),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.title, style: AppTypography.bodyMedium),
                            Text(
                              VndFormatter.format(bill.amountVnd),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textAccentRubySecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        identifier: 'btn_pay_obligation_${bill.id}',
                        button: true,
                        child: OutlinedButton(
                          onPressed: () => onPayObligation(bill.id),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const BoxConstraints(minHeight: 32),
                          ),
                          child: const Text('Đã trả'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 4.14 `lib/features/dashboard/presentation/widgets/fund_progress_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';

/// Mini Virtual Funds progress preview on Dashboard.
class FundProgressCard extends StatelessWidget {
  final List<Envelope> envelopes;
  final VoidCallback onTap;

  const FundProgressCard({
    super.key,
    required this.envelopes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int totalReserved =
        envelopes.fold(0, (sum, e) => sum + e.reservedBalanceVnd);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUỸ TIỀN ẢO',
                    style: AppTypography.subheadline.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    VndFormatter.format(totalReserved),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textAccentVerdantPrimary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH8,
              Text(
                '${envelopes.length} quỹ đang hoạt động.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 4.15 `lib/features/dashboard/presentation/widgets/recent_transactions_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';

/// Recent 5 Transactions mini list on Dashboard.
class RecentTransactionsCard extends StatelessWidget {
  final List<JournalTransaction> transactions;
  final VoidCallback onTapViewAll;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.onTapViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GIAO DỊCH GẦN ĐÂY',
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: onTapViewAll,
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            AppSpacing.gapH8,

            if (transactions.isEmpty)
              Text(
                'Chưa có giao dịch nào.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),

            ...transactions.map((tx) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceSecondary,
                  child: Icon(
                    tx.txType == 'INCOME'
                        ? Icons.arrow_downward
                        : (tx.txType == 'EXPENSE'
                            ? Icons.arrow_upward
                            : Icons.swap_horiz),
                    size: 18,
                    color: tx.txType == 'INCOME'
                        ? AppColors.jade14
                        : (tx.txType == 'EXPENSE'
                            ? AppColors.ruby14
                            : AppColors.blue14),
                  ),
                ),
                title: Text(tx.description, style: AppTypography.bodyMedium),
                subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(tx.occurredAt)
                      .toString()
                      .split(' ')[0],
                  style: AppTypography.caption,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
```

---

### 4.16 `lib/features/dashboard/presentation/dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import 'providers/dashboard_providers.dart';
import 'providers/safe_to_spend_provider.dart';
import 'widgets/fund_progress_card.dart';
import 'widgets/recent_transactions_card.dart';
import 'widgets/safe_to_spend_hero_card.dart';
import 'widgets/spending_vs_budget_card.dart';
import 'widgets/upcoming_obligations_card.dart';

/// Tab 0: Dashboard (Tổng quan) Screen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeToSpendAsync = ref.watch(safeToSpendProvider);
    final budgetSummaryAsync = ref.watch(currentMonthlyBudgetSummaryProvider);
    final pendingBillsAsync = ref.watch(pendingBillsStreamProvider);
    final nextIncomeAsync = ref.watch(nextPlannedIncomeStreamProvider);
    final envelopesAsync = ref.watch(envelopesStreamProvider);
    final recentTxAsync = ref.watch(recentTransactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đồng Tiền'),
        actions: [
          Semantics(
            identifier: 'btn_appbar_reports',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.assessment_outlined),
              onPressed: () {
                // Secondary navigation to Reports
              },
            ),
          ),
          Semantics(
            identifier: 'btn_appbar_settings',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                // Secondary navigation to Settings
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapH8,

            // 1. Safe-to-Spend Hero Card
            safeToSpendAsync.when(
              data: (result) => SafeToSpendHeroCard(result: result),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Lỗi: $err', style: AppTypography.caption),
            ),
            AppSpacing.gapH16,

            // 2. Spending vs Budget Card
            budgetSummaryAsync.when(
              data: (summary) => SpendingVsBudgetCard(
                summary: summary,
                onTap: () {
                  ref.read(navigationIndexProvider.notifier).state = 3; // Plans tab
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            AppSpacing.gapH16,

            // 3. Upcoming Obligations Card
            UpcomingObligationsCard(
              pendingBills: pendingBillsAsync.value ?? [],
              nextIncome: nextIncomeAsync.value,
              onPayObligation: (billId) {
                // Trigger obligation payment command
              },
            ),
            AppSpacing.gapH16,

            // 4. Mini Fund Progress Card
            FundProgressCard(
              envelopes: envelopesAsync.value ?? [],
              onTap: () {
                ref.read(navigationIndexProvider.notifier).state = 2; // Funds tab
              },
            ),
            AppSpacing.gapH16,

            // 5. Recent 5 Transactions Card
            RecentTransactionsCard(
              transactions: recentTxAsync.value ?? [],
              onTapViewAll: () {
                ref.read(navigationIndexProvider.notifier).state = 1; // Transactions tab
              },
            ),
            const SizedBox(height: AppSpacing.sp13), // Bottom bar clearance
          ],
        ),
      ),
    );
  }
}
```

---

### 4.17 `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DongTienApp(),
    ),
  );
}
```

---

## 5. VERIFICATION METHOD & WIDGET TEST SUITE

The implementer (`worker_m3_ui_core`) and QA auditor will verify this implementation through the following automated test steps:

### 5.1 Verification Commands
```bash
# 1. Code formatting check
dart format --output=none --set-exit-if-changed lib/app/ lib/core/widgets/ lib/features/dashboard/

# 2. Static analysis
flutter analyze

# 3. Unit & Widget tests
flutter test test/widget/dashboard_hero_test.dart
flutter test test/widget/custom_keypad_test.dart
flutter test test/widget/progress_bar_test.dart
```

### 5.2 Widget Test Specification: `test/widget/dashboard_hero_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/app/theme/app_colors.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/forecasting/safe_to_spend_calculator.dart';
import 'package:dongtien/features/dashboard/presentation/widgets/safe_to_spend_hero_card.dart';

void main() {
  group('SafeToSpendHeroCard Widget Tests', () {
    testWidgets('Renders positive Safe-to-Spend amount in Jade color', (tester) async {
      final result = SafeToSpendResult(
        safeToSpend: VndMoney(8500000),
        dailyAllowance: VndMoney(283333),
        isDeficit: false,
        daysRemaining: 30,
        breakdown: const SafeToSpendBreakdown(
          liquidAssets: VndMoney(10000000),
          protectedReserves: VndMoney(1000000),
          unfundedCommittedOutflows: VndMoney(500000),
          minimumCashBuffer: VndMoney.zero,
          billAllocations: [],
          envelopeCoverages: [],
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SafeToSpendHeroCard(result: result)),
      ));

      expect(find.bySemanticsLabel('hero_safe_to_spend'), findsOneWidget);
      expect(find.text('8.500.000 ₫'), findsOneWidget);
      expect(find.text('283.333 ₫/ngày (30 ngày tới)'), findsOneWidget);
    });

    testWidgets('Scenario 12: Renders negative deficit in Ruby red with 0 ₫/ngày', (tester) async {
      final result = SafeToSpendResult(
        safeToSpend: VndMoney(-1500000),
        dailyAllowance: VndMoney.zero,
        isDeficit: true,
        daysRemaining: 15,
        breakdown: const SafeToSpendBreakdown(
          liquidAssets: VndMoney(2000000),
          protectedReserves: VndMoney(1500000),
          unfundedCommittedOutflows: VndMoney(1000000),
          minimumCashBuffer: VndMoney(1000000),
          billAllocations: [],
          envelopeCoverages: [],
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SafeToSpendHeroCard(result: result)),
      ));

      expect(find.text('-1.500.000 ₫'), findsOneWidget);
      expect(find.text('0 ₫/ngày (Đang thâm hụt ngân sách)'), findsOneWidget);
    });
  });
}
```

### 5.3 Widget Test Specification: `test/widget/custom_keypad_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/widgets/custom_keypad.dart';

void main() {
  group('CustomKeypad Widget Tests', () {
    testWidgets('Tapping digits and backspace triggers callbacks and semantics', (tester) async {
      final List<int> pressed = [];
      bool backspacePressed = false;
      bool donePressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomKeypad(
            onDigitPressed: (d) => pressed.add(d),
            onBackspacePressed: () => backspacePressed = true,
            onDonePressed: () => donePressed = true,
          ),
        ),
      ));

      await tester.tap(find.bySemanticsLabel('keypad_btn_1'));
      await tester.tap(find.bySemanticsLabel('keypad_btn_2'));
      await tester.tap(find.bySemanticsLabel('keypad_btn_5'));
      await tester.tap(find.bySemanticsLabel('keypad_btn_0'));
      await tester.tap(find.bySemanticsLabel('keypad_btn_backspace'));
      await tester.tap(find.bySemanticsLabel('keypad_btn_done'));

      expect(pressed, equals([1, 2, 5, 0]));
      expect(backspacePressed, isTrue);
      expect(donePressed, isTrue);
    });
  });
}
```

### 5.4 Invalidation Conditions
This blueprint is invalidated if:
1. `max_Safe_VND` or `VndMoney` integer representation changes.
2. The Safe-to-Spend formula in `ARCHITECTURE_AND_RULES.md` is altered.
3. Any forbidden package (`go_router`, `fl_chart`, `freezed`) is introduced.
4. Non-tabular font features are used on monetary text widgets.
