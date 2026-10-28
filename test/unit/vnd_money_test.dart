import 'package:flutter_test/flutter_test.dart';
import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/core/money/vnd_formatter.dart';

void main() {
  group('VndMoney Value Object', () {
    test('Constructs valid VND amounts within safe bounds', () {
      final zero = VndMoney(0);
      expect(zero.amount, 0);
      expect(zero.isZero, isTrue);
      expect(zero.isPositive, isFalse);
      expect(zero.isNegative, isFalse);

      final tenMillion = VndMoney(10000000);
      expect(tenMillion.amount, 10000000);
      expect(tenMillion.isPositive, isTrue);

      final deficit = VndMoney(-500000);
      expect(deficit.amount, -500000);
      expect(deficit.isNegative, isTrue);
    });

    test('Canonical zero constant is identical and equals VndMoney(0)', () {
      expect(VndMoney.zero.amount, 0);
      expect(VndMoney(0), equals(VndMoney.zero));
    });

    test('positive factory enforces amount > 0', () {
      expect(VndMoney.positive(1).amount, 1);
      expect(() => VndMoney.positive(0), throwsArgumentError);
      expect(() => VndMoney.positive(-100), throwsArgumentError);
    });

    test('nonNegative factory enforces amount >= 0', () {
      expect(VndMoney.nonNegative(0).amount, 0);
      expect(VndMoney.nonNegative(50000).amount, 50000);
      expect(() => VndMoney.nonNegative(-1), throwsArgumentError);
    });

    group('64-Bit Overflow Guard (maxSafeVnd = 9_000_000_000_000_000)', () {
      test('Allows boundary values ±9 quadrillion VND', () {
        final maxVnd = VndMoney(VndMoney.maxSafeVnd);
        expect(maxVnd.amount, 9000000000000000);

        final minVnd = VndMoney(VndMoney.minSafeVnd);
        expect(minVnd.amount, -9000000000000000);
      });

      test('Rejects values exceeding maxSafeVnd', () {
        expect(
          () => VndMoney(VndMoney.maxSafeVnd + 1),
          throwsA(isA<VndOverflowException>()),
        );
        expect(
          () => VndMoney(VndMoney.minSafeVnd - 1),
          throwsA(isA<VndOverflowException>()),
        );
        expect(
          () => VndMoney.positive(VndMoney.maxSafeVnd + 1),
          throwsA(isA<VndOverflowException>()),
        );
        expect(
          () => VndMoney.nonNegative(VndMoney.maxSafeVnd + 1),
          throwsA(isA<VndOverflowException>()),
        );
      });
    });

    group('Arithmetic Operations', () {
      test('Addition (+) adds amounts correctly', () {
        final a = VndMoney(10000000);
        final b = VndMoney(20000000);
        final result = a + b;
        expect(result.amount, 30000000);
      });

      test('Addition with negative amount (net deficit)', () {
        final a = VndMoney(10000000);
        final b = VndMoney(-3000000);
        expect((a + b).amount, 7000000);
      });

      test('Addition throws VndOverflowException on boundary overflow', () {
        final max = VndMoney(VndMoney.maxSafeVnd);
        expect(() => max + VndMoney(1), throwsA(isA<VndOverflowException>()));

        final min = VndMoney(VndMoney.minSafeVnd);
        expect(() => min + VndMoney(-1), throwsA(isA<VndOverflowException>()));
      });

      test('Subtraction (-) subtracts amounts correctly', () {
        final a = VndMoney(29900000);
        final b = VndMoney(100000);
        expect((a - b).amount, 29800000);
      });

      test('Subtraction yielding negative shortfall', () {
        final a = VndMoney(500000);
        final b = VndMoney(1500000);
        final result = a - b;
        expect(result.amount, -1000000);
        expect(result.isNegative, isTrue);
      });

      test('Subtraction throws VndOverflowException on underflow', () {
        final min = VndMoney(VndMoney.minSafeVnd);
        expect(() => min - VndMoney(1), throwsA(isA<VndOverflowException>()));
      });

      test('Unary negation (-)', () {
        expect((-VndMoney(500000)).amount, -500000);
        expect((-VndMoney(-500000)).amount, 500000);
        expect((-VndMoney(0)).amount, 0);
      });

      test('Multiplication (*) scales amounts correctly', () {
        final a = VndMoney(2500000);
        expect((a * 3).amount, 7500000);
        expect((a * 0).amount, 0);
        expect((a * -1).amount, -2500000);
      });

      test(
          'Multiplication throws VndOverflowException when exceeding safe threshold',
          () {
        final huge = VndMoney(5000000000000000);
        expect(() => huge * 2, throwsA(isA<VndOverflowException>()));
      });

      test('Integer division (~/) truncates division correctly', () {
        final total = VndMoney(10000000);
        expect((total ~/ 3).amount, 3333333);
      });

      test('Integer division by zero throws ArgumentError', () {
        expect(() => VndMoney(10000000) ~/ 0, throwsArgumentError);
      });

      test('abs() returns absolute magnitude', () {
        expect(VndMoney(-500000).abs().amount, 500000);
        expect(VndMoney(500000).abs().amount, 500000);
        expect(VndMoney(0).abs().amount, 0);
      });
    });

    group('Comparison, Equality & Set Hashing', () {
      test('Relational operators (<, <=, >, >=)', () {
        final a = VndMoney(100000);
        final b = VndMoney(200000);
        final c = VndMoney(100000);

        expect(a < b, isTrue);
        expect(a <= b, isTrue);
        expect(a <= c, isTrue);
        expect(b > a, isTrue);
        expect(b >= a, isTrue);
        expect(a >= c, isTrue);
      });

      test('Equality and hashCode consistency', () {
        final m1 = VndMoney(500000);
        final m2 = VndMoney(500000);
        final m3 = VndMoney(600000);

        expect(m1, equals(m2));
        expect(m1.hashCode, equals(m2.hashCode));
        expect(m1, isNot(equals(m3)));

        final set = {m1, m2, m3};
        expect(set.length, 2);
      });

      test('Comparable interface sorts ascending', () {
        final list = [
          VndMoney(300),
          VndMoney(100),
          VndMoney(-50),
          VndMoney(200)
        ];
        list.sort();
        expect(list.map((m) => m.amount).toList(), [-50, 100, 200, 300]);
      });
    });
  });

  group('VndFormatter (vi_VN Locale Specification)', () {
    test('Formats zero as 0 ₫', () {
      expect(VndFormatter.format(0), '0 ₫');
      expect(VndFormatter.format(0, showSign: true), '0 ₫');
    });

    test('Formats positive amounts with dot grouping and ₫ suffix', () {
      expect(VndFormatter.format(100), '100 ₫');
      expect(VndFormatter.format(1000), '1.000 ₫');
      expect(VndFormatter.format(1250000), '1.250.000 ₫');
      expect(VndFormatter.format(10000000), '10.000.000 ₫');
      expect(VndFormatter.format(29900000), '29.900.000 ₫');
      expect(VndFormatter.format(9000000000000000), '9.000.000.000.000.000 ₫');
    });

    test('Formats negative amounts with minus sign', () {
      expect(VndFormatter.format(-500000), '-500.000 ₫');
      expect(VndFormatter.format(-1250000), '-1.250.000 ₫');
      expect(
          VndFormatter.format(-9000000000000000), '-9.000.000.000.000.000 ₫');
    });

    test(
        'Formats with showSign: true displays explicit plus sign on positive numbers',
        () {
      expect(VndFormatter.format(1250000, showSign: true), '+1.250.000 ₫');
      expect(VndFormatter.format(-500000, showSign: true), '-500.000 ₫');
      expect(VndFormatter.format(0, showSign: true), '0 ₫');
    });

    test('VndMoney.formatVnd() delegates to VndFormatter', () {
      final money = VndMoney(1250000);
      expect(money.formatVnd(), '1.250.000 ₫');
      expect(money.formatVnd(showSign: true), '+1.250.000 ₫');
      expect(money.toString(), '1.250.000 ₫');
    });

    group('Parsing Currency Strings', () {
      test('Parses formatted strings with dots, spaces, and currency symbols',
          () {
        expect(VndFormatter.parse('1.250.000 ₫'), 1250000);
        expect(VndFormatter.parse('1.250.000'), 1250000);
        expect(VndFormatter.parse('1250000'), 1250000);
        expect(VndFormatter.parse('0 ₫'), 0);
        expect(VndFormatter.parse('-500.000 ₫'), -500000);
        expect(VndFormatter.parse('+20.000.000 ₫'), 20000000);
      });

      test('tryParse returns null on invalid strings', () {
        expect(VndFormatter.tryParse('abc'), isNull);
        expect(VndFormatter.tryParse(''), isNull);
        expect(VndFormatter.tryParse('   '), isNull);
      });

      test('tryParse returns null if amount exceeds maxSafeVnd', () {
        expect(VndFormatter.tryParse('9.000.000.000.000.001 ₫'), isNull);
        expect(VndFormatter.tryParse('-9.000.000.000.000.001 ₫'), isNull);
      });

      test('tryParse returns null on consecutive or malformed signs', () {
        expect(VndFormatter.tryParse('--1000'), isNull);
        expect(VndFormatter.tryParse('++1000'), isNull);
        expect(VndFormatter.tryParse('+-1000'), isNull);
        expect(VndFormatter.tryParse('-+1000'), isNull);
        expect(VndFormatter.tryParse('- - 1000'), isNull);
      });

      test('parse throws VndOverflowException on amounts exceeding safe bounds',
          () {
        expect(
          () => VndFormatter.parse('9.000.000.000.000.001 ₫'),
          throwsA(isA<VndOverflowException>()),
        );
        expect(
          () => VndFormatter.parse('-9.000.000.000.000.001 ₫'),
          throwsA(isA<VndOverflowException>()),
        );
      });

      test('parse throws FormatException on invalid input or multiple signs',
          () {
        expect(() => VndFormatter.parse('abc'), throwsFormatException);
        expect(() => VndFormatter.parse('--1000'), throwsFormatException);
        expect(() => VndFormatter.parse(''), throwsFormatException);
      });

      test('tryParseMoney creates VndMoney instance on valid input', () {
        final parsed = VndFormatter.tryParseMoney('2.500.000 ₫');
        expect(parsed, isNotNull);
        expect(parsed!.amount, 2500000);
      });
    });
  });
}
