import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/widgets/progress_bar.dart';

/// Card widget displaying a single Protected or Flexible Virtual Fund Envelope.
class EnvelopeCard extends StatelessWidget {
  final Envelope envelope;
  final VoidCallback onTap;

  const EnvelopeCard({
    super.key,
    required this.envelope,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProtected = envelope.policy == 'PROTECTED';
    final isDeficit = envelope.reservedBalanceVnd < 0;
    final hasTarget =
        envelope.targetAmountVnd != null && envelope.targetAmountVnd! > 0;
    final double ratio = hasTarget
        ? (envelope.reservedBalanceVnd > 0
            ? envelope.reservedBalanceVnd / envelope.targetAmountVnd!
            : 0.0)
        : 0.0;

    return Semantics(
      identifier: 'card_envelope_${envelope.id}',
      button: true,
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: AppSpacing.paddingCard,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isDeficit
                    ? AppColors.borderAccentRuby
                    : AppColors.borderSecondary,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isProtected ? Icons.lock_outline : Icons.tune_outlined,
                      size: 18,
                      color: isProtected
                          ? AppColors.iconAccentVerdant
                          : AppColors.iconAccentSandstone,
                    ),
                    AppSpacing.gapW8,
                    Expanded(
                      child:
                          Text(envelope.name, style: AppTypography.bodyMedium),
                    ),
                    if (isDeficit)
                      Semantics(
                        identifier: 'badge_deficit_${envelope.id}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAccentRubySecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Thâm hụt',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textAccentRubyPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.gapH8,
                Text(
                  VndFormatter.format(envelope.reservedBalanceVnd),
                  style: VndFormatter.withTabularFigures(
                    AppTypography.headline.copyWith(
                      color: isDeficit
                          ? AppColors.textAccentRubyPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (hasTarget) ...[
                  AppSpacing.gapH8,
                  ProgressBar(ratio: ratio),
                  AppSpacing.gapH4,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(ratio * 100).round()}% • Mục tiêu: ${VndFormatter.format(envelope.targetAmountVnd!)}',
                        style: VndFormatter.withTabularFigures(
                          AppTypography.caption,
                        ),
                      ),
                      if (envelope.targetDateMs != null)
                        Builder(
                          builder: (_) {
                            final dt = DateTime.fromMillisecondsSinceEpoch(
                              envelope.targetDateMs!,
                            );
                            final dStr =
                                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                            return Text(
                              'Hạn: $dStr',
                              style: VndFormatter.withTabularFigures(
                                AppTypography.caption,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
