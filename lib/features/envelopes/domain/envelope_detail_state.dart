import '../../../core/database/app_database.dart';

/// State representation for an Envelope Detail Screen.
class EnvelopeDetailState {
  final Envelope envelope;
  final List<EnvelopeMovement> movements;
  final Map<int, String> envelopeNames;

  const EnvelopeDetailState({
    required this.envelope,
    required this.movements,
    required this.envelopeNames,
  });

  bool get isDeficit => envelope.reservedBalanceVnd < 0;

  double? get progressRatio {
    if (envelope.targetAmountVnd == null || envelope.targetAmountVnd! <= 0) {
      return null;
    }
    if (envelope.reservedBalanceVnd <= 0) return 0.0;
    return envelope.reservedBalanceVnd / envelope.targetAmountVnd!;
  }

  int? get targetShortfall {
    if (envelope.targetAmountVnd == null) return null;
    final diff = envelope.targetAmountVnd! - envelope.reservedBalanceVnd;
    return diff > 0 ? diff : 0;
  }
}
