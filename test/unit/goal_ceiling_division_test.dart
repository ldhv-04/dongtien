import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/goal_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalCalculator — Ceiling Integer Division & Overdue Invariants', () {
    test(
        'Ceiling division guarantees target attainment without 1 VND shortfall',
        () {
      // Target: 10.000.000 ₫, Current: 0 ₫, Remaining: 3 months
      // Standard integer division: 10.000.000 ~/ 3 = 3.333.333 (x3 = 9.999.999 -> 1 ₫ short!)
      // Ceiling integer division: ((10.000.000 - 0) + 3 - 1) ~/ 3 = 3.333.334 (x3 = 10.000.002 >= 10M)
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 3,
      );

      expect(result.status, equals(GoalStatus.inProgress));
      expect(result.shortfall, equals(VndMoney(10000000)));
      expect(result.requiredPerPeriod, equals(VndMoney(3333334)));
      expect(result.requiredPerPeriod * 3 >= result.targetAmount, isTrue);
    });

    test('Exact division produces clean required amount', () {
      final result = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(5000000),
        currentReserved: VndMoney(2000000),
        remainingPeriods: 6,
      );

      // Shortfall = 3.000.000 ₫. Required = 3M ~/ 6 = 500.000 ₫/month.
      expect(result.status, equals(GoalStatus.inProgress));
      expect(result.shortfall, equals(VndMoney(3000000)));
      expect(result.requiredPerPeriod, equals(VndMoney(500000)));
    });

    test('Achieved status when currentReserved >= targetAmount', () {
      final exact = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(5000000),
        currentReserved: VndMoney(5000000),
        remainingPeriods: 4,
      );
      expect(exact.status, equals(GoalStatus.achieved));
      expect(exact.isAchieved, isTrue);
      expect(exact.requiredPerPeriod, equals(VndMoney.zero));
      expect(exact.shortfall, equals(VndMoney.zero));
      expect(exact.progressRatio, equals(1.0));

      final surplus = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(5000000),
        currentReserved: VndMoney(6000000),
        remainingPeriods: 2,
      );
      expect(surplus.status, equals(GoalStatus.achieved));
      expect(surplus.requiredPerPeriod, equals(VndMoney.zero));
      expect(surplus.shortfall, equals(VndMoney.zero));
      expect(surplus.progressRatio, equals(1.2));
    });

    test('Overdue status when remainingPeriods <= 0 and target not yet reached',
        () {
      // 0 remaining periods (deadline is now)
      final zeroPeriods = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(5000000),
        currentReserved: VndMoney(3000000),
        remainingPeriods: 0,
      );
      expect(zeroPeriods.status, equals(GoalStatus.overdue));
      expect(zeroPeriods.isOverdue, isTrue);
      expect(zeroPeriods.shortfall, equals(VndMoney(2000000)));
      expect(zeroPeriods.requiredPerPeriod, equals(VndMoney(2000000)));

      // Negative remaining periods (deadline has passed)
      final pastDeadline = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(5000000),
        currentReserved: VndMoney(1000000),
        remainingPeriods: -3,
      );
      expect(pastDeadline.status, equals(GoalStatus.overdue));
      expect(pastDeadline.shortfall, equals(VndMoney(4000000)));
      expect(pastDeadline.requiredPerPeriod, equals(VndMoney(4000000)));
    });

    test('Negative values in input parameters throw ArgumentError', () {
      expect(
        () => GoalCalculator.evaluateGoal(
          targetAmount: VndMoney(-1000),
          currentReserved: VndMoney.zero,
          remainingPeriods: 5,
        ),
        throwsArgumentError,
      );

      expect(
        () => GoalCalculator.evaluateGoal(
          targetAmount: VndMoney(5000000),
          currentReserved: VndMoney(-500),
          remainingPeriods: 5,
        ),
        throwsArgumentError,
      );
    });

    test(
        'calculateRemainingMonths computes calendar month difference accurately',
        () {
      final now = DateTime(2026, 10, 1);
      final targetSameMonth = DateTime(2026, 10, 25);
      expect(GoalCalculator.calculateRemainingMonths(now, targetSameMonth),
          equals(1));

      final targetDec = DateTime(2026, 12, 1);
      expect(
          GoalCalculator.calculateRemainingMonths(now, targetDec), equals(2));

      final targetNextYear = DateTime(2027, 4, 1);
      expect(GoalCalculator.calculateRemainingMonths(now, targetNextYear),
          equals(6));

      final targetPast = DateTime(2026, 8, 1);
      expect(GoalCalculator.calculateRemainingMonths(now, targetPast),
          lessThanOrEqualTo(0));
    });
  });
}
