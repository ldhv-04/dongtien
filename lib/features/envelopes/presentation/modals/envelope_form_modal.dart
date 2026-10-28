import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../../../../domain/envelopes/envelope_policy.dart';
import '../../providers/envelope_controller.dart';

/// Modal sheet for creating or editing a Virtual Fund Envelope.
class EnvelopeFormModal extends ConsumerStatefulWidget {
  final Envelope? editingEnvelope;

  const EnvelopeFormModal({
    super.key,
    this.editingEnvelope,
  });

  @override
  ConsumerState<EnvelopeFormModal> createState() => _EnvelopeFormModalState();
}

class _EnvelopeFormModalState extends ConsumerState<EnvelopeFormModal> {
  late TextEditingController _nameController;
  EnvelopePolicy _policy = EnvelopePolicy.protected;
  int _targetAmountVnd = 0;
  DateTime? _targetDate;
  bool _allowNegativeException = false;
  int _priority = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final env = widget.editingEnvelope;
    if (env != null) {
      _nameController = TextEditingController(text: env.name);
      _policy = EnvelopePolicy.fromDbValue(env.policy);
      _targetAmountVnd = env.targetAmountVnd ?? 0;
      _targetDate = env.targetDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(env.targetDateMs!)
          : null;
      _allowNegativeException = env.allowNegativeException;
      _priority = env.priority;
    } else {
      _nameController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onDigit(int digit) {
    final next = _targetAmountVnd * 10 + digit;
    if (next <= VndMoney.maxSafeVnd) {
      setState(() => _targetAmountVnd = next);
    }
  }

  void _onBackspace() {
    setState(() => _targetAmountVnd = _targetAmountVnd ~/ 10);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingEnvelope != null;

    return Semantics(
      identifier: 'modal_envelope_form',
      container: true,
      child: Container(
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
                isEditing ? 'Chỉnh sửa quỹ tiền' : 'Tạo quỹ tiền mới',
                style: AppTypography.headline,
              ),
              AppSpacing.gapH12,
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên quỹ (VD: Quỹ Khẩn Cấp, Tiền Nhà)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              AppSpacing.gapH12,
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Quỹ bảo vệ (Bắt buộc)'),
                      selected: _policy == EnvelopePolicy.protected,
                      onSelected: (_) =>
                          setState(() => _policy = EnvelopePolicy.protected),
                    ),
                  ),
                  AppSpacing.gapW8,
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Quỹ linh hoạt'),
                      selected: _policy == EnvelopePolicy.flexible,
                      onSelected: (_) =>
                          setState(() => _policy = EnvelopePolicy.flexible),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Cho phép chi tiêu thâm hụt',
                  style: AppTypography.subheadline,
                ),
                value: _allowNegativeException,
                onChanged: (v) => setState(() => _allowNegativeException = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mục tiêu: ${VndFormatter.format(_targetAmountVnd)}',
                    style: VndFormatter.withTabularFigures(
                      AppTypography.bodyMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _targetDate ?? now.add(const Duration(days: 90)),
                        firstDate: now,
                        lastDate: DateTime(now.year + 10),
                      );
                      if (picked != null) {
                        setState(() => _targetDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _targetDate != null
                          ? '${_targetDate!.day.toString().padLeft(2, '0')}/${_targetDate!.month.toString().padLeft(2, '0')}/${_targetDate!.year}'
                          : 'Chọn ngày đích',
                    ),
                  ),
                ],
              ),
              CustomKeypad(
                onDigitPressed: _onDigit,
                onBackspacePressed: _onBackspace,
                onDonePressed: _submit,
              ),
              AppSpacing.gapH8,
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fillAccentVerdantPrimary,
                  foregroundColor: AppColors.textInverse,
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo quỹ tiền'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);
    final controller = ref.read(envelopeControllerProvider.notifier);
    final targetVal = _targetAmountVnd > 0 ? _targetAmountVnd : null;

    bool ok;
    if (widget.editingEnvelope != null) {
      ok = await controller.updateEnvelope(
        id: widget.editingEnvelope!.id,
        name: name,
        policy: _policy,
        targetAmountVnd: targetVal,
        targetDate: _targetDate,
        allowNegativeException: _allowNegativeException,
        priority: _priority,
      );
    } else {
      ok = await controller.createEnvelope(
        name: name,
        policy: _policy,
        targetAmountVnd: targetVal,
        targetDate: _targetDate,
        allowNegativeException: _allowNegativeException,
        priority: _priority,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) Navigator.of(context).pop();
    }
  }
}
