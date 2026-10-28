import 'dart:ui' show FontFeature;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/core/money/vnd_formatter.dart';

void main() {
  group('Adversarial Stress Test: VndMoney Boundaries', () {
    test(
        'Exact maxSafeVnd (9_000_000_000_000_000) allowed across all constructors',
        () {
      final m1 = VndMoney(9000000000000000);
      expect(m1.amount, 9000000000000000);
      expect(m1.isPositive, isTrue);
      expect(m1.isZero, isFalse);
      expect(m1.isNegative, isFalse);

      final m2 = VndMoney.positive(9000000000000000);
      expect(m2.amount, 9000000000000000);

      final m3 = VndMoney.nonNegative(9000000000000000);
      expect(m3.amount, 9000000000000000);
    });

    test(
        'Exact minSafeVnd (-9_000_000_000_000_000) allowed in standard constructor',
        () {
      final m = VndMoney(-9000000000000000);
      expect(m.amount, -9000000000000000);
      expect(m.isNegative, isTrue);
      expect(m.isZero, isFalse);
      expect(m.isPositive, isFalse);
    });

    test('Overflow by 1 (9_000_000_000_000_001) throws VndOverflowException',
        () {
      const int overflowVal = 9000000000000001;
      expect(() => VndMoney(overflowVal), throwsA(isA<VndOverflowException>()));
      expect(() => VndMoney.positive(overflowVal),
          throwsA(isA<VndOverflowException>()));
      expect(() => VndMoney.nonNegative(overflowVal),
          throwsA(isA<VndOverflowException>()));
    });

    test('Underflow by 1 (-9_000_000_000_000_001) throws VndOverflowException',
        () {
      const int underflowVal = -9000000000000001;
      expect(
          () => VndMoney(underflowVal), throwsA(isA<VndOverflowException>()));
    });

    test('Extreme 64-bit int boundaries throw VndOverflowException', () {
      const int int64Max = 9223372036854775807;
      const int int64Min = -9223372036854775808;

      expect(() => VndMoney(int64Max), throwsA(isA<VndOverflowException>()));
      expect(() => VndMoney(int64Min), throwsA(isA<VndOverflowException>()));
      expect(() => VndMoney.positive(int64Max),
          throwsA(isA<VndOverflowException>()));
      expect(() => VndMoney.nonNegative(int64Max),
          throwsA(isA<VndOverflowException>()));
    });

    test('Zero validation on restricted constructors', () {
      expect(() => VndMoney.positive(0), throwsArgumentError);
      expect(VndMoney.nonNegative(0).amount, 0);
      expect(VndMoney(0).amount, 0);
      expect(VndMoney.zero.amount, 0);
    });

    test('Negative validation on restricted constructors', () {
      expect(() => VndMoney.positive(-1), throwsArgumentError);
      expect(() => VndMoney.positive(-9000000000000000), throwsArgumentError);
      expect(() => VndMoney.nonNegative(-1), throwsArgumentError);
      expect(
          () => VndMoney.nonNegative(-9000000000000000), throwsArgumentError);
    });
  });

  group('Adversarial Stress Test: Arithmetic Edge Cases', () {
    test('Boundary Addition (+)', () {
      final max = VndMoney(VndMoney.maxSafeVnd);
      final min = VndMoney(VndMoney.minSafeVnd);

      // Identity with zero
      expect((max + VndMoney.zero).amount, VndMoney.maxSafeVnd);
      expect((min + VndMoney.zero).amount, VndMoney.minSafeVnd);

      // Max + Min == 0
      expect((max + min).amount, 0);
      expect(max + min, equals(VndMoney.zero));

      // 1 under max + 1 == max
      final oneUnder = VndMoney(VndMoney.maxSafeVnd - 1);
      expect((oneUnder + VndMoney(1)).amount, VndMoney.maxSafeVnd);

      // Max + 1 overflow
      expect(() => max + VndMoney(1), throwsA(isA<VndOverflowException>()));

      // Min + (-1) underflow
      expect(() => min + VndMoney(-1), throwsA(isA<VndOverflowException>()));

      // Max + Max overflow
      expect(() => max + max, throwsA(isA<VndOverflowException>()));

      // Min + Min underflow
      expect(() => min + min, throwsA(isA<VndOverflowException>()));
    });

    test('Boundary Subtraction (-)', () {
      final max = VndMoney(VndMoney.maxSafeVnd);
      final min = VndMoney(VndMoney.minSafeVnd);

      // Identity with zero
      expect((max - VndMoney.zero).amount, VndMoney.maxSafeVnd);
      expect((min - VndMoney.zero).amount, VndMoney.minSafeVnd);

      // Max - Max == 0
      expect((max - max).amount, 0);
      expect(max - max, equals(VndMoney.zero));

      // Min - Min == 0
      expect((min - min).amount, 0);
      expect(min - min, equals(VndMoney.zero));

      // 1 above min - 1 == min
      final oneAbove = VndMoney(VndMoney.minSafeVnd + 1);
      expect((oneAbove - VndMoney(1)).amount, VndMoney.minSafeVnd);

      // Min - 1 underflow
      expect(() => min - VndMoney(1), throwsA(isA<VndOverflowException>()));

      // Max - (-1) overflow
      expect(() => max - VndMoney(-1), throwsA(isA<VndOverflowException>()));

      // Max - Min overflow
      expect(() => max - min, throwsA(isA<VndOverflowException>()));

      // Min - Max underflow
      expect(() => min - max, throwsA(isA<VndOverflowException>()));
    });

    test('Unary negation and abs() at exact boundaries', () {
      final max = VndMoney(VndMoney.maxSafeVnd);
      final min = VndMoney(VndMoney.minSafeVnd);

      expect((-max).amount, VndMoney.minSafeVnd);
      expect((-min).amount, VndMoney.maxSafeVnd);
      expect((-VndMoney.zero).amount, 0);

      expect(max.abs().amount, VndMoney.maxSafeVnd);
      expect(min.abs().amount, VndMoney.maxSafeVnd);
      expect(VndMoney.zero.abs().amount, 0);
    });

    test('Boundary Multiplication (*)', () {
      final max = VndMoney(VndMoney.maxSafeVnd);
      final min = VndMoney(VndMoney.minSafeVnd);

      // Multiplication by zero yields zero without overflow
      expect((max * 0).amount, 0);
      expect((min * 0).amount, 0);

      // Multiplication by 1 preserves value
      expect((max * 1).amount, VndMoney.maxSafeVnd);
      expect((min * 1).amount, VndMoney.minSafeVnd);

      // Multiplication by -1 inverts value
      expect((max * -1).amount, VndMoney.minSafeVnd);
      expect((min * -1).amount, VndMoney.maxSafeVnd);

      // Factor splitting exact limit: 4.5 quadrillion * 2 == 9 quadrillion
      final halfMax = VndMoney(4500000000000000);
      expect((halfMax * 2).amount, VndMoney.maxSafeVnd);
      expect((halfMax * -2).amount, VndMoney.minSafeVnd);

      // Factor exceeding limit: (4.5 quadrillion + 1) * 2
      final halfMaxPlus1 = VndMoney(4500000000000001);
      expect(() => halfMaxPlus1 * 2, throwsA(isA<VndOverflowException>()));
      expect(() => halfMaxPlus1 * -2, throwsA(isA<VndOverflowException>()));

      // Negative half max: (-4.5 quadrillion - 1) * 2
      final halfMinMinus1 = VndMoney(-4500000000000001);
      expect(() => halfMinMinus1 * 2, throwsA(isA<VndOverflowException>()));
      expect(() => halfMinMinus1 * -2, throwsA(isA<VndOverflowException>()));

      // 1 * maxSafeVnd
      expect((VndMoney(1) * VndMoney.maxSafeVnd).amount, VndMoney.maxSafeVnd);
      expect((VndMoney(1) * VndMoney.minSafeVnd).amount, VndMoney.minSafeVnd);

      // 1 * (maxSafeVnd + 1)
      expect(() => VndMoney(1) * (VndMoney.maxSafeVnd + 1),
          throwsA(isA<VndOverflowException>()));

      // 1 * (minSafeVnd - 1)
      expect(() => VndMoney(1) * (VndMoney.minSafeVnd - 1),
          throwsA(isA<VndOverflowException>()));

      // Multiplication with extreme 64-bit scalars
      expect(() => VndMoney(2) * 9223372036854775807,
          throwsA(isA<VndOverflowException>()));
      expect(() => VndMoney(2) * -9223372036854775807,
          throwsA(isA<VndOverflowException>()));
      expect(() => VndMoney(1) * -0x8000000000000000,
          throwsA(isA<VndOverflowException>()));
    });

    test('Integer Division (~/) and Division by Zero', () {
      final max = VndMoney(VndMoney.maxSafeVnd);
      final min = VndMoney(VndMoney.minSafeVnd);

      // Division by 1
      expect((max ~/ 1).amount, VndMoney.maxSafeVnd);
      expect((min ~/ 1).amount, VndMoney.minSafeVnd);

      // Division by -1
      expect((max ~/ -1).amount, VndMoney.minSafeVnd);
      expect((min ~/ -1).amount, VndMoney.maxSafeVnd);

      // Truncation towards zero
      expect((VndMoney(10) ~/ 3).amount, 3);
      expect((VndMoney(-10) ~/ 3).amount, -3);
      expect((VndMoney(10) ~/ -3).amount, -3);
      expect((VndMoney(-10) ~/ -3).amount, 3);

      // Zero divided by non-zero
      expect((VndMoney.zero ~/ 100).amount, 0);

      // Division by zero throws ArgumentError
      expect(() => max ~/ 0, throwsArgumentError);
      expect(() => min ~/ 0, throwsArgumentError);
      expect(() => VndMoney.zero ~/ 0, throwsArgumentError);
    });

    test('Ceiling and Floor Integer Division simulation for savings goals', () {
      // Ceiling division formula: ((T - C) + N - 1) ~/ N
      int requiredPerPeriod(int target, int current, int periods) {
        if (current >= target) return 0;
        if (periods <= 0) return target - current;
        return ((target - current) + periods - 1) ~/ periods;
      }

      // Exact division: 30.000.000 / 3 periods = 10.000.000
      expect(requiredPerPeriod(30000000, 0, 3), 10000000);

      // Inexact division ceiling: 10.000.000 / 3 periods = 3.333.334
      // 3.333.334 * 3 = 10.000.002 >= 10.000.000 (ensures target is met!)
      expect(requiredPerPeriod(10000000, 0, 3), 3333334);

      // 1 VND over 3 periods: ((1) + 2) ~/ 3 = 1 VND per period
      expect(requiredPerPeriod(1, 0, 3), 1);

      // Already achieved
      expect(requiredPerPeriod(10000000, 10000000, 5), 0);
      expect(requiredPerPeriod(10000000, 12000000, 5), 0);

      // Overdue (periods = 0)
      expect(requiredPerPeriod(10000000, 4000000, 0), 6000000);
    });
  });

  group('Adversarial Stress Test: VndFormatter Formatting', () {
    test('Zero formatting with and without showSign', () {
      expect(VndFormatter.format(0), '0 ₫');
      expect(VndFormatter.format(0, showSign: false), '0 ₫');
      expect(VndFormatter.format(0, showSign: true), '0 ₫');
    });

    test('Single digit, double digit, triple digit formatting', () {
      expect(VndFormatter.format(1), '1 ₫');
      expect(VndFormatter.format(-1), '-1 ₫');
      expect(VndFormatter.format(1, showSign: true), '+1 ₫');
      expect(VndFormatter.format(-1, showSign: true), '-1 ₫');

      expect(VndFormatter.format(12), '12 ₫');
      expect(VndFormatter.format(-12), '-12 ₫');

      expect(VndFormatter.format(999), '999 ₫');
      expect(VndFormatter.format(-999), '-999 ₫');
    });

    test('Thousands grouping with dots across multiple orders of magnitude',
        () {
      expect(VndFormatter.format(1000), '1.000 ₫');
      expect(VndFormatter.format(10000), '10.000 ₫');
      expect(VndFormatter.format(100000), '100.000 ₫');
      expect(VndFormatter.format(1000000), '1.000.000 ₫');
      expect(VndFormatter.format(1250000), '1.250.000 ₫');
      expect(VndFormatter.format(-1250000), '-1.250.000 ₫');
      expect(VndFormatter.format(1250000, showSign: true), '+1.250.000 ₫');
    });

    test('Multi-trillion and quadrillion formatting', () {
      // 1 billion (1 tỷ)
      expect(VndFormatter.format(1000000000), '1.000.000.000 ₫');
      // 100 billion (100 tỷ)
      expect(VndFormatter.format(100000000000), '100.000.000.000 ₫');
      // 1 trillion (1.000 tỷ)
      expect(VndFormatter.format(1000000000000), '1.000.000.000.000 ₫');
      // 9 quadrillion (9 triệu tỷ) - maximum safe bound
      expect(VndFormatter.format(9000000000000000), '9.000.000.000.000.000 ₫');
      expect(
          VndFormatter.format(-9000000000000000), '-9.000.000.000.000.000 ₫');
      expect(VndFormatter.format(9000000000000000, showSign: true),
          '+9.000.000.000.000.000 ₫');
    });

    test('Tabular figures helper sets FontFeature.tabularFigures', () {
      const baseStyle = TextStyle(fontSize: 16);
      final tabularStyle = VndFormatter.withTabularFigures(baseStyle);
      expect(tabularStyle.fontFeatures,
          contains(const FontFeature.tabularFigures()));
    });
  });

  group('Adversarial Stress Test: VndFormatter Parsing', () {
    test('Standard currency inputs', () {
      expect(VndFormatter.tryParse('0 ₫'), 0);
      expect(VndFormatter.tryParse('0'), 0);
      expect(VndFormatter.tryParse('1 ₫'), 1);
      expect(VndFormatter.tryParse('1.250.000 ₫'), 1250000);
      expect(VndFormatter.tryParse('+1.250.000 ₫'), 1250000);
      expect(VndFormatter.tryParse('-1.250.000 ₫'), -1250000);
      expect(
          VndFormatter.tryParse('9.000.000.000.000.000 ₫'), 9000000000000000);
      expect(
          VndFormatter.tryParse('-9.000.000.000.000.000 ₫'), -9000000000000000);
    });

    test('Various thousand separators (dots, commas, spaces)', () {
      expect(VndFormatter.tryParse('1.250.000'), 1250000);
      expect(VndFormatter.tryParse('1,250,000'), 1250000);
      expect(VndFormatter.tryParse('1 250 000'), 1250000);
      expect(VndFormatter.tryParse('1\u00A0250\u00A0000'),
          1250000); // Non-breaking space
      expect(VndFormatter.tryParse('1250000'), 1250000);
    });

    test('Trailing currency notations (₫, VND, vnd)', () {
      expect(VndFormatter.tryParse('1.250.000 ₫'), 1250000);
      expect(VndFormatter.tryParse('1.250.000 VND'), 1250000);
      expect(VndFormatter.tryParse('1.250.000 vnd'), 1250000);
      expect(VndFormatter.tryParse('1.250.000₫'), 1250000);
      expect(VndFormatter.tryParse('1.250.000VND'), 1250000);
    });

    test('Leading and trailing whitespace, tabs, newlines', () {
      expect(VndFormatter.tryParse('   1.250.000 ₫   '), 1250000);
      expect(VndFormatter.tryParse('\t-500.000 ₫\n'), -500000);
      expect(VndFormatter.tryParse('+ 20.000.000 ₫'), 20000000);
      expect(VndFormatter.tryParse('- 500.000 ₫'), -500000);
    });

    test('Dirty or invalid input returns null', () {
      expect(VndFormatter.tryParse(''), isNull);
      expect(VndFormatter.tryParse('    '), isNull);
      expect(VndFormatter.tryParse('₫'), isNull);
      expect(VndFormatter.tryParse('VND'), isNull);
      expect(VndFormatter.tryParse('+'), isNull);
      expect(VndFormatter.tryParse('-'), isNull);
      expect(VndFormatter.tryParse('+ ₫'), isNull);
      expect(VndFormatter.tryParse('- ₫'), isNull);
      expect(VndFormatter.tryParse('abc'), isNull);
      expect(VndFormatter.tryParse('12a34'), isNull);
      expect(VndFormatter.tryParse('one million'), isNull);
    });

    test('Multiple consecutive signs should be rejected (BUG REPRODUCTION)',
        () {
      expect(
        VndFormatter.tryParse('--1000'),
        isNull,
        reason: 'BUG: Double minus "--1000" parsed as positive 1000',
      );
      expect(
        VndFormatter.tryParse('++1000'),
        isNull,
        reason: 'BUG: Double plus "++1000" parsed as positive 1000',
      );
      expect(
        VndFormatter.tryParse('+-1000'),
        isNull,
        reason: 'BUG: Plus-minus "+-1000" parsed as negative -1000',
      );
      expect(
        VndFormatter.tryParse('-+1000'),
        isNull,
        reason: 'BUG: Minus-plus "-+1000" parsed as negative -1000',
      );
      expect(
        VndFormatter.tryParse('- - 1000'),
        isNull,
        reason: 'BUG: Spaced double minus "- - 1000" parsed as positive 1000',
      );
    });

    test('Adversarial stress: Embedded, trailing, and multi-sign variants', () {
      final invalidSignStrings = [
        '---1000',
        '+++1000',
        '+-+1000',
        '-+-1000',
        '+ + 1000',
        '- + 1000',
        '+ - 1000',
        '- - - 1000',
        '-    +    1000',
        ' - - 1000 ₫ ',
        ' + - 1000 ₫ ',
        '1000-',
        '1000+',
        '1000- ₫',
        '1000+ ₫',
        '1.000 ₫ -',
        '1.000 ₫ +',
        '12-34',
        '12+34',
        '1.250-000',
        '1.250+000',
        '-1.000-000',
        '+1.000+000',
        '-1.000+000',
        '+1.000-000',
        '+1000-',
        '-1000+',
        '+1000+',
        '-1000-',
        '-₫',
        '+₫',
        '₫-',
        '₫+',
        '-VND',
        '+VND',
        'VND-',
        'VND+',
        '-1000-₫',
        '+1000+₫',
        '++0',
        '--0',
        '+-0',
        '-+0',
      ];

      for (final input in invalidSignStrings) {
        expect(
          VndFormatter.tryParse(input),
          isNull,
          reason: 'Expected tryParse("$input") to be null',
        );
        expect(
          () => VndFormatter.parse(input),
          throwsFormatException,
          reason: 'Expected parse("$input") to throw FormatException',
        );
      }
    });

    test('Amounts strictly exceeding maxSafeVnd return null from tryParse', () {
      expect(VndFormatter.tryParse('9.000.000.000.000.001 ₫'), isNull);
      expect(VndFormatter.tryParse('-9.000.000.000.000.001 ₫'), isNull);
      expect(VndFormatter.tryParse('999999999999999999999999999999'), isNull);
      expect(VndFormatter.tryParse('-999999999999999999999999999999'), isNull);
    });

    test('parse() throws FormatException on invalid non-numeric input', () {
      expect(() => VndFormatter.parse('invalid'), throwsFormatException);
      expect(() => VndFormatter.parse(''), throwsFormatException);
      expect(() => VndFormatter.parse('   '), throwsFormatException);
      expect(() => VndFormatter.parse('+'), throwsFormatException);
      expect(() => VndFormatter.parse('-'), throwsFormatException);
      expect(() => VndFormatter.parse('++'), throwsFormatException);
      expect(() => VndFormatter.parse('--'), throwsFormatException);
      expect(() => VndFormatter.parse('+-'), throwsFormatException);
      expect(() => VndFormatter.parse('-+'), throwsFormatException);
      expect(() => VndFormatter.parse('+ ₫'), throwsFormatException);
      expect(() => VndFormatter.parse('- ₫'), throwsFormatException);
      expect(() => VndFormatter.parse('₫'), throwsFormatException);
      expect(() => VndFormatter.parse('VND'), throwsFormatException);
    });

    test(
        'parse() throws VndOverflowException on overflow per docstring (BUG REPRODUCTION)',
        () {
      expect(
        () => VndFormatter.parse('9.000.000.000.000.001 ₫'),
        throwsA(isA<VndOverflowException>()),
        reason:
            'Docstring specifies throwing VndOverflowException on overflow, but currently throws FormatException',
      );
    });

    test('parse() throws VndOverflowException across all overflow spectra', () {
      final overflowInputs = [
        '9.000.000.000.000.001 ₫',
        '+9.000.000.000.000.001 ₫',
        '-9.000.000.000.000.001 ₫',
        '9000000000000001',
        '+9000000000000001',
        '-9000000000000001',
        '9223372036854775807 ₫',
        '+9223372036854775807 ₫',
        '-9223372036854775808 ₫',
        '-9223372036854775808',
        '9223372036854775808',
        '+9223372036854775808',
        '-9223372036854775809',
        '100000000000000000000',
        '-100000000000000000000',
        '+999999999999999999999999999999 ₫',
        '-999999999999999999999999999999 ₫',
        '0009000000000000001 ₫',
        '-0009000000000000001 ₫',
      ];

      for (final input in overflowInputs) {
        expect(
          VndFormatter.tryParse(input),
          isNull,
          reason: 'Expected tryParse("$input") to return null',
        );
        expect(
          () => VndFormatter.parse(input),
          throwsA(isA<VndOverflowException>()),
          reason: 'Expected parse("$input") to throw VndOverflowException',
        );
      }
    });

    test('parse() distinguishes FormatException vs VndOverflowException', () {
      // Malformed strings that also contain large numbers MUST throw FormatException, not VndOverflowException
      final malformedLargeStrings = [
        '--9000000000000001',
        '++9000000000000001',
        '+-9000000000000001',
        '9000000000000001-₫',
        '9000000000000001-2',
        'abc9000000000000001',
        '9000000000000001xyz',
      ];

      for (final input in malformedLargeStrings) {
        expect(
          VndFormatter.tryParse(input),
          isNull,
          reason: 'Expected tryParse("$input") to return null',
        );
        expect(
          () => VndFormatter.parse(input),
          throwsFormatException,
          reason:
              'Expected parse("$input") to throw FormatException due to malformed syntax',
        );
      }
    });

    test('Valid boundary amounts parse correctly without throwing', () {
      expect(VndFormatter.parse('9.000.000.000.000.000 ₫'), 9000000000000000);
      expect(VndFormatter.parse('+9.000.000.000.000.000 ₫'), 9000000000000000);
      expect(VndFormatter.parse('-9.000.000.000.000.000 ₫'), -9000000000000000);
      expect(VndFormatter.parse('9000000000000000'), 9000000000000000);
      expect(VndFormatter.parse('-9000000000000000'), -9000000000000000);
    });

    test('Zero variations and leading zeros parse correctly', () {
      expect(VndFormatter.parse('0 ₫'), 0);
      expect(VndFormatter.parse('+0 ₫'), 0);
      expect(VndFormatter.parse('-0 ₫'), 0);
      expect(VndFormatter.parse('+0'), 0);
      expect(VndFormatter.parse('-0'), 0);
      expect(VndFormatter.parse('00000 ₫'), 0);
      expect(VndFormatter.parse('+00000 ₫'), 0);
      expect(VndFormatter.parse('-00000 ₫'), 0);
      expect(VndFormatter.parse('00001000 ₫'), 1000);
      expect(VndFormatter.parse('+00001000 ₫'), 1000);
      expect(VndFormatter.parse('-00001000 ₫'), -1000);
    });

    test('tryParseMoney returns VndMoney instance or null', () {
      final valid = VndFormatter.tryParseMoney('1.500.000 ₫');
      expect(valid, isNotNull);
      expect(valid!.amount, 1500000);

      expect(VndFormatter.tryParseMoney('invalid'), isNull);
      expect(VndFormatter.tryParseMoney('9.000.000.000.000.001 ₫'), isNull);
    });
  });
}
