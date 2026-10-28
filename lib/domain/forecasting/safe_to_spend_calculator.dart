import 'package:dongtien/core/money/vnd_money.dart';

/// Policy governing how an envelope interacts with Safe-to-Spend.
enum EnvelopePolicyType {
  protected,
  flexible;

  static EnvelopePolicyType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'PROTECTED':
        return EnvelopePolicyType.protected;
      case 'FLEXIBLE':
        return EnvelopePolicyType.flexible;
      default:
        throw ArgumentError('Invalid envelope policy: "$val"');
    }
  }
}

/// Snapshot of an active virtual fund envelope.
class EnvelopeSnapshot {
  final int id;
  final String name;
  final EnvelopePolicyType policy;
  final VndMoney reservedBalance;

  const EnvelopeSnapshot({
    required this.id,
    required this.name,
    required this.policy,
    required this.reservedBalance,
  });
}

/// Representation of a pending bill obligation.
class PendingBillItem {
  final int id;
  final String title;
  final VndMoney amount;
  final DateTime dueDate;
  final int? linkedEnvelopeId;

  const PendingBillItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.linkedEnvelopeId,
  });
}

/// Detailed allocation tracking for an individual pending bill.
class BillAllocationDetail {
  final int billId;
  final String title;
  final VndMoney amount;
  final DateTime dueDate;
  final int? linkedEnvelopeId;
  final EnvelopePolicyType? linkedEnvelopePolicy;
  final VndMoney coveredAmount;
  final VndMoney unfundedAmount;

  const BillAllocationDetail({
    required this.billId,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.linkedEnvelopeId,
    this.linkedEnvelopePolicy,
    required this.coveredAmount,
    required this.unfundedAmount,
  });
}

/// Detailed coverage tracking for an individual protected envelope.
class EnvelopeCoverageDetail {
  final int envelopeId;
  final String envelopeName;
  final VndMoney initialReservedBalance;
  final VndMoney allocatedToBills;
  final VndMoney remainingProtectedReserve;

  const EnvelopeCoverageDetail({
    required this.envelopeId,
    required this.envelopeName,
    required this.initialReservedBalance,
    required this.allocatedToBills,
    required this.remainingProtectedReserve,
  });
}

/// Complete structural breakdown of the Safe-to-Spend formula.
class SafeToSpendBreakdown {
  final VndMoney liquidAssets;
  final VndMoney protectedReserves;
  final VndMoney unfundedCommittedOutflows;
  final VndMoney minimumCashBuffer;
  final List<BillAllocationDetail> billAllocations;
  final List<EnvelopeCoverageDetail> envelopeCoverages;

  const SafeToSpendBreakdown({
    required this.liquidAssets,
    required this.protectedReserves,
    required this.unfundedCommittedOutflows,
    required this.minimumCashBuffer,
    required this.billAllocations,
    required this.envelopeCoverages,
  });
}

/// Result of the Safe-to-Spend calculation.
class SafeToSpendResult {
  /// Spendable amount in VND. May be negative (NEVER clamped to zero).
  final VndMoney safeToSpend;

  /// Daily discretionary allowance: Safe-to-Spend ~/ max(1, daysRemaining) if positive, else 0 ₫.
  final VndMoney dailyAllowance;

  /// True if safeToSpend < 0 (user is in deficit).
  final bool isDeficit;

  /// Number of days remaining in the evaluation horizon.
  final int daysRemaining;

  /// Full transparent breakdown for the UI breakdown modal.
  final SafeToSpendBreakdown breakdown;

  const SafeToSpendResult({
    required this.safeToSpend,
    required this.dailyAllowance,
    required this.isDeficit,
    required this.daysRemaining,
    required this.breakdown,
  });

  int get safeToSpendVnd => safeToSpend.amount;
  int get dailyAllowanceVnd => dailyAllowance.amount;
}

/// Pure Dart calculator implementing the Zero Double-Counting Safe-to-Spend algorithm.
class SafeToSpendCalculator {
  const SafeToSpendCalculator._();

  /// Calculates Safe-to-Spend from [now] to [horizonDate].
  ///
  /// Mathematical specifications:
  /// Safe-to-Spend = Liquid Assets - Protected Reserves - Unfunded Committed Outflows - Minimum Cash Buffer
  ///
  /// Zero Double-Counting Algorithm:
  /// 1. Protected envelopes cover linked pending bills in chronological due-date order.
  /// 2. Case A (No linked envelope): unfunded = bill.amount.
  /// 3. Case B (Linked to PROTECTED envelope):
  ///    covered = min(bill.amount, remaining_balance)
  ///    unfunded = bill.amount - covered
  ///    remaining_balance -= covered
  /// 4. Case C (Linked to FLEXIBLE envelope): unfunded = bill.amount.
  /// 5. Daily allowance: Safe-to-Spend ~/ max(1, daysRemaining) if safeToSpend > 0, else 0 ₫/ngày.
  static SafeToSpendResult calculate({
    required VndMoney liquidAssets,
    required List<EnvelopeSnapshot> envelopes,
    required List<PendingBillItem> pendingBills,
    required VndMoney minimumCashBuffer,
    required DateTime now,
    required DateTime horizonDate,
    int? daysRemainingOverride,
  }) {
    // 1. Calculate days remaining
    final int daysRemaining;
    if (daysRemainingOverride != null) {
      daysRemaining = daysRemainingOverride > 0 ? daysRemainingOverride : 1;
    } else {
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      final horizonDateOnly =
          DateTime(horizonDate.year, horizonDate.month, horizonDate.day);
      final diff = horizonDateOnly.difference(nowDateOnly).inDays;
      daysRemaining = diff <= 0 ? 1 : diff;
    }

    // 2. Map envelopes and initialize remaining balances for PROTECTED envelopes
    final Map<int, EnvelopeSnapshot> envelopeMap = {
      for (final env in envelopes) env.id: env,
    };

    final Map<int, int> remainingBalances = {};
    int totalProtectedReservesVnd = 0;

    for (final env in envelopes) {
      if (env.policy == EnvelopePolicyType.protected) {
        final bal =
            env.reservedBalance.amount > 0 ? env.reservedBalance.amount : 0;
        remainingBalances[env.id] = bal;
        totalProtectedReservesVnd += bal;
      }
    }
    final VndMoney protectedReserves = VndMoney(totalProtectedReservesVnd);

    // 3. Filter pending bills due on or before horizonDate, sorted chronologically
    final horizonEndOfDay = DateTime(
      horizonDate.year,
      horizonDate.month,
      horizonDate.day,
      23,
      59,
      59,
      999,
    );

    final eligibleBills = pendingBills
        .where((b) => !b.dueDate.isAfter(horizonEndOfDay))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // 4. Chronological allocation across pending bills (Zero Double-Counting)
    final List<BillAllocationDetail> billAllocations = [];
    int totalUnfundedVnd = 0;
    final Map<int, int> envelopeAllocatedMap = {};

    for (final bill in eligibleBills) {
      final billAmountVnd = bill.amount.amount;
      final linkedEnvId = bill.linkedEnvelopeId;
      final linkedEnv = linkedEnvId != null ? envelopeMap[linkedEnvId] : null;

      if (linkedEnv == null) {
        // Case A: No linked envelope
        billAllocations.add(BillAllocationDetail(
          billId: bill.id,
          title: bill.title,
          amount: bill.amount,
          dueDate: bill.dueDate,
          linkedEnvelopeId: null,
          linkedEnvelopePolicy: null,
          coveredAmount: VndMoney.zero,
          unfundedAmount: bill.amount,
        ));
        totalUnfundedVnd += billAmountVnd;
      } else if (linkedEnv.policy == EnvelopePolicyType.protected) {
        // Case B: Linked to PROTECTED envelope
        final currentRemaining = remainingBalances[linkedEnv.id] ?? 0;
        final coveredVnd =
            billAmountVnd < currentRemaining ? billAmountVnd : currentRemaining;
        final unfundedVnd = billAmountVnd - coveredVnd;

        remainingBalances[linkedEnv.id] = currentRemaining - coveredVnd;
        envelopeAllocatedMap[linkedEnv.id] =
            (envelopeAllocatedMap[linkedEnv.id] ?? 0) + coveredVnd;

        billAllocations.add(BillAllocationDetail(
          billId: bill.id,
          title: bill.title,
          amount: bill.amount,
          dueDate: bill.dueDate,
          linkedEnvelopeId: linkedEnv.id,
          linkedEnvelopePolicy: EnvelopePolicyType.protected,
          coveredAmount: VndMoney(coveredVnd),
          unfundedAmount: VndMoney(unfundedVnd),
        ));
        totalUnfundedVnd += unfundedVnd;
      } else {
        // Case C: Linked to FLEXIBLE envelope
        billAllocations.add(BillAllocationDetail(
          billId: bill.id,
          title: bill.title,
          amount: bill.amount,
          dueDate: bill.dueDate,
          linkedEnvelopeId: linkedEnv.id,
          linkedEnvelopePolicy: EnvelopePolicyType.flexible,
          coveredAmount: VndMoney.zero,
          unfundedAmount: bill.amount,
        ));
        totalUnfundedVnd += billAmountVnd;
      }
    }

    final VndMoney unfundedCommittedOutflows = VndMoney(totalUnfundedVnd);

    // 5. Envelope coverage details
    final List<EnvelopeCoverageDetail> coverageDetails = [];
    for (final env in envelopes) {
      if (env.policy == EnvelopePolicyType.protected) {
        final initialBal =
            env.reservedBalance.amount > 0 ? env.reservedBalance.amount : 0;
        final allocated = envelopeAllocatedMap[env.id] ?? 0;
        final rem = initialBal - allocated;
        coverageDetails.add(EnvelopeCoverageDetail(
          envelopeId: env.id,
          envelopeName: env.name,
          initialReservedBalance: VndMoney(initialBal),
          allocatedToBills: VndMoney(allocated),
          remainingProtectedReserve: VndMoney(rem),
        ));
      }
    }

    // 6. Safe-to-Spend arithmetic: Liquid Assets - Protected Reserves - Unfunded Outflows - Buffer
    final int safeToSpendVnd = liquidAssets.amount -
        protectedReserves.amount -
        unfundedCommittedOutflows.amount -
        minimumCashBuffer.amount;

    final VndMoney safeToSpend = VndMoney(safeToSpendVnd);
    final bool isDeficit = safeToSpendVnd < 0;

    // 7. Daily allowance integer division
    final int effectiveDivisor = daysRemaining > 0 ? daysRemaining : 1;
    final VndMoney dailyAllowance;
    if (safeToSpendVnd > 0) {
      dailyAllowance = VndMoney(safeToSpendVnd ~/ effectiveDivisor);
    } else {
      dailyAllowance = VndMoney.zero;
    }

    return SafeToSpendResult(
      safeToSpend: safeToSpend,
      dailyAllowance: dailyAllowance,
      isDeficit: isDeficit,
      daysRemaining: effectiveDivisor,
      breakdown: SafeToSpendBreakdown(
        liquidAssets: liquidAssets,
        protectedReserves: protectedReserves,
        unfundedCommittedOutflows: unfundedCommittedOutflows,
        minimumCashBuffer: minimumCashBuffer,
        billAllocations: billAllocations,
        envelopeCoverages: coverageDetails,
      ),
    );
  }
}
