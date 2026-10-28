import 'posting_leg.dart';
import 'posting_matrix.dart';
import 'transaction_type.dart';

/// Command DTO encapsulating a request to post a balanced journal transaction.
class PostTransactionCommand {
  final TransactionType txType;
  final String description;
  final int occurredAt;
  final List<PostingLeg> postings;
  final String? idempotencyKey;
  final int? linkedEnvelopeId;
  final String? envelopeMovementType; // 'SPEND' or 'REFUND_RESTORE'

  const PostTransactionCommand({
    required this.txType,
    required this.description,
    required this.occurredAt,
    required this.postings,
    this.idempotencyKey,
    this.linkedEnvelopeId,
    this.envelopeMovementType,
  });

  /// Factory for Pattern 1: Opening Asset Balance.
  factory PostTransactionCommand.openingAsset({
    required int assetAccountId,
    required int amountVnd,
    required int occurredAt,
    String description = 'Số dư ban đầu',
    String? idempotencyKey,
  }) {
    return PostTransactionCommand(
      txType: TransactionType.openingBalance,
      description: description,
      occurredAt: occurredAt,
      postings: PostingMatrix.buildOpeningAsset(
        assetAccountId: assetAccountId,
        amountVnd: amountVnd,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  /// Factory for Pattern 2: Opening Card Debt Balance.
  factory PostTransactionCommand.openingDebt({
    required int creditCardAccountId,
    required int amountVnd,
    required int occurredAt,
    String description = 'Dư nợ thẻ tín dụng ban đầu',
    String? idempotencyKey,
  }) {
    return PostTransactionCommand(
      txType: TransactionType.openingBalance,
      description: description,
      occurredAt: occurredAt,
      postings: PostingMatrix.buildOpeningDebt(
        creditCardAccountId: creditCardAccountId,
        amountVnd: amountVnd,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  /// Factory for Pattern 3: Operating Income.
  factory PostTransactionCommand.income({
    required int receivingAssetAccountId,
    int incomeAccountId = PostingMatrix.defaultIncomeAccountId,
    required int categoryId,
    required int amountVnd,
    required int occurredAt,
    required String description,
    String? idempotencyKey,
  }) {
    return PostTransactionCommand(
      txType: TransactionType.income,
      description: description,
      occurredAt: occurredAt,
      postings: PostingMatrix.buildIncome(
        receivingAssetAccountId: receivingAssetAccountId,
        incomeAccountId: incomeAccountId,
        categoryId: categoryId,
        amountVnd: amountVnd,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  /// Factory for Patterns 4 & 5: Expense (Cash/Bank or Credit Card).
  factory PostTransactionCommand.expense({
    required int sourceAccountId,
    int expenseAccountId = PostingMatrix.defaultExpenseAccountId,
    required int categoryId,
    required int amountVnd,
    required int occurredAt,
    required String description,
    int? linkedEnvelopeId,
    String? idempotencyKey,
  }) {
    return PostTransactionCommand(
      txType: TransactionType.expense,
      description: description,
      occurredAt: occurredAt,
      postings: PostingMatrix.buildExpense(
        sourceAccountId: sourceAccountId,
        expenseAccountId: expenseAccountId,
        categoryId: categoryId,
        amountVnd: amountVnd,
        envelopeId: linkedEnvelopeId,
      ),
      linkedEnvelopeId: linkedEnvelopeId,
      envelopeMovementType: linkedEnvelopeId != null ? 'SPEND' : null,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Factory for Pattern 6: Credit Card Payment.
  factory PostTransactionCommand.creditCardPayment({
    required int creditCardAccountId,
    required int sourceAssetAccountId,
    required int amountVnd,
    required int occurredAt,
    String description = 'Thanh toán thẻ tín dụng',
    String? idempotencyKey,
  }) {
    return PostTransactionCommand(
      txType: TransactionType.creditCardPayment,
      description: description,
      occurredAt: occurredAt,
      postings: PostingMatrix.buildCreditCardPayment(
        creditCardAccountId: creditCardAccountId,
        sourceAssetAccountId: sourceAssetAccountId,
        amountVnd: amountVnd,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  /// Factory for Pattern 7: Internal Transfer.
  factory PostTransactionCommand.transfer({
    required int sourceAssetAccountId,
    required int destinationAssetAccountId,
    required int amountVnd,
    required int occurredAt,
    String description = 'Chuyển tiền nội bộ',
    String? idempotencyKey,
  }) {
    return PostTransactionCommand(
      txType: TransactionType.transfer,
      description: description,
      occurredAt: occurredAt,
      postings: PostingMatrix.buildInternalTransfer(
        sourceAssetAccountId: sourceAssetAccountId,
        destinationAssetAccountId: destinationAssetAccountId,
        amountVnd: amountVnd,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  /// Factory for Pattern 8: Refund.
  factory PostTransactionCommand.refund({
    required int receivingAccountId,
    int expenseAccountId = PostingMatrix.defaultExpenseAccountId,
    required int categoryId,
    required int amountVnd,
    required int occurredAt,
    required String description,
    int? linkedEnvelopeId,
    String? idempotencyKey,
  }) {
    return PostTransactionCommand(
      txType: TransactionType.refund,
      description: description,
      occurredAt: occurredAt,
      postings: PostingMatrix.buildRefund(
        receivingAccountId: receivingAccountId,
        expenseAccountId: expenseAccountId,
        categoryId: categoryId,
        amountVnd: amountVnd,
        envelopeId: linkedEnvelopeId,
      ),
      linkedEnvelopeId: linkedEnvelopeId,
      envelopeMovementType: linkedEnvelopeId != null ? 'REFUND_RESTORE' : null,
      idempotencyKey: idempotencyKey,
    );
  }
}
