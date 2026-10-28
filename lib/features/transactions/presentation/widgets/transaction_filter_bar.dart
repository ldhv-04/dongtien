import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../domain/ledger/transaction_type.dart';
import '../controllers/transaction_providers.dart';

/// Search bar and horizontal filter chips for Transactions screen.
class TransactionFilterBar extends ConsumerWidget {
  const TransactionFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'input_search_tx',
          textField: true,
          child: TextField(
            onChanged: notifier.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Tìm theo ghi chú, danh mục, tài khoản...',
              hintStyle: AppTypography.subheadline,
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.iconSecondary),
              filled: true,
              fillColor: AppColors.surfacePrimary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp6,
                vertical: AppSpacing.sp4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.borderSecondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: AppColors.borderSecondary),
              ),
            ),
          ),
        ),
        AppSpacing.gapH8,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChipItem(
                semanticId: 'chip_filter_all',
                label: 'Tất cả',
                selected: filter.typeFilter == null,
                onSelected: () => notifier.setTypeFilter(null),
              ),
              AppSpacing.gapW8,
              _FilterChipItem(
                semanticId: 'chip_filter_expense',
                label: 'Chi tiêu',
                selected: filter.typeFilter == TransactionType.expense,
                onSelected: () =>
                    notifier.setTypeFilter(TransactionType.expense),
              ),
              AppSpacing.gapW8,
              _FilterChipItem(
                semanticId: 'chip_filter_income',
                label: 'Thu nhập',
                selected: filter.typeFilter == TransactionType.income,
                onSelected: () =>
                    notifier.setTypeFilter(TransactionType.income),
              ),
              AppSpacing.gapW8,
              _FilterChipItem(
                semanticId: 'chip_filter_transfer',
                label: 'Chuyển khoản',
                selected: filter.typeFilter == TransactionType.transfer,
                onSelected: () =>
                    notifier.setTypeFilter(TransactionType.transfer),
              ),
              AppSpacing.gapW8,
              _FilterChipItem(
                semanticId: 'chip_filter_refund',
                label: 'Hoàn tiền',
                selected: filter.typeFilter == TransactionType.refund,
                onSelected: () =>
                    notifier.setTypeFilter(TransactionType.refund),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String semanticId;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChipItem({
    required this.semanticId,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticId,
      button: true,
      selected: selected,
      child: ChoiceChip(
        label: Text(
          label,
          style: AppTypography.subheadline.copyWith(
            color: selected ? AppColors.textInverse : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        selected: selected,
        selectedColor: AppColors.fillAccentVerdantPrimary,
        backgroundColor: AppColors.surfacePrimary,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
