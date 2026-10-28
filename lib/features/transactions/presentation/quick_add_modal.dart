import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ledger_dao.dart';
import '../../../core/money/vnd_formatter.dart';
import '../../../core/money/vnd_money.dart';
import '../../../core/widgets/custom_keypad.dart';
import '../../../domain/ledger/account_kind.dart';
import '../../../domain/ledger/post_transaction_command.dart';
import '../../../domain/ledger/transaction_type.dart';
import '../../dashboard/presentation/providers/dashboard_providers.dart';
import '../domain/models/transaction_item.dart';
import 'controllers/transaction_controller.dart';
import 'controllers/transaction_providers.dart';

/// Fast transaction entry modal with CustomKeypad, 5-way segmented selector,
/// category/account/envelope chips, deficit guard, and idempotency key protection.
class QuickAddModal extends ConsumerStatefulWidget {
  final TransactionItem? editingItem;

  const QuickAddModal({
    super.key,
    this.editingItem,
  });

  @override
  ConsumerState<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends ConsumerState<QuickAddModal> {
  int _amountVnd = 0;
  TransactionType _selectedType = TransactionType.expense;
  int? _selectedCategoryId;
  int? _selectedSourceAccountId;
  int? _selectedDestAccountId;
  int? _selectedEnvelopeId;
  late TextEditingController _noteController;
  late String _idempotencyKey;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _idempotencyKey =
        'quickadd_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(999999)}';
    final editing = widget.editingItem;
    if (editing != null) {
      _amountVnd = editing.amountVnd;
      _selectedType = editing.type == TransactionType.openingBalance ||
              editing.type == TransactionType.reversal
          ? TransactionType.expense
          : editing.type;
      _selectedCategoryId = editing.category?.id;
      _selectedSourceAccountId = editing.sourceAccount?.id;
      _selectedDestAccountId = editing.destinationAccount?.id;
      _selectedEnvelopeId = editing.linkedEnvelope?.id;
      _noteController = TextEditingController(text: editing.description);
    } else {
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onDigitPressed(int digit) {
    final next = _amountVnd * 10 + digit;
    if (next <= VndMoney.maxSafeVnd) {
      setState(() {
        _amountVnd = next;
        _errorMessage = null;
      });
    }
  }

  void _onBackspacePressed() {
    setState(() {
      _amountVnd = _amountVnd ~/ 10;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsWithBalancesStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final envelopesAsync = ref.watch(envelopesStreamProvider);

    final allAccounts = (accountsAsync.value ?? []).where((a) {
      return a.kind == AccountKind.assetCash ||
          a.kind == AccountKind.assetBank ||
          a.kind == AccountKind.liabilityCreditCard;
    }).toList();

    final liquidAccounts = allAccounts.where((a) => a.kind.isLiquid).toList();
    final creditCards = allAccounts
        .where((a) => a.kind == AccountKind.liabilityCreditCard)
        .toList();

    final allCategories = categoriesAsync.value ?? [];
    final filteredCategories = allCategories.where((c) {
      if (_selectedType == TransactionType.income) {
        return c.kind == 'INCOME';
      }
      return c.kind == 'EXPENSE';
    }).toList();

    final allEnvelopes = envelopesAsync.value ?? [];

    // Default selections if not yet chosen
    if (_selectedCategoryId == null && filteredCategories.isNotEmpty) {
      _selectedCategoryId = filteredCategories.first.id;
    }
    if (_selectedType == TransactionType.expense &&
        _selectedSourceAccountId == null &&
        allAccounts.isNotEmpty) {
      _selectedSourceAccountId = allAccounts.first.id;
    } else if (_selectedType == TransactionType.income &&
        _selectedDestAccountId == null &&
        liquidAccounts.isNotEmpty) {
      _selectedDestAccountId = liquidAccounts.first.id;
    } else if (_selectedType == TransactionType.transfer) {
      if (_selectedSourceAccountId == null && liquidAccounts.isNotEmpty) {
        _selectedSourceAccountId = liquidAccounts.first.id;
      }
      if (_selectedDestAccountId == null && liquidAccounts.length > 1) {
        _selectedDestAccountId = liquidAccounts[1].id;
      }
    } else if (_selectedType == TransactionType.creditCardPayment) {
      if (_selectedSourceAccountId == null && liquidAccounts.isNotEmpty) {
        _selectedSourceAccountId = liquidAccounts.first.id;
      }
      if (_selectedDestAccountId == null && creditCards.isNotEmpty) {
        _selectedDestAccountId = creditCards.first.id;
      }
    } else if (_selectedType == TransactionType.refund &&
        _selectedDestAccountId == null &&
        allAccounts.isNotEmpty) {
      _selectedDestAccountId = allAccounts.first.id;
    }

    Envelope? selectedEnvelope;
    if (_selectedEnvelopeId != null) {
      for (final e in allEnvelopes) {
        if (e.id == _selectedEnvelopeId) {
          selectedEnvelope = e;
          break;
        }
      }
    }

    final bool hasEnvelopeDeficit = _selectedType == TransactionType.expense &&
        selectedEnvelope != null &&
        _amountVnd > selectedEnvelope.reservedBalanceVnd;
    final bool isBlockedByDeficit =
        hasEnvelopeDeficit && !selectedEnvelope.allowNegativeException;

    return Semantics(
      identifier: 'modal_quick_add',
      container: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.sp6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.gapH8,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.editingItem != null
                        ? 'Chỉnh sửa giao dịch'
                        : 'Thêm giao dịch',
                    style: AppTypography.headline,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // Live formatted VND display
              Semantics(
                identifier: 'input_amount_display',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp4),
                  alignment: Alignment.center,
                  child: Text(
                    VndFormatter.format(_amountVnd),
                    style: VndFormatter.withTabularFigures(
                      AppTypography.largeTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              // 5-Way Segmented Type Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTypeSegment(
                      'segment_expense',
                      'Chi tiêu',
                      TransactionType.expense,
                    ),
                    AppSpacing.gapW8,
                    _buildTypeSegment(
                      'segment_income',
                      'Thu nhập',
                      TransactionType.income,
                    ),
                    AppSpacing.gapW8,
                    _buildTypeSegment(
                      'segment_transfer',
                      'Chuyển khoản',
                      TransactionType.transfer,
                    ),
                    AppSpacing.gapW8,
                    _buildTypeSegment(
                      'segment_card_payment',
                      'Trả thẻ',
                      TransactionType.creditCardPayment,
                    ),
                    AppSpacing.gapW8,
                    _buildTypeSegment(
                      'segment_refund',
                      'Hoàn tiền',
                      TransactionType.refund,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH12,
              // Category chips (for Expense, Income, Refund)
              if (_selectedType == TransactionType.expense ||
                  _selectedType == TransactionType.income ||
                  _selectedType == TransactionType.refund) ...[
                const Text('Danh mục', style: AppTypography.subheadline),
                AppSpacing.gapH4,
                Wrap(
                  spacing: AppSpacing.sp4,
                  runSpacing: AppSpacing.sp3,
                  children: filteredCategories.map((c) {
                    final selected = _selectedCategoryId == c.id;
                    return Semantics(
                      identifier: 'chip_category_${c.id}',
                      button: true,
                      selected: selected,
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: selected,
                        selectedColor: AppColors.surfaceAccentVerdantSecondary,
                        onSelected: (_) {
                          setState(() => _selectedCategoryId = c.id);
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.gapH8,
              ],
              // Source account selector
              if (_selectedType == TransactionType.expense ||
                  _selectedType == TransactionType.transfer ||
                  _selectedType == TransactionType.creditCardPayment) ...[
                const Text('Từ tài khoản', style: AppTypography.subheadline),
                AppSpacing.gapH4,
                _buildAccountChips(
                  accounts: _selectedType == TransactionType.expense
                      ? allAccounts
                      : liquidAccounts,
                  selectedId: _selectedSourceAccountId,
                  prefix: 'chip_source_account_',
                  onSelect: (id) =>
                      setState(() => _selectedSourceAccountId = id),
                ),
                AppSpacing.gapH8,
              ],
              // Destination account selector
              if (_selectedType == TransactionType.income ||
                  _selectedType == TransactionType.transfer ||
                  _selectedType == TransactionType.creditCardPayment ||
                  _selectedType == TransactionType.refund) ...[
                Text(
                  _selectedType == TransactionType.creditCardPayment
                      ? 'Thẻ tín dụng cần trả'
                      : 'Vào tài khoản',
                  style: AppTypography.subheadline,
                ),
                AppSpacing.gapH4,
                _buildAccountChips(
                  accounts: _selectedType == TransactionType.creditCardPayment
                      ? creditCards
                      : (_selectedType == TransactionType.refund
                          ? allAccounts
                          : liquidAccounts),
                  selectedId: _selectedDestAccountId,
                  prefix: 'chip_dest_account_',
                  onSelect: (id) => setState(() => _selectedDestAccountId = id),
                ),
                AppSpacing.gapH8,
              ],
              // Optional Envelope selector (for Expense & Refund)
              if ((_selectedType == TransactionType.expense ||
                      _selectedType == TransactionType.refund) &&
                  allEnvelopes.isNotEmpty) ...[
                const Text(
                  'Quỹ tiền liên kết (tuỳ chọn)',
                  style: AppTypography.subheadline,
                ),
                AppSpacing.gapH4,
                Wrap(
                  spacing: AppSpacing.sp4,
                  runSpacing: AppSpacing.sp3,
                  children: [
                    ChoiceChip(
                      label: const Text('Không chọn'),
                      selected: _selectedEnvelopeId == null,
                      onSelected: (_) =>
                          setState(() => _selectedEnvelopeId = null),
                    ),
                    ...allEnvelopes.map((env) {
                      final selected = _selectedEnvelopeId == env.id;
                      return Semantics(
                        identifier: 'chip_envelope_${env.id}',
                        button: true,
                        selected: selected,
                        child: ChoiceChip(
                          label: Text(
                            '${env.name} (${VndFormatter.format(env.reservedBalanceVnd)})',
                            style: VndFormatter.withTabularFigures(
                              AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          selected: selected,
                          selectedColor:
                              AppColors.surfaceAccentVerdantSecondary,
                          onSelected: (_) =>
                              setState(() => _selectedEnvelopeId = env.id),
                        ),
                      );
                    }),
                  ],
                ),
                if (hasEnvelopeDeficit) ...[
                  AppSpacing.gapH8,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sp4),
                    decoration: BoxDecoration(
                      color: isBlockedByDeficit
                          ? AppColors.surfaceAccentRubySecondary
                          : AppColors.surfaceAccentMarigoldSecondary,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isBlockedByDeficit
                            ? AppColors.borderAccentRuby
                            : AppColors.borderAccentMarigold,
                      ),
                    ),
                    child: Text(
                      isBlockedByDeficit
                          ? 'Số tiền chi tiêu (${VndFormatter.format(_amountVnd)}) vượt quá số dư quỹ (${VndFormatter.format(selectedEnvelope.reservedBalanceVnd)}). Quỹ này không cho phép bội chi.'
                          : 'Cảnh báo: Chi tiêu vượt số dư quỹ (${VndFormatter.format(selectedEnvelope.reservedBalanceVnd)}). Quỹ sẽ chuyển sang số dư âm.',
                      style: VndFormatter.withTabularFigures(
                        AppTypography.caption.copyWith(
                          color: isBlockedByDeficit
                              ? AppColors.textAccentRubyPrimary
                              : AppColors.textAccentMarigoldPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
                AppSpacing.gapH8,
              ],
              // Note field
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Ghi chú giao dịch (tuỳ chọn)',
                  hintStyle: AppTypography.subheadline,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp5,
                    vertical: AppSpacing.sp4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                AppSpacing.gapH8,
                Text(
                  _errorMessage!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textAccentRubyPrimary,
                  ),
                ),
              ],
              AppSpacing.gapH8,
              // Custom Numeric Keypad
              CustomKeypad(
                onDigitPressed: _onDigitPressed,
                onBackspacePressed: _onBackspacePressed,
                onDonePressed: () => _handleSubmit(allAccounts),
              ),
              AppSpacing.gapH8,
              Semantics(
                identifier: 'btn_submit_transaction',
                button: true,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fillAccentEmberPrimary,
                      foregroundColor: AppColors.textInverse,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    onPressed:
                        (_isSubmitting || _amountVnd <= 0 || isBlockedByDeficit)
                            ? null
                            : () => _handleSubmit(allAccounts),
                    child: Text(
                      _isSubmitting ? 'Đang lưu...' : 'Lưu giao dịch',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment(
    String semanticId,
    String label,
    TransactionType type,
  ) {
    final selected = _selectedType == type;
    return Semantics(
      identifier: semanticId,
      button: true,
      selected: selected,
      child: ChoiceChip(
        label: Text(
          label,
          style: AppTypography.subheadline.copyWith(
            color: selected ? AppColors.textInverse : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: selected,
        selectedColor: AppColors.fillAccentVerdantPrimary,
        onSelected: (_) {
          setState(() {
            _selectedType = type;
            _selectedCategoryId = null;
            _errorMessage = null;
          });
        },
      ),
    );
  }

  Widget _buildAccountChips({
    required List<AccountWithBalance> accounts,
    required int? selectedId,
    required String prefix,
    required ValueChanged<int> onSelect,
  }) {
    if (accounts.isEmpty) {
      return const Text(
        'Chưa có tài khoản phù hợp. Hãy tạo tài khoản trước.',
        style: AppTypography.caption,
      );
    }
    return Wrap(
      spacing: AppSpacing.sp4,
      runSpacing: AppSpacing.sp3,
      children: accounts.map((acc) {
        final selected = selectedId == acc.id;
        return Semantics(
          identifier: '$prefix${acc.id}',
          button: true,
          selected: selected,
          child: ChoiceChip(
            label: Text(
              '${acc.name} (${VndFormatter.format(acc.balanceVnd)})',
              style: VndFormatter.withTabularFigures(
                AppTypography.caption.copyWith(color: AppColors.textPrimary),
              ),
            ),
            selected: selected,
            selectedColor: AppColors.surfaceAccentVerdantSecondary,
            onSelected: (_) => onSelect(acc.id),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleSubmit(List<AccountWithBalance> allAccounts) async {
    if (_isSubmitting || _amountVnd <= 0) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final nowMs = widget.editingItem?.transaction.occurredAt ??
          DateTime.now().millisecondsSinceEpoch;
      final note = _noteController.text.trim();

      PostTransactionCommand command;
      switch (_selectedType) {
        case TransactionType.expense:
          if (_selectedSourceAccountId == null || _selectedCategoryId == null) {
            throw StateError('Vui lòng chọn tài khoản và danh mục.');
          }
          command = PostTransactionCommand.expense(
            sourceAccountId: _selectedSourceAccountId!,
            categoryId: _selectedCategoryId!,
            amountVnd: _amountVnd,
            occurredAt: nowMs,
            description: note.isEmpty ? 'Chi tiêu' : note,
            linkedEnvelopeId: _selectedEnvelopeId,
            idempotencyKey: _idempotencyKey,
          );
          break;
        case TransactionType.income:
          if (_selectedDestAccountId == null || _selectedCategoryId == null) {
            throw StateError('Vui lòng chọn tài khoản nhận và danh mục.');
          }
          command = PostTransactionCommand.income(
            receivingAssetAccountId: _selectedDestAccountId!,
            categoryId: _selectedCategoryId!,
            amountVnd: _amountVnd,
            occurredAt: nowMs,
            description: note.isEmpty ? 'Thu nhập' : note,
            idempotencyKey: _idempotencyKey,
          );
          break;
        case TransactionType.transfer:
          if (_selectedSourceAccountId == null ||
              _selectedDestAccountId == null ||
              _selectedSourceAccountId == _selectedDestAccountId) {
            throw StateError(
                'Vui lòng chọn 2 tài khoản nguồn và đích khác nhau.');
          }
          command = PostTransactionCommand.transfer(
            sourceAssetAccountId: _selectedSourceAccountId!,
            destinationAssetAccountId: _selectedDestAccountId!,
            amountVnd: _amountVnd,
            occurredAt: nowMs,
            description: note.isEmpty ? 'Chuyển tiền nội bộ' : note,
            idempotencyKey: _idempotencyKey,
          );
          break;
        case TransactionType.creditCardPayment:
          if (_selectedSourceAccountId == null ||
              _selectedDestAccountId == null) {
            throw StateError(
                'Vui lòng chọn tài khoản thanh toán và thẻ tín dụng.');
          }
          command = PostTransactionCommand.creditCardPayment(
            creditCardAccountId: _selectedDestAccountId!,
            sourceAssetAccountId: _selectedSourceAccountId!,
            amountVnd: _amountVnd,
            occurredAt: nowMs,
            description: note.isEmpty ? 'Thanh toán thẻ tín dụng' : note,
            idempotencyKey: _idempotencyKey,
          );
          break;
        case TransactionType.refund:
          if (_selectedDestAccountId == null || _selectedCategoryId == null) {
            throw StateError('Vui lòng chọn tài khoản nhận và danh mục hoàn.');
          }
          command = PostTransactionCommand.refund(
            receivingAccountId: _selectedDestAccountId!,
            categoryId: _selectedCategoryId!,
            amountVnd: _amountVnd,
            occurredAt: nowMs,
            description: note.isEmpty ? 'Hoàn tiền' : note,
            linkedEnvelopeId: _selectedEnvelopeId,
            idempotencyKey: _idempotencyKey,
          );
          break;
        default:
          throw StateError('Loại giao dịch không hợp lệ.');
      }

      final controller = ref.read(transactionControllerProvider.notifier);
      if (widget.editingItem != null) {
        await controller.editTransaction(
          originalTxId: widget.editingItem!.id,
          newCommand: command,
        );
      } else {
        await controller.postTransaction(command);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }
}
