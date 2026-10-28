## 2026-10-28T02:11:00Z
You are worker_m1_fix.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1_fix\
Read your dispatch instructions in: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1_fix\DISPATCH.md
Read the project specifications in: c:\Users\coihu12\Documents\App\PROJECT.md
Read the system invariants in: c:\Users\coihu12\Documents\App\AGENTS.md
Read the authoritative user request in: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md

Exclusive write file:
- lib/features/reports_settings/presentation/providers/reports_settings_providers.dart

Task:
1. In lib/features/reports_settings/presentation/providers/reports_settings_providers.dart inside reportsSummaryProvider (around lines 35-39), remove the 3 stream watch calls:
   ref.watch(accountsWithBalancesStreamProvider);
   ref.watch(recentTransactionsStreamProvider);
   ref.watch(settingsStreamProvider);
   Keep ref.watch(databaseProvider).
2. Set toolchain:
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
3. Run:
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   flutter test
4. Write handoff.md and report to orchestrator_2.

Mandatory Integrity Warning:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work.
