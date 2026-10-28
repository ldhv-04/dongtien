## 2026-10-27T19:52:10Z
[Message] timestamp=2026-10-27T19:52:10Z sender=4b707e3a-5355-44d8-b48d-d32bbd3220b1 priority=MESSAGE_PRIORITY_HIGH content=You are worker_m3_ui_core, the UI Core, Theme, Navigation Shell & Dashboard Lead Worker for DongTien.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m3_ui_core\

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY INVARIANTS:
1. Zero floating point currency: all monetary values are 64-bit int VndMoney.
2. Tabular figures: FontFeature.tabularFigures() on all monetary, percentage, and date text.
3. Material 3 styling and exact tokens from docs/design_refs/ and docs/DESIGN_AND_TEST_PLAN.md.
4. Zero forbidden packages: no uuid, no chart libraries (fl_chart), no go_router, no freezed, no dio/http, no firebase_*.
5. Semantics identifiers for accessibility and automated testing on all key cards, buttons, tabs, and modals.

TASKS:
1. Read the authoritative request and blueprint:
   - c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
   - c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m3_ui_core\handoff.md
   - c:\Users\coihu12\Documents\App\AGENTS.md
   - c:\Users\coihu12\Documents\App\docs\DESIGN_AND_TEST_PLAN.md
2. Implement design system tokens:
   - lib/app/theme/app_colors.dart (7 color families)
   - lib/app/theme/app_typography.dart (7 scales with tabular figures)
   - lib/app/theme/app_spacing.dart (16-step scale)
   - lib/app/theme/app_theme.dart (Material 3 ThemeData)
3. Implement core presentation widgets:
   - lib/core/widgets/custom_keypad.dart (4x3 keypad with touch targets >= 48px, backspace, done)
   - lib/core/widgets/progress_bar.dart (two-tone M3 progress bar with normal, warning >=80%, exceeded >100%)
4. Implement navigation shell:
   - lib/app/app.dart (MaterialApp, vi_VN locale, IndexedStack for 4 tabs, AppBar, QuickAdd FAB, and fallback placeholders for Tabs 1, 2, 3 so the app runs cleanly)
5. Implement Dashboard (Tab 0):
   - lib/features/dashboard/presentation/dashboard_screen.dart
   - lib/features/dashboard/presentation/widgets/safe_to_spend_hero_card.dart (Scenario 12 ruby deficit alert, daily allowance 0 if negative, breakdown modal)
   - lib/features/dashboard/presentation/widgets/safe_to_spend_breakdown_modal.dart
   - lib/features/dashboard/presentation/widgets/spending_vs_budget_card.dart
   - lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart
   - lib/features/dashboard/presentation/widgets/fund_progress_card.dart
   - lib/features/dashboard/presentation/widgets/recent_transactions_card.dart
   - lib/features/dashboard/providers/dashboard_providers.dart (Riverpod providers consuming LedgerDao, EnvelopeDao, SafeToSpendCalculator, etc.)
6. Create comprehensive widget tests:
   - test/widget/dashboard_widget_test.dart (verifying hero card, normal vs deficit states, breakdown modal, tabular figures, tab switching)
7. Run verification commands and ensure 0 errors:
   - dart format --output=none --set-exit-if-changed .
   - flutter analyze
   - flutter test
8. Write your completion report to:
   c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m3_ui_core\handoff.md
   and notify the orchestrator via send_message.
