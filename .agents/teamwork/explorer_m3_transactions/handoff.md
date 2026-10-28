# HANDOFF REPORT: IMPLEMENTATION BLUEPRINT FOR TRANSACTIONS & ACCOUNTS (TAB 1)

**Author**: `explorer_m3_transactions`  
**Target Worker**: `worker_m3_transactions`  
**Target Directories**: `lib/features/transactions/`, `lib/features/accounts/`  
**Date**: 2026-10-27T19:48:00Z  

---

## 1. OBSERVATIONS

### 1.1 Existing Database Accessors & Schema Contracts
1. **`lib/core/database/daos/ledger_dao.dart`**:
   - `watchCleanTransactions()` (lines 517–527):
     ```dart
     Stream<List<JournalTransaction>> watchCleanTransactions() {
       return (select(journalTransactions)
             ..where((t) =>
                 t.status.equals('POSTED') & t.txType.equals('REVERSAL').not())
             ..orderBy([
               (t) =>
                   OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
               (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
             ]))
           .watch();
     }
     ```
   - `watchAccountsWithBalances()` (lines 407–435):
     Queries `ledger_accounts` left-joined with `journal_postings` grouped by account ID, deriving dynamic balances without cached columns:
     - Debit-normal accounts (`ASSET_CASH`, `ASSET_BANK`, `EXPENSE`): $\sum \text{debit} - \sum \text{credit}$
     - Credit-normal accounts (`LIABILITY_CREDIT_CARD`, `INCOME`, `EQUITY_OPENING`): $\sum \text{credit} - \sum \text{debit}$
     Returns `Stream<List<AccountWithBalance>>` with fields: `id`, `name`, `kind`, `isLiquid`, `creditLimit`, `balanceVnd`.
   - `postTransaction(...)` (lines 72–200) & `postTransactionCommand(...)` (lines 203–213):
     Executes inside atomic `db.transaction()`, asserts `SUM(debit) == SUM(credit)`, verifies envelope deficit if `SPEND`, inserts `journal_transactions`, batch inserts `journal_postings`, and inserts `envelope_movements`.
   - `voidTransaction(int transactionId)` (lines 219–332):
     Marks target `status = 'VOIDED'`, inserts `REVERSAL` transaction with inverted postings (`debit <-> credit`) and offsetting envelope movements.
   - `editTransaction(...)` (lines 341–380):
     Calls `voidTransaction(originalTxId)`, updates original to `status = 'SUPERSEDED'`, posts new transaction with `status = 'POSTED'`, and sets `replacedByTxId = newTxId`.

2. **`lib/core/database/app_database.dart`**:
   - `JournalTransactions` (lines 52–74):
     `id` (int PK), `txType` (CHECK: `OPENING_BALANCE`, `INCOME`, `EXPENSE`, `TRANSFER`, `CREDIT_CARD_PAYMENT`, `REFUND`, `REVERSAL`), `status` (CHECK: `POSTED`, `SUPERSEDED`, `VOIDED`), `description`, `occurredAt`, `createdAt`, `idempotencyKey` (unique nullable), `reversesTxId` (FK nullable), `replacedByTxId` (FK nullable).
   - `JournalPostings` (lines 83–102):
     `id`, `transactionId` (FK cascade), `accountId` (FK restrict), `debitVnd`, `creditVnd`, `categoryId` (FK nullable setNull), `envelopeId` (FK nullable setNull). One-sided check: `(debit > 0 AND credit == 0) OR (credit > 0 AND debit == 0)`.
   - `Categories` (lines 30–45):
     `id`, `name`, `kind` (`INCOME`, `EXPENSE`), `ledgerAccountId`, `iconCode`, `colorHex`, `isDefault`, `isArchived`. Seeded with 8 defaults: `Lương`, `Thưởng` (Income) and `Ăn uống`, `Di chuyển`, `Hoá đơn & Tiện ích`, `Nhà cửa`, `Mua sắm`, `Y tế` (Expense).
   - `LedgerAccounts` (lines 12–25):
     `id`, `name`, `kind` (`ASSET_CASH`, `ASSET_BANK`, `LIABILITY_CREDIT_CARD`, `INCOME`, `EXPENSE`, `EQUITY_OPENING`), `isLiquid`, `creditLimit`, `isArchived`, `createdAt`.
   - `Envelopes` (lines 107–127):
     `id`, `name`, `policy` (`PROTECTED`, `FLEXIBLE`), `reservedBalanceVnd`, `allowNegativeException`, `targetAmountVnd`, `isArchived`.

3. **`lib/domain/ledger/` Domain Contracts**:
   - `PostTransactionCommand` (`lib/domain/ledger/post_transaction_command.dart`):
     Dedicated typed factory constructors:
     * `.openingAsset(assetAccountId, amountVnd, occurredAt, ...)`
     * `.openingDebt(creditCardAccountId, amountVnd, occurredAt, ...)`
     * `.income(receivingAssetAccountId, categoryId, amountVnd, occurredAt, description, ...)`
     * `.expense(sourceAccountId, categoryId, amountVnd, occurredAt, description, linkedEnvelopeId, ...)`
     * `.creditCardPayment(creditCardAccountId, sourceAssetAccountId, amountVnd, occurredAt, ...)`
     * `.transfer(sourceAssetAccountId, destinationAssetAccountId, amountVnd, occurredAt, ...)`
     * `.refund(receivingAccountId, categoryId, amountVnd, occurredAt, description, linkedEnvelopeId, ...)`
   - `PostingMatrix` (`lib/domain/ledger/posting_matrix.dart`):
     System accounts: `equityOpeningAccountId = 1`, `defaultIncomeAccountId = 2`, `defaultExpenseAccountId = 3`.

4. **`docs/DESIGN_AND_TEST_PLAN.md` & `AGENTS.md` Constraints**:
   - Zero Floating Point: All monetary amounts are 64-bit `int` (`VndMoney`).
   - Tabular Figures: Every widget displaying currency, percentage, or dates must use `fontFeatures: [FontFeature.tabularFigures()]` via `VndFormatter.withTabularFigures(style)`.
   - Clean Query Invariant: UI feeds query `status = 'POSTED' AND tx_type != 'REVERSAL'`.
   - Semantics identifiers strictly mapped to Section 4.

---

## 2. LOGIC CHAIN & ARCHITECTURAL BLUEPRINT

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        RIVERPOD STATE LAYER                            │
│  [cleanTransactionsProvider]   [accountsWithBalancesProvider]          │
│  [transactionFilterProvider]   [transactionControllerProvider]         │
│  [categoriesProvider]          [envelopesProvider]                     │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
         ┌───────────────────────────┴───────────────────────────┐
         ▼                                                       ▼
┌──────────────────────────────┐        ┌──────────────────────────────┐
│  TAB 1: TRANSACTIONS SCREEN  │        │       ACCOUNTS SCREEN        │
│  - Search & Filter Bar       │        │  - Total Assets & Net Worth  │
│  - Account Quick Cards       │        │  - Cash Group (ASSET_CASH)   │
│  - DayGroupedTransactionFeed │        │  - Bank Group (ASSET_BANK)   │
│  - TransactionDetailSheet    │        │  - Card Group (LIABILITY)    │
│    ├── Void Action Dialog    │        │    (used, limit, remaining)  │
│    ├── Edit Action Flow      │        │  - Add/Edit Account Modal    │
│    └── AuditHistorySheet     │        └──────────────────────────────┘
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│    QUICK-ADD MODAL SHEET     │
│  - Live Formatted Amount     │
│  - CustomKeypad Entry (4x3)  │
│  - 5-Way Segmented Selector  │
│  - Dynamic Form Fields       │
│  - Envelope Deficit Guard    │
│  - Idempotency Key Guard     │
└──────────────────────────────┘
```

### 2.1 Enriched Transaction Presentation Model
Because `journal_transactions` is normalized and decoupled from accounts/categories in double-entry bookkeeping, the feature layer defines an immutable enriched presentation entity:

```dart
// lib/features/transactions/domain/models/transaction_item.dart

import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../domain/ledger/transaction_type.dart';

@immutable
class TransactionItem {
  final JournalTransaction transaction;
  final int amountVnd;
  final TransactionType type;
  final Category? category;
  final LedgerAccount? sourceAccount;
  final LedgerAccount? destinationAccount;
  final Envelope? linkedEnvelope;
  final List<JournalPosting> postings;

  const TransactionItem({
    required this.transaction,
    required this.amountVnd,
    required this.type,
    this.category,
    this.sourceAccount,
    this.destinationAccount,
    this.linkedEnvelope,
    this.postings = const [],
  });

  int get id => transaction.id;
  String get description => transaction.description;
  DateTime get occurredAt => DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
  String? get idempotencyKey => transaction.idempotencyKey;
}
```

#### Enriched Item Resolution Algorithm
Given a `JournalTransaction tx`, postings `List<JournalPosting> postings`, `Map<int, LedgerAccount> accountMap`, `Map<int, Category> categoryMap`, and `Map<int, Envelope> envelopeMap`:
1. **Amount Resolution**:
   $$amountVnd = \max_{p \in postings} (p.debitVnd)$$
2. **Type Resolution**: `TransactionType.fromDbValue(tx.txType)`.
3. **Category Resolution**: Find posting $p$ with `p.categoryId != null` $\implies categoryMap[p.categoryId]$.
4. **Envelope Resolution**: Find posting $p$ with `p.envelopeId != null` $\implies envelopeMap[p.envelopeId]$.
5. **Account Resolution per Type**:
   - `EXPENSE`: `sourceAccount = accountMap[postings.firstWhere((p) => p.creditVnd > 0).accountId]`.
   - `INCOME`: `destinationAccount = accountMap[postings.firstWhere((p) => p.debitVnd > 0).accountId]`.
   - `TRANSFER`:
     * `sourceAccount = accountMap[postings.firstWhere((p) => p.creditVnd > 0).accountId]`
     * `destinationAccount = accountMap[postings.firstWhere((p) => p.debitVnd > 0).accountId]`
   - `CREDIT_CARD_PAYMENT`:
     * `sourceAccount = accountMap[postings.firstWhere((p) => p.creditVnd > 0).accountId]` (Asset Cash/Bank)
     * `destinationAccount = accountMap[postings.firstWhere((p) => p.debitVnd > 0).accountId]` (Credit Card)
   - `REFUND`:
     * `destinationAccount = accountMap[postings.firstWhere((p) => p.debitVnd > 0).accountId]`
   - `OPENING_BALANCE`:
     * If asset: `destinationAccount = accountMap[postings.firstWhere((p) => p.debitVnd > 0).accountId]`
     * If card: `sourceAccount = accountMap[postings.firstWhere((p) => p.creditVnd > 0).accountId]`

---

### 2.2 Transactions Screen (`lib/features/transactions/presentation/transactions_screen.dart`)

#### UI Layout Hierarchy
1. **AppBar**:
   - Title: "Giao dịch" (`AppTypography.title`).
   - Actions:
     * Manage Accounts Button (`Semantics(identifier: 'btn_manage_accounts')`): opens `AccountsScreen`.
     * Quick-Add Button / Search toggle.
2. **Account Balances Carousel / Header**:
   - Horizontal scrolling list of active accounts with balances (`card_account_<id>`).
   - Displays Quick Cash, Bank, and Card balances with tabular figures.
3. **Search & Filter Bar**:
   - Search text input (`Semantics(identifier: 'input_search_tx')`): Filters live on note/description or category name.
   - Filter Chips Row:
     * `Tất cả` (`chip_filter_all`)
     * `Chi tiêu` (`chip_filter_expense`)
     * `Thu nhập` (`chip_filter_income`)
     * `Chuyển khoản` (`chip_filter_transfer`)
     * `Bộ lọc ngày` (opens Date Range Picker).
4. **Day-Grouped Transaction Feed** (`ListView.builder`):
   - Items grouped by local calendar day (`DateTime(Y, M, D)`).
   - **Sticky / Section Day Header**:
     * Left: Calendar date in Vietnamese (`vi_VN`):
       - If today: "Hôm nay, 27/10/2026"
       - If yesterday: "Hôm qua, 26/10/2026"
       - Else: "Thứ Hai, 25/10/2026"
     * Right: Net daily balance:
       $$\text{Daily Net} = \sum \text{Income} - \sum \text{Expense}$$
       Rendered with tabular figures:
       - If net > 0: `+20.000.000 ₫` in `AppColors.textAccentVerdantPrimary`.
       - If net < 0: `-150.000 ₫` in `AppColors.textAccentRubySecondary`.
       - If net == 0: `0 ₫` in `AppColors.textSecondary`.
   - **Transaction Item Row** (`Semantics(identifier: 'item_transaction_<id>')`):
     * Leading: Category icon container (40x40 circle, background `colorHex` with 15% opacity, icon colored `colorHex`). If transfer, `Icons.swap_horiz` in sandstone. If card payment, `Icons.credit_card` in ember.
     * Title: Category name (or "Chuyển tiền sang Vietcombank" / "Thanh toán thẻ") (`AppTypography.bodyMedium`).
     * Subtitle:
       - Account name(s): e.g. "Tiền mặt" or "Vietcombank -> Tiền mặt".
       - Note snippet (if provided).
       - Envelope tag (if linked, e.g. "Quỹ Ăn uống").
     * Trailing:
       - Amount formatted with sign:
         * `EXPENSE`: `-100.000 ₫` (`AppColors.textPrimary` or `textAccentRubySecondary`).
         * `INCOME`: `+20.000.000 ₫` (`AppColors.textAccentVerdantPrimary`).
         * `REFUND`: `+50.000 ₫` (`AppColors.textAccentVerdantSecondary`).
         * `TRANSFER`: `2.000.000 ₫` (`AppColors.textPrimary`).
         * `CREDIT_CARD_PAYMENT`: `-500.000 ₫` (`AppColors.textPrimary`).
       - Typography: `AppTypography.bodyMedium` with `FontFeature.tabularFigures()`.
     * Tap: Opens `TransactionDetailSheet`.

---

### 2.3 Quick-Add Transaction Modal Sheet (`lib/features/transactions/presentation/quick_add_modal.dart`)

```text
┌────────────────────────────────────────────────────────┐
│  ──── (Grabber)                                        │
│  Thêm giao dịch                             [ X ]      │
├────────────────────────────────────────────────────────┤
│                     1.250.000 ₫                        │
│               (input_amount_display)                   │
├────────────────────────────────────────────────────────┤
│ [ Chi tiêu ] [ Thu nhập ] [ Chuyển ] [ Trả thẻ ] [Hoàn]│
│ (Segmented Transaction Type Selector)                  │
├────────────────────────────────────────────────────────┤
│ [ Ăn uống ] [ Di chuyển ] [ Hoá đơn ] [ Mua sắm ] ...  │
│ (Category Chips Grid)                                  │
├────────────────────────────────────────────────────────┤
│ Tài khoản: [ Tiền mặt ] [ Vietcombank ] [ VPBank Visa ]│
│ (Source Account Chips)                                 │
├────────────────────────────────────────────────────────┤
│ Quỹ tiền (tuỳ chọn): [ Quỹ Ăn uống (còn 500k) ]        │
│ ⚠️ Bội chi: Vượt số dư quỹ 750.000 ₫                   │
├────────────────────────────────────────────────────────┤
│ Ghi chú: [ Mua thực phẩm siêu thị                    ] │
│ Ngày: [ Hôm nay, 27/10/2026                          ] │
├────────────────────────────────────────────────────────┤
│             CUSTOM NUMERIC KEYPAD                      │
│        [ 1 ]        [ 2 ]        [ 3 ]                 │
│        [ 4 ]        [ 5 ]        [ 6 ]                 │
│        [ 7 ]        [ 8 ]        [ 9 ]                 │
│        [ . ]        [ 0 ]        [ < ]                 │
├────────────────────────────────────────────────────────┤
│             [ LƯU GIAO DỊCH (btn_submit) ]             │
└────────────────────────────────────────────────────────┘
```

#### Detailed Component Specifications
1. **Modal Container**:
   - `Semantics(identifier: 'modal_quick_add')`.
   - `BorderRadius.vertical(top: Radius.circular(24.0))`.
   - Background: `AppColors.surfacePrimary` (`#FFFFFF`).
2. **Live Amount Display**:
   - `Semantics(identifier: 'input_amount_display')`.
   - Displays current entered integer VND: `VndFormatter.format(currentAmount)`.
   - Text Style: `AppTypography.largeTitle` (32px w500) with `FontFeature.tabularFigures()`.
   - Color: `AppColors.textPrimary`.
3. **Custom Numeric Keypad (`CustomKeypad`)**:
   - Integrated directly from `lib/core/widgets/custom_keypad.dart`.
   - Buttons: `keypad_btn_0` through `keypad_btn_9`, and `keypad_btn_backspace`.
   - Digit append logic:
     ```dart
     void onDigitPressed(int digit) {
       final newAmount = currentAmount * 10 + digit;
       if (newAmount <= VndMoney.maxSafeVnd) {
         currentAmount = newAmount;
       }
     }
     void onBackspacePressed() {
       currentAmount = currentAmount ~/ 10;
     }
     ```
4. **Segmented Type Selector**:
   - 5 Segments with identifiers:
     * `Chi tiêu` $\implies$ `segment_expense`
     * `Thu nhập` $\implies$ `segment_income`
     * `Chuyển khoản` $\implies$ `segment_transfer`
     * `Trả thẻ` $\implies$ `segment_card_payment`
     * `Hoàn tiền` $\implies$ `segment_refund`
5. **Dynamic Form Fields per Type**:
   - **`EXPENSE`**:
     * Categories: Expense categories (`Categories.kind == 'EXPENSE'`) rendered as selectable chips (`chip_category_<id>`).
     * Source Account: Selectable chips (`chip_source_account_<id>`) for active accounts (`ASSET_CASH`, `ASSET_BANK`, `LIABILITY_CREDIT_CARD`).
     * Optional Envelope: Dropdown/chips (`chip_envelope_<id>`) showing envelope name and reserved balance.
     * **Envelope Deficit Check**:
       If `selectedEnvelope != null` and `currentAmount > selectedEnvelope.reservedBalanceVnd`:
       - If `selectedEnvelope.allowNegativeException == false`:
         Render inline red alert banner: "Số tiền chi tiêu (${format(currentAmount)}) vượt quá số dư quỹ (${format(selectedEnvelope.reservedBalanceVnd)}). Quỹ này không cho phép bội chi." The submit button displays a disabled/warning state unless user selects a different envelope or reduces amount.
       - If `selectedEnvelope.allowNegativeException == true`:
         Render inline amber warning: "Chi tiêu vượt số dư quỹ (${format(selectedEnvelope.reservedBalanceVnd)}). Quỹ sẽ chuyển sang số dư âm." Allowed to submit.
   - **`INCOME`**:
     * Categories: Income categories (`Categories.kind == 'INCOME'`) (`chip_category_<id>`).
     * Destination Account: Liquid accounts only (`ASSET_CASH`, `ASSET_BANK`) (`chip_dest_account_<id>`).
   - **`TRANSFER`**:
     * Source Account: Liquid accounts (`ASSET_CASH`, `ASSET_BANK`) (`chip_source_account_<id>`).
     * Destination Account: Liquid accounts (`chip_dest_account_<id>`), must differ from source account.
     * Category is hidden.
   - **`CREDIT_CARD_PAYMENT`**:
     * Source Account: Liquid accounts (`ASSET_CASH`, `ASSET_BANK`) (`chip_source_account_<id>`).
     * Destination Account: Credit Card accounts (`LIABILITY_CREDIT_CARD`) (`chip_dest_account_<id>`).
     * Category is hidden.
   - **`REFUND`**:
     * Category: Expense categories (`Categories.kind == 'EXPENSE'`).
     * Receiving Account: Cash, Bank, or Credit Card (`chip_dest_account_<id>`).
     * Optional Envelope: Envelope to restore spent reserve into via `REFUND_RESTORE`.
6. **Idempotency Guard**:
   - A unique `idempotencyKey` is generated upon opening the modal:
     `'quickadd_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(999999)}'`.
   - Double-tap guard: `isSubmitting` flag locks UI during `await`.
7. **Submit Button**:
   - `Semantics(identifier: 'btn_submit_transaction')`.
   - Full-width Ember pill button (`AppColors.fillAccentEmberPrimary` `#FD8240`), label "Lưu giao dịch".

---

### 2.4 Transaction Detail & Action Dialogs (`lib/features/transactions/presentation/transaction_detail_sheet.dart`)

When a user taps an item row, `TransactionDetailSheet` (`Semantics(identifier: 'sheet_transaction_detail')`) slides up:
- Header: Amount in large font, type badge, status badge (`POSTED`).
- Metadata table:
  * Date & Time (`occurredAt`).
  * Category & Icon.
  * Source Account / Destination Account.
  * Linked Envelope (if any).
  * Note / Description.
  * Transaction ID & Idempotency key.
- Action Buttons:
  1. **"Lịch sử chỉnh sửa"** (`Semantics(identifier: 'btn_audit_history')`):
     Opens `AuditHistorySheet`.
  2. **"Chỉnh sửa"** (`Semantics(identifier: 'btn_edit_transaction')`):
     Opens Quick-Add pre-populated with transaction data. On save, invokes `editTransaction(...)`.
  3. **"Hủy giao dịch"** (`Semantics(identifier: 'btn_void_transaction')`):
     Opens Void Confirmation Dialog.

#### Void Confirmation Dialog
- Dialog Title: "Xác nhận hủy giao dịch"
- Body:
  "Hành động này sẽ tạo một bút toán đảo ngược (Reversal) để hoàn nguyên toàn bộ số dư và quỹ tiền liên quan. Lịch sử kế toán được lưu trữ nguyên vẹn."
- Actions:
  * "Đóng" (Cancel)
  * "Hủy giao dịch" (Danger button, `AppColors.fillAccentRubyPrimary`).
- On Confirm: Calls `ref.read(transactionControllerProvider.notifier).voidTransaction(tx.id)`.

---

### 2.5 Audit History Sheet (`lib/features/transactions/presentation/audit_history_sheet.dart`)

#### Revision & Reversal Chain Resolution Algorithm
To build the chronological timeline for transaction $T_{target}$:
1. **Collect Root**:
   Query transactions related via `reversesTxId` or `replacedByTxId`:
   ```dart
   Future<List<JournalTransaction>> resolveAuditChain(int txId, AppDatabase db) async {
     final Set<int> allTxIds = {txId};
     bool expanded = true;
     while (expanded) {
       final beforeCount = allTxIds.length;
       final related = await (db.select(db.journalTransactions)
             ..where((t) =>
                 t.id.isIn(allTxIds) |
                 t.reversesTxId.isIn(allTxIds) |
                 t.replacedByTxId.isIn(allTxIds)))
           .get();
       for (final r in related) {
         allTxIds.add(r.id);
         if (r.reversesTxId != null) allTxIds.add(r.reversesTxId!);
         if (r.replacedByTxId != null) allTxIds.add(r.replacedByTxId!);
       }
       expanded = allTxIds.length > beforeCount;
     }
     final list = await (db.select(db.journalTransactions)
           ..where((t) => t.id.isIn(allTxIds))
           ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
         .get();
     return list;
   }
   ```
2. **Timeline Visual Representation**:
   - Container: `Semantics(identifier: 'sheet_audit_history')`.
   - Title: "Lịch sử chỉnh sửa & hoàn tác".
   - Vertical timeline connecting nodes:
     * **Node 1 (Khởi tạo / Original)**:
       - Icon: `Icons.add_circle_outline` (Verdant `#4E886F`).
       - Status badge: `POSTED` or `SUPERSEDED`.
       - Description: Original note, occurred date, amount.
     * **Node 2 (Đảo ngược / Reversal)** (if present):
       - Icon: `Icons.undo` (Ruby `#E0462F`).
       - Status badge: `REVERSAL`.
       - Description: "Hoàn tác bút toán #$reversesTxId", inverted debit/credit balance.
     * **Node 3 (Thay thế / Replacement)** (if edited):
       - Icon: `Icons.edit` (Ember `#E86B1C`).
       - Status badge: `POSTED`.
       - Description: New transaction amount, new category/account.

---

### 2.6 Accounts Screen (`lib/features/accounts/presentation/accounts_screen.dart`)

```text
┌────────────────────────────────────────────────────────┐
│  ← Tài khoản & Dư nợ                        [ + Thêm ] │
├────────────────────────────────────────────────────────┤
│  TỔNG TÀI SẢN THANH KHOẢN:      30.000.000 ₫           │
│  TỔNG DƯ NỢ THẺ TÍN DỤNG:          500.000 ₫           │
│  GIÁ TRỊ TÀI SẢN RÒNG:          29.500.000 ₫           │
├────────────────────────────────────────────────────────┤
│  TIỀN MẶT                                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 💵 Ví tiền mặt                      9.900.000 ₫  │  │
│  └──────────────────────────────────────────────────┘  │
│  NGÂN HÀNG & VÍ ĐIỆN TỬ                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 🏦 Vietcombank                     20.000.000 ₫  │  │
│  └──────────────────────────────────────────────────┘  │
│  THẺ TÍN DỤNG                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 💳 VPBank Visa Step Up                           │  │
│  │ Dư nợ hiện tại:                       500.000 ₫  │  │
│  │ Hạn mức:                           10.000.000 ₫  │  │
│  │ Hạn mức khả dụng:                   9.500.000 ₫  │  │
│  │ [██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 5% đã dùng    │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

#### Detailed Account Grouping & Math
1. **Summary Header Card**:
   - **Tổng tài sản thanh khoản** (`totalLiquidAssets`): Sum of `balanceVnd` for active accounts where `isLiquid == true`.
   - **Tổng dư nợ thẻ** (`totalCardDebt`): Sum of `balanceVnd` for active `LIABILITY_CREDIT_CARD` accounts.
   - **Giá trị tài sản ròng** (`netWorth`):
     $$\text{Net Worth} = \text{totalLiquidAssets} - \text{totalCardDebt}$$
2. **Account Grouping**:
   - Group 1: **Tiền mặt** (`ASSET_CASH`):
     Card showing name, icon `Icons.payments_outlined`, balance with tabular figures.
   - Group 2: **Ngân hàng & Ví điện tử** (`ASSET_BANK`):
     Card showing bank name, icon `Icons.account_balance_outlined`, balance.
   - Group 3: **Thẻ tín dụng** (`LIABILITY_CREDIT_CARD`):
     Card showing:
     * Card name, icon `Icons.credit_card_outlined`.
     * **Dư nợ hiện tại** (`balanceVnd`): formatted in ruby/charcoal.
     * **Hạn mức thẻ** (`creditLimit`): formatted in whole VND.
     * **Hạn mức khả dụng** (`remainingCredit`):
       $$\text{remainingCredit} = \max(0, \text{creditLimit} - \text{balanceVnd})$$
     * **Thanh tỷ lệ sử dụng hạn mức** (Progress Bar):
       $$\text{utilizationPct} = \text{creditLimit} > 0 ? \min(1.0, \text{balanceVnd} / \text{creditLimit}) : 0.0$$
       Color transitions: Verdant (<50%), Marigold (50–80%), Ruby (>80%).
3. **Add / Edit Account Modal (`AddEditAccountModal`)**:
   - Semantics: `modal_add_account`.
   - Kind Selector: `Tiền mặt` (`ASSET_CASH`), `Ngân hàng` (`ASSET_BANK`), `Thẻ tín dụng` (`LIABILITY_CREDIT_CARD`).
   - Account Name text field.
   - Credit limit integer field (visible only if Credit Card).
   - Initial Balance (Số dư ban đầu) field:
     * If amount > 0: On creation, automatically issues `postTransactionCommand`:
       - For Cash/Bank: `PostTransactionCommand.openingAsset(...)` (Debit account, Credit `EQUITY_OPENING`).
       - For Card: `PostTransactionCommand.openingDebt(...)` (Debit `EQUITY_OPENING`, Credit account).
   - Submit button: `Semantics(identifier: 'btn_submit_account')`.

---

### 2.7 Riverpod State Management Architecture

```dart
// lib/features/transactions/presentation/controllers/transaction_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../domain/ledger/post_transaction_command.dart';
import '../../../../domain/ledger/transaction_type.dart';
import '../../domain/models/transaction_item.dart';

// Database & DAO Providers
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final ledgerDaoProvider = Provider<LedgerDao>((ref) => ref.watch(databaseProvider).ledgerDao);

// Clean Transactions Stream Provider
final cleanTransactionsStreamProvider = StreamProvider<List<JournalTransaction>>((ref) {
  return ref.watch(ledgerDaoProvider).watchCleanTransactions();
});

// Accounts With Balances Stream Provider
final accountsWithBalancesProvider = StreamProvider<List<AccountWithBalance>>((ref) {
  return ref.watch(ledgerDaoProvider).watchAccountsWithBalances();
});

// Total Liquid Assets Stream Provider
final totalLiquidAssetsProvider = StreamProvider<int>((ref) {
  return ref.watch(ledgerDaoProvider).watchTotalLiquidAssets();
});

// Net Worth Stream Provider
final netWorthProvider = StreamProvider<int>((ref) {
  return ref.watch(ledgerDaoProvider).watchNetWorth();
});

// Categories Stream Provider
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)..where((c) => c.isArchived.equals(false))).watch();
});

// Envelopes Stream Provider
final envelopesProvider = StreamProvider<List<Envelope>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.envelopes)..where((e) => e.isArchived.equals(false))).watch();
});

// Filter State Class
class TransactionFilterState {
  final String searchQuery;
  final TransactionType? typeFilter;
  final int? accountIdFilter;
  final int? categoryIdFilter;
  final int? envelopeIdFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({
    this.searchQuery = '',
    this.typeFilter,
    this.accountIdFilter,
    this.categoryIdFilter,
    this.envelopeIdFilter,
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    String? searchQuery,
    TransactionType? typeFilter,
    int? accountIdFilter,
    int? categoryIdFilter,
    int? envelopeIdFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
  }) {
    return TransactionFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      accountIdFilter: accountIdFilter ?? this.accountIdFilter,
      categoryIdFilter: categoryIdFilter ?? this.categoryIdFilter,
      envelopeIdFilter: envelopeIdFilter ?? this.envelopeIdFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// Filter State Notifier
class TransactionFilterNotifier extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() => const TransactionFilterState();

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setTypeFilter(TransactionType? type) => state = state.copyWith(typeFilter: type, clearType: type == null);
  void resetFilters() => state = const TransactionFilterState();
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilterState>(TransactionFilterNotifier.new);

// Enriched & Filtered Transactions Provider
final enrichedTransactionsProvider = Provider<AsyncValue<List<TransactionItem>>>((ref) {
  final txAsync = ref.watch(cleanTransactionsStreamProvider);
  final accountsAsync = ref.watch(accountsWithBalancesProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final envelopesAsync = ref.watch(envelopesProvider);
  final filter = ref.watch(transactionFilterProvider);
  final db = ref.watch(databaseProvider);

  if (txAsync.isLoading || accountsAsync.isLoading || categoriesAsync.isLoading || envelopesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (txAsync.hasError) return AsyncValue.error(txAsync.error!, txAsync.stackTrace!);

  final rawTxList = txAsync.value ?? [];
  final accountMap = {for (final a in accountsAsync.value ?? []) a.id: a};
  final categoryMap = {for (final c in categoriesAsync.value ?? []) c.id: c};
  final envelopeMap = {for (final e in envelopesAsync.value ?? []) e.id: e};

  // Convert to TransactionItem and apply filters in memory
  // (Full batch mapping logic with postings queries)
  ...
});

// Transaction Controller Notifier (AsyncNotifier for Mutations)
class TransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> postTransaction(PostTransactionCommand command) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(ledgerDaoProvider);
      final txId = await dao.postTransactionCommand(command);
      state = const AsyncValue.data(null);
      return txId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> voidTransaction(int txId) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(ledgerDaoProvider);
      await dao.voidTransaction(txId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<int> editTransaction({
    required int originalTxId,
    required PostTransactionCommand newCommand,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(ledgerDaoProvider);
      final newTxId = await dao.editTransaction(
        originalTxId: originalTxId,
        txType: newCommand.txType.dbValue,
        description: newCommand.description,
        occurredAt: newCommand.occurredAt,
        newPostings: newCommand.postings,
        linkedEnvelopeId: newCommand.linkedEnvelopeId,
        envelopeMovementType: newCommand.envelopeMovementType,
      );
      state = const AsyncValue.data(null);
      return newTxId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, void>(TransactionController.new);
```

---

## 3. CAVEATS

1. **Cross-Layer Mutation Ban**:
   Neither `lib/core/database/` nor `lib/domain/` can be altered by feature workers. All queries for enriched presentation must consume existing methods in `LedgerDao` and Drift tables directly.
2. **Shared UI Components Dependency**:
   `CustomKeypad`, `AppColors`, `AppTypography`, and `AppSpacing` are owned by `worker_m3_ui_core`. `worker_m3_transactions` must import from `package:dongtien/app/theme/` and `package:dongtien/core/widgets/custom_keypad.dart`.
3. **Vietnamese Numbering Strictness**:
   Never use `double.parse()` or division producing floats. Always use `VndMoney` and `VndFormatter.format()`.

---

## 4. CONCLUSION & CONCRETE FILE INVENTORY

The implementation of Transactions (Tab 1) and Accounts is completely specified, respects double-entry invariants, enforces tabular typography, and guarantees offline-first reliability.

### Concrete Implementation Files for `worker_m3_transactions`
```text
lib/features/
├── transactions/
│   ├── domain/
│   │   └── models/
│   │       ├── transaction_item.dart           # Enriched presentation transaction entity
│   │       └── day_grouped_transactions.dart   # Day-grouped bucket model with daily net
│   ├── presentation/
│   │   ├── controllers/
│   │   │   ├── transaction_providers.dart      # Streams, filters, enriched items
│   │   │   └── transaction_controller.dart     # AsyncNotifier for post, void, edit
│   │   ├── widgets/
│   │   │   ├── day_group_header.dart           # Calendar day header + daily net total
│   │   │   ├── transaction_list_tile.dart      # Row tile with category icon & tabular amount
│   │   │   └── transaction_filter_bar.dart     # Search bar & filter chips
│   │   ├── quick_add_modal.dart                # Keypad + 5-way segmented type selector
│   │   ├── transaction_detail_sheet.dart       # Detail view with void/edit actions
│   │   ├── audit_history_sheet.dart            # Chronological revision & reversal timeline
│   │   └── transactions_screen.dart            # Tab 1 scaffold with feed & account bar
└── accounts/
    ├── presentation/
    │   ├── controllers/
    │   │   └── account_controller.dart         # Account creation & update notifier
    │   ├── widgets/
    │   │   ├── cash_account_card.dart          # Cash account card
    │   │   ├── bank_account_card.dart          # Bank account card
    │   │   └── credit_card_card.dart           # Card with used, limit, remaining & bar
    │   ├── add_edit_account_modal.dart         # Add/edit account modal with opening balance
    │   └── accounts_screen.dart                # Accounts management screen
```

---

## 5. VERIFICATION METHOD & WIDGET TEST PLAN

### 5.1 Static Analysis & Formatting Commands
```bash
dart format --output=none --set-exit-if-changed lib/features/transactions/ lib/features/accounts/ test/widget/
flutter analyze lib/features/transactions/ lib/features/accounts/
```

### 5.2 Widget Test Scenarios (`test/widget/`)
Write widget tests in `test/widget/transactions_widget_test.dart` and `test/widget/accounts_widget_test.dart`:

| Test Case | Scenario Verified | Assertions & Semantics Checks |
|---|---|---|
| **Test 1: Quick-Add Expense Entry** | Scenario 3 | Tap `fab_quick_add` -> Enter `100000` on `CustomKeypad` -> Tap `segment_expense` -> Select Category `Ăn uống` (`chip_category_3`) -> Select Account `Tiền mặt` -> Tap `btn_submit_transaction`. Verify feed displays `-100.000 ₫` under "Hôm nay". |
| **Test 2: Internal Transfer Entry** | Scenario 4 | Quick-Add -> Enter `2000000` -> Tap `segment_transfer` -> Source `Vietcombank` -> Dest `Tiền mặt` -> Submit. Verify liquid assets unchanged and category is hidden. |
| **Test 3: Credit Card Purchase & Card Screen** | Scenario 6 | Quick-Add -> Enter `500000` -> `segment_expense` -> Account `VPBank Visa` -> Submit. Navigate to Accounts Screen -> Verify card debt shows `500.000 ₫`, remaining credit `9.500.000 ₫`. |
| **Test 4: Credit Card Payment** | Scenario 7 | Quick-Add -> Enter `500000` -> `segment_card_payment` -> Source `Vietcombank` -> Dest `VPBank Visa` -> Submit. Verify card debt becomes `0 ₫` and gross expense is UNCHANGED. |
| **Test 5: Void Transaction & Clean Feed Filter** | Scenario 9 (Part A) | Open transaction item -> Tap `btn_void_transaction` -> Confirm dialog. Verify original transaction disappears from clean feed (`watchCleanTransactions`) and account balance reverts. |
| **Test 6: Edit Transaction & Audit Timeline** | Scenario 9 (Part B) | Open transaction item -> Tap `btn_edit_transaction` -> Change amount from `200.000 ₫` to `250.000 ₫` -> Submit. Tap `btn_audit_history` -> Verify timeline displays Original (`SUPERSEDED`), Reversal (`REVERSAL`), and New (`POSTED`). |
| **Test 7: Idempotency Double-Tap Prevention** | Scenario 10 | Quick-Add -> Fast double-tap `btn_submit_transaction`. Verify exactly 1 transaction is inserted into SQLite. |
| **Test 8: Envelope Deficit Guard** | R3 & Section 5.1 | Select envelope with `balance = 100.000 ₫` and enter amount `500.000 ₫`. Verify inline deficit warning appears when `allowNegativeException == false`. |
