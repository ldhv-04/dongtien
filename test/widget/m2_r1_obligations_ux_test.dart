import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/core/widgets/custom_keypad.dart';
import 'package:dongtien/domain/forecasting/cash_flow_forecaster.dart';
import 'package:dongtien/features/dashboard/presentation/widgets/upcoming_obligations_card.dart';
import 'package:dongtien/features/plans/presentation/providers/plans_providers.dart';
import 'package:dongtien/features/plans/presentation/widgets/obligations_forecast_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Finder bySemanticsId(String id) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.identifier == id,
    );

void main() {
  group('UpcomingObligationsCard M2 UX Tests', () {
    testWidgets('Renders "Đã nhận" button for nextIncome and fires callback',
        (tester) async {
      int? paidId;
      final income = ScheduledItem(
        id: 101,
        kind: 'PLANNED_INCOME',
        title: 'Lương tháng 11',
        amountVnd: 20000000,
        dueDateMs: DateTime(2026, 11, 5).millisecondsSinceEpoch,
        recurrence: 'NONE',
        anchorDayOfMonth: 5,
        status: 'PENDING',
        reminderDaysBefore: 1,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UpcomingObligationsCard(
            pendingBills: const [],
            nextIncome: income,
            onPayObligation: (id) => paidId = id,
          ),
        ),
      ));

      expect(find.text('Thu nhập tiếp theo: Lương tháng 11 (20.000.000 ₫)'),
          findsOneWidget);
      final receiveBtn = bySemanticsId('btn_pay_obligation_101');
      expect(receiveBtn, findsOneWidget);
      expect(find.text('Đã nhận'), findsOneWidget);

      await tester.tap(receiveBtn);
      await tester.pumpAndSettle();

      expect(paidId, equals(101));
    });
  });

  group('ObligationsForecastView M2 UX Tests', () {
    final pendingBill = ScheduledItem(
      id: 1,
      kind: 'BILL',
      title: 'Tiền điện',
      amountVnd: 500000,
      dueDateMs: DateTime(2026, 11, 15).millisecondsSinceEpoch,
      recurrence: 'NONE',
      anchorDayOfMonth: 15,
      status: 'PENDING',
      reminderDaysBefore: 1,
    );

    final completedBill = ScheduledItem(
      id: 2,
      kind: 'BILL',
      title: 'Tiền nước',
      amountVnd: 150000,
      dueDateMs: DateTime(2026, 11, 1).millisecondsSinceEpoch,
      recurrence: 'NONE',
      anchorDayOfMonth: 1,
      status: 'PAID_OR_RECEIVED',
      reminderDaysBefore: 1,
    );

    final dummyForecast = CashFlowForecastResult(
      startingBalance: VndMoney(10000000),
      endingBalance: VndMoney(10000000),
      lowestBalance: VndMoney(10000000),
      lowestBalanceDate: DateTime(2026, 11, 1),
      totalInflows: VndMoney.zero,
      totalOutflows: VndMoney.zero,
      netCashFlow: VndMoney.zero,
      hasDeficit: false,
      maxDeficitAmount: VndMoney.zero,
      dailyPoints: const [],
    );

    testWidgets(
        'Renders pending items with active "Đã trả" and completed items in history section with disabled "Đã hoàn tất"',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allScheduledItemsStreamProvider.overrideWith(
              (ref) => Stream.value([pendingBill, completedBill]),
            ),
            cashFlowForecastProvider.overrideWithValue(
              AsyncValue.data(dummyForecast),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ObligationsForecastView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Upper Section: Pending Bill
      expect(find.text('Tiền điện'), findsOneWidget);
      expect(bySemanticsId('btn_pay_obligation_1'), findsOneWidget);
      expect(find.text('Đã trả'), findsOneWidget);

      // Lower Section: History header and Completed Bill
      expect(find.text('LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN'), findsOneWidget);
      expect(find.text('Tiền nước'), findsOneWidget);
      expect(bySemanticsId('btn_completed_obligation_2'), findsOneWidget);
      expect(find.text('Đã hoàn tất'), findsOneWidget);

      // Verify disabled button (onPressed is null)
      final completedBtn = tester.widget<OutlinedButton>(
        find.descendant(
          of: bySemanticsId('btn_completed_obligation_2'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(completedBtn.onPressed, isNull);
    });

    testWidgets(
        'Tapping "Đã trả" shows confirmation dialog, and cancel dismisses without paying',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allScheduledItemsStreamProvider.overrideWith(
              (ref) => Stream.value([pendingBill]),
            ),
            cashFlowForecastProvider.overrideWithValue(
              AsyncValue.data(dummyForecast),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ObligationsForecastView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Đã trả" button
      await tester.tap(bySemanticsId('btn_pay_obligation_1'));
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Xác nhận thanh toán'), findsOneWidget);
      expect(
        find.textContaining(
            'Bạn có chắc chắn muốn ghi nhận đã thanh toán hoá đơn "Tiền điện" với số tiền 500.000 ₫?'),
        findsOneWidget,
      );
      expect(find.text('Hủy'), findsOneWidget);

      // Tap "Hủy"
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Dialog dismissed, still pending
      expect(find.text('Xác nhận thanh toán'), findsNothing);
      expect(find.text('Tiền điện'), findsOneWidget);
    });
  });

  group('CustomKeypad Submission & Guard Tests', () {
    testWidgets(
        'Tapping Done when isSubmitting is true does not fire onDonePressed',
        (tester) async {
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomKeypad(
              onDigitPressed: (_) {},
              onBackspacePressed: () {},
              onDonePressed: () => doneCalled = true,
              isSubmitting: true,
            ),
          ),
        ),
      );

      await tester.tap(bySemanticsId('keypad_btn_done'));
      await tester.pumpAndSettle();

      expect(doneCalled, isFalse);
    });

    testWidgets(
        'Tapping Done when isDoneEnabled is false does not fire onDonePressed',
        (tester) async {
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomKeypad(
              onDigitPressed: (_) {},
              onBackspacePressed: () {},
              onDonePressed: () => doneCalled = true,
              isDoneEnabled: false,
            ),
          ),
        ),
      );

      await tester.tap(bySemanticsId('keypad_btn_done'));
      await tester.pumpAndSettle();

      expect(doneCalled, isFalse);
    });

    testWidgets('Tapping Done when active fires onDonePressed', (tester) async {
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomKeypad(
              onDigitPressed: (_) {},
              onBackspacePressed: () {},
              onDonePressed: () => doneCalled = true,
              isSubmitting: false,
              isDoneEnabled: true,
            ),
          ),
        ),
      );

      await tester.tap(bySemanticsId('keypad_btn_done'));
      await tester.pumpAndSettle();

      expect(doneCalled, isTrue);
    });
  });
}
