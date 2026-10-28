import 'package:drift/drift.dart';
import '../../../domain/envelopes/available_to_allocate.dart';
import '../../../domain/envelopes/envelope_exceptions.dart';
import '../app_database.dart';

part 'envelope_dao.g.dart';

@DriftAccessor(tables: [
  Envelopes,
  EnvelopeMovements,
  Settings,
  LedgerAccounts,
  JournalPostings,
])
class EnvelopeDao extends DatabaseAccessor<AppDatabase>
    with _$EnvelopeDaoMixin {
  EnvelopeDao(super.db);

  /// Computes the current Available-to-Allocate amount:
  /// `total_liquid_assets - total_envelope_reserves - minimum_cash_buffer_vnd`
  Future<int> getAvailableToAllocate(int totalLiquidAssetsVnd) async {
    final settingsRow = await select(settings).getSingle();
    final envelopesList = await (select(envelopes)
          ..where((e) => e.isArchived.equals(false)))
        .get();
    final totalReserved =
        envelopesList.fold<int>(0, (sum, e) => sum + e.reservedBalanceVnd);

    return AvailableToAllocateCalculator.calculate(
      totalLiquidAssetsVnd: totalLiquidAssetsVnd,
      totalEnvelopeReservesVnd: totalReserved,
      minimumCashBufferVnd: settingsRow.minimumCashBufferVnd,
    );
  }

  /// Allocates virtual funds into an envelope.
  ///
  /// CRITICAL: Generates ZERO general ledger postings.
  /// Throws [OverAllocationException] if `amountVnd > max(0, availableToAllocate)`.
  Future<int> allocate({
    required int envelopeId,
    required int amountVnd,
    required int totalLiquidAssetsVnd,
  }) async {
    return db.transaction(() async {
      final available = await getAvailableToAllocate(totalLiquidAssetsVnd);
      AvailableToAllocateCalculator.validateAllocation(
        allocateAmountVnd: amountVnd,
        availableToAllocateVnd: available,
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final movementId = await into(envelopeMovements).insert(
        EnvelopeMovementsCompanion.insert(
          movementType: 'ALLOCATE',
          amountVnd: amountVnd,
          destEnvelopeId: Value(envelopeId),
          occurredAt: nowMs,
        ),
      );

      await customUpdate(
        'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ? WHERE id = ?',
        variables: [Variable.withInt(amountVnd), Variable.withInt(envelopeId)],
        updates: {envelopes},
      );

      return movementId;
    });
  }

  /// Releases virtual funds from an envelope back to Available-to-Allocate.
  ///
  /// CRITICAL: Generates ZERO general ledger postings.
  /// Throws [SpendingDeficitException] if `amountVnd > reservedBalance` and `allowNegativeException` is false.
  Future<int> release({
    required int envelopeId,
    required int amountVnd,
  }) async {
    if (amountVnd <= 0) {
      throw ArgumentError.value(
        amountVnd,
        'amountVnd',
        'Release amount must be strictly positive (> 0 ₫)',
      );
    }

    return db.transaction(() async {
      final target = await (select(envelopes)
            ..where((e) => e.id.equals(envelopeId)))
          .getSingle();
      if (amountVnd > target.reservedBalanceVnd &&
          !target.allowNegativeException) {
        throw SpendingDeficitException(
          requestedVnd: amountVnd,
          currentReservedVnd: target.reservedBalanceVnd,
          envelopeId: envelopeId,
          message:
              'Release amount exceeds reserved balance and negative exceptions are disabled',
        );
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final movementId = await into(envelopeMovements).insert(
        EnvelopeMovementsCompanion.insert(
          movementType: 'RELEASE',
          amountVnd: amountVnd,
          sourceEnvelopeId: Value(envelopeId),
          occurredAt: nowMs,
        ),
      );

      await customUpdate(
        'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
        variables: [Variable.withInt(amountVnd), Variable.withInt(envelopeId)],
        updates: {envelopes},
      );

      return movementId;
    });
  }

  /// Transfers reserved funds between two envelopes.
  ///
  /// CRITICAL: Generates ZERO general ledger postings.
  /// Throws [InvalidEnvelopeOperationException] if source == destination.
  /// Throws [SpendingDeficitException] if `amountVnd > source.reservedBalance` and negative exception disabled.
  Future<int> transfer({
    required int fromEnvelopeId,
    required int toEnvelopeId,
    required int amountVnd,
  }) async {
    return db.transaction(() async {
      final source = await (select(envelopes)
            ..where((e) => e.id.equals(fromEnvelopeId)))
          .getSingle();

      AvailableToAllocateCalculator.validateTransfer(
        fromEnvelopeId: fromEnvelopeId,
        toEnvelopeId: toEnvelopeId,
        amountVnd: amountVnd,
        sourceReservedVnd: source.reservedBalanceVnd,
        allowNegativeException: source.allowNegativeException,
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final movementId = await into(envelopeMovements).insert(
        EnvelopeMovementsCompanion.insert(
          movementType: 'TRANSFER',
          amountVnd: amountVnd,
          sourceEnvelopeId: Value(fromEnvelopeId),
          destEnvelopeId: Value(toEnvelopeId),
          occurredAt: nowMs,
        ),
      );

      await customUpdate(
        'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd - ? WHERE id = ?',
        variables: [
          Variable.withInt(amountVnd),
          Variable.withInt(fromEnvelopeId)
        ],
        updates: {envelopes},
      );
      await customUpdate(
        'UPDATE envelopes SET reserved_balance_vnd = reserved_balance_vnd + ? WHERE id = ?',
        variables: [
          Variable.withInt(amountVnd),
          Variable.withInt(toEnvelopeId)
        ],
        updates: {envelopes},
      );

      return movementId;
    });
  }

  /// Watches all active envelopes ordered by priority.
  Stream<List<Envelope>> watchAllEnvelopes() {
    return (select(envelopes)
          ..where((e) => e.isArchived.equals(false))
          ..orderBy([(e) => OrderingTerm(expression: e.priority)]))
        .watch();
  }

  /// Gets all active envelopes.
  Future<List<Envelope>> getAllEnvelopes() {
    return (select(envelopes)
          ..where((e) => e.isArchived.equals(false))
          ..orderBy([(e) => OrderingTerm(expression: e.priority)]))
        .get();
  }

  /// Finds an envelope by ID.
  Future<Envelope?> getEnvelopeById(int id) {
    return (select(envelopes)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  /// Watches movements associated with an envelope.
  Stream<List<EnvelopeMovement>> watchMovementsForEnvelope(int envelopeId) {
    return (select(envelopeMovements)
          ..where((m) =>
              m.sourceEnvelopeId.equals(envelopeId) |
              m.destEnvelopeId.equals(envelopeId))
          ..orderBy([
            (m) =>
                OrderingTerm(expression: m.occurredAt, mode: OrderingMode.desc),
            (m) => OrderingTerm(expression: m.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Gets movements associated with an envelope.
  Future<List<EnvelopeMovement>> getMovementsForEnvelope(int envelopeId) {
    return (select(envelopeMovements)
          ..where((m) =>
              m.sourceEnvelopeId.equals(envelopeId) |
              m.destEnvelopeId.equals(envelopeId))
          ..orderBy([
            (m) =>
                OrderingTerm(expression: m.occurredAt, mode: OrderingMode.desc),
            (m) => OrderingTerm(expression: m.id, mode: OrderingMode.desc),
          ]))
        .get();
  }
}
