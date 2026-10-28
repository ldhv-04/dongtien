import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../domain/ledger/transaction_type.dart';
import '../../domain/models/transaction_item.dart';

/// List tile displaying a single enriched transaction with tabular VND amount.
class TransactionListTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback onTap;

  const TransactionListTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  IconData _resolveIcon() {
    switch (item.type) {
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.creditCardPayment:
        return Icons.credit_card_rounded;
      case TransactionType.refund:
        return Icons.replay_rounded;
      case TransactionType.openingBalance:
        return Icons.account_balance_wallet_outlined;
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
      case TransactionType.reversal:
        final catName = item.category?.name ?? '';
        if (catName.contains('Ăn')) return Icons.restaurant;
        if (catName.contains('Di chuyển')) return Icons.directions_car_outlined;
        if (catName.contains('Hoá đơn')) return Icons.receipt_long_outlined;
        if (catName.contains('Nhà')) return Icons.home_work_outlined;
        if (catName.contains('Mua sắm')) return Icons.shopping_bag_outlined;
        if (catName.contains('Y tế')) return Icons.local_hospital_outlined;
        return Icons.receipt_outlined;
    }
  }

  Color _resolveBadgeColor() {
    switch (item.type) {
      case TransactionType.income:
      case TransactionType.refund:
        return AppColors.surfaceAccentVerdantSecondary;
      case TransactionType.expense:
        return AppColors.surfaceAccentRubySecondary;
      case TransactionType.transfer:
        return AppColors.surfaceAccentSandstoneSecondary;
      case TransactionType.creditCardPayment:
        return AppColors.surfaceAccentEmberSecondary;
      default:
        return AppColors.surfaceTertiary;
    }
  }

  Color _resolveIconColor() {
    switch (item.type) {
      case TransactionType.income:
      case TransactionType.refund:
        return AppColors.iconAccentVerdant;
      case TransactionType.expense:
        return AppColors.iconAccentRuby;
      case TransactionType.transfer:
        return AppColors.iconAccentSandstone;
      case TransactionType.creditCardPayment:
        return AppColors.iconAccentEmber;
      default:
        return AppColors.iconPrimary;
    }
  }

  String _resolveTitle() {
    if (item.category != null) {
      return item.category!.name;
    }
    switch (item.type) {
      case TransactionType.transfer:
        return 'Chuyển khoản nội bộ';
      case TransactionType.creditCardPayment:
        return 'Thanh toán thẻ tín dụng';
      case TransactionType.openingBalance:
        return 'Số dư ban đầu';
      case TransactionType.refund:
        return 'Hoàn tiền';
      case TransactionType.income:
        return 'Thu nhập';
      case TransactionType.expense:
        return 'Chi tiêu';
      case TransactionType.reversal:
        return 'Hoàn tác';
    }
  }

  String _resolveSubtitle() {
    final List<String> parts = [];
    if (item.sourceAccount != null && item.destinationAccount != null) {
      parts.add(
          '${item.sourceAccount!.name} → ${item.destinationAccount!.name}');
    } else if (item.sourceAccount != null) {
      parts.add(item.sourceAccount!.name);
    } else if (item.destinationAccount != null) {
      parts.add(item.destinationAccount!.name);
    }
    if (item.linkedEnvelope != null) {
      parts.add('Quỹ: ${item.linkedEnvelope!.name}');
    }
    if (item.description.trim().isNotEmpty) {
      parts.add(item.description.trim());
    }
    return parts.isEmpty ? 'Giao dịch' : parts.join(' • ');
  }

  String _resolveFormattedAmount() {
    switch (item.type) {
      case TransactionType.income:
      case TransactionType.refund:
        return VndFormatter.format(item.amountVnd, showSign: true);
      case TransactionType.expense:
      case TransactionType.creditCardPayment:
        return VndFormatter.format(-item.amountVnd);
      default:
        return VndFormatter.format(item.amountVnd);
    }
  }

  Color _resolveAmountColor() {
    switch (item.type) {
      case TransactionType.income:
      case TransactionType.refund:
        return AppColors.textAccentVerdantPrimary;
      case TransactionType.expense:
        return AppColors.textAccentRubySecondary;
      default:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'item_transaction_${item.id}',
      button: true,
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sp5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.borderSecondary),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _resolveBadgeColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _resolveIcon(),
                    color: _resolveIconColor(),
                    size: 20,
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resolveTitle(),
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _resolveSubtitle(),
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapW8,
                Text(
                  _resolveFormattedAmount(),
                  style: VndFormatter.withTabularFigures(
                    AppTypography.bodyMedium.copyWith(
                      color: _resolveAmountColor(),
                      fontWeight: FontWeight.w600,
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
