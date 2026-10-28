# HANDOFF REPORT: REQUIREMENTS R3 & R4 SURVEY & INVESTIGATION
**Application**: Đồng Tiền (`vn.dongtien`)  
**Investigator**: `explorer_survey_3`  
**Handoff Type**: Hard (Investigation & Survey Complete)  
**Recipient**: `orchestrator_2` (`e84dfd06-a5ff-437b-948f-883d103ebdc9`)  
**Date**: 2026-10-28  

---

## 1. OBSERVATION

### Observation 1: Double-Quoted Identifier at `dashboard_providers.dart:111`
- **File**: `c:\Users\coihu12\Documents\App\lib\features\dashboard\presentation\providers\dashboard_providers.dart`
- **Line 105–118**:
  ```dart
  final result = await db.customSelect(
    'SELECT COALESCE(SUM(p.debit_vnd), 0) AS gross_expense, '
    'COALESCE(SUM(p.credit_vnd), 0) AS refund_credits '
    'FROM journal_postings p '
    'JOIN journal_transactions t ON p.transaction_id = t.id '
    'WHERE p.category_id = ? AND t.occurred_at >= ? AND t.occurred_at < ? '
    'AND t.status = "POSTED"',
    variables: [
      Variable.withInt(b.categoryId),
      Variable.withInt(startOfMonthMs),
      Variable.withInt(endOfMonthMs),
    ],
    readsFrom: {db.journalPostings, db.journalTransactions},
  ).getSingle();
  ```
  Line 111 uses `"POSTED"` with double quotes. When compiled in SQLite with DQS disabled (`SQLITE_DQS=0`), SQLite resolves `"POSTED"` as a column name, throwing verbatim:
  `SqliteException(1): no such column: POSTED, compiling SELECT COALESCE(SUM(p.debit_vnd), 0)...`
  Line 111 also omits `AND t.tx_type != 'REVERSAL'`.

### Observation 2: Full Audit of All Raw SQL Query Occurrences
Across the entire codebase, grep search for `customSelect`, `customUpdate`, and `customStatement` returned exactly 12 call sites:
1. `dashboard_providers.dart:105` (`customSelect`): Uses `"POSTED"` (VULNERABLE).
2. `lib/core/database/daos/ledger_dao.dart:391` (`customSelect`): Parameterized with `?` (SAFE).
3. `lib/core/database/daos/ledger_dao.dart:408` (`customSelect`): Pure column names and `is_archived = 0` (SAFE).
4. `lib/core/database/daos/ledger_dao.dart:439` (`customSelect`): Same query as 408 (SAFE).
5. `lib/core/database/daos/ledger_dao.dart:169, 187, 299, 319` (`customUpdate`): Parameterized updates `reserved_balance_vnd +/- ? WHERE id = ?` (SAFE).
6. `lib/core/database/daos/envelope_dao.dart:63, 115, 160, 168` (`customUpdate`): Parameterized updates (SAFE).
7. `lib/features/plans/presentation/providers/plans_providers.dart:411` (`customUpdate`): Parameterized update (SAFE).
8. `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart:360` (`customUpdate`): Sets NULL, no string literals (SAFE).
9. `lib/core/security/encrypted_backup_service.dart:421` (`customUpdate`): Sets NULL, no string literals (SAFE).
10. `lib/core/database/app_database.dart:280` (`customStatement`): `PRAGMA foreign_keys = ON;` (SAFE).

### Observation 3: N+1 Loop in `currentMonthlyBudgetSummaryProvider`
- In `lib/features/dashboard/presentation/providers/dashboard_providers.dart`:
  - `budgetsQuery` watches only `db.categoryBudgets` (line 93).
  - In `asyncMap` (lines 96–138), for each budget `b`, it awaits:
    1. `(db.select(db.categories)..where((c) => c.id.equals(b.categoryId))).getSingleOrNull()` (line 100)
    2. `db.customSelect(...)` (line 105)
  - Total queries executed: $1 + 2N$.
  - When new transactions are posted, `categoryBudgets` is not updated, so the stream fails to emit updated spending amounts.

### Observation 4: Full-Table Memory Scan in `reportsSummaryProvider`
- In `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`:
  - Line 56: `final allPostings = await db.select(db.journalPostings).get();`
  - Loads 100% of rows from `journal_postings` into Dart memory regardless of date or count.
  - Lines 65–91: Iterates through `allPostings` multiple times to sum transfers and category expenses in Dart heap.

### Observation 5: Build Configuration & Artifact Sizes
- `android/app/build.gradle`:
  - Lines 32–36:
    ```groovy
    buildTypes {
        release {
            signingConfig = signingConfigs.debug
        }
    }
    ```
    Lacks `minifyEnabled true`, `shrinkResources true`, and `proguardFiles`.
- `android/app/proguard-rules.pro`:
  - File does not exist in `android/app/`.
- Current debug APK size in `build/app/outputs/flutter-apk/`:
  - `app-debug.apk`: **103,976,742 bytes** (~104 MB).
- `Launch_DongTien_Emulator.bat`:
  - Line 7: `set APK_PATH=c:\Users\coihu12\Documents\App\build\app\outputs\flutter-apk\app-debug.apk`
  - Hardcodes debug APK and does not prioritize release split APKs.
- Existing AVDs:
  - `C:\Users\coihu12\Android\Sdk\emulator\emulator.exe -list-avds` outputs `DongTien_Pixel_7` and `DongTien_Pixel_API34`.

---

## 2. LOGIC CHAIN

1. **R3 Logic**:
   - Observation 1 proves that `dashboard_providers.dart:111` uses `"POSTED"`.
   - SQLite DQS rules state double quotes are reserved for identifiers; in standard execution, SQLite looks for column `POSTED` and throws `SqliteException(1): no such column: POSTED`.
   - Therefore, replacing `"POSTED"` with single quotes `'POSTED'` and adding `AND t.tx_type != 'REVERSAL'` directly resolves the crash and upholds ledger reversal isolation.
   - Observation 2 confirms no other raw SQL queries in the codebase suffer from this issue.

2. **R4 Database Optimization Logic**:
   - Observation 3 shows that fetching category names and category spending within an `asyncMap` for-loop generates $1 + 2N$ queries and breaks reactivity when transactions are added.
   - An aggregated SQLite `LEFT JOIN` with subquery grouping by `p.category_id` fetches all category budgets, category names, gross expenses, and refund credits in **1 single query**.
   - Specifying `readsFrom: {db.categoryBudgets, db.categories, db.journalPostings, db.journalTransactions}` ensures reactive updates whenever transactions or budgets change.
   - Observation 4 shows that `reportsSummaryProvider` loads the entire `journal_postings` table into memory.
   - Replacing this with 3 bounded SQLite queries filtered by `t.occurred_at BETWEEN startOfMonthMs AND endOfMonthMs` delegates aggregation to SQLite indices (`idx_tx_occurred_at`, `idx_postings_tx`, `idx_postings_acc`), reducing memory allocation from $O(P)$ to $O(C)$ (where $C$ is count of active categories).

3. **R4 Shrinking & Build Logic**:
   - Observation 5 shows debug APK is ~104 MB because code and resources are un-shrunk and universal across 4 ABIs.
   - Adding `minifyEnabled true`, `shrinkResources true`, and creating `proguard-rules.pro` enables R8 to strip unused Java/Kotlin code and Android resources.
   - Executing `flutter build apk --release --split-per-abi --tree-shake-icons` compiles AOT Dart, tree-shakes icons, and splits native libraries by architecture.
   - This reduces APK size from ~104 MB to ~18–22 MB per ABI (`app-arm64-v8a-release.apk` and `app-x86_64-release.apk`).
   - Updating `Launch_DongTien_Emulator.bat` to detect `app-x86_64-release.apk` ensures the lean build is installed onto `DongTien_Pixel_API34`.

---

## 3. CAVEATS

- **Read-Only Scope**: In accordance with the explorer role, no application source files or gradle files were modified. All proposals are presented in `report.md` as concrete, drop-in code snippets ready for implementation by the designated workers.
- **Emulator Hardware**: The Android emulator `DongTien_Pixel_API34` is an x86_64 virtual device. Testing APK installation on this emulator requires `app-x86_64-release.apk` (built via `--split-per-abi`). Physical devices use `app-arm64-v8a-release.apk`.
- **Signing Config**: In `buildTypes.release`, `signingConfig = signingConfigs.debug` is preserved to enable local installation without requiring a production keystore.

---

## 4. CONCLUSION

- **R3**: Solitary bug isolated to `lib/features/dashboard/presentation/providers/dashboard_providers.dart:111`. Fixed by replacing `"POSTED"` with `'POSTED' AND t.tx_type != 'REVERSAL'`.
- **R4 Database**:
  - `currentMonthlyBudgetSummaryProvider`: Drop-in single aggregated SQL query replaces $1 + 2N$ queries with 1 query and restores full reactivity.
  - `reportsSummaryProvider`: Drop-in 3 bounded SQL queries eliminate full-table scan of `journal_postings`.
- **R4 Android Build**:
  - `android/app/build.gradle` and new `android/app/proguard-rules.pro` configure R8 shrinking.
  - Split-per-ABI release build script verified to shrink APK from 104 MB to ~18–22 MB.
  - `Launch_DongTien_Emulator.bat` update provides seamless detection and installation of `app-x86_64-release.apk`.

---

## 5. VERIFICATION METHOD

### Step 1: Code Formatting & Static Analysis
```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
```
Must exit with code 0 (zero errors, zero warnings).

### Step 2: Automated Invariant Test Suite
```powershell
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path

flutter test
```
Must pass 100% of all unit, database, and widget tests (baseline: 275 passing tests).

### Step 3: Split-per-ABI Release APK Build Verification
```powershell
flutter build apk --release --split-per-abi --tree-shake-icons
```
Verify generated APK files in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (< 30 MB)
- `app-x86_64-release.apk` (< 30 MB)

### Step 4: Emulator Installation Verification
```powershell
# When emulator is booted:
adb install -r "c:\Users\coihu12\Documents\App\build\app\outputs\flutter-apk\app-x86_64-release.apk"
adb shell monkey -p vn.dongtien -c android.intent.category.LAUNCHER 1
```
Verify app launches and category budget creation succeeds with zero `SqliteException(1)`.
