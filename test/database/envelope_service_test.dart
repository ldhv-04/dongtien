import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/envelopes/envelope_exceptions.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('EnvelopeDao & Virtual Funds Decoupled Invariants', () {
    test(
        'Scenario 5: Virtual Fund Allocation (1.000.000 ₫) generates ZERO journal postings',
        () async {
      // 1. Setup liquid assets: 10.000.000 ₫
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      final initialPostingsCount =
          (await db.select(db.journalPostings).get()).length;
      expect(
          initialPostingsCount, equals(2)); // Debit Cash, Credit Equity Opening

      final totalLiquid = await db.ledgerDao.getTotalLiquidAssets();
      expect(totalLiquid, equals(10000000));

      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ tiết kiệm',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(0),
            ),
          );

      // Available-to-allocate = 10.000.000 ₫ - 0 - 0 = 10.000.000 ₫
      final initialAvailable =
          await db.envelopeDao.getAvailableToAllocate(totalLiquid);
      expect(initialAvailable, equals(10000000));

      // 2. Allocate 1.000.000 ₫ into envelope
      final movementId = await db.envelopeDao.allocate(
        envelopeId: envId,
        amountVnd: 1000000,
        totalLiquidAssetsVnd: totalLiquid,
      );
      expect(movementId, isPositive);

      // 3. Verify Decoupled Invariant:
      // ZERO new journal postings!
      final afterPostingsCount =
          (await db.select(db.journalPostings).get()).length;
      expect(afterPostingsCount, equals(initialPostingsCount));

      // Liquid assets completely unchanged!
      final afterLiquid = await db.ledgerDao.getTotalLiquidAssets();
      expect(afterLiquid, equals(10000000));

      // Envelope reserved balance increased
      final env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(1000000));

      // Available-to-Allocate decreased by 1.000.000 ₫
      final afterAvailable =
          await db.envelopeDao.getAvailableToAllocate(afterLiquid);
      expect(afterAvailable, equals(9000000));

      // Movement record verified
      final movement = await (db.select(db.envelopeMovements)
            ..where((m) => m.id.equals(movementId)))
          .getSingle();
      expect(movement.movementType, equals('ALLOCATE'));
      expect(movement.amountVnd, equals(1000000));
      expect(movement.destEnvelopeId, equals(envId));
      expect(movement.sourceEnvelopeId, isNull);
    });

    test(
        'Release virtual funds back to Available-to-Allocate generates ZERO postings',
        () async {
      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ học tập',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(2000000),
            ),
          );

      final initialPostings = await db.select(db.journalPostings).get();

      // Release 500.000 ₫
      final movementId = await db.envelopeDao.release(
        envelopeId: envId,
        amountVnd: 500000,
      );
      expect(movementId, isPositive);

      // Postings untouched
      final afterPostings = await db.select(db.journalPostings).get();
      expect(afterPostings.length, equals(initialPostings.length));

      // Reserved balance = 1.500.000 ₫
      final env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(1500000));

      // Movement verified
      final movement = await (db.select(db.envelopeMovements)
            ..where((m) => m.id.equals(movementId)))
          .getSingle();
      expect(movement.movementType, equals('RELEASE'));
      expect(movement.amountVnd, equals(500000));
      expect(movement.sourceEnvelopeId, equals(envId));
      expect(movement.destEnvelopeId, isNull);
    });

    test('Transfer between envelopes reallocates reserves with ZERO postings',
        () async {
      final envA = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ A',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(1000000),
            ),
          );
      final envB = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ B',
              policy: 'FLEXIBLE',
              reservedBalanceVnd: const Value(500000),
            ),
          );

      final movementId = await db.envelopeDao.transfer(
        fromEnvelopeId: envA,
        toEnvelopeId: envB,
        amountVnd: 300000,
      );
      expect(movementId, isPositive);

      final resA = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envA)))
          .getSingle();
      final resB = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envB)))
          .getSingle();

      expect(resA.reservedBalanceVnd, equals(700000));
      expect(resB.reservedBalanceVnd, equals(800000));

      final movement = await (db.select(db.envelopeMovements)
            ..where((m) => m.id.equals(movementId)))
          .getSingle();
      expect(movement.movementType, equals('TRANSFER'));
      expect(movement.amountVnd, equals(300000));
      expect(movement.sourceEnvelopeId, equals(envA));
      expect(movement.destEnvelopeId, equals(envB));
    });

    test('Over-allocation throws OverAllocationException', () async {
      // 5M liquid assets
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 5000000,
          occurredAt: 1000,
        ),
      );

      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ lớn',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(0),
            ),
          );

      // Attempt to allocate 6M (exceeds 5M available)
      expect(
        () => db.envelopeDao.allocate(
          envelopeId: envId,
          amountVnd: 6000000,
          totalLiquidAssetsVnd: 5000000,
        ),
        throwsA(isA<OverAllocationException>()),
      );
    });

    test('Spending deficit exception when negative exception is disabled',
        () async {
      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ nghiêm ngặt',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(500000),
              allowNegativeException: const Value(false),
            ),
          );

      // Attempt to release 600k from 500k reserve
      expect(
        () => db.envelopeDao.release(
          envelopeId: envId,
          amountVnd: 600000,
        ),
        throwsA(isA<SpendingDeficitException>()),
      );
    });

    test('Deficit allowed when allowNegativeException is true', () async {
      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ cho phép âm',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(500000),
              allowNegativeException: const Value(true),
            ),
          );

      final movementId = await db.envelopeDao.release(
        envelopeId: envId,
        amountVnd: 600000,
      );
      expect(movementId, isPositive);

      final env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(-100000));
    });
  });
}
