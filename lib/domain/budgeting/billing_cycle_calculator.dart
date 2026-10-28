/// Pure Dart value object representing an active billing cycle.
class BillingCycle {
  final DateTime cycleStart;
  final DateTime cycleEndExclusive;
  final DateTime cycleEndInclusive;
  final int yearMonth;
  final int periodStartDay;

  const BillingCycle({
    required this.cycleStart,
    required this.cycleEndExclusive,
    required this.cycleEndInclusive,
    required this.yearMonth,
    required this.periodStartDay,
  });

  bool get isCalendarMonth => periodStartDay == 1;

  /// Formatted cycle range: e.g. "15/10 – 14/11" or "01/10 – 31/10".
  /// Spanning years: "15/12/2026 – 14/01/2027".
  String formatCycleRange({bool includeYear = false}) {
    final startDay = cycleStart.day.toString().padLeft(2, '0');
    final startMonth = cycleStart.month.toString().padLeft(2, '0');
    final endDay = cycleEndInclusive.day.toString().padLeft(2, '0');
    final endMonth = cycleEndInclusive.month.toString().padLeft(2, '0');

    if (includeYear || cycleStart.year != cycleEndInclusive.year) {
      return '$startDay/$startMonth/${cycleStart.year} – $endDay/$endMonth/${cycleEndInclusive.year}';
    }
    return '$startDay/$startMonth – $endDay/$endMonth';
  }

  /// Label for reports screen period header.
  String get reportPeriodLabel {
    final ymLabel =
        '${cycleStart.month.toString().padLeft(2, '0')}/${cycleStart.year}';
    if (isCalendarMonth) {
      return ymLabel;
    }
    return '$ymLabel (${formatCycleRange()})';
  }
}

/// Pure Dart calculator for billing cycles.
class BillingCycleCalculator {
  const BillingCycleCalculator._();

  static BillingCycle calculate(DateTime referenceDate, int periodStartDay) {
    if (periodStartDay < 1 || periodStartDay > 28) {
      throw ArgumentError.value(
        periodStartDay,
        'periodStartDay',
        'Billing cycle start day must be between 1 and 28',
      );
    }

    int startYear = referenceDate.year;
    int startMonth = referenceDate.month;

    if (periodStartDay > 1 && referenceDate.day < periodStartDay) {
      if (startMonth == 1) {
        startYear -= 1;
        startMonth = 12;
      } else {
        startMonth -= 1;
      }
    }

    final cycleStart =
        DateTime(startYear, startMonth, periodStartDay, 0, 0, 0, 0);

    int endYear = startYear;
    int endMonth = startMonth + 1;
    if (endMonth > 12) {
      endYear += 1;
      endMonth = 1;
    }
    final cycleEndExclusive =
        DateTime(endYear, endMonth, periodStartDay, 0, 0, 0, 0);

    final dayBefore = cycleEndExclusive.subtract(const Duration(days: 1));
    final cycleEndInclusive = DateTime(
      dayBefore.year,
      dayBefore.month,
      dayBefore.day,
      23,
      59,
      59,
      999,
    );

    final yearMonth = startYear * 100 + startMonth;

    return BillingCycle(
      cycleStart: cycleStart,
      cycleEndExclusive: cycleEndExclusive,
      cycleEndInclusive: cycleEndInclusive,
      yearMonth: yearMonth,
      periodStartDay: periodStartDay,
    );
  }
}
