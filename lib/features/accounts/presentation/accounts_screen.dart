import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/vnd_formatter.dart';
import '../../../domain/ledger/account_kind.dart';
import '../../dashboard/presentation/providers/dashboard_providers.dart';
import 'add_edit_account_modal.dart';
import 'widgets/bank_account_card.dart';
import 'widgets/cash_account_card.dart';
import 'widgets/credit_card_card.dart';

/// Screen for managing Cash, Bank, and Credit Card accounts and viewing Net Worth.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsWithBalancesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản & Dư nợ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddEditAccountModal(),
              );
            },
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          final cashAccounts =
              accounts.where((a) => a.kind == AccountKind.assetCash).toList();
          final bankAccounts =
              accounts.where((a) => a.kind == AccountKind.assetBank).toList();
          final creditCards = accounts
              .where((a) => a.kind == AccountKind.liabilityCreditCard)
              .toList();

          final int totalLiquid = [...cashAccounts, ...bankAccounts]
              .fold<int>(0, (sum, a) => sum + a.balanceVnd);
          final int totalCardDebt =
              creditCards.fold<int>(0, (sum, a) => sum + a.balanceVnd);
          final int netWorth = totalLiquid - totalCardDebt;

          return ListView(
            padding: AppSpacing.paddingScreen,
            children: [
              AppSpacing.gapH8,
              Container(
                padding: AppSpacing.paddingCard,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAccentVerdantSecondary,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.borderAccentVerdant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryRow(
                      label: 'Tổng tài sản thanh khoản',
                      amountVnd: totalLiquid,
                      color: AppColors.textAccentVerdantPrimary,
                    ),
                    AppSpacing.gapH8,
                    _SummaryRow(
                      label: 'Tổng dư nợ thẻ tín dụng',
                      amountVnd: totalCardDebt,
                      color: AppColors.textAccentRubySecondary,
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'Giá trị tài sản ròng (Net Worth)',
                      amountVnd: netWorth,
                      color: AppColors.textPrimary,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH20,
              const Text('TIỀN MẶT', style: AppTypography.subheadline),
              AppSpacing.gapH8,
              if (cashAccounts.isEmpty)
                const Text(
                  'Chưa có tài khoản tiền mặt.',
                  style: AppTypography.caption,
                )
              else
                ...cashAccounts.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                    child: CashAccountCard(
                      account: a,
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddEditAccountModal(editingAccount: a),
                      ),
                    ),
                  ),
                ),
              AppSpacing.gapH16,
              const Text(
                'NGÂN HÀNG & VÍ ĐIỆN TỬ',
                style: AppTypography.subheadline,
              ),
              AppSpacing.gapH8,
              if (bankAccounts.isEmpty)
                const Text(
                  'Chưa có tài khoản ngân hàng.',
                  style: AppTypography.caption,
                )
              else
                ...bankAccounts.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                    child: BankAccountCard(
                      account: a,
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddEditAccountModal(editingAccount: a),
                      ),
                    ),
                  ),
                ),
              AppSpacing.gapH16,
              const Text('THẺ TÍN DỤNG', style: AppTypography.subheadline),
              AppSpacing.gapH8,
              if (creditCards.isEmpty)
                const Text(
                  'Chưa có thẻ tín dụng.',
                  style: AppTypography.caption,
                )
              else
                ...creditCards.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                    child: CreditCardCard(
                      account: a,
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddEditAccountModal(editingAccount: a),
                      ),
                    ),
                  ),
                ),
              AppSpacing.gapH32,
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int amountVnd;
  final Color color;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.amountVnd,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? AppTypography.bodyMedium : AppTypography.subheadline,
        ),
        Text(
          VndFormatter.format(amountVnd),
          style: VndFormatter.withTabularFigures(
            AppTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
