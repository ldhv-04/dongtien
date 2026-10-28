import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'backup_payload_models.dart';

/// Service performing off-main-thread authenticated encryption (`Isolate.run`),
/// structural invariant validation, and atomic database restore.
class EncryptedBackupService {
  const EncryptedBackupService._();

  /// Exports all 9 SQLite tables into an authenticated AES-256-GCM encrypted JSON string.
  /// Runs KDF derivation, encryption, and JSON serialization inside [Isolate.run].
  static Future<String> exportBackupToJson({
    required AppDatabase db,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError('Backup password must not be empty');
    }

    // 1. Gather all 9 tables on main isolate
    final accounts = await db.select(db.ledgerAccounts).get();
    final categories = await db.select(db.categories).get();
    final transactions = await db.select(db.journalTransactions).get();
    final postings = await db.select(db.journalPostings).get();
    final envelopes = await db.select(db.envelopes).get();
    final movements = await db.select(db.envelopeMovements).get();
    final budgets = await db.select(db.categoryBudgets).get();
    final scheduledItems = await db.select(db.scheduledItems).get();
    final settingsRows = await db.select(db.settings).get();

    final payloadMap = <String, dynamic>{
      'ledger_accounts': accounts.map((r) => r.toJson()).toList(),
      'categories': categories.map((r) => r.toJson()).toList(),
      'journal_transactions': transactions.map((r) => r.toJson()).toList(),
      'journal_postings': postings.map((r) => r.toJson()).toList(),
      'envelopes': envelopes.map((r) => r.toJson()).toList(),
      'envelope_movements': movements.map((r) => r.toJson()).toList(),
      'category_budgets': budgets.map((r) => r.toJson()).toList(),
      'scheduled_items': scheduledItems.map((r) => r.toJson()).toList(),
      'settings': settingsRows.map((r) => r.toJson()).toList(),
    };

    final createdAtIso = DateTime.now().toIso8601String();

    // 2. Offload heavy PBKDF2 + AES-256-GCM encryption to background Isolate
    return Isolate.run(() async {
      final plaintextBytes = utf8.encode(jsonEncode(payloadMap));

      final rng = Random.secure();
      final salt = Uint8List.fromList(
        List<int>.generate(16, (_) => rng.nextInt(256)),
      );
      final nonce = Uint8List.fromList(
        List<int>.generate(12, (_) => rng.nextInt(256)),
      );

      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: EncryptedBackupEnvelope.defaultIterations,
        bits: 256,
      );

      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );

      final cipher = AesGcm.with256bits();
      final secretBox = await cipher.encrypt(
        plaintextBytes,
        secretKey: secretKey,
        nonce: nonce,
      );

      final envelope = EncryptedBackupEnvelope(
        magic: EncryptedBackupEnvelope.expectedMagic,
        formatVersion: 1,
        schemaVersion: 1,
        createdAtIso: createdAtIso,
        kdf: EncryptedBackupEnvelope.expectedKdf,
        kdfIterations: EncryptedBackupEnvelope.defaultIterations,
        saltB64: base64Encode(salt),
        cipher: EncryptedBackupEnvelope.expectedCipher,
        nonceB64: base64Encode(nonce),
        ciphertextB64: base64Encode(secretBox.cipherText),
        macB64: base64Encode(secretBox.mac.bytes),
      );

      return const JsonEncoder.withIndent('  ').convert(envelope.toJson());
    });
  }

  /// Validates and decrypts the backup inside [Isolate.run] without touching SQLite.
  /// Returns [BackupValidationResult] if valid, or throws:
  /// - [BackupSizeExceededException] if > 25 MB
  /// - [InvalidBackupFormatException] if outer wrapper is malformed
  /// - [InvalidCredentialsException] (subclass of [SecretBoxAuthenticationError]) if wrong password or tampered
  /// - [BackupCorruptException] if inner payload fails structural/accounting invariants
  static Future<BackupValidationResult> validateBackup({
    required String jsonContent,
    required String password,
  }) async {
    final byteLen = utf8.encode(jsonContent).length;
    if (byteLen > EncryptedBackupEnvelope.maxFileSizeBytes) {
      throw BackupSizeExceededException(
        actualBytes: byteLen,
        maxBytes: EncryptedBackupEnvelope.maxFileSizeBytes,
      );
    }

    return Isolate.run(() async {
      final Map<String, dynamic> outerMap;
      try {
        final decoded = jsonDecode(jsonContent);
        if (decoded is! Map<String, dynamic>) {
          throw const InvalidBackupFormatException(
            'Outer backup JSON is not an object',
          );
        }
        outerMap = decoded;
      } on FormatException catch (e) {
        throw InvalidBackupFormatException('Invalid outer JSON: ${e.message}');
      }

      final envelope = EncryptedBackupEnvelope.fromJson(outerMap);

      final Uint8List salt;
      final Uint8List nonce;
      final Uint8List cipherText;
      final Uint8List macBytes;
      try {
        salt = base64Decode(envelope.saltB64);
        nonce = base64Decode(envelope.nonceB64);
        cipherText = base64Decode(envelope.ciphertextB64);
        macBytes = base64Decode(envelope.macB64);
      } catch (e) {
        throw InvalidCredentialsException(
            'Malformed base64 cryptographic data');
      }

      if (salt.length != 16 || nonce.length != 12 || macBytes.length != 16) {
        throw InvalidCredentialsException(
          'Invalid salt/nonce/MAC length in backup envelope',
        );
      }

      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: envelope.kdfIterations,
        bits: 256,
      );

      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );

      final cipher = AesGcm.with256bits();
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final List<int> decryptedBytes;
      try {
        decryptedBytes = await cipher.decrypt(
          secretBox,
          secretKey: secretKey,
        );
      } on SecretBoxAuthenticationError {
        throw InvalidCredentialsException(
          'Authentication failed: wrong password or tampered backup payload',
        );
      }

      final Map<String, dynamic> innerPayload;
      try {
        final decoded = jsonDecode(utf8.decode(decryptedBytes));
        if (decoded is! Map<String, dynamic>) {
          throw const BackupCorruptException(
              'Decrypted payload is not a JSON map');
        }
        innerPayload = decoded;
      } catch (e) {
        if (e is BackupCorruptException) rethrow;
        throw BackupCorruptException('Corrupt decrypted JSON: $e');
      }

      // Stage 4: In-memory structural & accounting invariant validation
      _validatePayloadInvariants(innerPayload);

      return BackupValidationResult(
        createdAtIso: envelope.createdAtIso,
        schemaVersion: envelope.schemaVersion,
        accountsCount: (innerPayload['ledger_accounts'] as List).length,
        categoriesCount: (innerPayload['categories'] as List).length,
        transactionsCount:
            (innerPayload['journal_transactions'] as List).length,
        postingsCount: (innerPayload['journal_postings'] as List).length,
        envelopesCount: (innerPayload['envelopes'] as List).length,
        movementsCount: (innerPayload['envelope_movements'] as List).length,
        budgetsCount: (innerPayload['category_budgets'] as List).length,
        scheduledItemsCount: (innerPayload['scheduled_items'] as List).length,
        rawPayload: innerPayload,
      );
    });
  }

  static void _validatePayloadInvariants(Map<String, dynamic> payload) {
    const requiredTables = [
      'ledger_accounts',
      'categories',
      'journal_transactions',
      'journal_postings',
      'envelopes',
      'envelope_movements',
      'category_budgets',
      'scheduled_items',
      'settings',
    ];

    for (final table in requiredTables) {
      if (payload[table] is! List) {
        throw BackupCorruptException('Missing or invalid table array: $table');
      }
    }

    final accounts =
        (payload['ledger_accounts'] as List).cast<Map<String, dynamic>>();
    final categories =
        (payload['categories'] as List).cast<Map<String, dynamic>>();
    final transactions =
        (payload['journal_transactions'] as List).cast<Map<String, dynamic>>();
    final postings =
        (payload['journal_postings'] as List).cast<Map<String, dynamic>>();
    final envelopes =
        (payload['envelopes'] as List).cast<Map<String, dynamic>>();
    final movements =
        (payload['envelope_movements'] as List).cast<Map<String, dynamic>>();

    final accountIds = <int>{};
    for (final a in accounts) {
      final id = a['id'] as int?;
      final creditLimit = a['creditLimit'] as int? ?? 0;
      if (id == null || creditLimit < 0) {
        throw const BackupCorruptException('Invalid account row in backup');
      }
      accountIds.add(id);
    }

    final categoryIds = <int>{};
    for (final c in categories) {
      final id = c['id'] as int?;
      final ledgerAccountId = c['ledgerAccountId'] as int?;
      if (id == null ||
          ledgerAccountId == null ||
          !accountIds.contains(ledgerAccountId)) {
        throw const BackupCorruptException(
          'Category FK ledgerAccountId failed validation',
        );
      }
      categoryIds.add(id);
    }

    final envelopeIds = <int>{};
    for (final e in envelopes) {
      final id = e['id'] as int?;
      final reserved = e['reservedBalanceVnd'] as int? ?? 0;
      final allowNeg = e['allowNegativeException'] as bool? ?? false;
      if (id == null || (reserved < 0 && !allowNeg)) {
        throw const BackupCorruptException(
          'Envelope row has invalid negative balance without exception',
        );
      }
      envelopeIds.add(id);
    }

    final txIds = <int>{};
    for (final t in transactions) {
      final id = t['id'] as int?;
      if (id == null) {
        throw const BackupCorruptException('Transaction missing id');
      }
      txIds.add(id);
    }

    final debitByTx = <int, int>{};
    final creditByTx = <int, int>{};
    final countByTx = <int, int>{};

    for (final p in postings) {
      final txId = p['transactionId'] as int?;
      final accId = p['accountId'] as int?;
      final debit = p['debitVnd'] as int? ?? -1;
      final credit = p['creditVnd'] as int? ?? -1;
      final catId = p['categoryId'] as int?;
      final envId = p['envelopeId'] as int?;

      if (txId == null || !txIds.contains(txId)) {
        throw BackupCorruptException(
          'Posting references non-existent transaction $txId',
        );
      }
      if (accId == null || !accountIds.contains(accId)) {
        throw BackupCorruptException(
          'Posting references non-existent account $accId',
        );
      }
      if (catId != null && !categoryIds.contains(catId)) {
        throw BackupCorruptException(
          'Posting references non-existent category $catId',
        );
      }
      if (envId != null && !envelopeIds.contains(envId)) {
        throw BackupCorruptException(
          'Posting references non-existent envelope $envId',
        );
      }
      final validOneSided =
          (debit > 0 && credit == 0) || (credit > 0 && debit == 0);
      if (!validOneSided) {
        throw const BackupCorruptException(
          'Posting violates single-sided non-negative integer invariant',
        );
      }

      debitByTx[txId] = (debitByTx[txId] ?? 0) + debit;
      creditByTx[txId] = (creditByTx[txId] ?? 0) + credit;
      countByTx[txId] = (countByTx[txId] ?? 0) + 1;
    }

    for (final txId in txIds) {
      final count = countByTx[txId] ?? 0;
      final sumDebit = debitByTx[txId] ?? 0;
      final sumCredit = creditByTx[txId] ?? 0;
      if (count < 2 || sumDebit <= 0 || sumDebit != sumCredit) {
        throw BackupCorruptException(
          'Transaction #$txId violates double-entry balance invariant: debit=$sumDebit, credit=$sumCredit',
        );
      }
    }

    for (final m in movements) {
      final amt = m['amountVnd'] as int? ?? 0;
      if (amt <= 0) {
        throw const BackupCorruptException(
          'Envelope movement has non-positive amount',
        );
      }
    }
  }

  /// Validates, decrypts (inside [Isolate.run]), and atomically restores the database
  /// inside a single `db.transaction()`.
  static Future<BackupValidationResult> validateAndRestoreBackup({
    required AppDatabase db,
    required String jsonContent,
    required String password,
  }) async {
    // Stages 1-4 execute off-main-thread BEFORE touching SQLite
    final validation = await validateBackup(
      jsonContent: jsonContent,
      password: password,
    );

    await restoreValidatedPayload(db: db, validation: validation);
    return validation;
  }

  /// Executes Stage 6: Atomic Database Restore inside a single `db.transaction()`.
  static Future<void> restoreValidatedPayload({
    required AppDatabase db,
    required BackupValidationResult validation,
  }) async {
    final payload = validation.rawPayload;

    final accounts = (payload['ledger_accounts'] as List)
        .cast<Map<String, dynamic>>()
        .map(LedgerAccount.fromJson)
        .toList();
    final categories = (payload['categories'] as List)
        .cast<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
    final transactions = (payload['journal_transactions'] as List)
        .cast<Map<String, dynamic>>()
        .map(JournalTransaction.fromJson)
        .toList();
    final postings = (payload['journal_postings'] as List)
        .cast<Map<String, dynamic>>()
        .map(JournalPosting.fromJson)
        .toList();
    final envelopes = (payload['envelopes'] as List)
        .cast<Map<String, dynamic>>()
        .map(Envelope.fromJson)
        .toList();
    final movements = (payload['envelope_movements'] as List)
        .cast<Map<String, dynamic>>()
        .map(EnvelopeMovement.fromJson)
        .toList();
    final budgets = (payload['category_budgets'] as List)
        .cast<Map<String, dynamic>>()
        .map(CategoryBudget.fromJson)
        .toList();
    final scheduledItems = (payload['scheduled_items'] as List)
        .cast<Map<String, dynamic>>()
        .map(ScheduledItem.fromJson)
        .toList();
    final settingsRows = (payload['settings'] as List)
        .cast<Map<String, dynamic>>()
        .map(Setting.fromJson)
        .toList();

    await db.transaction(() async {
      // Clear self-referential FKs on journal_transactions first
      await db.customUpdate(
        'UPDATE journal_transactions SET reverses_tx_id = NULL, replaced_by_tx_id = NULL',
        updates: {db.journalTransactions},
      );

      // Delete existing rows in reverse dependency order
      await db.delete(db.envelopeMovements).go();
      await db.delete(db.journalPostings).go();
      await db.delete(db.scheduledItems).go();
      await db.delete(db.categoryBudgets).go();
      await db.delete(db.journalTransactions).go();
      await db.delete(db.envelopes).go();
      await db.delete(db.categories).go();
      await db.delete(db.ledgerAccounts).go();
      await db.delete(db.settings).go();

      // Insert validated rows in topological order
      await db.batch((b) {
        b.insertAll(db.ledgerAccounts, accounts);
        b.insertAll(db.categories, categories);
        b.insertAll(db.envelopes, envelopes);
      });

      // Insert transactions with self-referential FKs nulled initially in case of forward references
      for (final tx in transactions) {
        await db.into(db.journalTransactions).insert(
              tx.toCompanion(false).copyWith(
                    reversesTxId: const Value(null),
                    replacedByTxId: const Value(null),
                  ),
            );
      }

      // Restore self-referential FKs on transactions
      for (final tx in transactions) {
        if (tx.reversesTxId != null || tx.replacedByTxId != null) {
          await (db.update(db.journalTransactions)
                ..where((t) => t.id.equals(tx.id)))
              .write(
            JournalTransactionsCompanion(
              reversesTxId: Value(tx.reversesTxId),
              replacedByTxId: Value(tx.replacedByTxId),
            ),
          );
        }
      }

      await db.batch((b) {
        b.insertAll(db.journalPostings, postings);
        b.insertAll(db.categoryBudgets, budgets);
        b.insertAll(db.scheduledItems, scheduledItems);
        b.insertAll(db.envelopeMovements, movements);
        b.insertAll(db.settings, settingsRows);
      });
    });
  }
}
