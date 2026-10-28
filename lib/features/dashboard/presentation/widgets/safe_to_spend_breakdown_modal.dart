import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../domain/forecasting/safe_to_spend_calculator.dart';

void showSafeToSpendBreakdownModal(
    BuildContext context, SafeToSpendResult result) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeToSpendBreakdownModal(result: result),
  );
}

/// 4-Term Formula Breakdown Modal Sheet.
/// Explicitly exposes: Liquid Assets - Protected Reserves - Unfunded Bills - Buffer.
class SafeToSpendBreakdownModal extends StatelessWidget {
  final SafeToSpendResult result;

  const SafeToSpendBreakdownModal({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final breakdown = result.breakdown;

    return Semantics(
      identifier: 'modal_safe_to_spend_breakdown',
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: AppSpacing.paddingModal,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.borderSecondary,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              AppSpacing.gapH16,

              // Sheet Title
              Text(
                'Công thức Tiền an toàn chi tiêu',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapH4,
              Text(
                'Khoản tiền thực sự có thể chi tiêu tự do mà không ảnh hưởng đến các nghĩa vụ cố định.',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapH20,

              // 4 Mathematical Terms
              _buildFormulaRow(
                sign: '+',
                label: 'Tài sản tiền mặt khả dụng',
                amount: breakdown.liquidAssets.formatVnd(),
                color: AppColors.textAccentVerdantPrimary,
                subtext: 'Tiền mặt & số dư tài khoản ngân hàng',
              ),
              AppSpacing.gapH12,
              _buildFormulaRow(
                sign: '-',
                label: 'Dự phòng quỹ được bảo vệ',
                amount: breakdown.protectedReserves.formatVnd(),
                color: AppColors.textAccentRubyPrimary,
                subtext: 'Quỹ khẩn cấp & nghĩa vụ đã khóa',
              ),
              AppSpacing.gapH12,
              _buildFormulaRow(
                sign: '-',
                label: 'Nghĩa vụ chưa cấp vốn',
                amount: breakdown.unfundedCommittedOutflows.formatVnd(),
                color: AppColors.textAccentRubyPrimary,
                subtext: 'Hoá đơn sắp tới vượt mức quỹ bảo vệ',
              ),
              AppSpacing.gapH12,
              _buildFormulaRow(
                sign: '-',
                label: 'Vốn đệm tiền mặt tối thiểu',
                amount: breakdown.minimumCashBuffer.formatVnd(),
                color: AppColors.textAccentRubyPrimary,
                subtext: 'Mức đệm an toàn duy trì trong Cài đặt',
              ),
              AppSpacing.gapH16,
              const Divider(),
              AppSpacing.gapH16,

              // Result Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tiền an toàn khả dụng',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppSpacing.gapW8,
                  Text(
                    result.safeToSpend.formatVnd(),
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: result.isDeficit
                          ? AppColors.textAccentRubyPrimary
                          : AppColors.textAccentVerdantPrimary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH8,

              // Daily allowance note
              Container(
                padding: const EdgeInsets.all(AppSpacing.sp4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18.0),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        result.isDeficit
                            ? 'Mức chi hàng ngày: 0 ₫ (Đang thâm hụt)'
                            : 'Mức chi hàng ngày: ${result.dailyAllowance.formatVnd()}/ngày cho ${result.daysRemaining} ngày tiếp theo.',
                        style: AppTypography.subheadline,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaRow({
    required String sign,
    required String label,
    required String amount,
    required Color color,
    required String subtext,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.0,
          alignment: Alignment.center,
          child: Text(
            sign,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtext,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
