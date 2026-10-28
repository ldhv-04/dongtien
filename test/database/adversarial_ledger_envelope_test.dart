import 'package:dongtien/core/database/app_database.dart';
import 'package:dongtien/core/money/vnd_money.dart';
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

  group('CHALLENGE 1: Unbalanced Transactions & Atomic Rollback', () {
    test('1.1 PostingMatrix.assertBalanced rejects empty postings', () {
      expect(
        () => PostingMatrix.assertBalanced([]),
        throwsA(isA<UnbalancedTransactionException>()),
      );
    });

    test('1.2 PostingMatrix.assertBalanced rejects single-sided leg', () {
      final postings = [
        PostingLeg.debit(accountId: 1, amountVnd: 100000),
      ];
      expect(
        () => PostingMatrix.assertBalanced(postings),
        throwsA(isA<UnbalancedTransactionException>()),
      );
    });

    test('1.3 PostingMatrix.assertBalanced rejects 1 VND discrepancy', () {
      final postings = [
        PostingLeg.debit(accountId: 1, amountVnd: 100000),
        PostingLeg.credit(accountId: 2, amountVnd: 99999),
      ];
      expect(
        () => PostingMatrix.assertBalanced(postings),
        throwsA(isA<UnbalancedTransactionException>()),
      );
    });

    test('1.4 PostingMatrix.assertBalanced rejects multi-leg imbalance', () {
      final postings = [
        PostingLeg.debit(accountId: 1, amountVnd: 300000),
        PostingLeg.debit(accountId: 2, amountVnd: 200000),
        PostingLeg.credit(accountId: 3, amountVnd: 499990),
      ];
      expect(
        () => PostingMatrix.assertBalanced(postings),
        throwsA(isA<UnbalancedTransactionException>()),
      );
    });

    test(
        '1.5 LedgerDao.postTransaction with unbalanced legs throws and rolls back',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      final initialTxCount =
          (await db.select(db.journalTransactions).get()).length;
      final initialPostingsCount =
          (await db.select(db.journalPostings).get()).length;

      final unbalancedPostings = [
        PostingLeg.debit(accountId: cashId, amountVnd: 500000),
        PostingLeg.credit(
            accountId: PostingMatrix.equityOpeningAccountId, amountVnd: 400000),
      ];

      expect(
        () => db.ledgerDao.postTransaction(
          txType: 'OPENING_BALANCE',
          description: 'Unbalanced Attempt',
          occurredAt: 1000,
          postings: unbalancedPostings,
        ),
        throwsA(isA<UnbalancedTransactionException>()),
      );

      // Verify zero records written to DB (total rollback)
      final afterTxs = await db.select(db.journalTransactions).get();
      final afterPostings = await db.select(db.journalPostings).get();
      expect(afterTxs.length, equals(initialTxCount));
      expect(afterPostings.length, equals(initialPostingsCount));
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(0));
    });

    test(
        '1.6 Atomic rollback when SQLite constraint fails (non-existent account ID)',
        () async {
      final initialTxCount =
          (await db.select(db.journalTransactions).get()).length;
      final initialPostingsCount =
          (await db.select(db.journalPostings).get()).length;

      // Account 999999 does not exist in ledger_accounts, violating FK constraint
      final balancedPostingsWithBadFk = [
        PostingLeg.debit(accountId: 999999, amountVnd: 500000),
        PostingLeg.credit(
            accountId: PostingMatrix.equityOpeningAccountId, amountVnd: 500000),
      ];

      expect(
        () => db.ledgerDao.postTransaction(
          txType: 'OPENING_BALANCE',
          description: 'FK Violation Attempt',
          occurredAt: 1000,
          postings: balancedPostingsWithBadFk,
        ),
        throwsA(isA<SqliteException>()),
      );

      // Ensure journalTransactions did NOT retain the uncommitted transaction!
      final afterTxs = await db.select(db.journalTransactions).get();
      final afterPostings = await db.select(db.journalPostings).get();
      expect(afterTxs.length, equals(initialTxCount));
      expect(afterPostings.length, equals(initialPostingsCount));
    });

    test(
        '1.7 editTransaction with unbalanced newPostings aborts and preserves original transaction untouched',
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

      final unbalancedReplacement = [
        PostingLeg.debit(accountId: cashId, amountVnd: 2000000),
        PostingLeg.credit(
            accountId: PostingMatrix.equityOpeningAccountId,
            amountVnd: 1999999),
      ];

      expect(
        () => db.ledgerDao.editTransaction(
          originalTxId: origTxId,
          txType: 'OPENING_BALANCE',
          description: 'Failed Edit',
          occurredAt: 2000,
          newPostings: unbalancedReplacement,
        ),
        throwsA(isA<UnbalancedTransactionException>()),
      );

      // Verify original transaction is STILL POSTED and NOT voided or superseded!
      final origTx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(origTxId)))
          .getSingle();
      expect(origTx.status, equals('POSTED'));
      expect(origTx.replacedByTxId, isNull);

      // Verify no reversal transaction was created
      final reversals = await (db.select(db.journalTransactions)
            ..where((t) => t.txType.equals('REVERSAL')))
          .get();
      expect(reversals.isEmpty, isTrue);

      // Balance remains original 1.000.000 ₫
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(1000000));
    });
  });

  group('CHALLENGE 2: Credit Card Payment Isolation & Invariants', () {
    test(
        '2.1 Credit card payment postings NEVER touch expense accounts or categories',
        () {
      final paymentLegs = PostingMatrix.buildCreditCardPayment(
        creditCardAccountId: 20,
        sourceAssetAccountId: 10,
        amountVnd: 1500000,
      );

      expect(paymentLegs.length, equals(2));
      // Leg 1: Debit Credit Card Liability
      expect(paymentLegs[0].accountId, equals(20));
      expect(paymentLegs[0].debitVnd, equals(1500000));
      expect(paymentLegs[0].creditVnd, equals(0));
      expect(paymentLegs[0].categoryId, isNull);
      expect(paymentLegs[0].envelopeId, isNull);

      // Leg 2: Credit Paying Asset Account
      expect(paymentLegs[1].accountId, equals(10));
      expect(paymentLegs[1].debitVnd, equals(0));
      expect(paymentLegs[1].creditVnd, equals(1500000));
      expect(paymentLegs[1].categoryId, isNull);
      expect(paymentLegs[1].envelopeId, isNull);

      // None of the legs touch default expense account (ID 3) or default income account (ID 2)
      for (final leg in paymentLegs) {
        expect(leg.accountId,
            isNot(equals(PostingMatrix.defaultExpenseAccountId)));
        expect(
            leg.accountId, isNot(equals(PostingMatrix.defaultIncomeAccountId)));
      }
    });

    test(
        '2.2 End-to-end card payment leaves operating expense, income, and net worth strictly invariant',
        () async {
      final bankId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'VCB Checking',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      final cardId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Visa Credit Card',
              kind: 'LIABILITY_CREDIT_CARD',
              isLiquid: const Value(false),
              creditLimit: const Value(50000000),
              createdAt: 1000,
            ),
          );

      // Seed bank with 20.000.000 ₫
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: bankId,
          amountVnd: 20000000,
          occurredAt: 1000,
        ),
      );

      // Charge 3.000.000 ₫ to credit card (Dining expense, Category ID 3)
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cardId,
          categoryId: 3,
          amountVnd: 3000000,
          occurredAt: 2000,
          description: 'Dining out',
        ),
      );

      final expenseBeforePayment = await db.ledgerDao
          .getAccountBalance(PostingMatrix.defaultExpenseAccountId);
      expect(expenseBeforePayment, equals(3000000));
      final incomeBeforePayment = await db.ledgerDao
          .getAccountBalance(PostingMatrix.defaultIncomeAccountId);
      expect(incomeBeforePayment, equals(0));
      final netWorthBefore = await db.ledgerDao.getNetWorth();
      expect(netWorthBefore, equals(17000000)); // 20M bank - 3M card = 17M

      // Settle 3.000.000 ₫ credit card bill from bank
      final paymentCmd = PostTransactionCommand.creditCardPayment(
        creditCardAccountId: cardId,
        sourceAssetAccountId: bankId,
        amountVnd: 3000000,
        occurredAt: 3000,
      );
      final paymentTxId = await db.ledgerDao.postTransactionCommand(paymentCmd);
      expect(paymentTxId, isPositive);

      // POST-PAYMENT RIGOROUS INVARIANT CHECKS:
      // 1. Operating expense did NOT change by a single Dong
      final expenseAfterPayment = await db.ledgerDao
          .getAccountBalance(PostingMatrix.defaultExpenseAccountId);
      expect(expenseAfterPayment, equals(expenseBeforePayment));

      // 2. Operating income did NOT change
      final incomeAfterPayment = await db.ledgerDao
          .getAccountBalance(PostingMatrix.defaultIncomeAccountId);
      expect(incomeAfterPayment, equals(incomeBeforePayment));

      // 3. Card liability is settled to exactly 0 ₫
      expect(await db.ledgerDao.getAccountBalance(cardId), equals(0));

      // 4. Liquid assets decreased by payment amount (20M -> 17M)
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(17000000));

      // 5. Net worth remains exactly invariant (17.000.000 ₫)
      expect(await db.ledgerDao.getNetWorth(), equals(netWorthBefore));
    });

    test(
        '2.3 Card payment where creditCardAccountId == sourceAssetAccountId throws InvalidTransactionException',
        () {
      expect(
        () => PostingMatrix.buildCreditCardPayment(
          creditCardAccountId: 5,
          sourceAssetAccountId: 5,
          amountVnd: 1000000,
        ),
        throwsA(isA<InvalidTransactionException>()),
      );
    });

    test(
        '2.4 Overpayment of credit card creates negative liability (asset-like surplus) without touching expense',
        () async {
      final bankId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'VCB Checking',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      final cardId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Visa Credit Card',
              kind: 'LIABILITY_CREDIT_CARD',
              isLiquid: const Value(false),
              creditLimit: const Value(50000000),
              createdAt: 1000,
            ),
          );

      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: bankId,
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      // Card debt is only 1.000.000 ₫
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cardId,
          categoryId: 3,
          amountVnd: 1000000,
          occurredAt: 2000,
          description: 'Small bill',
        ),
      );

      // User pays 1.500.000 ₫ (overpayment of 500.000 ₫)
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.creditCardPayment(
          creditCardAccountId: cardId,
          sourceAssetAccountId: bankId,
          amountVnd: 1500000,
          occurredAt: 3000,
        ),
      );

      // Card liability is now -500.000 ₫ (surplus)
      expect(await db.ledgerDao.getAccountBalance(cardId), equals(-500000));
      // Expense remains strictly 1.000.000 ₫
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
        equals(1000000),
      );
    });

    test(
        '2.5 Voiding a card payment inverts card liability and liquid cash without touching expense',
        () async {
      final bankId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'VCB Checking',
              kind: 'ASSET_BANK',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      final cardId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Visa Credit Card',
              kind: 'LIABILITY_CREDIT_CARD',
              isLiquid: const Value(false),
              creditLimit: const Value(50000000),
              createdAt: 1000,
            ),
          );

      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: bankId,
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      final paymentTxId = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.creditCardPayment(
          creditCardAccountId: cardId,
          sourceAssetAccountId: bankId,
          amountVnd: 2000000,
          occurredAt: 2000,
        ),
      );

      expect(await db.ledgerDao.getAccountBalance(bankId), equals(8000000));
      expect(await db.ledgerDao.getAccountBalance(cardId), equals(-2000000));

      // Void the card payment
      await db.ledgerDao.voidTransaction(paymentTxId);

      // Restored balances
      expect(await db.ledgerDao.getAccountBalance(bankId), equals(10000000));
      expect(await db.ledgerDao.getAccountBalance(cardId), equals(0));
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
        equals(0),
      );
    });
  });

  group('CHALLENGE 3: Virtual Envelope Decoupling from General Ledger', () {
    test(
        '3.1 Envelope allocate, release, and transfer operations generate ZERO journal postings and ZERO net worth changes',
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
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      final basePostings = await db.select(db.journalPostings).get();
      final baseTransactions = await db.select(db.journalTransactions).get();
      final baseLiquid = await db.ledgerDao.getTotalLiquidAssets();
      final baseNetWorth = await db.ledgerDao.getNetWorth();

      final envA = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ A (Protected)',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(0),
            ),
          );
      final envB = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ B (Flexible)',
              policy: 'FLEXIBLE',
              reservedBalanceVnd: const Value(0),
            ),
          );

      // Operation 1: Allocate 3.000.000 ₫ into envA
      await db.envelopeDao.allocate(
        envelopeId: envA,
        amountVnd: 3000000,
        totalLiquidAssetsVnd: baseLiquid,
      );

      // Invariants after allocate:
      expect((await db.select(db.journalPostings).get()).length,
          equals(basePostings.length));
      expect((await db.select(db.journalTransactions).get()).length,
          equals(baseTransactions.length));
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(baseLiquid));
      expect(await db.ledgerDao.getNetWorth(), equals(baseNetWorth));

      // Operation 2: Transfer 1.000.000 ₫ from envA to envB
      await db.envelopeDao.transfer(
        fromEnvelopeId: envA,
        toEnvelopeId: envB,
        amountVnd: 1000000,
      );

      // Invariants after transfer:
      expect((await db.select(db.journalPostings).get()).length,
          equals(basePostings.length));
      expect((await db.select(db.journalTransactions).get()).length,
          equals(baseTransactions.length));
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(baseLiquid));
      expect(await db.ledgerDao.getNetWorth(), equals(baseNetWorth));

      // Operation 3: Release 500.000 ₫ from envB
      await db.envelopeDao.release(
        envelopeId: envB,
        amountVnd: 500000,
      );

      // Invariants after release:
      expect((await db.select(db.journalPostings).get()).length,
          equals(basePostings.length));
      expect((await db.select(db.journalTransactions).get()).length,
          equals(baseTransactions.length));
      expect(await db.ledgerDao.getTotalLiquidAssets(), equals(baseLiquid));
      expect(await db.ledgerDao.getNetWorth(), equals(baseNetWorth));

      // Operating income & expense still 0 ₫!
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
        equals(0),
      );
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultIncomeAccountId),
        equals(0),
      );
    });
  });

  group('CHALLENGE 4: Over-Allocation & Negative Exception Guards', () {
    test(
        '4.1 Over-allocation guard rejects amounts strictly exceeding available-to-allocate and rolls back',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      // Liquid assets = 5.000.000 ₫
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 5000000,
          occurredAt: 1000,
        ),
      );

      // Set minimum cash buffer to 1.000.000 ₫
      await (db.update(db.settings)).write(
        const SettingsCompanion(
          minimumCashBufferVnd: Value(1000000),
        ),
      );

      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ tiết kiệm',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(0),
            ),
          );

      // Available to allocate = 5M - 0 - 1M buffer = 4.000.000 ₫
      final available = await db.envelopeDao.getAvailableToAllocate(5000000);
      expect(available, equals(4000000));

      // Adversarial attempt: allocate 4.000.001 ₫ (exceeds by 1 VND)
      expect(
        () => db.envelopeDao.allocate(
          envelopeId: envId,
          amountVnd: 4000001,
          totalLiquidAssetsVnd: 5000000,
        ),
        throwsA(isA<OverAllocationException>()),
      );

      // Envelope balance remained 0 ₫
      final env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(0));

      // Exact boundary allocation (4.000.000 ₫) succeeds!
      await db.envelopeDao.allocate(
        envelopeId: envId,
        amountVnd: 4000000,
        totalLiquidAssetsVnd: 5000000,
      );
      final envAfter = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(envAfter.reservedBalanceVnd, equals(4000000));

      // Now available to allocate is 0 ₫. Any further allocation (> 0) must be rejected
      final availableZero =
          await db.envelopeDao.getAvailableToAllocate(5000000);
      expect(availableZero, equals(0));
      expect(
        () => db.envelopeDao.allocate(
          envelopeId: envId,
          amountVnd: 1,
          totalLiquidAssetsVnd: 5000000,
        ),
        throwsA(isA<OverAllocationException>()),
      );
    });

    test(
        '4.2 Over-allocation guard rejects when available-to-allocate is negative (cash deficit)',
        () async {
      // Liquid assets = 2.000.000 ₫, but buffer = 3.000.000 ₫ -> Available = -1.000.000 ₫
      await (db.update(db.settings)).write(
        const SettingsCompanion(
          minimumCashBufferVnd: Value(3000000),
        ),
      );

      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(0),
            ),
          );

      final available = await db.envelopeDao.getAvailableToAllocate(2000000);
      expect(available, equals(-1000000));

      expect(
        () => db.envelopeDao.allocate(
          envelopeId: envId,
          amountVnd: 100000,
          totalLiquidAssetsVnd: 2000000,
        ),
        throwsA(isA<OverAllocationException>()),
      );
    });

    test('4.3 Negative allocation or transfer amounts trigger ArgumentError',
        () async {
      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ test',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(1000000),
            ),
          );

      expect(
        () => db.envelopeDao.allocate(
          envelopeId: envId,
          amountVnd: 0,
          totalLiquidAssetsVnd: 10000000,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => db.envelopeDao.allocate(
          envelopeId: envId,
          amountVnd: -500,
          totalLiquidAssetsVnd: 10000000,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => db.envelopeDao.release(
          envelopeId: envId,
          amountVnd: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => db.envelopeDao.release(
          envelopeId: envId,
          amountVnd: -100,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        '4.4 Transfer to same envelope (from == to) throws InvalidEnvelopeOperationException',
        () async {
      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ chuyển cho chính mình',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(1000000),
            ),
          );

      expect(
        () => db.envelopeDao.transfer(
          fromEnvelopeId: envId,
          toEnvelopeId: envId,
          amountVnd: 200000,
        ),
        throwsA(isA<InvalidEnvelopeOperationException>()),
      );
    });

    test(
        '4.5 Release & transfer negative deficit guard blocks when allowNegativeException is false',
        () async {
      final envA = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ A nghiêm ngặt',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(300000),
              allowNegativeException: const Value(false),
            ),
          );
      final envB = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ B',
              policy: 'FLEXIBLE',
              reservedBalanceVnd: const Value(100000),
            ),
          );

      // Release 300.001 ₫ from 300.000 ₫ reserve
      expect(
        () => db.envelopeDao.release(
          envelopeId: envA,
          amountVnd: 300001,
        ),
        throwsA(isA<SpendingDeficitException>()),
      );

      // Transfer 300.001 ₫ from envA to envB
      expect(
        () => db.envelopeDao.transfer(
          fromEnvelopeId: envA,
          toEnvelopeId: envB,
          amountVnd: 300001,
        ),
        throwsA(isA<SpendingDeficitException>()),
      );

      // Invariants: envA and envB balances unchanged
      expect(
        (await (db.select(db.envelopes)..where((e) => e.id.equals(envA)))
                .getSingle())
            .reservedBalanceVnd,
        equals(300000),
      );
      expect(
        (await (db.select(db.envelopes)..where((e) => e.id.equals(envB)))
                .getSingle())
            .reservedBalanceVnd,
        equals(100000),
      );
    });

    test(
        '4.6 Release & transfer allow deficit when allowNegativeException is true',
        () async {
      final envA = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ A linh hoạt âm',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(200000),
              allowNegativeException: const Value(true),
            ),
          );
      final envB = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ B',
              policy: 'FLEXIBLE',
              reservedBalanceVnd: const Value(0),
            ),
          );

      // Transfer 500.000 ₫ from envA (reserve 200k) -> envA enters -300.000 ₫
      await db.envelopeDao.transfer(
        fromEnvelopeId: envA,
        toEnvelopeId: envB,
        amountVnd: 500000,
      );

      expect(
        (await (db.select(db.envelopes)..where((e) => e.id.equals(envA)))
                .getSingle())
            .reservedBalanceVnd,
        equals(-300000),
      );
      expect(
        (await (db.select(db.envelopes)..where((e) => e.id.equals(envB)))
                .getSingle())
            .reservedBalanceVnd,
        equals(500000),
      );
    });

    test(
        '4.7 LedgerDao.postTransaction with linkedEnvelopeId and SPEND enforces envelope deficit guard when allowNegativeException is false',
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
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      // Create envelope with reserved balance 100.000 ₫ and allowNegativeException = false
      final strictEnvId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ nghiêm ngặt không cho âm',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(100000),
              allowNegativeException: const Value(false),
            ),
          );

      // Posting an expense of 500.000 ₫ linked to strict envelope must throw SpendingDeficitException
      expect(
        () => db.ledgerDao.postTransactionCommand(
          PostTransactionCommand.expense(
            sourceAccountId: cashId,
            categoryId: 3,
            amountVnd: 500000,
            occurredAt: 2000,
            description: 'Chi tiêu vượt quá quỹ',
            linkedEnvelopeId: strictEnvId,
          ),
        ),
        throwsA(isA<SpendingDeficitException>()),
      );

      // Envelope balance remained unchanged at 100.000 ₫
      final env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(strictEnvId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(100000));

      // In contrast, an envelope with allowNegativeException = true permits spending into deficit
      final flexibleEnvId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ cho phép âm',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(100000),
              allowNegativeException: const Value(true),
            ),
          );

      final txId = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashId,
          categoryId: 3,
          amountVnd: 500000,
          occurredAt: 3000,
          description: 'Chi tiêu quỹ cho phép âm',
          linkedEnvelopeId: flexibleEnvId,
        ),
      );
      expect(txId, isPositive);

      final flexEnv = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(flexibleEnvId)))
          .getSingle();
      expect(flexEnv.reservedBalanceVnd, equals(-400000));
    });
  });

  group('CHALLENGE 5: Void & Edit Chains, Audit Preservation & Reversals', () {
    test(
        '5.1 Voiding non-existent transaction throws InvalidTransactionException',
        () async {
      expect(
        () => db.ledgerDao.voidTransaction(999999),
        throwsA(isA<InvalidTransactionException>()),
      );
    });

    test(
        '5.2 Voiding an already VOIDED transaction throws InvalidTransactionException',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );
      final txId = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 1000000,
          occurredAt: 1000,
        ),
      );

      // Void once
      await db.ledgerDao.voidTransaction(txId);

      // Attempt void twice
      expect(
        () => db.ledgerDao.voidTransaction(txId),
        throwsA(isA<InvalidTransactionException>()),
      );
    });

    test(
        '5.3 Sequential Edit Chain (T1 -> T2 -> T3 -> T4): audit history links, single active version, exact net balance',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      // Initial funding: 10.000.000 ₫
      await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.openingAsset(
          assetAccountId: cashId,
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      // T1: Initial expense 100.000 ₫
      final t1 = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashId,
          categoryId: 3,
          amountVnd: 100000,
          occurredAt: 2000,
          description: 'T1: Chi 100k',
        ),
      );
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(9900000));

      // T2: Edit to 200.000 ₫
      final t2 = await db.ledgerDao.editTransaction(
        originalTxId: t1,
        txType: 'EXPENSE',
        description: 'T2: Sửa thành 200k',
        occurredAt: 2100,
        newPostings: PostingMatrix.buildExpense(
          sourceAccountId: cashId,
          categoryId: 3,
          amountVnd: 200000,
        ),
      );
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(9800000));

      // T3: Edit to 500.000 ₫
      final t3 = await db.ledgerDao.editTransaction(
        originalTxId: t2,
        txType: 'EXPENSE',
        description: 'T3: Sửa thành 500k',
        occurredAt: 2200,
        newPostings: PostingMatrix.buildExpense(
          sourceAccountId: cashId,
          categoryId: 3,
          amountVnd: 500000,
        ),
      );
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(9500000));

      // T4: Edit to 1.500.000 ₫
      final t4 = await db.ledgerDao.editTransaction(
        originalTxId: t3,
        txType: 'EXPENSE',
        description: 'T4: Sửa thành 1.5M',
        occurredAt: 2300,
        newPostings: PostingMatrix.buildExpense(
          sourceAccountId: cashId,
          categoryId: 3,
          amountVnd: 1500000,
        ),
      );

      // Final cash balance: 10M - 1.5M = 8.5M
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(8500000));
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
        equals(1500000),
      );

      // Verify Audit Trail Links:
      final rowT1 = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(t1)))
          .getSingle();
      final rowT2 = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(t2)))
          .getSingle();
      final rowT3 = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(t3)))
          .getSingle();
      final rowT4 = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(t4)))
          .getSingle();

      expect(rowT1.status, equals('SUPERSEDED'));
      expect(rowT1.replacedByTxId, equals(t2));

      expect(rowT2.status, equals('SUPERSEDED'));
      expect(rowT2.replacedByTxId, equals(t3));

      expect(rowT3.status, equals('SUPERSEDED'));
      expect(rowT3.replacedByTxId, equals(t4));

      expect(rowT4.status, equals('POSTED'));
      expect(rowT4.replacedByTxId, isNull);

      // Verify Reversals created for T1, T2, T3:
      final r1 = await (db.select(db.journalTransactions)
            ..where((t) => t.reversesTxId.equals(t1)))
          .getSingle();
      final r2 = await (db.select(db.journalTransactions)
            ..where((t) => t.reversesTxId.equals(t2)))
          .getSingle();
      final r3 = await (db.select(db.journalTransactions)
            ..where((t) => t.reversesTxId.equals(t3)))
          .getSingle();

      expect(r1.txType, equals('REVERSAL'));
      expect(r2.txType, equals('REVERSAL'));
      expect(r3.txType, equals('REVERSAL'));

      // Attempting to edit or void superseded transactions throws InvalidTransactionException
      expect(
        () => db.ledgerDao.voidTransaction(t1),
        throwsA(isA<InvalidTransactionException>()),
      );
      expect(
        () => db.ledgerDao.voidTransaction(t2),
        throwsA(isA<InvalidTransactionException>()),
      );
      expect(
        () => db.ledgerDao.voidTransaction(t3),
        throwsA(isA<InvalidTransactionException>()),
      );

      // Clean transactions list contains only the Opening Asset and T4!
      final cleanTxs = await db.ledgerDao.getCleanTransactions();
      expect(cleanTxs.length, equals(2));
      expect(cleanTxs.map((t) => t.id), containsAll([t4]));
      expect(cleanTxs.map((t) => t.status).every((s) => s == 'POSTED'), isTrue);
      expect(cleanTxs.map((t) => t.txType).contains('REVERSAL'), isFalse);

      // Finally, void the head of chain T4:
      final revT4 = await db.ledgerDao.voidTransaction(t4);
      expect(revT4, isPositive);

      // All expenses offset back to 0 ₫!
      expect(
        await db.ledgerDao
            .getAccountBalance(PostingMatrix.defaultExpenseAccountId),
        equals(0),
      );
      // Cash restored completely to 10.000.000 ₫
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(10000000));

      // Clean transactions now contains ONLY the initial opening asset transaction!
      final finalCleanTxs = await db.ledgerDao.getCleanTransactions();
      expect(finalCleanTxs.length, equals(1));
    });

    test(
        '5.4 Voiding an expense with linked envelope movement cleanly restores envelope reserve',
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
          amountVnd: 10000000,
          occurredAt: 1000,
        ),
      );

      final envId = await db.into(db.envelopes).insert(
            EnvelopesCompanion.insert(
              name: 'Quỹ du lịch',
              policy: 'PROTECTED',
              reservedBalanceVnd: const Value(2000000),
            ),
          );

      // Spend 500.000 ₫ from envelope
      final spendTxId = await db.ledgerDao.postTransactionCommand(
        PostTransactionCommand.expense(
          sourceAccountId: cashId,
          categoryId: 3,
          amountVnd: 500000,
          occurredAt: 2000,
          description: 'Vé máy bay',
          linkedEnvelopeId: envId,
        ),
      );

      var env = await (db.select(db.envelopes)
            ..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(1500000));

      // Void the spend transaction
      await db.ledgerDao.voidTransaction(spendTxId);

      // Envelope reserve is restored to exactly 2.000.000 ₫
      env = await (db.select(db.envelopes)..where((e) => e.id.equals(envId)))
          .getSingle();
      expect(env.reservedBalanceVnd, equals(2000000));

      // Verify REVERSAL envelope movement record exists
      final revMovement = await (db.select(db.envelopeMovements)
            ..where((m) =>
                m.destEnvelopeId.equals(envId) &
                m.movementType.equals('REVERSAL')))
          .get();
      expect(revMovement.length, equals(1));
      expect(revMovement.first.amountVnd, equals(500000));
    });

    test('5.5 LedgerDao.voidTransaction rejects voiding a REVERSAL transaction',
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

      // Void original -> creates reversalTxId
      final reversalTxId = await db.ledgerDao.voidTransaction(origTxId);
      final revTx = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(reversalTxId)))
          .getSingle();
      expect(revTx.txType, equals('REVERSAL'));
      expect(revTx.status, equals('POSTED'));

      // Invariant: voidTransaction must reject voiding a REVERSAL transaction as reversals are immutable audit records
      expect(
        () => db.ledgerDao.voidTransaction(reversalTxId),
        throwsA(
          isA<InvalidTransactionException>().having(
            (e) => e.message,
            'message',
            contains('Cannot void a REVERSAL transaction'),
          ),
        ),
      );

      final revTxAfter = await (db.select(db.journalTransactions)
            ..where((t) => t.id.equals(reversalTxId)))
          .getSingle();
      expect(revTxAfter.status, equals('POSTED'));
    });
  });

  group('CHALLENGE 6: Extreme Boundaries, Safe VND & Idempotency', () {
    test('6.1 Boundary transaction at maxSafeVnd (9 quadrillion VND)',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Kho tiền quốc gia',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      final cmd = PostTransactionCommand.openingAsset(
        assetAccountId: cashId,
        amountVnd: VndMoney.maxSafeVnd,
        occurredAt: 1000,
      );

      final txId = await db.ledgerDao.postTransactionCommand(cmd);
      expect(txId, isPositive);

      final balance = await db.ledgerDao.getAccountBalance(cashId);
      expect(balance, equals(VndMoney.maxSafeVnd));
      expect(await db.ledgerDao.getTotalLiquidAssets(),
          equals(VndMoney.maxSafeVnd));
      expect(await db.ledgerDao.getNetWorth(), equals(VndMoney.maxSafeVnd));
    });

    test('6.2 Exceeding maxSafeVnd throws ArgumentError at PostingLeg factory',
        () {
      expect(
        () => PostingLeg.debit(
          accountId: 1,
          amountVnd: VndMoney.maxSafeVnd + 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PostingLeg.credit(
          accountId: 1,
          amountVnd: VndMoney.maxSafeVnd + 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('6.3 Zero and negative amount in PostingLeg throws ArgumentError', () {
      expect(
        () => PostingLeg.debit(accountId: 1, amountVnd: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => PostingLeg.credit(accountId: 1, amountVnd: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('6.4 Idempotency key conflict aborts insertion and preserves balance',
        () async {
      final cashId = await db.into(db.ledgerAccounts).insert(
            LedgerAccountsCompanion.insert(
              name: 'Tiền mặt',
              kind: 'ASSET_CASH',
              isLiquid: const Value(true),
              createdAt: 1000,
            ),
          );

      final cmd1 = PostTransactionCommand.openingAsset(
        assetAccountId: cashId,
        amountVnd: 5000000,
        occurredAt: 1000,
        idempotencyKey: 'idemp-stress-001',
      );
      final id1 = await db.ledgerDao.postTransactionCommand(cmd1);
      expect(id1, isPositive);

      final cmd2 = PostTransactionCommand.openingAsset(
        assetAccountId: cashId,
        amountVnd: 5000000,
        occurredAt: 1000,
        idempotencyKey: 'idemp-stress-001', // duplicate key
      );

      expect(
        () => db.ledgerDao.postTransactionCommand(cmd2),
        throwsA(isA<SqliteException>()),
      );

      // Balance remains 5.000.000 ₫ (not doubled to 10M)
      expect(await db.ledgerDao.getAccountBalance(cashId), equals(5000000));
    });
  });
}
