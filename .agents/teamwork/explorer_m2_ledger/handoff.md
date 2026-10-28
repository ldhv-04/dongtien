# M2 Ledger & Envelope Domain Implementation Blueprint

> **Agent**: `explorer_m2_ledger`  
> **Role**: Teamwork Explorer (Read-Only Investigation & Architectural Synthesis)  
> **Target Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_ledger\handoff.md`  
> **Scope**: Pure Dart Ledger Domain (`lib/domain/ledger/`), Envelope Domain (`lib/domain/envelopes/`), Drift DAOs (`lib/core/database/daos/`), Dynamic Balance Derivation, and Automated Test Plan (`test/unit/`, `test/database/`).

---

## 1. Observation

### 1.1 Existing Database Schema & Constraints
From direct inspection of `lib/core/database/app_database.dart`:
- **`LedgerAccounts`** (`lines 9–22`):
  - Check constraint: `CHECK (kind IN ('ASSET_CASH', 'ASSET_BANK', 'LIABILITY_CREDIT_CARD', 'INCOME', 'EXPENSE', 'EQUITY_OPENING'))`.
  - Attributes: `id` (PK), `name` (text), `kind` (text), `isLiquid` (bool, default `false`), `creditLimit` (int, default `0`), `isArchived` (bool, default `false`), `createdAt` (int).
  - Seeded accounts: `id: 1` (`EQUITY_OPENING`, "Vốn ban đầu"), `id: 2` (`INCOME`, "Thu nhập"), `id: 3` (`EXPENSE`, "Chi tiêu").
- **`Categories`** (`lines 27–42`):
  - Check constraint: `CHECK (kind IN ('INCOME', 'EXPENSE'))`.
  - Foreign key: `ledgerAccountId` references `LedgerAccounts.id` (`onDelete: KeyAction.restrict`).
  - Seeded categories: 2 income categories (linked to account 2) and 6 expense categories (linked to account 3).
- **`JournalTransactions`** (`lines 47–71`):
  - Check constraints:
    - `CHECK (tx_type IN ('OPENING_BALANCE', 'INCOME', 'EXPENSE', 'TRANSFER', 'CREDIT_CARD_PAYMENT', 'REFUND', 'REVERSAL'))`
    - `CHECK (status IN ('POSTED', 'SUPERSEDED', 'VOIDED'))`
  - Columns: `id` (PK auto-increment), `txType` (text), `status` (text default `'POSTED'`), `description` (text), `occurredAt` (int epoch ms), `createdAt` (int epoch ms), `idempotencyKey` (text unique nullable), `reversesTxId` (FK nullable -> `JournalTransactions.id`), `replacedByTxId` (FK nullable -> `JournalTransactions.id`).
- **`JournalPostings`** (`lines 76–99`):
  - Table constraint: `CONSTRAINT chk_posting_one_sided CHECK ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`.
  - Foreign keys: `transactionId` references `JournalTransactions.id` (`onDelete: KeyAction.cascade`), `accountId` references `LedgerAccounts.id` (`onDelete: KeyAction.restrict`), `categoryId` references `Categories.id` (`onDelete: KeyAction.setNull`), `envelopeId` references `Envelopes.id` (`onDelete: KeyAction.setNull`).
- **`Envelopes`** (`lines 104–124`):
  - Check constraint: `CHECK (policy IN ('PROTECTED', 'FLEXIBLE'))`.
  - Columns: `id` (PK), `name` (text), `policy` (text), `reservedBalanceVnd` (int default `0`), `allowNegativeException` (bool default `false`), `targetAmountVnd` (int nullable), `targetDateMs` (int nullable), `periodLimitVnd` (int nullable), `rolloverEnabled` (bool default `false`), `priority` (int default `1`), `isArchived` (bool default `false`).
- **`EnvelopeMovements`** (`lines 127–157`):
  - Check constraints:
    - `CHECK (amount_vnd > 0)`
    - `CHECK (movement_type IN ('ALLOCATE', 'RELEASE', 'TRANSFER', 'SPEND', 'REFUND_RESTORE', 'REVERSAL'))`
  - Foreign keys: `sourceEnvelopeId` references `Envelopes.id` (`onDelete: KeyAction.restrict`), `destEnvelopeId` references `Envelopes.id` (`onDelete: KeyAction.restrict`), `linkedTransactionId` references `JournalTransactions.id` (`onDelete: KeyAction.setNull`), `linkedObligationId` references `ScheduledItems.id` (`onDelete: KeyAction.setNull`).
- **`Settings`** (`lines 222–246`):
  - Singleton `id == 1`: `minimumCashBufferVnd` (int default `0`), `periodStartDay` (int default `1`), `dailyReminderHour` (int default `20`), `dailyReminderMinute` (int default `0`), `notificationsEnabled` (bool default `false`), `schemaVersion` (int default `1`).

### 1.2 Toolchain & Test Baseline
Direct tool execution:
- Flutter CLI located at `C:\Users\coihu12\flutter\bin\flutter.bat`.
- Executed `C:\Users\coihu12\flutter\bin\flutter.bat test`:
  ```text
  00:00 +124: All tests passed!
  ```
  All 124 existing unit and database tests pass without error.

### 1.3 Architectural Invariants & Clean Architecture Rules
From `AGENTS.md` and `docs/ARCHITECTURE_AND_RULES.md`:
1. `lib/domain/` must be pure Dart: zero imports from `package:flutter/*`, `package:drift/*`, or `package:flutter_riverpod/*`.
2. Monetary math is strictly 64-bit signed integer VND via `VndMoney` (`maxSafeVnd = 9_000_000_000_000_000`).
3. Immutable double-entry ledger equation: $\sum \text{debit\_vnd} == \sum \text{credit\_vnd}$ inside an atomic SQLite transaction (`db.transaction()`).
4. Zero cached balances on `ledger_accounts`. All balances derived dynamically across all postings.
5. Virtual funds (envelopes) decoupled: allocations never create general ledger postings.
6. Reversals/Voids never hard-delete: original transaction status updated to `VOIDED` or `SUPERSEDED`, and `REVERSAL` transaction inserted with inverted postings and offsetting envelope movements.
7. Clean UI filtering: transaction feeds query `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`.

---

## 2. Logic Chain

### 2.1 Domain Layer Decomposition & File Organization
To enforce pure Dart isolation and avoid file lock contention, domain models, value objects, exceptions, and engines are partitioned into clean, cohesive modules:

```text
lib/domain/
├── ledger/
│   ├── account_kind.dart              # AccountKind enum with classification helpers
│   ├── transaction_type.dart          # TransactionType enum matching SQLite CHECK
│   ├── transaction_status.dart        # TransactionStatus enum (POSTED, SUPERSEDED, VOIDED)
│   ├── posting_leg.dart               # Immutable single-sided posting leg value object
│   ├── posting_matrix.dart            # Pure Dart posting generation & validation engine
│   ├── ledger_exceptions.dart         # UnbalancedTransactionException, InvalidTransactionException
│   └── post_transaction_command.dart # Type-safe input commands for each transaction kind
└── envelopes/
    ├── envelope_policy.dart           # EnvelopePolicy enum (PROTECTED, FLEXIBLE)
    ├── envelope_movement_type.dart    # EnvelopeMovementType enum (6 valid movement types)
    ├── envelope_exceptions.dart       # OverAllocationException, SpendingDeficitException
    └── available_to_allocate.dart     # Pure Dart Available-to-Allocate calculator
```

### 2.2 Ledger Domain Specification (`lib/domain/ledger/`)

#### 2.2.1 `AccountKind` (`account_kind.dart`)
```dart
enum AccountKind {
  assetCash('ASSET_CASH'),
  assetBank('ASSET_BANK'),
  liabilityCreditCard('LIABILITY_CREDIT_CARD'),
  income('INCOME'),
  expense('EXPENSE'),
  equityOpening('EQUITY_OPENING');

  final String dbValue;
  const AccountKind(this.dbValue);

  /// Liquid assets comprise physical cash and bank/e-wallet accounts.
  /// Credit cards are liabilities and strictly NOT liquid.
  bool get isLiquid => this == assetCash || this == assetBank;

  /// Normal balance convention:
  /// - Asset and Expense accounts have a Debit normal balance (debit - credit).
  /// - Liability, Income, and Equity accounts have a Credit normal balance (credit - debit).
  bool get isDebitNormal =>
      this == assetCash || this == assetBank || this == expense;

  bool get isCreditNormal =>
      this == liabilityCreditCard || this == income || this == equityOpening;

  static AccountKind fromDbValue(String value) {
    return AccountKind.values.firstWhere(
      (k) => k.dbValue == value,
      orElse: () => throw ArgumentError('Unknown AccountKind: $value'),
    );
  }
}
```

#### 2.2.2 `TransactionType` & `TransactionStatus`
```dart
enum TransactionType {
  openingBalance('OPENING_BALANCE'),
  income('INCOME'),
  expense('EXPENSE'),
  transfer('TRANSFER'),
  creditCardPayment('CREDIT_CARD_PAYMENT'),
  refund('REFUND'),
  reversal('REVERSAL');

  final String dbValue;
  const TransactionType(this.dbValue);

  static TransactionType fromDbValue(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => throw ArgumentError('Unknown TransactionType: $value'),
    );
  }
}

enum TransactionStatus {
  posted('POSTED'),
  superseded('SUPERSEDED'),
  voided('VOIDED');

  final String dbValue;
  const TransactionStatus(this.dbValue);

  static TransactionStatus fromDbValue(String value) {
    return TransactionStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => throw ArgumentError('Unknown TransactionStatus: $value'),
    );
  }
}
```

#### 2.2.3 `LedgerExceptions` (`ledger_exceptions.dart`)
```dart
class UnbalancedTransactionException implements Exception {
  final int totalDebit;
  final int totalCredit;
  final String message;

  const UnbalancedTransactionException({
    required this.totalDebit,
    required this.totalCredit,
    this.message = 'Transaction is unbalanced: sum(debit) != sum(credit)',
  });

  @override
  String toString() =>
      'UnbalancedTransactionException: $message (debit: $totalDebit, credit: $totalCredit)';
}

class InvalidTransactionException implements Exception {
  final String message;
  const InvalidTransactionException(this.message);

  @override
  String toString() => 'InvalidTransactionException: $message';
}

class AccountKindMismatchException implements Exception {
  final String message;
  const AccountKindMismatchException(this.message);

  @override
  String toString() => 'AccountKindMismatchException: $message';
}
```

#### 2.2.4 `PostingLeg` Value Object (`posting_leg.dart`)
```dart
class PostingLeg {
  final int accountId;
  final int debitVnd;
  final int creditVnd;
  final int? categoryId;
  final int? envelopeId;

  const PostingLeg._({
    required this.accountId,
    required this.debitVnd,
    required this.creditVnd,
    this.categoryId,
    this.envelopeId,
  });

  factory PostingLeg.debit({
    required int accountId,
    required int amountVnd,
    int? categoryId,
    int? envelopeId,
  }) {
    if (amountVnd <= 0) {
      throw ArgumentError.value(amountVnd, 'amountVnd', 'Debit amount must be > 0');
    }
    if (amountVnd > 9000000000000000) {
      throw ArgumentError('Amount exceeds max safe VND limit');
    }
    return PostingLeg._(
      accountId: accountId,
      debitVnd: amountVnd,
      creditVnd: 0,
      categoryId: categoryId,
      envelopeId: envelopeId,
    );
  }

  factory PostingLeg.credit({
    required int accountId,
    required int amountVnd,
    int? categoryId,
    int? envelopeId,
  }) {
    if (amountVnd <= 0) {
      throw ArgumentError.value(amountVnd, 'amountVnd', 'Credit amount must be > 0');
    }
    if (amountVnd > 9000000000000000) {
      throw ArgumentError('Amount exceeds max safe VND limit');
    }
    return PostingLeg._(
      accountId: accountId,
      debitVnd: 0,
      creditVnd: amountVnd,
      categoryId: categoryId,
      envelopeId: envelopeId,
    );
  }

  /// Inverts this posting leg for audit reversals.
  PostingLeg invert() {
    return PostingLeg._(
      accountId: accountId,
      debitVnd: creditVnd,
      creditVnd: debitVnd,
      categoryId: categoryId,
      envelopeId: envelopeId,
    );
  }
}
```

#### 2.2.5 The Exact Posting Matrix for All 7 Transaction Types (9 Execution Patterns)
The database defines 7 `tx_type` values (`OPENING_BALANCE`, `INCOME`, `EXPENSE`, `TRANSFER`, `CREDIT_CARD_PAYMENT`, `REFUND`, `REVERSAL`). In practice, `OPENING_BALANCE` has 2 subtypes (Asset vs Debt), and `EXPENSE` has 2 subtypes (Cash/Bank vs Credit Card), resulting in 9 deterministic execution patterns:

| Pattern # | Logical Operation | DB `tx_type` | Debit Leg (`debit_vnd > 0`) | Credit Leg (`credit_vnd > 0`) | Category Link | Envelope Movement | Economic Invariant Effect |
|---|---|---|---|---|---|---|---|
| **1** | Opening Asset Balance | `OPENING_BALANCE` | `ASSET_CASH` or `ASSET_BANK` | `EQUITY_OPENING` (ID 1) | `null` | None | Liquid asset = initial VND; operating income = 0 ₫. |
| **2** | Opening Card Debt Balance | `OPENING_BALANCE` | `EQUITY_OPENING` (ID 1) | `LIABILITY_CREDIT_CARD` | `null` | None | Card debt = initial VND; liquid assets = 0 ₫. |
| **3** | Operating Income | `INCOME` | `ASSET_CASH` or `ASSET_BANK` | `INCOME` (ID 2) | Category ID | None | Liquid assets increase; recognized income increases. |
| **4** | Cash / Bank Expense | `EXPENSE` | `EXPENSE` (ID 3) | `ASSET_CASH` or `ASSET_BANK` | Category ID | If `envelope_id != null`: `SPEND` movement | Liquid assets decrease; gross expense increases. |
| **5** | Credit Card Purchase | `EXPENSE` | `EXPENSE` (ID 3) | `LIABILITY_CREDIT_CARD` | Category ID | If `envelope_id != null`: `SPEND` movement | Liquid assets unchanged; card debt and gross expense increase. |
| **6** | Credit Card Payment | `CREDIT_CARD_PAYMENT` | `LIABILITY_CREDIT_CARD` | `ASSET_CASH` or `ASSET_BANK` | `null` | None | Liquid assets decrease; card debt decreases. **NEVER an expense.** |
| **7** | Internal Transfer | `TRANSFER` | Destination `ASSET_*` | Source `ASSET_*` | `null` | None | Total liquid assets, net worth, and income/expense unchanged. |
| **8** | Expense Refund | `REFUND` | Receiving `ASSET_*` or `LIABILITY_CREDIT_CARD` | `EXPENSE` (ID 3) | Category ID | If `envelope_id != null`: `REFUND_RESTORE` movement | Decreases gross expense; restores liquid cash or lowers card debt. |
| **9** | Audit Reversal | `REVERSAL` | Inverted target credit account | Inverted target debit account | Preserved from target | If target had envelope movement: offsetting `REVERSAL` movement | Offsets original postings across all ledger accounts. |

#### 2.2.6 Posting Matrix Engine (`posting_matrix.dart`)
Pure Dart service that constructs and validates balanced postings before any database interaction:
```dart
class PostingMatrix {
  static const int equityOpeningAccountId = 1;
  static const int defaultIncomeAccountId = 2;
  static const int defaultExpenseAccountId = 3;

  /// Asserts that sum(debit) == sum(credit) across all legs.
  /// Throws [UnbalancedTransactionException] if unbalanced or empty.
  static void assertBalanced(List<PostingLeg> postings) {
    if (postings.isEmpty) {
      throw const UnbalancedTransactionException(
        totalDebit: 0,
        totalCredit: 0,
        message: 'Transaction has no posting legs',
      );
    }
    int totalDebit = 0;
    int totalCredit = 0;
    for (final leg in postings) {
      totalDebit += leg.debitVnd;
      totalCredit += leg.creditVnd;
    }
    if (totalDebit != totalCredit) {
      throw UnbalancedTransactionException(
        totalDebit: totalDebit,
        totalCredit: totalCredit,
      );
    }
  }

  /// 1. Opening Asset Balance
  static List<PostingLeg> buildOpeningAsset({
    required int assetAccountId,
    required int amountVnd,
  }) {
    return [
      PostingLeg.debit(accountId: assetAccountId, amountVnd: amountVnd),
      PostingLeg.credit(accountId: equityOpeningAccountId, amountVnd: amountVnd),
    ];
  }

  /// 2. Opening Card Debt Balance
  static List<PostingLeg> buildOpeningDebt({
    required int creditCardAccountId,
    required int amountVnd,
  }) {
    return [
      PostingLeg.debit(accountId: equityOpeningAccountId, amountVnd: amountVnd),
      PostingLeg.credit(accountId: creditCardAccountId, amountVnd: amountVnd),
    ];
  }

  /// 3. Income
  static List<PostingLeg> buildIncome({
    required int receivingAssetAccountId,
    required int incomeAccountId,
    required int categoryId,
    required int amountVnd,
  }) {
    return [
      PostingLeg.debit(accountId: receivingAssetAccountId, amountVnd: amountVnd),
      PostingLeg.credit(
        accountId: incomeAccountId,
        amountVnd: amountVnd,
        categoryId: categoryId,
      ),
    ];
  }

  /// 4 & 5. Expense (Cash/Bank or Credit Card)
  static List<PostingLeg> buildExpense({
    required int sourceAccountId,
    required int expenseAccountId,
    required int categoryId,
    required int amountVnd,
    int? envelopeId,
  }) {
    return [
      PostingLeg.debit(
        accountId: expenseAccountId,
        amountVnd: amountVnd,
        categoryId: categoryId,
        envelopeId: envelopeId,
      ),
      PostingLeg.credit(
        accountId: sourceAccountId,
        amountVnd: amountVnd,
      ),
    ];
  }

  /// 6. Credit Card Payment (NEVER an expense)
  static List<PostingLeg> buildCreditCardPayment({
    required int creditCardAccountId,
    required int sourceAssetAccountId,
    required int amountVnd,
  }) {
    return [
      PostingLeg.debit(accountId: creditCardAccountId, amountVnd: amountVnd),
      PostingLeg.credit(accountId: sourceAssetAccountId, amountVnd: amountVnd),
    ];
  }

  /// 7. Internal Transfer
  static List<PostingLeg> buildInternalTransfer({
    required int sourceAssetAccountId,
    required int destinationAssetAccountId,
    required int amountVnd,
  }) {
    if (sourceAssetAccountId == destinationAssetAccountId) {
      throw const InvalidTransactionException(
        'Source and destination accounts must be different',
      );
    }
    return [
      PostingLeg.debit(accountId: destinationAssetAccountId, amountVnd: amountVnd),
      PostingLeg.credit(accountId: sourceAssetAccountId, amountVnd: amountVnd),
    ];
  }

  /// 8. Refund
  static List<PostingLeg> buildRefund({
    required int receivingAccountId,
    required int expenseAccountId,
    required int categoryId,
    required int amountVnd,
    int? envelopeId,
  }) {
    return [
      PostingLeg.debit(accountId: receivingAccountId, amountVnd: amountVnd),
      PostingLeg.credit(
        accountId: expenseAccountId,
        amountVnd: amountVnd,
        categoryId: categoryId,
        envelopeId: envelopeId,
      ),
    ];
  }

  /// 9. Reversal (Inverts existing postings)
  static List<PostingLeg> buildReversal(List<PostingLeg> originalPostings) {
    return originalPostings.map((leg) => leg.invert()).toList();
  }
}
```

#### 2.2.7 Void & Edit Algorithms (Audit-Preserving)

**Void / Cancel Algorithm**:
```text
voidTransaction(targetTxId):
  1. In DB transaction:
     a. Fetch targetTx = SELECT * FROM journal_transactions WHERE id = targetTxId
     b. Assert targetTx.status == 'POSTED' (throw InvalidTransactionException if already VOIDED/SUPERSEDED)
     c. UPDATE journal_transactions SET status = 'VOIDED' WHERE id = targetTxId
     d. Insert reversalTx:
        tx_type = 'REVERSAL'
        status = 'POSTED'
        description = 'Hoàn tác: ' + targetTx.description
        occurred_at = targetTx.occurred_at
        created_at = now()
        reverses_tx_id = targetTx.id
     e. Fetch all original postings for targetTxId
     f. For each posting P:
        Insert posting in reversalTx with:
          debit_vnd = P.credit_vnd
          credit_vnd = P.debit_vnd
          account_id = P.account_id
          category_id = P.category_id
          envelope_id = P.envelope_id
     g. Fetch any linked envelope_movements WHERE linked_transaction_id = targetTxId
     h. For each movement M:
        If M.movement_type == 'SPEND':
          Insert movement: movement_type = 'REVERSAL', amount_vnd = M.amount_vnd, dest_envelope_id = M.source_envelope_id, source_envelope_id = null, linked_transaction_id = reversalTx.id
          Update envelope: reserved_balance_vnd += M.amount_vnd
        If M.movement_type == 'REFUND_RESTORE':
          Insert movement: movement_type = 'REVERSAL', amount_vnd = M.amount_vnd, source_envelope_id = M.dest_envelope_id, dest_envelope_id = null, linked_transaction_id = reversalTx.id
          Update envelope: reserved_balance_vnd -= M.amount_vnd
```

**Edit Algorithm**:
```text
editTransaction(originalTxId, newTxCommand):
  1. In DB transaction:
     a. Fetch originalTx = SELECT * FROM journal_transactions WHERE id = originalTxId
     b. Assert originalTx.status == 'POSTED'
     c. Insert reversalTx for originalTx (same step as Void, reversing original postings and offsetting envelope movements)
     d. Insert newTx from newTxCommand:
        status = 'POSTED'
        occurred_at = newTxCommand.occurredAt
        created_at = now()
     e. Insert new postings for newTx (assert debit == credit)
     f. If newTxCommand links an envelope:
        Insert SPEND / REFUND_RESTORE movement linked to newTx.id and update envelope balance
     g. UPDATE originalTx SET status = 'SUPERSEDED', replaced_by_tx_id = newTx.id
```

---

### 2.3 Envelope Domain Specification (`lib/domain/envelopes/`)

#### 2.3.1 Enums & Exceptions
```dart
enum EnvelopePolicy {
  protected('PROTECTED'),
  flexible('FLEXIBLE');

  final String dbValue;
  const EnvelopePolicy(this.dbValue);

  static EnvelopePolicy fromDbValue(String value) {
    return EnvelopePolicy.values.firstWhere(
      (p) => p.dbValue == value,
      orElse: () => throw ArgumentError('Unknown EnvelopePolicy: $value'),
    );
  }
}

enum EnvelopeMovementType {
  allocate('ALLOCATE'),
  release('RELEASE'),
  transfer('TRANSFER'),
  spend('SPEND'),
  refundRestore('REFUND_RESTORE'),
  reversal('REVERSAL');

  final String dbValue;
  const EnvelopeMovementType(this.dbValue);

  static EnvelopeMovementType fromDbValue(String value) {
    return EnvelopeMovementType.values.firstWhere(
      (m) => m.dbValue == value,
      orElse: () => throw ArgumentError('Unknown EnvelopeMovementType: $value'),
    );
  }
}

class OverAllocationException implements Exception {
  final int requestedVnd;
  final int availableToAllocateVnd;
  final String message;

  const OverAllocationException({
    required this.requestedVnd,
    required this.availableToAllocateVnd,
    this.message = 'Requested allocation exceeds available-to-allocate funds',
  });

  @override
  String toString() =>
      'OverAllocationException: $message (requested: $requestedVnd, available: $availableToAllocateVnd)';
}

class SpendingDeficitException implements Exception {
  final int requestedVnd;
  final int currentReservedVnd;
  final int envelopeId;
  final String message;

  const SpendingDeficitException({
    required this.requestedVnd,
    required this.currentReservedVnd,
    required this.envelopeId,
    this.message = 'Spending exceeds reserved balance and negative exceptions are disabled',
  });

  @override
  String toString() =>
      'SpendingDeficitException: $message (requested: $requestedVnd, reserved: $currentReservedVnd, envelope: $envelopeId)';
}

class InvalidEnvelopeOperationException implements Exception {
  final String message;
  const InvalidEnvelopeOperationException(this.message);

  @override
  String toString() => 'InvalidEnvelopeOperationException: $message';
}
```

#### 2.3.2 Available-to-Allocate Calculator (`available_to_allocate.dart`)
Pure Dart calculation implementing Section 5.1 of `ARCHITECTURE_AND_RULES.md`:
$$\text{available\_to\_allocate} = \text{total\_liquid\_assets} - \text{total\_envelope\_reserves} - \text{minimum\_cash\_buffer\_vnd}$$

```dart
class AvailableToAllocateCalculator {
  /// Computes the exact available-to-allocate amount in integer VND.
  /// Note: The result can be negative if reserves + buffer exceed liquid assets.
  static int calculate({
    required int totalLiquidAssetsVnd,
    required int totalEnvelopeReservesVnd,
    required int minimumCashBufferVnd,
  }) {
    if (minimumCashBufferVnd < 0) {
      throw ArgumentError.value(
        minimumCashBufferVnd,
        'minimumCashBufferVnd',
        'Minimum cash buffer must be non-negative',
      );
    }
    return totalLiquidAssetsVnd - totalEnvelopeReservesVnd - minimumCashBufferVnd;
  }

  /// Validates an ALLOCATE command.
  /// Throws [OverAllocationException] if amount > max(0, availableToAllocate).
  static void validateAllocation({
    required int allocateAmountVnd,
    required int availableToAllocateVnd,
  }) {
    if (allocateAmountVnd <= 0) {
      throw ArgumentError.value(
        allocateAmountVnd,
        'allocateAmountVnd',
        'Allocation amount must be > 0',
      );
    }
    final int maxAllowed = availableToAllocateVnd > 0 ? availableToAllocateVnd : 0;
    if (allocateAmountVnd > maxAllowed) {
      throw OverAllocationException(
        requestedVnd: allocateAmountVnd,
        availableToAllocateVnd: availableToAllocateVnd,
      );
    }
  }

  /// Validates spending from an envelope.
  /// Throws [SpendingDeficitException] if amount > reservedBalance and negative exception is false.
  static void validateSpending({
    required int spendAmountVnd,
    required int reservedBalanceVnd,
    required bool allowNegativeException,
    required int envelopeId,
  }) {
    if (spendAmountVnd <= 0) {
      throw ArgumentError.value(
        spendAmountVnd,
        'spendAmountVnd',
        'Spend amount must be > 0',
      );
    }
    if (spendAmountVnd > reservedBalanceVnd && !allowNegativeException) {
      throw SpendingDeficitException(
        requestedVnd: spendAmountVnd,
        currentReservedVnd: reservedBalanceVnd,
        envelopeId: envelopeId,
      );
    }
  }
}
```

---

### 2.4 Drift DAOs & Persistence Integration (`lib/core/database/daos/`)

#### 2.4.1 Dynamic Account Balance Derivation (Zero Cached Column)
As required by Architectural Invariant 1.3:
- For Asset (`ASSET_CASH`, `ASSET_BANK`) & Expense (`EXPENSE`):
  $$\text{balance} = \sum \text{debit\_vnd} - \sum \text{credit\_vnd}$$
- For Liability (`LIABILITY_CREDIT_CARD`), Income (`INCOME`), & Equity (`EQUITY_OPENING`):
  $$\text{balance} = \sum \text{credit\_vnd} - \sum \text{debit\_vnd}$$

**Single Account Derivation Query**:
```sql
SELECT 
  COALESCE(SUM(debit_vnd), 0) AS total_debit,
  COALESCE(SUM(credit_vnd), 0) AS total_credit
FROM journal_postings
WHERE account_id = :accountId;
```

**All Accounts Derivation Query (Reactive Stream)**:
```sql
SELECT 
  a.id,
  a.name,
  a.kind,
  a.is_liquid,
  a.credit_limit,
  a.is_archived,
  COALESCE(SUM(p.debit_vnd), 0) AS total_debit,
  COALESCE(SUM(p.credit_vnd), 0) AS total_credit
FROM ledger_accounts a
LEFT JOIN journal_postings p ON a.id = p.account_id
WHERE a.is_archived = 0
GROUP BY a.id;
```

From this result set:
- If `kind IN ('ASSET_CASH', 'ASSET_BANK', 'EXPENSE')`: $\text{balance} = \text{total\_debit} - \text{total\_credit}$.
- If `kind IN ('LIABILITY_CREDIT_CARD', 'INCOME', 'EQUITY_OPENING')`: $\text{balance} = \text{total\_credit} - \text{total\_debit}$.
- $\text{Total Liquid Assets} = \sum \text{balance}$ for accounts where $\text{is\_liquid} == 1$.
- $\text{Net Worth} = \sum \text{Asset Balances} - \sum \text{Liability Balances}$.

#### 2.4.2 Clean UI Query Filter
```sql
SELECT * FROM journal_transactions
WHERE status = 'POSTED' AND tx_type != 'REVERSAL'
ORDER BY occurred_at DESC, id DESC;
```
This cleanly filters out:
1. `VOIDED` transactions
2. `SUPERSEDED` transactions (historical versions before edits)
3. `REVERSAL` offset transactions
Leaving only the active, canonical entries for standard user feeds.

#### 2.4.3 `LedgerDao` Implementation Blueprint (`ledger_dao.dart`)
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../domain/ledger/posting_leg.dart';
import '../../../domain/ledger/posting_matrix.dart';
import '../../../domain/ledger/account_kind.dart';
import '../../../domain/ledger/ledger_exceptions.dart';

part 'ledger_dao.g.dart'; // or standalone DatabaseAccessor

@DriftAccessor(tables: [
  LedgerAccounts,
  Categories,
  JournalTransactions,
  JournalPostings,
  Envelopes,
  EnvelopeMovements,
  Settings,
])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.db);

  /// Posts a balanced journal transaction atomically.
  /// Invariant: SUM(debit) == SUM(credit).
  Future<int> postTransaction({
    required String txType,
    required String description,
    required int occurredAt,
    required List<PostingLeg> postings,
    String? idempotencyKey,
    int? linkedEnvelopeId,
    String? envelopeMovementType, // 'SPEND' or 'REFUND_RESTORE'
  }) async {
    // 1. Pure Dart Invariant Assertion
    PostingMatrix.assertBalanced(postings);

    return db.transaction(() async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 2. Insert Transaction Record
      final txId = await into(journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: txType,
          status: const Value('POSTED'),
          description: Value(description),
          occurredAt: occurredAt,
          createdAt: nowMs,
          idempotencyKey: Value(idempotencyKey),
        ),
      );

      // 3. Insert All Posting Legs
      await batch((b) {
        for (final leg in postings) {
          b.insert(
            journalPostings,
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: leg.accountId,
              debitVnd: Value(leg.debitVnd),
              creditVnd: Value(leg.creditVnd),
              categoryId: Value(leg.categoryId),
              envelopeId: Value(leg.envelopeId ?? linkedEnvelopeId),
            ),
          );
        }
      });

      // 4. Handle Linked Envelope Movement if specified
      if (linkedEnvelopeId != null && envelopeMovementType != null) {
        final amountVnd = postings.fold<int>(
          0,
          (sum, leg) => leg.envelopeId == linkedEnvelopeId
              ? (leg.debitVnd > 0 ? leg.debitVnd : leg.creditVnd)
              : sum,
        );

        if (amountVnd > 0) {
          if (envelopeMovementType == 'SPEND') {
            await into(envelopeMovements).insert(
              EnvelopeMovementsCompanion.insert(
                movementType: 'SPEND',
                amountVnd: amountVnd,
                sourceEnvelopeId: Value(linkedEnvelopeId),
                linkedTransactionId: Value(txId),
                occurredAt: occurredAt,
              ),
            );
            await customUpdate(
              'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
              variables: [Variable.withInt(amountVnd), Variable.withInt(linkedEnvelopeId)],
              updates: {envelopes},
            );
          } else if (envelopeMovementType == 'REFUND_RESTORE') {
            await into(envelopeMovements).insert(
              EnvelopeMovementsCompanion.insert(
                movementType: 'REFUND_RESTORE',
                amountVnd: amountVnd,
                destEnvelopeId: Value(linkedEnvelopeId),
                linkedTransactionId: Value(txId),
                occurredAt: occurredAt,
              ),
            );
            await customUpdate(
              'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ? WHERE id = ?',
              variables: [Variable.withInt(amountVnd), Variable.withInt(linkedEnvelopeId)],
              updates: {envelopes},
            );
          }
        }
      }

      return txId;
    });
  }

  /// Voids an active transaction and creates an audit REVERSAL record.
  Future<int> voidTransaction(int transactionId) async {
    return db.transaction(() async {
      final target = await (select(journalTransactions)
            ..where((t) => t.id.equals(transactionId)))
          .getSingleOrNull();

      if (target == null) {
        throw InvalidTransactionException('Transaction $transactionId not found');
      }
      if (target.status != 'POSTED') {
        throw InvalidTransactionException(
          'Cannot void transaction in status ${target.status}',
        );
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Mark target VOIDED
      await (update(journalTransactions)..where((t) => t.id.equals(transactionId))).write(
        const JournalTransactionsCompanion(status: Value('VOIDED')),
      );

      // 2. Insert REVERSAL Transaction
      final reversalTxId = await into(journalTransactions).insert(
        JournalTransactionsCompanion.insert(
          txType: 'REVERSAL',
          status: const Value('POSTED'),
          description: Value('Hoàn tác: ${target.description}'),
          occurredAt: target.occurredAt,
          createdAt: nowMs,
          reversesTxId: Value(target.id),
        ),
      );

      // 3. Fetch & Invert Postings
      final postings = await (select(journalPostings)
            ..where((p) => p.transactionId.equals(transactionId)))
          .get();

      await batch((b) {
        for (final p in postings) {
          b.insert(
            journalPostings,
            JournalPostingsCompanion.insert(
              transactionId: reversalTxId,
              accountId: p.accountId,
              debitVnd: Value(p.creditVnd),
              creditVnd: Value(p.debitVnd),
              categoryId: Value(p.categoryId),
              envelopeId: Value(p.envelopeId),
            ),
          );
        }
      });

      // 4. Reverse Linked Envelope Movements
      final movements = await (select(envelopeMovements)
            ..where((m) => m.linkedTransactionId.equals(transactionId)))
          .get();

      for (final m in movements) {
        if (m.movementType == 'SPEND' && m.sourceEnvelopeId != null) {
          // Restore spent amount
          await into(envelopeMovements).insert(
            EnvelopeMovementsCompanion.insert(
              movementType: 'REVERSAL',
              amountVnd: m.amountVnd,
              destEnvelopeId: Value(m.sourceEnvelopeId),
              linkedTransactionId: Value(reversalTxId),
              occurredAt: nowMs,
            ),
          );
          await customUpdate(
            'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ? WHERE id = ?',
            variables: [Variable.withInt(m.amountVnd), Variable.withInt(m.sourceEnvelopeId!)],
            updates: {envelopes},
          );
        } else if (m.movementType == 'REFUND_RESTORE' && m.destEnvelopeId != null) {
          // Re-deduct restored amount
          await into(envelopeMovements).insert(
            EnvelopeMovementsCompanion.insert(
              movementType: 'REVERSAL',
              amountVnd: m.amountVnd,
              sourceEnvelopeId: Value(m.destEnvelopeId),
              linkedTransactionId: Value(reversalTxId),
              occurredAt: nowMs,
            ),
          );
          await customUpdate(
            'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
            variables: [Variable.withInt(m.amountVnd), Variable.withInt(m.destEnvelopeId!)],
            updates: {envelopes},
          );
        }
      }

      return reversalTxId;
    });
  }

  /// Edits an active transaction by reversing the original and posting a replacement.
  Future<int> editTransaction({
    required int originalTxId,
    required String txType,
    required String description,
    required int occurredAt,
    required List<PostingLeg> newPostings,
    int? linkedEnvelopeId,
    String? envelopeMovementType,
  }) async {
    return db.transaction(() async {
      // 1. Void & reverse original
      await voidTransaction(originalTxId);

      // 2. Update original status from VOIDED to SUPERSEDED
      // (voidTransaction set it to VOIDED; edit transitions it to SUPERSEDED)
      await (update(journalTransactions)..where((t) => t.id.equals(originalTxId))).write(
        const JournalTransactionsCompanion(status: Value('SUPERSEDED')),
      );

      // 3. Post replacement transaction
      final newTxId = await postTransaction(
        txType: txType,
        description: description,
        occurredAt: occurredAt,
        postings: newPostings,
        linkedEnvelopeId: linkedEnvelopeId,
        envelopeMovementType: envelopeMovementType,
      );

      // 4. Link replaced_by_tx_id on original
      await (update(journalTransactions)..where((t) => t.id.equals(originalTxId))).write(
        JournalTransactionsCompanion(replacedByTxId: Value(newTxId)),
      );

      return newTxId;
    });
  }

  /// Derives dynamic balance for a single account.
  Future<int> getAccountBalance(int accountId) async {
    final account = await (select(ledgerAccounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingle();

    final result = await customSelect(
      'SELECT COALESCE(SUM(debit_vnd), 0) AS total_debit, '
      'COALESCE(SUM(credit_vnd), 0) AS total_credit '
      'FROM journal_postings WHERE account_id = ?',
      variables: [Variable.withInt(accountId)],
      readsFrom: {journalPostings},
    ).getSingle();

    final debit = result.read<int>('total_debit');
    final credit = result.read<int>('total_credit');
    final kind = AccountKind.fromDbValue(account.kind);

    return kind.isDebitNormal ? (debit - credit) : (credit - debit);
  }

  /// Watches all account balances with dynamic derivation.
  Stream<List<AccountWithBalance>> watchAccountsWithBalances() {
    return customSelect(
      'SELECT a.id, a.name, a.kind, a.is_liquid, a.credit_limit, a.is_archived, '
      'COALESCE(SUM(p.debit_vnd), 0) AS total_debit, '
      'COALESCE(SUM(p.credit_vnd), 0) AS total_credit '
      'FROM ledger_accounts a '
      'LEFT JOIN journal_postings p ON a.id = p.account_id '
      'WHERE a.is_archived = 0 '
      'GROUP BY a.id ORDER BY a.id ASC',
      readsFrom: {ledgerAccounts, journalPostings},
    ).watch().map((rows) {
      return rows.map((r) {
        final kind = AccountKind.fromDbValue(r.read<String>('kind'));
        final debit = r.read<int>('total_debit');
        final credit = r.read<int>('total_credit');
        final balance = kind.isDebitNormal ? (debit - credit) : (credit - debit);

        return AccountWithBalance(
          id: r.read<int>('id'),
          name: r.read<String>('name'),
          kind: kind,
          isLiquid: r.read<bool>('is_liquid'),
          creditLimit: r.read<int>('credit_limit'),
          balanceVnd: balance,
        );
      }).toList();
    });
  }

  /// Watches total liquid assets across active ASSET_CASH and ASSET_BANK accounts.
  Stream<int> watchTotalLiquidAssets() {
    return watchAccountsWithBalances().map((accounts) {
      return accounts
          .where((a) => a.isLiquid)
          .fold<int>(0, (sum, a) => sum + a.balanceVnd);
    });
  }

  /// Watches net worth: Total Assets - Total Liabilities.
  Stream<int> watchNetWorth() {
    return watchAccountsWithBalances().map((accounts) {
      int totalAssets = 0;
      int totalLiabilities = 0;
      for (final a in accounts) {
        if (a.kind == AccountKind.assetCash || a.kind == AccountKind.assetBank) {
          totalAssets += a.balanceVnd;
        } else if (a.kind == AccountKind.liabilityCreditCard) {
          totalLiabilities += a.balanceVnd;
        }
      }
      return totalAssets - totalLiabilities;
    });
  }

  /// Clean UI Transaction stream (filters out VOIDED, SUPERSEDED, and REVERSAL).
  Stream<List<JournalTransaction>> watchCleanTransactions() {
    return (select(journalTransactions)
          ..where((t) => t.status.equals('POSTED') & t.txType.equals('REVERSAL').not())
          ..orderBy([
            (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }
}

class AccountWithBalance {
  final int id;
  final String name;
  final AccountKind kind;
  final bool isLiquid;
  final int creditLimit;
  final int balanceVnd;

  const AccountWithBalance({
    required this.id,
    required this.name,
    required this.kind,
    required this.isLiquid,
    required this.creditLimit,
    required this.balanceVnd,
  });
}
```

#### 2.4.4 `EnvelopeDao` Implementation Blueprint (`envelope_dao.dart`)
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../domain/envelopes/envelope_policy.dart';
import '../../../domain/envelopes/envelope_exceptions.dart';
import '../../../domain/envelopes/available_to_allocate.dart';

part 'envelope_dao.g.dart';

@DriftAccessor(tables: [Envelopes, EnvelopeMovements, Settings, LedgerAccounts, JournalPostings])
class EnvelopeDao extends DatabaseAccessor<AppDatabase> with _$EnvelopeDaoMixin {
  EnvelopeDao(super.db);

  /// Computes current Available-to-Allocate.
  Future<int> getAvailableToAllocate(int totalLiquidAssetsVnd) async {
    final settingsRow = await select(settings).getSingle();
    final envelopesList = await (select(envelopes)..where((e) => e.isArchived.equals(false))).get();
    final totalReserved = envelopesList.fold<int>(0, (sum, e) => sum + e.reservedBalanceVnd);

    return AvailableToAllocateCalculator.calculate(
      totalLiquidAssetsVnd: totalLiquidAssetsVnd,
      totalEnvelopeReservesVnd: totalReserved,
      minimumCashBufferVnd: settingsRow.minimumCashBufferVnd,
    );
  }

  /// Allocates virtual cash into an envelope.
  /// Generates ZERO journal postings.
  Future<int> allocate({
    required int envelopeId,
    required int amountVnd,
    required int totalLiquidAssetsVnd,
  }) async {
    return db.transaction(() async {
      final available = await getAvailableToAllocate(totalLiquidAssetsVnd);
      AvailableToAllocateCalculator.validateAllocation(
        allocateAmountVnd: amountVnd,
        availableToAllocateVnd: available,
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final movementId = await into(envelopeMovements).insert(
        EnvelopeMovementsCompanion.insert(
          movementType: 'ALLOCATE',
          amountVnd: amountVnd,
          destEnvelopeId: Value(envelopeId),
          occurredAt: nowMs,
        ),
      );

      await customUpdate(
        'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ? WHERE id = ?',
        variables: [Variable.withInt(amountVnd), Variable.withInt(envelopeId)],
        updates: {envelopes},
      );

      return movementId;
    });
  }

  /// Releases virtual cash from an envelope back to Available-to-Allocate.
  /// Generates ZERO journal postings.
  Future<int> release({
    required int envelopeId,
    required int amountVnd,
  }) async {
    if (amountVnd <= 0) {
      throw ArgumentError.value(amountVnd, 'amountVnd', 'Release amount must be > 0');
    }

    return db.transaction(() async {
      final target = await (select(envelopes)..where((e) => e.id.equals(envelopeId))).getSingle();
      if (amountVnd > target.reservedBalanceVnd && !target.allowNegativeException) {
        throw SpendingDeficitException(
          requestedVnd: amountVnd,
          currentReservedVnd: target.reservedBalanceVnd,
          envelopeId: envelopeId,
        );
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final movementId = await into(envelopeMovements).insert(
        EnvelopeMovementsCompanion.insert(
          movementType: 'RELEASE',
          amountVnd: amountVnd,
          sourceEnvelopeId: Value(envelopeId),
          occurredAt: nowMs,
        ),
      );

      await customUpdate(
        'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
        variables: [Variable.withInt(amountVnd), Variable.withInt(envelopeId)],
        updates: {envelopes},
      );

      return movementId;
    });
  }

  /// Transfers reserved funds between two envelopes.
  /// Generates ZERO journal postings.
  Future<int> transfer({
    required int fromEnvelopeId,
    required int toEnvelopeId,
    required int amountVnd,
  }) async {
    if (fromEnvelopeId == toEnvelopeId) {
      throw const InvalidEnvelopeOperationException('Source and destination envelopes must be distinct');
    }
    if (amountVnd <= 0) {
      throw ArgumentError.value(amountVnd, 'amountVnd', 'Transfer amount must be > 0');
    }

    return db.transaction(() async {
      final source = await (select(envelopes)..where((e) => e.id.equals(fromEnvelopeId))).getSingle();
      if (amountVnd > source.reservedBalanceVnd && !source.allowNegativeException) {
        throw SpendingDeficitException(
          requestedVnd: amountVnd,
          currentReservedVnd: source.reservedBalanceVnd,
          envelopeId: fromEnvelopeId,
        );
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final movementId = await into(envelopeMovements).insert(
        EnvelopeMovementsCompanion.insert(
          movementType: 'TRANSFER',
          amountVnd: amountVnd,
          sourceEnvelopeId: Value(fromEnvelopeId),
          destEnvelopeId: Value(toEnvelopeId),
          occurredAt: nowMs,
        ),
      );

      await customUpdate(
        'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
        variables: [Variable.withInt(amountVnd), Variable.withInt(fromEnvelopeId)],
        updates: {envelopes},
      );
      await customUpdate(
        'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ? WHERE id = ?',
        variables: [Variable.withInt(amountVnd), Variable.withInt(toEnvelopeId)],
        updates: {envelopes},
      );

      return movementId;
    });
  }
}
```

---

## 3. Caveats

1. **Pure Dart Meta vs Flutter Foundation**: `lib/core/money/vnd_money.dart` currently imports `'package:flutter/foundation.dart' show immutable;`. Because `package:meta` is bundled with the Dart SDK, domain files can either import `package:meta/meta.dart` or omit annotations. If domain imports `vnd_money.dart`, replacing that one import with `import 'package:meta/meta.dart';` keeps `lib/core/money/` 100% pure Dart.
2. **Drift Code Generation**: When creating `LedgerDao` and `EnvelopeDao`, adding them to `@DriftDatabase(tables: [...], daos: [LedgerDao, EnvelopeDao])` requires running `C:\Users\coihu12\flutter\bin\flutter.bat pub run build_runner build --delete-conflicting-outputs`. Alternatively, implementing them as standalone classes wrapping `final AppDatabase db` or `DatabaseAccessor<AppDatabase>` without mixins compiles immediately with full type-safety. The implementer should choose the cleanest approach that maintains zero build warnings.
3. **Credit Card Payments**: A credit card payment transfers liquid funds to settle a liability (`Debit: LIABILITY_CREDIT_CARD, Credit: ASSET_CASH/BANK`). It must **never** touch an expense account or create an envelope movement. This is critical for Scenario 7 compliance.

---

## 4. Conclusion

1. **Ledger Engine**: Pure Dart `PostingMatrix` cleanly enforces `sum(debit) == sum(credit)` for all 7 transaction types across the 9 execution patterns. It isolates financial rules from the database and prevents corrupted postings from ever reaching SQLite.
2. **Decoupled Envelopes**: Virtual funds (`ALLOCATE`, `RELEASE`, `TRANSFER`) manipulate conceptual reserves in `envelopes` and `envelope_movements` without generating any double-entry journal postings. Over-allocations and unconfirmed negative deficits are blocked at the domain boundary.
3. **Audit-Preserving Reversals**: Edits and voids preserve complete historical integrity. Reversals mathematically cancel out previous postings, while the clean UI query filter (`status = 'POSTED' AND tx_type != 'REVERSAL'`) ensures user-facing screens remain clutter-free.
4. **Dynamic Balance Derivation**: Deriving account balances, liquid assets, and net worth on the fly guarantees zero cache desynchronization bugs across edits, voids, and batch imports.

---

## 5. Verification Method & Test Plan

### 5.1 Concrete Unit Test Matrix (`test/unit/ledger_envelope_test.dart`)
1. **`AccountKind` Tests**:
   - `isLiquid` returns `true` only for `ASSET_CASH` and `ASSET_BANK`.
   - `isDebitNormal` returns `true` for Asset and Expense; `false` for Liability, Income, Equity.
   - `fromDbValue` correctly round-trips all 6 kinds; throws on invalid strings.
2. **`PostingLeg` Value Object Tests**:
   - `PostingLeg.debit` creates leg with `debitVnd > 0`, `creditVnd == 0`.
   - `PostingLeg.credit` creates leg with `creditVnd > 0`, `debitVnd == 0`.
   - Rejects `amount <= 0` and amounts $> \text{maxSafeVnd}$.
   - `invert()` swaps debit and credit amounts accurately.
3. **`PostingMatrix` Invariant & Pattern Tests**:
   - `assertBalanced` passes when $\sum \text{debit} == \sum \text{credit}$.
   - Throws `UnbalancedTransactionException` when $\sum \text{debit} \ne \sum \text{credit}$ or empty.
   - Pattern 1 (Opening Asset): Debit Asset, Credit Equity Opening (ID 1).
   - Pattern 2 (Opening Debt): Debit Equity Opening (ID 1), Credit Card Liability.
   - Pattern 3 (Income): Debit Asset, Credit Income (ID 2).
   - Pattern 4 (Cash Expense): Debit Expense (ID 3), Credit Cash/Bank.
   - Pattern 5 (Card Expense): Debit Expense (ID 3), Credit Card Liability.
   - Pattern 6 (Credit Card Payment): Debit Card Liability, Credit Cash/Bank. **Asserts zero expense account involvement.**
   - Pattern 7 (Transfer): Debit Dest Asset, Credit Source Asset; rejects same source/dest.
   - Pattern 8 (Refund): Debit Asset/Card, Credit Expense (ID 3).
   - Pattern 9 (Reversal): Inverts all postings; asserts balanced.
4. **`AvailableToAllocateCalculator` Tests**:
   - Basic: `10.000.000 - 2.000.000 - 1.000.000 = 7.000.000 ₫`.
   - Negative outcome when reserves + buffer exceed liquid assets.
   - `validateAllocation` throws `OverAllocationException` when requested > available.
   - `validateSpending` throws `SpendingDeficitException` when spend > reserved and negative exception is false.

### 5.2 Concrete Database Test Matrix (`test/database/ledger_dao_test.dart`)
Execute against in-memory SQLite (`NativeDatabase.memory(setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'))`):

| Test # | Acceptance Scenario | Test Case Name & Setup | Assertions & Invariant Checks |
|---|---|---|---|
| **1** | **Scenario 1** | Opening Asset (`10.000.000 ₫`) | Post Opening Asset to Cash. Assert Cash balance = `10.000.000 ₫`, Total Liquid Assets = `10.000.000 ₫`, Operating Income = `0 ₫`. |
| **2** | **Scenario 2** | Salary Income (`20.000.000 ₫`) | Post Income from Salary category. Assert Cash balance = `30.000.000 ₫`, Total Liquid Assets = `30.000.000 ₫`, Recognized Income = `20.000.000 ₫`. |
| **3** | **Scenario 3** | Cash Expense (`100.000 ₫`) with Envelope | Create Envelope with `1.000.000 ₫`. Post Expense linked to category & envelope. Assert Cash balance = `29.900.000 ₫`, Net Expense = `100.000 ₫`, Envelope reserved balance = `900.000 ₫`. |
| **4** | **Scenario 4** | Internal Transfer (`2.000.000 ₫`) | Transfer from Cash to Bank account. Assert Total Liquid Assets unchanged (`29.900.000 ₫`), Net Worth unchanged, Income = `20.000.000 ₫`, Expense = `100.000 ₫`. |
| **5** | **Scenario 5** | Virtual Fund Allocation (`1.000.000 ₫` to Protected) | Allocate `1.000.000 ₫` into Protected Envelope. Assert Liquid Assets (`29.900.000 ₫`) and Net Expense (`100.000 ₫`) unchanged. Assert zero new journal postings created. Assert Available-to-Allocate decreases by `1.000.000 ₫`. |
| **6** | **Scenario 6** | Credit Card Purchase (`500.000 ₫`) | Post Expense using Credit Card account. Assert Net Expense increases by `500.000 ₫`, Card Liability = `500.000 ₫`, Liquid Assets untouched (`29.900.000 ₫`). |
| **7** | **Scenario 7** | Credit Card Payment (`500.000 ₫`) | Pay Card from Bank account. Assert Liquid Assets decrease by `500.000 ₫`, Card Liability = `0 ₫`, Net Expense does NOT increase. |
| **8** | **Scenario 8** | Refund (`50.000 ₫`) with Envelope | Post Refund to Cash with linked envelope. Assert Cash increases by `50.000 ₫`, Net Expense decreases by `50.000 ₫`, Envelope restored by `50.000 ₫`. |
| **9** | **Scenario 9** | Void & Edit Transaction | Void an Expense transaction: assert target status = `VOIDED`, `REVERSAL` transaction created, offsetting envelope movement created, balances restore cleanly. Edit a transaction: assert original status = `SUPERSEDED`, `replaced_by_tx_id` set, clean UI stream hides superseded/reversals. |
| **10** | **Scenario 10** | Duplicate Submission Guard | Post transaction with `idempotencyKey = 'idemp-1'`. Attempt second post with identical key: assert rejected by unique constraint; exactly one transaction persisted. |

### 5.3 Independent Verification Commands
```bash
# 1. Format check
C:\Users\coihu12\flutter\bin\flutter.bat format --output=none --set-exit-if-changed .

# 2. Static analysis
C:\Users\coihu12\flutter\bin\flutter.bat analyze

# 3. Test execution
C:\Users\coihu12\flutter\bin\flutter.bat test test/unit/ test/database/
```
