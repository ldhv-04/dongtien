# Dispatch to Orchestrator

## Identity & Working Directory
- **Agent Name**: `orchestrator_2`
- **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_2\`
- **Project Root**: `c:\Users\coihu12\Documents\App`

## Authoritative Request
See `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` under header `## 2026-10-28T00:39:16Z`.

## Mandatory Deliverables
1. **R1**: Single-payment bills & planned income (`recurrence = 'NONE'`), confirmation dialogs on "Đã trả" / "Đã nhận", move to completed history with disabled "Đã hoàn tất" button, deterministic idempotency key (`scheduled_pay_<id>`), in-flight tap guards (`_isSubmitting`).
2. **R2**: Android 14 local notifications with real local timezone initialization via `flutter_timezone` (fallback `Asia/Ho_Chi_Minh`), `POST_NOTIFICATIONS` runtime permission request, shared Riverpod provider, automatic alerts (toggled in Settings, bills added/paid, category budget crossing 80%/100%), and "Gửi thông báo kiểm tra ngay" button (`Semantics` identifier `btn_test_notification`).
3. **R3**: Fix `SqliteException(1)` when creating category budgets by changing `"POSTED"` double-quoted identifier to single quotes `'POSTED'` in `currentMonthlyBudgetSummaryProvider`. Audit all raw SQL queries (`customSelect`, `customUpdate`, `customStatement`) for single quotes.
4. **R4**: Optimize queries (single aggregated SQLite `JOIN ... GROUP BY` in `currentMonthlyBudgetSummaryProvider`, bounded queries in `reportsSummaryProvider`). Configure R8 code shrinking and resource shrinking in `android/app/build.gradle` and `proguard-rules.pro`. Build split-per-ABI release APKs (`flutter build apk --release --split-per-abi --tree-shake-icons`) producing lean builds (~18-22MB per ABI). Update `Launch_DongTien_Emulator.bat`, and install the APK onto the emulator if connected via `adb`.
5. **Quality Gates**: `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and `flutter test` must pass with zero errors.

## Invariants & Environment
- Review `c:\Users\coihu12\Documents\App\AGENTS.md` for project rules, locked dependencies, and architecture.
- Toolchain environment variables on this machine:
  `$env:JAVA_HOME = "C:\Users\coihu12\jdk17"`
  `$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"`
  Prepend `C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools` to `$env:Path`.
- Regularly update `progress.md` in your working directory.

## 2026-10-28T00:41:58Z
You are orchestrator_2, the Project Orchestrator for Đồng Tiền (vn.dongtien).
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_2\
Read your dispatch instructions in c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_2\DISPATCH.md and the authoritative user request in c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md (under ## 2026-10-28T00:39:16Z).
Preserve all invariants in c:\Users\coihu12\Documents\App\AGENTS.md.
Orchestrate the work across the 4 requirement areas (R1, R2, R3, R4) and quality gates:
1. R1: Single-payment bills & planned income (recurrence = 'NONE'), confirmation dialogs, completed history section, disabled button, idempotency key (scheduled_pay_<id>), in-flight tap guards (_isSubmitting).
2. R2: Local notifications with real local timezone (flutter_timezone, fallback Asia/Ho_Chi_Minh), POST_NOTIFICATIONS runtime permission request, shared Riverpod provider, automatic alerts, test notification button (Semantics identifier btn_test_notification).
3. R3: Fix SqliteException(1) in currentMonthlyBudgetSummaryProvider (double-quoted "POSTED" to single quotes 'POSTED'), audit all raw SQL queries.
4. R4: Query optimization (single aggregated JOIN ... GROUP BY in currentMonthlyBudgetSummaryProvider, bounded queries in reportsSummaryProvider), R8 code & resource shrinking in android/app/build.gradle and proguard-rules.pro, split-per-ABI release APK builds (<30MB each), update Launch_DongTien_Emulator.bat, and adb install if emulator connected.
5. Pass dart format, flutter analyze, flutter test, and flutter build apk.

Keep progress.md in your working directory updated continuously. When all requirements and gates are satisfied, report completion back to Sentinel.
