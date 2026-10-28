# Dispatch to worker_m3

## Identity & Scope
- **Agent Name**: `worker_m3`
- **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m3\`
- **Milestone**: M3 (Local Notifications, Real Timezone, Permissions & Budget Alerts — Requirement R2)

## Target Files
1. `lib/core/notifications/notification_scheduler.dart`
2. `lib/features/reports_settings/presentation/settings_screen.dart`
3. `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`
4. `lib/features/plans/presentation/providers/plans_providers.dart`
5. `lib/features/transactions/presentation/controllers/transaction_controller.dart`
6. `test/unit/notification_scheduler_test.dart`
7. `test/widget/features_widget_test.dart`

## Inputs & Blueprints
Read the authoritative blueprints and exact code proposals in:
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\report.md` (§ 2)
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\handoff.md`
- `c:\Users\coihu12\Documents\App\PROJECT.md`
- `c:\Users\coihu12\Documents\App\AGENTS.md`
- `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (## 2026-10-28T00:39:16Z § R2)

## Mandatory Tasks
1. **NotificationScheduler**:
   - Initialize real local timezone via `flutter_timezone` (`FlutterTimezone.getLocalTimezone()`, `tz.setLocalLocation()`, with fallback `Asia/Ho_Chi_Minh`).
   - Request runtime `POST_NOTIFICATIONS` permission on Android 13/14+ via `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`.
   - Expose `notificationSchedulerProvider = Provider<NotificationScheduler>((ref) => NotificationScheduler());`.
   - Implement `showTestNotification()`, `cancelAll()`, `reconcileFromDatabase(AppDatabase db)`, and `checkCategoryBudgetAlert({required AppDatabase db, required int categoryId})`.
   - In `checkCategoryBudgetAlert`, query category monthly net spent using single-quoted `'POSTED'` and `'REVERSAL'`. If net spent >= 80% or >= 100%, trigger alert.
2. **Wiring**:
   - `ReportsSettingsController.updateNotificationsEnabled`: initialize & reconcile when enabled; cancelAll when disabled.
   - `PlansController.createScheduledItem` & `markScheduledItemPaid`: reconcile with DB, and check budget alert when categoryId is set.
   - `TransactionController.postTransaction` & `editTransaction`: check budget alerts for all expense categories involved.
3. **Settings UI**:
   - In `SettingsScreen`: replace local `_scheduler` with `ref.read(notificationSchedulerProvider)`.
   - Add "Gửi thông báo kiểm tra ngay" button with `Semantics(identifier: 'btn_test_notification', button: true, ...)`.
   - Display banner when permission is denied.
4. **Testing**:
   - Add unit tests in `test/unit/notification_scheduler_test.dart` for timezone fallback, permission denied handling, budget threshold alerts, and test notification.
   - Add/update widget tests in `test/widget/features_widget_test.dart` for `btn_test_notification` button and permission banner.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Toolchain Environment
```powershell
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
```

## Quality Gates
Run:
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
Document exact results in your `handoff.md` and message orchestrator_2.
