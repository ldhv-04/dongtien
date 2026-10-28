# Dispatch to explorer_survey_3

## Mission
Survey codebase for Requirements R3 & R4:
- R3: Fix SqliteException(1) on category budget creation (`"POSTED"` vs `'POSTED'`), audit all raw SQL queries (`customSelect`, `customUpdate`, `customStatement`).
- R4: Query optimization (`currentMonthlyBudgetSummaryProvider` single aggregated JOIN GROUP BY, `reportsSummaryProvider` bounded queries). R8 code & resource shrinking in `android/app/build.gradle` and `proguard-rules.pro`. Release split-per-ABI build script and `Launch_DongTien_Emulator.bat`.

## Inputs
- Authoritative request: `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (specifically ## 2026-10-28T00:39:16Z § R3 and § R4)
- Project rules: `c:\Users\coihu12\Documents\App\AGENTS.md`
- Target code areas:
  - `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
  - `lib/features/reports_settings/presentation/providers/reports_providers.dart`
  - All occurrences of `customSelect`, `customUpdate`, `customStatement` in `lib/core/database/` and elsewhere
  - `android/app/build.gradle`, `android/app/proguard-rules.pro`
  - `Launch_DongTien_Emulator.bat`

## Deliverables
Write your comprehensive investigation report to:
`c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\report.md`
and write your `handoff.md`.
Identify all affected files, line numbers, current queries vs optimized queries, build.gradle configuration, and exact implementation recommendations.

## 2026-10-28T00:43:46Z
[Message] timestamp=2026-10-28T00:43:46Z sender=e84dfd06-a5ff-437b-948f-883d103ebdc9 priority=MESSAGE_PRIORITY_HIGH content=You are explorer_survey_3.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\
Read your dispatch instructions in: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\DISPATCH.md
Read the authoritative user request in: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md (under ## 2026-10-28T00:39:16Z § R3 and § R4)
Read the system invariants in: c:\Users\coihu12\Documents\App\AGENTS.md

Your task is to thoroughly survey and investigate the codebase for Requirements R3 and R4:
1. R3: Fix SqliteException(1) in currentMonthlyBudgetSummaryProvider (lib/features/dashboard/presentation/providers/dashboard_providers.dart) where double quotes "POSTED" are used.
   - Audit ALL raw SQL queries across the entire codebase (customSelect, customUpdate, customStatement) for double quotes vs single quotes.
2. R4 (Database):
   - In currentMonthlyBudgetSummaryProvider: replace N+1 query loop with a single aggregated SQLite JOIN ... GROUP BY query.
   - In reportsSummaryProvider: replace full-table db.select(db.journalPostings).get() memory load with bounded SQLite queries.
3. R4 (Android build & scripts):
   - Configure android/app/build.gradle and android/app/proguard-rules.pro with R8 code shrinking (minifyEnabled true) and resource shrinking (shrinkResources true).
   - Check release APK build command: flutter build apk --release --split-per-abi --tree-shake-icons.
   - Inspect Launch_DongTien_Emulator.bat and how to update it.
   - Inspect adb install command for DongTien_Pixel_API34 emulator.

Write your findings to: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\report.md
Write your handoff to: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\handoff.md
Send a completion message back to orchestrator_2 when finished.
