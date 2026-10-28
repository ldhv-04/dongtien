import 'dart:math';

import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/budgeting/category_spending_calculator.dart';
import 'package:dongtien/domain/budgeting/feasibility_advisor.dart';
import 'package:dongtien/domain/budgeting/goal_calculator.dart';
import 'package:dongtien/domain/forecasting/cash_flow_forecaster.dart';
import 'package:dongtien/domain/forecasting/recurrence_calculator.dart';
import 'package:dongtien/domain/forecasting/safe_to_spend_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ADVERSARIAL STRESS TEST 1: Safe-to-Spend Zero Double-Counting', () {
    test('Complex multi-envelope and multi-bill interleaved timeline', () {
      final now = DateTime(2026, 10, 1, 8, 0);
      final horizon = DateTime(2026, 10, 31, 23, 59);

      // 4 envelopes: 3 PROTECTED, 1 FLEXIBLE
      final env1 = EnvelopeSnapshot(
        id: 1,
        name: 'Tiền thuê nhà',
        policy: EnvelopePolicyType.protected,
        reservedBalance: VndMoney(8000000), // 8M
      );
      final env2 = EnvelopeSnapshot(
        id: 2,
        name: 'Hoá đơn điện nước internet',
        policy: EnvelopePolicyType.protected,
        reservedBalance: VndMoney(3000000), // 3M
      );
      final env3 = EnvelopeSnapshot(
        id: 3,
        name: 'Bảo hiểm & Y tế',
        policy: EnvelopePolicyType.protected,
        reservedBalance: VndMoney(5000000), // 5M
      );
      final env4 = EnvelopeSnapshot(
        id: 4,
        name: 'Quỹ du lịch (Linh hoạt)',
        policy: EnvelopePolicyType.flexible,
        reservedBalance: VndMoney(10000000), // 10M (Discretionary)
      );

      // Bills interleaved chronologically:
      final bills = [
        // Oct 2: Bill for Env 2 (1.2M) -> fully covered by 3M, rem 1.8M
        PendingBillItem(
          id: 101,
          title: 'Tiền nước',
          amount: VndMoney(1200000),
          dueDate: DateTime(2026, 10, 2),
          linkedEnvelopeId: 2,
        ),
        // Oct 5: Bill for Env 1 (5M) -> fully covered by 8M, rem 3M
        PendingBillItem(
          id: 102,
          title: 'Tiền nhà đợt 1',
          amount: VndMoney(5000000),
          dueDate: DateTime(2026, 10, 5),
          linkedEnvelopeId: 1,
        ),
        // Oct 8: Unlinked bill Case A (800k) -> 100% unfunded
        PendingBillItem(
          id: 103,
          title: 'Tiền rác & dịch vụ chung cư',
          amount: VndMoney(800000),
          dueDate: DateTime(2026, 10, 8),
          linkedEnvelopeId: null,
        ),
        // Oct 12: Bill for Env 2 (2M) -> partially covered by 1.8M, 200k unfunded, rem 0
        PendingBillItem(
          id: 104,
          title: 'Tiền điện',
          amount: VndMoney(2000000),
          dueDate: DateTime(2026, 10, 12),
          linkedEnvelopeId: 2,
        ),
        // Oct 15: Bill for Flexible Env 4 Case C (3M) -> 100% unfunded
        PendingBillItem(
          id: 105,
          title: 'Vé máy bay du lịch',
          amount: VndMoney(3000000),
          dueDate: DateTime(2026, 10, 15),
          linkedEnvelopeId: 4,
        ),
        // Oct 18: Bill for Env 3 (6M) -> partially covered by 5M, 1M unfunded, rem 0
        PendingBillItem(
          id: 106,
          title: 'Bảo hiểm nhân thọ',
          amount: VndMoney(6000000),
          dueDate: DateTime(2026, 10, 18),
          linkedEnvelopeId: 3,
        ),
        // Oct 22: Second bill for Env 1 (4M) -> partially covered by remaining 3M, 1M unfunded, rem 0
        PendingBillItem(
          id: 107,
          title: 'Tiền nhà đợt 2',
          amount: VndMoney(4000000),
          dueDate: DateTime(2026, 10, 22),
          linkedEnvelopeId: 1,
        ),
        // Oct 28: Third bill for Env 2 (500k) -> 0 covered because rem is 0, 500k unfunded
        PendingBillItem(
          id: 108,
          title: 'Tiền internet',
          amount: VndMoney(500000),
          dueDate: DateTime(2026, 10, 28),
          linkedEnvelopeId: 2,
        ),
        // Nov 3: Beyond horizon date (ends Oct 31) -> MUST NOT BE INCLUDED!
        PendingBillItem(
          id: 109,
          title: 'Tiền điện tháng 11',
          amount: VndMoney(2500000),
          dueDate: DateTime(2026, 11, 3),
          linkedEnvelopeId: 2,
        ),
      ];

      final liquidAssets = VndMoney(40000000); // 40M
      final minBuffer = VndMoney(5000000); // 5M

      final result = SafeToSpendCalculator.calculate(
        liquidAssets: liquidAssets,
        envelopes: [env1, env2, env3, env4],
        pendingBills: bills,
        minimumCashBuffer: minBuffer,
        now: now,
        horizonDate: horizon,
      );

      // Protected reserves: 8M + 3M + 5M = 16M (Env 4 is flexible, not included)
      expect(result.breakdown.protectedReserves, equals(VndMoney(16000000)));

      // Expected Unfunded Outflows:
      // Bill 101: 0 unfunded (1.2M covered)
      // Bill 102: 0 unfunded (5M covered)
      // Bill 103: 800k unfunded (unlinked)
      // Bill 104: 200k unfunded (1.8M covered)
      // Bill 105: 3M unfunded (flexible env)
      // Bill 106: 1M unfunded (5M covered)
      // Bill 107: 1M unfunded (3M covered)
      // Bill 108: 500k unfunded (0 covered)
      // Bill 109: Excluded!
      // Total unfunded = 0 + 0 + 800k + 200k + 3M + 1M + 1M + 500k = 6.500.000 ₫
      expect(result.breakdown.unfundedCommittedOutflows,
          equals(VndMoney(6500000)));

      // Total deductions = Protected Reserves (16M) + Unfunded (6.5M) + Buffer (5M) = 27.500.000 ₫
      // Safe to spend = 40M - 27.5M = 12.500.000 ₫
      expect(result.safeToSpend, equals(VndMoney(12500000)));
      expect(result.isDeficit, isFalse);

      // Verify that bill 109 is completely excluded
      expect(result.breakdown.billAllocations.length, equals(8));
      expect(result.breakdown.billAllocations.any((b) => b.billId == 109),
          isFalse);

      // Verify remaining envelope balances in coverage breakdown:
      final cov1 = result.breakdown.envelopeCoverages
          .firstWhere((c) => c.envelopeId == 1);
      final cov2 = result.breakdown.envelopeCoverages
          .firstWhere((c) => c.envelopeId == 2);
      final cov3 = result.breakdown.envelopeCoverages
          .firstWhere((c) => c.envelopeId == 3);

      expect(cov1.allocatedToBills, equals(VndMoney(8000000)));
      expect(cov1.remainingProtectedReserve, equals(VndMoney.zero));

      expect(cov2.allocatedToBills, equals(VndMoney(3000000)));
      expect(cov2.remainingProtectedReserve, equals(VndMoney.zero));

      expect(cov3.allocatedToBills, equals(VndMoney(5000000)));
      expect(cov3.remainingProtectedReserve, equals(VndMoney.zero));
    });

    test(
        'Zero double-counting invariant holds: sum(covered) + sum(unfunded) == sum(all eligible bills)',
        () {
      // Property verification: For any combination of bills and envelopes,
      // the total sum of covered + unfunded must strictly match the total amount of eligible bills.
      final rand = Random(42);
      for (int trial = 0; trial < 20; trial++) {
        final envCount = rand.nextInt(5) + 1;
        final List<EnvelopeSnapshot> envs = [];
        for (int i = 0; i < envCount; i++) {
          final isProt = rand.nextBool();
          envs.add(EnvelopeSnapshot(
            id: i + 1,
            name: 'Env $i',
            policy: isProt
                ? EnvelopePolicyType.protected
                : EnvelopePolicyType.flexible,
            reservedBalance: VndMoney(rand.nextInt(10000000)),
          ));
        }

        final billCount = rand.nextInt(15) + 1;
        final List<PendingBillItem> bills = [];
        for (int j = 0; j < billCount; j++) {
          final linkChoice = rand.nextInt(envCount + 1);
          bills.add(PendingBillItem(
            id: j + 1,
            title: 'Bill $j',
            amount: VndMoney((rand.nextInt(50) + 1) * 100000),
            dueDate: DateTime(2026, 10, rand.nextInt(28) + 1),
            linkedEnvelopeId: linkChoice == 0 ? null : linkChoice,
          ));
        }

        final res = SafeToSpendCalculator.calculate(
          liquidAssets: VndMoney(50000000),
          envelopes: envs,
          pendingBills: bills,
          minimumCashBuffer: VndMoney(1000000),
          now: DateTime(2026, 10, 1),
          horizonDate: DateTime(2026, 10, 31),
        );

        int totalCovered = 0;
        int totalUnfunded = 0;
        int totalOriginalBills = 0;
        for (final alloc in res.breakdown.billAllocations) {
          totalCovered += alloc.coveredAmount.amount;
          totalUnfunded += alloc.unfundedAmount.amount;
          totalOriginalBills += alloc.amount.amount;
        }

        expect(totalCovered + totalUnfunded, equals(totalOriginalBills),
            reason: 'Trial $trial failed covered + unfunded != total bills');
        expect(res.breakdown.unfundedCommittedOutflows.amount,
            equals(totalUnfunded));
      }
    });

    test('Negative envelope balance does not inflate available cash', () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Deficit Envelope',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(-2000000), // Negative balance!
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 1,
            title: 'Bill',
            amount: VndMoney(1000000),
            dueDate: DateTime(2026, 10, 10),
            linkedEnvelopeId: 1,
          ),
        ],
        minimumCashBuffer: VndMoney.zero,
        now: DateTime(2026, 10, 1),
        horizonDate: DateTime(2026, 10, 31),
      );

      // Protected reserves must treat negative balance as 0 (not negative reserve reducing deduction)
      expect(result.breakdown.protectedReserves, equals(VndMoney.zero));
      // Bill cannot be covered by negative reserve -> 100% unfunded
      expect(result.breakdown.billAllocations.first.coveredAmount,
          equals(VndMoney.zero));
      expect(result.breakdown.billAllocations.first.unfundedAmount,
          equals(VndMoney(1000000)));
      // Safe to spend = 10M - 0 - 1M - 0 = 9M
      expect(result.safeToSpend, equals(VndMoney(9000000)));
    });

    test(
        'Same due-date bills maintain deterministic processing without corruption',
        () {
      final now = DateTime(2026, 10, 1);
      final horizon = DateTime(2026, 10, 31);
      final sameDay = DateTime(2026, 10, 15, 12, 0);

      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Shared Protected Env',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(1500000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 1,
            title: 'Bill A',
            amount: VndMoney(1000000),
            dueDate: sameDay,
            linkedEnvelopeId: 1,
          ),
          PendingBillItem(
            id: 2,
            title: 'Bill B',
            amount: VndMoney(1000000),
            dueDate: sameDay,
            linkedEnvelopeId: 1,
          ),
        ],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizon,
      );

      // Total bill amount = 2M. Protected reserve = 1.5M.
      // Total covered across both bills must be exactly 1.5M, total unfunded must be exactly 500k.
      final b1 =
          result.breakdown.billAllocations.firstWhere((b) => b.billId == 1);
      final b2 =
          result.breakdown.billAllocations.firstWhere((b) => b.billId == 2);
      expect(
          b1.coveredAmount.amount + b2.coveredAmount.amount, equals(1500000));
      expect(
          b1.unfundedAmount.amount + b2.unfundedAmount.amount, equals(500000));
      expect(result.safeToSpend, equals(VndMoney(8000000)));
    });
  });

  group('ADVERSARIAL STRESS TEST 2: Negative Safe-to-Spend & Deficit Breakdown',
      () {
    test('Extreme deficit: Never clamps to zero, preserves exact negative int',
        () {
      // Liquid = 1.000.000 ₫
      // Protected Reserves = 50.000.000 ₫
      // Unfunded Bills = 30.000.000 ₫
      // Min Buffer = 10.000.000 ₫
      // Formula: 1M - 50M - 30M - 10M = -89.000.000 ₫
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(1000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Emergency',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(50000000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 1,
            title: 'Tuition',
            amount: VndMoney(30000000),
            dueDate: DateTime(2026, 10, 15),
          ),
        ],
        minimumCashBuffer: VndMoney(10000000),
        now: DateTime(2026, 10, 1),
        horizonDate: DateTime(2026, 10, 31),
      );

      expect(result.safeToSpend.amount, equals(-89000000));
      expect(result.isDeficit, isTrue);
      // Daily allowance MUST be strictly 0 ₫, never negative!
      expect(result.dailyAllowance, equals(VndMoney.zero));
      expect(result.dailyAllowanceVnd, equals(0));

      // Breakdown matches exact terms:
      expect(result.breakdown.liquidAssets, equals(VndMoney(1000000)));
      expect(result.breakdown.protectedReserves, equals(VndMoney(50000000)));
      expect(result.breakdown.unfundedCommittedOutflows,
          equals(VndMoney(30000000)));
      expect(result.breakdown.minimumCashBuffer, equals(VndMoney(10000000)));

      // Identity check:
      expect(
        result.breakdown.liquidAssets.amount -
            result.breakdown.protectedReserves.amount -
            result.breakdown.unfundedCommittedOutflows.amount -
            result.breakdown.minimumCashBuffer.amount,
        equals(result.safeToSpend.amount),
      );
    });

    test('Zero liquid assets with obligations produces exact deficit', () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney.zero,
        envelopes: const [],
        pendingBills: [
          PendingBillItem(
            id: 1,
            title: 'Rent',
            amount: VndMoney(4500000),
            dueDate: DateTime(2026, 10, 5),
          ),
        ],
        minimumCashBuffer: VndMoney(500000),
        now: DateTime(2026, 10, 1),
        horizonDate: DateTime(2026, 10, 31),
      );

      // 0 - 0 - 4.5M - 500k = -5.000.000 ₫
      expect(result.safeToSpend, equals(VndMoney(-5000000)));
      expect(result.isDeficit, isTrue);
      expect(result.dailyAllowance, equals(VndMoney.zero));
    });

    test('Negative liquid assets (e.g. overdraft) produces deeper deficit', () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(-2000000),
        envelopes: const [],
        pendingBills: const [],
        minimumCashBuffer: VndMoney(1000000),
        now: DateTime(2026, 10, 1),
        horizonDate: DateTime(2026, 10, 31),
      );

      // -2M - 0 - 0 - 1M = -3.000.000 ₫
      expect(result.safeToSpend, equals(VndMoney(-3000000)));
      expect(result.isDeficit, isTrue);
      expect(result.dailyAllowance, equals(VndMoney.zero));
    });

    test('Horizon date <= now does not divide by zero in daily allowance', () {
      // Past or same-day horizon date
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: const [],
        pendingBills: const [],
        minimumCashBuffer: VndMoney.zero,
        now: DateTime(2026, 10, 15, 12, 0),
        horizonDate: DateTime(2026, 10, 10), // in the past!
      );

      expect(result.daysRemaining, equals(1)); // clamped to 1
      expect(result.safeToSpend, equals(VndMoney(10000000)));
      expect(result.dailyAllowance, equals(VndMoney(10000000))); // 10M ~/ 1
    });
  });

  group('ADVERSARIAL STRESS TEST 3: Month-End Recurrence & Leap Years', () {
    test('Comprehensive Leap Year rules: 4, 100, 400 year edge cases', () {
      // 4-year rule:
      expect(RecurrenceCalculator.isLeapYear(2024), isTrue);
      expect(RecurrenceCalculator.isLeapYear(2028), isTrue);
      expect(RecurrenceCalculator.isLeapYear(2032), isTrue);
      expect(RecurrenceCalculator.isLeapYear(2025), isFalse);
      expect(RecurrenceCalculator.isLeapYear(2026), isFalse);
      expect(RecurrenceCalculator.isLeapYear(2027), isFalse);

      // 100-year non-leap century rule:
      expect(RecurrenceCalculator.isLeapYear(2100), isFalse);
      expect(RecurrenceCalculator.isLeapYear(2200), isFalse);
      expect(RecurrenceCalculator.isLeapYear(2300), isFalse);
      expect(RecurrenceCalculator.isLeapYear(1900), isFalse);
      expect(RecurrenceCalculator.isLeapYear(1800), isFalse);

      // 400-year leap century rule:
      expect(RecurrenceCalculator.isLeapYear(2000), isTrue);
      expect(RecurrenceCalculator.isLeapYear(2400), isTrue);
      expect(RecurrenceCalculator.isLeapYear(1600), isTrue);
    });

    test(
        'Scenario 15: Day 31 recurrence across full 48-month span including 2024 (leap) and 2026',
        () {
      // Start Jan 31, 2024 (Leap Year) and roll for 48 months (4 years)
      DateTime current = DateTime(2024, 1, 31);
      const int anchor = 31;

      for (int monthIdx = 1; monthIdx <= 48; monthIdx++) {
        current = RecurrenceCalculator.computeNextDueDate(
          currentDueDate: current,
          recurrence: 'MONTHLY',
          anchorDayOfMonth: anchor,
        );

        final expectedDays =
            RecurrenceCalculator.daysInMonth(current.year, current.month);
        final expectedDay = min(anchor, expectedDays);

        expect(
          current.day,
          equals(expectedDay),
          reason:
              'Month $monthIdx (${current.year}-${current.month}): expected day $expectedDay, got ${current.day}',
        );

        // Explicit check for February in 2024 (leap):
        if (current.year == 2024 && current.month == 2) {
          expect(current.day, equals(29));
        }
        // Explicit check for March in 2024 (restoration to 31):
        if (current.year == 2024 && current.month == 3) {
          expect(current.day, equals(31));
        }
        // Explicit check for February in 2025 (non-leap):
        if (current.year == 2025 && current.month == 2) {
          expect(current.day, equals(28));
        }
        // Explicit check for March in 2025 (restoration to 31):
        if (current.year == 2025 && current.month == 3) {
          expect(current.day, equals(31));
        }
      }
    });

    test(
        'Century non-leap 2100: Feb produces day 28, not 29, then restores to 31',
        () {
      final jan2100 = DateTime(2100, 1, 31);
      final feb2100 = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: jan2100,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(feb2100.year, equals(2100));
      expect(feb2100.month, equals(2));
      expect(feb2100.day, equals(28)); // 2100 is NOT a leap year!

      final mar2100 = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: feb2100,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(mar2100.year, equals(2100));
      expect(mar2100.month, equals(3));
      expect(mar2100.day, equals(31)); // Restores to 31!
    });

    test('Century leap 2000: Feb produces day 29, then restores to 31', () {
      final jan2000 = DateTime(2000, 1, 31);
      final feb2000 = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: jan2000,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(feb2000.year, equals(2000));
      expect(feb2000.month, equals(2));
      expect(feb2000.day, equals(29)); // 2000 IS a leap year!

      final mar2000 = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: feb2000,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 31,
      );
      expect(mar2000.year, equals(2000));
      expect(mar2000.month, equals(3));
      expect(mar2000.day, equals(31));
    });

    test(
        'Day 30 anchor rolls into Feb 28/29 and restores to 30 in March and April',
        () {
      // Non-leap 2026: Jan 30 -> Feb 28 -> Mar 30 -> Apr 30
      final jan30 = DateTime(2026, 1, 30);
      final feb = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: jan30,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 30,
      );
      expect(feb.day, equals(28));

      final mar = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: feb,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 30,
      );
      expect(mar.day, equals(30));

      final apr = RecurrenceCalculator.computeNextDueDate(
        currentDueDate: mar,
        recurrence: 'MONTHLY',
        anchorDayOfMonth: 30,
      );
      expect(apr.day, equals(30));
    });

    test('Invalid month and anchor parameters throw ArgumentError', () {
      expect(() => RecurrenceCalculator.daysInMonth(2026, -1),
          throwsArgumentError);
      expect(
          () => RecurrenceCalculator.daysInMonth(2026, 0), throwsArgumentError);
      expect(() => RecurrenceCalculator.daysInMonth(2026, 13),
          throwsArgumentError);
      expect(() => RecurrenceCalculator.calculateActualDueDay(0, 2026, 5),
          throwsArgumentError);
      expect(() => RecurrenceCalculator.calculateActualDueDay(32, 2026, 5),
          throwsArgumentError);
    });

    test('generateRecurrenceDates handles non-recurring items and large limits',
        () {
      final single = RecurrenceCalculator.generateRecurrenceDates(
        startDueDate: DateTime(2026, 10, 5),
        recurrence: 'NONE',
        horizonDate: DateTime(2026, 12, 31),
      );
      expect(single.length, equals(1));
      expect(single.first, equals(DateTime(2026, 10, 5)));
    });
  });

  group('ADVERSARIAL STRESS TEST 4: Goal Integer Ceiling Division', () {
    test(
        'Exhaustive remainder stress test: guarantees (required * N) >= shortfall for all remainders',
        () {
      // Test 100 different non-divisible target/shortfall combinations
      for (int shortfall = 1; shortfall <= 100; shortfall++) {
        for (int periods = 1; periods <= 12; periods++) {
          final res = GoalCalculator.evaluateGoal(
            targetAmount: VndMoney(shortfall),
            currentReserved: VndMoney.zero,
            remainingPeriods: periods,
          );

          final int req = res.requiredPerPeriod.amount;
          final int expectedReq = (shortfall + periods - 1) ~/ periods;

          expect(req, equals(expectedReq));
          // Property 1: Accumulating required amount for N periods strictly achieves or exceeds target
          expect(req * periods >= shortfall, isTrue,
              reason:
                  'Shortfall: $shortfall, Periods: $periods, Req: $req failed attainment');
          // Property 2: A contribution of (req - 1) strictly fails target (minimal ceiling)
          if (req > 1) {
            expect((req - 1) * periods < shortfall, isTrue,
                reason:
                    'Shortfall: $shortfall, Periods: $periods, Req: $req was not minimal');
          }
          // Property 3: Final period remainder surplus is strictly less than N
          expect(req * periods - shortfall < periods, isTrue);
        }
      }
    });

    test('Extreme goal amounts: Large numbers within 64-bit int', () {
      // Target: 8.000.000.000.000 ₫ (8 trillion VND)
      final bigTarget = VndMoney(8000000000000);
      final res = GoalCalculator.evaluateGoal(
        targetAmount: bigTarget,
        currentReserved: VndMoney.zero,
        remainingPeriods: 36, // 3 years
      );

      expect(res.status, equals(GoalStatus.inProgress));
      expect(res.requiredPerPeriod * 36 >= bigTarget, isTrue);
      // Expected: ((8_000_000_000_000) + 36 - 1) ~/ 36 = 222_222_222_223 ₫
      expect(res.requiredPerPeriod, equals(VndMoney(222222222223)));
    });

    test('Overdue handling with N <= 0: Shortfall is required immediately', () {
      // Periods = 0
      final res0 = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(6000000),
        remainingPeriods: 0,
      );
      expect(res0.status, equals(GoalStatus.overdue));
      expect(res0.isOverdue, isTrue);
      expect(res0.shortfall, equals(VndMoney(4000000)));
      expect(res0.requiredPerPeriod, equals(VndMoney(4000000)));

      // Periods = -12 (1 year overdue)
      final resPast = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(2000000),
        remainingPeriods: -12,
      );
      expect(resPast.status, equals(GoalStatus.overdue));
      expect(resPast.shortfall, equals(VndMoney(8000000)));
      expect(resPast.requiredPerPeriod, equals(VndMoney(8000000)));
    });

    test('Zero target amount edge case does not crash or produce NaN', () {
      final res = GoalCalculator.evaluateGoal(
        targetAmount: VndMoney.zero,
        currentReserved: VndMoney.zero,
        remainingPeriods: 5,
      );

      expect(res.status, equals(GoalStatus.achieved));
      expect(res.requiredPerPeriod, equals(VndMoney.zero));
      expect(res.shortfall, equals(VndMoney.zero));
      expect(res.progressRatio, equals(1.0));
      expect(res.progressRatio.isNaN, isFalse);
    });
  });

  group('ADVERSARIAL STRESS TEST 5: Savings Rate & Net Recovery', () {
    test(
        'Zero income: savingsRate is strictly null, display is "Chưa có thu nhập", never NaN/Infinity',
        () {
      final food = CategorySpendingItem(
        categoryId: 1,
        categoryName: 'Ăn uống',
        grossExpense: VndMoney(2000000),
        refundCredits: VndMoney.zero,
      );

      final report = CategorySpendingCalculator.calculate(
        categoryItems: [food],
        recognizedIncome: VndMoney.zero,
      );

      expect(report.savingsRate, isNull);
      expect(report.savingsRateDisplay, equals('Chưa có thu nhập'));
      expect(report.recognizedIncome, equals(VndMoney.zero));
      expect(report.netSaving, equals(VndMoney(-2000000)));
    });

    test('Negative income (e.g. accounting corrections): savingsRate is null',
        () {
      final food = CategorySpendingItem(
        categoryId: 1,
        categoryName: 'Ăn uống',
        grossExpense: VndMoney(1500000),
        refundCredits: VndMoney.zero,
      );

      final report = CategorySpendingCalculator.calculate(
        categoryItems: [food],
        recognizedIncome: VndMoney(-1000000),
      );

      expect(report.savingsRate, isNull);
      expect(report.savingsRateDisplay, equals('Chưa có thu nhập'));
      expect(report.netSaving, equals(VndMoney(-2500000)));
    });

    test(
        'Net Recovery: Refunds strictly exceed gross expenses across multiple categories',
        () {
      // Category 1: Gross 1M, Refund 3M -> Net = -2M (Recovery)
      // Category 2: Gross 500k, Refund 1.5M -> Net = -1M (Recovery)
      final item1 = CategorySpendingItem(
        categoryId: 1,
        categoryName: 'Mua sắm',
        grossExpense: VndMoney(1000000),
        refundCredits: VndMoney(3000000),
      );
      final item2 = CategorySpendingItem(
        categoryId: 2,
        categoryName: 'Điện tử',
        grossExpense: VndMoney(500000),
        refundCredits: VndMoney(1500000),
      );

      expect(item1.isNetRecovery, isTrue);
      expect(item1.recoveryLabel, equals('Thu hồi chi phí ròng'));
      expect(item2.isNetRecovery, isTrue);

      final report = CategorySpendingCalculator.calculate(
        categoryItems: [item1, item2],
        recognizedIncome: VndMoney(10000000), // 10M income
      );

      // Total gross: 1.5M, total refund: 4.5M -> total net: -3.000.000 ₫
      expect(report.grossExpense, equals(VndMoney(1500000)));
      expect(report.refundCredits, equals(VndMoney(4500000)));
      expect(report.netExpense, equals(VndMoney(-3000000)));
      expect(report.isNetRecovery, isTrue);

      // Effective expense clamped to 0 ₫
      expect(report.effectiveExpense, equals(VndMoney.zero));
      // Net saving increases: 10M - (-3M) = 13M
      expect(report.netSaving, equals(VndMoney(13000000)));

      // Savings rate = (10M - 0) / 10M = 1.0 (100%), never inflated beyond 100%!
      expect(report.savingsRate, equals(1.0));
      expect(report.savingsRateDisplay, equals('100%'));

      // Category breakdown proportions when all items are net recovery:
      for (final cat in report.categories) {
        expect(cat.percentageOfTotal, equals(0.0));
      }
    });

    test('100% Refund: Gross expense equals refunds exactly (net expense = 0)',
        () {
      final item = CategorySpendingItem(
        categoryId: 1,
        categoryName: 'Vé tàu',
        grossExpense: VndMoney(2000000),
        refundCredits: VndMoney(2000000), // Fully refunded
      );

      final report = CategorySpendingCalculator.calculate(
        categoryItems: [item],
        recognizedIncome: VndMoney(5000000),
      );

      expect(report.netExpense, equals(VndMoney.zero));
      expect(report.isNetRecovery, isFalse);
      expect(report.effectiveExpense, equals(VndMoney.zero));
      expect(report.netSaving, equals(VndMoney(5000000)));
      expect(report.savingsRate, equals(1.0)); // 100%
      expect(report.savingsRateDisplay, equals('100%'));
    });

    test('Overspending: Expense > Income produces negative savings rate', () {
      final food = CategorySpendingItem(
        categoryId: 1,
        categoryName: 'Ăn uống',
        grossExpense: VndMoney(15000000), // 15M
        refundCredits: VndMoney.zero,
      );

      final report = CategorySpendingCalculator.calculate(
        categoryItems: [food],
        recognizedIncome: VndMoney(10000000), // 10M income
      );

      // Net saving = 10M - 15M = -5M
      expect(report.netSaving, equals(VndMoney(-5000000)));
      // Savings rate = (10M - 15M) / 10M = -0.5 (-50%)
      expect(report.savingsRate, closeTo(-0.50, 0.001));
      expect(report.savingsRateDisplay, equals('-50%'));
    });
  });

  group('ADVERSARIAL STRESS TEST 6: Feasibility Advisor Edge Cases', () {
    test('Zero and negative capacity handling in calculators', () {
      // 1. Extend deadline throws ArgumentError if capacity <= 0
      expect(
        () => FeasibilityAdvisor.calculateExtendedDeadline(
          targetAmount: VndMoney(10000000),
          currentReserved: VndMoney.zero,
          allocatedMonthlyCapacity: VndMoney.zero,
        ),
        throwsArgumentError,
      );

      expect(
        () => FeasibilityAdvisor.calculateExtendedDeadline(
          targetAmount: VndMoney(10000000),
          currentReserved: VndMoney.zero,
          allocatedMonthlyCapacity: VndMoney(-500000),
        ),
        throwsArgumentError,
      );

      // 2. Lower target with negative capacity returns currentReserved
      final loweredNeg = FeasibilityAdvisor.calculateLoweredTarget(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(2000000),
        remainingPeriods: 5,
        allocatedMonthlyCapacity: VndMoney(-100000),
      );
      expect(loweredNeg, equals(VndMoney(2000000)));

      // 3. Lower target with 0 remaining periods returns currentReserved
      final lowered0 = FeasibilityAdvisor.calculateLoweredTarget(
        targetAmount: VndMoney(10000000),
        currentReserved: VndMoney(2000000),
        remainingPeriods: 0,
        allocatedMonthlyCapacity: VndMoney(1000000),
      );
      expect(lowered0, equals(VndMoney(2000000)));
    });

    test(
        'Pruning advisor with multiple identical priorities uses deadline tie-break',
        () {
      final g1 = ActiveGoalItem(
        id: 1,
        name: 'Goal Due in 12 months',
        targetAmount: VndMoney(12000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 12, // 1M/month
        priority: 1,
      );

      final g2 = ActiveGoalItem(
        id: 2,
        name: 'Goal Due in 3 months',
        targetAmount: VndMoney(3000000),
        currentReserved: VndMoney.zero,
        remainingPeriods: 3, // 1M/month
        priority: 1,
      );

      // Capacity = 1.000.000 ₫
      // Both priority 1 -> g2 (3 months) must be funded first, g1 (12 months) paused!
      final actions = FeasibilityAdvisor.recommendGoalPruning(
        goals: [g1, g2],
        monthlyCapacity: VndMoney(1000000),
      );

      expect(actions[0].goal.id, equals(2)); // g2 funded
      expect(actions[0].shouldPause, isFalse);
      expect(actions[1].goal.id, equals(1)); // g1 paused
      expect(actions[1].shouldPause, isTrue);
    });
  });

  group('ADVERSARIAL STRESS TEST 7: Cash Flow Forecaster Invariants', () {
    test(
        'Projects daily points, detects buffer breach and calculates max deficit',
        () {
      final startDate = DateTime(2026, 10, 1);
      final startingLiquid = VndMoney(5000000); // 5M
      final minBuffer = VndMoney(2000000); // 2M buffer

      // Bill on Oct 5: 4M -> balance becomes 1M (< 2M buffer, deficit 1M)
      // Income on Oct 10: 10M -> balance becomes 11M (> buffer)
      final bills = [
        ForecastScheduledItem(
          id: 1,
          kind: ScheduledItemKind.bill,
          title: 'Tiền học',
          amount: VndMoney(4000000),
          dueDate: DateTime(2026, 10, 5),
          recurrence: 'NONE',
          status: 'PENDING',
        ),
        ForecastScheduledItem(
          id: 2,
          kind: ScheduledItemKind.plannedIncome,
          title: 'Lương',
          amount: VndMoney(10000000),
          dueDate: DateTime(2026, 10, 10),
          recurrence: 'NONE',
          status: 'PENDING',
        ),
      ];

      final forecast = CashFlowForecaster.project(
        startingLiquidAssets: startingLiquid,
        minimumCashBuffer: minBuffer,
        scheduledItems: bills,
        startDate: startDate,
        horizonDays: 30,
      );

      expect(forecast.hasDeficit, isTrue);
      expect(forecast.firstDeficitDate, equals(DateTime(2026, 10, 5)));
      expect(
          forecast.maxDeficitAmount, equals(VndMoney(1000000))); // 2M - 1M = 1M
      expect(forecast.lowestBalance, equals(VndMoney(1000000)));
      expect(forecast.lowestBalanceDate, equals(DateTime(2026, 10, 5)));
      expect(forecast.totalInflows, equals(VndMoney(10000000)));
      expect(forecast.totalOutflows, equals(VndMoney(4000000)));
      expect(forecast.netCashFlow, equals(VndMoney(6000000)));
      expect(forecast.endingBalance, equals(VndMoney(11000000)));
    });

    test('Non-positive horizon days throws ArgumentError', () {
      expect(
        () => CashFlowForecaster.project(
          startingLiquidAssets: VndMoney(1000000),
          minimumCashBuffer: VndMoney.zero,
          scheduledItems: const [],
          startDate: DateTime(2026, 10, 1),
          horizonDays: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
