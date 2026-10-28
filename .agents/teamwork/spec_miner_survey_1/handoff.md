# Financial Domain & Persistence Layer Specification Report

**Agent**: `spec_miner_survey_1`  
**Role**: Financial Spec & Invariant Miner  
**Target Path**: `c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_1\handoff.md`  
**Authoritative Sources**:  
- `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md`
- `c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md`

---

## Features Discovered

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | Monetary Representation | `VndMoney` integer type | Value type representing whole Vietnamese Dong (VND) without floating-point inaccuracies | 64-bit integer (`int`), amount in whole VND | Formatted VND string, mathematical operations | Throws on negative input when strictly positive expected, throws on overflow exceeding `max_Safe_VND` | `build_spec.md` §4.1, `ORIGINAL_REQUEST.md` R2 |
| 2 | Monetary Representation | 64-bit Overflow Guard | Prevents integer wrapping on large aggregate calculations (`max_Safe_VND = 9_000_000_000_000_000`) | Integer amounts | Validated `VndMoney` | Throws `VndOverflowException` if value exceeds 9 quadrillion VND | `build_spec.md` §4.1 |
| 3 | Monetary Representation | `vi_VN` Currency Formatter | Formats whole VND with dot thousand separators and currency symbol (`1.250.000 ₫`) using tabular numerals | Integer amount, optional sign indicator | Formatted string `X.XXX.XXX ₫`, `FontFeature.tabularFigures()` | Handles 0 as `0 ₫`, handles negative as `-1.250.000 ₫` | `build_spec.md` §4.1, §6.1 |
| 4 | Persistence / Schema | `ledger_accounts` table | Stores chart of accounts (Cash, Bank, Credit Card, Income, Expense, Opening Equity) | Account fields: `id`, `name`, `kind`, `is_liquid`, `credit_limit`, `is_archived`, `created_at` | Row ID | Rejects invalid kinds; `is_liquid` constrained to `ASSET_CASH` and `ASSET_BANK` | `build_spec.md` §4.2 |
| 5 | Persistence / Schema | `categories` table | User and default classification of income and expenses linked to ledger accounts | Category fields: `id`, `name`, `kind`, `ledger_account_id`, `icon_code`, `color_hex`, `is_default`, `is_archived` | Row ID | FK violation if `ledger_account_id` not found | `build_spec.md` §4.2 |
| 6 | Persistence / Schema | `journal_transactions` table | Journal entries recording financial events with audit states and reversal pointers | Transaction fields: `id`, `tx_type`, `status`, `description`, `occurred_at`, `created_at`, `idempotency_key`, `reverses_tx_id`, `replaced_by_tx_id` | Row ID | Unique constraint on `idempotency_key`; FK checks on reversal/replacement | `build_spec.md` §4.2 |
| 7 | Persistence / Schema | `journal_postings` table | Double-entry line items for transactions; sum of debits must equal sum of credits | Posting fields: `id`, `transaction_id`, `account_id`, `debit_vnd`, `credit_vnd`, `category_id`, `envelope_id` | Row ID | Check constraint `(debit > 0 && credit == 0) \|\| (credit > 0 && debit == 0)`; FK checks | `build_spec.md` §4.2 |
| 8 | Persistence / Schema | `envelopes` table | Virtual fund envelopes (Protected and Flexible) holding conceptual cash reserves | Envelope fields: `id`, `name`, `policy`, `reserved_balance_vnd`, `allow_negative_exception`, `target_amount_vnd`, `target_date_ms`, `period_limit_vnd`, `rollover_enabled`, `priority`, `is_archived` | Row ID | Enforces non-negative balance unless `allow_negative_exception == true` | `build_spec.md` §4.2 |
| 9 | Persistence / Schema | `envelope_movements` table | Audit log of all virtual fund reserve changes (allocation, release, spend, refund restore) | Movement fields: `id`, `movement_type`, `amount_vnd`, `source_envelope_id`, `dest_envelope_id`, `linked_transaction_id`, `linked_obligation_id`, `occurred_at` | Row ID | FK violations if envelope/tx missing; `amount_vnd > 0` | `build_spec.md` §4.2 |
| 10 | Persistence / Schema | `category_budgets` table | Monthly spending caps per expense category with alert threshold | Budget fields: `id`, `category_id`, `year_month`, `limit_vnd`, `alert_threshold_pct` | Row ID | Unique index on `(category_id, year_month)`; FK check | `build_spec.md` §4.2 |
| 11 | Persistence / Schema | `scheduled_items` table | Recurring and one-time bills and planned income with anchor day | Scheduled fields: `id`, `kind`, `title`, `amount_vnd`, `due_date_ms`, `recurrence`, `anchor_day_of_month`, `category_id`, `linked_envelope_id`, `status`, `paid_transaction_id`, `reminder_days_before` | Row ID | FK checks on envelope/tx; `anchor_day_of_month` in 1..31 | `build_spec.md` §4.2 |
| 12 | Persistence / Schema | `settings` table | Application-wide singleton settings row (`id = 1`) | Settings fields: `id`, `minimum_cash_buffer_vnd`, `period_start_day`, `daily_reminder_hour`, `daily_reminder_minute`, `notifications_enabled`, `schema_version` | Row ID | Single row restriction (`id = 1`) | `build_spec.md` §4.2 |
| 13 | Persistence / Schema | Foreign Keys Enforcement | Enables relational integrity and prevents orphaned records | `PRAGMA foreign_keys = ON;` in `beforeOpen` | SQLite FK enforcement active | Aborts transactions violating FK or CASCADE rules | `build_spec.md` §4.2, `ORIGINAL_REQUEST.md` R2 |
| 14 | Persistence / Seeding | Default Vietnamese Seed Data | Seeds standard Vietnamese categories and system ledger accounts on first run | Initial startup | 8 default categories (`Ăn uống`, `Di chuyển`, `Hoá đơn & Tiện ích`, `Nhà cửa`, `Mua sắm`, `Y tế`, `Lương`, `Thưởng`), `EQUITY_OPENING` account | Idempotent: runs only if DB empty; zero fake transactions | `build_spec.md` §4.2, §6.1 |
| 15 | Double-Entry Posting | `OPENING_BALANCE` Posting | Initializes liquid asset balances or credit card liabilities against opening equity | Amount, Asset Account or Credit Card Account, date | 2 balanced postings (`Debit Asset / Credit Equity` or `Debit Equity / Credit Card Liability`) | Throws if debit != credit or amount <= 0 | `build_spec.md` §4.3 |
| 16 | Double-Entry Posting | `INCOME` Posting | Records earnings (salary, bonus) into liquid accounts | Amount, Receiving Asset Account, Income Category, date | 2 balanced postings (`Debit Asset / Credit Income`) | Throws if non-liquid account used as receiving asset | `build_spec.md` §4.3 |
| 17 | Double-Entry Posting | `EXPENSE` (Cash/Bank) Posting | Records cash/bank spending with optional envelope deduction | Amount, Paying Liquid Account, Expense Category, optional `envelope_id` | 2 balanced postings (`Debit Expense / Credit Asset`) + atomic `SPEND` movement if envelope attached | Throws if paying account is not liquid | `build_spec.md` §4.3 |
| 18 | Double-Entry Posting | `EXPENSE` (Credit Card) Posting | Records credit card spending with liability accumulation and optional envelope deduction | Amount, Credit Card Liability Account, Expense Category, optional `envelope_id` | 2 balanced postings (`Debit Expense / Credit Card Liability`) + atomic `SPEND` movement if envelope attached | Liquid assets remain untouched; card liability increases | `build_spec.md` §4.3 |
| 19 | Double-Entry Posting | `CREDIT_CARD_PAYMENT` Posting | Settles credit card debt using liquid funds; never recognized as an expense | Amount, Source Liquid Account, Target Credit Card Account | 2 balanced postings (`Debit Card Liability / Credit Asset`) | Throws if source is not liquid asset or dest is not card liability | `build_spec.md` §4.3 |
| 20 | Double-Entry Posting | `INTERNAL_TRANSFER` Posting | Transfers liquid funds between cash and bank accounts | Amount, Source Asset Account, Destination Asset Account | 2 balanced postings (`Debit Dest Asset / Credit Source Asset`) | Total liquid assets and income/expense unchanged | `build_spec.md` §4.3 |
| 21 | Double-Entry Posting | `REFUND` Posting | Records return of funds for a prior purchase, decreasing net expense | Amount, Receiving Account, Expense Category, optional `envelope_id` | 2 balanced postings (`Debit Asset or Liability / Credit Expense`) + optional `REFUND_RESTORE` movement | Decreases gross expense / net expense; never creates operating income | `build_spec.md` §4.3 |
| 22 | Double-Entry Posting | Transaction Invariant Check | Verifies double-entry equation `SUM(debit_vnd) == SUM(credit_vnd)` before commit | All postings for transaction | Commit approval or transaction rollback | Throws `UnbalancedTransactionException` and aborts DB transaction | `build_spec.md` §4.3 |
| 23 | Envelope Engine | Envelope `ALLOCATE` | Allocates available liquid cash into an envelope reserve | `dest_envelope_id`, `amount_vnd` | `envelope_movements` row (`type = ALLOCATE`), increases `reserved_balance_vnd` | Throws if `amount > available_to_allocate` | `build_spec.md` §4.3, §5.1 |
| 24 | Envelope Engine | Envelope `RELEASE` | Releases reserved money from an envelope back to unallocated cash | `source_envelope_id`, `amount_vnd` | `envelope_movements` row (`type = RELEASE`), decreases `reserved_balance_vnd` | Throws if `amount > reserved_balance_vnd` (unless negative exception confirmed) | `build_spec.md` §4.3 |
| 25 | Envelope Engine | Envelope `TRANSFER` | Shifts reserved funds directly from one envelope to another | `source_envelope_id`, `dest_envelope_id`, `amount_vnd` | `envelope_movements` row (`type = TRANSFER`), adjusts both envelopes | Throws if `amount > source.reserved_balance_vnd` | `build_spec.md` §4.3 |
| 26 | Envelope Engine | Envelope `SPEND` Linkage | Atomically deducts envelope reserve when linked to an expense transaction | `envelope_id`, expense transaction | `envelope_movements` row (`type = SPEND`, `linked_transaction_id`) | Blocks if amount > balance unless `allow_negative_exception == true` | `build_spec.md` §4.3, §5.1 |
| 27 | Envelope Engine | Envelope `REFUND_RESTORE` | Atomically restores reserve to an envelope when refund is processed | `envelope_id`, refund transaction | `envelope_movements` row (`type = REFUND_RESTORE`, `linked_transaction_id`) | Increases envelope `reserved_balance_vnd` | `build_spec.md` §4.3 |
| 28 | Dynamic Balance | Dynamic Account Balance Derivation | Dynamically calculates ledger balances from postings without mutable state | Account ID | Current balance: `Debit - Credit` (Asset/Expense) or `Credit - Debit` (Liability/Income/Equity) | Automatically offsets voided/superseded transactions via reversals | `build_spec.md` §4.4 |
| 29 | Dynamic Balance | Liquid Assets Derivation | Sums balances of accounts where `kind IN (ASSET_CASH, ASSET_BANK)` and `is_liquid == true` | Current postings | `total_liquid_assets` | Excludes credit limits and credit card balances | `build_spec.md` §5.1 |
| 30 | Reversal & Edit | Transaction Void / Delete | Voids transaction immutably by posting inverted entries and offsetting movements | Target `transaction_id` | Target marked `VOIDED`, `REVERSAL` transaction inserted, offsetting envelope movement inserted | Throws if target is not `POSTED` | `build_spec.md` §4.5 |
| 31 | Reversal & Edit | Transaction Edit | Immutably supersedes transaction with a reversal and replacement transaction | Target `transaction_id`, edited transaction data | Target marked `SUPERSEDED`, `REVERSAL` created, new `POSTED` transaction linked via `replaced_by_tx_id` | Throws if target is not `POSTED` | `build_spec.md` §4.5 |
| 32 | Reversal & Edit | Clean UI Filtering | Hides superseded and reversal noise from standard transaction lists | UI query filters | Returns transactions `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'` | Preserves clean view while keeping database mathematically complete | `build_spec.md` §4.5 |
| 33 | Reversal & Edit | Audit Trail History | Provides complete timeline of changes for any edited or voided transaction | Transaction ID | Ordered list of `(Original, Reversal, Replacement)` with diffs | Displays in "Lịch sử chỉnh sửa" bottom sheet | `build_spec.md` §4.5 |
| 34 | Deterministic Math | Available-to-Allocate | Calculates unallocated liquid cash available for reserve creation | `total_liquid_assets`, `total_envelope_reserves`, `minimum_cash_buffer_vnd` | `available_to_allocate` integer | Blocks allocations exceeding this value | `build_spec.md` §5.1 |
| 35 | Deterministic Math | Category Net Expense | Computes true expense after deducting refunds within date range | `start_ms`, `end_ms`, category ID | `gross_expense`, `refund_credits`, `net_expense` | If `net_expense < 0`, flagged as "Thu hồi chi phí ròng" | `build_spec.md` §5.2 |
| 36 | Deterministic Math | Savings Rate | Computes percentage of recognized income saved | `recognized_income`, `net_expense` | `saving_rate` double or null | Returns `null` ("Chưa có thu nhập") if `recognized_income <= 0`, clamps `effective_expense = max(0, net_expense)` | `build_spec.md` §5.2 |
| 37 | Deterministic Math | Safe-to-Spend Calculator | Computes uncommitted cash safe for discretionary spending until horizon | Liquid assets, protected envelopes, pending bills, horizon date, minimum buffer | `Safe-to-Spend` integer, daily discretionary allowance | Never clamps to 0; provides shortfall breakdown if negative | `build_spec.md` §5.3 |
| 38 | Deterministic Math | Zero Double-Counting Allocation | Allocates protected envelope reserves to linked pending bills chronologically | Linked bills, protected envelope balance | Unfunded bill excess for each bill | Only unfunded portion added to `Unfunded Committed Outflows` | `build_spec.md` §5.3 |
| 39 | Deterministic Math | Savings Goal Ceiling Division | Calculates periodic contribution required to achieve goal by target date | Target $T$, Current $C$, Periods remaining $N$ | `required_per_period = ((T - C) + N - 1) ~/ N` | Handles $N \le 0$ as `OVERDUE`, $C \ge T$ as `ACHIEVED` | `build_spec.md` §5.4 |
| 40 | Deterministic Math | Feasibility Advisor | Detects when total goal commitments exceed monthly capacity and proposes solutions | Required contributions, monthly savings capacity | Status `FEASIBLE` or `INFEASIBLE`, 3 one-tap calculator options | Proposes: extend deadline, lower target, or pause low-priority goals | `build_spec.md` §5.4 |
| 41 | Deterministic Math | Drift-Free Month-End Recurrence | Computes recurrence dates anchored to day 29, 30, or 31 without February drift | `anchor_day_of_month` (1..31), Target Year $Y$, Month $M$ | `actual_due_day = min(anchor_day, daysInMonth(Y, M))` | Jan 31 -> Feb 28/29 -> Mar 31 without losing anchor | `build_spec.md` §5.5 |
| 42 | Deterministic Math | 30/60/90-Day Cash Flow Forecast | Projects day-by-day liquid balances with pending obligations and planned income | Current liquid assets, pending bills, planned income, horizon days | List of daily projected closing balances, buffer breach flags | Highlights date where projected cash < minimum buffer | `build_spec.md` §5.5 |
| 43 | Deterministic Math | Idempotency Key Guard | Rejects duplicate transaction submissions caused by rapid UI taps | `idempotency_key` string | First succeeds; second is rejected / ignored | Returns existing transaction without creating duplicate postings | `build_spec.md` §4.2, §8 (#10) |
| 44 | Persistence / Lifecycle | Paid Obligation Conversion | Converts scheduled bill/income into posted transaction when marked paid | `scheduled_item_id`, account ID, date | Posted `EXPENSE` or `INCOME` tx, `scheduled_item.status = PAID_OR_RECEIVED`, next recurrence created | Eliminates double-counting in cash flow forecast | `build_spec.md` §5.5 |

---

## Edge Cases

| # | Feature | Input | Observed Behavior |
|---|---------|-------|-------------------|
| 1 | Monetary Representation | Negative amount input on transaction entry (e.g. `-50.000 ₫`) | Rejected immediately at domain validation layer before database write (`amount > 0` required). |
| 2 | Monetary Representation | Cumulative total exceeding `9_000_000_000_000_000 ₫` | Overflow guard triggers `VndOverflowException` before 64-bit integer bit-wrap occurs. |
| 3 | Monetary Representation | Zero VND amount transaction (e.g. `0 ₫`) | Blocked by entry command validator (`amount > 0`). |
| 4 | Monetary Representation | Decimal input (e.g. `12.5 ₫` or `150.75 ₫`) | VndMoney enforces integer whole VND only; UI custom numeric pad disallows decimal point key. |
| 5 | Double-Entry Posting | Unbalanced transaction postings (`SUM(debit) != SUM(credit)`) | Throws `UnbalancedTransactionException` inside `db.transaction()` and rolls back entirely. |
| 6 | Double-Entry Posting | Line item with both debit and credit > 0 | SQLite table check constraint `(debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0)` aborts row insertion. |
| 7 | Double-Entry Posting | Line item with both debit and credit == 0 | SQLite table check constraint rejects row insertion. |
| 8 | Double-Entry Posting | Credit card payment posted as expense | Architectural invariant violation: credit card payment must be Debit Liability / Credit Asset; expense account is never touched. |
| 9 | Envelope Allocation | Allocation amount > `available_to_allocate` | Allocation command throws `OverAllocationException`; database remains unchanged. |
| 10 | Envelope Spending | Spending amount > envelope reserve balance with `allow_negative_exception == false` | Spending command blocks transaction; UI prompts user to transfer funds or confirm exception. |
| 11 | Envelope Spending | Spending amount > envelope reserve balance with `allow_negative_exception == true` confirmed | Allows envelope `reserved_balance_vnd` to drop into deficit; `available_to_allocate` decreases accordingly. |
| 12 | Savings Rate Calculation | Zero recognized income (`recognized_income == 0`) with expenses > 0 | Formula yields `null`; UI displays `"Chưa có thu nhập"` (never displays `NaN`, `-Infinity`, or `0%`). |
| 13 | Savings Rate Calculation | Negative recognized income (`recognized_income < 0`) due to income adjustments | Formula yields `null`; UI displays `"Chưa có thu nhập"`. |
| 14 | Net Expense Calculation | Refunds in period exceed gross expenses (`net_expense < 0`) | `net_expense` displays in cyan/green as `"Thu hồi chi phí ròng"`; `effective_expense` clamps to 0 for savings rate formula. |
| 15 | Safe-to-Spend Calculation | Protected envelope balance > total of all linked pending bills | Surplus protected reserve remains in `Protected Reserves`; unfunded outflow for linked bills is `0 ₫`; zero double subtraction. |
| 16 | Safe-to-Spend Calculation | Protected envelope balance < total of linked bills (partially funded) | Envelope balance applied chronologically to earlier bills; only unfunded remainder of later bills added to `Unfunded Committed Outflows`. |
| 17 | Safe-to-Spend Calculation | Bill linked to a `FLEXIBLE` envelope | Flexible envelopes are discretionary (not subtracted in Protected Reserves); therefore full bill amount is added to Unfunded Outflows. |
| 18 | Safe-to-Spend Calculation | Total reserves + unfunded bills + buffer exceed liquid assets | `Safe-to-Spend` returns negative integer (e.g. `-1.500.000 ₫`); never clamped to 0; daily allowance displays `0 ₫/ngày`; deficit breakdown rendered. |
| 19 | Savings Goal Math | Target already achieved ($C \ge T$) | Status evaluates to `ACHIEVED`; `required_per_period = 0`. |
| 20 | Savings Goal Math | Deadline passed and target unreached ($N \le 0$ and $C < T$) | Status evaluates to `OVERDUE`; `shortfall = T - C`; no division by zero. |
| 21 | Savings Goal Math | Non-divisible target remainder (e.g. 10.000.000 ₫ over 3 periods = 3.333.333,33 ₫) | Ceiling integer division `((T - C) + N - 1) ~/ N` yields 3.333.334 ₫ for periods 1 and 2, and 3.333.332 ₫ for period 3, guaranteeing goal met by deadline. |
| 22 | Month-End Recurrence | Monthly bill on anchor day 31 evaluated in February (non-leap year, 28 days) | `min(31, 28)` generates due date February 28; next period evaluation in March uses `min(31, 31)` returning to March 31 without anchor degradation. |
| 23 | Month-End Recurrence | Monthly bill on anchor day 31 evaluated in February (leap year, 29 days) | `min(31, 29)` generates due date February 29; returns to March 31 in next cycle. |
| 24 | Month-End Recurrence | Monthly bill on anchor day 30 evaluated in February | `min(30, 28)` generates February 28; returns to March 30 in next cycle. |
| 25 | Cash Flow Forecast | Forecast date where liquid balance falls below `minimum_cash_buffer_vnd` | Daily closing balance marked with warning flag; UI highlights date in red/amber with projected deficit. |
| 26 | Reversal & Edit Engine | Attempting to void or edit a transaction that is already `VOIDED` or `SUPERSEDED` | Command rejected; only transactions with `status == POSTED` can be voided or edited. |
| 27 | Reversal & Edit Engine | Voiding an expense transaction that was linked to an envelope | Generates reversing journal transaction AND reversing `envelope_movements` row (`type = REVERSAL`), restoring envelope balance. |
| 28 | Idempotency Key Guard | Rapid double-tap of submit button sending identical `idempotency_key` | Database unique constraint or repository check intercepts second call; returns existing transaction without duplicate postings. |
| 29 | Scheduled Item Paid | Marking scheduled bill paid generates posted transaction | Scheduled item status becomes `PAID_OR_RECEIVED`, `paid_transaction_id` points to new transaction; bill excluded from future pending forecast. |
| 30 | Database Deletion Guard | Attempting to delete a ledger account referenced in postings | SQLite foreign key constraint blocks deletion unless accounts are archived (`is_archived = true`). |

---

## Detailed Financial Domain & Persistence Specification

### 1. Monetary Representation
- **Value Type**: `VndMoney`
- **Underlying Representation**: 64-bit signed integer (`int`) in Dart representing whole Vietnamese Dong (`VND`).
- **Precision**: 0 decimal places. No fractional currency exists in the modern Vietnamese economy (hào/xu are obsolete).
- **Overflow Prevention Invariant**:
  $$\text{max\_Safe\_VND} = 9\,000\,000\,000\,000\,000 \quad (9 \text{ quadrillion VND})$$
  Any addition, multiplication, or aggregation exceeding `max_Safe_VND` throws a `VndOverflowException`. This guarantees arithmetic safety well below signed 64-bit integer limit ($2^{63}-1 \approx 9.22 \times 10^{18}$) and avoids any IEEE 754 precision loss when serialized to standard 64-bit JSON numbers.
- **Validation**:
  - Entry commands enforce `amount > 0`.
  - Non-negative balances enforce `amount >= 0` (unless envelope exception confirmed).
- **Formatting Specification (`vi_VN`)**:
  - Number format: Thousands grouped by dot (`.`).
  - Suffix: Space followed by currency symbol (`₫`).
  - Example: `1.250.000 ₫`, `0 ₫`, `-500.000 ₫`.
  - Typography: Must use `FontFeature.tabularFigures()` on all monetary amounts in Flutter UI to prevent layout jitter during dynamic updates.

---

### 2. Drift Database Schema Specification

The database utilizes SQLite via Drift with `PRAGMA foreign_keys = ON;` executed in `MigrationStrategy.beforeOpen`.

#### Table 1: `ledger_accounts`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, AutoIncrement | Internal account identifier |
| `name` | Text | NOT NULL | Human-readable account name (e.g. "Tiền mặt", "Vietcombank") |
| `kind` | Text | NOT NULL | Enum: `ASSET_CASH`, `ASSET_BANK`, `LIABILITY_CREDIT_CARD`, `INCOME`, `EXPENSE`, `EQUITY_OPENING` |
| `is_liquid` | Bool | NOT NULL, DEFAULT false | Invariant: `true` ONLY if `kind IN ('ASSET_CASH', 'ASSET_BANK')` |
| `credit_limit` | Int | NOT NULL, DEFAULT 0 | Informational credit limit for cards (whole VND) |
| `is_archived` | Bool | NOT NULL, DEFAULT false | Soft deletion flag |
| `created_at` | Int | NOT NULL | Milliseconds since Unix epoch |

#### Table 2: `categories`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, AutoIncrement | Internal category identifier |
| `name` | Text | NOT NULL | Name (e.g. "Ăn uống", "Lương") |
| `kind` | Text | NOT NULL | Enum: `INCOME`, `EXPENSE` |
| `ledger_account_id` | Int | NOT NULL, FK -> `ledger_accounts.id` | Backing general ledger account |
| `icon_code` | Int | NOT NULL | Material icon code point |
| `color_hex` | Text | NOT NULL | Hex color string (e.g. `#FF5722`) |
| `is_default` | Bool | NOT NULL, DEFAULT false | Whether seeded as system default |
| `is_archived` | Bool | NOT NULL, DEFAULT false | Soft deletion flag |

#### Table 3: `journal_transactions`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, AutoIncrement | Internal transaction identifier |
| `tx_type` | Text | NOT NULL | Enum: `OPENING_BALANCE`, `INCOME`, `EXPENSE`, `TRANSFER`, `CREDIT_CARD_PAYMENT`, `REFUND`, `REVERSAL` |
| `status` | Text | NOT NULL, DEFAULT 'POSTED' | Enum: `POSTED`, `SUPERSEDED`, `VOIDED` |
| `description` | Text | NOT NULL | Memo or notes |
| `occurred_at` | Int | NOT NULL | Transaction timestamp (epoch ms) |
| `created_at` | Int | NOT NULL | Record creation timestamp (epoch ms) |
| `idempotency_key` | Text | NULLABLE, UNIQUE | Client UUID for duplicate submission guard |
| `reverses_tx_id` | Int | NULLABLE, FK -> `journal_transactions.id` | If REVERSAL, points to target tx |
| `replaced_by_tx_id` | Int | NULLABLE, FK -> `journal_transactions.id` | If SUPERSEDED, points to new tx |

#### Table 4: `journal_postings`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, AutoIncrement | Internal line item identifier |
| `transaction_id` | Int | NOT NULL, FK -> `journal_transactions.id` ON DELETE CASCADE | Parent transaction |
| `account_id` | Int | NOT NULL, FK -> `ledger_accounts.id` | Affected account |
| `debit_vnd` | Int | NOT NULL, DEFAULT 0, CHECK (`debit_vnd >= 0`) | Debit amount in whole VND |
| `credit_vnd` | Int | NOT NULL, DEFAULT 0, CHECK (`credit_vnd >= 0`) | Credit amount in whole VND |
| `category_id` | Int | NULLABLE, FK -> `categories.id` | Associated category |
| `envelope_id` | Int | NULLABLE, FK -> `envelopes.id` | Associated virtual fund envelope |

*Table Constraint*: `CHECK ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`

#### Table 5: `envelopes` (Virtual Funds)
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, AutoIncrement | Internal envelope identifier |
| `name` | Text | NOT NULL | Envelope name (e.g. "Quỹ khẩn cấp", "Du lịch") |
| `policy` | Text | NOT NULL | Enum: `PROTECTED`, `FLEXIBLE` |
| `reserved_balance_vnd` | Int | NOT NULL, DEFAULT 0 | Current reserved balance (reconciled with movements) |
| `allow_negative_exception` | Bool | NOT NULL, DEFAULT false | Whether overspending past 0 is permitted |
| `target_amount_vnd` | Int | NULLABLE | Savings goal target in VND |
| `target_date_ms` | Int | NULLABLE | Savings goal target date (epoch ms) |
| `period_limit_vnd` | Int | NULLABLE | Optional periodic spending cap |
| `rollover_enabled` | Bool | NOT NULL, DEFAULT false | Whether unused balance rolls over |
| `priority` | Int | NOT NULL, DEFAULT 1 | Priority ranking (1 = highest) for advisor |
| `is_archived` | Bool | NOT NULL, DEFAULT false | Soft deletion flag |

#### Table 6: `envelope_movements`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, AutoIncrement | Internal movement identifier |
| `movement_type` | Text | NOT NULL | Enum: `ALLOCATE`, `RELEASE`, `TRANSFER`, `SPEND`, `REFUND_RESTORE`, `REVERSAL` |
| `amount_vnd` | Int | NOT NULL, CHECK (`amount_vnd > 0`) | Movement amount in whole VND |
| `source_envelope_id` | Int | NULLABLE, FK -> `envelopes.id` | Source envelope |
| `dest_envelope_id` | Int | NULLABLE, FK -> `envelopes.id` | Destination envelope |
| `linked_transaction_id` | Int | NULLABLE, FK -> `journal_transactions.id` | Associated financial transaction |
| `linked_obligation_id` | Int | NULLABLE, FK -> `scheduled_items.id` | Associated obligation |
| `occurred_at` | Int | NOT NULL | Movement timestamp (epoch ms) |

#### Table 7: `category_budgets`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, AutoIncrement | Internal budget identifier |
| `category_id` | Int | NOT NULL, FK -> `categories.id` | Target expense category |
| `year_month` | Int | NOT NULL | Period identifier (e.g. `202610`) |
| `limit_vnd` | Int | NOT NULL, CHECK (`limit_vnd > 0`) | Budget spending cap in VND |
| `alert_threshold_pct` | Int | NOT NULL, DEFAULT 80 | Warning threshold percentage (e.g. 80, 100) |

*Index*: `UNIQUE (category_id, year_month)`

#### Table 8: `scheduled_items` (Obligations & Planned Inflows)
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, AutoIncrement | Internal scheduled item identifier |
| `kind` | Text | NOT NULL | Enum: `BILL`, `PLANNED_INCOME` |
| `title` | Text | NOT NULL | Item title (e.g. "Tiền nhà", "Lương tháng") |
| `amount_vnd` | Int | NOT NULL, CHECK (`amount_vnd > 0`) | Expected amount in VND |
| `due_date_ms` | Int | NOT NULL | Due date timestamp (epoch ms) |
| `recurrence` | Text | NOT NULL | Enum: `NONE`, `WEEKLY`, `MONTHLY`, `YEARLY` |
| `anchor_day_of_month` | Int | NULLABLE, CHECK (`anchor_day_of_month BETWEEN 1 AND 31`) | Anchor day for drift-free month-end recurrence |
| `category_id` | Int | NULLABLE, FK -> `categories.id` | Associated category |
| `linked_envelope_id` | Int | NULLABLE, FK -> `envelopes.id` | Associated virtual fund envelope |
| `status` | Text | NOT NULL, DEFAULT 'PENDING' | Enum: `PENDING`, `PAID_OR_RECEIVED`, `SKIPPED` |
| `paid_transaction_id` | Int | NULLABLE, FK -> `journal_transactions.id` | Real transaction created upon execution |
| `reminder_days_before` | Int | NOT NULL, DEFAULT 1 | Notification lead time in days |

#### Table 9: `settings` (Singleton Configuration)
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | Int | PK, CHECK (`id == 1`) | Single row constraint |
| `minimum_cash_buffer_vnd` | Int | NOT NULL, DEFAULT 0 | Mandatory emergency buffer deducted in Safe-to-Spend |
| `period_start_day` | Int | NOT NULL, DEFAULT 1 | Budget period start day of month (1..28) |
| `daily_reminder_hour` | Int | NOT NULL, DEFAULT 20 | Notification hour (0..23) |
| `daily_reminder_minute` | Int | NOT NULL, DEFAULT 0 | Notification minute (0..59) |
| `notifications_enabled` | Bool | NOT NULL, DEFAULT false | Master notification switch |
| `schema_version` | Int | NOT NULL, DEFAULT 1 | Database schema version |

#### Initial Vietnamese Seeding
1. **System Ledger Accounts**:
   - `EQUITY_OPENING`: kind = `EQUITY_OPENING`, `is_liquid = false`, `credit_limit = 0`.
   - Default Income account: kind = `INCOME`, `is_liquid = false`.
   - Default Expense account: kind = `EXPENSE`, `is_liquid = false`.
2. **Default Categories**:
   - Income:
     - `Lương` (Salary) — icon: work, color: green.
     - `Thưởng` (Bonus) — icon: card_giftcard, color: teal.
   - Expense:
     - `Ăn uống` (Food & Dining) — icon: restaurant, color: orange.
     - `Di chuyển` (Transportation) — icon: directions_car, color: blue.
     - `Hoá đơn & Tiện ích` (Bills & Utilities) — icon: receipt, color: purple.
     - `Nhà cửa` (Housing) — icon: home, color: brown.
     - `Mua sắm` (Shopping) — icon: shopping_bag, color: pink.
     - `Y tế` (Healthcare) — icon: local_hospital, color: red.
3. **Clean First-Run State**: All balances start at `0 ₫`, with zero fake transactions or sample records.

---

### 3. Double-Entry Posting Matrix & Invariants

All writes must execute within a single atomic `db.transaction()`. Before committing, the transaction invariant must be asserted:
$$\sum \text{debit\_vnd} == \sum \text{credit\_vnd}$$

#### Posting Rules Matrix (All 7 Transaction Types)

| Transaction Type | Debit Leg (`debit_vnd`) | Credit Leg (`credit_vnd`) | Atomic Envelope Movement | Notes |
|---|---|---|---|---|
| **1. OPENING_BALANCE (Asset)** | `ASSET_CASH` or `ASSET_BANK` | `EQUITY_OPENING` | None | Initializes starting cash/bank. Does NOT increase income. |
| **2. OPENING_BALANCE (Card Debt)** | `EQUITY_OPENING` | `LIABILITY_CREDIT_CARD` | None | Initializes starting credit card liability. |
| **3. INCOME** | `ASSET_CASH` or `ASSET_BANK` | `INCOME` (Category linked) | None | Increases liquid assets and recognized income. |
| **4. EXPENSE (Cash/Bank)** | `EXPENSE` (Category linked) | `ASSET_CASH` or `ASSET_BANK` | If `envelope_id != null`: `SPEND` from envelope | Decreases liquid assets and increases gross expense. |
| **5. EXPENSE (Credit Card)** | `EXPENSE` (Category linked) | `LIABILITY_CREDIT_CARD` | If `envelope_id != null`: `SPEND` from envelope | Liquid assets unchanged; credit card liability increases. |
| **6. CREDIT_CARD_PAYMENT** | `LIABILITY_CREDIT_CARD` | `ASSET_CASH` or `ASSET_BANK` | None | Decreases liquid assets and decreases card liability. **NEVER an expense.** |
| **7. INTERNAL_TRANSFER** | Destination `ASSET_*` | Source `ASSET_*` | None | Liquid assets, income, and expenses are unaffected. |
| **8. REFUND** | Receiving `ASSET_*` or `LIABILITY_CREDIT_CARD` | `EXPENSE` (Category linked) | If `envelope_id != null`: `REFUND_RESTORE` to envelope | Decreases gross expense; restores liquid assets or card limit. |
| **9. REVERSAL** | Inverted from target: original credit accounts | Inverted from target: original debit accounts | If target had envelope movement: offsetting `REVERSAL` | Exactly offsets original postings across all accounts. |

---

### 4. Atomic Envelope Linkage & Movement Engine

Virtual fund envelopes represent conceptual allocations of liquid cash. They never generate double-entry ledger postings.

#### Movement Types & Invariants
1. **`ALLOCATE`**:
   - `dest_envelope_id = envelope.id`, `source_envelope_id = null`.
   - Effect: `envelope.reserved_balance_vnd += amount`.
   - Invariant: `amount <= max(0, available_to_allocate)`.
2. **`RELEASE`**:
   - `source_envelope_id = envelope.id`, `dest_envelope_id = null`.
   - Effect: `envelope.reserved_balance_vnd -= amount`.
   - Invariant: `amount <= envelope.reserved_balance_vnd` (unless negative exception permitted).
3. **`TRANSFER`**:
   - `source_envelope_id = from_env.id`, `dest_envelope_id = to_env.id`.
   - Effect: `from_env.reserved_balance_vnd -= amount`, `to_env.reserved_balance_vnd += amount`.
   - Invariant: `amount <= from_env.reserved_balance_vnd`.
4. **`SPEND`**:
   - Triggered atomically when an `EXPENSE` transaction specifies `envelope_id`.
   - `source_envelope_id = envelope.id`, `dest_envelope_id = null`, `linked_transaction_id = tx.id`.
   - Effect: `envelope.reserved_balance_vnd -= amount`.
   - Invariant: If `amount > envelope.reserved_balance_vnd`, blocked unless `allow_negative_exception == true` is confirmed.
5. **`REFUND_RESTORE`**:
   - Triggered atomically when a `REFUND` transaction specifies `envelope_id`.
   - `source_envelope_id = null`, `dest_envelope_id = envelope.id`, `linked_transaction_id = tx.id`.
   - Effect: `envelope.reserved_balance_vnd += amount`.
6. **`REVERSAL`**:
   - Triggered atomically during void/edit of an expense or refund transaction linked to an envelope.
   - If original was `SPEND`: restores `amount` to envelope (`dest_envelope_id = envelope.id`).
   - If original was `REFUND_RESTORE`: deducts `amount` from envelope (`source_envelope_id = envelope.id`).

---

### 5. Dynamic Account Balance Derivation

No mutable balance cache exists on `ledger_accounts`. All balances are dynamically derived via SQL aggregate queries across **all** `journal_postings`:

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

#### Liquid Assets Derivation
$$\text{total\_liquid\_assets} = \sum_{a \in \text{Accounts}} \text{balance}(a) \quad \text{where } a.\text{kind} \in (\text{ASSET\_CASH}, \text{ASSET\_BANK}) \text{ and } a.\text{is\_liquid} == \text{true}$$
- Credit limits and credit card liabilities are strictly excluded from liquid assets.
- Net Worth is derived as:
  $$\text{Net Worth} = \sum \text{Asset Balances} - \sum \text{Liability Balances}$$

---

### 6. Audit-Preserving Reversal & Edit Engine

#### Void / Delete State Transition
1. Target transaction must have `status == 'POSTED'`.
2. Update target transaction `status = 'VOIDED'`.
3. Insert new `journal_transactions` row:
   - `tx_type = 'REVERSAL'`
   - `status = 'POSTED'`
   - `reverses_tx_id = target.id`
   - `occurred_at = target.occurred_at`
4. Insert inverted postings in `journal_postings`:
   - For each target posting with `(debit_vnd = D, credit_vnd = 0)`, create posting with `(debit_vnd = 0, credit_vnd = D)`.
   - For each target posting with `(debit_vnd = 0, credit_vnd = C)`, create posting with `(debit_vnd = C, credit_vnd = 0)`.
5. If target had an `envelope_movements` record, insert offsetting `REVERSAL` movement.

#### Edit State Transition
1. Perform Void/Reversal as above, except set target `status = 'SUPERSEDED'`.
2. Insert new edited `journal_transactions` row with `status = 'POSTED'`.
3. Set target's `replaced_by_tx_id = new_tx.id`.
4. Insert postings for new transaction and any new envelope movements.

#### Clean UI Filtering Rule
- Standard transaction queries and monthly category summary queries apply:
  $$\text{WHERE } \text{status} = \text{'POSTED'} \text{ AND } \text{tx\_type} \neq \text{'REVERSAL'}$$
- This keeps superseded, voided, and reversal pairs invisible in daily views.
- "Lịch sử chỉnh sửa" (Audit History) sheet queries by `reverses_tx_id` and `replaced_by_tx_id` to render the complete historical chain.

---

### 7. Deterministic Domain Algorithms

#### 7.1 Available-to-Allocate
$$\text{available\_to\_allocate} = \text{total\_liquid\_assets} - \text{total\_envelope\_reserves} - \text{minimum\_cash\_buffer\_vnd}$$
- $\text{total\_envelope\_reserves} = \sum_{e \in \text{Envelopes}} e.\text{reserved\_balance\_vnd}$ (for all active envelopes).
- Invariant: `ALLOCATE` is blocked if $\text{amount} > \max(0, \text{available\_to\_allocate})$.

#### 7.2 Category Spending, Refunds & Savings Rate
For any reporting interval $[start\_ms, end\_ms)$:
- $\text{gross\_expense} = \sum \text{debit\_vnd on EXPENSE accounts}$
- $\text{refund\_credits} = \sum \text{credit\_vnd on EXPENSE accounts}$
- $\text{net\_expense} = \text{gross\_expense} - \text{refund\_credits}$
- $\text{recognized\_income} = \sum (\text{credit\_vnd} - \text{debit\_vnd}) \text{ on INCOME accounts}$
- $\text{net\_saving} = \text{recognized\_income} - \text{net\_expense}$

**Edge Cases**:
- **Net Recovery**: If $\text{net\_expense} < 0$, display as `"Thu hồi chi phí ròng"`. When computing `saving_rate`, use:
  $$\text{effective\_expense} = \max(0, \text{net\_expense})$$
- **Zero or Negative Income**:
  - If $\text{recognized\_income} \le 0$: `saving_rate = null` (render `"Chưa có thu nhập"`, never `NaN` or `Infinity`).
  - Otherwise:
    $$\text{saving\_rate} = \frac{\text{recognized\_income} - \max(0, \text{net\_expense})}{\text{recognized\_income}}$$

#### 7.3 Safe-to-Spend (Zero Double-Counting Formula)
Evaluated from `now` until `horizon_date` (next scheduled `PLANNED_INCOME` or end of current budgeting period):
$$\text{Safe-to-Spend} = \text{Liquid Assets} - \text{Protected Reserves} - \text{Unfunded Committed Outflows} - \text{Minimum Cash Buffer}$$

1. **`Liquid Assets`**: $\text{total\_liquid\_assets}$ (`ASSET_CASH` + `ASSET_BANK`).
2. **`Protected Reserves`**: $\sum \max(0, e.\text{reserved\_balance\_vnd})$ for active envelopes with `policy == PROTECTED`. (Envelopes with `policy == FLEXIBLE` are discretionary and NOT subtracted here).
3. **`Unfunded Committed Outflows`**:
   For each pending `BILL` due $\le \text{horizon\_date}$:
   - If `linked_envelope_id == null`:
     $$\text{unfunded\_amount} = \text{bill.amount\_vnd}$$
   - If `linked_envelope_id` points to a `PROTECTED` envelope:
     Apply envelope's `reserved_balance_vnd` chronologically across all pending bills linked to it:
     $$\text{covered} = \min(\text{bill.amount\_vnd}, \text{remaining\_envelope\_balance})$$
     $$\text{unfunded\_amount} = \text{bill.amount\_vnd} - \text{covered}$$
     $$\text{remaining\_envelope\_balance} -= \text{covered}$$
     Only the unfunded portion is added to `Unfunded Committed Outflows`. *(Prevents double counting since the covered portion is already in Protected Reserves).*
   - If `linked_envelope_id` points to a `FLEXIBLE` envelope:
     $$\text{unfunded\_amount} = \text{bill.amount\_vnd}$$
     *(Because flexible envelopes were not subtracted in Protected Reserves).*
4. **`Minimum Cash Buffer`**: `settings.minimum_cash_buffer_vnd`.

**Negative Safe-to-Spend Invariant**:
- Never clamp `Safe-to-Spend` to 0.
- If negative, return exact deficit in whole VND (e.g. `-1.500.000 ₫`).
- UI renders exact breakdown of components and deficit in red.
- Daily allowance displays `0 ₫/ngày` when $\text{Safe-to-Spend} \le 0$. When positive:
  $$\text{daily\_allowance} = \text{Safe-to-Spend} \mathbin{\sim/} \max(1, \text{days\_remaining})$$

#### 7.4 Savings Goals & Feasibility Advisor
- Target $T$, Current balance $C$, Remaining periods $N$:
  - If $C \ge T$: Status = `ACHIEVED`, $\text{required\_per\_period} = 0$.
  - If $N \le 0$ and $C < T$: Status = `OVERDUE`, $\text{shortfall} = T - C$ (no division by zero).
  - If $N > 0$ and $C < T$:
    Ceiling integer division in VND:
    $$\text{required\_per\_period} = ((T - C) + N - 1) \mathbin{\sim/} N$$
- **Feasibility Trigger**:
  If $\sum \text{required\_per\_period of all active goals} > \text{available\_to\_allocate}$ (or monthly average net saving):
  - Mark status as `INFEASIBLE`.
  - Provide 3 one-tap calculators:
    1. *Extend deadline*: $N' = \lceil (T - C) / \text{monthly\_capacity} \rceil$.
    2. *Lower target*: $T' = C + N \times \text{monthly\_capacity}$.
    3. *Pause lower-priority goals*: Rank by `priority`, fund highest priority first, pause remaining.

#### 7.5 Month-End Recurrence & Cash-Flow Forecast
- **Drift-Free Recurrence**:
  For monthly items anchored to day $d \in \{1 \dots 31\}$ evaluated in target year $Y$ and month $M$:
  $$\text{actual\_due\_day} = \min(\text{anchor\_day\_of\_month}, \text{daysInMonth}(Y, M))$$
  - Anchor `31` in Jan $\to$ Jan 31
  - Anchor `31` in Feb $\to$ Feb 28 (or Feb 29 in leap year)
  - Anchor `31` in Mar $\to$ Mar 31 (retains 31 without degradation)
  - Anchor `31` in Apr $\to$ Apr 30
- **Execution & Conversion**:
  - Marking bill/income paid creates real `journal_transaction` (`paid_transaction_id = tx.id`) and sets `status = 'PAID_OR_RECEIVED'`.
  - Automatically advances next recurrence instance. Never double-counts paid bills as pending outflows.
- **30/60/90-Day Cash Flow Forecast**:
  - Starting baseline: `total_liquid_assets`.
  - Day $k$ projection:
    $$\text{Projected Balance}_{k} = \text{Projected Balance}_{k-1} + \sum \text{PLANNED\_INCOME}_k - \sum \text{PENDING\_BILL}_k$$
  - Flag any date where $\text{Projected Balance}_k < \text{minimum\_cash\_buffer\_vnd}$.

---

### 8. The 15 Mandatory Acceptance Scenarios Specification

#### Scenario 1: Opening Asset (`10.000.000 ₫`)
- **Initial State**: All database tables empty.
- **Action**: Create opening balance transaction of `10.000.000 ₫` for `ASSET_CASH`.
- **Postings**:
  - Debit: `ASSET_CASH` = 10.000.000 ₫
  - Credit: `EQUITY_OPENING` = 10.000.000 ₫
- **Assertions**:
  - `ASSET_CASH` balance == `10.000.000 ₫`
  - `total_liquid_assets` == `10.000.000 ₫`
  - Operating income == `0 ₫`
  - Net expense == `0 ₫`
  - Net worth == `10.000.000 ₫`

#### Scenario 2: Salary (`20.000.000 ₫`)
- **Preconditions**: State from Scenario 1 (`total_liquid_assets = 10.000.000 ₫`).
- **Action**: Post `INCOME` of `20.000.000 ₫` to `ASSET_BANK` linked to Category `Lương`.
- **Postings**:
  - Debit: `ASSET_BANK` = 20.000.000 ₫
  - Credit: `INCOME` (`Lương`) = 20.000.000 ₫
- **Assertions**:
  - `ASSET_BANK` balance == `20.000.000 ₫`
  - `total_liquid_assets` == `30.000.000 ₫` (10M + 20M)
  - Recognized income == `20.000.000 ₫`
  - Net expense == `0 ₫`
  - Net saving == `20.000.000 ₫`
  - Saving rate == `1.0` (100%)

#### Scenario 3: Cash Expense (`100.000 ₫`)
- **Preconditions**: State from Scenario 2 (`total_liquid_assets = 30.000.000 ₫`).
- **Action**: Post `EXPENSE` of `100.000 ₫` paid via `ASSET_CASH` for Category `Ăn uống` (no envelope).
- **Postings**:
  - Debit: `EXPENSE` (`Ăn uống`) = 100.000 ₫
  - Credit: `ASSET_CASH` = 100.000 ₫
- **Assertions**:
  - `ASSET_CASH` balance == `9.900.000 ₫` (10.000.000 - 100.000)
  - `total_liquid_assets` == `29.900.000 ₫` (9.9M + 20M)
  - Gross expense == `100.000 ₫`
  - Net expense == `100.000 ₫`
  - Recognized income == `20.000.000 ₫`
  - Net saving == `19.900.000 ₫`
  - Saving rate == `(20.000.000 - 100.000) / 20.000.000 = 0.995` (99.5%)

#### Scenario 4: Internal Transfer (`2.000.000 ₫`)
- **Preconditions**: State from Scenario 3 (`ASSET_CASH = 9.9M ₫`, `ASSET_BANK = 20M ₫`).
- **Action**: Post `INTERNAL_TRANSFER` of `2.000.000 ₫` from `ASSET_BANK` to `ASSET_CASH`.
- **Postings**:
  - Debit: `ASSET_CASH` = 2.000.000 ₫
  - Credit: `ASSET_BANK` = 2.000.000 ₫
- **Assertions**:
  - `ASSET_CASH` balance == `11.900.000 ₫` (9.9M + 2M)
  - `ASSET_BANK` balance == `18.000.000 ₫` (20M - 2M)
  - `total_liquid_assets` == `29.900.000 ₫` (UNCHANGED)
  - Recognized income == `20.000.000 ₫` (UNCHANGED)
  - Net expense == `100.000 ₫` (UNCHANGED)

#### Scenario 5: Virtual Fund Allocation (`1.000.000 ₫` to Protected Fund)
- **Preconditions**: State from Scenario 4 (`total_liquid_assets = 29.900.000 ₫`, buffer = 0 ₫).
- **Action**: Allocate `1.000.000 ₫` to Protected Envelope "Khẩn cấp" (`policy = PROTECTED`).
- **Movements**:
  - Insert `envelope_movements` (`type = ALLOCATE`, `dest_envelope_id = envelope.id`, `amount_vnd = 1.000.000 ₫`).
  - Zero journal postings.
- **Assertions**:
  - `total_liquid_assets` == `29.900.000 ₫` (UNCHANGED)
  - Net expense == `100.000 ₫` (UNCHANGED)
  - Income == `20.000.000 ₫` (UNCHANGED)
  - Protected reserve balance == `1.000.000 ₫`
  - `available_to_allocate` decreases by `1.000.000 ₫` (from 29.9M to 28.9M ₫)
  - `Safe-to-Spend` decreases by `1.000.000 ₫` (from 29.9M to 28.9M ₫)

#### Scenario 6: Credit-Card Purchase (`500.000 ₫`)
- **Preconditions**: State from Scenario 5 (`total_liquid_assets = 29.900.000 ₫`).
- **Action**: Post `EXPENSE` of `500.000 ₫` paid via `LIABILITY_CREDIT_CARD` for Category `Mua sắm`.
- **Postings**:
  - Debit: `EXPENSE` (`Mua sắm`) = 500.000 ₫
  - Credit: `LIABILITY_CREDIT_CARD` = 500.000 ₫
- **Assertions**:
  - `LIABILITY_CREDIT_CARD` balance == `500.000 ₫` (debt)
  - `total_liquid_assets` == `29.900.000 ₫` (UNCHANGED)
  - Gross expense == `600.000 ₫` (100k + 500k)
  - Net expense == `600.000 ₫` (increased by 500.000 ₫)
  - Net worth == `29.400.000 ₫` (Assets 29.9M - Liabilities 0.5M)

#### Scenario 7: Credit-Card Payment (`500.000 ₫`)
- **Preconditions**: State from Scenario 6 (`card debt = 500.000 ₫`, `ASSET_BANK = 18.000.000 ₫`).
- **Action**: Post `CREDIT_CARD_PAYMENT` of `500.000 ₫` from `ASSET_BANK` to `LIABILITY_CREDIT_CARD`.
- **Postings**:
  - Debit: `LIABILITY_CREDIT_CARD` = 500.000 ₫
  - Credit: `ASSET_BANK` = 500.000 ₫
- **Assertions**:
  - `LIABILITY_CREDIT_CARD` balance == `0 ₫` (cleared)
  - `ASSET_BANK` balance == `17.500.000 ₫` (18.000.000 - 500.000)
  - `total_liquid_assets` == `29.400.000 ₫` (decreased by 500.000 ₫)
  - Net expense == `600.000 ₫` (**DOES NOT INCREASE**, credit card payment is not an expense)
  - Net worth == `29.400.000 ₫` (UNCHANGED)

#### Scenario 8: Refund (`50.000 ₫`)
- **Preconditions**: State from Scenario 7 (`net_expense = 600.000 ₫`, `ASSET_BANK = 17.500.000 ₫`).
- **Action**: Post `REFUND` of `50.000 ₫` for Category `Mua sắm` receiving into `ASSET_BANK`.
- **Postings**:
  - Debit: `ASSET_BANK` = 50.000 ₫
  - Credit: `EXPENSE` (`Mua sắm`) = 50.000 ₫
- **Assertions**:
  - `ASSET_BANK` balance == `17.550.000 ₫` (17.5M + 50k)
  - `total_liquid_assets` == `29.450.000 ₫` (increased by 50.000 ₫)
  - Gross expense == `600.000 ₫`
  - Refund credits == `50.000 ₫`
  - Net expense == `550.000 ₫` (decreased by 50.000 ₫)
  - If linked to an envelope, envelope reserve balance increases by `50.000 ₫` via `REFUND_RESTORE`.

#### Scenario 9: Edit & Void Transaction
- **Part A (Void)**:
  - Create transaction T1: Expense of `100.000 ₫` from `ASSET_CASH`.
  - Void T1: T1 status becomes `VOIDED`.
  - Reversal transaction R1 created (`reverses_tx_id = T1.id`, `status = POSTED`):
    - Debit: `ASSET_CASH` = 100.000 ₫
    - Credit: `EXPENSE` = 100.000 ₫
  - Assertions:
    - Ledger sums balance: `SUM(debit) == SUM(credit)`.
    - `ASSET_CASH` balance returns to original value before T1.
    - Standard UI query (`WHERE status = 'POSTED' AND tx_type != 'REVERSAL'`) returns neither T1 nor R1.
- **Part B (Edit)**:
  - Create transaction T2: Expense of `200.000 ₫` from `ASSET_CASH`.
  - Edit T2 to `250.000 ₫`.
  - T2 status becomes `SUPERSEDED`, `replaced_by_tx_id = T3.id`.
  - Reversal R2 created (`reverses_tx_id = T2.id`).
  - New transaction T3 created (`status = POSTED`, amount = `250.000 ₫`).
  - Assertions:
    - Net effect on `ASSET_CASH` is exactly `-250.000 ₫`.
    - Standard UI query displays only T3.
    - Audit history sheet for T3 displays T2, R2, and T3 in sequence.

#### Scenario 10: Duplicate Submission Guard
- **Action**: Submit transaction with `idempotency_key = "idemp-001"`.
- Immediately submit identical transaction with `idempotency_key = "idemp-001"`.
- **Assertions**:
  - Second submission is intercepted and rejected / returns existing record.
  - Exactly 1 record exists in `journal_transactions` with `idempotency_key = "idemp-001"`.
  - Ledger account balances reflect exactly 1 transaction amount.

#### Scenario 11: Scheduled Bill (`1.500.000 ₫`) & Payment
- **Setup**:
  - `total_liquid_assets = 10.000.000 ₫`, buffer = 0 ₫.
  - Protected envelope "Điện nước" has `reserved_balance_vnd = 1.000.000 ₫`.
  - Create pending `BILL` "Tiền điện" for `1.500.000 ₫` linked to "Điện nước".
- **Assertions (Pending Phase)**:
  - Protected envelope covers 1.000.000 ₫.
  - Unfunded Committed Outflows == `500.000 ₫` (`1.500.000 - 1.000.000`).
  - Protected Reserves == `1.000.000 ₫`.
  - Total deduction = `1.000.000 (reserves) + 500.000 (unfunded) = 1.500.000 ₫`.
  - Safe-to-Spend == `10.000.000 - 1.000.000 - 500.000 = 8.500.000 ₫`.
  - **Zero double-counting guaranteed**.
- **Action (Payment Phase)**: Mark bill as paid.
  - Generates posted `EXPENSE` transaction for `1.500.000 ₫`.
  - Scheduled item status becomes `PAID_OR_RECEIVED`, `paid_transaction_id = tx.id`.
  - Envelope movement `SPEND` consumes `1.000.000 ₫` from "Điện nước".
- **Assertions (Post-Payment Phase)**:
  - `total_liquid_assets` == `8.500.000 ₫` (10M - 1.5M).
  - Protected envelope balance == `0 ₫`.
  - Unfunded pending bills == `0 ₫` (paid bill is no longer pending).
  - Safe-to-Spend == `8.500.000 ₫` (matches cash, no double subtraction).

#### Scenario 12: Negative Safe-to-Spend
- **Setup**:
  - `total_liquid_assets = 2.000.000 ₫`.
  - Protected Reserves == `1.500.000 ₫`.
  - Unfunded Bills == `1.000.000 ₫`.
  - Minimum Cash Buffer == `1.000.000 ₫`.
- **Calculation**:
  $$\text{Safe-to-Spend} = 2.000.000 - 1.500.000 - 1.000.000 - 1.000.000 = -1.500.000 \text{ ₫}$$
- **Assertions**:
  - `Safe-to-Spend` == `-1.500.000 ₫` (NOT clamped to 0).
  - Daily discretionary allowance == `0 ₫/ngày`.
  - Shortfall breakdown returned:
    - Liquid Assets: `+2.000.000 ₫`
    - Protected Reserves: `-1.500.000 ₫`
    - Unfunded Bills: `-1.000.000 ₫`
    - Cash Buffer: `-1.000.000 ₫`
    - Shortfall Deficit: `-1.500.000 ₫`
  - UI renders deficit in red warning style.

#### Scenario 13: Encrypted Backup & Restore Round-Trip
- **Preconditions**: Populated database with accounts, categories, transactions, postings, envelopes, movements, budgets, scheduled items, settings.
- **Action**:
  - Run backup export inside `Isolate.run` with password `"MatKhauManh#2026"`.
  - Verifies outer JSON format (`magic = "DONGTIEN_ENC_V1"`, `kdf = "PBKDF2-HMAC-SHA256"`, 120,000 iterations, 16-byte salt, 12-byte nonce, AES-256-GCM tag).
  - Completely wipe existing SQLite database.
  - Run restore inside `Isolate.run` with password `"MatKhauManh#2026"`.
- **Assertions**:
  - Decryption succeeds; structural invariants pass (`SUM(debit) == SUM(credit)` for every tx, FK integrity passes).
  - Database restored atomically inside single `db.transaction()`.
  - All 9 tables contain exact pre-wipe records and derived account balances match bit-for-bit.

#### Scenario 14: Tampered Backup / Wrong Password
- **Part A (Tampered Ciphertext)**:
  - Generate valid backup. Flip 1 single byte in `ciphertextB64` or `macB64`.
  - Attempt restore inside `Isolate.run`.
  - Assertions: `AesGcm` throws `SecretBoxAuthenticationError`. SQLite database is never touched. Existing data remains 100% intact.
- **Part B (Wrong Password)**:
  - Attempt restore of valid backup using `"SaiMatKhau"`.
  - Assertions: Decryption throws authentication error. SQLite database untouched.

#### Scenario 15: Notification Permission Denied & Month-End Recurrence
- **Part A (Permission Denied)**:
  - User denies `POST_NOTIFICATIONS` permission.
  - Assertions: All core financial paths (adding transactions, creating budgets, allocating funds) function normally without exceptions or degraded performance; Settings shows non-blocking warning banner.
- **Part B (Drift-Free Recurrence)**:
  - Create recurring monthly bill with `anchor_day_of_month = 31` starting Jan 31.
  - Advance to February (non-leap year, 28 days): Generated due date == `Feb 28`.
  - Advance to March (31 days): Generated due date == `Mar 31` (returns to 31 without drift).
  - Advance to April (30 days): Generated due date == `Apr 30`.
  - Advance to May (31 days): Generated due date == `May 31`.
  - Assertions: `scheduled_items.anchor_day_of_month` remains `31` across all occurrences; due dates match `min(anchor_day_of_month, daysInMonth(Y, M))`.

---

## 5-Component Handoff Report

### 1. Observation
1. **Authoritative Sources**:
   - `c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md`: Lines 22–39 (R2 and R3 specifications), lines 57–75 (15 mandatory acceptance criteria).
   - `c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md`:
     - Line 8: "Vietnamese UI (`vi_VN`), currency `VND` stored strictly as 64-bit integers (`int`), never `double`."
     - Lines 98–101: `VndMoney` value type, whole VND, `max_Safe_VND = 9_000_000_000_000_000`.
     - Lines 102–123: Detailed specification of all 9 Drift tables (`ledger_accounts`, `categories`, `journal_transactions`, `journal_postings`, `envelopes`, `envelope_movements`, `category_budgets`, `scheduled_items`, `settings`) and `PRAGMA foreign_keys = ON;`.
     - Lines 124–138: Double-Entry Posting Matrix & Envelope Atomic Linkage with exact debit/credit rules and transaction invariant `SUM(debit_vnd) == SUM(credit_vnd)`.
     - Lines 139–143: Account balance derivation rules (`Debit - Credit` for Asset/Expense, `Credit - Debit` for Liability/Income/Equity) and strict prohibition of mutable cached balances.
     - Lines 144–148: Audit-preserving reversal and edit engine (`VOIDED`, `SUPERSEDED`, `REVERSAL`, `reverses_tx_id`, `replaced_by_tx_id`) and UI filtering rule `WHERE tx.status = 'POSTED' AND tx.tx_type != 'REVERSAL'`.
     - Lines 153–196: Deterministic domain algorithms (Available-to-allocate, Category spending/refunds/savings rate, Safe-to-Spend with zero double-counting, savings goal ceiling integer division, drift-free month-end recurrence, 30/60/90-day cash-flow forecast).
     - Lines 273–289: The 15 mandatory acceptance scenarios with required values.
2. **Current Repository State**:
   - Inspected root directory `c:\Users\coihu12\Documents\App` via `list_dir`. Contains `build_spec/`, `docs/`, and `.agents/`.
   - Workspace is in Phase 0 (spec mining / survey phase). No application code has been generated yet.

### 2. Logic Chain
1. From `build_spec.md` §4.1 and `ORIGINAL_REQUEST.md` R2, storing currency as floating-point `double` introduces IEEE 754 precision errors (e.g. `0.1 + 0.2 != 0.3`). In Vietnam, currency is exclusively integer VND. Therefore, using 64-bit `int` with an explicit overflow guard `max_Safe_VND = 9_000_000_000_000_000` guarantees exact integer arithmetic across decades of transactions.
2. From `build_spec.md` §4.3 and §4.4, decoupling the general ledger from virtual funds prevents synthetic transactions. Virtual allocations reserve cash conceptually in `envelopes` via `envelope_movements` without posting fictitious accounting expenses or asset reductions.
3. Because all transactions and reversals are preserved in `journal_postings`, dynamic derivation (`SUM(debit) - SUM(credit)` for assets, `SUM(credit) - SUM(debit)` for liabilities/income/equity) eliminates cache desynchronization bugs and ensures absolute accounting integrity.
4. When voiding or editing, immutability requires inserting a `REVERSAL` transaction and marking target rows `VOIDED` or `SUPERSEDED`. Filtering UI lists by `WHERE status = 'POSTED' AND tx_type != 'REVERSAL'` guarantees that users see a clean feed while the underlying ledger retains a permanent audit trail.
5. In Safe-to-Spend calculations, subtracting both a protected envelope reserve and a linked pending bill would subtract the same cash twice. By chronologically allocating the envelope reserve to cover linked bills and only adding the unfunded excess to `Unfunded Committed Outflows`, double-counting is mathematically eliminated.
6. For monthly recurrence, month lengths vary (28, 29, 30, 31). Using `actual_due_day = min(anchor_day_of_month, daysInMonth(Y, M))` preserves the anchor (e.g. 31) across February without permanent date degradation.

### 3. Caveats
- No implementation code was written or modified during this mining phase (strict read-only spec mining).
- UI widget styling tokens and screen wireframes are owned by the visual survey agent (`docs/design_refs/`).
- Backup encryption PBKDF2/AES-GCM isolate implementation details are covered in R5/Security spec, but their data contracts and database restoration invariants are fully integrated into this report.
- "No other caveats."

### 4. Conclusion
The financial domain and persistence layer of DongTien are completely specified, deterministic, and closed under all mathematical and accounting operations. The 9 Drift tables, 7 transaction posting rules, 6 envelope movement types, dynamic balance derivation, audit-preserving reversal/edit state machine, Safe-to-Spend zero double-counting formula, and 15 acceptance scenarios have been fully mined and documented.

### 5. Verification Method
1. **Database Schema Verification**:
   - Inspect Drift table definitions in `lib/core/database/` to ensure all 9 tables, columns, constraints, foreign keys, and indexes match Section 2 above.
   - Run `dart run build_runner build --delete-conflicting-outputs` to verify Drift code generation.
2. **Domain Invariant Test Execution**:
   - Execute `flutter test test/unit/` and `flutter test test/database/`.
   - Verify 100% pass rate for tests implementing Scenarios 1 through 15 with exact assertions detailed in Section 8.
3. **Invalidation Conditions**:
   - Any floating-point `double` used for monetary VND storage.
   - Any mutable balance column added to `ledger_accounts`.
   - Any hard deletion (`DELETE FROM journal_transactions`) in standard user flows.
   - Clamping `Safe-to-Spend` to 0 when negative.
   - Permanent date drift of anchor 31 to 28 after February.
