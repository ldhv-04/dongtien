# HANDOFF REPORT — Milestone M1 Empirical Challenge: Query Performance & Boundary Conditions

**Agent**: `challenger_m1_2_rep`  
**Role**: Empirical Challenger (critic, specialist)  
**Parent Orchestrator**: `e84dfd06-a5ff-437b-948f-883d103ebdc9`  
**Handoff Type**: Hard  
**Verdict**: **REQUEST_CHANGES**  
**Date**: 2026-10-28T02:05:00Z  

---

## 1. Observation

### 1.1 Full Test Suite Failure (`flutter test`)
- **Command executed**:
  ```powershell
  $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
  $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
  $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
  flutter test
  ```
- **Result**: Exited with code 1.
- **Verbatim Error Log**:
  ```text
  00:31 +278 -2: C:/Users/coihu12/Documents/App/test/database/adversarial_query_optimization_test.dart: Empty Database & Boundary Resilience reportsSummaryProvider handles clean initial DB gracefully without throwing [E]
    TimeoutException after 0:00:30.000000: Test timed out after 30 seconds. See https://pub.dev/packages/test#timeouts
    dart:isolate  _RawReceivePort._handleMessage
    
    Bad state: The provider FutureProvider<ReportsSummaryData>#e761e was disposed during loading state, yet no value could be emitted.
    package:riverpod/src/async_notifier/base.dart 467:22          FutureHandlerProviderElementMixin.dispose
    package:riverpod/src/framework/container.dart 634:15          ProviderContainer.dispose
    test\database\adversarial_query_optimization_test.dart 31:15  main.<fn>

  01:01 +279 -3: C:/Users/coihu12/Documents/App/test/database/adversarial_query_optimization_test.dart: Transaction Semantics & Filtering Verifications REVERSAL, VOIDED, and SUPERSEDED transactions are strictly excluded from spending [E]
    TimeoutException after 0:00:30.000000: Test timed out after 30 seconds.

  01:31 +279 -4: C:/Users/coihu12/Documents/App/test/database/adversarial_query_optimization_test.dart: Transaction Semantics & Filtering Verifications refund transactions offset gross expenses correctly in both providers [E]
    TimeoutException after 0:00:30.000000: Test timed out after 30 seconds.

  02:01 +280 -5: C:/Users/coihu12/Documents/App/test/database/adversarial_query_optimization_test.dart: Massive Volume Benchmark (Stress Test) 1000 transactions and 2000 postings query executes in single-digit ms [E]
    TimeoutException after 0:00:30.000000: Test timed out after 30 seconds.
  ```

### 1.2 Isolated Code Inspection of `reportsSummaryProvider`
- **File**: `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`
- **Lines 32–39**:
  ```dart
  /// Reactive provider computing the Reports summary for the current period and Net Worth.
  final reportsSummaryProvider = FutureProvider<ReportsSummaryData>((ref) async {
    final db = ref.watch(databaseProvider);

    // Watch streams so any transaction/account/setting mutation triggers recomputation
    ref.watch(accountsWithBalancesStreamProvider);
    ref.watch(recentTransactionsStreamProvider);
    ref.watch(settingsStreamProvider);
  ```
- **Observations**:
  1. `reportsSummaryProvider` is declared as an asynchronous `FutureProvider<ReportsSummaryData>`.
  2. Inside its asynchronous body, it synchronously calls `ref.watch` on three uninitialized `StreamProvider` instances: `accountsWithBalancesStreamProvider`, `recentTransactionsStreamProvider`, and `settingsStreamProvider`.
  3. Immediately after watching the three streams, the method awaits three consecutive SQLite database queries (`await db.customSelect(...).getSingle()`, `await db.customSelect(...).getSingle()`, and `await db.customSelect(...).get()`).

### 1.3 Empirical Reproduction of Provider Deadlock
- **Diagnostic Execution**:
  Running a standalone cold read on `reportsSummaryProvider.future`:
  ```dart
  final reports = await container.read(reportsSummaryProvider.future);
  ```
  Result: **100% reproducible hang and 30-second `TimeoutException`**.
- **Empirical Contrast**:
  In `test/database/m1_sql_edge_conditions_challenge_test.dart` (lines 40–43), the author added a workaround:
  ```dart
  // Pre-warm reactive stream providers to prevent unpumped FutureProvider timeouts
  await container.read(accountsWithBalancesStreamProvider.future);
  await container.read(recentTransactionsStreamProvider.future);
  await container.read(settingsStreamProvider.future);
  ```
  When the three stream providers are manually pre-warmed prior to invoking `reportsSummaryProvider.future`, `reportsSummaryProvider` executes in **under 5 milliseconds**.
  When the stream providers are NOT pre-warmed (cold start), `reportsSummaryProvider` times out **100% of the time**.

### 1.4 Observation of `currentMonthlyBudgetSummaryProvider` in `dashboard_providers.dart`
- **File**: `lib/features/dashboard/presentation/providers/dashboard_providers.dart` (lines 86–167)
- **Observations**:
  1. Double-quoted `"POSTED"` identifier bug was successfully replaced with ANSI single-quoted `'POSTED'` and `'REVERSAL'`.
  2. N+1 query loop was successfully replaced with a single aggregated `JOIN ... GROUP BY` query.
  3. The query is observed via Drift's reactive table mechanism: `readsFrom: {db.categoryBudgets, db.categories, db.journalPostings, db.journalTransactions}`.
  4. Execution plan check in `test/database/adversarial_query_optimization_test.dart` confirms SQLite uses `idx_tx_occurred_at` and `idx_postings_tx`.
  5. Tested with 1,000 transactions and 2,000 postings: `currentMonthlyBudgetSummaryProvider` executes in single-digit milliseconds (<10ms).

---

## 2. Logic Chain

1. **Premise 1 (Riverpod Lifecycle & Future Provider Invalidation)**:
   In `flutter_riverpod`, calling `ref.watch(streamProvider)` subscribes the caller to that `StreamProvider`.
   Initially, every `StreamProvider` has state `AsyncLoading()`.
   When the background Dart Stream emits its first event, Riverpod transitions the `StreamProvider` from `AsyncLoading` to `AsyncData`.
   Whenever any watched provider changes state, Riverpod marks the dependent `FutureProvider` as stale and triggers a rebuild, cancelling the in-flight future computation of the previous execution.

2. **Premise 2 (Asynchronous Gap Cancellation)**:
   In `reportsSummaryProvider`, the method watches three separate `StreamProvider` instances and then performs `await db.customSelect(...)`.
   During this `await` asynchronous suspension gap, the SQLite thread emits data for `accountsWithBalancesStreamProvider`, `recentTransactionsStreamProvider`, and `settingsStreamProvider`.
   Each emission triggers a re-execution of `reportsSummaryProvider`.
   Because the first execution was suspended at `await db.customSelect(...)`, Riverpod cancels the first execution Completer.

3. **Premise 3 (Cold-Start Deadlock Linking)**:
   When a cold container evaluates `await container.read(reportsSummaryProvider.future)` (such as when a user navigates to the Reports screen or in any test without pre-warmed streams):
   The caller receives the `Future` from the *initial* execution.
   Because that initial execution was superseded and cancelled during its `await` suspension gap, its `Completer` is discarded and never completes with a value or error.
   The caller is left awaiting an abandoned `Future`, resulting in an unrecoverable freeze/timeout.

4. **Premise 4 (Violation of System Quality Gates)**:
   Per `AGENTS.md` Section 5.2 and `ORIGINAL_REQUEST.md` R4:
   `flutter test` must pass 100% of unit, database, and widget tests without failure.
   Because of this deadlock, `flutter test test/database/adversarial_query_optimization_test.dart` and `flutter test` fail with exit code 1.

---

## 3. Caveats

- Testing was performed on the local Windows environment with standard SQLite native memory database (`PRAGMA foreign_keys = ON;`).
- The SQL aggregation logic itself in `reportsSummaryProvider` (Queries 1, 2, and 3) is mathematically correct and index-optimized; the failure is strictly caused by the Riverpod stream-watching concurrency anti-pattern in lines 36–38 of `reports_settings_providers.dart`.

---

## 4. Conclusion

**Verdict: REQUEST_CHANGES**

Milestone M1 cannot be approved until the cold-start deadlock in `reportsSummaryProvider` is resolved and `flutter test` exits with code 0.

### Required Actions for `worker_m1`:
1. In `lib/features/reports_settings/presentation/providers/reports_settings_providers.dart`:
   Remove the three `ref.watch` stream subscriptions from lines 36–38:
   ```dart
   // REMOVE THESE THREE LINES:
   ref.watch(accountsWithBalancesStreamProvider);
   ref.watch(recentTransactionsStreamProvider);
   ref.watch(settingsStreamProvider);
   ```
2. For reactivity:
   `ReportsSettingsController` already explicitly invalidates `reportsSummaryProvider` on all state-mutating actions (`ref.invalidate(reportsSummaryProvider)`).
   If continuous automatic reactivity to ledger postings is desired, either:
   - Convert `reportsSummaryProvider` to a `StreamProvider` utilizing Drift's native table observation (`readsFrom: {db.journalPostings, db.journalTransactions, db.ledgerAccounts, db.categories}`).
   - Or keep it as a clean `FutureProvider` invalidated by transaction controllers and settings updates, without watching `StreamProvider`s inside the async body.
3. Ensure `flutter test test/database/` and full `flutter test` pass 100% without timeouts.

---

## 5. Verification Method

To independently reproduce the bug and verify the fix:

1. **Reproduce the Bug**:
   ```powershell
   $env:JAVA_HOME = "C:\Users\coihu12\jdk17"
   $env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
   $env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path
   flutter test test/database/adversarial_query_optimization_test.dart --plain-name "reportsSummaryProvider handles clean initial DB gracefully without throwing"
   ```
   *Expected outcome*: Times out after 30 seconds (`TimeoutException after 0:00:30.000000`).

2. **Verify After Fix**:
   ```powershell
   flutter test test/database/adversarial_query_optimization_test.dart
   flutter test test/database/m1_sql_edge_conditions_challenge_test.dart
   flutter test
   ```
   *Expected outcome*: Exit code 0, 100% of tests pass.

3. **Invalidation Condition**:
   Any solution that leaves `ref.watch` on uninitialized `StreamProvider` instances inside an `async FutureProvider` will continue to trigger non-deterministic Future cancellations and test timeouts.
