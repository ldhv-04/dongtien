import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../domain/budgeting/category_budget_progress.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../transactions/presentation/controllers/transaction_providers.dart';
import '../providers/plans_providers.dart';

/// Sub-view (a) of Plans tab: Monthly Category Budgets.
class CategoryBudgetsView extends ConsumerWidget {
  const CategoryBudgetsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(currentMonthlyBudgetSummaryProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final expenseCategories = (categoriesAsync.value ?? [])
        .where((c) => c.kind == 'EXPENSE')
        .toList();

    return summaryAsync.when(
      data: (summary) {
        return ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            AppSpacing.gapH8,
            Container(
              padding: AppSpacing.paddingCard,
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.borderSecondary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng ngân sách tháng này',
                        style: AppTypography.bodyMedium,
                      ),
                      TextButton.icon(
                        onPressed: expenseCategories.isEmpty
                            ? null
                            : () => _openSetBudgetSheet(
                                  context,
                                  expenseCategories.first.id,
                                  expenseCategories.first.name,
                                ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thiết lập'),
                      ),
                    ],
                  ),
                  Text(
                    'Đã chi: ${VndFormatter.formatMoney(summary.totalSpentVnd)} / ${VndFormatter.formatMoney(summary.totalLimitVnd)}',
                    style: VndFormatter.withTabularFigures(
                      AppTypography.subheadline,
                    ),
                  ),
                  AppSpacing.gapH8,
                  ProgressBar(ratio: summary.overallSpentRatio),
                ],
              ),
            ),
            AppSpacing.gapH16,
            const Text('NGÂN SÁCH THEO DANH MỤC',
                style: AppTypography.subheadline),
            AppSpacing.gapH8,
            if (summary.categoryProgresses.isEmpty)
              ...expenseCategories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                  child: Semantics(
                    identifier: 'card_budget_${cat.id}',
                    button: true,
                    child: ListTile(
                      tileColor: AppColors.surfacePrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                        side:
                            const BorderSide(color: AppColors.borderSecondary),
                      ),
                      title: Text(cat.name, style: AppTypography.bodyMedium),
                      subtitle: const Text(
                        'Chưa đặt hạn mức ngân sách',
                        style: AppTypography.caption,
                      ),
                      trailing: OutlinedButton(
                        onPressed: () =>
                            _openSetBudgetSheet(context, cat.id, cat.name),
                        child: const Text('Đặt hạn mức'),
                      ),
                    ),
                  ),
                ),
              )
            else
              ...summary.categoryProgresses.map((prog) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                  child: Semantics(
                    identifier: 'card_budget_${prog.categoryId}',
                    button: true,
                    child: InkWell(
                      onTap: () => _openSetBudgetSheet(
                        context,
                        prog.categoryId,
                        prog.categoryName,
                        initialLimit: prog.limitVnd.amount,
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        padding: AppSpacing.paddingCard,
                        decoration: BoxDecoration(
                          color: AppColors.surfacePrimary,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: prog.isExceeded
                                ? AppColors.borderAccentRuby
                                : AppColors.borderSecondary,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  prog.categoryName,
                                  style: AppTypography.bodyMedium,
                                ),
                                Text(
                                  '${prog.spentPercentageInt}%',
                                  style: VndFormatter.withTabularFigures(
                                    AppTypography.bodyMedium.copyWith(
                                      color: prog.isExceeded
                                          ? AppColors.textAccentRubyPrimary
                                          : (prog.status == BudgetStatus.warning
                                              ? AppColors
                                                  .textAccentMarigoldSecondary
                                              : AppColors
                                                  .textAccentVerdantPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH8,
                            ProgressBar(
                              ratio: prog.spentRatio,
                              warningThreshold: prog.alertThresholdPct / 100.0,
                            ),
                            AppSpacing.gapH8,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đã chi: ${VndFormatter.formatMoney(prog.spentVnd)}',
                                  style: VndFormatter.withTabularFigures(
                                    AppTypography.caption,
                                  ),
                                ),
                                Text(
                                  'Hạn mức: ${VndFormatter.formatMoney(prog.limitVnd)}',
                                  style: VndFormatter.withTabularFigures(
                                    AppTypography.caption,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.sp13),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Lỗi: $err')),
    );
  }

  void _openSetBudgetSheet(
    BuildContext context,
    int categoryId,
    String categoryName, {
    int initialLimit = 0,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetBudgetModal(
        initialCategoryId: categoryId,
        initialCategoryName: categoryName,
        initialLimitVnd: initialLimit,
      ),
    );
  }
}

class _SetBudgetModal extends ConsumerStatefulWidget {
  final int initialCategoryId;
  final String initialCategoryName;
  final int initialLimitVnd;

  const _SetBudgetModal({
    required this.initialCategoryId,
    required this.initialCategoryName,
    required this.initialLimitVnd,
  });

  @override
  ConsumerState<_SetBudgetModal> createState() => _SetBudgetModalState();
}

class _SetBudgetModalState extends ConsumerState<_SetBudgetModal> {
  late int _selectedCategoryId;
  late int _limitVnd;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _limitVnd = widget.initialLimitVnd;
  }

  @override
  Widget build(BuildContext context) {
    final categories = (ref.watch(categoriesStreamProvider).value ?? [])
        .where((c) => c.kind == 'EXPENSE')
        .toList();

    return Container(
      padding: AppSpacing.paddingModal,
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Thiết lập ngân sách tháng',
                style: AppTypography.headline),
            AppSpacing.gapH8,
            Wrap(
              spacing: AppSpacing.sp4,
              children: categories.map((c) {
                return ChoiceChip(
                  label: Text(c.name),
                  selected: _selectedCategoryId == c.id,
                  onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                );
              }).toList(),
            ),
            AppSpacing.gapH8,
            Center(
              child: Text(
                VndFormatter.format(_limitVnd),
                style: VndFormatter.withTabularFigures(
                  AppTypography.largeTitle,
                ),
              ),
            ),
            AppSpacing.gapH8,
            CustomKeypad(
              onDigitPressed: (d) {
                final next = _limitVnd * 10 + d;
                if (next <= VndMoney.maxSafeVnd) {
                  setState(() => _limitVnd = next);
                }
              },
              onBackspacePressed: () => setState(() => _limitVnd ~/= 10),
              onDonePressed: _submit,
            ),
            AppSpacing.gapH8,
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fillAccentVerdantPrimary,
                foregroundColor: AppColors.textInverse,
              ),
              onPressed: _limitVnd <= 0 ? null : _submit,
              child: const Text('Lưu hạn mức'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_limitVnd <= 0) return;
    await ref.read(plansControllerProvider.notifier).upsertCategoryBudget(
          categoryId: _selectedCategoryId,
          limitVnd: _limitVnd,
        );
    if (mounted) Navigator.of(context).pop();
  }
}
