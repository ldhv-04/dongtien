import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// 4x3 Custom Numeric Keypad from wallet.png.
/// Minimum touch target 48x48px (actual 64x56px), emerald/verdant background for action,
/// backspace (<) key, and Done action button.
class CustomKeypad extends StatelessWidget {
  final ValueChanged<int> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onDonePressed;
  final bool isSubmitting;
  final bool? isDoneEnabled;

  const CustomKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onDonePressed,
    this.isSubmitting = false,
    this.isDoneEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp6,
        vertical: AppSpacing.sp4,
      ),
      color: AppColors.surfacePrimary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          AppSpacing.gapH8,
          _buildRow(['4', '5', '6']),
          AppSpacing.gapH8,
          _buildRow(['7', '8', '9']),
          AppSpacing.gapH8,
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      children: digits.map((d) {
        final int val = int.parse(d);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
            child: _KeypadButton(
              semanticId: 'keypad_btn_$d',
              label: d,
              onTap: () {
                HapticFeedback.lightImpact();
                onDigitPressed(val);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    final bool doneActive = !isSubmitting && (isDoneEnabled ?? true);
    return Row(
      children: [
        // Done button
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
            child: _KeypadButton(
              semanticId: 'keypad_btn_done',
              icon: Icons.check,
              label: 'Xong',
              isAction: true,
              isEnabled: doneActive,
              onTap: doneActive
                  ? () {
                      HapticFeedback.mediumImpact();
                      onDonePressed();
                    }
                  : null,
            ),
          ),
        ),
        // 0 Digit
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
            child: _KeypadButton(
              semanticId: 'keypad_btn_0',
              label: '0',
              onTap: () {
                HapticFeedback.lightImpact();
                onDigitPressed(0);
              },
            ),
          ),
        ),
        // Backspace
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
            child: _KeypadButton(
              semanticId: 'keypad_btn_backspace',
              icon: Icons.backspace_outlined,
              isAction: true,
              onTap: () {
                HapticFeedback.lightImpact();
                onBackspacePressed();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String semanticId;
  final String? label;
  final IconData? icon;
  final bool isAction;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _KeypadButton({
    required this.semanticId,
    this.label,
    this.icon,
    this.isAction = false,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticId,
      button: true,
      enabled: isEnabled,
      child: Material(
        color: isAction
            ? (isEnabled
                ? AppColors.surfaceAccentVerdantSecondary
                : AppColors.surfaceSecondary)
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16.0),
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.4,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 56.0,
                minWidth: 64.0,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20.0,
                      color: isAction
                          ? (isEnabled
                              ? AppColors.textAccentVerdantPrimary
                              : AppColors.textTertiary)
                          : AppColors.iconPrimary,
                    ),
                    if (label != null) const SizedBox(width: 4.0),
                  ],
                  if (label != null)
                    Text(
                      label!,
                      style: AppTypography.titleLarge.copyWith(
                        color: isAction
                            ? (isEnabled
                                ? AppColors.textAccentVerdantPrimary
                                : AppColors.textTertiary)
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
