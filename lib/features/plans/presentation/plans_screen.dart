import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import 'providers/plans_providers.dart';
import 'widgets/category_budgets_view.dart';
import 'widgets/obligations_forecast_view.dart';
import 'widgets/savings_goals_view.dart';

/// Tab 3: Plans (Kế hoạch) Screen with 3 segmented sub-views:
/// (a) Monthly Category Budgets, (b) Savings Goals, and (c) Scheduled Obligations & Forecast.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentIndex = ref.watch(plansSegmentIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch tài chính'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.paddingScreen,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SegmentButton(
                    semanticId: 'tab_category_budgets',
                    label: 'Ngân sách',
                    selected: segmentIndex == 0,
                    onTap: () =>
                        ref.read(plansSegmentIndexProvider.notifier).state = 0,
                  ),
                  AppSpacing.gapW8,
                  _SegmentButton(
                    semanticId: 'tab_savings_goals',
                    label: 'Mục tiêu tiết kiệm',
                    selected: segmentIndex == 1,
                    onTap: () =>
                        ref.read(plansSegmentIndexProvider.notifier).state = 1,
                  ),
                  AppSpacing.gapW8,
                  _SegmentButton(
                    semanticId: 'tab_scheduled_bills',
                    label: 'Nghĩa vụ & Dự báo',
                    selected: segmentIndex == 2,
                    onTap: () =>
                        ref.read(plansSegmentIndexProvider.notifier).state = 2,
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapH8,
          Expanded(
            child: IndexedStack(
              index: segmentIndex,
              children: const [
                CategoryBudgetsView(),
                SavingsGoalsView(),
                ObligationsForecastView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String semanticId;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.semanticId,
    required this.label,
    required this.selected,
    required this.onTap,
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
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: selected,
        selectedColor: AppColors.fillAccentVerdantPrimary,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
