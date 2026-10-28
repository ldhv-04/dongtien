import 'package:dongtien/core/money/vnd_money.dart';

/// Immutable single-sided posting leg for a double-entry journal transaction.
///
/// Enforces the database CHECK constraint:
/// `((debit_vnd > 0 AND credit_vnd == 0) OR (credit_vnd > 0 AND debit_vnd == 0))`
class PostingLeg {
  final int accountId;
  final int debitVnd;
  final int creditVnd;
  final int? categoryId;
  final int? envelopeId;

  const PostingLeg._({
    required this.accountId,
    required this.debitVnd,
    required this.creditVnd,
    this.categoryId,
    this.envelopeId,
  });

  /// Creates a debit posting leg.
  ///
  /// Throws [ArgumentError] if [amountVnd] <= 0 or exceeds [VndMoney.maxSafeVnd].
  factory PostingLeg.debit({
    required int accountId,
    required int amountVnd,
    int? categoryId,
    int? envelopeId,
  }) {
    if (amountVnd <= 0) {
      throw ArgumentError.value(
        amountVnd,
        'amountVnd',
        'Debit amount must be strictly positive (> 0 ₫)',
      );
    }
    if (amountVnd > VndMoney.maxSafeVnd) {
      throw ArgumentError.value(
        amountVnd,
        'amountVnd',
        'Amount exceeds max safe VND limit (${VndMoney.maxSafeVnd} ₫)',
      );
    }
    return PostingLeg._(
      accountId: accountId,
      debitVnd: amountVnd,
      creditVnd: 0,
      categoryId: categoryId,
      envelopeId: envelopeId,
    );
  }

  /// Creates a credit posting leg.
  ///
  /// Throws [ArgumentError] if [amountVnd] <= 0 or exceeds [VndMoney.maxSafeVnd].
  factory PostingLeg.credit({
    required int accountId,
    required int amountVnd,
    int? categoryId,
    int? envelopeId,
  }) {
    if (amountVnd <= 0) {
      throw ArgumentError.value(
        amountVnd,
        'amountVnd',
        'Credit amount must be strictly positive (> 0 ₫)',
      );
    }
    if (amountVnd > VndMoney.maxSafeVnd) {
      throw ArgumentError.value(
        amountVnd,
        'amountVnd',
        'Amount exceeds max safe VND limit (${VndMoney.maxSafeVnd} ₫)',
      );
    }
    return PostingLeg._(
      accountId: accountId,
      debitVnd: 0,
      creditVnd: amountVnd,
      categoryId: categoryId,
      envelopeId: envelopeId,
    );
  }

  /// Inverts this posting leg for audit reversals:
  /// Swaps debitVnd and creditVnd while preserving accountId, categoryId, and envelopeId.
  PostingLeg invert() {
    return PostingLeg._(
      accountId: accountId,
      debitVnd: creditVnd,
      creditVnd: debitVnd,
      categoryId: categoryId,
      envelopeId: envelopeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostingLeg &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId &&
          debitVnd == other.debitVnd &&
          creditVnd == other.creditVnd &&
          categoryId == other.categoryId &&
          envelopeId == other.envelopeId;

  @override
  int get hashCode => Object.hash(
        accountId,
        debitVnd,
        creditVnd,
        categoryId,
        envelopeId,
      );

  @override
  String toString() {
    if (debitVnd > 0) {
      return 'PostingLeg.debit(acc: $accountId, debit: $debitVnd ₫, cat: $categoryId, env: $envelopeId)';
    } else {
      return 'PostingLeg.credit(acc: $accountId, credit: $creditVnd ₫, cat: $categoryId, env: $envelopeId)';
    }
  }
}
