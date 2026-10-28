/// Policy governing how an envelope's reserves are treated.
///
/// Matches SQLite CHECK constraint on `envelopes(policy)`:
/// `CHECK (policy IN ('PROTECTED', 'FLEXIBLE'))`
enum EnvelopePolicy {
  protected('PROTECTED'),
  flexible('FLEXIBLE');

  final String dbValue;
  const EnvelopePolicy(this.dbValue);

  /// Parses an [EnvelopePolicy] from its database string representation.
  static EnvelopePolicy fromDbValue(String value) {
    return EnvelopePolicy.values.firstWhere(
      (p) => p.dbValue == value,
      orElse: () => throw ArgumentError('Unknown EnvelopePolicy: "$value"'),
    );
  }
}
