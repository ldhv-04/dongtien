import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/database/daos/ledger_dao.dart';
import '../../../core/money/vnd_formatter.dart';
import '../../../core/money/vnd_money.dart';
import '../../../core/widgets/custom_keypad.dart';
import '../../../domain/ledger/account_kind.dart';
import 'controllers/account_controller.dart';

/// Modal sheet for creating or editing a Cash, Bank, or Credit Card account.
class AddEditAccountModal extends ConsumerStatefulWidget {
  final AccountWithBalance? editingAccount;

  const AddEditAccountModal({
    super.key,
    this.editingAccount,
  });

  @override
  ConsumerState<AddEditAccountModal> createState() =>
      _AddEditAccountModalState();
}

class _AddEditAccountModalState extends ConsumerState<AddEditAccountModal> {
  late TextEditingController _nameController;
  AccountKind _selectedKind = AccountKind.assetCash;
  int _openingBalanceVnd = 0;
  int _creditLimitVnd = 0;
  bool _editingCreditLimit = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final acc = widget.editingAccount;
    if (acc != null) {
      _nameController = TextEditingController(text: acc.name);
      _selectedKind = acc.kind;
      _creditLimitVnd = acc.creditLimit;
    } else {
      _nameController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onDigitPressed(int digit) {
    setState(() {
      if (_editingCreditLimit) {
        final next = _creditLimitVnd * 10 + digit;
        if (next <= VndMoney.maxSafeVnd) _creditLimitVnd = next;
      } else {
        final next = _openingBalanceVnd * 10 + digit;
        if (next <= VndMoney.maxSafeVnd) _openingBalanceVnd = next;
      }
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_editingCreditLimit) {
        _creditLimitVnd = _creditLimitVnd ~/ 10;
      } else {
        _openingBalanceVnd = _openingBalanceVnd ~/ 10;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingAccount != null;

    return Semantics(
      identifier: 'modal_add_account',
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
                isEditing ? 'Chỉnh sửa tài khoản' : 'Thêm tài khoản mới',
                style: AppTypography.headline,
              ),
              AppSpacing.gapH12,
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên tài khoản (VD: Tiền mặt, Vietcombank)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              if (!isEditing) ...[
                AppSpacing.gapH12,
                const Text('Loại tài khoản', style: AppTypography.subheadline),
                AppSpacing.gapH4,
                Wrap(
                  spacing: AppSpacing.sp4,
                  children: [
                    ChoiceChip(
                      label: const Text('Tiền mặt'),
                      selected: _selectedKind == AccountKind.assetCash,
                      onSelected: (_) => setState(() {
                        _selectedKind = AccountKind.assetCash;
                        _editingCreditLimit = false;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Ngân hàng'),
                      selected: _selectedKind == AccountKind.assetBank,
                      onSelected: (_) => setState(() {
                        _selectedKind = AccountKind.assetBank;
                        _editingCreditLimit = false;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Thẻ tín dụng'),
                      selected:
                          _selectedKind == AccountKind.liabilityCreditCard,
                      onSelected: (_) => setState(
                        () => _selectedKind = AccountKind.liabilityCreditCard,
                      ),
                    ),
                  ],
                ),
              ],
              AppSpacing.gapH12,
              if (_selectedKind == AccountKind.liabilityCreditCard) ...[
                Row(
                  children: [
                    if (!isEditing)
                      Expanded(
                        child: ChoiceChip(
                          label: Text(
                            'Dư nợ đầu: ${VndFormatter.format(_openingBalanceVnd)}',
                          ),
                          selected: !_editingCreditLimit,
                          onSelected: (_) =>
                              setState(() => _editingCreditLimit = false),
                        ),
                      ),
                    if (!isEditing) AppSpacing.gapW8,
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          'Hạn mức: ${VndFormatter.format(_creditLimitVnd)}',
                        ),
                        selected: _editingCreditLimit || isEditing,
                        onSelected: (_) =>
                            setState(() => _editingCreditLimit = true),
                      ),
                    ),
                  ],
                ),
              ] else if (!isEditing) ...[
                Text(
                  'Số dư ban đầu: ${VndFormatter.format(_openingBalanceVnd)}',
                  style: VndFormatter.withTabularFigures(
                    AppTypography.bodyMedium,
                  ),
                ),
              ],
              if (!isEditing ||
                  _selectedKind == AccountKind.liabilityCreditCard) ...[
                AppSpacing.gapH8,
                CustomKeypad(
                  onDigitPressed: _onDigitPressed,
                  onBackspacePressed: _onBackspacePressed,
                  onDonePressed: _submit,
                  isSubmitting: _isSubmitting,
                  isDoneEnabled: _nameController.text.trim().isNotEmpty,
                ),
              ],
              AppSpacing.gapH12,
              Semantics(
                identifier: 'btn_submit_account',
                button: true,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fillAccentVerdantPrimary,
                    foregroundColor: AppColors.textInverse,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: const Text('Lưu tài khoản'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final controller = ref.read(accountControllerProvider.notifier);
      if (widget.editingAccount != null) {
        await controller.updateAccount(
          id: widget.editingAccount!.id,
          name: name,
          creditLimitVnd: _creditLimitVnd,
        );
      } else {
        await controller.createAccount(
          name: name,
          kind: _selectedKind,
          creditLimitVnd: _creditLimitVnd,
          openingBalanceVnd: _openingBalanceVnd,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
