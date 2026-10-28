import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/security/backup_payload_models.dart';
import 'package:dongtien/core/security/encrypted_backup_service.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createInMemoryDb() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    ),
  );
}

void main() {
  group('EncryptedBackupService — Scenarios 13 & 14', () {
    test(
        'Scenario 13: Export AES-256-GCM + PBKDF2 (120,000 iterations) backup and restore into wiped DB reproduces 100% of state',
        () async {
      final sourceDb = _createInMemoryDb();
      final targetDb = _createInMemoryDb();
      addTearDown(() async {
        await sourceDb.close();
        await targetDb.close();
      });

      // 1. Populate source database across all tables
      final bankId = await sourceDb.into(sourceDb.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Vietcombank',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1700000000000,
            ),
          );

      await sourceDb.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: bankId,
          amountVnd: 12000000,
          occurredAt: 1700000001000,
        ),
      );

      final cats = await sourceDb.select(sourceDb.categories).get();
      final foodCat = cats.firstWhere((c) => c.kind == 'EXPENSE');

      await sourceDb.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: bankId,
          categoryId: foodCat.id,
          amountVnd: 250000,
          occurredAt: 1700000002000,
          description: 'Ăn trưa',
        ),
      );

      final envId = await sourceDb.into(sourceDb.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ khẩn cấp',
              policy: 'PROTECTED',
              targetAmountVnd: const Value(5000000),
            ),
          );

      final totalLiquid = await sourceDb.ledgerDao.getTotalLiquidAssets();
      await sourceDb.envelopeDao.allocate(
        envelopeId: envId,
        amountVnd: 2000000,
        totalLiquidAssetsVnd: totalLiquid,
      );

      await (sourceDb.update(sourceDb.settings)..where((s) => s.id.equals(1)))
          .write(
        const SettingsCompanion(minimumCashBufferVnd: Value(500000)),
      );

      // 2. Export encrypted backup JSON
      final backupJson = await EncryptedBackupService.exportBackupToJson(
        db: sourceDb,
        password: 'MatKhauAnToan!2026',
      );

      final outer = jsonDecode(backupJson) as Map<String, dynamic>;
      expect(outer['magic'], equals('DONGTIEN_ENC_V1'));
      expect(outer['kdf'], equals('PBKDF2-HMAC-SHA256'));
      expect(outer['kdfIterations'], equals(120000));
      expect(outer['cipher'], equals('AES-256-GCM'));

      // 3. Restore into targetDb
      final validation = await EncryptedBackupService.validateAndRestoreBackup(
        db: targetDb,
        jsonContent: backupJson,
        password: 'MatKhauAnToan!2026',
      );

      expect(validation.transactionsCount, equals(2));
      expect(validation.envelopesCount, equals(1));

      final restoredLiquid = await targetDb.ledgerDao.getTotalLiquidAssets();
      expect(restoredLiquid, equals(11750000));

      final restoredEnv = await targetDb.envelopeDao.getEnvelopeById(envId);
      expect(restoredEnv?.reservedBalanceVnd, equals(2000000));

      final restoredSetting =
          await targetDb.select(targetDb.settings).getSingle();
      expect(restoredSetting.minimumCashBufferVnd, equals(500000));
    });

    test(
        'Scenario 14: 1-byte flip in ciphertextB64 or macB64 or wrong password throws SecretBoxAuthenticationError / InvalidCredentialsException and leaves existing DB untouched',
        () async {
      final db = _createInMemoryDb();
      addTearDown(() async => db.close());

      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1700000000000,
            ),
          );
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 5000000,
          occurredAt: 1700000001000,
        ),
      );

      final validBackup = await EncryptedBackupService.exportBackupToJson(
        db: db,
        password: 'CorrectPassword123',
      );

      // Wrong password rejection
      await expectLater(
        () => EncryptedBackupService.validateAndRestoreBackup(
          db: db,
          jsonContent: validBackup,
          password: 'WrongPassword999',
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );

      // Flip 1 byte in ciphertextB64
      final map1 = jsonDecode(validBackup) as Map<String, dynamic>;
      final cipherBytes = base64Decode(map1['ciphertextB64'] as String);
      cipherBytes[0] ^= 0xFF;
      map1['ciphertextB64'] = base64Encode(cipherBytes);
      final tamperedCipherJson = jsonEncode(map1);

      await expectLater(
        () => EncryptedBackupService.validateAndRestoreBackup(
          db: db,
          jsonContent: tamperedCipherJson,
          password: 'CorrectPassword123',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );

      // Flip 1 byte in macB64
      final map2 = jsonDecode(validBackup) as Map<String, dynamic>;
      final macBytes = base64Decode(map2['macB64'] as String);
      macBytes[0] ^= 0xFF;
      map2['macB64'] = base64Encode(macBytes);
      final tamperedMacJson = jsonEncode(map2);

      await expectLater(
        () => EncryptedBackupService.validateAndRestoreBackup(
          db: db,
          jsonContent: tamperedMacJson,
          password: 'CorrectPassword123',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );

      // Verify existing DB state is 100% untouched (still 5.000.000 ₫)
      final remainingLiquid = await db.ledgerDao.getTotalLiquidAssets();
      expect(remainingLiquid, equals(5000000));
    });
  });
}
