# Project: Đồng Tiền (vn.dongtien) — Maintenance & Hardening

## Architecture
Clean Architecture with offline-first local SQLite persistence:
- **Core Persistence & Money**: `lib/core/database/` (Drift SQLite tables, DAOs), `lib/core/money/` (`VndMoney`, formatting), `lib/core/security/` (AES-256-GCM), `lib/core/notifications/` (`NotificationScheduler`).
- **Domain Services**: Pure Dart engines in `lib/domain/` (zero Flutter/Drift imports).
- **Features & State**: Riverpod standard Notifiers/AsyncNotifiers in `lib/features/` consuming domain and DAOs.
- **Presentation**: Material 3 UI (`vi_VN` locale, tabular numerals, Semantics identifiers).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| F1 | Fix SqliteException(1) in Budget Stream | Replace `"POSTED"` with `'POSTED'` and `AND t.tx_type != 'REVERSAL'` in `currentMonthlyBudgetSummaryProvider` | M1 | R3 |
| F2 | Single Aggregated Budget Query | Replace N+1 loop in `currentMonthlyBudgetSummaryProvider` with single SQLite `JOIN ... GROUP BY` query | M1 | R4 |
| F3 | Bounded Queries in Reports Summary | Replace full-table `journal_postings` memory load in `reportsSummaryProvider` with 3 bounded SQLite queries | M1 | R4 |
| F4 | Single-Payment Obligations | Convert bills and planned income to strictly single-payment (`recurrence = 'NONE'`), date picker, no recurring row spawning | M2 | R1 |
| F5 | Confirmation Dialogs for Obligations | Require user confirmation before marking "Đã trả" or "Đã nhận" in Plans and Dashboard | M2 | R1 |
| F6 | Completed Obligations History | Add "Lịch sử đã thanh toán / Đã nhận" section with permanently disabled "Đã hoàn tất" button | M2 | R1 |
| F7 | Deterministic Idempotency Key | Enforce `idempotencyKey = 'scheduled_pay_<id>'` when marking scheduled items paid | M2 | R1 |
| F8 | Anti-Double-Tap Guards (_isSubmitting) | Add in-flight tap guards across all modal sheets and `CustomKeypad` | M2 | R1 |
| F9 | Real Local Timezone & Permission Request | Initialize real local timezone via `flutter_timezone` (fallback `Asia/Ho_Chi_Minh`) and runtime `POST_NOTIFICATIONS` permission | M3 | R2 |
| F10 | Shared Notification Provider & Auto-Alerts | Expose `notificationSchedulerProvider`, wire auto-scheduling on Settings toggle, bill add/pay, and budget 80%/100% crossings | M3 | R2 |
| F11 | In-App Test Notification Button | Add "Gửi thông báo kiểm tra ngay" button (`Semantics` identifier `btn_test_notification`) in `SettingsScreen` | M3 | R2 |
| F12 | R8 Code & Resource Shrinking | Enable `minifyEnabled true`, `shrinkResources true`, and create `proguard-rules.pro` in `android/app/` | M4 | R4 |
| F13 | Lean Split-per-ABI Release Builds | Build split-per-ABI release APKs (<30MB each), update `Launch_DongTien_Emulator.bat`, and install via `adb` if emulator is connected | M4 | R4 |
| F14 | Comprehensive Quality Gates & Audit | Validate `dart format`, `flutter analyze`, 100% test pass, and forensic audit | M5 | Gates |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Database Bug Fixes & Query Optimization | F1, F2, F3 | None | DONE |
| M2 | Single-Payment Obligations & Anti-Double-Tap UX | F4, F5, F6, F7, F8 | None | DONE |
| M3 | Local Notifications, Permissions & Budget Alerts | F9, F10, F11 | M1 | DONE |
| M4 | Android R8 Shrinking & Lean Release Builds | F12, F13 | M1, M2, M3 | DONE |
| M5 | Comprehensive Quality Gates & Audit | F14 (All) | M1, M2, M3, M4 | DONE |

## Code Layout
- `lib/features/dashboard/presentation/providers/dashboard_providers.dart`: `currentMonthlyBudgetSummaryProvider` (F1, F2)
- `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`: `reportsSummaryProvider` (F3), `updateNotificationsEnabled` (F10)
- `lib/features/plans/presentation/`: `obligations_forecast_view.dart`, `plans_providers.dart`, `category_budgets_view.dart` (F4, F5, F6, F7, F8)
- `lib/features/dashboard/presentation/`: `dashboard_screen.dart`, `upcoming_obligations_card.dart` (F5)
- `lib/core/widgets/custom_keypad.dart`: Done action disabled state (F8)
- `lib/features/envelopes/presentation/modals/`: `_isSubmitting` guards (F8)
- `lib/features/accounts/presentation/add_edit_account_modal.dart`: `_isSubmitting` guard (F8)
- `lib/core/notifications/notification_scheduler.dart`: Timezone, permissions, test notification, budget alerts, provider (F9, F10)
- `lib/features/reports_settings/presentation/settings_screen.dart`: `btn_test_notification` (F11)
- `android/app/build.gradle`, `android/app/proguard-rules.pro`: R8 config (F12)
- `Launch_DongTien_Emulator.bat`: Lean release APK path (F13)
- `test/unit/`, `test/widget/`: Comprehensive automated test verification

## Interface Contracts
### Notification Scheduler ↔ Controllers
- `notificationSchedulerProvider`: `Provider<NotificationScheduler>`
- `NotificationScheduler.reconcileFromDatabase(AppDatabase db)`
- `NotificationScheduler.checkCategoryBudgetAlert({required AppDatabase db, required int categoryId})`
- `NotificationScheduler.showTestNotification()`
- `NotificationScheduler.cancelAll()`

### Plans Controller ↔ Ledger DAO
- `markScheduledItemPaid`: passes `idempotencyKey: 'scheduled_pay_${item.id}'` to `dao.postTransaction` / `dao.postTransactionCommand`.
- Returns integer transaction ID; suppresses recurring row creation.
