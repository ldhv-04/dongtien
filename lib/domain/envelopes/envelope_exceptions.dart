/// Exception thrown when attempting to allocate more funds than are available in Available-to-Allocate.
class OverAllocationException implements Exception {
  final int requestedVnd;
  final int availableToAllocateVnd;
  final String message;

  const OverAllocationException({
    required this.requestedVnd,
    required this.availableToAllocateVnd,
    this.message = 'Requested allocation exceeds available-to-allocate funds',
  });

  @override
  String toString() =>
      'OverAllocationException: $message (requested: $requestedVnd ₫, available: $availableToAllocateVnd ₫)';
}

/// Exception thrown when spending or transferring from an envelope exceeds its reserved balance
/// and negative exceptions are disabled (`allowNegativeException == false`).
class SpendingDeficitException implements Exception {
  final int requestedVnd;
  final int currentReservedVnd;
  final int envelopeId;
  final String message;

  const SpendingDeficitException({
    required this.requestedVnd,
    required this.currentReservedVnd,
    required this.envelopeId,
    this.message =
        'Spending exceeds reserved balance and negative exceptions are disabled',
  });

  @override
  String toString() =>
      'SpendingDeficitException: $message (requested: $requestedVnd ₫, reserved: $currentReservedVnd ₫, envelope: $envelopeId)';
}

/// Exception thrown when an envelope operation is semantically invalid.
class InvalidEnvelopeOperationException implements Exception {
  final String message;
  const InvalidEnvelopeOperationException(this.message);

  @override
  String toString() => 'InvalidEnvelopeOperationException: $message';
}
