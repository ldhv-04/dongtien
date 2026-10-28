/// Transaction types supported by DongTien double-entry general ledger.
///
/// Matches SQLite CHECK constraint on `journal_transactions(tx_type)`:
/// `CHECK (tx_type IN ('OPENING_BALANCE', 'INCOME', 'EXPENSE', 'TRANSFER', 'CREDIT_CARD_PAYMENT', 'REFUND', 'REVERSAL'))`
enum TransactionType {
  openingBalance('OPENING_BALANCE'),
  income('INCOME'),
  expense('EXPENSE'),
  transfer('TRANSFER'),
  creditCardPayment('CREDIT_CARD_PAYMENT'),
  refund('REFUND'),
  reversal('REVERSAL');

  final String dbValue;
  const TransactionType(this.dbValue);

  /// Parses a [TransactionType] from its database string representation.
  static TransactionType fromDbValue(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => throw ArgumentError('Unknown TransactionType: "$value"'),
    );
  }
}
