# Handoff Report — worker_m2_2

- **Milestone**: Milestone 2 Remediation (Deterministic Domain Engines, General Ledger & Recurrence Schedule)
- **Role**: implementer, qa, specialist
- **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m2_2`
- **Date**: 2026-10-27T19:33:00Z
- **Verdict**: **READY_FOR_HANDOFF**

---

## 1. Observation

### 1.1 Direct Tool Execution Results
1. **Full Automated Test Suite**:
   Command: `& C:\Users\coihu12\flutter\bin\flutter.bat test`
   Result:
   ```text
   00:03 +253: All tests passed!
   Exit code: 0
   ```
2. **Targeted Remediation Test Suite**:
   Command: `& C:\Users\coihu12\flutter\bin\flutter.bat test test/database/adversarial_ledger_envelope_test.dart test/database/ledger_service_test.dart test/unit/recurrence_test.dart`
   Result:
   ```text
   00:00 +51: All tests passed!
   Exit code: 0
   ```
3. **Static Analysis**:
   Command: `& C:\Users\coihu12\flutter\bin\flutter.bat analyze`
   Result:
   ```text
   Analyzing App...
   No issues found! (ran in 1.5s)
   Exit code: 0
   ```
4. **Dart Code Formatting**:
   Command: `& C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed .`
   Result:
   ```text
   Formatted 41 files (0 changed) in 0.97 seconds.
   Exit code: 0
   ```
5. **Clean Architecture Layer Isolation**:
   Grep query for `import ['"]package:(flutter|drift|flutter_riverpod)` in `lib/domain/`:
   Result: `No results found` (Zero prohibited imports across all files in `lib/domain/`).

---

### 1.2 Exact File Modifications

#### 1. `lib/core/database/daos/ledger_dao.dart`
- **Lines 1-5**: Imported `../../../domain/envelopes/available_to_allocate.dart`.
- **Lines 84-123 (`postTransaction`)**:
  - Extracted movement amount calculation and envelope validation prior to writing transaction records.
  - When `linkedEnvelopeId != null && envelopeMovementType == 'SPEND'`, queries the target envelope.
  - If envelope is missing, throws `InvalidTransactionException('Linked envelope $linkedEnvelopeId not found')`.
  - If `movementAmount > 0`, invokes `AvailableToAllocateCalculator.validateSpending(spendAmountVnd: movementAmount, reservedBalanceVnd: targetEnv.reservedBalanceVnd, allowNegativeException: targetEnv.allowNegativeException, envelopeId: linkedEnvelopeId)`.
  - Throws `SpendingDeficitException` if `movementAmount > targetEnv.reservedBalanceVnd` and `!targetEnv.allowNegativeException`.
- **Lines 237-246 (`voidTransaction`)**:
  - Added guard preventing voiding of reversal transactions:
    ```dart
    if (target.txType == 'REVERSAL') {
      throw const InvalidTransactionException(
        'Cannot void a REVERSAL transaction. Reversals are immutable audit records.',
      );
    }
    ```

#### 2. `lib/domain/forecasting/recurrence_calculator.dart`
- **Lines 123-149 (`generateRecurrenceDates`)**:
  - Computed `final int effectiveAnchor = anchorDayOfMonth ?? startDueDate.day;`.
  - Passed `anchorDayOfMonth: effectiveAnchor` into each iteration's `computeNextDueDate` call, preventing anchor degradation across short months (e.g. February).

#### 3. `test/database/adversarial_ledger_envelope_test.dart`
- **Lines 810-877 (Test 4.7)**:
  - Updated test 4.7 to assert that attempting to spend beyond envelope balance with `allowNegativeException = false` throws `SpendingDeficitException`.
  - Asserted that envelope reserved balance remains untouched (`100.000 ₫`).
  - Added contrasting assertion verifying that with `allowNegativeException = true`, spending beyond envelope balance succeeds and decrements into negative (`-400.000 ₫`).
- **Lines 1172-1209 (Test 5.5)**:
  - Updated test 5.5 to assert that `db.ledgerDao.voidTransaction(reversalTxId)` throws `InvalidTransactionException` with message `'Cannot void a REVERSAL transaction. Reversals are immutable audit records.'`.
  - Verified reversal record status remains `'POSTED'`.

#### 4. `test/database/ledger_service_test.dart`
- **Line 2**: Added import `package:dongtien/domain/envelopes/envelope_exceptions.dart`.
- **Lines 540-636**: Added three comprehensive database invariant tests:
  - `postTransaction with linked envelope not found throws InvalidTransactionException`.
  - `postTransaction SPEND exceeding envelope balance throws SpendingDeficitException when allowNegativeException is false`.
  - `voidTransaction on a REVERSAL transaction throws InvalidTransactionException`.

#### 5. `test/unit/recurrence_test.dart`
- **Lines 165-184**: Added test `generateRecurrenceDates pins startDueDate.day when anchorDayOfMonth is null` verifying that starting Jan 31 with `anchorDayOfMonth = null` generates Jan 31 -> Feb 28 -> Mar 31 -> Apr 30 -> May 31 without anchor degradation to day 28.

---

## 2. Logic Chain

1. **Premise 1**: Section 5.3 of `ARCHITECTURE_AND_RULES.md` and Section R3 of `ORIGINAL_REQUEST.md` specify that spending against an envelope with insufficient funds must be rejected by default unless `allow_negative_exception == true`.
2. **Observation 1**: Previously, `LedgerDao.postTransaction` decremented `reserved_balance_vnd` blindly without querying the envelope's current reserve or checking `allow_negative_exception`.
3. **Action 1**: Querying the target envelope in `postTransaction` prior to journal insertion and invoking `AvailableToAllocateCalculator.validateSpending` guarantees atomic pre-condition validation. If insufficient funds and exception not allowed, `SpendingDeficitException` is thrown before any database records are written, preserving full integrity.
4. **Premise 2**: In double-entry accounting and Section 4.5 of `ARCHITECTURE_AND_RULES.md`, `REVERSAL` transactions are immutable offsetting audit records. Voiding a reversal creates cyclic "reversals of reversals" and corrupts the audit trail.
5. **Observation 2**: Previously, `LedgerDao.voidTransaction` only verified `target.status != 'POSTED'`. Since reversals are posted with `status = 'POSTED'`, reversals were vulnerable to being voided.
6. **Action 2**: Adding an explicit check `if (target.txType == 'REVERSAL') throw const InvalidTransactionException(...)` guarantees reversals are structurally non-voidable.
7. **Premise 3**: In Section 9.2 of `ARCHITECTURE_AND_RULES.md`, calendar recurrence schedules must remain drift-free. If a monthly schedule starts on day 31 and `anchorDayOfMonth` is not explicitly provided, the schedule anchor must default to `startDueDate.day` and remain pinned for all subsequent occurrences.
8. **Observation 3**: Previously, `generateRecurrenceDates` passed `anchorDayOfMonth: anchorDayOfMonth` (which was null) to `computeNextDueDate`. On the second iteration (from Feb 28 to March), `computeNextDueDate` fell back to `currentDueDate.day` (28), permanently degrading the recurrence anchor to the 28th.
9. **Action 3**: Setting `final int effectiveAnchor = anchorDayOfMonth ?? startDueDate.day;` in `generateRecurrenceDates` guarantees the original starting day is preserved across all recurrence cycles.
10. **Conclusion**: All 3 gaps identified by challenger and reviewer are completely resolved, backed by rigorous tests, with zero regressions.

---

## 3. Caveats

No caveats. All changes are strictly within the assigned file ownership boundaries, 100% compliant with clean architecture, and verified by automated test suites.

---

## 4. Conclusion

The remediation is complete and verified:
- `lib/core/database/daos/ledger_dao.dart` validates linked envelopes and blocks deficit spending unless explicitly permitted, and protects audit reversals from voiding.
- `lib/domain/forecasting/recurrence_calculator.dart` preserves start date day-of-month anchor across recurring schedules when anchor day is null.
- Test suites (`adversarial_ledger_envelope_test.dart`, `ledger_service_test.dart`, `recurrence_test.dart`) thoroughly cover all remediated behaviors and edge cases.
- All 253 tests pass, static analysis has 0 warnings/errors, and formatting is completely clean.

---

## 5. Verification Method

To independently verify the changes:
1. Run full automated test suite:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat test
   ```
   Expected: `All tests passed!` (253 passed, 0 failed).

2. Run targeted test suite:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat test test/database/adversarial_ledger_envelope_test.dart test/database/ledger_service_test.dart test/unit/recurrence_test.dart
   ```
   Expected: `All tests passed!` (51 passed, 0 failed).

3. Run static analyzer:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat analyze
   ```
   Expected: `No issues found!`.

4. Run code formatter check:
   ```powershell
   & C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed .
   ```
   Expected: `0 changed`.

Invalidation conditions:
- Any `SpendingDeficitException` failing to throw when posting an expense exceeding envelope balance with `allowNegativeException = false`.
- Any `voidTransaction` call on a transaction with `txType == 'REVERSAL'` succeeding instead of throwing `InvalidTransactionException`.
- Any monthly recurrence starting on Jan 31 with null anchor scheduling March on the 28th instead of March 31st.
