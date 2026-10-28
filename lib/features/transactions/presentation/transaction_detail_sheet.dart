import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/vnd_formatter.dart';
import '../domain/models/transaction_item.dart';
import 'audit_history_sheet.dart';
import 'controllers/transaction_controller.dart';
import 'quick_add_modal.dart';

/// Bottom sheet displaying transaction details and offering Edit, Void, and Audit History actions.
class TransactionDetailSheet extends ConsumerWidget {
  final TransactionItem item;

  const TransactionDetailSheet({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = item.occurredAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    return Semantics(
      identifier: 'sheet_transaction_detail',
      container: true,
      child: Container(
        padding: AppSpacing.paddingModal,
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: Column(
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
                Text(
                  'Chi tiết giao dịch #${item.id}',
                  style: AppTypography.headline,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            AppSpacing.gapH12,
            Center(
              child: Text(
                VndFormatter.format(item.amountVnd),
                style: VndFormatter.withTabularFigures(
                  AppTypography.largeTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            AppSpacing.gapH16,
            _DetailRow(label: 'Loại giao dịch', value: item.type.dbValue),
            if (item.category != null)
              _DetailRow(label: 'Danh mục', value: item.category!.name),
            if (item.sourceAccount != null)
              _DetailRow(
                  label: 'Tài khoản nguồn', value: item.sourceAccount!.name),
            if (item.destinationAccount != null)
              _DetailRow(
                  label: 'Tài khoản đích',
                  value: item.destinationAccount!.name),
            if (item.linkedEnvelope != null)
              _DetailRow(label: 'Quỹ tiền', value: item.linkedEnvelope!.name),
            _DetailRow(label: 'Ngày giao dịch', value: dateStr),
            if (item.description.isNotEmpty)
              _DetailRow(label: 'Ghi chú', value: item.description),
            AppSpacing.gapH20,
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    identifier: 'btn_audit_history',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              AuditHistorySheet(transactionId: item.id),
                        );
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Lịch sử chỉnh sửa'),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH8,
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    identifier: 'btn_edit_transaction',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => QuickAddModal(editingItem: item),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Chỉnh sửa'),
                    ),
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: Semantics(
                    identifier: 'btn_void_transaction',
                    button: true,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fillAccentRubyPrimary,
                        foregroundColor: AppColors.textInverse,
                      ),
                      onPressed: () => _confirmVoid(context, ref),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hủy giao dịch'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy giao dịch'),
        content: const Text(
          'Hành động này sẽ tạo một bút toán đảo ngược (Reversal) để hoàn nguyên số dư và quỹ tiền liên quan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fillAccentRubyPrimary,
              foregroundColor: AppColors.textInverse,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(transactionControllerProvider.notifier)
          .voidTransaction(item.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.subheadline),
          Flexible(
            child: Text(
              value,
              style: VndFormatter.withTabularFigures(AppTypography.bodyMedium),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
