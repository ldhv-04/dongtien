# Scope: Đồng Tiền Three Critical Fixes & Split-ABI Release APK

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | R1: Explicit Category Selection & Isolation | Option B: Category picker in Add/Edit Scheduled Item modal (default `Hoá đơn & Tiện ích` for BILL, `Lương` for PLANNED_INCOME), eliminate silent `cats.first` fallback in `markScheduledItemPaid`, ensure paying a bill only affects its assigned category budget and envelope. | M2 | ORIGINAL_REQUEST §2026-10-28T18:36:33Z |
| 2 | R2: Financial Plans CRUD & Atomic Reversals | Full Edit (`Sửa`) & Delete (`Xóa`) on Category Budgets, Savings Goals, and Scheduled Items. For `PAID_OR_RECEIVED` items: deleting voids/reverses ledger transaction + restores envelope; editing voids old transaction and posts updated transaction. | M2 | ORIGINAL_REQUEST §2026-10-28T18:36:33Z |
| 3 | R3: periodStartDay Billing Cycle Sync | Pure domain `BillingCycleCalculator`, synchronized across `currentMonthlyBudgetSummaryProvider`, `safeToSpendProvider`, `reportsSummaryProvider`, `NotificationScheduler`, `CategoryBudgetsView`, and `SpendingVsBudgetCard`. | M2 | ORIGINAL_REQUEST §2026-10-28T18:36:33Z |
| 4 | R4: Full Verification & Release APK | `dart format`, `flutter analyze`, `flutter test` (100% green), and `flutter build apk --release --split-per-abi --tree-shake-icons`. | M3 | ORIGINAL_REQUEST §2026-10-28T18:36:33Z |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Exploration & Survey | 3 parallel Explorers: Exp 1 (R1), Exp 2 (R2), Exp 3 (R3) | none | DONE |
| 2 | Implementation of R1, R2, R3 | Worker implementing all 3 requirements cleanly | M1 | IN_PROGRESS |
| 3 | Verification & APK Build | Worker running tests, dart format, flutter analyze, flutter test, and building split APKs | M2 | PLANNED |
| 4 | Gate & Forensics | Reviewers, Challengers, and Forensic Auditor | M3 | PLANNED |

## Interface Contracts
- `BillingCycleCalculator`: Pure Dart class taking `(DateTime referenceDate, int periodStartDay)` returning `cycleStart`, `cycleEndExclusive`, `cycleEndInclusive`, `yearMonth`, and formatted label `formatCycleRange()`.
- `PlansController`:
  - `deleteCategoryBudget(int categoryId, {int? yearMonth})`
  - `deleteSavingsGoal(int envelopeId)`
  - `updateScheduledItem(...)` & `deleteScheduledItem(int scheduledItemId)`
- `markScheduledItemPaid`:
  - Category resolution: explicit `item.categoryId`, fallback to `Hoá đơn & Tiện ích` (never `cats.first`).
- Ledger Reversals:
  - Deleting paid scheduled item -> `ledgerDao.voidTransaction(item.paidTransactionId)` -> updates envelope reserve & liquid assets.
  - Editing paid scheduled item -> `ledgerDao.voidTransaction(oldTxId)` + posts new transaction.
