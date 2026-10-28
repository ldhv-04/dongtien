import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';

/// Recent 5 Transactions mini list on Dashboard.
class RecentTransactionsCard extends StatelessWidget {
  final List<JournalTransaction> transactions;
  final VoidCallback onTapViewAll;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.onTapViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GIAO DỊCH GẦN ĐÂY',
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: onTapViewAll,
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            AppSpacing.gapH8,
            if (transactions.isEmpty)
              Text(
                'Chưa có giao dịch nào.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ...transactions.map((tx) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceSecondary,
                  child: Icon(
                    tx.txType == 'INCOME'
                        ? Icons.arrow_downward
                        : (tx.txType == 'EXPENSE'
                            ? Icons.arrow_upward
                            : Icons.swap_horiz),
                    size: 18,
                    color: tx.txType == 'INCOME'
                        ? AppColors.jade14
                        : (tx.txType == 'EXPENSE'
                            ? AppColors.ruby14
                            : AppColors.blue14),
                  ),
                ),
                title: Text(tx.description, style: AppTypography.bodyMedium),
                subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(tx.occurredAt)
                      .toString()
                      .split(' ')[0],
                  style: AppTypography.caption,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
