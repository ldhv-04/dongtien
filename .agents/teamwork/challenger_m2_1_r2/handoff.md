# Handoff Report — challenger_m2_1_r2

- **Milestone**: Milestone 2 Review (Round 2)
- **Role**: critic, specialist (Empirical Challenger)
- **Working Directory**: `c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m2_1_r2`
- **Date**: 2026-10-27T19:40:00Z
- **Verdict**: **APPROVE**

---

## 1. Observation

### 1.1 Direct Tool Execution Results

1. **Targeted Adversarial Test Suite**:
   Command: `& C:\Users\coihu12\flutter\bin\flutter.bat test test/database/adversarial_ledger_envelope_test.dart`
   Result:
   ```text
   00:00 +29: All tests passed!
   Exit code: 0
   ```
   Directly confirms Test 4.7 (`LedgerDao.postTransaction with linkedEnvelopeId and SPEND enforces envelope deficit guard when allowNegativeException is false`) and Test 5.5 (`LedgerDao.voidTransaction rejects voiding a REVERSAL transaction`).

2. **Remediation Regression Tests**:
   Command: `& C:\Users\coihu12\flutter\bin\flutter.bat test test/database/ledger_service_test.dart test/unit/recurrence_test.dart`
   Result:
   ```text
   00:00 +22: All tests passed!
   Exit code: 0
   ```
   Directly confirms envelope missing check, envelope deficit check, voiding reversal rejection, and null-anchor recurrence preservation.

3. **Full Automated Test Suite**:
   Command: `& C:\Users\coihu12\flutter\bin\flutter.bat test`
   Result:
   ```text
   00:03 +253: All tests passed!
   Exit code: 0
   ```

4. **Static Analysis**:
   Command: `& C:\Users\coihu12\flutter\bin\flutter.bat analyze`
   Result:
   ```text
   Analyzing App...
   No issues found! (ran in 1.2s)
   Exit code: 0
   ```

5. **Code Formatting Check**:
   Command: `& C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed .`
   Result:
   ```text
   Formatted 41 files (0 changed) in 1.04 seconds.
   Exit code: 0
   ```

6. **Layer Isolation Invariant**:
   Query: `import ['"]package:(flutter|drift|flutter_riverpod)` in `lib/domain/`
   Result: `No results found` (Zero prohibited imports across all pure domain files).

7. **Empirical Challenger Probe Stress Suite**:
   Executed a dedicated temporary adversarial probe test (`test/database/adversarial_r2_probe_test.dart`) exercising:
   - Spending exact envelope balance (`100.000 ₫` on `100.000 ₫`) with `allowNegativeException = false` -> Succeeded, envelope reserve became `0 ₫`.
   - Spending `1 ₫` over reserve (`100.001 ₫` on `100.000 ₫`) with `allowNegativeException = false` -> Threw `SpendingDeficitException(requestedVnd: 100001, currentReservedVnd: 100000)`, database transaction aborted atomically, envelope reserve remained `100.000 ₫`, zero movements inserted.
   - Spending `1 ₫` over reserve with `allowNegativeException = true` -> Succeeded, envelope reserve became `-1 ₫`.
   - Direct `voidTransaction` on `REVERSAL` transaction -> Threw `InvalidTransactionException('Cannot void a REVERSAL transaction. Reversals are immutable audit records.')`, reversal status remained `POSTED`.
   - `editTransaction` on `REVERSAL` transaction -> Threw `InvalidTransactionException('Cannot void a REVERSAL transaction...')`, reversal status remained `POSTED`.
   - 12-month monthly recurrence starting Jan 31 with `anchorDayOfMonth: null` across short months (Feb 28, Apr 30, Jun 30, Sep 30, Nov 30) -> Correctly restored to day 31 on all 31-day months (Jan 31, Mar 31, May 31, Jul 31, Aug 31, Oct 31, Dec 31, Jan 31 2027) without drift.
   - Leap year (2024) monthly recurrence from Jan 31 with `anchorDayOfMonth: null` -> Jan 31 -> Feb 29 -> Mar 31.
   Result: `00:00 +9: All tests passed! Exit code: 0`.

---

### 1.2 Verbatim Code Inspection

#### 1. Envelope Deficit Check in `lib/core/database/daos/ledger_dao.dart` (Lines 87-124)
```dart
      // 2. Validate Linked Envelope & Deficit if SPEND
      int movementAmount = 0;
      if (linkedEnvelopeId != null && envelopeMovementType != null) {
        // Calculate the movement amount from postings
        for (final leg in postings) {
          if (leg.envelopeId == linkedEnvelopeId) {
            movementAmount += leg.debitVnd > 0 ? leg.debitVnd : leg.creditVnd;
          }
        }
        if (movementAmount == 0) {
          movementAmount = postings.fold<int>(
            0,
            (max, leg) => leg.debitVnd > max
                ? leg.debitVnd
                : (leg.creditVnd > max ? leg.creditVnd : max),
          );
        }

        if (envelopeMovementType == 'SPEND') {
          final targetEnv = await (select(envelopes)
                ..where((e) => e.id.equals(linkedEnvelopeId)))
              .getSingleOrNull();
          if (targetEnv == null) {
            throw InvalidTransactionException(
              'Linked envelope $linkedEnvelopeId not found',
            );
          }

          if (movementAmount > 0) {
            AvailableToAllocateCalculator.validateSpending(
              spendAmountVnd: movementAmount,
              reservedBalanceVnd: targetEnv.reservedBalanceVnd,
              allowNegativeException: targetEnv.allowNegativeException,
              envelopeId: linkedEnvelopeId,
            );
          }
        }
      }
```

#### 2. Reversal Inviolability in `lib/core/database/daos/ledger_dao.dart` (Lines 234-238)
```dart
      if (target.txType == 'REVERSAL') {
        throw const InvalidTransactionException(
          'Cannot void a REVERSAL transaction. Reversals are immutable audit records.',
        );
      }
```

#### 3. Recurrence Anchor Preservation in `lib/domain/forecasting/recurrence_calculator.dart` (Lines 128-152)
```dart
    final int effectiveAnchor = anchorDayOfMonth ?? startDueDate.day;

    final List<DateTime> dates = [];
    DateTime current = startDueDate;
    int count = 0;

    final horizonEndOfDay = DateTime(
      horizonDate.year,
      horizonDate.month,
      horizonDate.day,
      23,
      59,
      59,
      999,
    );

    while (!current.isAfter(horizonEndOfDay) && count < maxOccurrences) {
      dates.add(current);
      count++;
      current = computeNextDueDate(
        currentDueDate: current,
        recurrence: recurrence,
        anchorDayOfMonth: effectiveAnchor,
      );
    }
```

---

## 2. Logic Chain

1. **Envelope Deficit Invariant (Section 5.3 ARCHITECTURE_AND_RULES.md)**:
   - Premise: When an expense transaction is posted with a linked envelope (`linkedEnvelopeId != null && envelopeMovementType == 'SPEND'`), spending beyond the envelope's current reserve must throw `SpendingDeficitException` unless `allowNegativeException == true`.
   - Observation: In `ledger_dao.dart` (lines 106-123), `targetEnv` is queried within the atomic SQLite transaction. If `movementAmount > targetEnv.reservedBalanceVnd` and `!targetEnv.allowNegativeException`, `validateSpending` throws `SpendingDeficitException`.
   - Inference: The exception triggers prior to inserting journal records, rolling back the database transaction completely. If `allowNegativeException == true`, validation passes and the envelope balance is decremented into negative territory as specified.

2. **Reversal Audit Invariant (Section 4.5 ARCHITECTURE_AND_RULES.md)**:
   - Premise: `REVERSAL` transactions are immutable offsetting audit records. Voiding or editing a reversal breaks double-entry reconciliation and creates duplicate offsetting postings.
   - Observation: In `ledger_dao.dart` (lines 234-238), `voidTransaction` asserts `target.txType != 'REVERSAL'`. Since `editTransaction` also calls `voidTransaction(originalTxId)` at line 352, reversals are protected from both void and edit operations.
   - Inference: Attempts to void or edit any `REVERSAL` transaction fail deterministically with `InvalidTransactionException`, ensuring the general ledger audit trail is immutable.

3. **Recurrence Anchor Invariant (Section 9.2 ARCHITECTURE_AND_RULES.md & Acceptance Scenario 15B)**:
   - Premise: When generating recurrence dates from a monthly schedule where `anchorDayOfMonth` is not explicitly set, the anchor must default to `startDueDate.day` and remain fixed across all future iterations.
   - Observation: In `recurrence_calculator.dart` (line 128), `effectiveAnchor = anchorDayOfMonth ?? startDueDate.day;` is pinned outside the while loop and passed to `computeNextDueDate(..., anchorDayOfMonth: effectiveAnchor)` in every cycle.
   - Inference: Even when February clamps to day 28 or 29, the next cycle retains `effectiveAnchor = 31`, producing March 31st and preserving drift-free recurrence across calendar boundaries.

4. **Conclusion**:
   - All 3 items are comprehensively resolved, verified by automated unit and database tests, confirmed through adversarial boundary probes, and exhibit zero regressions across all 253 project tests.

---

## 3. Caveats

No caveats. All investigated areas meet or exceed specifications.

---

## 4. Conclusion

**Verdict: APPROVE**

The Round 2 remediation implemented by `worker_m2_2` is verified to be complete, robust, and mathematically sound:
1. `LedgerDao.postTransaction` strictly enforces envelope deficit protection with `SpendingDeficitException` when `allowNegativeException = false` and permits deficit spending when `true`.
2. `LedgerDao.voidTransaction` and `editTransaction` strictly forbid mutating or voiding `REVERSAL` records with `InvalidTransactionException`.
3. `RecurrenceCalculator.generateRecurrenceDates` pins `startDueDate.day` when `anchorDayOfMonth == null`, guaranteeing drift-free recurrence across short months.
4. All 253 automated tests pass, `flutter analyze` reports zero issues, and `dart format` is 100% compliant.

Milestone 2 is ready to be locked and approved.

---

## 5. Verification Method

To independently reproduce this verification:
1. Run adversarial ledger and envelope tests:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat test test/database/adversarial_ledger_envelope_test.dart
   ```
2. Run targeted remediation tests:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat test test/database/ledger_service_test.dart test/unit/recurrence_test.dart
   ```
3. Run entire test suite:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat test
   ```
4. Run static analyzer:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat analyze
   ```
5. Check formatting:
   ```powershell
   & C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed .
   ```

Invalidation conditions:
- Any `SpendingDeficitException` failing to throw when posting an expense exceeding envelope balance with `allowNegativeException = false`.
- Any `voidTransaction` call on a transaction with `txType == 'REVERSAL'` succeeding instead of throwing `InvalidTransactionException`.
- Any monthly recurrence starting on Jan 31 with null anchor scheduling March on the 28th instead of March 31st.
