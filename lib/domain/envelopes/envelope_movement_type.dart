/// Movement types for virtual fund envelopes.
///
/// Matches SQLite CHECK constraint on `envelope_movements(movement_type)`:
/// `CHECK (movement_type IN ('ALLOCATE', 'RELEASE', 'TRANSFER', 'SPEND', 'REFUND_RESTORE', 'REVERSAL'))`
enum EnvelopeMovementType {
  allocate('ALLOCATE'),
  release('RELEASE'),
  transfer('TRANSFER'),
  spend('SPEND'),
  refundRestore('REFUND_RESTORE'),
  reversal('REVERSAL');

  final String dbValue;
  const EnvelopeMovementType(this.dbValue);

  /// Parses an [EnvelopeMovementType] from its database string representation.
  static EnvelopeMovementType fromDbValue(String value) {
    return EnvelopeMovementType.values.firstWhere(
      (m) => m.dbValue == value,
      orElse: () =>
          throw ArgumentError('Unknown EnvelopeMovementType: "$value"'),
    );
  }
}
