# Dispatch to worker_m1

## Identity & Scope
- **Agent Name**: `worker_m1`
- **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1\`
- **Milestone**: M1 (Database Bug Fixes & Query Optimization)
- **Features**:
  - F1: Fix `SqliteException(1)` by replacing `"POSTED"` with `'POSTED'` and adding `AND t.tx_type != 'REVERSAL'` in `currentMonthlyBudgetSummaryProvider`.
  - F2: Replace N+1 loop in `currentMonthlyBudgetSummaryProvider` with single aggregated SQLite `JOIN ... GROUP BY` query.
  - F3: Replace full-table `journal_postings` memory load in `reportsSummaryProvider` with 3 bounded SQLite queries.

## Exclusive File Ownership
- `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`

## Inputs & Survey Findings
Read the authoritative drop-in SQL queries and instructions in:
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\report.md` (§ 1 & § 2)
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\handoff.md`
- `c:\Users\coihu12\Documents\App\PROJECT.md`
- `c:\Users\coihu12\Documents\App\AGENTS.md`
- `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md`

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Environment Variables on this Machine
```powershell
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
```

## Verification Requirement
Run:
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
Document exact results in your `handoff.md` and send a completion message back to orchestrator_2.


## 2026-10-28T00:57:43Z
You are worker_m1.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1\
Read your dispatch instructions in: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1\DISPATCH.md
Read the authoritative user request in: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
Read the project specifications in: c:\Users\coihu12\Documents\App\PROJECT.md
Read the system invariants in: c:\Users\coihu12\Documents\App\AGENTS.md
Read the explorer findings and exact code blueprints in:
c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\report.md (§ 1 & § 2)

Your exclusive write files:
- lib/features/dashboard/presentation/providers/dashboard_providers.dart
- lib/features/reports_settings/presentation/providers/reports_settings_providers.dart

Mandatory Integrity Warning:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Tasks:
1. Implement the single aggregated SQLite JOIN ... GROUP BY query with single quotes 'POSTED' and 'REVERSAL' in currentMonthlyBudgetSummaryProvider (eliminating the N+1 loop and fixing SqliteException(1)).
2. Implement the 3 bounded SQLite queries in reportsSummaryProvider (eliminating the full-table scan of journal_postings).
3. Set the toolchain environment variables in PowerShell:
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
4. Run:
   dart format lib/features/dashboard/presentation/providers/dashboard_providers.dart lib/features/reports_settings/presentation/providers/reports_settings_providers.dart
   flutter analyze
   flutter test
5. Write your report and handoff.md, then send a message back to orchestrator_2.
