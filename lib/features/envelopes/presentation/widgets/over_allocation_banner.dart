import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/money/vnd_formatter.dart';

/// Warning banner rendered when Available-to-Allocate is negative.
class OverAllocationBanner extends StatelessWidget {
  final int overAllocatedAmountVnd;

  const OverAllocationBanner({
    super.key,
    required this.overAllocatedAmountVnd,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'banner_over_allocation',
      container: true,
      child: Container(
        padding: AppSpacing.paddingCard,
        decoration: BoxDecoration(
          color: AppColors.surfaceAccentRubySecondary,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.borderAccentRuby),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.iconAccentRuby,
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cảnh báo bội phân bổ quỹ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textAccentRubyPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng tiền đã phân bổ vào các quỹ và dự phòng vượt quá tài sản khả dụng thực tế ${VndFormatter.format(overAllocatedAmountVnd)}. Hãy rút bớt từ quỹ linh hoạt để cân bằng!',
                    style: VndFormatter.withTabularFigures(
                      AppTypography.caption.copyWith(
                        color: AppColors.textAccentRubyPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
