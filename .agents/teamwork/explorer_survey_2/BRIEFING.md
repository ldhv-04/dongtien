# BRIEFING — 2026-10-28T00:53:30Z

## Mission
Thoroughly survey and investigate the codebase for Requirement R2: On-Screen Notification Delivery & Verification.

## 🔒 My Identity
- Archetype: explorer
- Roles: codebase investigator, architect surveyor, synthesis
- Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2
- Original parent: e84dfd06-a5ff-437b-948f-883d103ebdc9
- Milestone: Requirement R2 (On-Screen Notification Delivery & Verification)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement code changes in the app source code
- Confine workspace edits to c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\
- Comply with AGENTS.md invariants (Integer VND, offline-first, no forbidden packages, tabular figures, Semantics identifiers)

## Current Parent
- Conversation ID: e84dfd06-a5ff-437b-948f-883d103ebdc9
- Updated: 2026-10-28T00:53:30Z

## Investigation State
- **Explored paths**:
  - `lib/core/notifications/notification_scheduler.dart`
  - `pubspec.yaml`, `pubspec.lock`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/build.gradle`
  - `lib/features/reports_settings/presentation/settings_screen.dart`
  - `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`
  - `lib/features/plans/presentation/providers/plans_providers.dart`
  - `lib/features/transactions/presentation/controllers/transaction_controller.dart`
  - `lib/features/transactions/presentation/quick_add_modal.dart`
  - `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
  - `test/` (all 275 tests currently passing)
- **Key findings**:
  1. `tz.setLocalLocation` was never called, keeping `tz.local` at UTC (causing 7h offset in Vietnam).
  2. `POST_NOTIFICATIONS` runtime permission was not requested via `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`.
  3. No `notificationSchedulerProvider` exists; `SettingsScreen` uses an isolated private instance.
  4. Auto-scheduling is missing in settings toggle, bill add/pay, and expense category budget crossing 80%/100%.
  5. Missing test notification button (`btn_test_notification`) on `SettingsScreen`.
- **Unexplored areas**: None (Survey completed 100%).

## Key Decisions Made
- Expose `notificationSchedulerProvider` in `lib/core/notifications/notification_scheduler.dart`.
- Add `checkCategoryBudgetAlert` and `reconcileFromDatabase` helpers directly to `NotificationScheduler` to avoid query duplication and keep domain/controller layers clean.
- Add "Gửi thông báo kiểm tra ngay" button (`btn_test_notification`) below notification switch in `SettingsScreen`.

## Artifact Index
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\report.md` — Comprehensive survey report
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\handoff.md` — 5-component handoff report
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_2\progress.md` — Liveness heartbeat
