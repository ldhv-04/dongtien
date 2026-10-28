import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/providers/dashboard_providers.dart';
import '../data/envelope_repository.dart';
import '../domain/envelope_detail_state.dart';
import '../domain/virtual_funds_summary.dart';

final envelopeRepositoryProvider = Provider<EnvelopeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EnvelopeRepository(db);
});

/// Combined summary provider recomputing reactively whenever any stream updates.
final virtualFundsSummaryProvider =
    Provider<AsyncValue<VirtualFundsSummary>>((ref) {
  final envelopesAsync = ref.watch(envelopesStreamProvider);
  final liquidAsync = ref.watch(liquidAssetsStreamProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);

  if (envelopesAsync.isLoading ||
      liquidAsync.isLoading ||
      settingsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (envelopesAsync.hasError) {
    return AsyncValue.error(envelopesAsync.error!, envelopesAsync.stackTrace!);
  }
  if (liquidAsync.hasError) {
    return AsyncValue.error(liquidAsync.error!, liquidAsync.stackTrace!);
  }
  if (settingsAsync.hasError) {
    return AsyncValue.error(settingsAsync.error!, settingsAsync.stackTrace!);
  }

  final allEnvelopes = envelopesAsync.value ?? [];
  final liquid = liquidAsync.value ?? 0;
  final settings = settingsAsync.value;
  final buffer = settings?.minimumCashBufferVnd ?? 0;

  final summary = VirtualFundsSummary.compute(
    totalLiquidAssets: liquid,
    allEnvelopes: allEnvelopes,
    minimumCashBuffer: buffer,
  );

  return AsyncValue.data(summary);
});

/// Detail provider family for viewing a specific envelope and its movement history.
final envelopeDetailProvider =
    StreamProvider.family<EnvelopeDetailState, int>((ref, envelopeId) async* {
  final repo = ref.watch(envelopeRepositoryProvider);
  final envelopesStream = repo.watchAllEnvelopes();

  await for (final envelopes in envelopesStream) {
    final movements = await repo.watchMovements(envelopeId).first;
    final currentEnv = envelopes.firstWhere(
      (e) => e.id == envelopeId,
      orElse: () => throw ArgumentError('Envelope not found: $envelopeId'),
    );

    final names = {for (final e in envelopes) e.id: e.name};

    yield EnvelopeDetailState(
      envelope: currentEnv,
      movements: movements,
      envelopeNames: names,
    );
  }
});
