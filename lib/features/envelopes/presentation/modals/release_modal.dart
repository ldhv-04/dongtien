import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/vnd_formatter.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/widgets/custom_keypad.dart';
import '../../providers/envelope_controller.dart';

/// Modal sheet for releasing reserved funds from an Envelope back to Available-to-Allocate.
class ReleaseModal extends ConsumerStatefulWidget {
  final List<Envelope> envelopes;
  final Envelope? initialEnvelope;

  const ReleaseModal({
    super.key,
    required this.envelopes,
    this.initialEnvelope,
  });

  @override
  ConsumerState<ReleaseModal> createState() => _ReleaseModalState();
}

class _ReleaseModalState extends ConsumerState<ReleaseModal> {
  int _amountVnd = 0;
  late int? _selectedEnvelopeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedEnvelopeId = widget.initialEnvelope?.id ??
        (widget.envelopes.isNotEmpty ? widget.envelopes.first.id : null);
  }

  void _onDigit(int digit) {
    final next = _amountVnd * 10 + digit;
    if (next <= VndMoney.maxSafeVnd) {
      setState(() => _amountVnd = next);
    }
  }

  void _onBackspace() {
    setState(() => _amountVnd = _amountVnd ~/ 10);
  }

  @override
  Widget build(BuildContext context) {
    Envelope? selected;
    for (final e in widget.envelopes) {
      if (e.id == _selectedEnvelopeId) {
        selected = e;
        break;
      }
    }

    final isDeficit =
        selected != null && _amountVnd > selected.reservedBalanceVnd;
    final isBlocked = isDeficit && !selected.allowNegativeException;

    return Semantics(
      identifier: 'modal_release',
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
              const Text('Giải phóng quỹ tiền', style: AppTypography.headline),
              if (selected != null) ...[
                AppSpacing.gapH4,
                Text(
                  'Số dư hiện tại (${selected.name}): ${VndFormatter.format(selected.reservedBalanceVnd)}',
                  style: VndFormatter.withTabularFigures(
                    AppTypography.subheadline,
                  ),
                ),
              ],
              AppSpacing.gapH12,
              if (widget.initialEnvelope == null) ...[
                Wrap(
                  spacing: AppSpacing.sp4,
                  children: widget.envelopes.map((env) {
                    return ChoiceChip(
                      label: Text(env.name),
                      selected: _selectedEnvelopeId == env.id,
                      onSelected: (_) =>
                          setState(() => _selectedEnvelopeId = env.id),
                    );
                  }).toList(),
                ),
                AppSpacing.gapH8,
              ],
              Center(
                child: Text(
                  VndFormatter.format(_amountVnd),
                  style: VndFormatter.withTabularFigures(
                    AppTypography.largeTitle.copyWith(
                      color: isBlocked
                          ? AppColors.textAccentRubyPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (isBlocked) ...[
                AppSpacing.gapH4,
                Text(
                  'Số tiền giải phóng vượt quá số dư quỹ. Quỹ này không cho phép thâm hụt.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textAccentRubyPrimary,
                  ),
                ),
              ],
              AppSpacing.gapH8,
              CustomKeypad(
                onDigitPressed: _onDigit,
                onBackspacePressed: _onBackspace,
                onDonePressed: _submit,
              ),
              AppSpacing.gapH8,
              Semantics(
                identifier: 'btn_confirm_release',
                button: true,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fillAccentEmberPrimary,
                    foregroundColor: AppColors.textInverse,
                  ),
                  onPressed: (_isSubmitting ||
                          _amountVnd <= 0 ||
                          isBlocked ||
                          _selectedEnvelopeId == null)
                      ? null
                      : _submit,
                  child: const Text('Xác nhận giải phóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedEnvelopeId == null || _amountVnd <= 0) return;
    setState(() => _isSubmitting = true);
    final ok = await ref.read(envelopeControllerProvider.notifier).release(
          envelopeId: _selectedEnvelopeId!,
          amountVnd: _amountVnd,
        );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) Navigator.of(context).pop();
    }
  }
}
