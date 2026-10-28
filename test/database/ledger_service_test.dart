import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/domain/envelopes/envelope_exceptions.dart';
import 'package:dongtien/domain/ledger/ledger_exceptions.dart';
import 'package:dongtien/domain/ledger/post_transaction_command.dart';
import 'package:dongtien/domain/ledger/posting_leg.dart';
import 'package:dongtien/domain/ledger/posting_matrix.dart';
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

  group('LedgerDao & Double-Entry General Ledger End-to-End Invariants', () {
    test('Scenario 1: Opening Asset Balance (10.000.000 ₫ to Cash)', () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      final cmd = PostTransactionCommand.openingAsset(
        assetAccountId: cashId,
        amountVnd: 10000000,
        occurredAt: 1000,
      );

      final txId = await db.ledgerDao.postTransactionCommand(cmd);
      expect(txId, isPositive);

      // Dynamic Balances
      final cashBal = await db.ledgerDao.getAccountBalance(cashId);
      expect(cashBal, equals(10000000));

      final equityBal = await db.ledgerDao
          .getAccountBalance(PostingMatrix.equityOpeningAccountId);
      expect(equityBal, equals(10000000));

      final liquidAssets = await db.ledgerDao.getTotalLiquidAssets();
      expect(liquidAssets, equals(10000000));

      final operatingIncome = await db.ledgerDao
          .getAccountBalance(PostingMatrix.defaultIncomeAccountId);
      expect(operatingIncome,
          equals(0)); // Opening balance is NOT operating income!
    });

    test('Scenario 2: Salary Income (20.000.000 ₫)', () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      // Initial 10M
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      // Salary income 20M (using default Category ID 1: "Lương")
      final incomeCmd = PostTransactionCommand.income(
        receivingAssetAccountId: cashId,
        categoryId: 1,
        amountVnd: 20000000,
        occurredAt: 2000,
        description: 'Lương tháng 10',
      );
      await db.ledgerDao.postTransactionCommand(incomeCmd);

      // Assertions
      final cashBal = await db.ledgerDao.getAccountBalance(cashId);
      expect(cashBal, equals(30000000));

      final totalLiquid = await db.ledgerDao.getTotalLiquidAssets();
      expect(totalLiquid, equals(30000000));

      final recognizedIncome = await db.ledgerDao
          .getAccountBalance(PostingMatrix.defaultIncomeAccountId);
      expect(recognizedIncome, equals(20000000));
    });

    test('Scenario 3: Cash Expense (100.000 ₫) with Linked Envelope', () async {
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
          amountVnd: 30000000,
          occurredAt: 1000,
        ),
      );

      // Create envelope with 1.000.000 ₫ initial reserve
      final envelopeId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Ăn uống',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(1000000),
            ),
          );

      // Post 100.000 ₫ expense (Category ID 3: "Ăn uống")
      final expenseCmd = PostTransactionCommand.expense(
        sourceAccountId: cashId,
        categoryId: 3,
        amountVnd: 100000,
        occurredAt: 3000,
        description: 'Ăn trưa',
        linkedEnvelopeId: envelopeId,
      );
      final txId = await db.ledgerDao.postTransactionCommand(expenseCmd);

      // Balances
      final cashBal = await db.ledgerDao.getAccountBalance(cashId);
      expect(cashBal, equals(29900000));

      final netExpense = await db.ledgerDao
          .getAccountBalance(PostingMatrix.defaultExpenseAccountId);
      expect(netExpense, equals(100000));

      // Envelope balance updated
      final env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envelopeId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(900000));

      // Linked envelope movement recorded
      final movements = await (db.select(db.envelopeMovements)
            ..where((m) => m.linkedTransactionId.equals(txId)))
          .get();
      expect(movements.length, equals(1));
      expect(movements.first.movementType, equals('SPEND'));
      expect(movements.first.amountVnd, equals(100000));
      expect(movements.first.sourceEnvelopeId, equals(envelopeId));
    });

    test('Scenario 4: Internal Transfer (2.000.000 ₫) from Cash to Bank',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      final bankId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tài khoản VCB',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 29900000,
          occurredAt: 1000,
        ),
      );

      final transferCmd = PostTransactionCommand.transfer(
        sourceAssetAccountId: cashId,
        destinationAssetAccountId: bankId,
        amountVnd: 2000000,
        occurredAt: 4000,
      );
      await db.ledgerDao.postTransactionCommand(transferCmd);

      // Total liquid assets unchanged
      final totalLiquid = await db.ledgerDao.getTotalLiquidAssets();
      expect(totalLiquid, equals(29900000));

      // Individual account balances
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(27900000));
      expect(await db.ledgerDao.getAccountBalance(bankId), equals(2000000));

      // Net worth unchanged
      expect(await db.ledgerDao.getNetWorth(), equals(29900000));
    });

    test('Scenario 6 & 7: Credit Card Purchase & Card Payment Invariants',
        () async {
      final bankId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tài khoản VCB',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      final cardId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Thẻ tín dụng Techcombank',
              kind: 'LIABILITY_CREDIT_CARD',
              isLiquid: const Value(false),
              creditLimit: const Value(20000000),
              createdAt: 1000,
            ),
          );

      // Seed bank with 10M
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: bankId,
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      // Scenario 6: Credit Card Purchase of 500.000 ₫ (Category ID 7: "Mua sắm")
      final purchaseCmd = PostTransactionCommand.expense(
        sourceAccountId: cardId,
        categoryId: 7,
        amountVnd: 500000,
        occurredAt: 5000,
        description: 'Mua sắm qua thẻ',
      );
      await db.ledgerDao.postTransactionCommand(purchaseCmd);

      // Check Invariants after purchase:
      // Liquid assets untouched!
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(10000000));
      // Card liability = 500.000 ₫
      expect(await db.ledgerDao.getAccountBalance(cardId), equals(500000));
      // Expense = 500.000 ₫
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
        equals(500000),
      );
      // Net worth = 10M - 500k = 9.5M
      expect(await db.ledgerDao.getNetWorth(), equals(9500000));

      // Scenario 7: Credit Card Payment of 500.000 ₫ from Bank account
      final paymentCmd = PostTransactionCommand.creditCardPayment(
        creditCardAccountId: cardId,
        sourceAssetAccountId: bankId,
        amountVnd: 500000,
        occurredAt: 6000,
      );
      await db.ledgerDao.postTransactionCommand(paymentCmd);

      // Check Invariants after card settlement:
      // Bank balance decreased by 500k -> 9.5M
      expect(await db.ledgerDao.getAccountBalance(bankId), equals(9500000));
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(9500000));
      // Card debt settled to 0 ₫!
      expect(await db.ledgerDao.getAccountBalance(cardId), equals(0));
      // CRITICAL: Operating expense did NOT increase (remains 500.000 ₫)
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
        equals(500000),
      );
      // Net worth unchanged by debt repayment: 9.5M
      expect(await db.ledgerDao.getNetWorth(), equals(9500000));
    });

    test(
        'Scenario 8: Refund restores cash, offsets expense, and restores envelope reserve',
        () async {
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
          amountVnd: 1000000,
          occurredAt: 1000,
        ),
      );

      final envelopeId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Mua sắm',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(500000),
            ),
          );

      // 1. Spend 200.000 ₫
      final spendTxId = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashId,
          categoryId: 7,
          amountVnd: 200000,
          occurredAt: 2000,
          description: 'Mua áo',
          linkedEnvelopeId: envelopeId,
        ),
      );
      expect(spendTxId, isPositive);
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(800000));
      var env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envelopeId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(300000));

      // 2. Refund 50.000 ₫
      final refundCmd = PostTransactionCommand.refund(
        receivingAccountId: cashId,
        categoryId: 7,
        amountVnd: 50000,
        occurredAt: 3000,
        description: 'Hoàn tiền trả hàng',
        linkedEnvelopeId: envelopeId,
      );
      final refundTxId = await db.ledgerDao.postTransactionCommand(refundCmd);
      expect(refundTxId, isPositive);

      // Cash restored to 850.000 ₫
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(850000));
      // Net expense decreased to 150.000 ₫
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
        equals(150000),
      );
      // Envelope reserve restored by 50.000 ₫ to 350.000 ₫
      env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envelopeId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(350000));

      // Envelope movement REFUND_RESTORE recorded
      final movements = await (db.select(db.envelopeMovements)
            ..where((m) => m.linkedTransactionId.equals(refundTxId)))
          .get();
      expect(movements.first.movementType, equals('REFUND_RESTORE'));
      expect(movements.first.amountVnd, equals(50000));
    });

    test('Scenario 9: Void & Edit Audit-Preserving State Transitions',
        () async {
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

      final envelopeId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Tiện ích',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(1000000),
            ),
          );

      // 1. Post expense of 300.000 ₫
      final origTxId = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashId,
          categoryId: 5,
          amountVnd: 300000,
          occurredAt: 2000,
          description: 'Tiền điện',
          linkedEnvelopeId: envelopeId,
        ),
      );
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(4700000));
      var env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envelopeId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(700000));

      // 2. Void transaction
      final reversalTxId = await db.ledgerDao.voidTransaction(origTxId);
      expect(reversalTxId, isPositive);

      // Check original is VOIDED
      final origTx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(origTxId)))
          .getSingle();
      expect(origTx.status, equals('VOIDED'));

      // Check reversal is POSTED and references original
      final revTx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(reversalTxId)))
          .getSingle();
      expect(revTx.status, equals('POSTED'));
      expect(revTx.txType, equals('REVERSAL'));
      expect(revTx.reversesTxId, equals(origTxId));

      // Check balances restored cleanly
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(5000000));
      expect(
          await db.ledgerDao
              .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
          equals(0));
      env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envelopeId)))
          .getSingle();
      expect(env.reservedBalanceVnd,
          equals(1000000)); // Envelope reserve restored!

      // Clean UI feed hides VOIDED and REVERSAL transactions!
      final cleanTxs = await db.ledgerDao.getCleanTransactions();
      // Only the opening asset transaction is visible
      expect(cleanTxs.length, equals(1));
      expect(cleanTxs.first.txType, equals('OPENING_BALANCE'));

      // 3. Edit test
      final txToEdit = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashId,
          categoryId: 5,
          amountVnd: 400000,
          occurredAt: 3000,
          description: 'Tiền nước cũ',
        ),
      );
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(4600000));

      final newPostings = PostingMatrix.buildExpense(
        sourceAccountId: cashId,
        categoryId: 5,
        amountVnd: 600000,
      );

      final replacementTxId = await db.ledgerDao.editTransaction(
        originalTxId: txToEdit,
        txType: 'EXPENSE',
        description: 'Tiền nước mới đã chỉnh sửa',
        occurredAt: 3000,
        newPostings: newPostings,
      );

      final supersededTx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(txToEdit)))
          .getSingle();
      expect(supersededTx.status, equals('SUPERSEDED'));
      expect(supersededTx.replacedByTxId, equals(replacementTxId));

      // Balance now reflects 600.000 ₫ expense (5M - 600k = 4.4M)
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(4400000));
    });

    test('Scenario 10: Idempotency Key Guard Rejects Double Submissions',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      final cmd = PostTransactionCommand.openingAsset(
        assetAccountId: cashId,
        amountVnd: 1000000,
        occurredAt: 1000,
        idempotencyKey: 'idemp-duplicate-test',
      );

      final firstId = await db.ledgerDao.postTransactionCommand(cmd);
      expect(firstId, isPositive);

      // Second post with identical key throws SqliteException
      expect(
        () => db.ledgerDao.postTransactionCommand(cmd),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
        'Unbalanced transaction is rejected at pure domain boundary before touching DB',
        () async {
      final unbalancedPostings = [
        PostingLeg.debit(accountId: 1, amountVnd: 500000),
        PostingLeg.credit(accountId: 2, amountVnd: 400000),
      ];

      expect(
        () => db.ledgerDao.postTransaction(
          txType: 'EXPENSE',
          description: 'Unbalanced',
          occurredAt: 1000,
          postings: unbalancedPostings,
        ),
        throwsA(isA<UnbalancedTransactionException>()),
      );

      // Verify no records inserted
      final txs = await db.select(db.journalTransactions).get();
      expect(txs.isEmpty, isTrue);
    });

    test(
        'postTransaction with linked envelope not found throws InvalidTransactionException',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      expect(
        () => db.ledgerDao.postTransactionCommand(
          PostTransactionCommand.expense(
            sourceAccountId: cashId,
            categoryId: 3,
            amountVnd: 100000,
            occurredAt: 2000,
            description: 'Non-existent envelope',
            linkedEnvelopeId: 99999,
          ),
        ),
        throwsA(isA<InvalidTransactionException>().having(
          (e) => e.message,
          'message',
          contains('Linked envelope 99999 not found'),
        )),
      );
    });

    test(
        'postTransaction SPEND exceeding envelope balance throws SpendingDeficitException when allowNegativeException is false',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      final envelopeId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Ăn uống',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(100000),
              allowNegativeException: const Value(false),
            ),
          );

      expect(
        () => db.ledgerDao.postTransactionCommand(
          PostTransactionCommand.expense(
            sourceAccountId: cashId,
            categoryId: 3,
            amountVnd: 200000,
            occurredAt: 2000,
            description: 'Vượt quỹ ăn uống',
            linkedEnvelopeId: envelopeId,
          ),
        ),
        throwsA(isA<SpendingDeficitException>()),
      );
    });

    test(
        'voidTransaction on a REVERSAL transaction throws InvalidTransactionException',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      final origTxId = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 1000000,
          occurredAt: 1000,
        ),
      );

      final revTxId = await db.ledgerDao.voidTransaction(origTxId);

      expect(
        () => db.ledgerDao.voidTransaction(revTxId),
        throwsA(isA<InvalidTransactionException>().having(
          (e) => e.message,
          'message',
          contains('Cannot void a REVERSAL transaction'),
        )),
      );
    });
  });
}
