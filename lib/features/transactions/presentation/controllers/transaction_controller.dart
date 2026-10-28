import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../domain/ledger/post_transaction_command.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// Controller for transaction mutations (post, void, edit, audit chain resolution).
class TransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Posts a transaction with idempotency check.
  Future<int> postTransaction(PostTransactionCommand command) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final dao = ref.read(ledgerDaoProvider);

      // Idempotency guard: if idempotencyKey already exists, return existing transaction ID
      if (command.idempotencyKey != null) {
        final existing = await (db.select(db.journalTransactions)
              ..where((t) => t.idempotencyKey.equals(command.idempotencyKey!)))
            .getSingleOrNull();
        if (existing != null) {
          state = const AsyncValue.data(null);
          return existing.id;
        }
      }

      final txId = await dao.postTransactionCommand(command);
      state = const AsyncValue.data(null);
      return txId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Voids an active transaction, creating an audit-preserving REVERSAL.
  Future<int> voidTransaction(int transactionId) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(ledgerDaoProvider);
      final reversalId = await dao.voidTransaction(transactionId);
      state = const AsyncValue.data(null);
      return reversalId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Edits an active transaction by voiding the original (SUPERSEDED) and posting the replacement.
  Future<int> editTransaction({
    required int originalTxId,
    required PostTransactionCommand newCommand,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(ledgerDaoProvider);
      final newTxId = await dao.editTransaction(
        originalTxId: originalTxId,
        txType: newCommand.txType.dbValue,
        description: newCommand.description,
        occurredAt: newCommand.occurredAt,
        newPostings: newCommand.postings,
        linkedEnvelopeId: newCommand.linkedEnvelopeId,
        envelopeMovementType: newCommand.envelopeMovementType,
      );
      state = const AsyncValue.data(null);
      return newTxId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Resolves the complete audit chain (original, reversals, and replacements) for a transaction.
  Future<List<JournalTransaction>> resolveAuditChain(int txId) async {
    final db = ref.read(databaseProvider);
    final Set<int> allTxIds = {txId};
    bool expanded = true;

    while (expanded) {
      final beforeCount = allTxIds.length;
      final related = await (db.select(db.journalTransactions)
            ..where((t) =>
                t.id.isIn(allTxIds) |
                t.reversesTxId.isIn(allTxIds) |
                t.replacedByTxId.isIn(allTxIds)))
          .get();

      for (final r in related) {
        allTxIds.add(r.id);
        if (r.reversesTxId != null) allTxIds.add(r.reversesTxId!);
        if (r.replacedByTxId != null) allTxIds.add(r.replacedByTxId!);
      }
      expanded = allTxIds.length > beforeCount;
    }

    return (db.select(db.journalTransactions)
          ..where((t) => t.id.isIn(allTxIds))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
          ]))
        .get();
  }
}

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, void>(
  TransactionController.new,
);
