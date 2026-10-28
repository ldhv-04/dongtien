## 2026-10-27T17:47:49Z
You are worker_m1_1, working as Core Foundation & Drift Database Engineer.
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1_1

Read the authoritative user request at: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
Read the build specification at: c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md
Read the project scope & architecture at: c:\Users\coihu12\Documents\App\.agents\teamwork\orchestrator_1\PROJECT.md
Read the approved architectural specifications:
- c:\Users\coihu12\Documents\App\AGENTS.md
- c:\Users\coihu12\Documents\App\docs\ARCHITECTURE_AND_RULES.md
- c:\Users\coihu12\Documents\App\docs\DESIGN_AND_TEST_PLAN.md
Read the Milestone M1 exploratory reports and blueprints:
- c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_1\handoff.md (Scaffolding, pubspec.yaml, analysis_options.yaml, VndMoney & tests)
- c:\Users\coihu12\Documents\App\.agents\teamwork\spec_miner_m1_2\handoff.md (Complete 9 Drift tables code, constraints, FKs, index, deferrals)
- c:\Users\coihu12\Documents\App\.agents\teamwork\explorer_m1_3\handoff.md (Vietnamese seeding, system accounts, and test/database/app_database_test.dart)

Your Milestone: M1 (Scaffold & Drift Database Schema).
Exclusive Write Ownership:
- c:\Users\coihu12\Documents\App\pubspec.yaml
- c:\Users\coihu12\Documents\App\analysis_options.yaml
- c:\Users\coihu12\Documents\App\lib\core\money\vnd_money.dart
- c:\Users\coihu12\Documents\App\lib\core\money\vnd_formatter.dart
- c:\Users\coihu12\Documents\App\lib\core\database\
- c:\Users\coihu12\Documents\App\test\unit\vnd_money_test.dart
- c:\Users\coihu12\Documents\App\test\database\app_database_test.dart

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your Tasks:
1. Initialize/configure `pubspec.yaml` with the exact locked dependencies whitelist from Section 3 of `dongtien_build_spec.md` (no forbidden packages).
2. Configure `analysis_options.yaml` (clean lints).
3. Implement `lib/core/money/vnd_money.dart` and `lib/core/money/vnd_formatter.dart`:
   - 64-bit integer (`int`), zero decimals, whole VND.
   - `max_Safe_VND = 9_000_000_000_000_000` overflow guard with `VndOverflowException`.
   - Operators `+`, `-`, `*`, `~/`.
   - Formatter producing `1.250.000 ₫`, `0 ₫`, `-500.000 ₫` with `FontFeature.tabularFigures()`.
4. Implement all 9 Drift tables and `AppDatabase` in `lib/core/database/`:
   - `ledger_accounts`, `categories`, `journal_transactions`, `journal_postings` (with `(debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0)` check constraint), `envelopes`, `envelope_movements`, `category_budgets` (with unique `(category_id, year_month)`), `scheduled_items` (with `anchor_day_of_month` 1..31 check), `settings` (with single-row check `id == 1`).
   - `MigrationStrategy.beforeOpen`: `await customStatement('PRAGMA foreign_keys = ON;');`.
   - `MigrationStrategy.onCreate`: seed 3 system accounts (`EQUITY_OPENING`, default Income, default Expense) and 8 Vietnamese categories (Lương, Thưởng, Ăn uống, Di chuyển, Hoá đơn & Tiện ích, Nhà cửa, Mua sắm, Y tế) and default settings row (`id = 1`) with 0 ₫ balances and zero fake transactions.
   - Drift code generation (`app_database.g.dart`).
5. Write and execute tests:
   - `test/unit/vnd_money_test.dart`: arithmetic, overflow, formatting, sign, zero.
   - `test/database/app_database_test.dart`: in-memory Drift tests asserting FK enforcement, default seeding, balanced transaction execution, check constraints, unique constraints.
6. Verify and record exact outputs of all verification commands.

Maintain `progress.md` in your working directory.
When complete, write your comprehensive handoff report to `c:\Users\coihu12\Documents\App\.agents\teamwork\worker_m1_1\handoff.md` and send a message back with your report path.
