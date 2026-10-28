import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/vnd_formatter.dart';
import '../../plans/presentation/providers/plans_providers.dart';
import '../../plans/presentation/widgets/obligations_forecast_view.dart';
import '../../reports_settings/presentation/reports_screen.dart';
import '../../reports_settings/presentation/settings_screen.dart';
import '../../transactions/presentation/controllers/transaction_providers.dart';
import 'providers/dashboard_providers.dart';
import 'providers/safe_to_spend_provider.dart';
import 'widgets/fund_progress_card.dart';
import 'widgets/recent_transactions_card.dart';
import 'widgets/safe_to_spend_hero_card.dart';
import 'widgets/spending_vs_budget_card.dart';
import 'widgets/upcoming_obligations_card.dart';

/// Tab 0: Dashboard (Tổng quan) Screen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeToSpendAsync = ref.watch(safeToSpendProvider);
    final budgetSummaryAsync = ref.watch(currentMonthlyBudgetSummaryProvider);
    final pendingBillsAsync = ref.watch(pendingBillsStreamProvider);
    final nextIncomeAsync = ref.watch(nextPlannedIncomeStreamProvider);
    final envelopesAsync = ref.watch(envelopesStreamProvider);
    final recentTxAsync = ref.watch(recentTransactionsStreamProvider);
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c.name};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đồng Tiền'),
        actions: [
          Semantics(
            identifier: 'btn_appbar_reports',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.assessment_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReportsScreen(),
                  ),
                );
              },
            ),
          ),
          Semantics(
            identifier: 'btn_appbar_settings',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapH8,

            // 1. Safe-to-Spend Hero Card
            safeToSpendAsync.when(
              data: (result) => SafeToSpendHeroCard(result: result),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sp8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAccentRubySecondary,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  'Lỗi tải dữ liệu: $err',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textAccentRubyPrimary,
                  ),
                ),
              ),
            ),
            AppSpacing.gapH16,

            // 2. Spending vs Budget Card
            budgetSummaryAsync.when(
              data: (summary) => SpendingVsBudgetCard(
                summary: summary,
                onTap: () {
                  ref.read(navigationIndexProvider.notifier).state =
                      3; // Plans tab
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            AppSpacing.gapH16,

            // 3. Upcoming Obligations Card
            UpcomingObligationsCard(
              pendingBills: pendingBillsAsync.value ?? [],
              nextIncome: nextIncomeAsync.value,
              categoryNames: catMap,
              onEditObligation: (item) {
                showScheduledItemModal(context, existingItem: item);
              },
              onDeleteObligation: (item) async {
                final isBill = item.kind == 'BILL';
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isBill
                        ? 'Xác nhận xóa hoá đơn'
                        : 'Xác nhận xóa khoản thu'),
                    content: Text(
                      'Bạn có chắc chắn muốn xóa "${item.title}" (${VndFormatter.format(item.amountVnd)}) khỏi danh sách không?',
                      style: VndFormatter.withTabularFigures(
                        AppTypography.bodyMedium,
                      ),
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
                      .deleteScheduledItem(item.id);
                }
              },
              onPayObligation: (itemId) async {
                final item = (pendingBillsAsync.value ?? [])
                        .where((b) => b.id == itemId)
                        .firstOrNull ??
                    (nextIncomeAsync.value?.id == itemId
                        ? nextIncomeAsync.value
                        : null);
                if (item == null) return;

                final isBill = item.kind == 'BILL';
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                        isBill ? 'Xác nhận thanh toán' : 'Xác nhận đã nhận'),
                    content: Text(
                      'Bạn có chắc chắn muốn ghi nhận ${isBill ? 'đã thanh toán hoá đơn' : 'đã nhận khoản thu'} '
                      '"${item.title}" với số tiền ${VndFormatter.format(item.amountVnd)}?',
                      style: VndFormatter.withTabularFigures(
                        AppTypography.bodyMedium,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBill
                              ? AppColors.fillAccentRubyPrimary
                              : AppColors.fillAccentVerdantPrimary,
                          foregroundColor: AppColors.textInverse,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(isBill ? 'Đã trả' : 'Đã nhận'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await ref
                      .read(plansControllerProvider.notifier)
                      .markScheduledItemPaid(scheduledItemId: itemId);
                }
              },
            ),
            AppSpacing.gapH16,

            // 4. Mini Fund Progress Card
            FundProgressCard(
              envelopes: envelopesAsync.value ?? [],
              onTap: () {
                ref.read(navigationIndexProvider.notifier).state =
                    2; // Funds tab
              },
            ),
            AppSpacing.gapH16,

            // 5. Recent 5 Transactions Card
            RecentTransactionsCard(
              transactions: recentTxAsync.value ?? [],
              onTapViewAll: () {
                ref.read(navigationIndexProvider.notifier).state =
                    1; // Transactions tab
              },
            ),
            const SizedBox(height: AppSpacing.sp13), // Bottom bar clearance
          ],
        ),
      ),
    );
  }
}
