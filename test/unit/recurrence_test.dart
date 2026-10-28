import 'package:dongtien/domain/forecasting/recurrence_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
      'RecurrenceCalculator — Drift-Free Anchor Preservation & Gregorian Math',
      () {
    test('isLeapYear checks 4, 100, and 400 year rules', () {
      expect(RecurrenceCalculator.isLeapYear(2024), isTrue); // 4
      expect(RecurrenceCalculator.isLeapYear(2026), isFalse); // non-leap
      expect(RecurrenceCalculator.isLeapYear(2000), isTrue); // 400
      expect(RecurrenceCalculator.isLeapYear(1900), isFalse); // 100
      expect(RecurrenceCalculator.isLeapYear(2100), isFalse); // 100
    });

    test(
        'daysInMonth correctly returns month lengths including February leap years',
        () {
      expect(RecurrenceCalculator.daysInMonth(2026, 1), equals(31));
      expect(RecurrenceCalculator.daysInMonth(2026, 2), equals(28));
      expect(RecurrenceCalculator.daysInMonth(2024, 2), equals(29));
      expect(RecurrenceCalculator.daysInMonth(2026, 3), equals(31));
      expect(RecurrenceCalculator.daysInMonth(2026, 4), equals(30));
      expect(RecurrenceCalculator.daysInMonth(2026, 5), equals(31));
      expect(RecurrenceCalculator.daysInMonth(2026, 6), equals(30));
      expect(RecurrenceCalculator.daysInMonth(2026, 7), equals(31));
      expect(RecurrenceCalculator.daysInMonth(2026, 8), equals(31));
      expect(RecurrenceCalculator.daysInMonth(2026, 9), equals(30));
      expect(RecurrenceCalculator.daysInMonth(2026, 10), equals(31));
      expect(RecurrenceCalculator.daysInMonth(2026, 11), equals(30));
      expect(RecurrenceCalculator.daysInMonth(2026, 12), equals(31));

      expect(
          () => RecurrenceCalculator.daysInMonth(2026, 0), throwsArgumentError);
      expect(() => RecurrenceCalculator.daysInMonth(2026, 13),
          throwsArgumentError);
    });

    test(
        'Scenario 15B: Month-End Anchor Day 31 Preserves Schedule Without Drift',
        () {
      // In 2026 (non-leap year):
      // Jan 31 -> Feb 28 -> Mar 31 -> Apr 30 -> May 31
      final jan31 = DateTime(2026, 1, 31);
      final feb = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: jan31,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(feb.year, equals(2026));
      expect(feb.month, equals(2));
      expect(feb.day, equals(28));

      final mar = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: feb,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(mar.year, equals(2026));
      expect(mar.month, equals(3));
      expect(mar.day, equals(31)); // Anchor restored to 31! Never stuck at 28!

      final apr = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: mar,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(apr.year, equals(2026));
      expect(apr.month, equals(4));
      expect(apr.day, equals(30));

      final may = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: apr,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(may.year, equals(2026));
      expect(may.month, equals(5));
      expect(may.day, equals(31)); // Anchor restored to 31!
    });

    test('Month-End Anchor Day 31 in Leap Year 2024 resolves to Feb 29', () {
      final jan31 = DateTime(2024, 1, 31);
      final feb = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: jan31,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(feb.year, equals(2024));
      expect(feb.month, equals(2));
      expect(feb.day, equals(29));

      final mar = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: feb,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(mar.year, equals(2024));
      expect(mar.month, equals(3));
      expect(mar.day, equals(31));
    });

    test('Year-end rollover (December to January)', () {
      final dec15 = DateTime(2026, 12, 15);
      final jan = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: dec15,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 15,
      );
      expect(jan.year, equals(2027));
      expect(jan.month, equals(1));
      expect(jan.day, equals(15));
    });

    test('WEEKLY recurrence adds exactly 7 days', () {
      final mon = DateTime(2026, 10, 5);
      final nextMon = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: mon,
        recurrence: 'WEEKLY',
      );
      expect(nextMon, equals(DateTime(2026, 10, 12)));
    });

    test(
        'YEARLY recurrence advances one calendar year with anchor preservation',
        () {
      final feb29Leap = DateTime(2024, 2, 29);
      final nextYear = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: feb29Leap,
        recurrence: 'YEARLY',
        anchorDayOfMonth: 29,
      );
      expect(nextYear.year, equals(2025));
      expect(nextYear.month, equals(2));
      expect(nextYear.day, equals(28)); // Non-leap year clamps to 28
    });

    test('NONE recurrence throws ArgumentError', () {
      expect(
        () => RecurrenceCalculator.computeNextDueDate(
          currentDueDate: DateTime(2026, 10, 1),
          recurrence: 'NONE',
        ),
        throwsArgumentError,
      );
    });

    test('generateRecurrenceDates generates full sequence up to horizonDate',
        () {
      final dates = RecurrenceCalculator.generateRecurrenceDates(
        startDueDate: DateTime(2026, 1, 31),
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
        horizonDate: DateTime(2026, 6, 1),
      );

      expect(dates.length, equals(5)); // Jan 31, Feb 28, Mar 31, Apr 30, May 31
      expect(dates[0].day, equals(31));
      expect(dates[1].day, equals(28));
      expect(dates[2].day, equals(31));
      expect(dates[3].day, equals(30));
      expect(dates[4].day, equals(31));
    });

    test(
        'generateRecurrenceDates pins startDueDate.day when anchorDayOfMonth is null',
        () {
      // Starting on Jan 31 with anchorDayOfMonth = null
      // Must generate: Jan 31 -> Feb 28 -> Mar 31 -> Apr 30 -> May 31
      // Without pinning, Feb 28 would cause subsequent months to stick to 28
      final dates = RecurrenceCalculator.generateRecurrenceDates(
        startDueDate: DateTime(2026, 1, 31),
        recurrence: 'MONTHLY',
        anchorDayOfMonth: null,
        horizonDate: DateTime(2026, 6, 1),
      );

      expect(dates.length, equals(5));
      expect(dates[0], equals(DateTime(2026, 1, 31)));
      expect(dates[1], equals(DateTime(2026, 2, 28)));
      expect(dates[2], equals(DateTime(2026, 3, 31)));
      expect(dates[3], equals(DateTime(2026, 4, 30)));
      expect(dates[4], equals(DateTime(2026, 5, 31)));
    });
  });
}
