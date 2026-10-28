import 'ledger_exceptions.dart';
import 'posting_leg.dart';

/// Pure Dart double-entry posting engine.
///
/// Implements the 7 transaction types (9 execution patterns) asserting the fundamental
/// accounting equation of motion:
/// `SUM(debit_vnd) == SUM(credit_vnd)`.
class PostingMatrix {
  const PostingMatrix._();

  /// Foundational system account IDs seeded in `app_database.dart`:
  /// - ID 1: EQUITY_OPENING ("Vốn ban đầu")
  /// - ID 2: INCOME ("Thu nhập")
  /// - ID 3: EXPENSE ("Chi tiêu")
  static const int equityOpeningAccountId = 1;
  static const int defaultIncomeAccountId = 2;
  static const int defaultExpenseAccountId = 3;

  /// Validates that all legs are strictly balanced: `sum(debit) == sum(credit)`.
  ///
  /// Throws [UnbalancedTransactionException] if the list is empty or debit != credit.
  static void assertBalanced(List<PostingLeg> postings) {
    if (postings.isEmpty) {
      throw const UnbalancedTransactionException(
        totalDebit: 0,
        totalCredit: 0,
        message: 'Transaction has no posting legs',
      );
    }

    int totalDebit = 0;
    int totalCredit = 0;

    for (final leg in postings) {
      totalDebit += leg.debitVnd;
      totalCredit += leg.creditVnd;
    }

    if (totalDebit != totalCredit) {
      throw UnbalancedTransactionException(
        totalDebit: totalDebit,
        totalCredit: totalCredit,
      );
    }
  }

  /// Pattern 1: Opening Asset Balance (Cash or Bank account).
  ///
  /// - Debit: Asset Account ([assetAccountId])
  /// - Credit: Equity Opening Balance (ID 1)
  ///
  /// Economic invariant: Increases liquid assets; operating income is 0 ₫.
  static List<PostingLeg> buildOpeningAsset({
    required int assetAccountId,
    required int amountVnd,
  }) {
    final legs = [
      PostingLeg.debit(accountId: assetAccountId, amountVnd: amountVnd),
      PostingLeg.credit(
          accountId: equityOpeningAccountId, amountVnd: amountVnd),
    ];
    assertBalanced(legs);
    return legs;
  }

  /// Pattern 2: Opening Card Debt Balance (Credit Card liability).
  ///
  /// - Debit: Equity Opening Balance (ID 1)
  /// - Credit: Credit Card Liability ([creditCardAccountId])
  ///
  /// Economic invariant: Increases card debt; liquid assets are 0 ₫.
  static List<PostingLeg> buildOpeningDebt({
    required int creditCardAccountId,
    required int amountVnd,
  }) {
    final legs = [
      PostingLeg.debit(accountId: equityOpeningAccountId, amountVnd: amountVnd),
      PostingLeg.credit(accountId: creditCardAccountId, amountVnd: amountVnd),
    ];
    assertBalanced(legs);
    return legs;
  }

  /// Pattern 3: Operating Income (Salary, Bonus, etc.).
  ///
  /// - Debit: Receiving Asset Account ([receivingAssetAccountId])
  /// - Credit: Income Account ([incomeAccountId], default ID 2) linked to [categoryId]
  ///
  /// Economic invariant: Liquid assets increase; recognized income increases.
  static List<PostingLeg> buildIncome({
    required int receivingAssetAccountId,
    int incomeAccountId = defaultIncomeAccountId,
    required int categoryId,
    required int amountVnd,
  }) {
    final legs = [
      PostingLeg.debit(
          accountId: receivingAssetAccountId, amountVnd: amountVnd),
      PostingLeg.credit(
        accountId: incomeAccountId,
        amountVnd: amountVnd,
        categoryId: categoryId,
      ),
    ];
    assertBalanced(legs);
    return legs;
  }

  /// Patterns 4 & 5: Cash / Bank or Credit Card Expense.
  ///
  /// - Debit: Expense Account ([expenseAccountId], default ID 3) linked to [categoryId] & optional [envelopeId]
  /// - Credit: Source Account ([sourceAccountId]: Cash, Bank, or Credit Card)
  ///
  /// Economic invariant:
  /// - If source is Cash/Bank: Liquid assets decrease; gross expense increases.
  /// - If source is Credit Card: Card debt increases; liquid assets unchanged; gross expense increases.
  static List<PostingLeg> buildExpense({
    required int sourceAccountId,
    int expenseAccountId = defaultExpenseAccountId,
    required int categoryId,
    required int amountVnd,
    int? envelopeId,
  }) {
    final legs = [
      PostingLeg.debit(
        accountId: expenseAccountId,
        amountVnd: amountVnd,
        categoryId: categoryId,
        envelopeId: envelopeId,
      ),
      PostingLeg.credit(
        accountId: sourceAccountId,
        amountVnd: amountVnd,
      ),
    ];
    assertBalanced(legs);
    return legs;
  }

  /// Pattern 6: Credit Card Payment.
  ///
  /// - Debit: Credit Card Liability Account ([creditCardAccountId])
  /// - Credit: Paying Asset Account ([sourceAssetAccountId]: Cash or Bank)
  ///
  /// Economic invariant: Liquid assets decrease; card debt decreases.
  /// CRITICAL: NEVER touches an expense account. Zero operating expense generated.
  static List<PostingLeg> buildCreditCardPayment({
    required int creditCardAccountId,
    required int sourceAssetAccountId,
    required int amountVnd,
  }) {
    if (creditCardAccountId == sourceAssetAccountId) {
      throw const InvalidTransactionException(
        'Credit card account and source paying account cannot be the same',
      );
    }
    final legs = [
      PostingLeg.debit(accountId: creditCardAccountId, amountVnd: amountVnd),
      PostingLeg.credit(accountId: sourceAssetAccountId, amountVnd: amountVnd),
    ];
    assertBalanced(legs);
    return legs;
  }

  /// Pattern 7: Internal Transfer between liquid accounts.
  ///
  /// - Debit: Destination Asset Account ([destinationAssetAccountId])
  /// - Credit: Source Asset Account ([sourceAssetAccountId])
  ///
  /// Economic invariant: Total liquid assets, net worth, and income/expense are unchanged.
  static List<PostingLeg> buildInternalTransfer({
    required int sourceAssetAccountId,
    required int destinationAssetAccountId,
    required int amountVnd,
  }) {
    if (sourceAssetAccountId == destinationAssetAccountId) {
      throw const InvalidTransactionException(
        'Source and destination accounts must be different for internal transfer',
      );
    }
    final legs = [
      PostingLeg.debit(
          accountId: destinationAssetAccountId, amountVnd: amountVnd),
      PostingLeg.credit(accountId: sourceAssetAccountId, amountVnd: amountVnd),
    ];
    assertBalanced(legs);
    return legs;
  }

  /// Pattern 8: Expense Refund.
  ///
  /// - Debit: Receiving Account ([receivingAccountId]: Cash, Bank, or Credit Card)
  /// - Credit: Expense Account ([expenseAccountId], default ID 3) linked to [categoryId] & optional [envelopeId]
  ///
  /// Economic invariant: Restores liquid cash or lowers card debt; offsets gross expense.
  static List<PostingLeg> buildRefund({
    required int receivingAccountId,
    int expenseAccountId = defaultExpenseAccountId,
    required int categoryId,
    required int amountVnd,
    int? envelopeId,
  }) {
    final legs = [
      PostingLeg.debit(accountId: receivingAccountId, amountVnd: amountVnd),
      PostingLeg.credit(
        accountId: expenseAccountId,
        amountVnd: amountVnd,
        categoryId: categoryId,
        envelopeId: envelopeId,
      ),
    ];
    assertBalanced(legs);
    return legs;
  }

  /// Pattern 9: Audit Reversal.
  ///
  /// Inverts all original posting legs (debit becomes credit, credit becomes debit).
  ///
  /// Economic invariant: Net impact of original + reversal across all ledger accounts is exactly 0 ₫.
  static List<PostingLeg> buildReversal(List<PostingLeg> originalPostings) {
    if (originalPostings.isEmpty) {
      throw const InvalidTransactionException(
          'Cannot reverse empty postings list');
    }
    final reversed = originalPostings.map((leg) => leg.invert()).toList();
    assertBalanced(reversed);
    return reversed;
  }
}
