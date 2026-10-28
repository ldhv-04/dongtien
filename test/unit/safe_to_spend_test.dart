import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/forecasting/safe_to_spend_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeToSpendCalculator — Zero Double-Counting & Deficit Invariants',
      () {
    final now = DateTime(2026, 10, 1, 9, 0);
    final horizonDate = DateTime(2026, 10, 31, 23, 59);

    test(
        'Scenario 5: Protected Envelope Allocation reduces Safe-to-Spend without bill',
        () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(20000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Quỹ khẩn cấp',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(1000000),
          ),
          EnvelopeSnapshot(
            id: 2,
            name: 'Quỹ mua sắm',
            policy: EnvelopePolicyType.flexible,
            reservedBalance: VndMoney(2000000),
          ),
        ],
        pendingBills: const [],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizonDate,
      );

      // Liquid: 20M - Protected Reserve: 1M - Unfunded: 0 - Buffer: 0 = 19M
      expect(result.safeToSpend, equals(VndMoney(19000000)));
      expect(result.isDeficit, isFalse);
      expect(result.breakdown.protectedReserves, equals(VndMoney(1000000)));
      expect(result.breakdown.unfundedCommittedOutflows, equals(VndMoney.zero));
    });

    test(
        'Scenario 11: Zero Double-Counting for Bill Linked to Protected Envelope',
        () {
      // Setup: 10M liquid, 1M in Protected "Điện Nước", 0 buffer.
      // Bill: "Tiền điện" 1.5M linked to "Điện Nước".
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Điện Nước',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(1000000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 101,
            title: 'Tiền điện tháng 10',
            amount: VndMoney(1500000),
            dueDate: DateTime(2026, 10, 15),
            linkedEnvelopeId: 1,
          ),
        ],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizonDate,
      );

      // Protected reserve = 1M
      // Bill is covered 1M, unfunded = 500k.
      // Total deducted = 1M (reserve) + 500k (unfunded) = 1.5M.
      // NOT 1M + 1.5M = 2.5M!
      // Safe-to-Spend = 10M - 1M - 500k = 8.5M.
      expect(result.safeToSpend, equals(VndMoney(8500000)));
      expect(result.isDeficit, isFalse);
      expect(result.breakdown.protectedReserves, equals(VndMoney(1000000)));
      expect(
          result.breakdown.unfundedCommittedOutflows, equals(VndMoney(500000)));

      final billDetail = result.breakdown.billAllocations.first;
      expect(billDetail.coveredAmount, equals(VndMoney(1000000)));
      expect(billDetail.unfundedAmount, equals(VndMoney(500000)));
    });

    test(
        'Multiple bills linked to same Protected envelope are funded chronologically',
        () {
      // Protected envelope has 2.000.000 ₫
      // Bill A (due Oct 5): 1.200.000 ₫ -> covered 1.2M, unfunded 0, remaining reserve 800k
      // Bill B (due Oct 20): 1.500.000 ₫ -> covered 800k, unfunded 700k, remaining reserve 0
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Quỹ hoá đơn',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(2000000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 2,
            title: 'Internet',
            amount: VndMoney(1500000),
            dueDate: DateTime(2026, 10, 20),
            linkedEnvelopeId: 1,
          ),
          PendingBillItem(
            id: 1,
            title: 'Tiền điện',
            amount: VndMoney(1200000),
            dueDate: DateTime(2026, 10, 5),
            linkedEnvelopeId: 1,
          ),
        ],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizonDate,
      );

      // Protected reserve = 2M. Unfunded outflows = 700k.
      // Total deduction = 2.7M.
      // Safe-to-Spend = 10M - 2M - 700k = 7.3M.
      expect(result.safeToSpend, equals(VndMoney(7300000)));
      expect(
          result.breakdown.unfundedCommittedOutflows, equals(VndMoney(700000)));

      // Check chronological ordering: Bill 1 (Oct 5) was processed before Bill 2 (Oct 20)
      final bill1 =
          result.breakdown.billAllocations.firstWhere((b) => b.billId == 1);
      final bill2 =
          result.breakdown.billAllocations.firstWhere((b) => b.billId == 2);
      expect(bill1.coveredAmount, equals(VndMoney(1200000)));
      expect(bill1.unfundedAmount, equals(VndMoney.zero));
      expect(bill2.coveredAmount, equals(VndMoney(800000)));
      expect(bill2.unfundedAmount, equals(VndMoney(700000)));
    });

    test(
        'Case A (unlinked bill) and Case C (flexible envelope) are 100% unfunded',
        () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(10000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Quỹ linh hoạt',
            policy: EnvelopePolicyType.flexible,
            reservedBalance: VndMoney(1000000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 10,
            title: 'Tiền chợ',
            amount: VndMoney(500000),
            dueDate: DateTime(2026, 10, 10),
            linkedEnvelopeId: null, // Case A
          ),
          PendingBillItem(
            id: 11,
            title: 'Mua quà',
            amount: VndMoney(300000),
            dueDate: DateTime(2026, 10, 12),
            linkedEnvelopeId: 1, // Case C
          ),
        ],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizonDate,
      );

      // Flexible reserves are NOT deducted in protectedReserves
      expect(result.breakdown.protectedReserves, equals(VndMoney.zero));
      // Both bills are unfunded = 500k + 300k = 800k
      expect(
          result.breakdown.unfundedCommittedOutflows, equals(VndMoney(800000)));
      // Safe-to-Spend = 10M - 800k = 9.2M
      expect(result.safeToSpend, equals(VndMoney(9200000)));
    });

    test('Bills beyond horizon date are excluded from Safe-to-Spend', () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(5000000),
        envelopes: const [],
        pendingBills: [
          PendingBillItem(
            id: 1,
            title: 'Bill in October',
            amount: VndMoney(1000000),
            dueDate: DateTime(2026, 10, 20),
          ),
          PendingBillItem(
            id: 2,
            title: 'Bill in November',
            amount: VndMoney(2000000),
            dueDate: DateTime(2026, 11, 5),
          ),
        ],
        minimumCashBuffer: VndMoney.zero,
        now: now,
        horizonDate: horizonDate, // Ends Oct 31
      );

      expect(result.breakdown.unfundedCommittedOutflows,
          equals(VndMoney(1000000)));
      expect(result.safeToSpend, equals(VndMoney(4000000)));
      expect(result.breakdown.billAllocations.length, equals(1));
    });

    test('Never clamp to zero: Returns exact negative integer VND on deficit',
        () {
      // 2M liquid - 1.5M protected - 1M bill - 1M buffer = -1.5M
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(2000000),
        envelopes: [
          EnvelopeSnapshot(
            id: 1,
            name: 'Bảo hiểm',
            policy: EnvelopePolicyType.protected,
            reservedBalance: VndMoney(1500000),
          ),
        ],
        pendingBills: [
          PendingBillItem(
            id: 1,
            title: 'Học phí',
            amount: VndMoney(1000000),
            dueDate: DateTime(2026, 10, 10),
          ),
        ],
        minimumCashBuffer: VndMoney(1000000),
        now: now,
        horizonDate: horizonDate,
      );

      expect(result.safeToSpend, equals(VndMoney(-1500000)));
      expect(result.isDeficit, isTrue);
      // Daily allowance must be strictly 0 ₫ when in deficit
      expect(result.dailyAllowance, equals(VndMoney.zero));
    });

    test(
        'Daily discretionary allowance performs integer division ~/ max(1, daysRemaining)',
        () {
      final result = SafeToSpendCalculator.calculate(
        liquidAssets: VndMoney(3000000),
        envelopes: const [],
        pendingBills: const [],
        minimumCashBuffer: VndMoney.zero,
        now: DateTime(2026, 10, 1),
        horizonDate: DateTime(2026, 10, 11), // 10 days difference
        daysRemainingOverride: 10,
      );

      expect(result.safeToSpend, equals(VndMoney(3000000)));
      expect(result.dailyAllowance, equals(VndMoney(300000)));
      expect(result.daysRemaining, equals(10));
    });
  });
}
