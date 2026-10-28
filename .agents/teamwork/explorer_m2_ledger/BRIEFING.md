# BRIEFING — 2026-10-27T18:55:00Z

## Mission
Investigate and produce a detailed, implementation-ready blueprint for M2: Pure Dart ledger domain models & exceptions, envelope domain models & exceptions, database DAO integration, and unit/database test specifications.

## 🔒 My Identity
- Archetype: explorer
- Roles: explorer, synthesis, read-only investigation
- Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_ledger
- Original parent: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Milestone: M2 Ledger & Envelope Domain Blueprint

## 🔒 Key Constraints
- Read-only investigation — do NOT implement in `lib/`
- Zero floating-point currency (VndMoney integer VND 64-bit)
- Immutable double-entry ledger invariant: SUM(debit_vnd) == SUM(credit_vnd)
- Virtual funds (envelopes) decoupled: allocations do NOT alter general ledger postings or liquid assets
- Dynamic balance derivation: no mutable cached balance column on ledger_accounts
- Audit-preserving reversals: void/edit never hard-deletes; status VOIDED / SUPERSEDED + REVERSAL tx

## Current Parent
- Conversation ID: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Updated: 2026-10-27T18:55:00Z

## Investigation State
- **Explored paths**:
  - `lib/core/database/app_database.dart` (All 9 tables, seed data, foreign keys)
  - `lib/core/money/vnd_money.dart` (VndMoney contracts and constraints)
  - `docs/ARCHITECTURE_AND_RULES.md` (Sections 1-5: Posting matrix, balance formulas, reversal/void, envelope rules)
  - `build_spec/dongtien_build_spec.md` (Sections 4 & 5: Schema, posting matrix, algorithms)
  - `test/database/app_database_test.dart` and `test/database/adversarial_schema_test.dart` (Existing 124 passing tests)
- **Key findings**:
  - All 9 tables and foreign keys are operational in SQLite.
  - Domain models in `lib/domain/ledger/` and `lib/domain/envelopes/` must have zero Flutter/Drift imports.
  - `VndMoney` in `lib/core/money/vnd_money.dart` can be imported safely if using pure Dart contracts.
  - The 7 transaction types in DB expand to 9 posting patterns (asset opening, debt opening, income, cash expense, card expense, cc payment, transfer, refund, reversal).
  - Dynamic balance queries must compute:
    - Asset & Expense: SUM(debit) - SUM(credit)
    - Liability, Income & Equity: SUM(credit) - SUM(debit)
    - Liquid Assets: SUM(balance) of active accounts where is_liquid == true
    - Net Worth: Asset Balances - Liability Balances
- **Unexplored areas**: None for M2 Ledger & Envelope scope.

## Key Decisions Made
- Partition into:
  1. `lib/domain/ledger/`: pure Dart enums, models, commands, exceptions, and `PostingMatrix`.
  2. `lib/domain/envelopes/`: pure Dart enums, models, commands, exceptions, and available-to-allocate calculator.
  3. `lib/core/database/daos/`: `LedgerDao` and `EnvelopeDao` extending Drift database accessors, wrapping queries in `db.transaction()`.
  4. Comprehensive test plan for `test/unit/` and `test/database/` validating all Scenarios 1–10.

## Artifact Index
- c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_ledger\handoff.md — final handoff report
- c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_ledger\progress.md — liveness heartbeat
