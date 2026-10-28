import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../domain/virtual_funds_summary.dart';

/// Top summary metrics bar for Virtual Funds (Quỹ tiền):
/// Liquid Assets, Total Reserved, and Available-to-Allocate.
class SummaryHeaderBar extends StatelessWidget {
  final VirtualFundsSummary summary;

  const SummaryHeaderBar({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = summary.availableToAllocate < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                identifier: 'card_summary_liquid',
                container: true,
                child: _MetricCard(
                  label: 'Tài sản khả dụng',
                  amountVnd: summary.totalLiquidAssets,
                  subtext: 'Tiền mặt & Ngân hàng',
                  bgColor: AppColors.surfacePrimary,
                  borderColor: AppColors.borderSecondary,
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ),
            AppSpacing.gapW8,
            Expanded(
              child: Semantics(
                identifier: 'card_summary_reserved',
                container: true,
                child: _MetricCard(
                  label: 'Đã phân bổ quỹ',
                  amountVnd: summary.totalEnvelopeReserves,
                  subtext:
                      'Bảo vệ: ${VndFormatter.format(summary.totalProtectedReserves)}',
                  bgColor: AppColors.surfacePrimary,
                  borderColor: AppColors.borderSecondary,
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapH8,
        Semantics(
          identifier: 'card_summary_available',
          container: true,
          child: Container(
            padding: AppSpacing.paddingCard,
            decoration: BoxDecoration(
              color: isOver
                  ? AppColors.surfaceAccentRubySecondary
                  : AppColors.surfaceAccentVerdantSecondary,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isOver
                    ? AppColors.borderAccentRuby
                    : AppColors.borderAccentVerdant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sẵn sàng phân bổ',
                      style: AppTypography.subheadline,
                    ),
                    Text(
                      'Dự phòng tối thiểu: ${VndFormatter.format(summary.minimumCashBuffer)}',
                      style: VndFormatter.withTabularFigures(
                        AppTypography.caption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  VndFormatter.format(summary.availableToAllocate),
                  style: VndFormatter.withTabularFigures(
                    AppTypography.titleLarge.copyWith(
                      color: isOver
                          ? AppColors.textAccentRubyPrimary
                          : AppColors.textAccentVerdantPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int amountVnd;
  final String subtext;
  final Color bgColor;
  final Color borderColor;
  final Color valueColor;

  const _MetricCard({
    required this.label,
    required this.amountVnd,
    required this.subtext,
    required this.bgColor,
    required this.borderColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(
            VndFormatter.format(amountVnd),
            style: VndFormatter.withTabularFigures(
              AppTypography.bodyMedium.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: VndFormatter.withTabularFigures(AppTypography.microCaption),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
