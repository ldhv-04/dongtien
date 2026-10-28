import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../domain/budgeting/feasibility_advisor.dart';
import '../../../../domain/budgeting/goal_calculator.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../envelopes/presentation/modals/envelope_form_modal.dart';
import '../providers/plans_providers.dart';

/// Sub-view (b) of Plans tab: Savings Goals & Feasibility Advisor with 3 one-tap calculators.
class SavingsGoalsView extends ConsumerWidget {
  const SavingsGoalsView({super.key});

  Future<void> _confirmAndDeleteGoal(
    BuildContext context,
    WidgetRef ref,
    ActiveGoalItem goal,
  ) async {
    final hasReserve = goal.currentReserved.amount > 0;
    final message = hasReserve
        ? 'Mục tiêu "${goal.name}" đang có ${VndFormatter.formatMoney(goal.currentReserved)} tiền bảo lưu. Khi xóa, toàn bộ số tiền này sẽ được giải phóng về tiền khả dụng (Available to Allocate). Bạn có chắc chắn muốn xóa không?'
        : 'Bạn có chắc chắn muốn xóa mục tiêu "${goal.name}" không?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa mục tiêu'),
        content: Text(
          message,
          style: VndFormatter.withTabularFigures(AppTypography.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fillAccentRubyPrimary,
              foregroundColor: AppColors.textInverse,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(plansControllerProvider.notifier)
          .deleteSavingsGoal(goal.id);
    }
  }

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
                          AppSpacing.gapH8,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Semantics(
                                identifier: 'btn_edit_goal_${goal.id}',
                                button: true,
                                child: TextButton.icon(
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Sửa'),
                                  onPressed: () async {
                                    final envelopes = ref
                                            .read(envelopesStreamProvider)
                                            .value ??
                                        [];
                                    final env =
                                        envelopes.cast<Envelope?>().firstWhere(
                                              (e) => e!.id == goal.id,
                                              orElse: () => null,
                                            );
                                    if (env != null && context.mounted) {
                                      await showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => EnvelopeFormModal(
                                            editingEnvelope: env),
                                      );
                                    }
                                  },
                                ),
                              ),
                              AppSpacing.gapW8,
                              Semantics(
                                identifier: 'btn_delete_goal_${goal.id}',
                                button: true,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16,
                                      color: AppColors.textAccentRubyPrimary),
                                  label: const Text('Xóa',
                                      style: TextStyle(
                                          color:
                                              AppColors.textAccentRubyPrimary)),
                                  onPressed: () =>
                                      _confirmAndDeleteGoal(context, ref, goal),
                                ),
                              ),
                            ],
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
