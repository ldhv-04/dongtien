# Handoff Report: Requirement R1 (Scheduled Obligations Category Selection & Isolation — Option B)

**Author**: Explorer 1 (`explorer_m1_1`)  
**Target Milestone**: Milestone 3 / R1 Implementation  
**Status**: Completed Investigation & Authoritative Design

---

## 1. Observation

### 1.1 Database Schema Inspection (`lib/core/database/app_database.dart`)
At line 198 of `lib/core/database/app_database.dart`, the `ScheduledItems` table definition already contains a nullable foreign key column for `categoryId`:
```dart
198:   IntColumn get categoryId => integer()
199:       .nullable()
200:       .references(Categories, #id, onDelete: KeyAction.setNull)();
```
And in `seedInitialData` (lines 336–411 of `lib/core/database/app_database.dart`), default categories are inserted in the following exact order:
```dart
// Income Categories:
1: 'Lương' (id: 1)
2: 'Thưởng' (id: 2)
// Expense Categories:
3: 'Ăn uống' (id: 3)
4: 'Di chuyển' (id: 4)
5: 'Hoá đơn & Tiện ích' (id: 5)
6: 'Nhà cửa' (id: 6)
7: 'Mua sắm' (id: 7)
8: 'Y tế' (id: 8)
```
When querying `WHERE kind = 'EXPENSE'` in SQLite without an `ORDER BY` clause, SQLite returns rows in ascending `rowid`/`id` order, where the first element is **`Ăn uống` (id: 3)**.

### 1.2 Root Cause in Controller (`lib/features/plans/presentation/providers/plans_providers.dart`)
In `PlansController.markScheduledItemPaid`, lines 343–351:
```dart
343:         // Resolve category
344:         int targetCategoryId = item.categoryId ?? 0;
345:         if (targetCategoryId == 0) {
346:           final cats = await (db.select(db.categories)
347:                 ..where((c) => c.kind.equals(
348:                     item.kind == 'PLANNED_INCOME' ? 'INCOME' : 'EXPENSE')))
349:               .get();
350:           targetCategoryId = cats.isNotEmpty ? cats.first.id : 1;
351:         }
```
When `item.categoryId` is `null` (or 0), line 350 executes `targetCategoryId = cats.isNotEmpty ? cats.first.id : 1;`.
Because `cats.first` is category 3 (`Ăn uống`), `targetCategoryId` is evaluated as `3`.

Then, at lines 397–406:
```dart
397:           createdTxId = await dao.postTransaction(
398:             txType: 'EXPENSE',
399:             description: item.title,
400:             occurredAt: nowMs,
401:             postings: PostingMatrix.buildExpense(
402:               sourceAccountId: targetAccountId,
403:               categoryId: targetCategoryId,
404:               amountVnd: item.amountVnd,
405:               envelopeId: envelopeToLink ?? item.linkedEnvelopeId,
406:             ),
```
`PostingMatrix.buildExpense` creates a debit posting on category 3 (`Ăn uống`).

### 1.3 Budget Pollution in Dashboard Provider (`lib/features/dashboard/presentation/providers/dashboard_providers.dart`)
In `currentMonthlyBudgetSummaryProvider` (lines 106–123):
```sql
FROM category_budgets b
JOIN categories c ON b.category_id = c.id
LEFT JOIN (
  SELECT 
    p.category_id,
    SUM(p.debit_vnd) AS gross_expense,
    SUM(p.credit_vnd) AS refund_credits
  FROM journal_postings p
  JOIN journal_transactions t ON p.transaction_id = t.id
  WHERE t.occurred_at >= ? 
    AND t.occurred_at < ? 
    AND t.status = 'POSTED' 
    AND t.tx_type != 'REVERSAL'
    AND p.category_id IS NOT NULL
  GROUP BY p.category_id
) spent ON b.category_id = spent.category_id
WHERE b.year_month = ?
```
The subquery sums `p.debit_vnd` where `p.category_id = b.category_id`.
Since `targetCategoryId` was set to `3` (`Ăn uống`), the 3.500.000 ₫ rent bill is added to `gross_expense` for `Ăn uống`!
If the user's `Ăn uống` budget is 3.000.000 ₫, it immediately registers 3.500.000 ₫ spent and turns red (Overbudget, 116.7%), while `Hoá đơn & Tiện ích` or `Nhà cửa` shows 0 ₫.

### 1.4 Missing Category Selection in UI (`lib/features/plans/presentation/widgets/obligations_forecast_view.dart`)
Lines 365–373 of `_AddScheduledItemModalState`:
```dart
365: class _AddScheduledItemModalState
366:     extends ConsumerState<_AddScheduledItemModal> {
367:   final TextEditingController _titleController = TextEditingController();
368:   String _kind = 'BILL';
369:   int _amountVnd = 0;
370:   DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
371:   int? _linkedEnvelopeId;
372:   bool _isSubmitting = false;
```
`_categoryId` is not tracked.
At line 382:
```dart
382:     final envelopes = ref.watch(envelopesStreamProvider).value ?? [];
```
`categoriesStreamProvider` is not watched.
At lines 521–529:
```dart
521:       await ref.read(plansControllerProvider.notifier).createScheduledItem(
522:             kind: _kind,
523:             title: title,
524:             amountVnd: _amountVnd,
525:             dueDate: _dueDate,
526:             recurrence: 'NONE',
527:             anchorDayOfMonth: _dueDate.day,
528:             linkedEnvelopeId: _linkedEnvelopeId,
529:           );
```
`categoryId` is completely omitted when calling `createScheduledItem`.

### 1.5 Missing Category Display in Cards
1. `ObligationsForecastView` (lines 236–245):
```dart
236:                                   Text(item.title,
237:                                       style: AppTypography.bodyMedium),
238:                                   const SizedBox(height: 2),
239:                                   Text(
240:                                     '${isBill ? 'Hoá đơn cam kết' : 'Thu nhập dự kiến'} • Hạn: $dStr',
```
Does not render the category name.
2. `UpcomingObligationsCard` (`lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart`, lines 95–109):
```dart
95:                         child: Column(
96:                           crossAxisAlignment: CrossAxisAlignment.start,
97:                           children: [
98:                             Text(bill.title, style: AppTypography.bodyMedium),
99:                             Text(
100:                               VndFormatter.format(bill.amountVnd),
```
Does not render the category name.

### 1.6 Existing Test Baseline
Commands run:
1. `flutter test test/unit/m2_r1_single_payment_plans_test.dart` -> 4/4 passed (exit code 0).
2. `flutter test test/widget/m2_r1_obligations_ux_test.dart` -> 6/6 passed (exit code 0).
3. `flutter test test/database/acceptance_scenarios_1_to_15_test.dart` -> 4/4 passed (exit code 0).

---

## 2. Logic Chain

1. **Category Ordering in SQLite**: Because `seedInitialData` inserts `Ăn uống` as the first `EXPENSE` category (id: 3), any raw `cats.first` expression evaluates to `Ăn uống`.
2. **Double-Entry Impact**: In general ledger accounting, an expense posting must specify a debit account (Category). If this is defaulted to `cats.first`, the debit posting hits `Ăn uống`.
3. **Budget Engine Impact**: Category budgets are derived by aggregating debit postings where `p.category_id = b.category_id`. Therefore, hitting `Ăn uống` immediately increases the calculated spent amount for the `Ăn uống` budget.
4. **Virtual Fund Isolation**: In Đồng Tiền's architecture, virtual fund envelopes are decoupled from general ledger postings. An envelope is only affected if `linkedEnvelopeId` is explicitly populated. By default, `linkedEnvelopeId` is null, so paying a bill does NOT affect envelopes unless chosen. However, because of the `cats.first` bug, the user's `Ăn uống` category budget was corrupted.
5. **Option B Resolution**:
   - In UI: Provide an explicit Category selector in `_AddScheduledItemModal` (filtered to `EXPENSE` for `BILL`, and `INCOME` for `PLANNED_INCOME`), defaulting `BILL` to `Hoá đơn & Tiện ích` (id: 5), and `PLANNED_INCOME` to `Lương` (id: 1).
   - In Controller: In `markScheduledItemPaid`, check if `item.categoryId` is valid. If null or 0 (legacy records), fallback strictly to `Hoá đơn & Tiện ích` (or `Nhà cửa`), and NEVER to `cats.first` (`Ăn uống`).
   - In Presentation: Display category name on scheduled item cards in both `ObligationsForecastView` and `UpcomingObligationsCard` in a backwards-compatible manner so existing widget test finders (such as `find.text('Tiền Điện')` and `find.text('750.000 ₫')`) continue to pass.

---

## 3. Caveats

- **Legacy Records**: Existing database rows where `categoryId == null` will automatically resolve to `Hoá đơn & Tiện ích` on payment, ensuring backward compatibility without requiring a schema migration.
- **Envelope Linkage Scope**: Linking a bill to an envelope (`linkedEnvelopeId`) remains optional. If `linkedEnvelopeId` is null, no envelope is touched; if `linkedEnvelopeId` is set, only that specific envelope's reserve is consumed up to its balance (per Scenario 11). Unlinked envelopes (like an `Ăn uống` envelope) remain 100% untouched.
- **R2 Interface**: R2 adds full Edit/Delete (`updateScheduledItem`, `deleteScheduledItem`). `_AddScheduledItemModal` and cards should be designed so `_AddScheduledItemModal` can accept an optional `ScheduledItem? existingItem` without breaking or requiring duplicative UI rewriting.

---

## 4. Conclusion & Concrete Code Specifications

### 4.1 Changes to `lib/features/plans/presentation/widgets/obligations_forecast_view.dart`

#### (A) Import Category Provider
Add to top imports:
```dart
import '../../../transactions/presentation/controllers/transaction_providers.dart';
```

#### (B) Add Category Display to `ObligationsForecastView`
In `ObligationsForecastView.build`:
```dart
    final itemsAsync = ref.watch(allScheduledItemsStreamProvider);
    final forecastAsync = ref.watch(cashFlowForecastProvider);
    final horizonDays = ref.watch(forecastHorizonDaysProvider);
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c.name};
```

For pending items (around line 239):
```dart
final catName = item.categoryId != null ? catMap[item.categoryId] : null;
final subtitle = catName != null
    ? '${isBill ? 'Hoá đơn cam kết' : 'Thu nhập dự kiến'} • $catName • Hạn: $dStr'
    : '${isBill ? 'Hoá đơn cam kết' : 'Thu nhập dự kiến'} • Hạn: $dStr';

// Replace line 240 with:
Text(
  subtitle,
  style: VndFormatter.withTabularFigures(AppTypography.caption),
),
```

For completed history items (around line 310):
```dart
final catName = item.categoryId != null ? catMap[item.categoryId] : null;
final subtitle = catName != null
    ? '${isBill ? 'Hoá đơn đã trả' : 'Thu nhập đã nhận'} • $catName • Ngày: $dStr'
    : '${isBill ? 'Hoá đơn đã trả' : 'Thu nhập đã nhận'} • Ngày: $dStr';

// Replace line 311 with:
Text(
  subtitle,
  style: VndFormatter.withTabularFigures(
    AppTypography.caption.copyWith(color: AppColors.textTertiary),
  ),
),
```

#### (C) Category Selector in `_AddScheduledItemModal`
Update `_AddScheduledItemModal` to accept optional `existingItem` for edit support and add `_categoryId`:
```dart
class _AddScheduledItemModal extends ConsumerStatefulWidget {
  final ScheduledItem? existingItem;
  const _AddScheduledItemModal({this.existingItem});

  @override
  ConsumerState<_AddScheduledItemModal> createState() =>
      _AddScheduledItemModalState();
}

class _AddScheduledItemModalState
    extends ConsumerState<_AddScheduledItemModal> {
  final TextEditingController _titleController = TextEditingController();
  String _kind = 'BILL';
  int _amountVnd = 0;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  int? _categoryId;
  int? _linkedEnvelopeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _titleController.text = item.title;
      _kind = item.kind;
      _amountVnd = item.amountVnd;
      _dueDate = DateTime.fromMillisecondsSinceEpoch(item.dueDateMs);
      _categoryId = item.categoryId;
      _linkedEnvelopeId = item.linkedEnvelopeId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  int? _resolveDefaultCategoryId(String kind, List<Category> allCategories) {
    if (kind == 'BILL') {
      final expenseCats = allCategories.where((c) => c.kind == 'EXPENSE').toList();
      final defaultCat = expenseCats.firstWhere(
        (c) => c.name == 'Hoá đơn & Tiện ích',
        orElse: () => expenseCats.firstWhere(
          (c) => c.name == 'Nhà cửa',
          orElse: () => expenseCats.isNotEmpty ? expenseCats.first : allCategories.first,
        ),
      );
      return defaultCat.id;
    } else {
      final incomeCats = allCategories.where((c) => c.kind == 'INCOME').toList();
      final defaultCat = incomeCats.firstWhere(
        (c) => c.name == 'Lương',
        orElse: () => incomeCats.firstWhere(
          (c) => c.name == 'Thưởng',
          orElse: () => incomeCats.isNotEmpty ? incomeCats.first : allCategories.first,
        ),
      );
      return defaultCat.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final envelopes = ref.watch(envelopesStreamProvider).value ?? [];
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final availableCategories = categories
        .where((c) => c.kind == (_kind == 'BILL' ? 'EXPENSE' : 'INCOME'))
        .toList();

    // Default category selection if unset or invalid for current kind
    if (availableCategories.isNotEmpty) {
      final isCurrentValid = availableCategories.any((c) => c.id == _categoryId);
      if (_categoryId == null || !isCurrentValid) {
        _categoryId = _resolveDefaultCategoryId(_kind, categories);
      }
    }
```

When switching `_kind` chip (around line 404):
```dart
ChoiceChip(
  label: const Text('Hoá đơn (BILL)'),
  selected: _kind == 'BILL',
  onSelected: (_) {
    setState(() {
      _kind = 'BILL';
      _categoryId = _resolveDefaultCategoryId('BILL', categories);
    });
  },
),
...
ChoiceChip(
  label: const Text('Thu nhập dự kiến'),
  selected: _kind == 'PLANNED_INCOME',
  onSelected: (_) {
    setState(() {
      _kind = 'PLANNED_INCOME';
      _categoryId = _resolveDefaultCategoryId('PLANNED_INCOME', categories);
    });
  },
),
```

Add the Category Picker UI right above the Due Date or Amount section:
```dart
AppSpacing.gapH8,
Text(
  'Danh mục (${_kind == 'BILL' ? 'Chi tiêu' : 'Thu nhập'})',
  style: AppTypography.subheadline,
),
AppSpacing.gapH4,
if (availableCategories.isNotEmpty)
  Wrap(
    spacing: AppSpacing.sp4,
    children: availableCategories.map((c) {
      return ChoiceChip(
        label: Text(c.name),
        selected: _categoryId == c.id,
        onSelected: (selected) {
          if (selected) {
            setState(() => _categoryId = c.id);
          }
        },
      );
    }).toList(),
  ),
```

And in `_submit()`:
```dart
  Future<void> _submit() async {
    if (_isSubmitting) return;
    final title = _titleController.text.trim();
    if (title.isEmpty || _amountVnd <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.existingItem == null) {
        await ref.read(plansControllerProvider.notifier).createScheduledItem(
              kind: _kind,
              title: title,
              amountVnd: _amountVnd,
              dueDate: _dueDate,
              recurrence: 'NONE',
              anchorDayOfMonth: _dueDate.day,
              categoryId: _categoryId,
              linkedEnvelopeId: _linkedEnvelopeId,
            );
      } else {
        await ref.read(plansControllerProvider.notifier).updateScheduledItem(
              scheduledItemId: widget.existingItem!.id,
              kind: _kind,
              title: title,
              amountVnd: _amountVnd,
              dueDate: _dueDate,
              categoryId: _categoryId,
              linkedEnvelopeId: _linkedEnvelopeId,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
```

---

### 4.2 Changes to `lib/features/plans/presentation/providers/plans_providers.dart`

In `PlansController.markScheduledItemPaid`, replace lines 343–351 with:
```dart
        // Resolve category with strict isolation (Option B)
        int targetCategoryId = 0;
        if (item.categoryId != null && item.categoryId! > 0) {
          final existingCat = await (db.select(db.categories)
                ..where((c) => c.id.equals(item.categoryId!)))
              .getSingleOrNull();
          if (existingCat != null) {
            targetCategoryId = existingCat.id;
          }
        }

        if (targetCategoryId == 0) {
          final isBill = item.kind == 'BILL';
          final desiredKind = isBill ? 'EXPENSE' : 'INCOME';
          final cats = await (db.select(db.categories)
                ..where((c) => c.kind.equals(desiredKind)))
              .get();

          if (isBill) {
            // Default legacy/null bill category:
            // 1. 'Hoá đơn & Tiện ích'
            // 2. 'Nhà cửa'
            // 3. Any non-food expense category if available
            // 4. NEVER cats.first ('Ăn uống') unless it is the only category in db
            final defaultBillCat = cats.firstWhere(
              (c) => c.name == 'Hoá đơn & Tiện ích',
              orElse: () => cats.firstWhere(
                (c) => c.name == 'Nhà cửa',
                orElse: () {
                  final nonFood = cats.where((c) => c.name != 'Ăn uống').toList();
                  return nonFood.isNotEmpty
                      ? nonFood.first
                      : (cats.isNotEmpty ? cats.first : null);
                },
              ),
            );
            targetCategoryId = defaultBillCat?.id ?? 1;
          } else {
            // Default legacy/null income category:
            // 1. 'Lương'
            // 2. 'Thưởng'
            final defaultIncomeCat = cats.firstWhere(
              (c) => c.name == 'Lương',
              orElse: () => cats.firstWhere(
                (c) => c.name == 'Thưởng',
                orElse: () => cats.isNotEmpty ? cats.first : null,
              ),
            );
            targetCategoryId = defaultIncomeCat?.id ?? 1;
          }
        }
```

---

### 4.3 Changes to `lib/features/dashboard/presentation/widgets/upcoming_obligations_card.dart`

Convert `UpcomingObligationsCard` to a `ConsumerWidget` and add `catMap` lookup:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../transactions/presentation/controllers/transaction_providers.dart';

/// Upcoming Obligations Card on Dashboard.
class UpcomingObligationsCard extends ConsumerWidget {
  final List<ScheduledItem> pendingBills;
  final ScheduledItem? nextIncome;
  final ValueChanged<int> onPayObligation;
  final ValueChanged<ScheduledItem>? onEditObligation;
  final ValueChanged<ScheduledItem>? onDeleteObligation;

  const UpcomingObligationsCard({
    super.key,
    required this.pendingBills,
    this.nextIncome,
    required this.onPayObligation,
    this.onEditObligation,
    this.onDeleteObligation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c.name};
```

For pending bills:
```dart
                      final catName = bill.categoryId != null ? catMap[bill.categoryId] : null;
                      ...
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.title, style: AppTypography.bodyMedium),
                            if (catName != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                catName,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                            Text(
                              VndFormatter.format(bill.amountVnd),
                              style: VndFormatter.withTabularFigures(
                                AppTypography.caption.copyWith(
                                  color: AppColors.textAccentRubySecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
```
*Note*: Displaying `catName` as its own Text widget preserves compatibility with existing tests expecting exact match on `find.text(bill.title)` and `find.text(VndFormatter.format(bill.amountVnd))`.

---

## 5. Verification Method

### 5.1 Project Commands to Run
```powershell
$env:JAVA_HOME = "C:\Users\coihu12\jdk17"
$env:ANDROID_HOME = "C:\Users\coihu12\Android\Sdk"
$env:Path = "C:\Users\coihu12\flutter\bin;C:\Users\coihu12\jdk17\bin;C:\Users\coihu12\Android\Sdk\platform-tools;" + $env:Path

flutter test test/unit/m2_r1_single_payment_plans_test.dart
flutter test test/widget/m2_r1_obligations_ux_test.dart
flutter test test/database/acceptance_scenarios_1_to_15_test.dart
```

### 5.2 Concrete New Automated Test for R1 Isolation
Create in `test/unit/m3_r1_scheduled_obligations_isolation_test.dart`:
```dart
import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/envelopes/providers/envelope_providers.dart';
import 'package:dongtien/features/plans/presentation/providers/plans_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openMemoryDb() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
    ),
  );
}

void main() {
  group('R1: Scheduled Obligations Category Selection & Isolation', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _openMemoryDb();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          ledgerDaoProvider.overrideWithValue(db.ledgerDao),
          envelopeDaoProvider.overrideWithValue(db.envelopeDao),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
        'Paying Tiền nhà (3.500.000 ₫) under Nhà cửa leaves Ăn uống budget at 0 ₫ spent and Ăn uống envelope untouched',
        () async {
      // 1. Seed initial liquid cash: 10.000.000 ₫ in Tiền mặt
      final cashAccountId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingBalance(
          assetAccountId: cashAccountId,
          amountVnd: 10000000,
          occurredAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // 2. Fetch categories
      final categories = await db.select(db.categories).get();
      final foodCat = categories.firstWhere((c) => c.name == 'Ăn uống');
      final housingCat = categories.firstWhere((c) => c.name == 'Nhà cửa');
      final utilitiesCat =
          categories.firstWhere((c) => c.name == 'Hoá đơn & Tiện ích');

      // 3. Set up 'Ăn uống' Category Budget for 3.000.000 ₫
      final controller = container.read(plansControllerProvider.notifier);
      await controller.upsertCategoryBudget(
        categoryId: foodCat.id,
        limitVnd: 3000000,
      );

      // 4. Create an 'Ăn uống' virtual fund envelope with 3.000.000 ₫ reserved
      final foodEnvelopeId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ Ăn uống',
              policy: 'FLEXIBLE',
              reservedBalanceVnd: const Value(3000000),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      // 5. Create scheduled bill for 'Tiền nhà' (3.500.000 ₫) under 'Nhà cửa'
      final now = DateTime.now();
      final billId = await controller.createScheduledItem(
        kind: 'BILL',
        title: 'Tiền nhà tháng 11',
        amountVnd: 3500000,
        dueDate: DateTime(now.year, now.month, 15),
        categoryId: housingCat.id,
        linkedEnvelopeId: null, // Not linked to any envelope
      );

      // 6. Pay the bill
      final txId = await controller.markScheduledItemPaid(scheduledItemId: billId);
      expect(txId, greaterThan(0));

      // 7. Verify ledger postings: Debit is on Nhà cửa, NOT Ăn uống
      final postings = await (db.select(db.journalPostings)
            ..where((p) => p.transactionId.equals(txId)))
          .get();
      final debitPosting = postings.firstWhere((p) => p.debitVnd > 0);
      expect(debitPosting.categoryId, equals(housingCat.id));
      expect(debitPosting.debitVnd, equals(3500000));

      // 8. Verify Ăn uống Category Budget is 0 ₫ spent
      final budgetSummary =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      final foodBudget =
          budgetSummary.items.firstWhere((i) => i.categoryId == foodCat.id);
      expect(foodBudget.spentVnd.amount, equals(0));
      expect(foodBudget.remainingVnd.amount, equals(3000000));
      expect(foodBudget.isOverBudget, isFalse);

      // 9. Verify Ăn uống Envelope balance is untouched (3.000.000 ₫)
      final foodEnv = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(foodEnvelopeId)))
          .getSingle();
      expect(foodEnv.reservedBalanceVnd, equals(3000000));

      // 10. Verify legacy fallback: bill with categoryId == null defaults to Hoá đơn & Tiện ích
      final legacyBillId = await controller.createScheduledItem(
        kind: 'BILL',
        title: 'Hoá đơn internet cũ',
        amountVnd: 250000,
        dueDate: DateTime(now.year, now.month, 20),
        categoryId: null,
      );
      final legacyTxId =
          await controller.markScheduledItemPaid(scheduledItemId: legacyBillId);
      final legacyPostings = await (db.select(db.journalPostings)
            ..where((p) => p.transactionId.equals(legacyTxId)))
          .get();
      final legacyDebit = legacyPostings.firstWhere((p) => p.debitVnd > 0);
      expect(legacyDebit.categoryId, equals(utilitiesCat.id));
      expect(legacyDebit.categoryId, isNot(equals(foodCat.id)));

      // Food budget spent still exactly 0 ₫
      final budgetSummaryAfterLegacy =
          await container.read(currentMonthlyBudgetSummaryProvider.future);
      final foodBudgetAfter = budgetSummaryAfterLegacy.items
          .firstWhere((i) => i.categoryId == foodCat.id);
      expect(foodBudgetAfter.spentVnd.amount, equals(0));
    });
  });
}
```
