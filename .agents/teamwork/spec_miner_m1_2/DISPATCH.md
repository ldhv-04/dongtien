## 2026-10-27T17:39:33Z
You are spec_miner_m1_2, working as Drift Schema & Relational Invariants Spec Miner for Milestone M1.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_m1_2

Read the authoritative user request at: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
Read the build specification at: c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md
Read the project scope at: c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
Read the approved architectural documents:
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md

Your Milestone: M1 (Scaffold & Drift Database Schema).
Your investigation scope:
1. Detailed Drift table declarations for all 9 tables in `lib/core/database/tables/` or `app_database.dart`:
   - `ledger_accounts`
   - `categories`
   - `journal_transactions`
   - `journal_postings` (with check constraint `(debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0)`)
   - `envelopes`
   - `envelope_movements`
   - `category_budgets` (with unique index `(category_id, year_month)`)
   - `scheduled_items` (with anchor_day_of_month 1..31 check)
   - `settings` (with single-row check `id == 1`)
2. Relational constraints, foreign key declarations with cascade behaviors, and `PRAGMA foreign_keys = ON;` in `MigrationStrategy.beforeOpen`.
3. Self-referencing FK pointers and deferral rules (`reverses_tx_id`, `replaced_by_tx_id`, `PRAGMA defer_foreign_keys = ON;`).
4. Drift code generation strategy (`drift_dev` + `build_runner`) or clean generation fallback.

Maintain `progress.md` in your working directory.
Deliver your schema blueprint and handoff report to:
c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_m1_2\handoff.md
Send a completion message back with summary and handoff path.
