import 'package:dongtien/core/money/vnd_money.dart';
import 'recurrence_calculator.dart';

enum ScheduledItemKind {
  bill,
  plannedIncome;

  static ScheduledItemKind fromString(String val) {
    switch (val.toUpperCase()) {
      case 'BILL':
        return ScheduledItemKind.bill;
      case 'PLANNED_INCOME':
        return ScheduledItemKind.plannedIncome;
      default:
        throw ArgumentError('Invalid scheduled item kind: "$val"');
    }
  }
}

/// Domain model of a scheduled obligation or planned income.
class ForecastScheduledItem {
  final int id;
  final ScheduledItemKind kind;
  final String title;
  final VndMoney amount;
  final DateTime dueDate;
  final String recurrence;
  final int? anchorDayOfMonth;
  final String status;

  const ForecastScheduledItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.recurrence,
    this.anchorDayOfMonth,
    required this.status,
  });
}

/// A single day's projected cash flow data point.
class CashFlowTimelinePoint {
  final DateTime date;
  final VndMoney startingBalance;
  final VndMoney projectedInflows;
  final VndMoney projectedOutflows;
  final VndMoney netChange;
  final VndMoney closingBalance;
  final bool isBufferBreached;
  final VndMoney deficitAmount;
  final List<String> eventTitles;

  const CashFlowTimelinePoint({
    required this.date,
    required this.startingBalance,
    required this.projectedInflows,
    required this.projectedOutflows,
    required this.netChange,
    required this.closingBalance,
    required this.isBufferBreached,
    required this.deficitAmount,
    required this.eventTitles,
  });
}

/// Comprehensive result of 30/60/90-day cash flow forecast.
class CashFlowForecastResult {
  final VndMoney startingBalance;
  final VndMoney endingBalance;
  final VndMoney lowestBalance;
  final DateTime lowestBalanceDate;
  final VndMoney totalInflows;
  final VndMoney totalOutflows;
  final VndMoney netCashFlow;
  final bool hasDeficit;
  final DateTime? firstDeficitDate;
  final VndMoney maxDeficitAmount;
  final List<CashFlowTimelinePoint> dailyPoints;

  const CashFlowForecastResult({
    required this.startingBalance,
    required this.endingBalance,
    required this.lowestBalance,
    required this.lowestBalanceDate,
    required this.totalInflows,
    required this.totalOutflows,
    required this.netCashFlow,
    required this.hasDeficit,
    this.firstDeficitDate,
    required this.maxDeficitAmount,
    required this.dailyPoints,
  });
}

/// Pure Dart cash flow projection engine.
class CashFlowForecaster {
  const CashFlowForecaster._();

  /// Projects daily balances for [horizonDays] (e.g. 30, 60, or 90 days) starting from [startDate].
  static CashFlowForecastResult project({
    required VndMoney startingLiquidAssets,
    required VndMoney minimumCashBuffer,
    required List<ForecastScheduledItem> scheduledItems,
    required DateTime startDate,
    required int horizonDays,
  }) {
    if (horizonDays <= 0) {
      throw ArgumentError.value(
        horizonDays,
        'horizonDays',
        'Horizon days must be strictly positive (> 0)',
      );
    }

    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endDay = DateTime(
        startDate.year, startDate.month, startDate.day + horizonDays - 1);

    // 1. Expand recurring and one-off items into discrete daily event buckets
    final Map<int, List<ForecastScheduledItem>> eventsByDayOffset = {};

    for (final item in scheduledItems) {
      if (item.status != 'PENDING') {
        continue; // Paid or skipped items are excluded from future forecast
      }

      final dates = RecurrenceCalculator.generateRecurrenceDates(
        startDueDate: item.dueDate,
        recurrence: item.recurrence,
        anchorDayOfMonth: item.anchorDayOfMonth,
        horizonDate: endDay,
      );

      for (final dt in dates) {
        final dtDay = DateTime(dt.year, dt.month, dt.day);
        final offset = dtDay.difference(startDay).inDays;
        if (offset >= 0 && offset < horizonDays) {
          eventsByDayOffset.putIfAbsent(offset, () => []).add(item);
        }
      }
    }

    // 2. Iterate step-by-step through each calendar day
    final List<CashFlowTimelinePoint> points = [];
    VndMoney currentBalance = startingLiquidAssets;
    VndMoney lowestBal = startingLiquidAssets;
    DateTime lowestBalDate = startDay;
    DateTime? firstDeficitDate;
    VndMoney maxDeficit = VndMoney.zero;
    int totalInflowVnd = 0;
    int totalOutflowVnd = 0;

    for (int dayIdx = 0; dayIdx < horizonDays; dayIdx++) {
      final currentDayDate =
          DateTime(startDay.year, startDay.month, startDay.day + dayIdx);
      final dayEvents = eventsByDayOffset[dayIdx] ?? const [];

      int dayInflowsVnd = 0;
      int dayOutflowsVnd = 0;
      final List<String> titles = [];

      for (final event in dayEvents) {
        titles.add(event.title);
        if (event.kind == ScheduledItemKind.plannedIncome) {
          dayInflowsVnd += event.amount.amount;
        } else {
          dayOutflowsVnd += event.amount.amount;
        }
      }

      totalInflowVnd += dayInflowsVnd;
      totalOutflowVnd += dayOutflowsVnd;

      final VndMoney dayInflows = VndMoney(dayInflowsVnd);
      final VndMoney dayOutflows = VndMoney(dayOutflowsVnd);
      final VndMoney netChange = dayInflows - dayOutflows;
      final VndMoney closingBalance = currentBalance + netChange;

      final bool isBufferBreached = closingBalance < minimumCashBuffer;
      final VndMoney deficit = isBufferBreached
          ? (minimumCashBuffer - closingBalance)
          : VndMoney.zero;

      if (isBufferBreached) {
        firstDeficitDate ??= currentDayDate;
        if (deficit > maxDeficit) {
          maxDeficit = deficit;
        }
      }

      if (closingBalance < lowestBal) {
        lowestBal = closingBalance;
        lowestBalDate = currentDayDate;
      }

      points.add(CashFlowTimelinePoint(
        date: currentDayDate,
        startingBalance: currentBalance,
        projectedInflows: dayInflows,
        projectedOutflows: dayOutflows,
        netChange: netChange,
        closingBalance: closingBalance,
        isBufferBreached: isBufferBreached,
        deficitAmount: deficit,
        eventTitles: titles,
      ));

      currentBalance = closingBalance;
    }

    final VndMoney totalInflows = VndMoney(totalInflowVnd);
    final VndMoney totalOutflows = VndMoney(totalOutflowVnd);
    final VndMoney netCashFlow = totalInflows - totalOutflows;

    return CashFlowForecastResult(
      startingBalance: startingLiquidAssets,
      endingBalance: currentBalance,
      lowestBalance: lowestBal,
      lowestBalanceDate: lowestBalDate,
      totalInflows: totalInflows,
      totalOutflows: totalOutflows,
      netCashFlow: netCashFlow,
      hasDeficit: firstDeficitDate != null,
      firstDeficitDate: firstDeficitDate,
      maxDeficitAmount: maxDeficit,
      dailyPoints: points,
    );
  }
}
