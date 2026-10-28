# Progress — worker_m1_1 (Core Foundation & Drift Database Schema)

Last visited: 2026-10-28T01:07:45Z

## Milestone Status: COMPLETE (100%)

### Deliverables Completed:
1. `pubspec.yaml`: Locked dependencies whitelist matching `build_spec/dongtien_build_spec.md` Section 3 and `AGENTS.md` Section 4. Zero forbidden packages.
2. `analysis_options.yaml`: Strict analysis configured (`strict-casts`, `strict-inference`, `strict-raw-types`, clean rules, exclude `**/*.g.dart`).
3. `lib/core/money/vnd_money.dart`:
   - 64-bit integer (`int`), zero decimal places, whole VND.
   - `max_Safe_VND = 9_000_000_000_000_000` with `VndOverflowException`.
   - Operators `+`, `-`, `*`, `~/`, `-` (unary negation).
   - `positive` and `nonNegative` constructors.
   - Comparison operators, `Comparable`, `==`, `hashCode`.
4. `lib/core/money/vnd_formatter.dart`:
   - vi_VN dot separator formatting: `1.250.000 ₫`, `0 ₫`, `-500.000 ₫`, `+20.000.000 ₫`.
   - `FontFeature.tabularFigures()` helper (`tabularFigures` list, `withTabularFigures(TextStyle style)`).
   - Robust integer parsing from formatted strings.
5. `lib/core/database/app_database.dart`:
   - All 9 Drift tables implemented: `LedgerAccounts`, `Categories`, `JournalTransactions`, `JournalPostings`, `Envelopes`, `EnvelopeMovements`, `CategoryBudgets`, `ScheduledItems`, `Settings`.
   - One-sided posting check constraint: `((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`.
   - Unique composite index on `CategoryBudgets` `(category_id, year_month)`.
   - Anchor day check on `ScheduledItems`: `1..31` or NULL.
   - Singleton check on `Settings`: `id == 1`.
   - `MigrationStrategy.beforeOpen`: `await customStatement('PRAGMA foreign_keys = ON;');`.
   - `MigrationStrategy.onCreate`: Seeds 3 system accounts (`EQUITY_OPENING`, default Income, default Expense), 8 default Vietnamese categories (Lương, Thưởng, Ăn uống, Di chuyển, Hoá đơn & Tiện ích, Nhà cửa, Mua sắm, Y tế), default settings row (`id = 1`) with strictly 0 ₫ initial balances and zero fake transactions.
6. `lib/core/database/app_database.g.dart`: Generated via `dart run build_runner build --delete-conflicting-outputs` (858 outputs, 1714 actions, 0 warnings).
7. `test/unit/vnd_money_test.dart`: 30 unit tests covering arithmetic, overflow, constructors, comparisons, formatting, parsing, edge cases. (30/30 passed).
8. `test/database/app_database_test.dart`: 14 in-memory SQLite tests asserting FK enforcement, default seeding, balanced transaction execution, check constraints, unique constraints. (14/14 passed).
9. Automated Quality Gates:
   - `dart format --output=none --set-exit-if-changed .` -> Code 0 (0 unformatted lines)
   - `flutter analyze` -> Code 0 ("No issues found!")
   - `flutter test --coverage` -> Code 0 (44/44 tests passed, coverage generated)
