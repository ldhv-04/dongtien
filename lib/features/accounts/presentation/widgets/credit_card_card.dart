import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/widgets/progress_bar.dart';

/// Card widget displaying a credit card liability account (`LIABILITY_CREDIT_CARD`)
/// with current debt, credit limit, remaining credit, and utilization bar.
class CreditCardCard extends StatelessWidget {
  final AccountWithBalance account;
  final VoidCallback? onTap;

  const CreditCardCard({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int usedVnd = account.balanceVnd;
    final int limitVnd = account.creditLimit;
    final int remainingVnd = math.max(0, limitVnd - usedVnd);
    final double ratio = limitVnd > 0 ? (usedVnd / limitVnd) : 0.0;

    return Semantics(
      identifier: 'card_account_${account.id}',
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
              border: Border.all(color: AppColors.borderSecondary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceAccentRubySecondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.credit_card_outlined,
                        color: AppColors.iconAccentRuby,
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child:
                          Text(account.name, style: AppTypography.bodyMedium),
                    ),
                    Text(
                      VndFormatter.format(usedVnd),
                      style: VndFormatter.withTabularFigures(
                        AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: usedVnd > 0
                              ? AppColors.textAccentRubySecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (limitVnd > 0) ...[
                  AppSpacing.gapH12,
                  ProgressBar(ratio: ratio),
                  AppSpacing.gapH8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hạn mức: ${VndFormatter.format(limitVnd)}',
                        style: VndFormatter.withTabularFigures(
                          AppTypography.caption,
                        ),
                      ),
                      Text(
                        'Khả dụng: ${VndFormatter.format(remainingVnd)}',
                        style: VndFormatter.withTabularFigures(
                          AppTypography.caption.copyWith(
                            color: AppColors.textAccentVerdantPrimary,
                          ),
                        ),
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
