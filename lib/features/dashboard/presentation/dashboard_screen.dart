import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../plans/presentation/providers/plans_providers.dart';
import '../../reports_settings/presentation/reports_screen.dart';
import '../../reports_settings/presentation/settings_screen.dart';
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
              onPayObligation: (billId) {
                ref
                    .read(plansControllerProvider.notifier)
                    .markScheduledItemPaid(scheduledItemId: billId);
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
