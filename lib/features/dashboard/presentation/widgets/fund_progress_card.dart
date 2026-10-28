import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';

/// Mini Virtual Funds progress preview on Dashboard.
class FundProgressCard extends StatelessWidget {
  final List<Envelope> envelopes;
  final VoidCallback onTap;

  const FundProgressCard({
    super.key,
    required this.envelopes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int totalReserved =
        envelopes.fold(0, (sum, e) => sum + e.reservedBalanceVnd);

    return Semantics(
      identifier: 'card_summary_reserved',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: AppSpacing.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QUỸ TIỀN ẢO',
                      style: AppTypography.subheadline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      VndFormatter.format(totalReserved),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textAccentVerdantPrimary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapH8,
                Text(
                  '${envelopes.length} quỹ đang hoạt động.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
