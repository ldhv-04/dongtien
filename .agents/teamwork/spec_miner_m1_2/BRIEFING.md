# BRIEFING — 2026-10-27T17:40:00Z

## Mission
Discover, probe, and document the complete Drift SQLite schema, 9 tables, relational invariants, check constraints, foreign keys, cascades, indexes, PRAGMAs, and code generation specification for Milestone M1.

## 🔒 My Identity
- Archetype: Specification Miner
- Roles: Drift Schema & Relational Invariants Spec Miner
- Working directory: c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_m1_2
- Original parent: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Milestone: M1 (Scaffold & Drift Database Schema)

## 🔒 Key Constraints
- Pure read-only specification mining; do NOT implement application code.
- Strict Integer VND 64-Bit representation (`int` in Dart, INTEGER in SQLite). Zero floats/doubles.
- 9 tables: ledger_accounts, categories, journal_transactions, journal_postings, envelopes, envelope_movements, category_budgets, scheduled_items, settings.
- Exact check constraints specified:
  - journal_postings: `(debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0)`
  - category_budgets: unique index `(category_id, year_month)`
  - scheduled_items: anchor_day_of_month 1..31 check
  - settings: single-row check `id == 1`
- PRAGMA foreign_keys = ON; in MigrationStrategy.beforeOpen.
- Self-referencing FK pointers and deferral rules (`reverses_tx_id`, `replaced_by_tx_id`, PRAGMA defer_foreign_keys = ON).
- Drift code generation strategy (`drift_dev` + `build_runner`).

## Current Parent
- Conversation ID: 4b707e3a-5355-44d8-b48d-d32bbd3220b1
- Updated: not yet

## Task Summary
- **What to build**: Comprehensive schema blueprint and relational invariants specification for M1 implementation.
- **Success criteria**: Detailed schema blueprint covering all 9 tables, table columns, data types, nullability, defaults, check constraints, FK constraints & cascades, indexes, PRAGMAs, DAOs outline, and code generation workflow.
- **Interface contracts**: docs/ARCHITECTURE_AND_RULES.md, AGENTS.md, build_spec/dongtien_build_spec.md
- **Code layout**: lib/core/database/

## Key Decisions Made
- Confirmed all 9 tables DDL & Dart DSL mappings, verified in-memory via test_m1_drift_schema_probe.py.
- Verified PRAGMA foreign_keys = ON; in MigrationStrategy.beforeOpen.
- Verified PRAGMA defer_foreign_keys = ON; for multi-step transaction edits, self-referencing pointers, and atomic backup restore.
- Verified one-sided posting check constraint on journal_postings: ((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0)).
- Verified unique index on (category_id, year_month) for category_budgets.
- Verified anchor_day_of_month check (1..31 or NULL) for scheduled_items.
- Verified singleton check (id == 1) for settings.
- Verified CASCADE delete on journal_transactions -> journal_postings and RESTRICT on ledger_accounts deletion.

## Artifact Index
- DISPATCH.md — Dispatch instructions
- BRIEFING.md — Persistent context & memory
- progress.md — Liveness heartbeat & step tracking
- test_m1_drift_schema_probe.py — Automated Python SQLite verification probe
- handoff.md — Final schema specification & handoff report
