# ARCHITECTURE & DOMAIN RULES SPECIFICATION — ĐỒNG TIỀN

> **Authoritative Technical Blueprint, Mathematical Formats, Persistence Rules & Architecture Decision Records (ADRs)**  
> Application: **Đồng Tiền** (`vn.dongtien`)  
> Target Platform: Android (Offline-First, Material 3, `vi_VN` Locale)

---

## 1. DOUBLE-ENTRY GENERAL LEDGER ARCHITECTURE

The accounting foundation of Đồng Tiền is a formal double-entry general ledger. Unlike conventional budget apps that maintain arbitrary running balances, every financial event in Đồng Tiền is modeled as a balanced journal transaction composed of discrete debit and credit postings.

### 1.1 Fundamental Accounting Equation
The ledger enforces the expanded balance sheet equation across the entire lifecycle of the application:
$$\text{Assets} = \text{Liabilities} + \text{Equity} + (\text{Income} - \text{Expenses})$$

Rearranged into the debit-credit equality form:
$$\sum \text{Debits} = \sum \text{Credits}$$

### 1.2 Chart of Accounts
Every ledger account is classified into one of six distinct kinds:

| Account Kind (`kind`) | Normal Balance | Economic Purpose | Liquid Flag (`is_liquid`) |
|---|---|---|---|
| `ASSET_CASH` | Debit | Physical cash in wallet or safe | `true` |
| `ASSET_BANK` | Debit | Checking, savings, or digital wallet accounts | `true` |
| `LIABILITY_CREDIT_CARD` | Credit | Short-term credit card borrowing / debt | `false` |
| `INCOME` | Credit | Inflows from salary, bonus, investments | `false` |
| `EXPENSE` | Debit | Outflows for goods, services, utilities | `false` |
| `EQUITY_OPENING` | Credit | Balancing equity for initial starting balances | `false` |

#### Liquid Asset Invariant
An account has `is_liquid == true` **if and only if** its kind is `ASSET_CASH` or `ASSET_BANK`. Credit card accounts, regardless of their available limit, are liabilities and NEVER marked liquid.

### 1.3 Transaction Invariant Check
Every ledger modification MUST execute inside an atomic SQLite transaction:
```dart
await db.transaction(() async {
  // 1. Insert journal_transactions row
  // 2. Insert journal_postings rows
  // 3. Verify debit == credit
  // 4. Record any linked envelope_movements
});
```

Before committing the transaction, the engine asserts the fundamental balance invariant:
$$\sum_{p \in \text{postings}} p.\text{debit\_vnd} == \sum_{p \in \text{postings}} p.\text{credit\_vnd}$$

If $\sum \text{debit} \ne \sum \text{credit}$, the engine throws an `UnbalancedTransactionException` and aborts the database transaction, leaving the database completely unmodified.

### 1.4 The 7-Type Double-Entry Posting Matrix

The ledger defines explicit posting rules for all 7 transaction operations:

| # | Transaction Type (`tx_type`) | Debit Leg (`debit_vnd`) | Credit Leg (`credit_vnd`) | Atomic Envelope Linkage | Economic Effect |
|---|---|---|---|---|---|
| **1** | `OPENING_BALANCE` (Asset) | `ASSET_CASH` or `ASSET_BANK` | `EQUITY_OPENING` | None | Initializes starting liquid cash. Operating income remains `0 ₫`. |
| **2** | `OPENING_BALANCE` (Card Debt) | `EQUITY_OPENING` | `LIABILITY_CREDIT_CARD` | None | Initializes pre-existing credit card liability. |
| **3** | `INCOME` | `ASSET_CASH` or `ASSET_BANK` | `INCOME` (Category linked) | None | Increases liquid cash and recognized operating income. |
| **4** | `EXPENSE` (Cash/Bank) | `EXPENSE` (Category linked) | `ASSET_CASH` or `ASSET_BANK` | If `envelope_id != null`: `SPEND` movement | Decreases liquid cash and increases gross expense. |
| **5** | `EXPENSE` (Credit Card) | `EXPENSE` (Category linked) | `LIABILITY_CREDIT_CARD` | If `envelope_id != null`: `SPEND` movement | Liquid cash untouched; credit card debt increases. |
| **6** | `CREDIT_CARD_PAYMENT` | `LIABILITY_CREDIT_CARD` | `ASSET_CASH` or `ASSET_BANK` | None | Settles card debt using liquid cash. **NEVER recognized as an expense.** |
| **7** | `INTERNAL_TRANSFER` | Destination `ASSET_*` | Source `ASSET_*` | None | Moves cash between accounts. Total liquid cash, income, and expenses unchanged. |
| **8** | `REFUND` | Receiving `ASSET_*` or `LIABILITY_CREDIT_CARD` | `EXPENSE` (Category linked) | If `envelope_id != null`: `REFUND_RESTORE` movement | Decreases gross expense; restores liquid cash or reduces card debt. |
| **9** | `REVERSAL` | Inverted target credit accounts | Inverted target debit accounts | If target had envelope movement: offsetting `REVERSAL` | Offsets original postings across all accounts. |

---

## 2. ATOMIC ENVELOPE LINKAGE & MOVEMENT ENGINE

### 2.1 Decoupling Principle
Virtual fund envelopes (`envelopes`) represent conceptual earmarks or reservations of existing liquid cash. They are completely decoupled from the double-entry general ledger:
- Allocating money into an envelope does NOT transfer money to a different bank account.
- Allocating money into an envelope does NOT count as an accounting expense.
- Releasing money from an envelope does NOT count as income.

Because virtual fund operations do not affect real assets, liabilities, or equity, they generate **zero double-entry journal postings**. They are recorded exclusively in `envelope_movements`.

### 2.2 Envelope Policies
Each envelope specifies an immutable policy governing how it interacts with the Safe-to-Spend formula:
1. `PROTECTED`: Reserved for critical obligations, emergency funds, or fixed savings goals (e.g., "Quỹ khẩn cấp", "Tiền thuê nhà"). Funds in protected envelopes are strictly subtracted from available cash in Safe-to-Spend.
2. `FLEXIBLE`: Reserved for discretionary budgeting goals (e.g., "Ăn chơi", "Mua sắm cá nhân"). Funds in flexible envelopes are discretionary and NOT subtracted in Safe-to-Spend.

### 2.3 The 6 Envelope Movement Types

All changes to envelope balances are recorded in `envelope_movements` with `amount_vnd > 0`:

```text
               ┌──────────┐
               │ ALLOCATE │ ──> Increases envelope reserved balance
               └──────────┘
               ┌──────────┐
               │ RELEASE  │ ──> Decreases envelope reserved balance
               └──────────┘
               ┌──────────┐
               │ TRANSFER │ ──> Moves reserve between envelopes
               └──────────┘
               ┌──────────┐
               │  SPEND   │ ──> Linked to EXPENSE transaction
               └──────────┘
               ┌────────────────┐
               │ REFUND_RESTORE │ ──> Linked to REFUND transaction
               └────────────────┘
               ┌──────────┐
               │ REVERSAL │ ──> Linked to void/edit of transaction
               └──────────┘
```

#### Movement Invariants & Execution Rules

1. **`ALLOCATE`**:
   - `source_envelope_id = null`, `dest_envelope_id = target_env.id`.
   - Invariant: `amount_vnd <= max(0, available_to_allocate)`.
   - Effect: `target_env.reserved_balance_vnd += amount_vnd`.
2. **`RELEASE`**:
   - `source_envelope_id = target_env.id`, `dest_envelope_id = null`.
   - Invariant: `amount_vnd <= target_env.reserved_balance_vnd` (unless negative exception confirmed).
   - Effect: `target_env.reserved_balance_vnd -= amount_vnd`.
3. **`TRANSFER`**:
   - `source_envelope_id = from_env.id`, `dest_envelope_id = to_env.id`.
   - Invariant: `amount_vnd <= from_env.reserved_balance_vnd`.
   - Effect: `from_env.reserved_balance_vnd -= amount_vnd`, `to_env.reserved_balance_vnd += amount_vnd`.
4. **`SPEND`**:
   - Triggered atomically inside `postTransaction()` when an `EXPENSE` transaction supplies `envelope_id`.
   - `source_envelope_id = envelope.id`, `dest_envelope_id = null`, `linked_transaction_id = tx.id`.
   - Invariant: If `amount_vnd > envelope.reserved_balance_vnd`, transaction is blocked unless `allow_negative_exception == true` is explicitly confirmed by the user.
   - Effect: `envelope.reserved_balance_vnd -= amount_vnd`.
5. **`REFUND_RESTORE`**:
   - Triggered atomically inside `postTransaction()` when a `REFUND` transaction supplies `envelope_id`.
   - `source_envelope_id = null`, `dest_envelope_id = envelope.id`, `linked_transaction_id = tx.id`.
   - Effect: `envelope.reserved_balance_vnd += amount_vnd`.
6. **`REVERSAL`**:
   - Triggered atomically inside `voidTransaction()` or `editTransaction()` when reversing a transaction that had a linked envelope movement.
   - If original was `SPEND`: restores `amount_vnd` to envelope (`dest_envelope_id = envelope.id`).
   - If original was `REFUND_RESTORE`: deducts `amount_vnd` from envelope (`source_envelope_id = envelope.id`).

---

## 3. DYNAMIC ACCOUNT BALANCE DERIVATION

No mutable cached balance columns exist on `ledger_accounts`. Cached balance columns introduce data corruption, concurrency race conditions, and synchronization bugs when transactions are edited or voided.

### 3.1 Derivation Formulas Across Postings
Balances are calculated on the fly using SQL aggregate queries across **all** postings in `journal_postings`:

- **Asset Accounts** (`ASSET_CASH`, `ASSET_BANK`):
  $$\text{Balance} = \sum \text{debit\_vnd} - \sum \text{credit\_vnd}$$
- **Expense Accounts** (`EXPENSE`):
  $$\text{Balance} = \sum \text{debit\_vnd} - \sum \text{credit\_vnd}$$
- **Liability Accounts** (`LIABILITY_CREDIT_CARD`):
  $$\text{Balance} = \sum \text{credit\_vnd} - \sum \text{debit\_vnd}$$
- **Income Accounts** (`INCOME`):
  $$\text{Balance} = \sum \text{credit\_vnd} - \sum \text{debit\_vnd}$$
- **Equity Accounts** (`EQUITY_OPENING`):
  $$\text{Balance} = \sum \text{credit\_vnd} - \sum \text{debit\_vnd}$$

### 3.2 Total Liquid Assets
$$\text{total\_liquid\_assets} = \sum_{a \in \text{Accounts}} \text{balance}(a) \quad \text{where } a.\text{kind} \in (\text{ASSET\_CASH}, \text{ASSET\_BANK}) \text{ and } a.\text{is\_liquid} == \text{true}$$
- Credit limits and credit card liabilities are strictly excluded from liquid assets.

### 3.3 Net Worth
$$\text{Net Worth} = \sum \text{Asset Balances} - \sum \text{Liability Balances}$$

---

## 4. AUDIT-PRESERVING REVERSAL & EDIT ENGINE

To ensure absolute auditability and mathematical integrity, user-facing deletes and edits NEVER perform destructive SQL `DELETE` or `UPDATE` operations on historical postings.

### 4.1 State Machine Lifecycle
Each transaction in `journal_transactions` maintains a `status`:
- `POSTED`: Active transaction currently contributing to standard user views.
- `SUPERSEDED`: Replaced by a newer version following an edit operation.
- `VOIDED`: Cancelled/deleted by the user.

```text
            [ Create ]
                │
                ▼
           ┌──────────┐
    ┌───── │  POSTED  │ ─────┐
    │      └──────────┘      │
    │ (Void)                 │ (Edit)
    ▼                        ▼
┌──────────┐          ┌────────────┐
│  VOIDED  │          │ SUPERSEDED │
└──────────┘          └────────────┘
```

### 4.2 Void / Delete Transaction Algorithm
When a user voids transaction $T_1$:
1. Assert $T_1.\text{status} == \text{'POSTED'}$. (Reject if already voided or superseded).
2. Inside `db.transaction()`:
   - Update $T_1$: set $\text{status} = \text{'VOIDED'}$.
   - Insert reversal transaction $R_1$:
     - $\text{tx\_type} = \text{'REVERSAL'}$
     - $\text{status} = \text{'POSTED'}$
     - $\text{reverses\_tx\_id} = T_1.\text{id}$
     - $\text{occurred\_at} = T_1.\text{occurred\_at}$
   - For every posting $P$ belonging to $T_1$, insert an inverted posting into $R_1$:
     - $\text{debit\_vnd} = P.\text{credit\_vnd}$
     - $\text{credit\_vnd} = P.\text{debit\_vnd}$
     - $\text{account\_id} = P.\text{account\_id}$
     - $\text{category\_id} = P.\text{category\_id}$
     - $\text{envelope\_id} = P.\text{envelope\_id}$
   - If $T_1$ had a linked movement in `envelope_movements`, insert an offsetting movement with $\text{movement\_type} = \text{'REVERSAL'}$.

### 4.3 Edit Transaction Algorithm
When a user edits transaction $T_1$ into updated command $C_{new}$:
1. Assert $T_1.\text{status} == \text{'POSTED'}$.
2. Inside `db.transaction()`:
   - Insert reversal transaction $R_1$ with inverted postings of $T_1$ (as in Void).
   - Insert new transaction $T_2$ with postings and movements from $C_{new}$ ($\text{status} = \text{'POSTED'}$).
   - Update $T_1$: set $\text{status} = \text{'SUPERSEDED'}$ and $\text{replaced\_by\_tx\_id} = T_2.\text{id}$.

### 4.4 Clean UI Query Filtering Rule
Because reversals mathematically cancel out voided and superseded transactions, queries must filter:
$$\text{WHERE } \text{status} = \text{'POSTED'} \text{ AND } \text{tx\_type} \neq \text{'REVERSAL'}$$
- In standard transaction feeds, users see only active, non-reversal transactions.
- In "Lịch sử chỉnh sửa" (Audit History) sheets, the UI follows $\text{reverses\_tx\_id}$ and $\text{replaced\_by\_tx\_id}$ to render the full chronological timeline.

---

## 5. AVAILABLE-TO-ALLOCATE & VIRTUAL FUND RULES

### 5.1 Available-to-Allocate Formula
$$\text{available\_to\_allocate} = \text{total\_liquid\_assets} - \text{total\_envelope\_reserves} - \text{minimum\_cash\_buffer\_vnd}$$
Where:
- $\text{total\_liquid\_assets}$: Sum of all balances for active accounts where $\text{is\_liquid} == \text{true}$.
- $\text{total\_envelope\_reserves} = \sum_{e \in \text{Envelopes}} e.\text{reserved\_balance\_vnd}$ (all active envelopes).
- $\text{minimum\_cash\_buffer\_vnd}$: Mandatory buffer from `settings.minimum_cash_buffer_vnd`.

### 5.2 Over-Allocation Guard
An `ALLOCATE` command is blocked if:
$$\text{amount\_vnd} > \max(0, \text{available\_to\_allocate})$$
The system throws an `OverAllocationException`.

### 5.3 Envelope Spending Deficit Guard
When an expense specifies a linked `envelope_id`:
- If $\text{amount\_vnd} \le \text{envelope.reserved\_balance\_vnd}$: Allowed.
- If $\text{amount\_vnd} > \text{envelope.reserved\_balance\_vnd}$:
  - If $\text{envelope.allow\_negative_exception} == \text{false}$: Blocked by default.
  - If the user explicitly confirms the negative exception: Allowed. The envelope balance enters negative territory, and $\text{available\_to\_allocate}$ decreases accordingly.

---

## 6. SAFE-TO-SPEND (ZERO DOUBLE-COUNTING FORMULA)

Safe-to-Spend represents the exact amount of cash a user can spend today without jeopardizing upcoming fixed bills, protected emergency reserves, or the minimum cash buffer before their next scheduled income.

### 6.1 Formula
Evaluated from `now` to `horizon_date` (the next scheduled `PLANNED_INCOME` date, or the end of the current period if none is scheduled):
$$\text{Safe-to-Spend} = \text{Liquid Assets} - \text{Protected Reserves} - \text{Unfunded Committed Outflows} - \text{Minimum Cash Buffer}$$

#### Component Definitions:
1. **`Liquid Assets`**: $\text{total\_liquid\_assets}$ (`ASSET_CASH` + `ASSET_BANK`).
2. **`Protected Reserves`**:
   $$\text{Protected Reserves} = \sum_{e \in \text{Envelopes, } e.\text{policy} = \text{PROTECTED}} \max(0, e.\text{reserved\_balance\_vnd})$$
   *(Flexible envelopes are discretionary and NOT subtracted here).*
3. **`Unfunded Committed Outflows` (Zero Double-Counting Chronological Algorithm)**:
   For all `scheduled_items` with $\text{kind} = \text{'BILL'}$ and $\text{status} = \text{'PENDING'}$ due $\le \text{horizon\_date}$:
   - For each distinct `PROTECTED` envelope, initialize:
     $$\text{remaining\_balance} = \max(0, \text{envelope.reserved\_balance\_vnd})$$
   - Iterate through pending bills sorted chronologically by $\text{due\_date\_ms}$:
     - **Case A**: Bill has no linked envelope ($\text{linked\_envelope\_id} == \text{null}$):
       $$\text{unfunded} = \text{bill.amount\_vnd}$$
     - **Case B**: Bill linked to a `PROTECTED` envelope:
       $$\text{covered} = \min(\text{bill.amount\_vnd}, \text{remaining\_balance})$$
       $$\text{unfunded} = \text{bill.amount\_vnd} - \text{covered}$$
       $$\text{remaining\_balance} -= \text{covered}$$
       *(Only the unfunded excess is added to Outflows, preventing double subtraction since the covered portion is already in Protected Reserves).*
     - **Case C**: Bill linked to a `FLEXIBLE` envelope:
       $$\text{unfunded} = \text{bill.amount\_vnd}$$
       *(Because flexible envelopes were not subtracted in Protected Reserves).*
   - Total `Unfunded Committed Outflows` is the sum of all $\text{unfunded}$ portions.
4. **`Minimum Cash Buffer`**: `settings.minimum_cash_buffer_vnd`.

### 6.2 Negative Safe-to-Spend Handling
- **Never Clamp to Zero**: If the sum of reserves, unfunded bills, and buffer exceeds liquid assets, $\text{Safe-to-Spend}$ returns an exact negative integer (e.g., `-1.500.000 ₫`).
- **Deficit Breakdown**: The UI displays the exact negative amount in red (`AppColors.textAccentRubyPrimary`) and provides a breakdown modal detailing the exact contributing factors.
- **Daily Discretionary Allowance**:
  - When $\text{Safe-to-Spend} > 0$:
    $$\text{daily\_allowance} = \text{Safe-to-Spend} \mathbin{\sim/} \max(1, \text{days\_remaining})$$
  - When $\text{Safe-to-Spend} \le 0$:
    $$\text{daily\_allowance} = 0 \text{ ₫/ngày}$$

---

## 7. CATEGORY SPENDING, REFUNDS & SAVINGS RATE

For any reporting interval $[start\_ms, end\_ms)$:
- $\text{gross\_expense} = \sum \text{debit\_vnd on EXPENSE accounts}$
- $\text{refund\_credits} = \sum \text{credit\_vnd on EXPENSE accounts}$
- $\text{net\_expense} = \text{gross\_expense} - \text{refund\_credits}$
- $\text{recognized\_income} = \sum (\text{credit\_vnd} - \text{debit\_vnd}) \text{ on INCOME accounts}$
- $\text{net\_saving} = \text{recognized\_income} - \text{net\_expense}$

### 7.1 Net Recovery Handling
If refunds in a period exceed gross expenses ($\text{net\_expense} < 0$), the category is marked as **"Thu hồi chi phí ròng"** (Net Recovery). For savings rate calculation:
$$\text{effective\_expense} = \max(0, \text{net\_expense})$$

### 7.2 Savings Rate Calculation
- If $\text{recognized\_income} \le 0$:
  $$\text{saving\_rate} = \text{null}$$
  UI renders `"Chưa có thu nhập"` (never displays `NaN`, `-Infinity`, or `0%`).
- If $\text{recognized\_income} > 0$:
  $$\text{saving\_rate} = \frac{\text{recognized\_income} - \max(0, \text{net\_expense})}{\text{recognized\_income}}$$

---

## 8. SAVINGS GOALS & FEASIBILITY ADVISOR

### 8.1 Ceiling Integer Division Math
For a savings goal backed by an envelope with target $T$, current reserved balance $C$, and $N$ remaining budgeting periods:
- If $C \ge T$: Status is `ACHIEVED`, $\text{required\_per\_period} = 0$.
- If $N \le 0$ and $C < T$: Status is `OVERDUE`, $\text{shortfall} = T - C$ (no division by zero).
- If $N > 0$ and $C < T$:
  $$\text{required\_per\_period} = ((T - C) + N - 1) \mathbin{\sim/} N$$
  Using ceiling integer division guarantees that the user reaches their exact target by period $N$, with the final period absorbing the exact non-divisible remainder.

### 8.2 Feasibility Advisor Engine
If $\sum \text{required\_per\_period of all active goals} > \text{available\_to\_allocate}$ (or average monthly $\text{net\_saving}$):
- Status is flagged as `INFEASIBLE`.
- The UI displays 3 one-tap calculators:
  1. **Extend Deadline**: New required periods $N' = \lceil (T - C) / \text{monthly\_capacity} \rceil$.
  2. **Lower Target**: New achievable target $T' = C + N \times \text{monthly\_capacity}$.
  3. **Pause Goals**: Rank goals by `priority`, fund highest-priority goals first, and recommend pausing remaining goals.

---

## 9. MONTH-END RECURRENCE & CASH FLOW FORECAST

### 9.1 Drift-Free Month-End Recurrence
When generating the next recurrence of a monthly scheduled item anchored on day $d \in \{1 \dots 31\}$ for target year $Y$ and month $M$:
$$\text{actual\_due\_day} = \min(\text{anchor\_day\_of\_month}, \text{daysInMonth}(Y, M))$$
- A bill anchored to day 31 evaluated in February (28 days) produces February 28.
- Evaluated in February of a leap year (29 days) produces February 29.
- In March (31 days), it automatically schedules on March 31 without anchor degradation.

### 9.2 Obligation Conversion
When marking a `scheduled_item` as paid:
1. Insert real `journal_transaction` (`tx_type = EXPENSE` or `INCOME`, `paid_transaction_id = tx.id`).
2. Update `scheduled_item`: set $\text{status} = \text{'PAID\_OR\_RECEIVED'}$.
3. Advance next recurrence instance. Paid items are excluded from future forecast outflows.

### 9.3 30/60/90-Day Cash Flow Forecast Engine
- Starting balance: $\text{Balance}_0 = \text{total\_liquid\_assets}$.
- Day $k$ balance:
  $$\text{Balance}_k = \text{Balance}_{k-1} + \sum \text{PLANNED\_INCOME}_k - \sum \text{PENDING\_BILL}_k$$
- Date warning: If $\text{Balance}_k < \text{minimum\_cash\_buffer\_vnd}$, flag day $k$ with an alert indicator and show the projected deficit.

---

## 10. SECURITY & ENCRYPTED BACKUP ARCHITECTURE

### 10.1 Android Hardening
- `android:allowBackup="false"` prevents unencrypted cloud backups.
- `res/xml/data_extraction_rules.xml` excludes SQLite databases from device-to-device transfers.

### 10.2 Off-Main-Thread Authenticated Encryption (`Isolate.run`)
Heavy PBKDF2 key derivation (120,000 iterations) takes 300–800ms and must run off the UI thread:
```dart
final String encryptedJson = await Isolate.run(() async {
  // 1. Generate 16-byte secure random salt
  // 2. Generate 12-byte secure random nonce
  // 3. Derive 256-bit key via Pbkdf2(Hmac.sha256(), iterations: 120000)
  // 4. Encrypt via AesGcm.with256Bits() producing ciphertext & 16-byte MAC tag
  // 5. Serialize outer JSON envelope
});
```

### 10.3 Outer JSON Envelope Format
```json
{
  "magic": "DONGTIEN_ENC_V1",
  "formatVersion": 1,
  "schemaVersion": 1,
  "createdAtIso": "2026-10-27T10:15:00+07:00",
  "kdf": "PBKDF2-HMAC-SHA256",
  "kdfIterations": 120000,
  "saltB64": "vF3+9xL0pQ1kM8...",
  "cipher": "AES-256-GCM",
  "nonceB64": "k7Lm9P4qR1sT...",
  "ciphertextB64": "x9J2kL8mP0...",
  "macB64": "w3Er5Ty7Ui9O..."
}
```

### 10.4 The 6-Stage Validation & Restore Pipeline
```text
[ Stage 1: File Size Check ]
  └─ If file.length > 25 MB ──> Throw BackupSizeExceededException
           │
           ▼
[ Stage 2: Outer JSON Header & Magic Check ]
  └─ If "magic" != "DONGTIEN_ENC_V1" or iterations < 100000 ──> Throw InvalidBackupFormatException
           │
           ▼
[ Stage 3: Off-Main-Thread Decryption (Isolate.run) ]
  ├─ Derive PBKDF2 key from password + saltB64
  ├─ Decrypt ciphertextB64 with nonceB64 & authenticate with macB64
  └─ If wrong password or tampered byte ──> SecretBoxAuthenticationError ──> Throw InvalidCredentialsException
           │
           ▼
[ Stage 4: In-Memory Structural Invariant Validation ]
  ├─ Verify all 9 tables exist in decrypted JSON
  ├─ Invariant A: For every transaction, SUM(debit_vnd) == SUM(credit_vnd)
  ├─ Invariant B: All foreign keys resolve to valid entities
  ├─ Invariant C: All monetary amounts are integers >= 0
  └─ If any invariant fails ──> Throw BackupCorruptException (SQLite untouched)
           │
           ▼
[ Stage 5: User Confirmation Dialog ]
  ├─ Display: createdAtIso, counts of accounts, transactions, envelopes, budgets
  └─ Confirmation: "Khôi phục sẽ thay thế dữ liệu hiện tại." -> Cancel or Confirm
           │
           ▼
[ Stage 6: Atomic Database Restore (Single db.transaction) ]
  ├─ Clear existing tables in reverse dependency order
  ├─ Insert validated records in topological order
  └─ If any SQL error occurs ──> Transaction rolls back completely (data intact)
```

---

## 11. ARCHITECTURE DECISION RECORDS (ADRS)

### ADR-001: 64-Bit Integer VND (`VndMoney`) vs Floating-Point
- **Context**: In financial software, IEEE 754 floating-point representations (`double`) accumulate binary rounding errors (e.g., `0.1 + 0.2 = 0.30000000000000004`). In Vietnam, currency is exclusively integer VND with zero decimals.
- **Decision**: Store all amounts as 64-bit signed integers (`int` in whole VND). Guard against overflow with `max_Safe_VND = 9_000_000_000_000_000`.
- **Consequences**: Exact arithmetic across all ledger transactions. Zero rounding discrepancies. Safe JSON serialization.

### ADR-002: Decoupled Double-Entry General Ledger and Virtual Fund Envelopes
- **Context**: Many budgeting apps create synthetic bank transactions when users allocate money to virtual funds, distorting real-world financial balances and reports.
- **Decision**: Decouple the double-entry general ledger from virtual funds. Envelopes represent conceptual cash reservations. Allocations and transfers generate zero journal postings.
- **Consequences**: Real accounting balances remain 100% faithful to actual bank and cash balances. Virtual funds provide budgeting control without ledger pollution.

### ADR-003: Dynamically Derived Account Balances vs Stored Running Balances
- **Context**: Storing mutable running balances on accounts requires synchronization across edits, voids, and reversals, creating race conditions.
- **Decision**: Never store mutable cached balances on `ledger_accounts`. Derive balances dynamically using SQL aggregation over all postings.
- **Consequences**: Absolute consistency. Edits and voids automatically reflect in account balances via reversals.

### ADR-004: Audit-Preserving Immutable Reversal Engine vs Destructive Updates
- **Context**: Destructive SQL `DELETE` or `UPDATE` operations destroy historical evidence and make audit tracking impossible.
- **Decision**: Implement an audit-preserving engine with `POSTED`, `SUPERSEDED`, and `VOIDED` states. Voiding or editing inserts a balancing `REVERSAL` transaction. Standard UI views filter `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`.
- **Consequences**: Permanent audit trail preserved while delivering a clean, clutter-free user interface.

### ADR-005: Zero Double-Counting Chronological Safe-to-Spend Allocation
- **Context**: If both a protected envelope reserve and an upcoming pending bill are subtracted, the same obligation is subtracted twice.
- **Decision**: Chronologically allocate protected envelope balances to cover linked pending bills. Only the unfunded excess of the bill is added to `Unfunded Committed Outflows`.
- **Consequences**: Eliminates double counting mathematically, providing an accurate discretionary spending figure.

### ADR-006: Inexact Alarms (`inexactAllowWhileIdle`) for Google Play Compliance
- **Context**: Android 12–15+ heavily restricts `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`, rejecting apps that do not meet strict calendar/alarm clock criteria.
- **Decision**: Declare only `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`. Schedule reminders using `AndroidScheduleMode.inexactAllowWhileIdle`.
- **Consequences**: Full Google Play compliance, battery friendliness during Doze mode, and zero risk of store policy rejections.

### ADR-007: Isolate-Based Authenticated PBKDF2 + AES-GCM Backup vs SQLCipher
- **Context**: SQLCipher introduces heavy native NDK binaries that frequently break Android Gradle builds, while unencrypted SQLite backups expose personal financial data.
- **Decision**: Use standard SQLite (`drift_flutter` + `sqlite3_flutter_libs`) for rock-solid local persistence, combined with off-main-thread authenticated encrypted backup exports via `Isolate.run`, `PBKDF2-HMAC-SHA256` (120,000 iterations), and `AES-256-GCM`.
- **Consequences**: Flawless compilation on all Android targets, 60fps UI smoothness, and military-grade authenticated backup privacy.
