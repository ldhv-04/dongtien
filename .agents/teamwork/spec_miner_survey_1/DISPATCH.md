## 2026-10-27T10:07:13Z
Sender: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
Priority: MESSAGE_PRIORITY_HIGH

You are spec_miner_survey_1, working as Financial Spec & Invariant Miner.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_1
Read the authoritative user request at: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
Read the build specification at: c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md

Your task is to thoroughly analyze and extract the complete specifications for the Financial Domain and Persistence layer of DongTien:
1. Monetary Representation: VndMoney value type, 64-bit integer (whole VND), overflow prevention (max_Safe_VND = 9_000_000_000_000_000), vi_VN formatting (1.250.000 ₫, tabular numerals, zero decimals).
2. Drift Database Schema:
   - Detailed specification of all 9 tables: ledger_accounts, categories, journal_transactions, journal_postings, envelopes, envelope_movements, category_budgets, scheduled_items, settings.
   - Column names, data types, constraints, foreign keys, cascade rules, PRAGMA foreign_keys = ON.
   - Initial Vietnamese seeding: default categories (Ăn uống, Di chuyển, Hoá đơn & Tiện ích, Nhà cửa, Mua sắm, Y tế, Lương, Thưởng) and system ledger accounts (EQUITY_OPENING) with 0 ₫ balances.
3. Double-Entry Posting Matrix & Invariants:
   - Debit / Credit rules for all 7 transaction types: OPENING_BALANCE (Asset/Card Debt), INCOME, EXPENSE (Cash/Bank vs Credit Card), CREDIT_CARD_PAYMENT, INTERNAL_TRANSFER, REFUND, REVERSAL.
   - Strict transaction invariant: SUM(debit_vnd) == SUM(credit_vnd).
4. Atomic Envelope Linkage & Movement Engine:
   - Movement types: ALLOCATE, RELEASE, TRANSFER, SPEND, REFUND_RESTORE, REVERSAL.
   - Atomic linkage inside db.transaction() when transactions involve an envelope.
5. Account Balance Derivation:
   - Dynamic derivation across all postings (Asset/Expense = Debit - Credit, Liability/Income/Equity = Credit - Debit). No mutable cached balances.
6. Reversal & Edit Engine:
   - Void vs Edit rules, status transition (POSTED, SUPERSEDED, VOIDED), REVERSAL transaction, reverses_tx_id, replaced_by_tx_id.
   - UI filtering: WHERE status = 'POSTED' AND tx_type != 'REVERSAL'.
7. Deterministic Domain Algorithms:
   - Available-to-allocate formula: total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd. Over-allocation prevention.
   - Category spending, refunds, net expense, savings rate, handling of net recovery and zero income.
   - Safe-to-Spend formula: Liquid Assets - Protected Reserves - Unfunded Committed Outflows - Minimum Cash Buffer (zero double-counting with protected envelopes, exact negative shortfall breakdown).
   - Savings goals & feasibility advisor: ceiling division, overdue/achieved, infeasibility triggers, 3 one-tap calculators.
   - Month-end recurrence & cash-flow forecast: anchor day 1..31 with min(anchor_day, daysInMonth(Y, M)) (no drift across Feb), 30/60/90-day daily balance projection.
8. The 15 Mandatory Acceptance Scenarios:
   - Detailed breakdown of each scenario (1 through 15) with exact numbers, state transitions, and expected assertion values.

Maintain progress.md in your working directory with timestamps.
When complete, write your comprehensive specification report to:
c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_1\handoff.md
And send a completion message back with summary and handoff path.
