import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/feasibility_advisor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeasibilityAdvisor — Multi-Goal Priority & Remediation Calculators',
      () {
    test(
        'evaluatePlan distinguishes feasible vs infeasible plans and computes exact deficit',
        () {
      final goal1 = ActiveGoalItem(
        id: 1,
        name: 'Mua laptop',
        targetAmount: VndMoney(20000000),
        currentReserved: VndMoney(10000000),
        remainingPeriods: 5, // Shortfall 10M / 5 = 2M/month
      );

      final goal2 = ActiveGoalItem(
        id: 2,
        name: 'Du lịch',
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 10, // Shortfall 10M / 10 = 1M/month
      );

      // Total required = 2M + 1M = 3M/month
      final feasible = FeasibilityAdvisor.evaluatePlan(
        goals: [goal1, goal2],
        monthlyCapacity: VndMoney(3500000),
      );
      expect(feasible.isFeasible, isTrue);
      expect(feasible.totalRequiredPerPeriod, equals(VndMoney(3000000)));
      expect(feasible.deficit, equals(VndMoney.zero));

      final infeasible = FeasibilityAdvisor.evaluatePlan(
        goals: [goal1, goal2],
        monthlyCapacity: VndMoney(2000000), // Capacity only 2M (Deficit = 1M)
      );
      expect(infeasible.isInfeasible, isTrue);
      expect(infeasible.totalRequiredPerPeriod, equals(VndMoney(3000000)));
      expect(infeasible.deficit, equals(VndMoney(1000000)));
    });

    test('1. One-tap Extend Deadline calculates ceil((T - C) / capacity)', () {
      // Shortfall = 10.000.000 ₫, capacity = 3.000.000 ₫
      // 10M / 3M = 3.333 -> ceil = 4 periods
      final extended = FeasibilityAdvisor.calculateExtendedDeadline(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        allocatedMonthlyCapacity: VndMoney(3000000),
      );
      expect(extended, equals(4));

      // Exact multiple: Shortfall = 9M, capacity = 3M -> 3 periods
      final exact = FeasibilityAdvisor.calculateExtendedDeadline(
        targetAmount: VndMoney(9000000),
        currentReserved: VndMoney.zero,
        allocatedMonthlyCapacity: VndMoney(3000000),
      );
      expect(exact, equals(3));

      // Already achieved -> 0 periods
      final achieved = FeasibilityAdvisor.calculateExtendedDeadline(
        targetAmount: VndMoney(5000000),
        currentReserved: VndMoney(5000000),
        allocatedMonthlyCapacity: VndMoney(1000000),
      );
      expect(achieved, equals(0));

      // Zero capacity throws ArgumentError
      expect(
        () => FeasibilityAdvisor.calculateExtendedDeadline(
          targetAmount: VndMoney(5000000),
          currentReserved: VndMoney.zero,
          allocatedMonthlyCapacity: VndMoney.zero,
        ),
        throwsArgumentError,
      );
    });

    test(
        '2. One-tap Lower Target calculates T\' = C + N * capacity clamped appropriately',
        () {
      // Current: 2M, N = 6, capacity = 500k -> 2M + 6 * 500k = 5M
      final lowered = FeasibilityAdvisor.calculateLoweredTarget(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(2000000),
        remainingPeriods: 6,
        allocatedMonthlyCapacity: VndMoney(500000),
      );
      expect(lowered, equals(VndMoney(5000000)));

      // Never inflate above original target
      final clampedAbove = FeasibilityAdvisor.calculateLoweredTarget(
        targetAmount: VndMoney(4000000),
        currentReserved: VndMoney(2000000),
        remainingPeriods: 10,
        allocatedMonthlyCapacity: VndMoney(1000000),
      );
      expect(clampedAbove, equals(VndMoney(4000000)));

      // Never deflate below current reserved
      final clampedBelow = FeasibilityAdvisor.calculateLoweredTarget(
        targetAmount: VndMoney(5000000),
        currentReserved: VndMoney(3000000),
        remainingPeriods: 0,
        allocatedMonthlyCapacity: VndMoney(500000),
      );
      expect(clampedBelow, equals(VndMoney(3000000)));
    });

    test('3. One-tap Pause Goals ranks by priority and recommends pruning', () {
      final emergency = ActiveGoalItem(
        id: 1,
        name: 'Quỹ khẩn cấp',
        targetAmount: VndMoney(6000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 6, // 1M/month
        priority: 1, // Highest
      );

      final car = ActiveGoalItem(
        id: 2,
        name: 'Đổi xe',
        targetAmount: VndMoney(15000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 10, // 1.5M/month
        priority: 2, // Second
      );

      final vacation = ActiveGoalItem(
        id: 3,
        name: 'Nghỉ dưỡng',
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 10, // 1M/month
        priority: 3, // Third
      );

      // Monthly capacity = 2.000.000 ₫
      final actions = FeasibilityAdvisor.recommendGoalPruning(
        goals: [vacation, car, emergency],
        monthlyCapacity: VndMoney(2000000),
      );

      // Total goals: 3
      expect(actions.length, equals(3));

      // 1. Emergency (Priority 1): Needs 1M -> Fully funded (1M allocated, shouldPause = false)
      expect(actions[0].goal.id, equals(1));
      expect(actions[0].shouldPause, isFalse);
      expect(actions[0].allocatedMonthly, equals(VndMoney(1000000)));
      expect(actions[0].unmetShortfall, equals(VndMoney.zero));

      // 2. Car (Priority 2): Needs 1.5M, remaining capacity 1M -> Partial (shouldPause = true, unmet = 500k)
      expect(actions[1].goal.id, equals(2));
      expect(actions[1].shouldPause, isTrue);
      expect(actions[1].allocatedMonthly, equals(VndMoney(1000000)));
      expect(actions[1].unmetShortfall, equals(VndMoney(500000)));

      // 3. Vacation (Priority 3): Needs 1M, remaining capacity 0 -> Full Pause (shouldPause = true, unmet = 1M)
      expect(actions[2].goal.id, equals(3));
      expect(actions[2].shouldPause, isTrue);
      expect(actions[2].allocatedMonthly, equals(VndMoney.zero));
      expect(actions[2].unmetShortfall, equals(VndMoney(1000000)));
    });
  });
}
