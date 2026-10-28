# Dispatch to explorer_survey_2

## Mission
Survey codebase for Requirement R2: On-Screen Notification Delivery & Verification.

## Inputs
- Authoritative request: `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (specifically ## 2026-10-28T00:39:16Z § R2)
- Project rules: `c:\Users\coihu12\Documents\App\AGENTS.md`
- Target code areas:
  - `lib/core/notifications/notification_scheduler.dart`
  - `pubspec.yaml` (dependencies: `flutter_local_notifications`, `timezone`, `flutter_timezone`)
  - Android configuration: `android/app/src/main/AndroidManifest.xml` (permissions: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`)
  - Riverpod providers for notifications
  - Integration with Settings, transaction/expense flow (budget crossing 80%/100%), and scheduled items (bills added/paid)
  - `SettingsScreen` test notification button (`Semantics` identifier `btn_test_notification`)

## Deliverables
Write your comprehensive investigation report to:
`c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\report.md`
and write your `handoff.md`.
Identify all affected files, line numbers, current behavior vs required behavior, and exact implementation recommendations.

## 2026-10-28T00:43:46Z
You are explorer_survey_2.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\
Read your dispatch instructions in: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\DISPATCH.md
Read the authoritative user request in: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md (under ## 2026-10-28T00:39:16Z § R2)
Read the system invariants in: c:\Users\coihu12\Documents\App\AGENTS.md

Your task is to thoroughly survey and investigate the codebase for Requirement R2:
1. NotificationScheduler in lib/core/notifications/notification_scheduler.dart:
   - Real local timezone initialization via flutter_timezone (tz.setLocalLocation, fallback to Asia/Ho_Chi_Minh).
   - Android 13/14+ runtime POST_NOTIFICATIONS permission request via AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission().
   - Check AndroidManifest.xml permissions.
2. Expose a shared Riverpod provider for NotificationScheduler.
3. Wire automatic scheduling/alerting:
   - When notifications are toggled in Settings.
   - When scheduled bills are added/paid.
   - When an expense causes a category budget to cross 80% or 100%.
4. Add "Gửi thông báo kiểm tra ngay" button with Semantics identifier btn_test_notification in SettingsScreen.
5. Identify existing tests and what new tests are required.

Write your findings to: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\report.md
Write your handoff to: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\handoff.md
Send a completion message back to orchestrator_2 when finished.
