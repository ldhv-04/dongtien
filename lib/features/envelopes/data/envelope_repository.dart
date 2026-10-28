import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../domain/envelopes/envelope_policy.dart';

/// Repository abstracting persistence for envelopes and movements.
class EnvelopeRepository {
  final AppDatabase _db;
  EnvelopeRepository(this._db);

  Stream<List<Envelope>> watchAllEnvelopes() =>
      _db.envelopeDao.watchAllEnvelopes();
  Future<List<Envelope>> getAllEnvelopes() => _db.envelopeDao.getAllEnvelopes();
  Future<Envelope?> getEnvelopeById(int id) =>
      _db.envelopeDao.getEnvelopeById(id);
  Stream<List<EnvelopeMovement>> watchMovements(int id) =>
      _db.envelopeDao.watchMovementsForEnvelope(id);

  Stream<int> watchTotalLiquidAssets() =>
      _db.ledgerDao.watchTotalLiquidAssets();
  Stream<Setting> watchSettings() =>
      (_db.select(_db.settings)..where((s) => s.id.equals(1))).watchSingle();

  Future<int> allocate({
    required int envelopeId,
    required int amountVnd,
    required int totalLiquidAssetsVnd,
  }) =>
      _db.envelopeDao.allocate(
        envelopeId: envelopeId,
        amountVnd: amountVnd,
        totalLiquidAssetsVnd: totalLiquidAssetsVnd,
      );

  Future<int> release({
    required int envelopeId,
    required int amountVnd,
  }) =>
      _db.envelopeDao.release(
        envelopeId: envelopeId,
        amountVnd: amountVnd,
      );

  Future<int> transfer({
    required int fromEnvelopeId,
    required int toEnvelopeId,
    required int amountVnd,
  }) =>
      _db.envelopeDao.transfer(
        fromEnvelopeId: fromEnvelopeId,
        toEnvelopeId: toEnvelopeId,
        amountVnd: amountVnd,
      );

  Future<int> createEnvelope({
    required String name,
    required EnvelopePolicy policy,
    int? targetAmountVnd,
    DateTime? targetDate,
    bool allowNegativeException = false,
    int priority = 1,
  }) async {
    return _db.into(_db.envelopes).insert(
          EnvelopesCompanion.insert(
            name: name,
            policy: policy.dbValue,
            reservedBalanceVnd: const Value(0),
            allowNegativeException: Value(allowNegativeException),
            targetAmountVnd: Value(targetAmountVnd),
            targetDateMs: Value(targetDate?.millisecondsSinceEpoch),
            priority: Value(priority),
            isArchived: const Value(false),
          ),
        );
  }

  Future<void> updateEnvelope({
    required int id,
    required String name,
    required EnvelopePolicy policy,
    int? targetAmountVnd,
    DateTime? targetDate,
    required bool allowNegativeException,
    int priority = 1,
  }) async {
    await (_db.update(_db.envelopes)..where((e) => e.id.equals(id))).write(
      EnvelopesCompanion(
        name: Value(name),
        policy: Value(policy.dbValue),
        targetAmountVnd: Value(targetAmountVnd),
        targetDateMs: Value(targetDate?.millisecondsSinceEpoch),
        allowNegativeException: Value(allowNegativeException),
        priority: Value(priority),
      ),
    );
  }

  Future<void> archiveEnvelope(int id) async {
    await (_db.update(_db.envelopes)..where((e) => e.id.equals(id))).write(
      const EnvelopesCompanion(isArchived: Value(true)),
    );
  }
}
