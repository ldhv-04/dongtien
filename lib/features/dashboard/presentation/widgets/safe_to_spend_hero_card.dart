import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../domain/forecasting/safe_to_spend_calculator.dart';
import 'safe_to_spend_breakdown_modal.dart';

/// Safe-to-Spend Hero Card component.
/// Invariant (Scenario 12): When Safe-to-Spend is negative, displays
/// exact deficit in ruby red (never clamped to 0), and daily allowance as 0 ₫/ngày.
class SafeToSpendHeroCard extends StatelessWidget {
  final SafeToSpendResult result;

  const SafeToSpendHeroCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDeficit = result.isDeficit;

    final Color bgColor = isDeficit
        ? AppColors.surfaceAccentRubySecondary
        : AppColors.surfaceAccentVerdantSecondary;

    final Color borderColor =
        isDeficit ? AppColors.borderAccentRuby : AppColors.borderAccentVerdant;

    final Color primaryTextColor = isDeficit
        ? AppColors.textAccentRubyPrimary
        : AppColors.textAccentVerdantPrimary;

    final Color secondaryTextColor = isDeficit
        ? AppColors.textAccentRubySecondary
        : AppColors.textAccentVerdantSecondary;

    return Semantics(
      identifier: 'hero_safe_to_spend',
      child: Container(
        padding: AppSpacing.paddingHero,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Label & Info action button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDeficit
                          ? Icons.warning_amber_rounded
                          : Icons.shield_outlined,
                      size: 20.0,
                      color: primaryTextColor,
                    ),
                    AppSpacing.gapW8,
                    Text(
                      'TIỀN AN TOÀN ĐỂ CHI TIÊU',
                      style: AppTypography.subheadline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Semantics(
                  identifier: 'btn_safe_to_spend_breakdown',
                  button: true,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.info_outline,
                        size: 20.0, color: primaryTextColor),
                    onPressed: () =>
                        showSafeToSpendBreakdownModal(context, result),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH12,

            // Hero Safe-to-Spend Amount
            Semantics(
              identifier: 'text_safe_to_spend_amount',
              child: Text(
                result.safeToSpend.formatVnd(),
                style: AppTypography.displayLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ),
            AppSpacing.gapH4,

            // Daily Allowance / Deficit notice
            Semantics(
              identifier: 'text_daily_allowance',
              child: Text(
                isDeficit
                    ? '0 ₫/ngày (Đang thâm hụt ngân sách)'
                    : '${result.dailyAllowance.formatVnd()}/ngày (${result.daysRemaining} ngày tới)',
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ),

            if (isDeficit) ...[
              AppSpacing.gapH12,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp4,
                  vertical: AppSpacing.sp3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.borderAccentRuby),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16.0, color: AppColors.ruby14),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        'Các nghĩa vụ và quỹ dự phòng vượt quá tiền mặt hiện có.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.ruby14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
