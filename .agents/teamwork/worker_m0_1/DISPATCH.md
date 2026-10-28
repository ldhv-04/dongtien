# Dispatch: worker_m0_1
Role: Lean Documentation Author & Architect
Milestone: M0 (Phase 0 — Audit, Toolchain & Lean Documentation)
Exclusive Write Ownership:
- AGENTS.md
- docs/ARCHITECTURE_AND_RULES.md
- docs/DESIGN_AND_TEST_PLAN.md
## 2026-10-27T17:17:45Z
You are worker_m0_1, working as Lean Documentation Author & Architect.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m0_1

Read the authoritative user request at: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
Read the build specification at: c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md
Read the project scope & architecture at: c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
Read the survey handoff reports:
- c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_1\handoff.md (Financial Domain, Drift Schema & Invariants)
- c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_2\handoff.md (UI/UX, Design Tokens, Notifications & Security)
- c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_survey_3\handoff.md (Environment, Toolchain, Scaffolding & Dependencies)

Your Milestone: M0 (Phase 0 — Audit, Toolchain & Lean Documentation).
Exclusive Write Ownership:
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md
- c:\Users\coihu12\Documents\App\docs\DESIGN_AND_TEST_PLAN.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your task is to write the three lean documentation files with full technical depth and precision:
1. `AGENTS.md`:
   - Project invariants (offline-first, single user, integer VND 64-bit, zero decimals, max_Safe_VND = 9_000_000_000_000_000).
   - Architectural layer boundaries (lib/app, lib/core, lib/domain, lib/features).
   - File-ownership rules for sequential and parallel phases.
   - Locked dependency whitelist and strictly forbidden packages list.
   - Quality gates and coding standards (FontFeature.tabularFigures, PRAGMA foreign_keys = ON, Semantics identifiers).

2. `docs/ARCHITECTURE_AND_RULES.md`:
   - Double-entry general ledger rules, chart of accounts, and 7-type posting matrix.
   - Atomic envelope linkage and the 6 movement types.
   - Dynamic account balance derivation (Asset/Expense = Debit - Credit; Liability/Income/Equity = Credit - Debit).
   - Audit-preserving reversal and edit engine (VOIDED, SUPERSEDED, REVERSAL tx, clean UI filter).
   - Available-to-allocate formula and over-allocation guards.
   - Safe-to-Spend formula (Zero double-counting formula with chronological protected envelope allocation).
   - Negative Safe-to-Spend handling (never clamp to 0, deficit breakdown, 0 ₫/ngày daily allowance).
   - Savings goals ceiling division math `((T - C) + N - 1) ~/ N` and feasibility advisor (3 one-tap calculators).
   - Month-end recurrence with anchor day 1..31 (`min(anchor, daysInMonth)`).
   - Cash flow forecast engine (30/60/90 days).
   - Security & Privacy architecture: Isolate-based AES-256-GCM + PBKDF2-HMAC-SHA256 (120,000 iterations), outer JSON `DONGTIEN_ENC_V1`, 25MB limit, 6-stage validation.
   - Architecture Decision Records (ADRs).

3. `docs/DESIGN_AND_TEST_PLAN.md`:
   - Design tokens extracted from `docs/design_refs/`: 16-step spacing scale (`sp0`..`sp15`), 7 typography tiers with tabular figures, verbatim 7-family color palette with hex values, Remix icon mapping, card radius/elevation.
   - Custom numeric keypad specifications from `wallet.png`.
   - Screen map: 4 bottom tabs (`Tổng quan`, `Giao dịch`, `Quỹ tiền`, `Kế hoạch`) and secondary screens (`Báo cáo`, `Cài đặt & Sao lưu`).
   - Semantics identifier map for automated test hooks.
   - Compliant local notifications specification (`POST_NOTIFICATIONS`, `AndroidScheduleMode.inexactAllowWhileIdle`).
   - Detailed test matrix for the 15 mandatory acceptance scenarios with step-by-step state setup, actions, and exact assertion values.

Maintain `progress.md` in your working directory.
When done, write a complete handoff report to `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m0_1\handoff.md` and send a message back with your report path.
