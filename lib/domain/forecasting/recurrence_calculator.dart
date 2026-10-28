/// Pure Dart calculator for recurrence schedules with anchor preservation.
///
/// Implements Section 9.2 of `ARCHITECTURE_AND_RULES.md`:
/// `actual_due_day = min(anchor_day_of_month, daysInMonth(Y, M))`
///
/// Guarantees drift-free recurrence across month lengths and leap years:
/// e.g. A bill anchored to day 31 evaluated in February (28 days) produces Feb 28;
/// evaluated in March (31 days) it restores to March 31 without anchor degradation.
class RecurrenceCalculator {
  const RecurrenceCalculator._();

  /// Determines if a Gregorian [year] is a leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Returns the number of days in [month] of [year] (1..12).
  static int daysInMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(
        month,
        'month',
        'Month must be between 1 and 12',
      );
    }
    if (month == 2) {
      return isLeapYear(year) ? 29 : 28;
    }
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month];
  }

  /// Calculates the actual day of month preserving the anchor without degradation:
  /// `actual_due_day = min(anchor_day_of_month, daysInMonth(Y, M))`.
  static int calculateActualDueDay(int anchorDayOfMonth, int year, int month) {
    if (anchorDayOfMonth < 1 || anchorDayOfMonth > 31) {
      throw ArgumentError.value(
        anchorDayOfMonth,
        'anchorDayOfMonth',
        'Anchor day must be between 1 and 31',
      );
    }
    final maxDays = daysInMonth(year, month);
    return anchorDayOfMonth < maxDays ? anchorDayOfMonth : maxDays;
  }

  /// Computes the next due date given the [currentDueDate], [recurrence], and optional [anchorDayOfMonth].
  ///
  /// Recurrence options:
  /// - `NONE`: throws [ArgumentError] (no next due date).
  /// - `WEEKLY`: adds 7 calendar days.
  /// - `MONTHLY`: advances to next month using `calculateActualDueDay(anchor, nextYear, nextMonth)`.
  /// - `YEARLY`: advances to next year using `calculateActualDueDay(anchor, nextYear, currentMonth)`.
  static DateTime computeNextDueDate({
    required DateTime currentDueDate,
    required String recurrence,
    int? anchorDayOfMonth,
  }) {
    final cleanRecurrence = recurrence.trim().toUpperCase();
    final anchor = anchorDayOfMonth ?? currentDueDate.day;

    switch (cleanRecurrence) {
      case 'WEEKLY':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month,
          currentDueDate.day + 7,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
          currentDueDate.millisecond,
        );

      case 'MONTHLY':
        final int nextYear = currentDueDate.month == 12
            ? currentDueDate.year + 1
            : currentDueDate.year;
        final int nextMonth =
            currentDueDate.month == 12 ? 1 : currentDueDate.month + 1;
        final int actualDay =
            calculateActualDueDay(anchor, nextYear, nextMonth);
        return DateTime(
          nextYear,
          nextMonth,
          actualDay,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
          currentDueDate.millisecond,
        );

      case 'YEARLY':
        final int nextYear = currentDueDate.year + 1;
        final int actualDay =
            calculateActualDueDay(anchor, nextYear, currentDueDate.month);
        return DateTime(
          nextYear,
          currentDueDate.month,
          actualDay,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
          currentDueDate.millisecond,
        );

      case 'NONE':
        throw ArgumentError(
          'Cannot compute next due date for non-recurring item (NONE)',
        );

      default:
        throw ArgumentError('Unsupported recurrence type: $recurrence');
    }
  }

  /// Generates a list of all occurrence dates up to [horizonDate].
  static List<DateTime> generateRecurrenceDates({
    required DateTime startDueDate,
    required String recurrence,
    int? anchorDayOfMonth,
    required DateTime horizonDate,
    int maxOccurrences = 365,
  }) {
    if (recurrence.trim().toUpperCase() == 'NONE') {
      return [startDueDate];
    }

    final int effectiveAnchor = anchorDayOfMonth ?? startDueDate.day;

    final List<DateTime> dates = [];
    DateTime current = startDueDate;
    int count = 0;

    final horizonEndOfDay = DateTime(
      horizonDate.year,
      horizonDate.month,
      horizonDate.day,
      23,
      59,
      59,
      999,
    );

    while (!current.isAfter(horizonEndOfDay) && count < maxOccurrences) {
      dates.add(current);
      count++;
      current = computeNextDueDate(
        currentDueDate: current,
        recurrence: recurrence,
        anchorDayOfMonth: effectiveAnchor,
      );
    }

    return dates;
  }
}
