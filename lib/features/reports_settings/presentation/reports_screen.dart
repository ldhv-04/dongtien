import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/vnd_formatter.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../domain/budgeting/category_spending_calculator.dart';
import 'providers/reports_settings_providers.dart';

/// Secondary Screen: Reports (`Báo cáo`)
/// Shows Recognized Income, Gross Expense, Refunds, Net Expense (with "Thu hồi chi phí ròng" recovery badge),
/// Internal Transfers, Saving Rate ("Chưa có thu nhập" when income <= 0), Category Breakdown, and Net Worth.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo tài chính'),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: AppSpacing.paddingScreen,
            child: Text(
              'Không thể tải báo cáo: $err',
              style: AppTypography.body.copyWith(
                color: AppColors.textAccentRubyPrimary,
              ),
            ),
          ),
        ),
        data: (summary) {
          final report = summary.spendingReport;
          return SingleChildScrollView(
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPeriodHeader(summary.currentPeriodMonth),
                AppSpacing.gapH12,
                _buildIncomeExpenseCard(report, summary),
                AppSpacing.gapH16,
                _buildNetWorthCard(summary),
                AppSpacing.gapH16,
                _buildCategoryBreakdownCard(report),
                const SizedBox(height: AppSpacing.sp10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodHeader(String periodMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Kỳ báo cáo',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          'Tháng $periodMonth',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseCard(
    CategorySpendingReport report,
    ReportsSummaryData summary,
  ) {
    final netExpenseFormatted = report.isNetRecovery
        ? '+${VndFormatter.formatMoney(report.netExpense.abs())}'
        : VndFormatter.formatMoney(report.netExpense);

    return Semantics(
      identifier: 'card_reports_income_expense',
      child: Container(
        padding: AppSpacing.paddingCard,
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng hợp Thu - Chi & Tiết kiệm',
              style: AppTypography.headline.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapH12,
            _buildMetricRow(
              label: 'Thu nhập ghi nhận',
              value: VndFormatter.formatMoney(report.recognizedIncome),
              valueColor: AppColors.textAccentVerdantPrimary,
              semanticsId: 'txt_report_recognized_income',
            ),
            const Divider(height: 20, color: AppColors.borderSecondary),
            _buildMetricRow(
              label: 'Tổng chi tiêu gộp',
              value: VndFormatter.formatMoney(report.grossExpense),
              valueColor: AppColors.textPrimary,
              semanticsId: 'txt_report_gross_expense',
            ),
            AppSpacing.gapH8,
            _buildMetricRow(
              label: 'Hoàn tiền nhận được',
              value: VndFormatter.formatMoney(report.refundCredits),
              valueColor: AppColors.textAccentVerdantSecondary,
              semanticsId: 'txt_report_refund_credits',
            ),
            AppSpacing.gapH8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chi tiêu ròng',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (report.isNetRecovery) ...[
                        const SizedBox(height: 4),
                        Semantics(
                          identifier: 'badge_net_recovery_total',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAccentVerdantSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Thu hồi chi phí ròng',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textAccentVerdantPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Semantics(
                  identifier: 'txt_report_net_expense',
                  child: Text(
                    netExpenseFormatted,
                    style: AppTypography.bodyMedium.copyWith(
                      color: report.isNetRecovery
                          ? AppColors.textAccentVerdantPrimary
                          : AppColors.textAccentRubyPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.borderSecondary),
            _buildMetricRow(
              label: 'Tiết kiệm ròng',
              value: VndFormatter.formatMoney(report.netSaving),
              valueColor: report.netSaving.isNegative
                  ? AppColors.textAccentRubyPrimary
                  : AppColors.textAccentVerdantPrimary,
              semanticsId: 'txt_report_net_saving',
            ),
            AppSpacing.gapH8,
            _buildMetricRow(
              label: 'Tỷ lệ tiết kiệm',
              value: report.savingsRateDisplay,
              valueColor: AppColors.blue14,
              semanticsId: 'txt_report_savings_rate',
            ),
            const Divider(height: 20, color: AppColors.borderSecondary),
            _buildMetricRow(
              label: 'Chuyển khoản nội bộ / Trả thẻ',
              value: VndFormatter.formatMoney(summary.internalTransfersTotal),
              valueColor: AppColors.textSecondary,
              semanticsId: 'txt_report_internal_transfers',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(ReportsSummaryData summary) {
    return Semantics(
      identifier: 'card_reports_net_worth',
      child: Container(
        padding: AppSpacing.paddingCard,
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài sản ròng (Net Worth)',
              style: AppTypography.headline.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapH12,
            _buildMetricRow(
              label: 'Tổng tài sản thanh khoản',
              value: VndFormatter.formatMoney(summary.totalAssets),
              valueColor: AppColors.textAccentVerdantPrimary,
              semanticsId: 'txt_report_total_assets',
            ),
            AppSpacing.gapH8,
            _buildMetricRow(
              label: 'Tổng dư nợ thẻ tín dụng',
              value: VndFormatter.formatMoney(summary.totalLiabilities),
              valueColor: AppColors.textAccentRubyPrimary,
              semanticsId: 'txt_report_total_liabilities',
            ),
            const Divider(height: 20, color: AppColors.borderSecondary),
            _buildMetricRow(
              label: 'Tài sản ròng hiện tại',
              value: VndFormatter.formatMoney(summary.netWorth),
              valueColor: summary.netWorth.isNegative
                  ? AppColors.textAccentRubyPrimary
                  : AppColors.textPrimary,
              semanticsId: 'txt_report_net_worth',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(CategorySpendingReport report) {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cơ cấu chi tiêu theo danh mục',
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH12,
          if (report.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Chưa có giao dịch chi tiêu trong kỳ này',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...report.categories.map((cat) {
              final pctInt = (cat.percentageOfTotal * 100).round();
              final displayAmt = cat.isNetRecovery
                  ? '+${VndFormatter.formatMoney(cat.netExpense.abs())}'
                  : VndFormatter.formatMoney(cat.netExpense);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  cat.categoryName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (cat.isNetRecovery) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.surfaceAccentVerdantSecondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    cat.recoveryLabel ?? 'Thu hồi chi phí ròng',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textAccentVerdantPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '$displayAmt ($pctInt%)',
                          style: AppTypography.bodyMedium.copyWith(
                            color: cat.isNetRecovery
                                ? AppColors.textAccentVerdantPrimary
                                : AppColors.textPrimary,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ProgressBar(
                      ratio: cat.percentageOfTotal,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required Color valueColor,
    required String semanticsId,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Semantics(
          identifier: semanticsId,
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
