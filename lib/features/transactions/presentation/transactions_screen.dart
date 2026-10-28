import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/money/vnd_formatter.dart';
import '../../../domain/ledger/account_kind.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../dashboard/presentation/providers/dashboard_providers.dart';
import 'controllers/transaction_providers.dart';
import 'transaction_detail_sheet.dart';
import 'widgets/day_group_header.dart';
import 'widgets/transaction_filter_bar.dart';
import 'widgets/transaction_list_tile.dart';

/// Tab 1: Transactions & Accounts (Giao dịch) Screen.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsWithBalancesStreamProvider);
    final groupedAsync = ref.watch(dayGroupedTransactionsProvider);

    final userAccounts = (accountsAsync.value ?? []).where((a) {
      return a.kind == AccountKind.assetCash ||
          a.kind == AccountKind.assetBank ||
          a.kind == AccountKind.liabilityCreditCard;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch'),
        actions: [
          Semantics(
            identifier: 'btn_manage_accounts',
            button: true,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: const Text('Tài khoản'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Horizontal account balance strip
            if (userAccounts.isNotEmpty) ...[
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: userAccounts.length,
                  separatorBuilder: (_, __) => AppSpacing.gapW8,
                  itemBuilder: (context, index) {
                    final acc = userAccounts[index];
                    final isCard = acc.kind == AccountKind.liabilityCreditCard;
                    return Semantics(
                      identifier: 'card_account_${acc.id}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp5,
                          vertical: AppSpacing.sp4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfacePrimary,
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(color: AppColors.borderSecondary),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(acc.name, style: AppTypography.caption),
                            const SizedBox(height: 2),
                            Text(
                              isCard
                                  ? 'Dư nợ: ${VndFormatter.format(acc.balanceVnd)}'
                                  : VndFormatter.format(acc.balanceVnd),
                              style: VndFormatter.withTabularFigures(
                                AppTypography.bodyMedium.copyWith(
                                  color: isCard && acc.balanceVnd > 0
                                      ? AppColors.textAccentRubySecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              AppSpacing.gapH12,
            ],
            const TransactionFilterBar(),
            AppSpacing.gapH12,
            Expanded(
              child: groupedAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có giao dịch nào phù hợp.',
                        style: AppTypography.subheadline,
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp13),
                    itemCount: groups.length,
                    itemBuilder: (context, gIdx) {
                      final group = groups[gIdx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DayGroupHeader(
                            date: group.date,
                            dailyNetVnd: group.dailyNetVnd,
                          ),
                          ...group.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sp4,
                              ),
                              child: TransactionListTile(
                                item: item,
                                onTap: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        TransactionDetailSheet(item: item),
                                  );
                                },
                              ),
                            ),
                          ),
                          AppSpacing.gapH8,
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Lỗi tải giao dịch: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
