import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';

/// Upcoming Obligations Card on Dashboard.
class UpcomingObligationsCard extends StatelessWidget {
  final List<ScheduledItem> pendingBills;
  final ScheduledItem? nextIncome;
  final ValueChanged<int> onPayObligation;
  final ValueChanged<ScheduledItem>? onEditObligation;
  final ValueChanged<ScheduledItem>? onDeleteObligation;
  final Map<int, String>? categoryNames;

  const UpcomingObligationsCard({
    super.key,
    required this.pendingBills,
    this.nextIncome,
    required this.onPayObligation,
    this.onEditObligation,
    this.onDeleteObligation,
    this.categoryNames,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'card_upcoming_obligations',
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NGHĨA VỤ SẮP ĐẾN HẠN',
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              AppSpacing.gapH12,
              if (pendingBills.isEmpty && nextIncome == null)
                Text(
                  'Không có hoá đơn nào sắp đến hạn.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              if (nextIncome != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sp3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAccentVerdantSecondary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward,
                          size: 16.0, color: AppColors.jade14),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          'Thu nhập tiếp theo: ${nextIncome!.title} (${VndFormatter.format(nextIncome!.amountVnd)})',
                          style: VndFormatter.withTabularFigures(
                            AppTypography.caption.copyWith(
                              color: AppColors.jade14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (onEditObligation != null)
                        Semantics(
                          identifier: 'btn_edit_obligation_${nextIncome!.id}',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Sửa',
                            onPressed: () => onEditObligation!(nextIncome!),
                          ),
                        ),
                      if (onDeleteObligation != null) ...[
                        AppSpacing.gapW4,
                        Semantics(
                          identifier: 'btn_delete_obligation_${nextIncome!.id}',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18,
                                color: AppColors.textAccentRubyPrimary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Xóa',
                            onPressed: () => onDeleteObligation!(nextIncome!),
                          ),
                        ),
                      ],
                      AppSpacing.gapW8,
                      Semantics(
                        identifier: 'btn_pay_obligation_${nextIncome!.id}',
                        button: true,
                        child: OutlinedButton(
                          onPressed: () => onPayObligation(nextIncome!.id),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(64, 32),
                          ),
                          child: const Text('Đã nhận'),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH8,
              ],
              ...pendingBills.take(3).map((bill) {
                final catName =
                    (bill.categoryId != null && categoryNames != null)
                        ? categoryNames![bill.categoryId!]
                        : null;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp3),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 20.0),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.title, style: AppTypography.bodyMedium),
                            if (catName != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                catName,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                            Text(
                              VndFormatter.format(bill.amountVnd),
                              style: VndFormatter.withTabularFigures(
                                AppTypography.caption.copyWith(
                                  color: AppColors.textAccentRubySecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onEditObligation != null)
                        Semantics(
                          identifier: 'btn_edit_obligation_${bill.id}',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Sửa',
                            onPressed: () => onEditObligation!(bill),
                          ),
                        ),
                      if (onDeleteObligation != null) ...[
                        AppSpacing.gapW4,
                        Semantics(
                          identifier: 'btn_delete_obligation_${bill.id}',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18,
                                color: AppColors.textAccentRubyPrimary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Xóa',
                            onPressed: () => onDeleteObligation!(bill),
                          ),
                        ),
                      ],
                      AppSpacing.gapW8,
                      Semantics(
                        identifier: 'btn_pay_obligation_${bill.id}',
                        button: true,
                        child: OutlinedButton(
                          onPressed: () => onPayObligation(bill.id),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(64, 32),
                          ),
                          child: const Text('Đã trả'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
