import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/database/app_database.dart';
import '../../../core/money/vnd_formatter.dart';
import '../providers/envelope_providers.dart';
import 'modals/allocate_modal.dart';
import 'modals/envelope_form_modal.dart';
import 'modals/release_modal.dart';
import 'modals/transfer_modal.dart';
import 'widgets/movement_history_tile.dart';

/// Detail screen for a single Virtual Fund Envelope displaying movement history.
class EnvelopeDetailScreen extends ConsumerWidget {
  final int envelopeId;

  const EnvelopeDetailScreen({
    super.key,
    required this.envelopeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(envelopeDetailProvider(envelopeId));
    final summaryAsync = ref.watch(virtualFundsSummaryProvider);

    return Semantics(
      identifier: 'screen_fund_detail',
      container: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(detailAsync.value?.envelope.name ?? 'Chi tiết quỹ tiền'),
          actions: [
            if (detailAsync.value != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => EnvelopeFormModal(
                      editingEnvelope: detailAsync.value!.envelope,
                    ),
                  );
                },
              ),
          ],
        ),
        body: detailAsync.when(
          data: (detail) {
            final env = detail.envelope;
            final summary = summaryAsync.value;
            final allEnvelopes = <Envelope>[
              ...(summary?.protectedEnvelopes ?? const <Envelope>[]),
              ...(summary?.flexibleEnvelopes ?? const <Envelope>[]),
            ];

            return ListView(
              padding: AppSpacing.paddingScreen,
              children: [
                AppSpacing.gapH8,
                Container(
                  padding: AppSpacing.paddingHero,
                  decoration: BoxDecoration(
                    color: detail.isDeficit
                        ? AppColors.surfaceAccentRubySecondary
                        : AppColors.surfaceAccentVerdantSecondary,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: detail.isDeficit
                          ? AppColors.borderAccentRuby
                          : AppColors.borderAccentVerdant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        env.policy == 'PROTECTED'
                            ? 'Quỹ bảo vệ (Bắt buộc)'
                            : 'Quỹ linh hoạt (Tùy chọn)',
                        style: AppTypography.subheadline,
                      ),
                      AppSpacing.gapH8,
                      Text(
                        VndFormatter.format(env.reservedBalanceVnd),
                        style: VndFormatter.withTabularFigures(
                          AppTypography.largeTitle.copyWith(
                            color: detail.isDeficit
                                ? AppColors.textAccentRubyPrimary
                                : AppColors.textAccentVerdantPrimary,
                          ),
                        ),
                      ),
                      if (env.targetAmountVnd != null) ...[
                        AppSpacing.gapH8,
                        Text(
                          'Mục tiêu: ${VndFormatter.format(env.targetAmountVnd!)} • Còn thiếu: ${VndFormatter.format(detail.targetShortfall ?? 0)}',
                          style: VndFormatter.withTabularFigures(
                            AppTypography.caption,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.gapH12,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AllocateModal(
                              envelopes: allEnvelopes,
                              initialEnvelope: env,
                              availableToAllocateVnd:
                                  summary?.availableToAllocate ?? 0,
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: const Text('Phân bổ'),
                      ),
                    ),
                    AppSpacing.gapW8,
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ReleaseModal(
                              envelopes: allEnvelopes,
                              initialEnvelope: env,
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        label: const Text('Giải phóng'),
                      ),
                    ),
                    if (allEnvelopes.length > 1) ...[
                      AppSpacing.gapW8,
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => TransferModal(
                                envelopes: allEnvelopes,
                                initialSourceEnvelope: env,
                              ),
                            );
                          },
                          icon: const Icon(Icons.sync_alt, size: 16),
                          label: const Text('Chuyển quỹ'),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapH20,
                const Text(
                  'Lịch sử biến động quỹ',
                  style: AppTypography.headline,
                ),
                AppSpacing.gapH8,
                if (detail.movements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sp6),
                    child: Text(
                      'Chưa có biến động nào trong quỹ này.',
                      style: AppTypography.subheadline,
                    ),
                  )
                else
                  ...detail.movements.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                      child: MovementHistoryTile(
                        movement: m,
                        currentEnvelopeId: envelopeId,
                        envelopeNames: detail.envelopeNames,
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
      ),
    );
  }
}
