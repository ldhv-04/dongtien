# Master Orchestration Plan — DongTien

## High-Level Objective
Deliver production-ready Flutter app `DongTien` for offline-first personal finance in Vietnam (`vi_VN`, integer `VND`), fulfilling all requirements R1-R5 and passing all 15 acceptance criteria.

## Orchestration Strategy: Project Pattern (Dual Track)
- **Track 1: Implementation Track** (Phase 0 -> Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5)
- **Track 2: E2E Testing Track** (Specification-driven test matrix & automated scenarios)

## Execution Phases
1. **Survey Phase (Current)**:
   - Spawn 3 parallel survey explorers / spec miners to map requirements, toolchain, design references, and invariants.
   - Synthesize findings into `PROJECT.md` Feature Inventory & Interface Contracts.
2. **Phase 0 — Audit, Toolchain & Lean Docs**:
   - Verify environment (`flutter`, `dart`, `adb`, `java`).
   - Extract design tokens from `docs/design_refs/`.
   - Produce `AGENTS.md`, `docs/ARCHITECTURE_AND_RULES.md`, and `docs/DESIGN_AND_TEST_PLAN.md`.
3. **Phase 1 — Scaffold & Double-Entry Drift Database**:
   - Initialize Flutter project structure, configure `pubspec.yaml` with locked dependencies.
   - Implement `VndMoney` 64-bit integer monetary type.
   - Implement all 9 Drift tables with foreign keys and seeding logic.
   - Run code generation (`drift_dev`, `build_runner`).
4. **Phase 2 — Pure Domain Financial Engines**:
   - Double-entry posting service & atomic envelope linkage.
   - Reversal & edit engine with audit trail.
   - Safe-to-Spend engine (zero double-counting formula).
   - Savings goal & feasibility advisor.
   - Month-end recurrence & 30/60/90-day cash flow projection.
   - Verify with 100% unit & database tests.
5. **Phase 3 — Material 3 Design System & Core Features**:
   - Design tokens, typography (tabular numerals), color palette.
   - 4-tab navigation shell (`Tổng quan`, `Giao dịch`, `Quỹ tiền`, `Kế hoạch`).
   - Dashboard (Safe-to-Spend card, budget vs spending, upcoming obligations).
   - Transactions & Accounts management, Quick-Add modal with numeric keypad.
   - Virtual Funds (Envelopes) list and movements.
6. **Phase 4 — Plans, Reports, Notifications & Hardened Backup**:
   - Plans screen (Budgets, Goals, Scheduled Items & Forecast).
   - Reports screen (Net expense, Net worth, Saving rate).
   - Settings screen (Cash buffer, CSV export, Sample data / Reset).
   - Low-risk local notifications (`POST_NOTIFICATIONS`, inexact).
   - Isolate-based AES-256-GCM + PBKDF2 encrypted backup/restore (`DONGTIEN_ENC_V1`).
7. **Phase 5 — Full Verification & Hardening**:
   - Execute all 15 mandatory acceptance scenarios.
   - Run `dart format`, `flutter analyze`, `flutter test --coverage`, and `flutter build apk --debug`.
   - Adversarial verification (Challenger + Forensic Auditor).
   - Submit Victory Claim to Sentinel.
