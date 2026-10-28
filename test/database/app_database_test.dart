import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
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

  group('1. Drift Fresh Database Initialization & Vietnamese Seeding', () {
    test('fresh database creates all 9 tables', () async {
      expect(await db.select(db.ledgerAccounts).get(), isNotNull);
      expect(await db.select(db.categories).get(), isNotNull);
      expect(await db.select(db.journalTransactions).get(), isNotNull);
      expect(await db.select(db.journalPostings).get(), isNotNull);
      expect(await db.select(db.envelopes).get(), isNotNull);
      expect(await db.select(db.envelopeMovements).get(), isNotNull);
      expect(await db.select(db.categoryBudgets).get(), isNotNull);
      expect(await db.select(db.scheduledItems).get(), isNotNull);
      expect(await db.select(db.settings).get(), isNotNull);
    });

    test('3 system accounts are seeded with correct attributes', () async {
      final accounts = await db.select(db.ledgerAccounts).get();
      expect(accounts.length, equals(3));

      final equityOpening =
          accounts.firstWhere((a) => a.kind == 'EQUITY_OPENING');
      expect(equityOpening.id, equals(1));
      expect(equityOpening.name, equals('Vốn ban đầu'));
      expect(equityOpening.isLiquid, isFalse);
      expect(equityOpening.creditLimit, equals(0));
      expect(equityOpening.isArchived, isFalse);

      final defaultIncome = accounts.firstWhere((a) => a.kind == 'INCOME');
      expect(defaultIncome.id, equals(2));
      expect(defaultIncome.name, equals('Thu nhập'));
      expect(defaultIncome.isLiquid, isFalse);
      expect(defaultIncome.creditLimit, equals(0));

      final defaultExpense = accounts.firstWhere((a) => a.kind == 'EXPENSE');
      expect(defaultExpense.id, equals(3));
      expect(defaultExpense.name, equals('Chi tiêu'));
      expect(defaultExpense.isLiquid, isFalse);
      expect(defaultExpense.creditLimit, equals(0));
    });

    test(
        '8 default Vietnamese categories are seeded with correct icons, colors, and FKs',
        () async {
      final categories = await db.select(db.categories).get();
      expect(categories.length, equals(8));

      // 2 Income Categories
      final salary = categories.firstWhere((c) => c.name == 'Lương');
      expect(salary.kind, equals('INCOME'));
      expect(salary.ledgerAccountId, equals(2));
      expect(salary.iconCode, equals(0xe6f3));
      expect(salary.colorHex, equals('#4E886F'));
      expect(salary.isDefault, isTrue);

      final bonus = categories.firstWhere((c) => c.name == 'Thưởng');
      expect(bonus.kind, equals('INCOME'));
      expect(bonus.ledgerAccountId, equals(2));
      expect(bonus.iconCode, equals(0xeeb8));
      expect(bonus.colorHex, equals('#EE8D00'));
      expect(bonus.isDefault, isTrue);

      // 6 Expense Categories
      final expenseNames = [
        'Ăn uống',
        'Di chuyển',
        'Hoá đơn & Tiện ích',
        'Nhà cửa',
        'Mua sắm',
        'Y tế',
      ];
      for (final name in expenseNames) {
        final cat = categories.firstWhere((c) => c.name == name);
        expect(cat.kind, equals('EXPENSE'));
        expect(cat.ledgerAccountId, equals(3));
        expect(cat.isDefault, isTrue);
        expect(cat.isArchived, isFalse);
      }
    });

    test('singleton settings row is initialized with id = 1 and default values',
        () async {
      final settingsList = await db.select(db.settings).get();
      expect(settingsList.length, equals(1));

      final s = settingsList.single;
      expect(s.id, equals(1));
      expect(s.minimumCashBufferVnd, equals(0));
      expect(s.periodStartDay, equals(1));
      expect(s.dailyReminderHour, equals(20));
      expect(s.dailyReminderMinute, equals(0));
      expect(s.notificationsEnabled, isFalse);
      expect(s.schemaVersion, equals(1));
    });

    test('initial state has strictly 0 transactions and 0 ₫ balances',
        () async {
      final txs = await db.select(db.journalTransactions).get();
      final postings = await db.select(db.journalPostings).get();
      final envelopes = await db.select(db.envelopes).get();

      expect(txs.isEmpty, isTrue);
      expect(postings.isEmpty, isTrue);
      expect(envelopes.isEmpty, isTrue);
    });
  });

  group('2. Foreign Key Enforcement (PRAGMA foreign_keys = ON;)', () {
    test(
        'inserting category with non-existent ledger_account_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.categories).insert(
                CategoriesCompanion.insert(
                  name: 'Orphan Category',
                  kind: 'EXPENSE',
                  ledgerAccountId: 9999, // Non-existent
                  iconCode: 0xe532,
                  colorHex: '#000000',
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
        'inserting journal posting with non-existent transaction_id throws SqliteException',
        () async {
      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: 9999,
                  accountId: 1,
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

    test(
        'inserting journal posting with non-existent account_id throws SqliteException',
        () async {
      final txId = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: const Value('Tx'),
              occurredAt: 1,
              createdAt: 1,
            ),
          );

      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: 9999, // Non-existent account
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
  });

  group('3. Journal Postings Constraints & Balanced Double-Entry Postings', () {
    test(
        'inserting posting with debit > 0 AND credit > 0 throws SqliteException (CHECK constraint)',
        () async {
      final txId = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: const Value('Invalid Posting'),
              occurredAt: 1,
              createdAt: 1,
            ),
          );

      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: 1,
                  debitVnd: const Value(50000),
                  creditVnd: const Value(50000), // Violates CHECK
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
        'inserting posting with debit == 0 AND credit == 0 throws SqliteException (CHECK constraint)',
        () async {
      final txId = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: const Value('Invalid Zero Posting'),
              occurredAt: 1,
              createdAt: 1,
            ),
          );

      expect(
        () async {
          await db.into(db.journalPostings).insert(
                JournalPostingsCompanion.insert(
                  transactionId: txId,
                  accountId: 1,
                  debitVnd: const Value(0),
                  creditVnd: const Value(0), // Violates CHECK
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
        'balanced transaction insertion and dynamic account balance derivation succeeds',
        () async {
      // Create user cash account
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1,
            ),
          );

      // Insert OPENING_BALANCE transaction of 10.000.000 ₫
      final txId = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'OPENING_BALANCE',
              description: const Value('Số dư ban đầu tiền mặt'),
              occurredAt: 100,
              createdAt: 100,
            ),
          );

      // Balanced postings: Debit Asset Cash 10M, Credit EQUITY_OPENING 10M
      await db.batch((batch) {
        batch.insert(
          db.journalPostings,
          JournalPostingsCompanion.insert(
            transactionId: txId,
            accountId: cashId,
            debitVnd: const Value(10000000),
            creditVnd: const Value(0),
          ),
        );
        batch.insert(
          db.journalPostings,
          JournalPostingsCompanion.insert(
            transactionId: txId,
            accountId: 1, // EQUITY_OPENING
            debitVnd: const Value(0),
            creditVnd: const Value(10000000),
          ),
        );
      });

      // Assert sum(debit) == sum(credit)
      final postings = await (db.select(db.journalPostings)
            ..where((p) => p.transactionId.equals(txId)))
          .get();
      final totalDebit = postings.fold<int>(0, (sum, p) => sum + p.debitVnd);
      final totalCredit = postings.fold<int>(0, (sum, p) => sum + p.creditVnd);
      expect(totalDebit, equals(10000000));
      expect(totalCredit, equals(10000000));
      expect(totalDebit, equals(totalCredit));

      // Derive cash balance: sum(debit) - sum(credit)
      final cashPostings = await (db.select(db.journalPostings)
            ..where((p) => p.accountId.equals(cashId)))
          .get();
      final cashBalance = cashPostings.fold<int>(
        0,
        (sum, p) => sum + p.debitVnd - p.creditVnd,
      );
      expect(cashBalance, equals(10000000));

      // Derive equity balance: sum(credit) - sum(debit)
      final equityPostings = await (db.select(db.journalPostings)
            ..where((p) => p.accountId.equals(1)))
          .get();
      final equityBalance = equityPostings.fold<int>(
        0,
        (sum, p) => sum + p.creditVnd - p.debitVnd,
      );
      expect(equityBalance, equals(10000000));
    });
  });

  group('4. Unique Constraints & Relational Integrity', () {
    test('idempotency_key rejects duplicate non-null submissions', () async {
      await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: const Value('Tx 1'),
              occurredAt: 1,
              createdAt: 1,
              idempotencyKey: const Value('unique-key-123'),
            ),
          );

      expect(
        () async {
          await db.into(db.journalTransactions).insert(
                JournalTransactionsCompanion.insert(
                  txType: 'EXPENSE',
                  description: const Value('Tx 2 duplicate'),
                  occurredAt: 2,
                  createdAt: 2,
                  idempotencyKey: const Value('unique-key-123'),
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
              description: const Value('Tx 1 (null key)'),
              occurredAt: 1,
              createdAt: 1,
            ),
          );
      final id2 = await db.into(db.journalTransactions).insert(
            JournalTransactionsCompanion.insert(
              txType: 'EXPENSE',
              description: const Value('Tx 2 (null key)'),
              occurredAt: 2,
              createdAt: 2,
            ),
          );
      expect(id1, isNotNull);
      expect(id2, isNotNull);
      expect(id1, isNot(equals(id2)));
    });

    test(
        'composite unique (category_id, year_month) on category_budgets is enforced',
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
                  yearMonth: 202610, // Duplicate month for same category
                  limitVnd: 6000000,
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
  });
}
