/// Lifecycle status of a journal transaction.
///
/// Matches SQLite CHECK constraint on `journal_transactions(status)`:
/// `CHECK (status IN ('POSTED', 'SUPERSEDED', 'VOIDED'))`
enum TransactionStatus {
  posted('POSTED'),
  superseded('SUPERSEDED'),
  voided('VOIDED');

  final String dbValue;
  const TransactionStatus(this.dbValue);

  /// Parses a [TransactionStatus] from its database string representation.
  static TransactionStatus fromDbValue(String value) {
    return TransactionStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => throw ArgumentError('Unknown TransactionStatus: "$value"'),
    );
  }
}
