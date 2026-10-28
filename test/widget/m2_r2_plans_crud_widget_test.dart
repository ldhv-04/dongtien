import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/category_budget_progress.dart';
import 'package:dongtien/domain/budgeting/feasibility_advisor.dart';
import 'package:dongtien/domain/forecasting/cash_flow_forecaster.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/envelopes/providers/envelope_providers.dart';
import 'package:dongtien/features/plans/presentation/providers/plans_providers.dart';
import 'package:dongtien/features/plans/presentation/widgets/category_budgets_view.dart';
import 'package:dongtien/features/plans/presentation/widgets/obligations_forecast_view.dart';
import 'package:dongtien/features/plans/presentation/widgets/savings_goals_view.dart';
import 'package:dongtien/features/transactions/presentation/controllers/transaction_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Finder bySemanticsId(String id) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.identifier == id,
    );

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

  group('M2 R2: Plans CRUD Widget Tests', () {
    testWidgets(
        'CategoryBudgetsView renders Edit and Delete buttons and shows confirmation dialog',
        (tester) async {
      final summary = MonthlyBudgetSummary(
        yearMonth: 202610,
        cycleLabel: '01/10 – 31/10',
        categoryProgresses: [
          CategoryBudgetProgress(
            categoryId: 10,
            categoryName: 'Ăn uống',
            yearMonth: 202610,
            limitVnd: VndMoney(5000000),
            spentVnd: VndMoney(1500000),
            alertThresholdPct: 80,
          ),
        ],
      );

      final dummyCategory = Category(
        id: 10,
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
                .overrideWith((ref) => Stream.value([dummyCategory])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CategoryBudgetsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify cycle label and budget details
      expect(find.text('Chu kỳ: 01/10 – 31/10'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);

      // Verify Edit and Delete semantics buttons exist
      final editBtn = bySemanticsId('btn_edit_budget_10');
      final deleteBtn = bySemanticsId('btn_delete_budget_10');
      expect(editBtn, findsOneWidget);
      expect(deleteBtn, findsOneWidget);

      // Tap Delete button -> confirmation dialog appears
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận xóa ngân sách'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hủy'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Xóa'), findsOneWidget);

      // Tap Cancel -> dialog dismisses
      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận xóa ngân sách'), findsNothing);
    });

    testWidgets(
        'SavingsGoalsView renders Edit and Delete buttons and shows confirmation dialog',
        (tester) async {
      final goal = ActiveGoalItem(
        id: 5,
        name: 'Quỹ khẩn cấp',
        currentReserved: VndMoney(2000000),
        targetAmount: VndMoney(10000000),
        remainingPeriods: 3,
      );

      final eval = FeasibilityEvaluation(
        status: FeasibilityStatus.feasible,
        totalRequiredPerPeriod: VndMoney(2666667),
        monthlyCapacity: VndMoney(5000000),
        deficit: VndMoney.zero,
        activeGoals: [goal],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            feasibilityEvaluationProvider
                .overrideWith((ref) => AsyncData(eval)),
            envelopesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SavingsGoalsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quỹ khẩn cấp'), findsOneWidget);

      final editBtn = bySemanticsId('btn_edit_goal_5');
      final deleteBtn = bySemanticsId('btn_delete_goal_5');
      expect(editBtn, findsOneWidget);
      expect(deleteBtn, findsOneWidget);

      // Tap Delete button -> confirmation dialog appears
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận xóa mục tiêu'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Hủy'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Xóa'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận xóa mục tiêu'), findsNothing);
    });

    testWidgets(
        'ObligationsForecastView renders category subtitle and Edit/Delete buttons for obligations',
        (tester) async {
      final pendingItem = ScheduledItem(
        id: 21,
        kind: 'BILL',
        title: 'Tiền internet VNPT',
        amountVnd: 220000,
        dueDateMs: DateTime(2026, 11, 20).millisecondsSinceEpoch,
        recurrence: 'NONE',
        anchorDayOfMonth: 20,
        status: 'PENDING',
        categoryId: 7,
        reminderDaysBefore: 1,
      );

      final completedItem = ScheduledItem(
        id: 22,
        kind: 'BILL',
        title: 'Tiền nước',
        amountVnd: 100000,
        dueDateMs: DateTime(2026, 11, 5).millisecondsSinceEpoch,
        recurrence: 'NONE',
        anchorDayOfMonth: 5,
        status: 'PAID_OR_RECEIVED',
        categoryId: 7,
        reminderDaysBefore: 1,
      );

      final forecast = CashFlowForecastResult(
        startingBalance: VndMoney(10000000),
        endingBalance: VndMoney(15000000),
        lowestBalance: VndMoney(8000000),
        lowestBalanceDate: DateTime(2026, 11, 10),
        totalInflows: VndMoney(10000000),
        totalOutflows: VndMoney(3000000),
        netCashFlow: VndMoney(7000000),
        hasDeficit: false,
        firstDeficitDate: null,
        maxDeficitAmount: VndMoney.zero,
        dailyPoints: [],
      );

      final category = Category(
        id: 7,
        name: 'Hoá đơn & Tiện ích',
        kind: 'EXPENSE',
        ledgerAccountId: 3,
        iconCode: 0xf2eb,
        colorHex: '#FAA800',
        isDefault: true,
        isArchived: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            allScheduledItemsStreamProvider.overrideWith(
                (ref) => Stream.value([pendingItem, completedItem])),
            cashFlowForecastProvider.overrideWith((ref) => AsyncData(forecast)),
            categoriesStreamProvider
                .overrideWith((ref) => Stream.value([category])),
            envelopesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ObligationsForecastView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify category subtitles contain category name
      expect(find.textContaining('Hoá đơn & Tiện ích'), findsNWidgets(2));

      // Verify Edit and Delete buttons on pending bill
      expect(bySemanticsId('btn_edit_obligation_21'), findsOneWidget);
      expect(bySemanticsId('btn_delete_obligation_21'), findsOneWidget);

      // Verify Edit and Delete buttons on completed bill
      expect(bySemanticsId('btn_edit_obligation_22'), findsOneWidget);
      expect(bySemanticsId('btn_delete_obligation_22'), findsOneWidget);

      // Tap Delete on pending bill -> confirmation dialog
      await tester.tap(bySemanticsId('btn_delete_obligation_21'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận xóa hoá đơn'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận xóa hoá đơn'), findsNothing);
    });
  });
}
