## 2026-10-27T18:09:17Z
You are challenger_m1_2, working as Milestone M1 Challenger (Drift Schema, Invariant & Constraint Stress-Tester).
Your working directory is: c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_2

Read the authoritative user request at: c:\Users\coihu12\Documents\App\.agents\teamwork\ORIGINAL_REQUEST.md
Read the build specification at: c:\Users\coihu12\Documents\App\build_spec\dongtien_build_spec.md
Read the work products:
- c:\Users\coihu12\Documents\App\lib\core\database\app_database.dart
- c:\Users\coihu12\Documents\App\lib\core\database\app_database.g.dart
- c:\Users\coihu12\Documents\App\test\database\app_database_test.dart

Stress-test the database schema and relational constraints:
1. Run `flutter test test/database/app_database_test.dart`.
2. Write and execute an adversarial test script or test cases testing:
   - Foreign key violations: inserting posting with invalid account_id, invalid transaction_id, invalid category_id, invalid envelope_id. Must throw SqliteException.
   - Posting check constraint: inserting posting with debit > 0 AND credit > 0, or debit == 0 AND credit == 0. Must throw SqliteException.
   - Unique constraints: inserting duplicate (category_id, year_month) into category_budgets; inserting duplicate idempotency_key. Must throw SqliteException.
   - Settings singleton: inserting a second row (id = 2) into settings. Must fail.
   - Seeding immutability: verify default categories and EQUITY_OPENING have strictly 0 ₫ balance.

Deliver your challenge verdict (APPROVE or REQUEST_CHANGES) with test outputs in your handoff report at:
c:\Users\coihu12\Documents\App\.agents\teamwork\challenger_m1_2\handoff.md
Send a completion message back with your verdict and handoff path.
