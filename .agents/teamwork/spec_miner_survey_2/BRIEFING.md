# BRIEFING — 2026-10-27T10:08:00Z

## Mission
Thoroughly probe, analyze, and extract the complete specifications for UI/UX, Design System, Local Notifications, and Security/Backup of DongTien financial application.

## 🔒 My Identity
- Archetype: Specification Miner
- Roles: UI/UX & Security Spec Miner
- Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_survey_2
- Original parent: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Milestone: Milestone 0 - Specification Mining & Architecture Survey

## 🔒 Key Constraints
- Sole job is to discover and document features by probing authoritative specification sources.
- Do NOT implement anything (read-only regarding implementation code).
- Enumerate full interface, typical usage, edge cases, error behaviors, input/output formats, constraints.
- Output comprehensive handoff.md with 5 components and Features Discovered / Edge Cases tables.

## Current Parent
- Conversation ID: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Updated: 2026-10-27T10:12:00Z

## Task Summary
- **What to analyze**:
  1. Design System & Tokens: Spacing scale (sp-0..sp-15), typography scale (Large Title..Caption) with tabular numerals and vi_VN currency formatting, exact hex color tokens (Verdant, Sandstone, Ember, Ruby, Marigold, Charcoal, Neutral), card radius (16-24px), low elevation, and Remix icons extracted from 9 reference images.
  2. Navigation & Architecture: 4 bottom navigation tabs (Tổng quan, Giao dịch, Quỹ tiền, Kế hoạch) using IndexedStack + standard Navigator, secondary screens (Báo cáo, Cài đặt & Sao lưu) via AppBar actions.
  3. Detailed Screen Requirements & Interactive Components: Safe-to-Spend hero card, breakdown modal, day-grouped transactions with daily net totals, custom numeric keypad Quick-Add UX, virtual fund allocation/movement screens, 3-subview Plans (budgets, savings goals with feasibility advisor, cash-flow forecast), reports, settings, and accessibility semantics.
  4. Compliant Local Notifications: Android 12-15+ compatibility, POST_NOTIFICATIONS & RECEIVE_BOOT_COMPLETED only, inexactAllowWhileIdle scheduling, graceful degradation upon denial (Scenario 15).
  5. Android Hardening & Encrypted Backup/Restore: allowBackup=false, data extraction exclusion, off-main-thread Isolate.run, PBKDF2-HMAC-SHA256 (120k iterations) + AES-256-GCM, 25MB limit, multi-gate in-memory validation, atomic transactional restore (Scenarios 13 & 14).
- **Success criteria**: Comprehensive handoff report matching user instructions and spec miner standard.
- **Interface contracts**: c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md
- **Original request**: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md

## Key Decisions Made
- All design tokens transcribed directly from `Spacing.png`, `Untitled-2.png`, and `Untitled-3.png`.
- Custom numeric keypad and quick-add flow modeled faithfully on `wallet.png` and `budget.png`.
- Notification engine locked to `inexactAllowWhileIdle` with zero exact alarm permissions to comply with modern Android policy.
- Backup crypto engine fully isolated in `Isolate.run` with 6-stage validation gates.

## Artifact Index
- DISPATCH.md — Dispatch assignment
- BRIEFING.md — Persistent working memory
- progress.md — Heartbeat and progress log
- handoff.md — Final comprehensive specification handoff report
