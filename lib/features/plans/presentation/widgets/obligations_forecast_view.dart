import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/plans_providers.dart';

/// Sub-view (c) of Plans tab: Scheduled Bills & Planned Income + 30/60/90-day Cash-Flow Forecast.
class ObligationsForecastView extends ConsumerWidget {
  const ObligationsForecastView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allScheduledItemsStreamProvider);
    final forecastAsync = ref.watch(cashFlowForecastProvider);
    final horizonDays = ref.watch(forecastHorizonDaysProvider);

    return ListView(
      padding: AppSpacing.paddingScreen,
      children: [
        AppSpacing.gapH8,
        // Cash-Flow Forecast Card
        Semantics(
          identifier: 'timeline_cash_flow_forecast',
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
                    const Text(
                      'Dự báo dòng tiền',
                      style: AppTypography.bodyMedium,
                    ),
                    Row(
                      children: [30, 60, 90].map((days) {
                        final selected = horizonDays == days;
                        return Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: ChoiceChip(
                            label: Text('${days}N'),
                            selected: selected,
                            onSelected: (_) => ref
                                .read(forecastHorizonDaysProvider.notifier)
                                .state = days,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                AppSpacing.gapH8,
                forecastAsync.when(
                  data: (forecast) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thu dự kiến: +${VndFormatter.formatMoney(forecast.totalInflows)}',
                              style: VndFormatter.withTabularFigures(
                                AppTypography.caption.copyWith(
                                  color: AppColors.textAccentVerdantPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'Chi cam kết: -${VndFormatter.formatMoney(forecast.totalOutflows)}',
                              style: VndFormatter.withTabularFigures(
                                AppTypography.caption.copyWith(
                                  color: AppColors.textAccentRubySecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH8,
                        Text(
                          'Số dư cuối kỳ dự kiến: ${VndFormatter.formatMoney(forecast.endingBalance)}',
                          style: VndFormatter.withTabularFigures(
                            AppTypography.bodyMedium,
                          ),
                        ),
                        if (forecast.hasDeficit &&
                            forecast.firstDeficitDate != null) ...[
                          AppSpacing.gapH8,
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sp4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAccentRubySecondary,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              'Cảnh báo: Tiền mặt dự kiến giảm dưới mức đệm an toàn vào ngày '
                              '${forecast.firstDeficitDate!.day.toString().padLeft(2, '0')}/'
                              '${forecast.firstDeficitDate!.month.toString().padLeft(2, '0')}/'
                              '${forecast.firstDeficitDate!.year} '
                              '(Thiếu hụt tối đa: ${VndFormatter.formatMoney(forecast.maxDeficitAmount)}).',
                              style: VndFormatter.withTabularFigures(
                                AppTypography.caption.copyWith(
                                  color: AppColors.textAccentRubyPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => Text('Lỗi dự báo: $err'),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapH16,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HOÁ ĐƠN & THU NHẬP ĐỊNH KỲ',
              style: AppTypography.subheadline,
            ),
            TextButton.icon(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _AddScheduledItemModal(),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm lịch'),
            ),
          ],
        ),
        AppSpacing.gapH8,
        itemsAsync.when(
          data: (items) {
            final pending = items.where((i) => i.status == 'PENDING').toList();
            if (pending.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.sp6),
                child: Text(
                  'Chưa có hoá đơn hoặc thu nhập dự kiến nào.',
                  style: AppTypography.subheadline,
                ),
              );
            }
            return Column(
              children: pending.map((item) {
                final isBill = item.kind == 'BILL';
                final dt = DateTime.fromMillisecondsSinceEpoch(item.dueDateMs);
                final dStr =
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                  child: Container(
                    padding: AppSpacing.paddingCard,
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.borderSecondary),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: AppTypography.bodyMedium),
                              const SizedBox(height: 2),
                              Text(
                                '${isBill ? 'Hoá đơn cam kết' : 'Thu nhập dự kiến'} • Hạn: $dStr (${item.recurrence})',
                                style: VndFormatter.withTabularFigures(
                                  AppTypography.caption,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                VndFormatter.format(item.amountVnd),
                                style: VndFormatter.withTabularFigures(
                                  AppTypography.bodyMedium.copyWith(
                                    color: isBill
                                        ? AppColors.textAccentRubySecondary
                                        : AppColors.textAccentVerdantPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          identifier: 'btn_pay_obligation_${item.id}',
                          button: true,
                          child: OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(plansControllerProvider.notifier)
                                  .markScheduledItemPaid(
                                    scheduledItemId: item.id,
                                  );
                            },
                            child: Text(isBill ? 'Đã trả' : 'Đã nhận'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Lỗi: $err'),
        ),
        const SizedBox(height: AppSpacing.sp13),
      ],
    );
  }
}

class _AddScheduledItemModal extends ConsumerStatefulWidget {
  const _AddScheduledItemModal();

  @override
  ConsumerState<_AddScheduledItemModal> createState() =>
      _AddScheduledItemModalState();
}

class _AddScheduledItemModalState
    extends ConsumerState<_AddScheduledItemModal> {
  final TextEditingController _titleController = TextEditingController();
  String _kind = 'BILL';
  String _recurrence = 'MONTHLY';
  int _amountVnd = 0;
  final DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  int? _linkedEnvelopeId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final envelopes = ref.watch(envelopesStreamProvider).value ?? [];

    return Container(
      padding: AppSpacing.paddingModal,
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Thêm lịch nghĩa vụ / thu nhập',
                style: AppTypography.headline),
            AppSpacing.gapH8,
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Hoá đơn (BILL)'),
                    selected: _kind == 'BILL',
                    onSelected: (_) => setState(() => _kind = 'BILL'),
                  ),
                ),
                AppSpacing.gapW8,
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Thu nhập dự kiến'),
                    selected: _kind == 'PLANNED_INCOME',
                    onSelected: (_) => setState(() => _kind = 'PLANNED_INCOME'),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH8,
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề (VD: Tiền điện, Lương tháng)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            AppSpacing.gapH8,
            Wrap(
              spacing: AppSpacing.sp4,
              children: ['NONE', 'WEEKLY', 'MONTHLY', 'YEARLY'].map((rec) {
                return ChoiceChip(
                  label: Text(rec),
                  selected: _recurrence == rec,
                  onSelected: (_) => setState(() => _recurrence = rec),
                );
              }).toList(),
            ),
            if (_kind == 'BILL' && envelopes.isNotEmpty) ...[
              AppSpacing.gapH8,
              Wrap(
                spacing: AppSpacing.sp4,
                children: [
                  ChoiceChip(
                    label: const Text('Không liên kết quỹ'),
                    selected: _linkedEnvelopeId == null,
                    onSelected: (_) => setState(() => _linkedEnvelopeId = null),
                  ),
                  ...envelopes.map((e) {
                    return ChoiceChip(
                      label: Text(e.name),
                      selected: _linkedEnvelopeId == e.id,
                      onSelected: (_) =>
                          setState(() => _linkedEnvelopeId = e.id),
                    );
                  }),
                ],
              ),
            ],
            AppSpacing.gapH8,
            Center(
              child: Text(
                VndFormatter.format(_amountVnd),
                style: VndFormatter.withTabularFigures(
                  AppTypography.largeTitle,
                ),
              ),
            ),
            CustomKeypad(
              onDigitPressed: (d) {
                final next = _amountVnd * 10 + d;
                if (next <= VndMoney.maxSafeVnd) {
                  setState(() => _amountVnd = next);
                }
              },
              onBackspacePressed: () => setState(() => _amountVnd ~/= 10),
              onDonePressed: _submit,
            ),
            AppSpacing.gapH8,
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fillAccentVerdantPrimary,
                foregroundColor: AppColors.textInverse,
              ),
              onPressed: _amountVnd <= 0 ? null : _submit,
              child: const Text('Lưu lịch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _amountVnd <= 0) return;

    await ref.read(plansControllerProvider.notifier).createScheduledItem(
          kind: _kind,
          title: title,
          amountVnd: _amountVnd,
          dueDate: _dueDate,
          recurrence: _recurrence,
          anchorDayOfMonth: _dueDate.day,
          linkedEnvelopeId: _linkedEnvelopeId,
        );
    if (mounted) Navigator.of(context).pop();
  }
}
