## 2026-10-28T18:38:27Z
You are the Project Orchestrator for the Đồng Tiền (vn.dongtien) project.
Your assigned working directory is: `c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_3`.
All your plans, progress logs, and handoff reports must be written strictly inside your working directory (`plan.md`, `progress.md`, `BRIEFING.md`, `handoff.md`).

Read and strictly execute the user's latest request in `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` under section `## 2026-10-28T18:36:33Z`.
Strictly follow and enforce all architectural invariants and agent rules in `c:\Users\coihu12\Documents\App\AGENTS.md`.

When executing any Flutter, Dart, Gradle, or ADB commands in powershell, always set:
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path

Key Tasks:
1. R1: Explicit Category Selection & Isolation for Scheduled Obligations (`Hoá đơn & Thu nhập`) vs. Category Budgets (`Ngân sách`) & Envelopes (`Quỹ tiền`) — Option B.
2. R2: Full Edit (`Sửa`) & Delete (`Xóa`) Support Across All Widgets on Financial Plans (`Kế hoạch tài chính`) Screen (Category Budgets, Savings Goals, and Scheduled Items including atomic ledger reversal on paid/received items).
3. R3: Synchronize Monthly Cycle Start Day (`periodStartDay`) across Dashboard, Plans, Notifications, and Reports using pure domain `BillingCycleCalculator`.
4. R4: Full verification with automated tests (`dart format`, `flutter analyze`, `flutter test`), and build updated split-per-ABI release APKs (`flutter build apk --release --split-per-abi --tree-shake-icons`).
