import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:dongtien/core/database/app_database.dart';

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

  // Helper to create a valid transaction
  Future<int> createDummyTx({String txType = 'EXPENSE'}) async {
    return db.into(db.journalTransactions).insert(
          JournalTransactionsCompanion.insert(
            txType: txType,
            description: const Value('Valid Tx'),
            occurredAt: 1000,
            createdAt: 1000,
          ),
        );
  }

  // Helper to create a valid cash account
  Future<int> createCashAccount({String name = 'Tiền mặt'}) async {
    return db.into(db.ledgerAccounts).insert(
          LedgerAccountsCompanion.insert(
            name: name,
            kind: 'ASSET_CASH',
            isLiquid: const Value(true),
            createdAt: 1000,
          ),
        );
  }

  // Helper to create a valid envelope
  Future<int> createDummyEnvelope(
      {String name = 'Quỹ Tiết Kiệm', String policy = 'PROTECTED'}) async {
    return db.into(db.envelopes).insert(
          EnvelopesCompanion.insert(
            name: name,
            policy: policy,
            reservedBalanceVnd: const Value(0),
          ),
        );
  }

  group('Group 1: Foreign Key Enforcement & Violations', () {
    test('inserting posting with invalid account_id throws SqliteException',
        () async {
      final txId = await createDummyTx();
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: 99999, // Non-existent account
                  debitVnd: const Value(100000),
                  creditVnd: const Value(0),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test('inserting posting with invalid transaction_id throws SqliteException',
        () async {
      final accId = await createCashAccount();
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: 88888, // Non-existent transaction
                  accountId: accId,
                  debitVnd: const Value(100000),
                  creditVnd: const Value(0),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test('inserting posting with invalid category_id throws SqliteException',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: accId,
                  debitVnd: const Value(100000),
                  creditVnd: const Value(0),
                  categoryId: const Value(77777), // Non-existent category
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test('inserting posting with invalid envelope_id throws SqliteException',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: accId,
                  debitVnd: const Value(100000),
                  creditVnd: const Value(0),
                  envelopeId: const Value(66666), // Non-existent envelope
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'inserting category with invalid ledger_account_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.categories).insert(
                CategoriesCompanion.insert(
                  name: 'Orphan Category',
                  kind: 'EXPENSE',
                  ledgerAccountId: 55555, // Non-existent
                  iconCode: 0xe532,
                  colorHex: '#E86B1C',
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'inserting category_budgets with invalid category_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.categoryBudgets).insert(
                CategoryBudgetsCompanion.insert(
                  categoryId: 44444, // Non-existent category
                  yearMonth: 202611,
                  limitVnd: 5000000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'inserting envelope_movements with invalid source_envelope_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.envelopeMovements).insert(
                EnvelopeMovementsCompanion.insert(
                  movementType: 'RELEASE',
                  amountVnd: 500000,
                  sourceEnvelopeId: const Value(33333), // Non-existent
                  occurredAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'inserting envelope_movements with invalid dest_envelope_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.envelopeMovements).insert(
                EnvelopeMovementsCompanion.insert(
                  movementType: 'ALLOCATE',
                  amountVnd: 500000,
                  destEnvelopeId: const Value(22222), // Non-existent
                  occurredAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'inserting envelope_movements with invalid linked_transaction_id throws SqliteException',
        () async {
      final envId = await createDummyEnvelope();
      expect(
        () async {
          await db.into(db.envelopeMovements).insert(
                EnvelopeMovementsCompanion.insert(
                  movementType: 'SPEND',
                  amountVnd: 200000,
                  sourceEnvelopeId: Value(envId),
                  linkedTransactionId: const Value(11111), // Non-existent tx
                  occurredAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'inserting scheduled_items with invalid category_id or linked_envelope_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.scheduledItems).insert(
                ScheduledItemsCompanion.insert(
                  kind: 'BILL',
                  title: 'Invalid Bill',
                  amountVnd: 100000,
                  dueDateMs: 2000,
                  categoryId: const Value(99999), // Non-existent
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );

      expect(
        () async {
          await db.into(db.scheduledItems).insert(
                ScheduledItemsCompanion.insert(
                  kind: 'BILL',
                  title: 'Invalid Bill 2',
                  amountVnd: 100000,
                  dueDateMs: 2000,
                  linkedEnvelopeId: const Value(99999), // Non-existent
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'inserting journal_transactions with invalid reverses_tx_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.journalTransactions).insert(
                JournalTransactionsCompanion.insert(
                  txType: 'REVERSAL',
                  description: const Value('Bad reversal'),
                  occurredAt: 1000,
                  createdAt: 1000,
                  reversesTxId: const Value(99999), // Non-existent
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'inserting journal_transactions with invalid replaced_by_tx_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.journalTransactions).insert(
                JournalTransactionsCompanion.insert(
                  txType: 'EXPENSE',
                  status: const Value('SUPERSEDED'),
                  description: const Value('Superseded tx'),
                  occurredAt: 1000,
                  createdAt: 1000,
                  replacedByTxId: const Value(99999), // Non-existent
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });
  });

  group('Group 2: Journal Postings CHECK Constraints', () {
    test(
        'inserting posting with debit > 0 AND credit > 0 throws SqliteException',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: accId,
                  debitVnd: const Value(150000),
                  creditVnd: const Value(150000),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test(
        'inserting posting with debit == 0 AND credit == 0 throws SqliteException',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: accId,
                  debitVnd: const Value(0),
                  creditVnd: const Value(0),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('inserting posting with negative debit throws SqliteException',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: accId,
                  debitVnd: const Value(-50000),
                  creditVnd: const Value(0),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('inserting posting with negative credit throws SqliteException',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: accId,
                  debitVnd: const Value(0),
                  creditVnd: const Value(-50000),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('valid one-sided debit posting succeeds', () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();
      final id = await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: accId,
              debitVnd: const Value(250000),
              creditVnd: const Value(0),
            ),
          );
      expect(id, isPositive);
    });

    test('valid one-sided credit posting succeeds', () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();
      final id = await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: accId,
              debitVnd: const Value(0),
              creditVnd: const Value(250000),
            ),
          );
      expect(id, isPositive);
    });
  });

  group('Group 3: Unique Constraints', () {
    test(
        'duplicate (category_id, year_month) in category_budgets throws SqliteException',
        () async {
      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: 1,
              yearMonth: 202610,
              limitVnd: 5000000,
            ),
          );

      expect(
        () async {
          await db.into(db.categoryBudgets).insert(
                CategoryBudgetsCompanion.insert(
                  categoryId: 1,
                  yearMonth: 202610, // Duplicate composite key
                  limitVnd: 7000000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('UNIQUE constraint failed'),
        )),
      );
    });

    test(
        'different year_month for same category is permitted in category_budgets',
        () async {
      final id1 = await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: 1,
              yearMonth: 202610,
              limitVnd: 5000000,
            ),
          );
      final id2 = await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: 1,
              yearMonth: 202611, // Different month
              limitVnd: 5500000,
            ),
          );
      expect(id1, isPositive);
      expect(id2, isPositive);
      expect(id1, isNot(equals(id2)));
    });

    test(
        'different category for same year_month is permitted in category_budgets',
        () async {
      final id1 = await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: 1,
              yearMonth: 202610,
              limitVnd: 5000000,
            ),
          );
      final id2 = await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: 2,
              yearMonth: 202610, // Different category
              limitVnd: 5500000,
            ),
          );
      expect(id1, isPositive);
      expect(id2, isPositive);
      expect(id1, isNot(equals(id2)));
    });

    test('duplicate non-null idempotency_key throws SqliteException', () async {
      await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: const Value('Original'),
              occurredAt: 1,
              createdAt: 1,
              idempotencyKey: const Value('idemp-key-xyz'),
            ),
          );

      expect(
        () async {
          await db.into(db.journalTransactions).insert(
                JournalTransactionsCompanion.insert(
                  txType: 'EXPENSE',
                  description: const Value('Duplicate'),
                  occurredAt: 2,
                  createdAt: 2,
                  idempotencyKey: const Value('idemp-key-xyz'),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('UNIQUE constraint failed'),
        )),
      );
    });

    test('multiple null idempotency_key transactions are permitted', () async {
      final id1 = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: const Value('Null idemp 1'),
              occurredAt: 1,
              createdAt: 1,
            ),
          );
      final id2 = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: const Value('Null idemp 2'),
              occurredAt: 2,
              createdAt: 2,
            ),
          );
      expect(id1, isPositive);
      expect(id2, isPositive);
      expect(id1, isNot(equals(id2)));
    });
  });

  group('Group 4: Settings Table Singleton & Bounds Constraints', () {
    test(
        'inserting second row with id = 2 into settings throws SqliteException',
        () async {
      // Existing row id = 1 is seeded.
      expect(
        () async {
          await db.into(db.settings).insert(
                SettingsCompanion.insert(
                  id: const Value(2), // Fails CHECK (id == 1)
                  minimumCashBufferVnd: const Value(100000),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test(
        'inserting duplicate row with id = 1 into settings throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.settings).insert(
                SettingsCompanion.insert(
                  id: const Value(1), // Primary key collision
                  minimumCashBufferVnd: const Value(100000),
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('UNIQUE constraint failed'),
        )),
      );
    });

    test(
        'updating settings with invalid minimum_cash_buffer_vnd < 0 throws SqliteException',
        () async {
      expect(
        () async {
          await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
            const SettingsCompanion(
              minimumCashBufferVnd: Value(-1),
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test(
        'updating settings with period_start_day outside 1..31 throws SqliteException',
        () async {
      expect(
        () async {
          await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
            const SettingsCompanion(
              periodStartDay: Value(0),
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );

      expect(
        () async {
          await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
            const SettingsCompanion(
              periodStartDay: Value(32),
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test(
        'updating settings with daily_reminder_hour outside 0..23 throws SqliteException',
        () async {
      expect(
        () async {
          await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
            const SettingsCompanion(
              dailyReminderHour: Value(24),
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test(
        'updating settings with daily_reminder_minute outside 0..59 throws SqliteException',
        () async {
      expect(
        () async {
          await (db.update(db.settings)..where((s) => s.id.equals(1))).write(
            const SettingsCompanion(
              dailyReminderMinute: Value(60),
            ),
          );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });
  });

  group('Group 5: Seeding Immutability & Zero Balances', () {
    test(
        'EQUITY_OPENING and default system accounts have strictly 0 ₫ derived balance',
        () async {
      final accounts = await db.select(db.ledgerAccounts).get();
      expect(accounts.length, equals(3));

      // Assert no postings exist in database
      final postings = await db.select(db.journalPostings).get();
      expect(postings, isEmpty);

      // Verify derived balance for EQUITY_OPENING (id = 1) is 0 ₫
      final equityPostings = await (db.select(db.journalPostings)
            ..where((p) => p.accountId.equals(1)))
          .get();
      final equityCredit =
          equityPostings.fold<int>(0, (s, p) => s + p.creditVnd);
      final equityDebit = equityPostings.fold<int>(0, (s, p) => s + p.debitVnd);
      expect(equityCredit - equityDebit, equals(0));

      // Verify derived balance for default Income (id = 2) is 0 ₫
      final incomePostings = await (db.select(db.journalPostings)
            ..where((p) => p.accountId.equals(2)))
          .get();
      final incomeCredit =
          incomePostings.fold<int>(0, (s, p) => s + p.creditVnd);
      final incomeDebit = incomePostings.fold<int>(0, (s, p) => s + p.debitVnd);
      expect(incomeCredit - incomeDebit, equals(0));

      // Verify derived balance for default Expense (id = 3) is 0 ₫
      final expensePostings = await (db.select(db.journalPostings)
            ..where((p) => p.accountId.equals(3)))
          .get();
      final expenseDebit =
          expensePostings.fold<int>(0, (s, p) => s + p.debitVnd);
      final expenseCredit =
          expensePostings.fold<int>(0, (s, p) => s + p.creditVnd);
      expect(expenseDebit - expenseCredit, equals(0));
    });

    test(
        'all 8 default Vietnamese categories have strictly 0 ₫ spending and 0 transactions',
        () async {
      final categories = await db.select(db.categories).get();
      expect(categories.length, equals(8));

      for (final cat in categories) {
        final catPostings = await (db.select(db.journalPostings)
              ..where((p) => p.categoryId.equals(cat.id)))
            .get();
        expect(catPostings, isEmpty);
      }
    });

    test('clean initial state contains zero records in operational tables',
        () async {
      expect(await db.select(db.journalTransactions).get(), isEmpty);
      expect(await db.select(db.journalPostings).get(), isEmpty);
      expect(await db.select(db.envelopes).get(), isEmpty);
      expect(await db.select(db.envelopeMovements).get(), isEmpty);
      expect(await db.select(db.categoryBudgets).get(), isEmpty);
      expect(await db.select(db.scheduledItems).get(), isEmpty);
    });
  });

  group('Group 6: Table Enum & Value CHECK Constraints Stress-Testing', () {
    test('ledger_accounts rejects invalid kind', () async {
      expect(
        () async {
          await db.into(db.ledgerAccounts).insert(
                LedgerAccountsCompanion.insert(
                  name: 'Invalid Account',
                  kind: 'CRYPTO_WALLET', // Invalid kind
                  createdAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('categories rejects invalid kind', () async {
      expect(
        () async {
          await db.into(db.categories).insert(
                CategoriesCompanion.insert(
                  name: 'Transfer Cat',
                  kind: 'TRANSFER', // Invalid kind
                  ledgerAccountId: 2,
                  iconCode: 1,
                  colorHex: '#FFFFFF',
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('journal_transactions rejects invalid tx_type and status', () async {
      expect(
        () async {
          await db.into(db.journalTransactions).insert(
                JournalTransactionsCompanion.insert(
                  txType: 'PAYROLL_BONUS', // Invalid tx_type
                  occurredAt: 1000,
                  createdAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );

      expect(
        () async {
          await db.into(db.journalTransactions).insert(
                JournalTransactionsCompanion.insert(
                  txType: 'EXPENSE',
                  status: const Value('ARCHIVED'), // Invalid status
                  occurredAt: 1000,
                  createdAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('envelopes rejects invalid policy', () async {
      expect(
        () async {
          await db.into(db.envelopes).insert(
                EnvelopesCompanion.insert(
                  name: 'Emergency',
                  policy: 'SEMI_PROTECTED', // Invalid policy
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('envelope_movements rejects amount_vnd <= 0', () async {
      final envId = await createDummyEnvelope();
      expect(
        () async {
          await db.into(db.envelopeMovements).insert(
                EnvelopeMovementsCompanion.insert(
                  movementType: 'ALLOCATE',
                  amountVnd: 0, // Violates amount_vnd > 0
                  destEnvelopeId: Value(envId),
                  occurredAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );

      expect(
        () async {
          await db.into(db.envelopeMovements).insert(
                EnvelopeMovementsCompanion.insert(
                  movementType: 'ALLOCATE',
                  amountVnd: -100000, // Negative amount
                  destEnvelopeId: Value(envId),
                  occurredAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('envelope_movements rejects invalid movement_type', () async {
      final envId = await createDummyEnvelope();
      expect(
        () async {
          await db.into(db.envelopeMovements).insert(
                EnvelopeMovementsCompanion.insert(
                  movementType: 'LOAN_DISTRIBUTION', // Invalid movement_type
                  amountVnd: 50000,
                  destEnvelopeId: Value(envId),
                  occurredAt: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test(
        'category_budgets rejects limit_vnd <= 0 and alert_threshold outside 1..100',
        () async {
      expect(
        () async {
          await db.into(db.categoryBudgets).insert(
                CategoryBudgetsCompanion.insert(
                  categoryId: 1,
                  yearMonth: 202612,
                  limitVnd: 0, // Violates limit_vnd > 0
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );

      expect(
        () async {
          await db.into(db.categoryBudgets).insert(
                CategoryBudgetsCompanion.insert(
                  categoryId: 1,
                  yearMonth: 202612,
                  limitVnd: 5000000,
                  alertThresholdPct:
                      const Value(0), // Violates alert_threshold_pct >= 1
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );

      expect(
        () async {
          await db.into(db.categoryBudgets).insert(
                CategoryBudgetsCompanion.insert(
                  categoryId: 1,
                  yearMonth: 202612,
                  limitVnd: 5000000,
                  alertThresholdPct:
                      const Value(101), // Violates alert_threshold_pct <= 100
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });

    test('scheduled_items rejects invalid amount_vnd, anchor_day, and enums',
        () async {
      expect(
        () async {
          await db.into(db.scheduledItems).insert(
                ScheduledItemsCompanion.insert(
                  kind: 'BILL',
                  title: 'Zero Amount Bill',
                  amountVnd: 0, // Violates amount_vnd > 0
                  dueDateMs: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );

      expect(
        () async {
          await db.into(db.scheduledItems).insert(
                ScheduledItemsCompanion.insert(
                  kind: 'BILL',
                  title: 'Day 32 Bill',
                  amountVnd: 100000,
                  dueDateMs: 1000,
                  anchorDayOfMonth: const Value(32), // Violates <= 31
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );

      expect(
        () async {
          await db.into(db.scheduledItems).insert(
                ScheduledItemsCompanion.insert(
                  kind: 'SUBSCRIPTION', // Invalid kind
                  title: 'Sub',
                  amountVnd: 50000,
                  dueDateMs: 1000,
                ),
              );
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('CHECK constraint failed'),
        )),
      );
    });
  });

  group('Group 7: Referential Actions & Cascades', () {
    test('deleting journal transaction cascades and deletes postings',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();

      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: accId,
              debitVnd: const Value(100000),
              creditVnd: const Value(0),
            ),
          );

      expect((await db.select(db.journalPostings).get()).length, equals(1));

      // Delete the transaction
      await (db.delete(db.journalTransactions)..where((t) => t.id.equals(txId)))
          .go();

      // Postings must be cascaded
      expect((await db.select(db.journalPostings).get()), isEmpty);
    });

    test(
        'deleting ledger account referenced by posting throws SqliteException (RESTRICT)',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();

      await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: accId,
              debitVnd: const Value(100000),
              creditVnd: const Value(0),
            ),
          );

      expect(
        () async {
          await (db.delete(db.ledgerAccounts)..where((a) => a.id.equals(accId)))
              .go();
        },
        throwsA(isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('FOREIGN KEY constraint failed'),
        )),
      );
    });

    test(
        'deleting category referenced by posting sets category_id to NULL (SET NULL)',
        () async {
      final txId = await createDummyTx();
      final accId = await createCashAccount();

      // Create a custom category to delete
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Temporary Category',
              kind: 'EXPENSE',
              ledgerAccountId: 3,
              iconCode: 0xe532,
              colorHex: '#000000',
            ),
          );

      final postingId = await db.into(db.journalPostings).insert(
            JournalPostingsCompanion.insert(
              transactionId: txId,
              accountId: accId,
              debitVnd: const Value(100000),
              creditVnd: const Value(0),
              categoryId: Value(catId),
            ),
          );

      // Verify posting has categoryId
      var posting = await (db.select(db.journalPostings)
            ..where((p) => p.id.equals(postingId)))
          .getSingle();
      expect(posting.categoryId, equals(catId));

      // Delete the category
      await (db.delete(db.categories)..where((c) => c.id.equals(catId))).go();

      // Category in posting should now be NULL
      posting = await (db.select(db.journalPostings)
            ..where((p) => p.id.equals(postingId)))
          .getSingle();
      expect(posting.categoryId, isNull);
    });

    test('deleting category cascades and deletes associated category_budgets',
        () async {
      final catId = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: 'Budgeted Cat',
              kind: 'EXPENSE',
              ledgerAccountId: 3,
              iconCode: 0xe532,
              colorHex: '#000000',
            ),
          );

      await db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              categoryId: catId,
              yearMonth: 202610,
              limitVnd: 1000000,
            ),
          );

      expect((await db.select(db.categoryBudgets).get()).length, equals(1));

      // Delete the category
      await (db.delete(db.categories)..where((c) => c.id.equals(catId))).go();

      // category_budgets should be cascaded
      expect((await db.select(db.categoryBudgets).get()), isEmpty);
    });
  });
}
