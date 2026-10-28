import '../../../core/database/app_database.dart';

/// Aggregated financial metrics for the Virtual Funds (Quỹ tiền) tab.
class VirtualFundsSummary {
  final int totalLiquidAssets;
  final int totalEnvelopeReserves;
  final int totalProtectedReserves;
  final int totalFlexibleReserves;
  final int minimumCashBuffer;
  final int availableToAllocate;
  final bool isOverAllocated;
  final int overAllocatedAmount;
  final List<Envelope> protectedEnvelopes;
  final List<Envelope> flexibleEnvelopes;

  const VirtualFundsSummary({
    required this.totalLiquidAssets,
    required this.totalEnvelopeReserves,
    required this.totalProtectedReserves,
    required this.totalFlexibleReserves,
    required this.minimumCashBuffer,
    required this.availableToAllocate,
    required this.isOverAllocated,
    required this.overAllocatedAmount,
    required this.protectedEnvelopes,
    required this.flexibleEnvelopes,
  });

  factory VirtualFundsSummary.compute({
    required int totalLiquidAssets,
    required List<Envelope> allEnvelopes,
    required int minimumCashBuffer,
  }) {
    final activeEnvelopes = allEnvelopes.where((e) => !e.isArchived).toList();

    int protectedSum = 0;
    int flexibleSum = 0;
    final protectedList = <Envelope>[];
    final flexibleList = <Envelope>[];

    for (final env in activeEnvelopes) {
      if (env.policy == 'PROTECTED') {
        protectedSum += env.reservedBalanceVnd;
        protectedList.add(env);
      } else {
        flexibleSum += env.reservedBalanceVnd;
        flexibleList.add(env);
      }
    }

    final totalReserved = protectedSum + flexibleSum;
    final available = totalLiquidAssets - totalReserved - minimumCashBuffer;
    final isOver = available < 0;
    final overAmount = isOver ? -available : 0;

    return VirtualFundsSummary(
      totalLiquidAssets: totalLiquidAssets,
      totalEnvelopeReserves: totalReserved,
      totalProtectedReserves: protectedSum,
      totalFlexibleReserves: flexibleSum,
      minimumCashBuffer: minimumCashBuffer,
      availableToAllocate: available,
      isOverAllocated: isOver,
      overAllocatedAmount: overAmount,
      protectedEnvelopes: protectedList,
      flexibleEnvelopes: flexibleList,
    );
  }
}
