import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/daos/ledger_dao.dart';
import '../../../../core/money/vnd_formatter.dart';

/// Card widget displaying a physical cash account (`ASSET_CASH`).
class CashAccountCard extends StatelessWidget {
  final AccountWithBalance account;
  final VoidCallback? onTap;

  const CashAccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAccentVerdantSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.iconAccentVerdant,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: AppTypography.bodyMedium),
                      const Text('Tiền mặt thanh khoản',
                          style: AppTypography.caption),
                    ],
                  ),
                ),
                Text(
                  VndFormatter.format(account.balanceVnd),
                  style: VndFormatter.withTabularFigures(
                    AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textAccentVerdantPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
