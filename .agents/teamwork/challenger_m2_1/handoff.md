# Handoff Report — challenger_m2_1

**Milestone**: M2 (Double-Entry General Ledger & Envelope Decoupling Adversarial Audit)  
**Role**: Empirical Challenger (`critic`, `specialist`)  
**Verdict**: **REQUEST_CHANGES**  

---

## 1. Observation

### 1.1 Empirical Verification Commands and Results
- Test execution:
  ```powershell
  & C:\Users\coihu12\flutter\bin\flutter.bat test test/database/adversarial_ledger_envelope_test.dart
  ```
  Result: **29 passed, 0 failed** in 4.0s.
- Entire project test suite:
  ```powershell
  & C:\Users\coihu12\flutter\bin\flutter.bat test
  ```
  Result: **249 passed, 0 failed** in 7.0s.
- Static analysis:
  ```powershell
  & C:\Users\coihu12\flutter\bin\flutter.bat analyze
  ```
  Result: **No issues found!** (0 errors, 0 warnings, 0 lints).
- Code formatting:
  ```powershell
  & C:\Users\coihu12\flutter\bin\cache\dart-sdk\bin\dart.exe format --output=none --set-exit-if-changed test/database/adversarial_ledger_envelope_test.dart
  ```
  Result: **0 changed (cleanly formatted)**.

---

### 1.2 Direct Code Observations & Invariant Findings

#### Finding 1 (HIGH): Missing Envelope Spending Deficit Guard in `LedgerDao.postTransaction`
- **Location**: `c:\Users\coihu12\Documents\App\lib\core\database\daos\ledger_dao.dart:134-151`:
  ```dart
  if (envelopeMovementType == 'SPEND') {
    await into(envelopeMovements).insert(
      EnvelopeMovementsCompanion.insert(
        movementType: 'SPEND',
        amountVnd: movementAmount,
        sourceEnvelopeId: Value(linkedEnvelopeId),
        linkedTransactionId: Value(txId),
        occurredAt: occurredAt,
      ),
    );
    await customUpdate(
      'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
      variables: [
        Variable.withInt(movementAmount),
        Variable.withInt(linkedEnvelopeId),
      ],
      updates: {envelopes},
    );
  }
  ```
- **Specification Mandate**:
  - `docs/ARCHITECTURE_AND_RULES.md:126`:
    > "Invariant: If `amount_vnd > envelope.reserved_balance_vnd`, transaction is blocked unless `allow_negative_exception == true` is explicitly confirmed by the user."
  - `docs/ARCHITECTURE_AND_RULES.md:238-244` (Section 5.3):
    > "When an expense specifies a linked `envelope_id`:
    > - If `amount_vnd <= envelope.reserved_balance_vnd`: Allowed.
    > - If `amount_vnd > envelope.reserved_balance_vnd`:
    >   - If `envelope.allow_negative_exception == false`: Blocked by default."
  - `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md:34`:
    > "Block over-allocation and block envelope overspending unless `allow_negative_exception == true` is confirmed."
- **Empirical Demonstration**:
  - Test 4.7 in `test/database/adversarial_ledger_envelope_test.dart`:
    An envelope with `reserved_balance_vnd = 100.000 ₫` and `allow_negative_exception = false` had an expense of `500.000 ₫` posted against it.
    `LedgerDao.postTransaction` accepted the transaction without error and decremented the envelope reserve to `-400.000 ₫`, completely bypassing `AvailableToAllocateCalculator.validateSpending`.

#### Finding 2 (MEDIUM): `LedgerDao.voidTransaction` Permits Voiding Audit `REVERSAL` Transactions
- **Location**: `c:\Users\coihu12\Documents\App\lib\core\database\daos\ledger_dao.dart:205-209`:
  ```dart
  if (target.status != 'POSTED') {
    throw InvalidTransactionException(
      'Cannot void transaction in status "${target.status}". Only POSTED transactions can be voided.',
    );
  }
  ```
- **Specification Mandate**:
  - `docs/ARCHITECTURE_AND_RULES.md:65`:
    > "Audit Reversal: Inverts target credit accounts and debit accounts... Clean UI queries filter `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`."
- **Empirical Demonstration**:
  - Test 5.5 in `test/database/adversarial_ledger_envelope_test.dart`:
    Because a reversal transaction has `status == 'POSTED'`, calling `db.ledgerDao.voidTransaction(reversalTxId)` succeeds, marks the reversal as `VOIDED`, and inserts a "reversal of a reversal" transaction. An audit reversal should be structurally immutable and non-voidable at the DAO boundary.

---

### 1.3 Verified Robust Invariants

1. **Unbalanced Transaction Rejection & Rollback**:
   - `PostingMatrix.assertBalanced` immediately rejects empty postings, single-sided postings, 1 VND discrepancies, and multi-leg imbalances with `UnbalancedTransactionException` (Tests 1.1 - 1.4).
   - Calling `db.ledgerDao.postTransaction` with unbalanced legs aborts before database writes, writing 0 records (Test 1.5).
   - Foreign key constraint violations (e.g. non-existent account ID) trigger SQLite atomic rollback, writing 0 uncommitted records to `journal_transactions` or `journal_postings` (Test 1.6).
   - Calling `db.ledgerDao.editTransaction` with unbalanced replacement legs aborts atomically, preserving original transaction `status = 'POSTED'`, `replaced_by_tx_id = null`, and creating 0 reversal records (Test 1.7).
2. **Credit Card Payment Accounting Isolation**:
   - `PostingMatrix.buildCreditCardPayment` generates strictly Debit `creditCardAccountId`, Credit `sourceAssetAccountId`. Zero legs touch `EXPENSE` (account ID 3) or `INCOME` (account ID 2), with `categoryId = null` and `envelopeId = null` (Test 2.1).
   - Settle card balance leaves operating expense, income, and net worth strictly invariant (Test 2.2).
   - Same account for card and source throws `InvalidTransactionException` (Test 2.3).
   - Overpayment creates negative credit card liability (surplus) without touching expense (Test 2.4).
   - Voiding card payment cleanly inverts card liability and liquid assets without touching expense (Test 2.5).
3. **Envelope Decoupling from General Ledger**:
   - `allocate`, `release`, and `transfer` generate strictly ZERO rows in `journal_postings` and `journal_transactions` (Test 3.1).
   - Liquid assets, net worth, operating expense, and income remain strictly invariant during envelope movements (Test 3.1).
4. **Envelope Boundary Guards in EnvelopeDao**:
   - Allocating `available + 1 ₫` throws `OverAllocationException` and rolls back (Test 4.1).
   - Allocating when `available < 0` (cash deficit) throws `OverAllocationException` (Test 4.2).
   - Allocation/release amounts `<= 0` throw `ArgumentError` (Test 4.3).
   - Self-transfers (`from == to`) throw `InvalidEnvelopeOperationException` (Test 4.4).
   - Envelope release & transfer block deficits when `allowNegativeException == false` with `SpendingDeficitException` (Test 4.5), and allow deficits when `allowNegativeException == true` (Test 4.6).
5. **Audit Preservation & State Transition Chains**:
   - Voiding non-existent, already-voided, or already-superseded transactions throws `InvalidTransactionException` (Tests 5.1, 5.2, 5.3).
   - Sequential edit chain $T_1 \to T_2 \to T_3 \to T_4$: accurately updates `SUPERSEDED` and `replaced_by_tx_id` links, inserts offsetting `REVERSAL` transactions, computes exact net balance of $T_4$, and `getCleanTransactions` exposes only $T_4$. Subsequent void of $T_4$ cleanly resets balances and removes all from clean views (Test 5.3).
   - Voiding an expense with linked envelope movement cleanly inserts a `REVERSAL` envelope movement and restores `reserved_balance_vnd` (Test 5.4).
6. **Extreme Boundaries & Idempotency**:
   - Boundary transactions at `VndMoney.maxSafeVnd` (9 quadrillion VND) succeed without 64-bit integer overflow (Test 6.1).
   - Posting legs with amounts `> 9 quadrillion VND` or `<= 0 VND` are rejected by `PostingLeg` factory with `ArgumentError` (Tests 6.2, 6.3).
   - Duplicate idempotency keys fail with `SqliteException` and abort insertion (Test 6.4).

---

## 2. Logic Chain

1. **Premise 1**: Section R3 of `ORIGINAL_REQUEST.md` and Section 5.3 of `ARCHITECTURE_AND_RULES.md` mandate that envelope overspending must be blocked by default unless `allow_negative_exception == true` is confirmed.
2. **Premise 2**: Observation 1.2 shows that `lib/core/database/daos/ledger_dao.dart:134-151` unconditionally updates `reserved_balance_vnd = reserved_balance_vnd - ?` without verifying the envelope's current balance or `allow_negative_exception` setting.
3. **Inference 1**: Any expense transaction submitted with `linkedEnvelopeId` can drive an envelope into an illegal negative state even when the user or envelope policy explicitly forbids negative balances.
4. **Premise 3**: Section 4.1 of `ARCHITECTURE_AND_RULES.md` specifies that `REVERSAL` transactions are immutable audit offsets.
5. **Premise 4**: Observation 1.2 shows that `LedgerDao.voidTransaction` checks only `target.status != 'POSTED'`. Because reversals are inserted with `status = 'POSTED'`, `voidTransaction` permits voiding reversals, leading to cyclic re-reversals.
6. **Inference 2**: `LedgerDao.voidTransaction` requires an explicit guard: `if (target.txType == 'REVERSAL') throw InvalidTransactionException('Cannot void a REVERSAL transaction.');`.
7. **Conclusion**: While double-entry balance arithmetic, credit card isolation, and envelope GL decoupling are 100% sound and verified, these two integrity gaps in `LedgerDao` require surgical remediation by the Core Architect.

---

## 3. Caveats

- **Multi-isolate Concurrency**: Drift runs in a single-isolate SQLite configuration on Android; concurrent multi-process database writes were not evaluated as the app runs in a single offline process sandbox.
- **UI Confirmation Hook**: In the full UI flow (Phase 3), if a user confirms an overspending exception for an envelope, either `allow_negative_exception` on the envelope is toggled to true or `postTransaction` should accept an optional `allowNegativeOverride: true` parameter.

---

## 4. Conclusion & Actionable Recommendations

### Verdict: **REQUEST_CHANGES**

### Actionable Remediation Recipe for Core Architect:

#### Action 1: Enforce Deficit Guard in `LedgerDao.postTransaction`
In `lib/core/database/daos/ledger_dao.dart`, inside `postTransaction` (before decrementing envelope balance):
```dart
if (linkedEnvelopeId != null && envelopeMovementType != null) {
  // 1. Fetch envelope to check balance and policy
  final targetEnv = await (select(envelopes)..where((e) => e.id.equals(linkedEnvelopeId))).getSingleOrNull();
  if (targetEnv == null) {
    throw InvalidTransactionException('Linked envelope $linkedEnvelopeId not found');
  }

  // 2. Validate spending deficit
  if (envelopeMovementType == 'SPEND') {
    AvailableToAllocateCalculator.validateSpending(
      spendAmountVnd: movementAmount,
      reservedBalanceVnd: targetEnv.reservedBalanceVnd,
      allowNegativeException: targetEnv.allowNegativeException,
      envelopeId: linkedEnvelopeId,
    );
  }
  ...
}
```

#### Action 2: Guard `LedgerDao.voidTransaction` Against Reversal Mutations
In `lib/core/database/daos/ledger_dao.dart`, inside `voidTransaction`:
```dart
if (target.txType == 'REVERSAL') {
  throw const InvalidTransactionException(
    'Cannot void a REVERSAL transaction. Reversals are immutable audit records.',
  );
}
```

---

## 5. Verification Method

To independently verify the adversarial findings and test suite:
1. Run adversarial test suite:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat test test/database/adversarial_ledger_envelope_test.dart
   ```
2. Run full test suite:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat test
   ```
3. Run static analyzer:
   ```powershell
   & C:\Users\coihu12\flutter\bin\flutter.bat analyze
   ```
4. Invalidation condition: If `test 4.7` in `test/database/adversarial_ledger_envelope_test.dart` is updated to expect `SpendingDeficitException` and fails, it proves that `LedgerDao.postTransaction` still lacks the envelope deficit guard.
