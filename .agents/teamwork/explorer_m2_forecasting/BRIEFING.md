# BRIEFING — 2026-10-27T18:52:00Z

## Mission
Produce an authoritative, complete, production-grade implementation blueprint for the Safe-to-Spend, Recurrence, and Cash Flow Forecast domain engines in `lib/domain/forecasting/`.

## 🔒 My Identity
- Archetype: explorer
- Roles: investigator, architect, domain-specifier
- Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m2_forecasting
- Original parent: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Milestone: M2 - Domain Engines & Forecasting Blueprint

## 🔒 Key Constraints
- Read-only investigation — do NOT implement or modify production code in `lib/` or `test/`.
- All outputs go into `.agents/teamwork/explorer_m2_forecasting/`.
- Strict integer VND 64-bit arithmetic (VndMoney); zero float/double.
- Safe-to-Spend formula strictly adheres to zero double-counting chronological algorithm.
- Recurrence calculator must be drift-free with anchor preservation.

## Current Parent
- Conversation ID: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Updated: 2026-10-27T18:56:00Z

## Investigation State
- **Explored paths**:
  - `build_spec/dongtien_build_spec.md`
  - `docs/ARCHITECTURE_AND_RULES.md` (Sections 1, 2, 5, 6, 9, 11)
  - `docs/DESIGN_AND_TEST_PLAN.md` (Design tokens, Screen map, Scenarios 1, 2, 3, 4, 5, 11, 12, 15)
  - `lib/core/money/vnd_money.dart`
  - `lib/core/database/app_database.dart`
- **Key findings**:
  1. Safe-to-Spend formula strictly adheres to zero double-counting: `Liquid Assets - Protected Reserves - Unfunded Committed Outflows - Minimum Cash Buffer`.
  2. Protected envelopes cover linked pending bills in chronological order: `unfunded = bill.amount - min(bill.amount, remaining_balance)`. Flexible envelopes do not cover bills in this calculation (`unfunded = bill.amount`).
  3. Safe-to-Spend never clamps to zero; returns exact negative integer VND with detailed breakdown and 0 ₫/ngày daily allowance when in deficit.
  4. Month-end recurrence uses `min(anchor_day_of_month, daysInMonth(Y, M))` preserving the anchor across leap/non-leap February and restoring to 31 in March/May without drift.
  5. Cash flow forecast projects 30/60/90-day balances with step-by-step net change and buffer breach flags.
  6. Obligation conversion links real ledger transactions, records envelope spend movement if linked, marks item `PAID_OR_RECEIVED`, and advances recurrence without double counting.
- **Unexplored areas**: None for forecasting milestone. All domain contracts and edge cases analyzed.

## Key Decisions Made
- Handcrafted immutable pure Dart DTOs (`EnvelopeSnapshot`, `PendingBillItem`, `SafeToSpendResult`, `SafeToSpendBreakdown`, `CashFlowTimelinePoint`, `CashFlowForecastResult`).
- Zero double-counting algorithm implemented with chronological sorting, per-envelope balance tracking, and detailed allocation tracking for UI breakdown modal.
- `daysInMonth` implemented with full Gregorian leap-year rule `(year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)`.
- Full unit test specifications ready for `test/unit/safe_to_spend_test.dart` and `test/unit/recurrence_test.dart`.

## Artifact Index
- `DISPATCH.md` — Incoming dispatch instructions
- `BRIEFING.md` — Persistent working memory
- `progress.md` — Liveness heartbeat
- `handoff.md` — 5-component handoff report containing complete blueprints and unit test plans

