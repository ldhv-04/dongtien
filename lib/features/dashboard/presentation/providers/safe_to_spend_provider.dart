import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../domain/forecasting/safe_to_spend_calculator.dart';
import 'dashboard_providers.dart';

/// Pure reactive provider computing the live Safe-to-Spend figure
/// and transparent breakdown using the Zero Double-Counting formula.
final safeToSpendProvider = Provider<AsyncValue<SafeToSpendResult>>((ref) {
  final liquidAssetsAsync = ref.watch(liquidAssetsStreamProvider);
  final envelopesAsync = ref.watch(envelopesStreamProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final pendingBillsAsync = ref.watch(pendingBillsStreamProvider);
  final nextIncomeAsync = ref.watch(nextPlannedIncomeStreamProvider);

  if (liquidAssetsAsync.isLoading ||
      envelopesAsync.isLoading ||
      settingsAsync.isLoading ||
      pendingBillsAsync.isLoading ||
      nextIncomeAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (liquidAssetsAsync.hasError) {
    return AsyncValue.error(
        liquidAssetsAsync.error!, liquidAssetsAsync.stackTrace!);
  }
  if (envelopesAsync.hasError) {
    return AsyncValue.error(envelopesAsync.error!, envelopesAsync.stackTrace!);
  }
  if (settingsAsync.hasError) {
    return AsyncValue.error(settingsAsync.error!, settingsAsync.stackTrace!);
  }
  if (pendingBillsAsync.hasError) {
    return AsyncValue.error(
        pendingBillsAsync.error!, pendingBillsAsync.stackTrace!);
  }

  final liquidAssets = VndMoney(liquidAssetsAsync.value ?? 0);
  final settings = settingsAsync.value;
  final minBuffer = settings != null
      ? VndMoney(settings.minimumCashBufferVnd)
      : VndMoney.zero;

  final envelopeSnapshots = (envelopesAsync.value ?? []).map((e) {
    return EnvelopeSnapshot(
      id: e.id,
      name: e.name,
      policy: EnvelopePolicyType.fromString(e.policy),
      reservedBalance: VndMoney(e.reservedBalanceVnd),
    );
  }).toList();

  final pendingBillItems = (pendingBillsAsync.value ?? []).map((b) {
    return PendingBillItem(
      id: b.id,
      title: b.title,
      amount: VndMoney(b.amountVnd),
      dueDate: DateTime.fromMillisecondsSinceEpoch(b.dueDateMs),
      linkedEnvelopeId: b.linkedEnvelopeId,
    );
  }).toList();

  final now = DateTime.now();
  final nextIncome = nextIncomeAsync.value;
  final DateTime horizonDate;
  if (nextIncome != null) {
    horizonDate = DateTime.fromMillisecondsSinceEpoch(nextIncome.dueDateMs);
  } else {
    // End of current month
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    horizonDate = DateTime(now.year, now.month, lastDay, 23, 59, 59);
  }

  final result = SafeToSpendCalculator.calculate(
    liquidAssets: liquidAssets,
    envelopes: envelopeSnapshots,
    pendingBills: pendingBillItems,
    minimumCashBuffer: minBuffer,
    now: now,
    horizonDate: horizonDate,
  );

  return AsyncValue.data(result);
});
