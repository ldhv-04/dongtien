# BRIEFING — 2026-10-27T19:43:00Z

## Mission
Investigate and author a detailed implementation blueprint for Virtual Funds (Quỹ tiền) Screen (Tab 2) in `lib/features/envelopes/`, including Riverpod state management, UI components, action modals, semantics identifiers, and widget test plan.

## 🔒 My Identity
- Archetype: explorer
- Roles: investigator, reporter, architect
- Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m3_envelopes
- Original parent: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Milestone: M3 (Virtual Funds / Quỹ tiền UI Blueprint)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement application source code.
- Write only to own folder (.agents/teamwork/explorer_m3_envelopes/).
- Follow AGENTS.md: offline-first, pure integer VndMoney, Material 3, Riverpod (Notifier/AsyncNotifier, no code-gen), Tabular Figures for currency/dates.
- Output comprehensive blueprint report in handoff.md and notify orchestrator via send_message.

## Current Parent
- Conversation ID: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Updated: 2026-10-27T19:43:00Z

## Investigation State
- **Explored paths**:
  - `lib/core/database/app_database.dart` (`Envelopes`, `EnvelopeMovements`, `Settings` tables)
  - `lib/core/database/daos/envelope_dao.dart` & `ledger_dao.dart`
  - `lib/domain/envelopes/` (`available_to_allocate.dart`, `envelope_exceptions.dart`, `envelope_movement_type.dart`, `envelope_policy.dart`)
  - `lib/core/money/` (`vnd_money.dart`, `vnd_formatter.dart`)
  - `docs/DESIGN_AND_TEST_PLAN.md` (Sections 1-6) & `docs/ARCHITECTURE_AND_RULES.md`
- **Key findings**:
  - `EnvelopeDao` implements atomic `allocate`, `release`, `transfer` inside `db.transaction()` creating zero ledger postings.
  - `available_to_allocate = total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd`.
  - When `available_to_allocate < 0`, over-allocation warning banner must trigger.
  - Envelopes partition into `PROTECTED` and `FLEXIBLE` lists.
  - Deficit badge (`badge_deficit_<id>`) and red balance must trigger when `reservedBalanceVnd < 0`.
  - Full Riverpod provider and notifier architecture designed without prohibited code-gen.
- **Unexplored areas**: None for M3 Virtual Funds UI blueprint.

## Key Decisions Made
- Authored complete architecture blueprint for `lib/features/envelopes/` with 11 distinct components, 4 action modals, Riverpod state management, and 10 widget test scenarios.
- Feature worker `worker_m3_envelopes` will interact with `AppDatabase` and `EnvelopeDao` via `EnvelopeRepository` without violating cross-layer mutation boundaries.

## Artifact Index
- `DISPATCH.md` — Inbound message record
- `BRIEFING.md` — Situational awareness
- `progress.md` — Liveness heartbeat
- `handoff.md` — Authoritative 5-component implementation blueprint

