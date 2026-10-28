import 'package:dongtien/app/app.dart';
import 'package:dongtien/app/theme/app_colors.dart';
import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/category_budget_progress.dart';
import 'package:dongtien/domain/forecasting/safe_to_spend_calculator.dart';
import 'package:dongtien/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:dongtien/features/dashboard/presentation/providers/safe_to_spend_provider.dart';
import 'package:dongtien/features/dashboard/presentation/widgets/fund_progress_card.dart';
import 'package:dongtien/features/dashboard/presentation/widgets/safe_to_spend_hero_card.dart';
import 'package:dongtien/features/plans/presentation/providers/plans_providers.dart';
import 'package:dongtien/features/transactions/presentation/controllers/transaction_providers.dart';
import 'package:dongtien/features/dashboard/presentation/widgets/spending_vs_budget_card.dart';
import 'package:dongtien/features/dashboard/presentation/widgets/upcoming_obligations_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Finder bySemanticsId(String id) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.identifier == id,
    );

void main() {
  group('SafeToSpendHeroCard Widget Tests', () {
    testWidgets(
        'Renders positive Safe-to-Spend amount in Jade color with shield icon',
        (tester) async {
      final result = SafeToSpendResult(
        safeToSpend: VndMoney(8500000),
        dailyAllowance: VndMoney(283333),
        isDeficit: false,
        daysRemaining: 30,
        breakdown: SafeToSpendBreakdown(
          liquidAssets: VndMoney(10000000),
          protectedReserves: VndMoney(1000000),
          unfundedCommittedOutflows: VndMoney(500000),
          minimumCashBuffer: VndMoney.zero,
          billAllocations: [],
          envelopeCoverages: [],
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SafeToSpendHeroCard(result: result)),
      ));

      expect(bySemanticsId('hero_safe_to_spend'), findsOneWidget);
      expect(find.text('8.500.000 ₫'), findsOneWidget);
      expect(find.text('283.333 ₫/ngày (30 ngày tới)'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

      // Verify tabular figures on amount
      final amountText = tester.widget<Text>(find.text('8.500.000 ₫'));
      expect(
        amountText.style?.fontFeatures
            ?.contains(const FontFeature.tabularFigures()),
        isTrue,
      );
    });

    testWidgets(
        'Scenario 12: Renders negative deficit in Ruby red with 0 ₫/ngày',
        (tester) async {
      final result = SafeToSpendResult(
        safeToSpend: VndMoney(-1500000),
        dailyAllowance: VndMoney.zero,
        isDeficit: true,
        daysRemaining: 15,
        breakdown: SafeToSpendBreakdown(
          liquidAssets: VndMoney(2000000),
          protectedReserves: VndMoney(1500000),
          unfundedCommittedOutflows: VndMoney(1000000),
          minimumCashBuffer: VndMoney(1000000),
          billAllocations: [],
          envelopeCoverages: [],
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SafeToSpendHeroCard(result: result)),
      ));

      expect(find.text('-1.500.000 ₫'), findsOneWidget);
      expect(find.text('0 ₫/ngày (Đang thâm hụt ngân sách)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.text('Các nghĩa vụ và quỹ dự phòng vượt quá tiền mặt hiện có.'),
        findsOneWidget,
      );

      final amountText = tester.widget<Text>(find.text('-1.500.000 ₫'));
      expect(amountText.style?.color, AppColors.textAccentRubyPrimary);
    });

    testWidgets(
        'Tapping info button opens formula breakdown modal with 4 terms',
        (tester) async {
      final result = SafeToSpendResult(
        safeToSpend: VndMoney(7500000),
        dailyAllowance: VndMoney(250000),
        isDeficit: false,
        daysRemaining: 30,
        breakdown: SafeToSpendBreakdown(
          liquidAssets: VndMoney(10000000),
          protectedReserves: VndMoney(1500000),
          unfundedCommittedOutflows: VndMoney(500000),
          minimumCashBuffer: VndMoney(500000),
          billAllocations: [],
          envelopeCoverages: [],
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SafeToSpendHeroCard(result: result)),
      ));

      // Tap info button
      await tester.tap(bySemanticsId('btn_safe_to_spend_breakdown'));
      await tester.pumpAndSettle();

      expect(bySemanticsId('modal_safe_to_spend_breakdown'), findsOneWidget);
      expect(find.text('Công thức Tiền an toàn chi tiêu'), findsOneWidget);
      expect(find.text('Tài sản tiền mặt khả dụng'), findsOneWidget);
      expect(find.text('Dự phòng quỹ được bảo vệ'), findsOneWidget);
      expect(find.text('Nghĩa vụ chưa cấp vốn'), findsOneWidget);
      expect(find.text('Vốn đệm tiền mặt tối thiểu'), findsOneWidget);
      final modalFinder = bySemanticsId('modal_safe_to_spend_breakdown');
      expect(
        find.descendant(of: modalFinder, matching: find.text('10.000.000 ₫')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: modalFinder, matching: find.text('1.500.000 ₫')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: modalFinder, matching: find.text('7.500.000 ₫')),
        findsOneWidget,
      );
    });
  });

  group('Dashboard Cards Widget Tests', () {
    testWidgets('SpendingVsBudgetCard displays ratio and amounts',
        (tester) async {
      final summary = MonthlyBudgetSummary(
        yearMonth: 202610,
        categoryProgresses: [
          CategoryBudgetProgress(
            categoryId: 1,
            categoryName: 'Ăn uống',
            yearMonth: 202610,
            limitVnd: VndMoney(5000000),
            spentVnd: VndMoney(4200000),
            alertThresholdPct: 80,
          ),
        ],
      );

      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpendingVsBudgetCard(
            summary: summary,
            onTap: () => tapped = true,
          ),
        ),
      ));

      expect(bySemanticsId('card_spending_vs_budget'), findsOneWidget);
      expect(find.text('84%'), findsOneWidget);
      expect(find.text('Đã chi: 4.200.000 ₫'), findsOneWidget);
      expect(find.text('Hạn mức: 5.000.000 ₫'), findsOneWidget);

      await tester.tap(bySemanticsId('card_spending_vs_budget'));
      expect(tapped, isTrue);
    });

    testWidgets('UpcomingObligationsCard displays pending bills and pay action',
        (tester) async {
      int? paidBillId;
      final pendingBills = [
        const ScheduledItem(
          id: 42,
          kind: 'BILL',
          title: 'Tiền Điện',
          amountVnd: 750000,
          dueDateMs: 1761609600000,
          recurrence: 'MONTHLY',
          anchorDayOfMonth: 15,
          status: 'PENDING',
          reminderDaysBefore: 1,
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UpcomingObligationsCard(
            pendingBills: pendingBills,
            onPayObligation: (id) => paidBillId = id,
          ),
        ),
      ));

      expect(bySemanticsId('card_upcoming_obligations'), findsOneWidget);
      expect(find.text('Tiền Điện'), findsOneWidget);
      expect(find.text('750.000 ₫'), findsOneWidget);
      expect(bySemanticsId('btn_pay_obligation_42'), findsOneWidget);

      await tester.tap(bySemanticsId('btn_pay_obligation_42'));
      expect(paidBillId, equals(42));
    });

    testWidgets('FundProgressCard displays reserved balance and envelope count',
        (tester) async {
      bool tapped = false;
      final envelopes = [
        const Envelope(
          id: 1,
          name: 'Quỹ khẩn cấp',
          policy: 'PROTECTED',
          reservedBalanceVnd: 5000000,
          allowNegativeException: false,
          priority: 1,
          isArchived: false,
          rolloverEnabled: false,
        ),
        const Envelope(
          id: 2,
          name: 'Mua sắm Tết',
          policy: 'FLEXIBLE',
          reservedBalanceVnd: 2000000,
          allowNegativeException: false,
          priority: 2,
          isArchived: false,
          rolloverEnabled: false,
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FundProgressCard(
            envelopes: envelopes,
            onTap: () => tapped = true,
          ),
        ),
      ));

      expect(bySemanticsId('card_summary_reserved'), findsOneWidget);
      expect(find.text('7.000.000 ₫'), findsOneWidget);
      expect(find.text('2 quỹ đang hoạt động.'), findsOneWidget);

      await tester.tap(bySemanticsId('card_summary_reserved'));
      expect(tapped, isTrue);
    });
  });

  group('DongTienApp Shell & Tab Switching Tests', () {
    testWidgets(
        'Renders all 4 navigation tabs and switches tabs via bottom bar',
        (tester) async {
      final safeToSpendMock = SafeToSpendResult(
        safeToSpend: VndMoney(10000000),
        dailyAllowance: VndMoney(333333),
        isDeficit: false,
        daysRemaining: 30,
        breakdown: SafeToSpendBreakdown(
          liquidAssets: VndMoney(10000000),
          protectedReserves: VndMoney.zero,
          unfundedCommittedOutflows: VndMoney.zero,
          minimumCashBuffer: VndMoney.zero,
          billAllocations: [],
          envelopeCoverages: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            safeToSpendProvider
                .overrideWithValue(AsyncValue.data(safeToSpendMock)),
            liquidAssetsStreamProvider
                .overrideWith((ref) => Stream.value(10000000)),
            accountsWithBalancesStreamProvider
                .overrideWith((ref) => Stream.value([])),
            settingsStreamProvider.overrideWith(
              (ref) => Stream.value(
                const Setting(
                  id: 1,
                  minimumCashBufferVnd: 0,
                  periodStartDay: 1,
                  dailyReminderHour: 20,
                  dailyReminderMinute: 0,
                  notificationsEnabled: false,
                  schemaVersion: 1,
                ),
              ),
            ),
            currentMonthlyBudgetSummaryProvider.overrideWith(
              (ref) => Stream.value(
                const MonthlyBudgetSummary(
                    yearMonth: 202610, categoryProgresses: []),
              ),
            ),
            pendingBillsStreamProvider.overrideWith((ref) => Stream.value([])),
            nextPlannedIncomeStreamProvider
                .overrideWith((ref) => Stream.value(null)),
            envelopesStreamProvider.overrideWith((ref) => Stream.value([])),
            recentTransactionsStreamProvider
                .overrideWith((ref) => Stream.value([])),
            cleanTransactionsStreamProvider
                .overrideWith((ref) => Stream.value([])),
            allPostingsStreamProvider.overrideWith((ref) => Stream.value([])),
            categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
            netWorthStreamProvider
                .overrideWith((ref) => Stream.value(10000000)),
            allScheduledItemsStreamProvider
                .overrideWith((ref) => Stream.value([])),
          ],
          child: const DongTienApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0 Dashboard is active
      expect(find.text('Đồng Tiền'), findsOneWidget);
      expect(bySemanticsId('hero_safe_to_spend'), findsOneWidget);
      expect(find.text('10.000.000 ₫'), findsWidgets);

      // Verify 4 tabs exist
      expect(bySemanticsId('nav_tab_dashboard'), findsOneWidget);
      expect(bySemanticsId('nav_tab_transactions'), findsOneWidget);
      expect(bySemanticsId('nav_tab_funds'), findsOneWidget);
      expect(bySemanticsId('nav_tab_plans'), findsOneWidget);

      // Switch to Tab 1 (Giao dịch)
      await tester.tap(bySemanticsId('nav_tab_transactions'));
      await tester.pumpAndSettle();
      expect(find.text('Giao dịch'), findsWidgets);

      // Switch to Tab 2 (Quỹ tiền)
      await tester.tap(bySemanticsId('nav_tab_funds'));
      await tester.pumpAndSettle();
      expect(find.text('Quỹ tiền'), findsWidgets);

      // Switch to Tab 3 (Kế hoạch)
      await tester.tap(bySemanticsId('nav_tab_plans'));
      await tester.pumpAndSettle();
      expect(find.text('Kế hoạch'), findsWidgets);

      // Switch back to Tab 0 (Tổng quan)
      await tester.tap(bySemanticsId('nav_tab_dashboard'));
      await tester.pumpAndSettle();
      expect(bySemanticsId('hero_safe_to_spend'), findsOneWidget);

      // Verify Quick-Add FAB
      expect(bySemanticsId('fab_quick_add'), findsOneWidget);
      await tester.tap(bySemanticsId('fab_quick_add'));
      await tester.pumpAndSettle();
      expect(bySemanticsId('modal_quick_add'), findsOneWidget);
    });
  });
}
