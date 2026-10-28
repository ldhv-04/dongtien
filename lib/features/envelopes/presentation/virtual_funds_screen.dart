import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../providers/envelope_providers.dart';
import 'envelope_detail_screen.dart';
import 'modals/allocate_modal.dart';
import 'modals/envelope_form_modal.dart';
import 'modals/release_modal.dart';
import 'modals/transfer_modal.dart';
import 'widgets/envelope_card.dart';
import 'widgets/over_allocation_banner.dart';
import 'widgets/summary_header_bar.dart';

/// Tab 2: Virtual Funds (Quỹ tiền) Screen.
class VirtualFundsScreen extends ConsumerWidget {
  const VirtualFundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(virtualFundsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quỹ tiền'),
        actions: [
          Semantics(
            identifier: 'btn_create_envelope',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const EnvelopeFormModal(),
                );
              },
            ),
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) {
          final allEnvelopes = [
            ...summary.protectedEnvelopes,
            ...summary.flexibleEnvelopes,
          ];

          return ListView(
            padding: AppSpacing.paddingScreen,
            children: [
              AppSpacing.gapH8,
              SummaryHeaderBar(summary: summary),
              if (summary.isOverAllocated) ...[
                AppSpacing.gapH12,
                OverAllocationBanner(
                  overAllocatedAmountVnd: summary.overAllocatedAmount,
                ),
              ],
              AppSpacing.gapH12,
              // Quick action buttons
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      identifier: 'btn_allocate_fund',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: allEnvelopes.isEmpty
                            ? null
                            : () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => AllocateModal(
                                    envelopes: allEnvelopes,
                                    availableToAllocateVnd:
                                        summary.availableToAllocate,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: const Text('Phân bổ'),
                      ),
                    ),
                  ),
                  AppSpacing.gapW8,
                  Expanded(
                    child: Semantics(
                      identifier: 'btn_transfer_fund',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: allEnvelopes.length < 2
                            ? null
                            : () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => TransferModal(
                                    envelopes: allEnvelopes,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: const Text('Chuyển quỹ'),
                      ),
                    ),
                  ),
                  AppSpacing.gapW8,
                  Expanded(
                    child: Semantics(
                      identifier: 'btn_release_fund',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: allEnvelopes.isEmpty
                            ? null
                            : () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ReleaseModal(
                                    envelopes: allEnvelopes,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        label: const Text('Giải phóng'),
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH20,
              const Text(
                'QUỸ BẢO VỆ (BẮT BUỘC)',
                style: AppTypography.subheadline,
              ),
              AppSpacing.gapH8,
              if (summary.protectedEnvelopes.isEmpty)
                const Text(
                  'Chưa có quỹ bảo vệ nào. Nhấn + để tạo quỹ khẩn cấp, tiền thuê nhà, v.v.',
                  style: AppTypography.caption,
                )
              else
                ...summary.protectedEnvelopes.map(
                  (env) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                    child: EnvelopeCard(
                      envelope: env,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                EnvelopeDetailScreen(envelopeId: env.id),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              AppSpacing.gapH16,
              const Text(
                'QUỸ LINH HOẠT (TÙY CHỌN)',
                style: AppTypography.subheadline,
              ),
              AppSpacing.gapH8,
              if (summary.flexibleEnvelopes.isEmpty)
                const Text(
                  'Chưa có quỹ linh hoạt nào. Nhấn + để tạo quỹ ăn uống, mua sắm, v.v.',
                  style: AppTypography.caption,
                )
              else
                ...summary.flexibleEnvelopes.map(
                  (env) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                    child: EnvelopeCard(
                      envelope: env,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                EnvelopeDetailScreen(envelopeId: env.id),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sp13),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}
