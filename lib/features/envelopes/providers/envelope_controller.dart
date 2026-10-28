import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/envelopes/envelope_policy.dart';
import '../../dashboard/presentation/providers/dashboard_providers.dart';
import 'envelope_providers.dart';

/// Controller executing user-initiated virtual fund (envelope) mutations.
class EnvelopeController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> allocate({
    required int envelopeId,
    required int amountVnd,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      final liquid = await ref.read(liquidAssetsStreamProvider.future);
      await repo.allocate(
        envelopeId: envelopeId,
        amountVnd: amountVnd,
        totalLiquidAssetsVnd: liquid,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> release({
    required int envelopeId,
    required int amountVnd,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.release(envelopeId: envelopeId, amountVnd: amountVnd);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> transfer({
    required int fromEnvelopeId,
    required int toEnvelopeId,
    required int amountVnd,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.transfer(
        fromEnvelopeId: fromEnvelopeId,
        toEnvelopeId: toEnvelopeId,
        amountVnd: amountVnd,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createEnvelope({
    required String name,
    required EnvelopePolicy policy,
    int? targetAmountVnd,
    DateTime? targetDate,
    bool allowNegativeException = false,
    int priority = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.createEnvelope(
        name: name,
        policy: policy,
        targetAmountVnd: targetAmountVnd,
        targetDate: targetDate,
        allowNegativeException: allowNegativeException,
        priority: priority,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateEnvelope({
    required int id,
    required String name,
    required EnvelopePolicy policy,
    int? targetAmountVnd,
    DateTime? targetDate,
    required bool allowNegativeException,
    int priority = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.updateEnvelope(
        id: id,
        name: name,
        policy: policy,
        targetAmountVnd: targetAmountVnd,
        targetDate: targetDate,
        allowNegativeException: allowNegativeException,
        priority: priority,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> archiveEnvelope(int id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(envelopeRepositoryProvider);
      await repo.archiveEnvelope(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final envelopeControllerProvider =
    NotifierProvider<EnvelopeController, AsyncValue<void>>(
  EnvelopeController.new,
);
