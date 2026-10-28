# BRIEFING — 2026-10-27T18:18:00Z

## Mission
Adversarial empirical stress-testing of Milestone M1 Money & Integer Arithmetic engine (VndMoney, VndFormatter, and parser).

## 🔒 My Identity
- Archetype: challenger
- Roles: critic, specialist
- Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_1
- Original parent: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Milestone: M1
- Instance: 1 of 1

## 🔒 Key Constraints
- Review-only — do NOT modify implementation code
- Layout Compliance: .agents/teamwork/ holds only metadata — source, tests, or data there is a violation
- Empirical Challenger: must write and run verification tests directly, reproduce all bugs empirically

## Current Parent
- Conversation ID: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Updated: not yet

## Review Scope
- **Files to review**:
  - `lib/core/money/vnd_money.dart`
  - `lib/core/money/vnd_formatter.dart`
  - `test/unit/vnd_money_test.dart`
- **Interface contracts**: `AGENTS.md`, `build_spec/dongtien_build_spec.md`, `docs/ARCHITECTURE_AND_RULES.md`
- **Review criteria**:
  - 64-bit overflow guard: exactly ±9_000_000_000_000_000 allowed, ±9_000_000_000_000_001 throws VndOverflowException
  - Arithmetic edge cases: add, sub, mul, div, ceiling/floor div, div by zero
  - Formatter edge cases: 0 ₫, negative amounts (-1.250.000 ₫), multi-trillion amounts, tabular figures
  - Text parsing edge cases: dirty input, dot vs comma, spaces, non-numeric strings

## Key Decisions Made
- Executed baseline tests `test/unit/vnd_money_test.dart` (30/30 passed).
- Built adversarial test harness in `test/unit/vnd_money_adversarial_test.dart` with 28 comprehensive edge cases.
- Empirically confirmed 2 bugs in `VndFormatter`:
  1. Multiple consecutive signs (`--1000`, `++1000`, `+-1000`, `- - 1000`) accepted and `--1000` evaluates to positive 1000.
  2. `VndFormatter.parse()` throws `FormatException` instead of `VndOverflowException` on overflow, violating public contract.
- Issued verdict: `REQUEST_CHANGES` with exact reproducible test suite and proposed minimal patch for `worker_m1_1`.

## Artifact Index
- `BRIEFING.md` — Agent working memory
- `progress.md` — Liveness and step tracking
- `DISPATCH.md` — Inbound instructions log
- `handoff.md` — Final challenge report and verdict
- `test/unit/vnd_money_adversarial_test.dart` — Empirical adversarial test harness

## Attack Surface
- **Hypotheses tested**:
  - Boundary limits: ±9_000_000_000_000_000 (PASSED)
  - Boundary overflow: ±9_000_000_000_000_001 (PASSED)
  - Int64 max/min multiplication overflow (PASSED)
  - Division by zero exception (PASSED)
  - Multi-trillion formatting (PASSED)
  - Tabular figure text styling (PASSED)
  - Consecutive sign parsing (FAILED - BUG REPRODUCED)
  - Parse overflow exception type (FAILED - BUG REPRODUCED)
- **Vulnerabilities found**:
  - BUG-M1-01: `VndFormatter.tryParse` parses `--1000` as positive `1000`.
  - BUG-M1-02: `VndFormatter.parse` fails to throw `VndOverflowException` on out-of-range strings.
- **Untested angles**: All specified angles empirically verified.

## Loaded Skills
- None specified
