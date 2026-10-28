## 2026-10-27T19:42:23Z
You are explorer_m3_ui_core.
Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m3_ui_core
Read:
- c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\DESIGN_AND_TEST_PLAN.md (Sections 1, 2, 3, 4, 5, 6)
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md
- c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart
- c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart
- `lib/domain/forecasting/safe_to_spend_calculator.dart`
- `lib/core/database/daos/ledger_dao.dart`

Investigate and author a detailed implementation blueprint for:
1. Design system tokens in `lib/app/theme/`:
   - `app_colors.dart`: 7 color families from Untitled-3.png (Primary Jade, Slate Neutral, Accent Amber, Accent Ruby, Functional Blue, Surface, Overlay).
   - `app_typography.dart`: 7 scales (displayLarge, headlineMedium, titleLarge, bodyLarge, bodyMedium, labelMedium, caption) with tabular figures (`FontFeature.tabularFigures()`).
   - `app_spacing.dart`: 16-step spacing scale from Spacing.png (spacing2 = 2dp to spacing64 = 64dp).
2. Presentation widgets in `lib/core/widgets/`:
   - `custom_keypad.dart`: 4x3 custom numeric keypad from `wallet.png` with Backspace and Done button.
   - `progress_bar.dart`: Material 3 two-tone progress bar with overflow/warning state.
3. App shell in `lib/app/`:
   - `app.dart`: `MaterialApp`, `vi_VN` localization (`supportedLocales: [Locale('vi', 'VN')]`), `IndexedStack` preserving state across the 4 bottom navigation tabs (`Tổng quan`, `Giao dịch`, `Quỹ tiền`, `Kế hoạch`).
4. Dashboard (Tab 0) in `lib/features/dashboard/`:
   - Safe-to-Spend hero card: displays live Safe-to-Spend amount, daily allowance, deficit alert (ruby red if negative), and breakdown modal sheet.
   - Spending vs Budget card (consuming category spending calculations).
   - Upcoming obligations card.
5. Riverpod state management: Providers for Safe-to-Spend, liquid assets, and dashboard presentation.
6. Semantics identifiers from `docs/DESIGN_AND_TEST_PLAN.md` Section 6.

Write your full blueprint report to:
c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m3_ui_core\handoff.md
Notify orchestrator when done.
