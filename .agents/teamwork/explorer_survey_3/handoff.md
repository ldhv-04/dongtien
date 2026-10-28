# Toolchain, Environment & Workspace Audit Report

**Agent**: `explorer_survey_3`  
**Role**: Toolchain & Environment Auditor  
**Milestone**: Phase 0 — Survey & Pre-Code Audit  
**Target Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\handoff.md`  
**Authoritative Sources**:  
- `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (R1, R2, Acceptance Criteria)
- `c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md` (§1, §2, §3, §4, §7, §8)

---

## 1. Observation

### 1.1 Toolchain & CLI Execution Results
The required audit commands were executed directly in PowerShell in the working directory `c:\Users\coihu12\Documents\App`:

```powershell
Write-Host "--- GIT ---"; git --version
Write-Host "--- FLUTTER ---"; flutter --version
Write-Host "--- DART ---"; dart --version
Write-Host "--- FLUTTER DOCTOR ---"; flutter doctor -v
Write-Host "--- ADB VERSION ---"; adb version
Write-Host "--- ADB DEVICES ---"; adb devices
Write-Host "--- JAVA ---"; java -version
```

**Verbatim Results**:
1. `git --version`:
   ```text
   git : The term 'git' is not recognized as the name of a cmdlet, function, script file, or operable program.
   CategoryInfo: ObjectNotFound: (git:String) [], CommandNotFoundException
   ```
2. `flutter --version`:
   ```text
   flutter : The term 'flutter' is not recognized as the name of a cmdlet, function, script file, or operable program.
   CategoryInfo: ObjectNotFound: (flutter:String) [], CommandNotFoundException
   ```
3. `dart --version`:
   ```text
   dart : The term 'dart' is not recognized as the name of a cmdlet, function, script file, or operable program.
   CategoryInfo: ObjectNotFound: (dart:String) [], CommandNotFoundException
   ```
4. `flutter doctor -v`:
   ```text
   flutter : The term 'flutter' is not recognized as the name of a cmdlet, function, script file, or operable program.
   CategoryInfo: ObjectNotFound: (flutter:String) [], CommandNotFoundException
   ```
5. `adb version`:
   ```text
   adb : The term 'adb' is not recognized as the name of a cmdlet, function, script file, or operable program.
   CategoryInfo: ObjectNotFound: (adb:String) [], CommandNotFoundException
   ```
6. `adb devices`:
   ```text
   adb : The term 'adb' is not recognized as the name of a cmdlet, function, script file, or operable program.
   CategoryInfo: ObjectNotFound: (adb:String) [], CommandNotFoundException
   ```
7. `java -version`:
   ```text
   java : The term 'java' is not recognized as the name of a cmdlet, function, script file, or operable program.
   CategoryInfo: ObjectNotFound: (java:String) [], CommandNotFoundException
   ```

### 1.2 System Environment, Registry & Tool Discovery
- **Host Operating System**: Windows 11 (Windows NT 10.0.26100 AMD64), 16 logical processor threads (`Intel64 Family 6 Model 141 Stepping 1`).
- **Disk Storage**: Drive `C:\` has `62.31 GB` free of `119.12 GB`. No secondary drives exist.
- **Active System & User PATH**:
  - `C:/Users/coihu12/.gemini/antigravity/bin`
  - `C:\Users\coihu12\AppData\Roaming\Antigravity\bin`
  - `C:\WINDOWS\system32`
  - `C:\WINDOWS`
  - `C:\WINDOWS\System32\Wbem`
  - `C:\WINDOWS\System32\WindowsPowerShell\v1.0\`
  - `C:\WINDOWS\System32\OpenSSH\`
  - `C:\Users\coihu12\AppData\Local\Microsoft\WindowsApps`
  - `C:\Users\coihu12\AppData\Local\Programs\Microsoft VS Code\bin`
  - `C:\Users\coihu12\AppData\Local\Programs\Microsoft VS Code\bin\copilot-shim`
  - `C:\Users\coihu12\AppData\Local\agy\bin`
- **Installed Software Registry (`HKLM` / `HKCU` Uninstall Keys)**:
  - Antigravity 2.26.0
  - Microsoft Visual Studio Code (User) 1.143.1
  - Microsoft Edge & WebView2 Runtime
  - Microsoft Copilot
  - NVIDIA Graphics Driver 555.97
  - Microsoft OneDrive
  *(No Git, Java JDK, Flutter SDK, Android Studio, or Android SDK present in registry)*.
- **Filesystem Depth Scan on Tool Locations**:
  - `C:\Users\coihu12\AppData\Local\Android`: Does NOT exist (`Test-Path` returned `False`).
  - `C:\Program Files\Android`: Does NOT exist.
  - `C:\Android`: Does NOT exist.
  - `C:\Program Files\Java`, `C:\Program Files\Eclipse Adoptium`: Does NOT exist.
  - `C:\Program Files\Git`, `C:\Git`: Does NOT exist.
  - `C:\flutter`, `C:\src\flutter`, `C:\tools\flutter`: Does NOT exist.
  - `wsl -l -v`: Windows Subsystem for Linux is not installed.
- **Package Manager**:
  - `winget --version`: `v1.29.380` (active, functioning, internet connected).
  - Available packages via winget: `Git.Git` (v2.56.0.3), `Microsoft.OpenJDK.17` (v17.0.21.1021), `Google.AndroidStudio` (v2026.2.1.8).

### 1.3 Workspace & Project Structure
Contents of `c:\Users\coihu12\Documents\App`:
```text
c:\Users\coihu12\Documents\App\
├── .agents/
│   └── teamwork/
│       ├── ORIGINAL_REQUEST.md      [12,006 bytes, authoritative initial request]
│       ├── orchestrator_1/
│       ├── sentinel_1/
│       ├── spec_miner_survey_1/     [handoff.md: 60,515 bytes financial invariant mining]
│       ├── spec_miner_survey_2/
│       └── explorer_survey_3/       [Audit files: DISPATCH.md, BRIEFING.md, progress.md]
├── build_spec/
│   └── dongtien_build_spec.md       [29,032 bytes, 299 lines authoritative spec]
└── docs/
    └── design_refs/
        ├── Spacing.png              [106,060 bytes]
        ├── Untitled.png             [106,396 bytes]
        ├── Untitled-1.png           [107,259 bytes]
        ├── Untitled-2.png           [135,675 bytes]
        ├── Untitled-3.png           [496,854 bytes]
        ├── budget.png               [776,860 bytes]
        ├── invest.png               [876,323 bytes]
        ├── savings.png              [529,907 bytes]
        └── wallet.png               [594,195 bytes]
```

---

## 2. Logic Chain

### 2.1 Toolchain Status Assessment
1. **Observation**: `git`, `flutter`, `dart`, `flutter doctor`, `adb`, and `java` all threw `CommandNotFoundException` when invoked directly.
2. **Observation**: Deep searches across standard directories (`C:\Program Files`, `AppData\Local\Android`, `C:\flutter`, etc.) and system uninstall registries showed no bundled or hidden installations of Git, Flutter, Dart, Java, or Android SDK.
3. **Inference**: The host machine is currently an unprovisioned Windows workstation for Flutter/Android compilation.
4. **Observation**: `winget` v1.29.380 is available and connected to the public repository. Disk space has 62.3 GB free.
5. **Deduction**: If toolchain provisioning is required, it can be executed cleanly without destructive commands using `winget` or direct ZIP extraction. When tools are provisioned or when code generation / linting is triggered, commands must be added to user PATH or called via full paths.

### 2.2 Project Scaffolding & Directory Invariants
1. **Observation**: The working directory is named `App`, but the project specification defines the application name as `DongTien` (`dongtien` package).
2. **Observation**: `build_spec/` and `docs/design_refs/` exist directly under `c:\Users\coihu12\Documents\App`.
3. **Deduction**: Running a standard `flutter create .` would default to package name `app` unless explicitly overridden. Furthermore, running Flutter scaffolding must preserve `build_spec/`, `docs/`, and `.agents/` without deletion or clobbering.
4. **Scaffolding Invariant**: The Flutter project scaffolding must be initialized with:
   ```powershell
   flutter create --project-name dongtien --org vn.dongtien --platforms android .
   ```
   Or constructed directly with exact file definitions (`pubspec.yaml`, `analysis_options.yaml`, `android/` directory layout with Android hardening).

### 2.3 Dependency Lockdown & Compatibility
1. **Observation**: Section 3 of `build_spec/dongtien_build_spec.md` specifies a strict whitelist of dependencies and explicitly forbids:
   - `uuid`
   - Chart libraries (e.g. `fl_chart`, `syncfusion_flutter_charts`)
   - `go_router`
   - `freezed`
   - `dio` / `http`
   - `firebase_*`
   - `flutter_secure_storage`
   - `sqlcipher`
2. **Deduction**:
   - `uuid` is forbidden because SQLite auto-increment integers (`int` PK) and deterministic epoch timestamps guarantee identity without third-party library churn.
   - External chart libraries are forbidden because custom Material 3 progress bars and `CustomPainter` canvas elements provide deterministic, zero-dependency visual rendering.
   - `go_router` is forbidden because an offline mobile app with 4 bottom tabs is cleanly and deterministically driven by `IndexedStack` + standard `Navigator`.
   - `freezed` is forbidden to eliminate `build_runner` code generation latency and runtime bottlenecks for domain models; domain models and `VndMoney` are handcrafted immutable Dart classes.
   - `dio`/`http` and `firebase_*` are forbidden to enforce 100% offline-first privacy with zero telemetry or network attack surfaces.
   - `flutter_secure_storage` is forbidden because settings live in SQLite and encrypted backup uses a user-supplied password via PBKDF2-HMAC-SHA256 and AES-256-GCM.
   - `sqlcipher` is forbidden because plain SQLite (`drift_flutter` + `sqlite3_flutter_libs`) guarantees zero native build failures on Android, while data-at-rest protection is enforced via Android's sandbox and authenticated encrypted backup exports.
3. **Synthesis**: `drift_dev` and `build_runner` are the **only** code generation dependencies allowed. Code generation is restricted solely to `app_database.g.dart` via:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### 2.4 Testing & Verification Protocol
1. **Observation**: Section 8 of `dongtien_build_spec.md` mandates 15 acceptance scenarios covering the full financial engine (Opening asset, salary, cash expense, internal transfer, envelope allocation, credit card spend/payment, refund, audit reversal/edit, duplicate submission guard, scheduled bills, negative Safe-to-Spend, encrypted backup/restore roundtrip, tampered backup rejection, notification permission denial & month-end recurrence).
2. **Inference**: Testing must be layered into distinct test targets:
   - `test/unit/`: Pure Dart tests for `VndMoney`, Safe-to-Spend arithmetic, ceiling division, cash-flow forecast, and `Isolate.run` PBKDF2/AES-GCM encryption.
   - `test/database/`: Drift in-memory tests (`NativeDatabase.memory()`) verifying `PRAGMA foreign_keys = ON;`, balanced transactions, 9 tables CRUD, reversals, and seed data.
   - `test/widget/`: UI widget tests for dashboard cards, keypad input, transaction filters, and virtual fund allocation.
   - `integration_test/`: Automated emulator/device flows executing the 15 acceptance scenarios end-to-end.
   - `maestro/`: Declarative YAML E2E flows.
3. **Synthesis**: The 4 mandatory verification commands from Section 8 must pass:
   - `dart format --output=none --set-exit-if-changed .`
   - `flutter analyze`
   - `flutter test --coverage`
   - `flutter build apk --debug`

---

## 3. Caveats

1. **Toolchain Absence**: The workstation currently lacks installed binaries for `git`, `flutter`, `dart`, `java`, and `adb`. Therefore, live compilation, linting, and APK builds cannot execute on this machine until the tools are provisioned or provided in the environment.
2. **Android Emulator**: No hardware emulator or connected Android device is active (`adb` is absent). While `test/unit/`, `test/database/`, and `test/widget/` can execute via standard Dart/Flutter test runners once installed, `integration_test` and `maestro` require an Android device or emulator.
3. **Scaffolding Protection**: Running `flutter create .` directly will generate template code; implementers must ensure that template generation does not overwrite pre-existing files in `docs/` or `build_spec/`.
4. **Maestro CLI**: Maestro is host-dependent. On Windows, if Maestro CLI is not easily installed or supported without WSL, Section 1 (§1.4) explicitly specifies: *"otherwise rely on integration_test on emulator and document the CLI status"*.

---

## 4. Conclusion

### 4.1 Environment & Toolchain Status Summary
| Tool | Expected Purpose | Detected Status | Remediation / Provisioning Command |
|---|---|---|---|
| `git` | Version control & repo sync | **Missing** (`CommandNotFoundException`) | `winget install --id Git.Git -e --source winget` |
| `java` / JDK | Android Gradle build toolchain | **Missing** (`CommandNotFoundException`) | `winget install --id Microsoft.OpenJDK.17 -e --source winget` |
| `flutter` | Flutter SDK & runtime | **Missing** (`CommandNotFoundException`) | Download & unpack Flutter stable to `C:\src\flutter`, add `bin` to PATH |
| `dart` | Dart SDK (bundled with Flutter) | **Missing** (`CommandNotFoundException`) | Provided automatically with Flutter SDK |
| `adb` / SDK | Android platform tools & device bridge | **Missing** (`CommandNotFoundException`) | `winget install --id Google.AndroidStudio -e --source winget` or cmdline-tools |
| `emulator` | Android virtual device runner | **Missing** | Android Studio AVD Manager |
| `winget` | Package manager CLI | **Available** (`v1.29.380`) | N/A (operational) |

### 4.2 Locked `pubspec.yaml` Specification
The following `pubspec.yaml` satisfies all requirements of Section 3 without forbidden packages:

```yaml
name: dongtien
description: "DongTien - Production-ready, offline-first personal finance application for Android."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management (Standard Notifier / AsyncNotifier)
  flutter_riverpod: ^2.5.1

  # Persistence & Type-safe SQLite
  drift: ^2.20.0
  drift_flutter: ^0.2.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

  # Scheduled Local Reminders & Timezone
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
  flutter_timezone: ^3.0.1

  # Localization & Formatting
  intl: ^0.19.0

  # Export & Import File Bridge
  share_plus: ^10.0.0
  file_picker: ^8.1.0

  # Authenticated Cryptography (PBKDF2-HMAC-SHA256, AES-256-GCM)
  cryptography: ^2.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.12
  drift_dev: ^2.20.0

flutter:
  uses-material-design: true
  assets:
    - docs/design_refs/
```

### 4.3 Forbidden Packages Compliance Matrix
| Package | Status | Rationale & Mandated Alternative |
|---|---|---|
| `uuid` | **STRICTLY FORBIDDEN** | Drift auto-increment `int` PKs and epoch millisecond identifiers provide deterministic keys without external bloat. |
| `fl_chart`, `charts_flutter`, etc. | **STRICTLY FORBIDDEN** | Custom Material 3 progress indicators and `CustomPainter` canvas widgets provide deterministic, zero-dependency visuals. |
| `go_router` | **STRICTLY FORBIDDEN** | Offline Android app with 4 bottom destinations uses clean `IndexedStack` + standard `Navigator`. |
| `freezed` | **STRICTLY FORBIDDEN** | Value objects (`VndMoney`, domain models) are handcrafted immutable Dart classes to avoid `build_runner` latency. |
| `dio` / `http` | **STRICTLY FORBIDDEN** | 100% offline-first architecture; zero network calls or external APIs. |
| `firebase_*` | **STRICTLY FORBIDDEN** | No cloud sync, telemetry, crash reporting, or external servers. |
| `flutter_secure_storage` | **STRICTLY FORBIDDEN** | Backup files are password-encrypted via PBKDF2-HMAC-SHA256 and AES-256-GCM; preferences live in SQLite `settings` table. |
| `sqlcipher` | **STRICTLY FORBIDDEN** | Standard SQLite via `drift_flutter` + `sqlite3_flutter_libs` avoids Android NDK build failures; backups are independently AES-GCM encrypted. |

### 4.4 Project Layout & File Scaffolding Plan
1. **Scaffolding Command**:
   ```powershell
   flutter create --project-name dongtien --org vn.dongtien --platforms android .
   ```
2. **Directory Tree**:
   ```text
   lib/
     app/
       app.dart                      # MaterialApp, vi_VN localization, routing shell
       theme/                        # Material 3 tokens, colors, typography, spacing
     core/
       database/                     # Drift tables, DAOs, migrations, database provider
       money/                        # VndMoney value type, arithmetic overflow guards, vi_VN formatter
       security/                     # Isolate-based AES-256-GCM + PBKDF2 backup encryption
       notifications/                # Low-risk inexact local reminder scheduler
       widgets/                      # Custom M3 progress bars, numeric keypad, dialogs
     domain/
       ledger/                       # Double-entry posting engine, balance derivation, reversal/edit
       envelopes/                    # Virtual fund allocations, spend linkages, Available-to-Allocate
       budgeting/                    # Category period budgets, savings goal ceiling math & feasibility
       forecasting/                  # Safe-to-Spend formula, month-end recurrence, cash flow forecast
     features/
       dashboard/                    # Tong quan screen & controllers
       transactions/                 # Giao dich CRUD, quick-add sheet, filters, audit trail
       accounts/                     # Cash, bank & credit card management
       envelopes/                    # Quy tien (protected & flexible envelopes)
       plans/                        # Ke hoach (budgets, goals, obligations, forecast)
       reports_settings/             # Reports, CSV export, encrypted backup/restore, settings
     main.dart
   test/
     unit/                           # Pure domain math, VndMoney, and cryptography tests
     database/                       # Drift in-memory transaction, FK, and restore tests
     widget/                         # M3 UI components & screen state tests
   integration_test/                 # 15 mandatory acceptance scenario tests
   maestro/                          # Declarative YAML E2E flows
   docs/
     ARCHITECTURE_AND_RULES.md       # High-density architecture spec
     DESIGN_AND_TEST_PLAN.md         # Design tokens & test plan
     design_refs/                    # Visual reference PNGs
   AGENTS.md                         # Sub-agent invariants & ownership rules
   README.md                         # Project overview & verification guide
   ```
3. **Android Security Hardening**:
   - `android/app/src/main/AndroidManifest.xml`:
     - Set `android:allowBackup="false"`
     - Declare ONLY:
       ```xml
       <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
       <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
       ```
     - Exclude `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`.
   - `android/app/src/main/res/xml/data_extraction_rules.xml`:
     ```xml
     <?xml version="1.0" encoding="utf-8"?>
     <data-extraction-rules>
         <cloud-backup>
             <exclude path="databases/" />
         </cloud-backup>
         <device-transfer>
             <exclude path="databases/" />
         </device-transfer>
     </data-extraction-rules>
     ```

---

## 5. Verification Method

To independently verify the findings in this audit:

1. **Verify Toolchain Commands**:
   Run the following command in PowerShell from the project root:
   ```powershell
   git --version; flutter --version; dart --version; flutter doctor -v; adb version; adb devices; java -version
   ```
   *Expected Result*: Returns `CommandNotFoundException` for all tools on the unprovisioned machine.
2. **Verify Workspace Contents**:
   Run:
   ```powershell
   Get-ChildItem -Path c:\Users\coihu12\Documents\App | Select-Object Name
   ```
   *Expected Result*: Confirms existence of `.agents`, `build_spec`, and `docs`.
3. **Verify Design Reference Files**:
   Run:
   ```powershell
   Get-ChildItem -Path c:\Users\coihu12\Documents\App\docs\design_refs | Select-Object Name, Length
   ```
   *Expected Result*: Confirms all 9 PNG assets are present.
4. **Verify Mandatory Quality Gate Commands**:
   Once Flutter and Dart are provisioned, run:
   ```bash
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   flutter test --coverage
   flutter build apk --debug
   ```
   *Pass Criteria*: All 4 commands exit with code 0.
