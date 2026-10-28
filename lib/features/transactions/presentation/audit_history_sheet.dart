import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/database/app_database.dart';
import '../../../core/money/vnd_formatter.dart';
import '../../dashboard/presentation/providers/dashboard_providers.dart';
import 'controllers/transaction_controller.dart';

/// Bottom sheet displaying the complete audit history (original, reversal, replacement)
/// of a transaction.
class AuditHistorySheet extends ConsumerWidget {
  final int transactionId;

  const AuditHistorySheet({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Semantics(
      identifier: 'sheet_audit_history',
      container: true,
      child: Container(
        padding: AppSpacing.paddingModal,
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: FutureBuilder<List<JournalTransaction>>(
          future: ref
              .read(transactionControllerProvider.notifier)
              .resolveAuditChain(transactionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final chain = snapshot.data ?? [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                AppSpacing.gapH16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch sử chỉnh sửa & hoàn tác',
                      style: AppTypography.headline,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                AppSpacing.gapH12,
                if (chain.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sp6),
                    child: Text('Không tìm thấy lịch sử bút toán.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: chain.length,
                      separatorBuilder: (_, __) => AppSpacing.gapH12,
                      itemBuilder: (context, index) {
                        final tx = chain[index];
                        return FutureBuilder<List<JournalPosting>>(
                          future: (db.select(db.journalPostings)
                                ..where((p) => p.transactionId.equals(tx.id)))
                              .get(),
                          builder: (context, postSnap) {
                            final posts = postSnap.data ?? [];
                            int maxAmt = 0;
                            for (final p in posts) {
                              if (p.debitVnd > maxAmt) maxAmt = p.debitVnd;
                            }
                            return _AuditNodeCard(tx: tx, amountVnd: maxAmt);
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AuditNodeCard extends StatelessWidget {
  final JournalTransaction tx;
  final int amountVnd;

  const _AuditNodeCard({
    required this.tx,
    required this.amountVnd,
  });

  @override
  Widget build(BuildContext context) {
    final isReversal = tx.txType == 'REVERSAL';
    final isSuperseded = tx.status == 'SUPERSEDED';
    final isVoided = tx.status == 'VOIDED';

    Color badgeColor = AppColors.surfaceAccentVerdantSecondary;
    Color textColor = AppColors.textAccentVerdantPrimary;
    IconData icon = Icons.check_circle_outline;
    String statusLabel = tx.status;

    if (isReversal) {
      badgeColor = AppColors.surfaceAccentRubySecondary;
      textColor = AppColors.textAccentRubyPrimary;
      icon = Icons.undo_rounded;
      statusLabel = 'REVERSAL (Đảo ngược #${tx.reversesTxId})';
    } else if (isSuperseded) {
      badgeColor = AppColors.surfaceAccentMarigoldSecondary;
      textColor = AppColors.textAccentMarigoldPrimary;
      icon = Icons.history_rounded;
      statusLabel = 'SUPERSEDED (Thay thế bởi #${tx.replacedByTxId})';
    } else if (isVoided) {
      badgeColor = AppColors.surfaceAccentRubySecondary;
      textColor = AppColors.textAccentRubyPrimary;
      icon = Icons.cancel_outlined;
      statusLabel = 'VOIDED (Đã hủy)';
    }

    final dt = DateTime.fromMillisecondsSinceEpoch(tx.createdAt);
    final timeStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 22),
          AppSpacing.gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bút toán #${tx.id} (${tx.txType})',
                      style: AppTypography.bodyMedium,
                    ),
                    Text(
                      VndFormatter.format(amountVnd),
                      style: VndFormatter.withTabularFigures(
                        AppTypography.bodyMedium.copyWith(color: textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTypography.caption.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (tx.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(tx.description, style: AppTypography.subheadline),
                ],
                const SizedBox(height: 4),
                Text(
                  'Ghi nhận lúc: $timeStr',
                  style: VndFormatter.withTabularFigures(AppTypography.caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
