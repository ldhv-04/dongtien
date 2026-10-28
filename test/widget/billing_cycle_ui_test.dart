import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/category_budget_progress.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/dashboard/presentation/widgets/spending_vs_budget_card.dart';
import 'package:dongtien/features/plans/presentation/widgets/category_budgets_view.dart';
import 'package:dongtien/features/transactions/presentation/controllers/transaction_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
  late AppDatabase db;

  setUp(() {
    db = _openMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('Billing Cycle UI Tests (SpendingVsBudgetCard & CategoryBudgetsView)',
      () {
    final summary = MonthlyBudgetSummary(
      yearMonth: 202610,
      cycleLabel: '15/10 – 14/11',
      categoryProgresses: [
        CategoryBudgetProgress(
          categoryId: 1,
          categoryName: 'Ăn uống',
          yearMonth: 202610,
          limitVnd: VndMoney(4000000),
          spentVnd: VndMoney(1200000),
        ),
      ],
    );

    testWidgets('SpendingVsBudgetCard renders cycle label with tabular figures',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingVsBudgetCard(
              summary: summary,
              onTap: () {},
            ),
          ),
        ),
      );

      final cycleTextFinder = find.text('Chu kỳ: 15/10 – 14/11');
      expect(cycleTextFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(cycleTextFinder);
      expect(
        textWidget.style?.fontFeatures
            ?.contains(const FontFeature.tabularFigures()),
        isTrue,
      );
    });

    testWidgets('CategoryBudgetsView renders cycle label with tabular figures',
        (tester) async {
      final category = Category(
        id: 1,
        name: 'Ăn uống',
        kind: 'EXPENSE',
        ledgerAccountId: 3,
        iconCode: 0xe532,
        colorHex: '#E86B1C',
        isDefault: true,
        isArchived: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            currentMonthlyBudgetSummaryProvider
                .overrideWith((ref) => Stream.value(summary)),
            categoriesStreamProvider
                .overrideWith((ref) => Stream.value([category])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CategoryBudgetsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cycleTextFinder = find.text('Chu kỳ: 15/10 – 14/11');
      expect(cycleTextFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(cycleTextFinder);
      expect(
        textWidget.style?.fontFeatures
            ?.contains(const FontFeature.tabularFigures()),
        isTrue,
      );
    });
  });
}
