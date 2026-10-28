# Dispatch to worker_m4

## Identity & Scope
- **Agent Name**: `worker_m4`
- **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m4\`
- **Milestone**: M4 (Android R8 Code & Resource Shrinking, Lean Release Builds & Emulator Deployment — Requirement R4)

## Target Files
1. `android/app/build.gradle`
2. `android/app/proguard-rules.pro`
3. `Launch_DongTien_Emulator.bat`

## Inputs & Specifications
Read the authoritative blueprints in:
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\report.md` (§ 3)
- `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\handoff.md`
- `c:\Users\coihu12\Documents\App\PROJECT.md`
- `c:\Users\coihu12\Documents\App\AGENTS.md`
- `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md` (## 2026-10-28T00:39:16Z § R4)

## Mandatory Tasks
1. **R8 Configuration in `android/app/build.gradle`**:
   In `buildTypes { release { ... } }`:
   ```groovy
   signingConfig = signingConfigs.debug
   minifyEnabled true
   shrinkResources true
   proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
   ```
2. **Create `android/app/proguard-rules.pro`**:
   Write the complete ProGuard / R8 rules specified in `explorer_survey_3/report.md` (lines 452–490) keeping Flutter, SQLite JNI, LocalNotifications, Timezone, and plugins.
3. **Update `Launch_DongTien_Emulator.bat`**:
   Update `APK_PATH` to prioritize `app-x86_64-release.apk`, with fallbacks to `app-release.apk` and `app-debug.apk` (see `explorer_survey_3/report.md` lines 518–567).
4. **Build Split-per-ABI Release APKs**:
   Run with toolchain environment:
   ```powershell
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path

   flutter build apk --release --split-per-abi --tree-shake-icons
   ```
   Verify that output APKs in `build/app/outputs/flutter-apk/`:
   - `app-arm64-v8a-release.apk` is < 30 MB (expected ~18–22 MB).
   - `app-x86_64-release.apk` is < 30 MB (expected ~20–24 MB).
   - Document exact byte sizes in `handoff.md`.
5. **Emulator Check & ADB Install**:
   Run:
   ```powershell
   adb devices
   ```
   If `emulator-5554` or any device is connected, install the APK:
   ```powershell
   adb install -r "c:\Users\coihu12\Documents\App\build\app\outputs\flutter-apk\app-x86_64-release.apk"
   ```
   If no emulator is connected, document that adb checked and no emulator was running.
6. **Quality Gates**:
   Run:
   ```powershell
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   flutter test
   ```
7. Write `handoff.md` and message orchestrator_2.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work.


## 2026-10-28T03:20:16Z
[Message] timestamp=2026-10-28T03:20:16Z sender=e84dfd06-a5ff-437b-948f-883d103ebdc9 priority=MESSAGE_PRIORITY_HIGH content=You are worker_m4.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m4\
Read your dispatch instructions in: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m4\DISPATCH.md
Read the authoritative user request in: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md (## 2026-10-28T00:39:16Z § R4)
Read the explorer findings and exact code proposals in:
c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\report.md (§ 3)
Read the project specifications in: c:\Users\coihu12\Documents\App\PROJECT.md
Read the system invariants in: c:\Users\coihu12\Documents\App\AGENTS.md

Target files:
- android/app/build.gradle
- android/app/proguard-rules.pro
- Launch_DongTien_Emulator.bat

Mandatory Integrity Warning:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Tasks:
1. Configure R8 code & resource shrinking in android/app/build.gradle:
   minifyEnabled true
   shrinkResources true
   proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
2. Create android/app/proguard-rules.pro with full rules from explorer_survey_3/report.md.
3. Update Launch_DongTien_Emulator.bat to detect and install app-x86_64-release.apk with fallback.
4. Set toolchain:
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
5. Build release split APKs:
   flutter build apk --release --split-per-abi --tree-shake-icons
   Verify that output APKs in build/app/outputs/flutter-apk/ are < 30 MB each.
6. Check adb devices and install app-x86_64-release.apk if emulator is connected.
7. Run dart format, flutter analyze, and flutter test.
8. Write handoff.md and send message back to orchestrator_2.
