# Handoff Report — Milestone M3 (Local Notifications, Real Timezone, Permissions & Budget Alerts)

## 1. Observation
- Target files inspected and modified:
  - `lib/core/notifications/notification_scheduler.dart`:
    - Added real local timezone initialization via `flutter_timezone` (`FlutterTimezone.getLocalTimezone()`, `tz.setLocalLocation()`) with fallback `Asia/Ho_Chi_Minh`.
    - Added Android 13/14+ runtime `POST_NOTIFICATIONS` permission request via `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`.
    - Exposed shared `notificationSchedulerProvider = Provider<NotificationScheduler>((ref) => NotificationScheduler());`.
    - Implemented `showTestNotification()` with channel `dongtien_test_channel` ('Thông báo kiểm tra', `Importance.max`, `Priority.max`) and notification ID `9999`.
    - Implemented `cancelAll()`, `reconcileFromDatabase(AppDatabase db)`, and `checkCategoryBudgetAlert({required AppDatabase db, required int categoryId})`.
    - Single-quoted string literals `'POSTED'` and `'REVERSAL'` are enforced in SQLite query within `checkCategoryBudgetAlert`.
  - `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`:
    - Updated `ReportsSettingsController.updateNotificationsEnabled` to initialize and reconcile notifications when enabled, and invoke `cancelAll()` when disabled.
  - `lib/features/plans/presentation/providers/plans_providers.dart`:
    - Updated `PlansController.createScheduledItem` to call `reconcileFromDatabase` when a `BILL` item is created.
    - Updated `PlansController.markScheduledItemPaid` to call `reconcileFromDatabase` and `checkCategoryBudgetAlert` for the affected expense category upon payment.
  - `lib/features/transactions/presentation/controllers/transaction_controller.dart`:
    - Updated `TransactionController.postTransaction` to invoke `checkCategoryBudgetAlert` for all affected expense categories.
    - Updated `TransactionController.editTransaction` to invoke `checkCategoryBudgetAlert` for all affected expense categories in the replacement command.
  - `lib/features/reports_settings/presentation/settings_screen.dart`:
    - Replaced isolated local `_scheduler` with `ref.read(notificationSchedulerProvider)`.
    - Initialized permission state in `initState` post-frame callback to show warning banner when permission is not granted.
    - Added "Gửi thông báo kiểm tra ngay" button with `Semantics(identifier: 'btn_test_notification', button: true, ...)` that displays on-screen test notification and feedback snackbars.
  - `test/unit/notification_scheduler_test.dart`:
    - Created 6 unit tests covering timezone initialization, permission denial graceful degradation, test notification firing, budget threshold alerts (below 80%, 80-99%, >=100%), SQLite database budget checks, and database reconciliation.
  - `test/widget/features_widget_test.dart`:
    - Added widget tests verifying presence and behavior of `btn_test_notification` button and permission denied banner.

## 2. Logic Chain
1. Android 13/14+ devices require runtime user permission for `POST_NOTIFICATIONS`. By querying `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`, the system prompt is triggered at appropriate times while maintaining graceful fallback if denied.
2. Timezone synchronization is required for scheduled notifications at 20:00 local time to avoid UTC offsets (+7 hours in Vietnam). Calling `FlutterTimezone.getLocalTimezone()` with safe fallback to `Asia/Ho_Chi_Minh` guarantees reliable scheduling across all devices.
3. Exposing a Riverpod provider (`notificationSchedulerProvider`) eliminates duplicated/isolated scheduler instances, allowing consistent notification state management across Settings, Plans, and Transaction controllers.
4. Auto-alerting in `TransactionController` and `PlansController` inspects monthly category budget limits and cumulative net expenditures using single-quoted `'POSTED'` and `'REVERSAL'` SQL syntax to prevent SQLite dialect errors. Thresholds of 80% (warning) and 100% (exceeded) trigger heads-up banners immediately.
5. In SettingsScreen, `btn_test_notification` allows users and auditors to verify on-screen notification delivery with a single tap.

## 3. Caveats
- Native push notifications only appear on physical Android devices or running emulators with Google APIs and notification services enabled. In headless test runners and desktop hosts, the scheduler gracefully records invocation states (`lastNotificationId`, `lastNotificationTitle`, `lastNotificationBody`) without throwing missing plugin exceptions.
- No caveats regarding project invariants, SQLite integrity, or offline-first constraints.

## 4. Conclusion
- Requirement R2 is fully implemented and tested according to specification.
- All quality gates pass:
  - `dart format --output=none --set-exit-if-changed .`: Exit code 0 (all 114 files clean).
  - `flutter analyze`: Exit code 0 (0 issues found).
  - `flutter test`: Exit code 0 (308/308 tests passed, 100% success).

## 5. Verification Method
Run the following PowerShell commands to independently verify:
```powershell
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path

# 1. Format check
dart format --output=none --set-exit-if-changed .

# 2. Static analysis
flutter analyze

# 3. Dedicated unit & widget test runs
flutter test test/unit/notification_scheduler_test.dart
flutter test test/widget/features_widget_test.dart

# 4. Complete test suite
flutter test
```
