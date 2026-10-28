import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/forecasting/cash_flow_forecaster.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CashFlowForecaster — 30/60/90 Day Balance Timeline & Deficit Flags',
      () {
    final startDate = DateTime(2026, 10, 1);

    test(
        '30-day timeline projects daily balances with recurring and one-off items',
        () {
      final salary = ForecastScheduledItem(
        id: 1,
        kind: ScheduledItemKind.plannedIncome,
        title: 'Lương',
        amount: VndMoney(20000000),
        dueDate: DateTime(2026, 10, 5),
        recurrence: 'NONE',
        status: 'PENDING',
      );

      final rent = ForecastScheduledItem(
        id: 2,
        kind: ScheduledItemKind.bill,
        title: 'Tiền thuê nhà',
        amount: VndMoney(8000000),
        dueDate: DateTime(2026, 10, 10),
        recurrence: 'NONE',
        status: 'PENDING',
      );

      final result = CashFlowForecaster.project(
        startingLiquidAssets: VndMoney(5000000),
        minimumCashBuffer: VndMoney(2000000),
        scheduledItems: [salary, rent],
        startDate: startDate,
        horizonDays: 30,
      );

      expect(result.startingBalance, equals(VndMoney(5000000)));
      expect(result.totalInflows, equals(VndMoney(20000000)));
      expect(result.totalOutflows, equals(VndMoney(8000000)));
      expect(result.netCashFlow, equals(VndMoney(12000000)));
      expect(result.endingBalance, equals(VndMoney(17000000)));
      expect(result.hasDeficit, isFalse);
      expect(result.dailyPoints.length, equals(30));

      // Day 0 to 3 (Oct 1..4): balance remains 5M
      expect(result.dailyPoints[0].closingBalance, equals(VndMoney(5000000)));

      // Day 4 (Oct 5): Salary arrives (+20M -> 25M)
      expect(
          result.dailyPoints[4].projectedInflows, equals(VndMoney(20000000)));
      expect(result.dailyPoints[4].closingBalance, equals(VndMoney(25000000)));

      // Day 9 (Oct 10): Rent paid (-8M -> 17M)
      expect(
          result.dailyPoints[9].projectedOutflows, equals(VndMoney(8000000)));
      expect(result.dailyPoints[9].closingBalance, equals(VndMoney(17000000)));
    });

    test('Buffer breach detected with firstDeficitDate and maxDeficitAmount',
        () {
      // Starting balance = 3.000.000 ₫, Buffer = 2.000.000 ₫
      // Big bill on Oct 5 of 2.500.000 ₫ -> Balance drops to 500.000 ₫ (< 2M buffer by 1.5M!)
      final bill = ForecastScheduledItem(
        id: 1,
        kind: ScheduledItemKind.bill,
        title: 'Học phí',
        amount: VndMoney(2500000),
        dueDate: DateTime(2026, 10, 5),
        recurrence: 'NONE',
        status: 'PENDING',
      );

      final result = CashFlowForecaster.project(
        startingLiquidAssets: VndMoney(3000000),
        minimumCashBuffer: VndMoney(2000000),
        scheduledItems: [bill],
        startDate: startDate,
        horizonDays: 15,
      );

      expect(result.hasDeficit, isTrue);
      expect(result.firstDeficitDate, equals(DateTime(2026, 10, 5)));
      expect(result.maxDeficitAmount,
          equals(VndMoney(1500000))); // 2M buffer - 500k = 1.5M deficit
      expect(result.lowestBalance, equals(VndMoney(500000)));

      final breachedPoint = result.dailyPoints[4]; // Oct 5
      expect(breachedPoint.isBufferBreached, isTrue);
      expect(breachedPoint.deficitAmount, equals(VndMoney(1500000)));
    });

    test(
        'Non-pending items (PAID_OR_RECEIVED, SKIPPED) are excluded from forecast',
        () {
      final paidBill = ForecastScheduledItem(
        id: 1,
        kind: ScheduledItemKind.bill,
        title: 'Đã trả',
        amount: VndMoney(5000000),
        dueDate: DateTime(2026, 10, 3),
        recurrence: 'NONE',
        status: 'PAID_OR_RECEIVED',
      );

      final result = CashFlowForecaster.project(
        startingLiquidAssets: VndMoney(10000000),
        minimumCashBuffer: VndMoney.zero,
        scheduledItems: [paidBill],
        startDate: startDate,
        horizonDays: 10,
      );

      expect(result.totalOutflows, equals(VndMoney.zero));
      expect(result.endingBalance, equals(VndMoney(10000000)));
    });
  });
}
