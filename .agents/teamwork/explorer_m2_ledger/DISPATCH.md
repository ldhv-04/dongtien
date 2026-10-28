## 2026-10-27T18:51:51Z
You are explorer_m2_ledger.
Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_ledger
Read:
- c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
- c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md (Sections 1, 2, 3, 4, 5)
- c:\Users\coihu12\Documents\App\lib\core\database\app_database.dart

Investigate and produce a detailed implementation blueprint for:
1. Pure Dart ledger domain models & exceptions in `lib/domain/ledger/`:
   - AccountKind, TransactionType, TransactionStatus, PostingMatrix, UnbalancedTransactionException.
   - Exact posting rules for all 7 transaction types:
     1: OPENING_BALANCE (Asset: Cash/Bank Debit, Equity Credit)
     2: OPENING_BALANCE (Debt: Equity Debit, Credit Card Liability Credit)
     3: INCOME (Cash/Bank Debit, Category-linked Income Credit)
     4: EXPENSE (Cash/Bank: Category-linked Expense Debit, Cash/Bank Credit; optional SPEND movement)
     5: EXPENSE (Card: Category-linked Expense Debit, Credit Card Liability Credit; optional SPEND movement)
     6: CREDIT_CARD_PAYMENT (Credit Card Liability Debit, Cash/Bank Credit; NEVER an expense)
     7: INTERNAL_TRANSFER (Destination Asset Debit, Source Asset Credit)
     8: REFUND (Asset/Card Debit, Category-linked Expense Credit; optional REFUND_RESTORE movement)
     9: REVERSAL (Inverted target credit and debit accounts; optional REVERSAL movement)
   - Assertion invariant: SUM(debit_vnd) == SUM(credit_vnd).
   - Reversal/Void algorithm: update status to VOIDED, insert REVERSAL transaction with inverted postings, offset linked envelope movements.
   - Edit algorithm: insert REVERSAL of original, insert new POSTED transaction, update original to SUPERSEDED with replaced_by_tx_id.
2. Pure Dart envelope domain models & exceptions in `lib/domain/envelopes/`:
   - EnvelopePolicy (PROTECTED, FLEXIBLE), EnvelopeMovementType (6 types: ALLOCATE, RELEASE, TRANSFER, SPEND, REFUND_RESTORE, REVERSAL).
   - OverAllocationException, SpendingDeficitException.
   - available_to_allocate formula: total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd.
3. Database DAO / service integration in `lib/core/database/daos/` or `lib/core/database/`:
   - LedgerDao and EnvelopeDao implementing the operations inside `db.transaction()`.
   - Dynamic account balance derivation queries (zero cached balance columns):
     * Asset & Expense: SUM(debit) - SUM(credit)
     * Liability, Income & Equity: SUM(credit) - SUM(debit)
     * Total Liquid Assets: SUM(balance) for active accounts with is_liquid == true
     * Net Worth: Asset Balances - Liability Balances
   - Clean UI query filter: WHERE status = 'POSTED' AND tx_type != 'REVERSAL'.
4. Concrete unit and database test plan for `test/unit/` and `test/database/`.

Write your complete report to:
c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_ledger\handoff.md
Notify orchestrator when done.
