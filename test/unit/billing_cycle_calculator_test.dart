import 'package:dongtien/domain/budgeting/billing_cycle_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillingCycleCalculator Unit Tests', () {
    test('periodStartDay = 1 matches standard calendar month', () {
      final ref = DateTime(2026, 10, 15);
      final cycle = BillingCycleCalculator.calculate(ref, 1);

      expect(cycle.periodStartDay, equals(1));
      expect(cycle.isCalendarMonth, isTrue);
      expect(cycle.cycleStart, equals(DateTime(2026, 10, 1)));
      expect(cycle.cycleEndInclusive,
          equals(DateTime(2026, 10, 31, 23, 59, 59, 999)));
      expect(cycle.cycleEndExclusive, equals(DateTime(2026, 11, 1)));
      expect(cycle.yearMonth, equals(202610));
      expect(cycle.formatCycleRange(), equals('01/10 – 31/10'));
      expect(cycle.reportPeriodLabel, equals('10/2026'));
    });

    test('periodStartDay = 15 on or after anchor day', () {
      final ref = DateTime(2026, 10, 20);
      final cycle = BillingCycleCalculator.calculate(ref, 15);

      expect(cycle.periodStartDay, equals(15));
      expect(cycle.isCalendarMonth, isFalse);
      expect(cycle.cycleStart, equals(DateTime(2026, 10, 15)));
      expect(cycle.cycleEndInclusive,
          equals(DateTime(2026, 11, 14, 23, 59, 59, 999)));
      expect(cycle.cycleEndExclusive, equals(DateTime(2026, 11, 15)));
      expect(cycle.yearMonth, equals(202610));
      expect(cycle.formatCycleRange(), equals('15/10 – 14/11'));
      expect(cycle.reportPeriodLabel, equals('10/2026 (15/10 – 14/11)'));
    });

    test('periodStartDay = 15 before anchor day', () {
      final ref = DateTime(2026, 10, 10);
      final cycle = BillingCycleCalculator.calculate(ref, 15);

      expect(cycle.periodStartDay, equals(15));
      expect(cycle.isCalendarMonth, isFalse);
      expect(cycle.cycleStart, equals(DateTime(2026, 9, 15)));
      expect(cycle.cycleEndInclusive,
          equals(DateTime(2026, 10, 14, 23, 59, 59, 999)));
      expect(cycle.cycleEndExclusive, equals(DateTime(2026, 10, 15)));
      expect(cycle.yearMonth, equals(202609));
      expect(cycle.formatCycleRange(), equals('15/09 – 14/10'));
      expect(cycle.reportPeriodLabel, equals('09/2026 (15/09 – 14/10)'));
    });

    test('periodStartDay exact anchor day', () {
      final ref = DateTime(2026, 5, 20);
      final cycle = BillingCycleCalculator.calculate(ref, 20);

      expect(cycle.cycleStart, equals(DateTime(2026, 5, 20)));
      expect(cycle.cycleEndInclusive,
          equals(DateTime(2026, 6, 19, 23, 59, 59, 999)));
      expect(cycle.cycleEndExclusive, equals(DateTime(2026, 6, 20)));
      expect(cycle.yearMonth, equals(202605));
      expect(cycle.formatCycleRange(), equals('20/05 – 19/06'));
    });

    test('Year boundary transition (December to January)', () {
      // 1. December on/after anchor 25 -> cycle spans into next year
      final refDec = DateTime(2026, 12, 28);
      final cycleDec = BillingCycleCalculator.calculate(refDec, 25);

      expect(cycleDec.cycleStart, equals(DateTime(2026, 12, 25)));
      expect(cycleDec.cycleEndInclusive,
          equals(DateTime(2027, 1, 24, 23, 59, 59, 999)));
      expect(cycleDec.cycleEndExclusive, equals(DateTime(2027, 1, 25)));
      expect(cycleDec.yearMonth, equals(202612));
      expect(cycleDec.formatCycleRange(), equals('25/12/2026 – 24/01/2027'));

      // 2. January before anchor 25 -> cycle started in previous year (December)
      final refJan = DateTime(2027, 1, 10);
      final cycleJan = BillingCycleCalculator.calculate(refJan, 25);

      expect(cycleJan.cycleStart, equals(DateTime(2026, 12, 25)));
      expect(cycleJan.cycleEndInclusive,
          equals(DateTime(2027, 1, 24, 23, 59, 59, 999)));
      expect(cycleJan.cycleEndExclusive, equals(DateTime(2027, 1, 25)));
      expect(cycleJan.yearMonth, equals(202612));
      expect(cycleJan.formatCycleRange(), equals('25/12/2026 – 24/01/2027'));
    });

    test('February transitions in non-leap year (2025, 28 days)', () {
      final ref = DateTime(2025, 2, 10);
      final cycle = BillingCycleCalculator.calculate(ref, 1);

      expect(cycle.cycleStart, equals(DateTime(2025, 2, 1)));
      expect(cycle.cycleEndInclusive,
          equals(DateTime(2025, 2, 28, 23, 59, 59, 999)));
      expect(cycle.cycleEndExclusive, equals(DateTime(2025, 3, 1)));
      expect(cycle.yearMonth, equals(202502));
      expect(cycle.formatCycleRange(), equals('01/02 – 28/02'));
    });

    test('February transitions in leap year (2024, 29 days)', () {
      final ref = DateTime(2024, 2, 15);
      final cycle = BillingCycleCalculator.calculate(ref, 1);

      expect(cycle.cycleStart, equals(DateTime(2024, 2, 1)));
      expect(cycle.cycleEndInclusive,
          equals(DateTime(2024, 2, 29, 23, 59, 59, 999)));
      expect(cycle.cycleEndExclusive, equals(DateTime(2024, 3, 1)));
      expect(cycle.yearMonth, equals(202402));
      expect(cycle.formatCycleRange(), equals('01/02 – 29/02'));
    });

    test('February anchor day 28 in non-leap year', () {
      final ref = DateTime(2025, 2, 28);
      final cycle = BillingCycleCalculator.calculate(ref, 28);

      expect(cycle.cycleStart, equals(DateTime(2025, 2, 28)));
      expect(cycle.cycleEndInclusive,
          equals(DateTime(2025, 3, 27, 23, 59, 59, 999)));
      expect(cycle.cycleEndExclusive, equals(DateTime(2025, 3, 28)));
      expect(cycle.yearMonth, equals(202502));
    });

    test('Argument validation: periodStartDay must be in 1..28', () {
      final now = DateTime.now();
      expect(
        () => BillingCycleCalculator.calculate(now, 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BillingCycleCalculator.calculate(now, -5),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BillingCycleCalculator.calculate(now, 29),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BillingCycleCalculator.calculate(now, 31),
        throwsA(isA<ArgumentError>()),
      );
      // Valid boundaries
      expect(() => BillingCycleCalculator.calculate(now, 1), returnsNormally);
      expect(() => BillingCycleCalculator.calculate(now, 28), returnsNormally);
    });
  });
}
