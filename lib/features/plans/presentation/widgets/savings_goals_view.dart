import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../domain/budgeting/goal_calculator.dart';
import '../../../envelopes/presentation/modals/envelope_form_modal.dart';
import '../providers/plans_providers.dart';

/// Sub-view (b) of Plans tab: Savings Goals & Feasibility Advisor with 3 one-tap calculators.
class SavingsGoalsView extends ConsumerWidget {
  const SavingsGoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalAsync = ref.watch(feasibilityEvaluationProvider);

    return evalAsync.when(
      data: (eval) {
        final controller = ref.read(plansControllerProvider.notifier);

        return ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            AppSpacing.gapH8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MỤC TIÊU TIẾT KIỆM',
                  style: AppTypography.subheadline,
                ),
                TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const EnvelopeFormModal(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm mục tiêu'),
                ),
              ],
            ),
            if (eval.isInfeasible && eval.activeGoals.isNotEmpty) ...[
              Semantics(
                identifier: 'banner_feasibility_advisor',
                container: true,
                child: Container(
                  padding: AppSpacing.paddingCard,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAccentMarigoldSecondary,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.borderAccentMarigold),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.iconAccentMarigold,
                          ),
                          AppSpacing.gapW8,
                          Expanded(
                            child: Text(
                              'Cảnh báo khả thi (Thiếu hụt ${VndFormatter.formatMoney(eval.deficit)}/tháng)',
                              style: VndFormatter.withTabularFigures(
                                AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textAccentMarigoldPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapH8,
                      Text(
                        'Tổng mức đóng góp cần thiết (${VndFormatter.formatMoney(eval.totalRequiredPerPeriod)}/tháng) vượt quá khả năng phân bổ hiện tại (${VndFormatter.formatMoney(eval.monthlyCapacity)}). Chọn 1 giải pháp tự động:',
                        style: VndFormatter.withTabularFigures(
                          AppTypography.caption.copyWith(
                            color: AppColors.textAccentMarigoldPrimary,
                          ),
                        ),
                      ),
                      AppSpacing.gapH12,
                      Wrap(
                        spacing: AppSpacing.sp4,
                        runSpacing: AppSpacing.sp3,
                        children: [
                          Semantics(
                            identifier: 'btn_advisor_extend_deadline',
                            button: true,
                            child: OutlinedButton(
                              onPressed: () {
                                controller.applyExtendDeadline(
                                  goal: eval.activeGoals.first,
                                  monthlyCapacity: eval.monthlyCapacity,
                                );
                              },
                              child: const Text('1. Giãn thời hạn (N\')'),
                            ),
                          ),
                          Semantics(
                            identifier: 'btn_advisor_lower_target',
                            button: true,
                            child: OutlinedButton(
                              onPressed: () {
                                controller.applyLowerTarget(
                                  goal: eval.activeGoals.first,
                                  monthlyCapacity: eval.monthlyCapacity,
                                );
                              },
                              child: const Text('2. Giảm mục tiêu (T\')'),
                            ),
                          ),
                          Semantics(
                            identifier: 'btn_advisor_pause_goals',
                            button: true,
                            child: OutlinedButton(
                              onPressed: () {
                                controller.applyPauseLowerPriorityGoals(
                                  goals: eval.activeGoals,
                                  monthlyCapacity: eval.monthlyCapacity,
                                );
                              },
                              child: const Text('3. Tạm dừng ưu tiên thấp'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapH12,
            ],
            if (eval.activeGoals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sp6),
                child: Text(
                  'Chưa có mục tiêu tiết kiệm nào. Hãy tạo Quỹ tiền có số tiền mục tiêu.',
                  style: AppTypography.subheadline,
                ),
              )
            else
              ...eval.activeGoals.map((goal) {
                final gEval = goal.evaluation;
                String statusBadge;
                Color statusColor;
                switch (gEval.status) {
                  case GoalStatus.achieved:
                    statusBadge = 'Đạt mục tiêu';
                    statusColor = AppColors.textAccentVerdantPrimary;
                    break;
                  case GoalStatus.overdue:
                    statusBadge = 'Quá hạn';
                    statusColor = AppColors.textAccentRubyPrimary;
                    break;
                  case GoalStatus.inProgress:
                    statusBadge = 'Còn ${goal.remainingPeriods} tháng';
                    statusColor = AppColors.textSecondary;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                  child: Semantics(
                    identifier: 'card_goal_${goal.id}',
                    container: true,
                    child: Container(
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
                              Text(goal.name, style: AppTypography.bodyMedium),
                              Text(
                                statusBadge,
                                style: VndFormatter.withTabularFigures(
                                  AppTypography.caption.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.gapH8,
                          Text(
                            '${VndFormatter.formatMoney(goal.currentReserved)} / ${VndFormatter.formatMoney(goal.targetAmount)}',
                            style: VndFormatter.withTabularFigures(
                              AppTypography.headline,
                            ),
                          ),
                          AppSpacing.gapH8,
                          ProgressBar(ratio: gEval.progressRatio),
                          AppSpacing.gapH8,
                          Text(
                            'Cần tích lũy: ${VndFormatter.formatMoney(goal.requiredPerPeriod)} / kỳ',
                            style: VndFormatter.withTabularFigures(
                              AppTypography.caption,
                            ),
                          ),
                        ],
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
}
