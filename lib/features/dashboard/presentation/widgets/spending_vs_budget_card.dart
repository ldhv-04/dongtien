import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../domain/budgeting/category_budget_progress.dart';

/// Spending vs Budget Dashboard Card.
class SpendingVsBudgetCard extends StatelessWidget {
  final MonthlyBudgetSummary summary;
  final VoidCallback onTap;

  const SpendingVsBudgetCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = summary.overallSpentRatio;
    final int pct = (ratio * 100).toInt();

    return Semantics(
      identifier: 'card_spending_vs_budget',
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
                      'CHI TIÊU & NGÂN SÁCH THÁNG',
                      style: AppTypography.subheadline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: summary.exceededCount > 0
                            ? AppColors.textAccentRubyPrimary
                            : (summary.warningCount > 0
                                ? AppColors.textAccentMarigoldPrimary
                                : AppColors.textAccentVerdantPrimary),
                      ),
                    ),
                  ],
                ),
                if (summary.cycleLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Chu kỳ: ${summary.cycleLabel}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                AppSpacing.gapH8,

                // Progress Bar
                ProgressBar(ratio: ratio),
                AppSpacing.gapH8,

                // Metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã chi: ${summary.totalSpentVnd.formatVnd()}',
                      style: VndFormatter.withTabularFigures(
                        AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      'Hạn mức: ${summary.totalLimitVnd.formatVnd()}',
                      style: VndFormatter.withTabularFigures(
                        AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (summary.exceededCount > 0) ...[
                  AppSpacing.gapH8,
                  Text(
                    '⚠️ Có ${summary.exceededCount} danh mục vượt ngân sách.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textAccentRubyPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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
