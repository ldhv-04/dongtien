/// Exception thrown when a journal transaction fails the fundamental accounting invariant:
/// SUM(debit_vnd) == SUM(credit_vnd).
class UnbalancedTransactionException implements Exception {
  final int totalDebit;
  final int totalCredit;
  final String message;

  const UnbalancedTransactionException({
    required this.totalDebit,
    required this.totalCredit,
    this.message = 'Transaction is unbalanced: sum(debit) != sum(credit)',
  });

  @override
  String toString() =>
      'UnbalancedTransactionException: $message (debit: $totalDebit, credit: $totalCredit)';
}

/// Exception thrown when a transaction violates business rules or constraints.
class InvalidTransactionException implements Exception {
  final String message;
  const InvalidTransactionException(this.message);

  @override
  String toString() => 'InvalidTransactionException: $message';
}

/// Exception thrown when an operation references an account of inappropriate kind.
class AccountKindMismatchException implements Exception {
  final String message;
  const AccountKindMismatchException(this.message);

  @override
  String toString() => 'AccountKindMismatchException: $message';
}
