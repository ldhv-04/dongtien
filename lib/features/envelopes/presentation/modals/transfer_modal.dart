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

/// Modal sheet for transferring virtual funds between two Envelopes.
class TransferModal extends ConsumerStatefulWidget {
  final List<Envelope> envelopes;
  final Envelope? initialSourceEnvelope;

  const TransferModal({
    super.key,
    required this.envelopes,
    this.initialSourceEnvelope,
  });

  @override
  ConsumerState<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends ConsumerState<TransferModal> {
  int _amountVnd = 0;
  int? _sourceId;
  int? _destId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.envelopes.isNotEmpty) {
      _sourceId = widget.initialSourceEnvelope?.id ?? widget.envelopes.first.id;
      for (final e in widget.envelopes) {
        if (e.id != _sourceId) {
          _destId = e.id;
          break;
        }
      }
    }
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
    Envelope? source;
    for (final e in widget.envelopes) {
      if (e.id == _sourceId) {
        source = e;
        break;
      }
    }

    final isBlocked = source != null &&
        _amountVnd > source.reservedBalanceVnd &&
        !source.allowNegativeException;

    return Semantics(
      identifier: 'modal_transfer',
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
              const Text(
                'Chuyển tiền giữa các quỹ',
                style: AppTypography.headline,
              ),
              AppSpacing.gapH12,
              const Text('Từ quỹ', style: AppTypography.subheadline),
              Wrap(
                spacing: AppSpacing.sp4,
                children: widget.envelopes.map((e) {
                  return ChoiceChip(
                    label: Text(
                      '${e.name} (${VndFormatter.format(e.reservedBalanceVnd)})',
                      style: VndFormatter.withTabularFigures(
                        AppTypography.caption,
                      ),
                    ),
                    selected: _sourceId == e.id,
                    onSelected: (_) {
                      setState(() {
                        _sourceId = e.id;
                        if (_destId == e.id) {
                          _destId = widget.envelopes
                              .where((x) => x.id != e.id)
                              .firstOrNull
                              ?.id;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              AppSpacing.gapH8,
              const Text('Đến quỹ', style: AppTypography.subheadline),
              Wrap(
                spacing: AppSpacing.sp4,
                children:
                    widget.envelopes.where((e) => e.id != _sourceId).map((e) {
                  return ChoiceChip(
                    label: Text(e.name),
                    selected: _destId == e.id,
                    onSelected: (_) => setState(() => _destId = e.id),
                  );
                }).toList(),
              ),
              AppSpacing.gapH8,
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
              AppSpacing.gapH8,
              CustomKeypad(
                onDigitPressed: _onDigit,
                onBackspacePressed: _onBackspace,
                onDonePressed: _submit,
              ),
              AppSpacing.gapH8,
              Semantics(
                identifier: 'btn_confirm_transfer',
                button: true,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fillAccentVerdantPrimary,
                    foregroundColor: AppColors.textInverse,
                  ),
                  onPressed: (_isSubmitting ||
                          _amountVnd <= 0 ||
                          isBlocked ||
                          _sourceId == null ||
                          _destId == null ||
                          _sourceId == _destId)
                      ? null
                      : _submit,
                  child: const Text('Xác nhận chuyển quỹ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_sourceId == null || _destId == null || _sourceId == _destId) return;
    setState(() => _isSubmitting = true);
    final ok = await ref.read(envelopeControllerProvider.notifier).transfer(
          fromEnvelopeId: _sourceId!,
          toEnvelopeId: _destId!,
          amountVnd: _amountVnd,
        );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) Navigator.of(context).pop();
    }
  }
}
