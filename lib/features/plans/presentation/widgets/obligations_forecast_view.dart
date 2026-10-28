import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../transactions/presentation/controllers/transaction_providers.dart';
import '../providers/plans_providers.dart';

/// Shows the scheduled item creation/edit modal.
void showScheduledItemModal(BuildContext context,
    {ScheduledItem? existingItem}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddScheduledItemModal(existingItem: existingItem),
  );
}

/// Sub-view (c) of Plans tab: Scheduled Bills & Planned Income + 30/60/90-day Cash-Flow Forecast.
class ObligationsForecastView extends ConsumerWidget {
  const ObligationsForecastView({super.key});

  void _openEditModal(BuildContext context, ScheduledItem item) {
    showScheduledItemModal(context, existingItem: item);
  }

  Future<void> _confirmAndDeletePending(
    BuildContext context,
    WidgetRef ref,
    ScheduledItem item,
  ) async {
    final isBill = item.kind == 'BILL';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBill ? 'Xác nhận xóa hoá đơn' : 'Xác nhận xóa khoản thu'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${item.title}" (${VndFormatter.format(item.amountVnd)}) khỏi danh sách không?',
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
          .deleteScheduledItem(item.id);
    }
  }

  Future<void> _confirmAndDeleteCompleted(
    BuildContext context,
    WidgetRef ref,
    ScheduledItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa & hoàn tác giao dịch'),
        content: Text(
          'Hoá đơn/Khoản thu "${item.title}" (${VndFormatter.format(item.amountVnd)}) đã được ghi nhận vào sổ cái tài chính. Khi xóa, giao dịch thanh toán sẽ được hoàn tác tự động (hoàn lại tiền vào tài khoản và quỹ tiền bảo vệ liên quan). Bạn có chắc chắn muốn xóa không?',
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
            child: const Text('Hoàn tác & Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(plansControllerProvider.notifier)
          .deleteScheduledItem(item.id);
    }
  }

  Future<void> _confirmAndPay(
    BuildContext context,
    WidgetRef ref,
    ScheduledItem item,
  ) async {
    final isBill = item.kind == 'BILL';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBill ? 'Xác nhận thanh toán' : 'Xác nhận đã nhận'),
        content: Text(
          'Bạn có chắc chắn muốn ghi nhận ${isBill ? 'đã thanh toán hoá đơn' : 'đã nhận khoản thu'} '
          '"${item.title}" với số tiền ${VndFormatter.format(item.amountVnd)}?',
          style: VndFormatter.withTabularFigures(AppTypography.bodyMedium),
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
          .markScheduledItemPaid(scheduledItemId: item.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allScheduledItemsStreamProvider);
    final forecastAsync = ref.watch(cashFlowForecastProvider);
    final horizonDays = ref.watch(forecastHorizonDaysProvider);
    final categories = ref.watch(categoriesStreamProvider).value ?? [];

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
            final completed =
                items.where((i) => i.status == 'PAID_OR_RECEIVED').toList();
            final catMap = {for (final c in categories) c.id: c.name};

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pending.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sp6),
                    child: Text(
                      'Chưa có hoá đơn hoặc thu nhập dự kiến nào.',
                      style: AppTypography.subheadline,
                    ),
                  )
                else
                  ...pending.map((item) {
                    final isBill = item.kind == 'BILL';
                    final dt =
                        DateTime.fromMillisecondsSinceEpoch(item.dueDateMs);
                    final dStr =
                        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                    final catName = item.categoryId != null
                        ? catMap[item.categoryId]
                        : null;
                    final subtitle = catName != null
                        ? '${isBill ? 'Hoá đơn cam kết' : 'Thu nhập dự kiến'} • $catName • Hạn: $dStr'
                        : '${isBill ? 'Hoá đơn cam kết' : 'Thu nhập dự kiến'} • Hạn: $dStr';

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
                                  Text(item.title,
                                      style: AppTypography.bodyMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
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
                                            : AppColors
                                                .textAccentVerdantPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  identifier: 'btn_edit_obligation_${item.id}',
                                  button: true,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    tooltip: 'Sửa',
                                    onPressed: () =>
                                        _openEditModal(context, item),
                                  ),
                                ),
                                Semantics(
                                  identifier:
                                      'btn_delete_obligation_${item.id}',
                                  button: true,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.textAccentRubyPrimary),
                                    tooltip: 'Xóa',
                                    onPressed: () => _confirmAndDeletePending(
                                        context, ref, item),
                                  ),
                                ),
                                Semantics(
                                  identifier: 'btn_pay_obligation_${item.id}',
                                  button: true,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _confirmAndPay(context, ref, item),
                                    child: Text(isBill ? 'Đã trả' : 'Đã nhận'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (completed.isNotEmpty) ...[
                  AppSpacing.gapH16,
                  const Text(
                    'LỊCH SỬ ĐÃ THANH TOÁN / ĐÃ NHẬN',
                    style: AppTypography.subheadline,
                  ),
                  AppSpacing.gapH8,
                  ...completed.map((item) {
                    final isBill = item.kind == 'BILL';
                    final dt =
                        DateTime.fromMillisecondsSinceEpoch(item.dueDateMs);
                    final dStr =
                        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                    final catName = item.categoryId != null
                        ? catMap[item.categoryId]
                        : null;
                    final subtitle = catName != null
                        ? '${isBill ? 'Hoá đơn đã trả' : 'Thu nhập đã nhận'} • $catName • Ngày: $dStr'
                        : '${isBill ? 'Hoá đơn đã trả' : 'Thu nhập đã nhận'} • Ngày: $dStr';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                      child: Container(
                        padding: AppSpacing.paddingCard,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: AppColors.borderSecondary),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: VndFormatter.withTabularFigures(
                                      AppTypography.caption.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    VndFormatter.format(item.amountVnd),
                                    style: VndFormatter.withTabularFigures(
                                      AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  identifier: 'btn_edit_obligation_${item.id}',
                                  button: true,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    tooltip: 'Sửa',
                                    onPressed: () =>
                                        _openEditModal(context, item),
                                  ),
                                ),
                                Semantics(
                                  identifier:
                                      'btn_delete_obligation_${item.id}',
                                  button: true,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.textAccentRubyPrimary),
                                    tooltip: 'Xóa',
                                    onPressed: () => _confirmAndDeleteCompleted(
                                        context, ref, item),
                                  ),
                                ),
                                Semantics(
                                  identifier:
                                      'btn_completed_obligation_${item.id}',
                                  button: true,
                                  enabled: false,
                                  child: const OutlinedButton(
                                    onPressed: null,
                                    child: Text('Đã hoàn tất'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
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
  final ScheduledItem? existingItem;
  const _AddScheduledItemModal({this.existingItem});

  @override
  ConsumerState<_AddScheduledItemModal> createState() =>
      _AddScheduledItemModalState();
}

class _AddScheduledItemModalState
    extends ConsumerState<_AddScheduledItemModal> {
  final TextEditingController _titleController = TextEditingController();
  String _kind = 'BILL';
  int _amountVnd = 0;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  int? _categoryId;
  int? _linkedEnvelopeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _titleController.text = item.title;
      _kind = item.kind;
      _amountVnd = item.amountVnd;
      _dueDate = DateTime.fromMillisecondsSinceEpoch(item.dueDateMs);
      _categoryId = item.categoryId;
      _linkedEnvelopeId = item.linkedEnvelopeId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  int? _resolveDefaultCategoryId(String kind, List<Category> allCategories) {
    if (kind == 'BILL') {
      final expenseCats =
          allCategories.where((c) => c.kind == 'EXPENSE').toList();
      final defaultCat = expenseCats.cast<Category?>().firstWhere(
            (c) => c!.name == 'Hoá đơn & Tiện ích',
            orElse: () => expenseCats.cast<Category?>().firstWhere(
                  (c) => c!.name == 'Nhà cửa',
                  orElse: () =>
                      expenseCats.isNotEmpty ? expenseCats.first : null,
                ),
          );
      return defaultCat?.id;
    } else {
      final incomeCats =
          allCategories.where((c) => c.kind == 'INCOME').toList();
      final defaultCat = incomeCats.cast<Category?>().firstWhere(
            (c) => c!.name == 'Lương',
            orElse: () => incomeCats.cast<Category?>().firstWhere(
                  (c) => c!.name == 'Thưởng',
                  orElse: () => incomeCats.isNotEmpty ? incomeCats.first : null,
                ),
          );
      return defaultCat?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final envelopes = ref.watch(envelopesStreamProvider).value ?? [];
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final availableCategories = categories
        .where((c) => c.kind == (_kind == 'BILL' ? 'EXPENSE' : 'INCOME'))
        .toList();

    // Default category selection if unset or invalid for current kind
    if (availableCategories.isNotEmpty) {
      final isCurrentValid =
          availableCategories.any((c) => c.id == _categoryId);
      if (_categoryId == null || !isCurrentValid) {
        _categoryId = _resolveDefaultCategoryId(_kind, categories);
      }
    }

    final isEditing = widget.existingItem != null;

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
            Text(
              isEditing
                  ? 'Chỉnh sửa lịch nghĩa vụ'
                  : 'Thêm lịch nghĩa vụ / thu nhập',
              style: AppTypography.headline,
            ),
            AppSpacing.gapH8,
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Hoá đơn (BILL)'),
                    selected: _kind == 'BILL',
                    onSelected: (_) {
                      setState(() {
                        _kind = 'BILL';
                        _categoryId =
                            _resolveDefaultCategoryId('BILL', categories);
                      });
                    },
                  ),
                ),
                AppSpacing.gapW8,
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Thu nhập dự kiến'),
                    selected: _kind == 'PLANNED_INCOME',
                    onSelected: (_) {
                      setState(() {
                        _kind = 'PLANNED_INCOME';
                        _categoryId = _resolveDefaultCategoryId(
                            'PLANNED_INCOME', categories);
                      });
                    },
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
            Text(
              'Danh mục (${_kind == 'BILL' ? 'Chi tiêu' : 'Thu nhập'})',
              style: AppTypography.subheadline,
            ),
            AppSpacing.gapH4,
            if (availableCategories.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sp4,
                children: availableCategories.map((c) {
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _categoryId = c.id);
                      }
                    },
                  );
                }).toList(),
              ),
            AppSpacing.gapH8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hạn: ${_dueDate.day.toString().padLeft(2, '0')}/${_dueDate.month.toString().padLeft(2, '0')}/${_dueDate.year}',
                  style:
                      VndFormatter.withTabularFigures(AppTypography.bodyMedium),
                ),
                TextButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: now.subtract(const Duration(days: 365)),
                            lastDate: now.add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Chọn ngày'),
                ),
              ],
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
              isSubmitting: _isSubmitting,
              isDoneEnabled:
                  _titleController.text.trim().isNotEmpty && _amountVnd > 0,
            ),
            AppSpacing.gapH8,
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fillAccentVerdantPrimary,
                foregroundColor: AppColors.textInverse,
              ),
              onPressed: (_amountVnd <= 0 || _isSubmitting) ? null : _submit,
              child: Text(isEditing ? 'Lưu thay đổi' : 'Lưu lịch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final title = _titleController.text.trim();
    if (title.isEmpty || _amountVnd <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.existingItem == null) {
        await ref.read(plansControllerProvider.notifier).createScheduledItem(
              kind: _kind,
              title: title,
              amountVnd: _amountVnd,
              dueDate: _dueDate,
              recurrence: 'NONE',
              anchorDayOfMonth: _dueDate.day,
              categoryId: _categoryId,
              linkedEnvelopeId: _linkedEnvelopeId,
            );
      } else {
        await ref.read(plansControllerProvider.notifier).updateScheduledItem(
              scheduledItemId: widget.existingItem!.id,
              kind: _kind,
              title: title,
              amountVnd: _amountVnd,
              dueDate: _dueDate,
              categoryId: _categoryId,
              linkedEnvelopeId: _linkedEnvelopeId,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
