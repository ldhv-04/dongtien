import 'package:dongtien/core/money/vnd_money.dart';
import 'package:dongtien/domain/envelopes/available_to_allocate.dart';
import 'package:dongtien/domain/envelopes/envelope_exceptions.dart';
import 'package:dongtien/domain/envelopes/envelope_movement_type.dart';
import 'package:dongtien/domain/envelopes/envelope_policy.dart';
import 'package:dongtien/domain/ledger/account_kind.dart';
import 'package:dongtien/domain/ledger/ledger_exceptions.dart';
import 'package:dongtien/domain/ledger/posting_leg.dart';
import 'package:dongtien/domain/ledger/posting_matrix.dart';
import 'package:dongtien/domain/ledger/transaction_status.dart';
import 'package:dongtien/domain/ledger/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ledger Domain — AccountKind & Enum Invariants', () {
    test('AccountKind isLiquid returns true only for ASSET_CASH and ASSET_BANK',
        () {
      expect(AccountKind.assetCash.isLiquid, isTrue);
      expect(AccountKind.assetBank.isLiquid, isTrue);
      expect(AccountKind.liabilityCreditCard.isLiquid, isFalse);
      expect(AccountKind.income.isLiquid, isFalse);
      expect(AccountKind.expense.isLiquid, isFalse);
      expect(AccountKind.equityOpening.isLiquid, isFalse);
    });

    test('AccountKind normal balance conventions', () {
      expect(AccountKind.assetCash.isDebitNormal, isTrue);
      expect(AccountKind.assetBank.isDebitNormal, isTrue);
      expect(AccountKind.expense.isDebitNormal, isTrue);

      expect(AccountKind.liabilityCreditCard.isCreditNormal, isTrue);
      expect(AccountKind.income.isCreditNormal, isTrue);
      expect(AccountKind.equityOpening.isCreditNormal, isTrue);
    });

    test('fromDbValue round-trips correctly for all enums', () {
      for (final kind in AccountKind.values) {
        expect(AccountKind.fromDbValue(kind.dbValue), equals(kind));
      }
      expect(() => AccountKind.fromDbValue('INVALID'), throwsArgumentError);

      for (final t in TransactionType.values) {
        expect(TransactionType.fromDbValue(t.dbValue), equals(t));
      }
      expect(() => TransactionType.fromDbValue('INVALID'), throwsArgumentError);

      for (final s in TransactionStatus.values) {
        expect(TransactionStatus.fromDbValue(s.dbValue), equals(s));
      }
      expect(
          () => TransactionStatus.fromDbValue('INVALID'), throwsArgumentError);

      for (final p in EnvelopePolicy.values) {
        expect(EnvelopePolicy.fromDbValue(p.dbValue), equals(p));
      }
      expect(() => EnvelopePolicy.fromDbValue('INVALID'), throwsArgumentError);

      for (final m in EnvelopeMovementType.values) {
        expect(EnvelopeMovementType.fromDbValue(m.dbValue), equals(m));
      }
      expect(() => EnvelopeMovementType.fromDbValue('INVALID'),
          throwsArgumentError);
    });
  });

  group('PostingLeg — One-Sidedness & Inversion', () {
    test('PostingLeg debit creates debit > 0 and credit == 0', () {
      final leg = PostingLeg.debit(accountId: 10, amountVnd: 500000);
      expect(leg.accountId, equals(10));
      expect(leg.debitVnd, equals(500000));
      expect(leg.creditVnd, equals(0));
    });

    test('PostingLeg credit creates credit > 0 and debit == 0', () {
      final leg = PostingLeg.credit(accountId: 10, amountVnd: 500000);
      expect(leg.accountId, equals(10));
      expect(leg.debitVnd, equals(0));
      expect(leg.creditVnd, equals(500000));
    });

    test('PostingLeg rejects non-positive or overflowing amounts', () {
      expect(
        () => PostingLeg.debit(accountId: 1, amountVnd: 0),
        throwsArgumentError,
      );
      expect(
        () => PostingLeg.credit(accountId: 1, amountVnd: -100),
        throwsArgumentError,
      );
      expect(
        () =>
            PostingLeg.debit(accountId: 1, amountVnd: VndMoney.maxSafeVnd + 1),
        throwsArgumentError,
      );
    });

    test('PostingLeg invert() accurately swaps debit and credit amounts', () {
      final debitLeg = PostingLeg.debit(
        accountId: 5,
        amountVnd: 200000,
        categoryId: 1,
        envelopeId: 2,
      );
      final inverted = debitLeg.invert();

      expect(inverted.accountId, equals(5));
      expect(inverted.debitVnd, equals(0));
      expect(inverted.creditVnd, equals(200000));
      expect(inverted.categoryId, equals(1));
      expect(inverted.envelopeId, equals(2));
    });
  });

  group('PostingMatrix — 7 Transaction Types (9 Execution Patterns)', () {
    test('assertBalanced validates SUM(debit) == SUM(credit)', () {
      final balanced = [
        PostingLeg.debit(accountId: 1, amountVnd: 100000),
        PostingLeg.credit(accountId: 2, amountVnd: 100000),
      ];
      expect(() => PostingMatrix.assertBalanced(balanced), returnsNormally);

      final unbalanced = [
        PostingLeg.debit(accountId: 1, amountVnd: 100000),
        PostingLeg.credit(accountId: 2, amountVnd: 90000),
      ];
      expect(
        () => PostingMatrix.assertBalanced(unbalanced),
        throwsA(isA<UnbalancedTransactionException>()),
      );

      expect(
        () => PostingMatrix.assertBalanced([]),
        throwsA(isA<UnbalancedTransactionException>()),
      );
    });

    test(
        'Pattern 1: Opening Asset Balance (Debit Asset, Credit Equity Opening)',
        () {
      final legs = PostingMatrix.buildOpeningAsset(
        assetAccountId: 10,
        amountVnd: 10000000,
      );
      expect(legs.length, equals(2));
      expect(legs[0].accountId, equals(10));
      expect(legs[0].debitVnd, equals(10000000));
      expect(legs[1].accountId, equals(PostingMatrix.equityOpeningAccountId));
      expect(legs[1].creditVnd, equals(10000000));
    });

    test('Pattern 2: Opening Debt Balance (Debit Equity Opening, Credit Card)',
        () {
      final legs = PostingMatrix.buildOpeningDebt(
        creditCardAccountId: 20,
        amountVnd: 5000000,
      );
      expect(legs.length, equals(2));
      expect(legs[0].accountId, equals(PostingMatrix.equityOpeningAccountId));
      expect(legs[0].debitVnd, equals(5000000));
      expect(legs[1].accountId, equals(20));
      expect(legs[1].creditVnd, equals(5000000));
    });

    test('Pattern 3: Income (Debit Asset, Credit Income)', () {
      final legs = PostingMatrix.buildIncome(
        receivingAssetAccountId: 10,
        categoryId: 1,
        amountVnd: 20000000,
      );
      expect(legs.length, equals(2));
      expect(legs[0].accountId, equals(10));
      expect(legs[0].debitVnd, equals(20000000));
      expect(legs[1].accountId, equals(PostingMatrix.defaultIncomeAccountId));
      expect(legs[1].creditVnd, equals(20000000));
      expect(legs[1].categoryId, equals(1));
    });

    test('Patterns 4 & 5: Expense (Debit Expense, Credit Source Cash/Card)',
        () {
      final legs = PostingMatrix.buildExpense(
        sourceAccountId: 10,
        categoryId: 2,
        amountVnd: 150000,
        envelopeId: 3,
      );
      expect(legs.length, equals(2));
      expect(legs[0].accountId, equals(PostingMatrix.defaultExpenseAccountId));
      expect(legs[0].debitVnd, equals(150000));
      expect(legs[0].categoryId, equals(2));
      expect(legs[0].envelopeId, equals(3));
      expect(legs[1].accountId, equals(10));
      expect(legs[1].creditVnd, equals(150000));
    });

    test(
        'Pattern 6: Credit Card Payment (Debit Card, Credit Bank — NEVER an expense)',
        () {
      final legs = PostingMatrix.buildCreditCardPayment(
        creditCardAccountId: 20,
        sourceAssetAccountId: 10,
        amountVnd: 3000000,
      );
      expect(legs.length, equals(2));
      expect(legs[0].accountId, equals(20));
      expect(legs[0].debitVnd, equals(3000000));
      expect(legs[1].accountId, equals(10));
      expect(legs[1].creditVnd, equals(3000000));

      // Assert zero expense account involvement
      for (final leg in legs) {
        expect(leg.accountId != PostingMatrix.defaultExpenseAccountId, isTrue);
      }
    });

    test('Pattern 7: Internal Transfer rejects identical accounts', () {
      expect(
        () => PostingMatrix.buildInternalTransfer(
          sourceAssetAccountId: 10,
          destinationAssetAccountId: 10,
          amountVnd: 1000000,
        ),
        throwsA(isA<InvalidTransactionException>()),
      );

      final legs = PostingMatrix.buildInternalTransfer(
        sourceAssetAccountId: 10,
        destinationAssetAccountId: 11,
        amountVnd: 1000000,
      );
      expect(legs.length, equals(2));
      expect(legs[0].accountId, equals(11));
      expect(legs[0].debitVnd, equals(1000000));
      expect(legs[1].accountId, equals(10));
      expect(legs[1].creditVnd, equals(1000000));
    });

    test('Pattern 8: Refund (Debit Receiving Account, Credit Expense)', () {
      final legs = PostingMatrix.buildRefund(
        receivingAccountId: 10,
        categoryId: 2,
        amountVnd: 50000,
        envelopeId: 3,
      );
      expect(legs.length, equals(2));
      expect(legs[0].accountId, equals(10));
      expect(legs[0].debitVnd, equals(50000));
      expect(legs[1].accountId, equals(PostingMatrix.defaultExpenseAccountId));
      expect(legs[1].creditVnd, equals(50000));
    });

    test('Pattern 9: Reversal inverts legs and remains balanced', () {
      final original = PostingMatrix.buildExpense(
        sourceAccountId: 10,
        categoryId: 2,
        amountVnd: 150000,
      );
      final reversed = PostingMatrix.buildReversal(original);

      expect(reversed.length, equals(2));
      expect(
          reversed[0].accountId, equals(PostingMatrix.defaultExpenseAccountId));
      expect(reversed[0].creditVnd, equals(150000));
      expect(reversed[1].accountId, equals(10));
      expect(reversed[1].debitVnd, equals(150000));
    });
  });

  group('AvailableToAllocateCalculator Invariants', () {
    test('calculate returns total_liquid - reserves - buffer', () {
      final available = AvailableToAllocateCalculator.calculate(
        totalLiquidAssetsVnd: 10000000,
        totalEnvelopeReservesVnd: 2000000,
        minimumCashBufferVnd: 1000000,
      );
      expect(available, equals(7000000));

      final negative = AvailableToAllocateCalculator.calculate(
        totalLiquidAssetsVnd: 2000000,
        totalEnvelopeReservesVnd: 3000000,
        minimumCashBufferVnd: 1000000,
      );
      expect(negative, equals(-2000000));
    });

    test('validateAllocation throws OverAllocationException on over-allocation',
        () {
      // Available = 1.000.000 ₫, request 1.500.000 ₫
      expect(
        () => AvailableToAllocateCalculator.validateAllocation(
          allocateAmountVnd: 1500000,
          availableToAllocateVnd: 1000000,
        ),
        throwsA(isA<OverAllocationException>()),
      );

      // Available is negative (-500.000 ₫), cannot allocate any positive amount
      expect(
        () => AvailableToAllocateCalculator.validateAllocation(
          allocateAmountVnd: 100000,
          availableToAllocateVnd: -500000,
        ),
        throwsA(isA<OverAllocationException>()),
      );
    });

    test(
        'validateSpending throws SpendingDeficitException when negative exception disabled',
        () {
      expect(
        () => AvailableToAllocateCalculator.validateSpending(
          spendAmountVnd: 1000000,
          reservedBalanceVnd: 800000,
          allowNegativeException: false,
          envelopeId: 1,
        ),
        throwsA(isA<SpendingDeficitException>()),
      );

      // Allowed when allowNegativeException is true
      expect(
        () => AvailableToAllocateCalculator.validateSpending(
          spendAmountVnd: 1000000,
          reservedBalanceVnd: 800000,
          allowNegativeException: true,
          envelopeId: 1,
        ),
        returnsNormally,
      );
    });
  });
}
