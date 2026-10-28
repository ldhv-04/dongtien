import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Material 3 Two-Tone Progress Bar with normal (Verdant),
/// warning (Marigold >= 80%), and exceeded / overflow (Ruby > 100%) states.
class ProgressBar extends StatelessWidget {
  /// Spending ratio or progress ratio (0.0 to 1.0+).
  final double ratio;

  /// Warning threshold percentage ratio (default 0.8 for 80%).
  final double warningThreshold;

  /// Bar height (default 8.0dp).
  final double height;

  /// Optional track color.
  final Color? trackColor;

  const ProgressBar({
    super.key,
    required this.ratio,
    this.warningThreshold = 0.8,
    this.height = 8.0,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedFill = ratio.clamp(0.0, 1.0);
    final bool isExceeded = ratio > 1.0;
    final bool isWarning = ratio >= warningThreshold && !isExceeded;

    Color fillColor;
    if (isExceeded) {
      fillColor = AppColors.fillAccentRubyPrimary;
    } else if (isWarning) {
      fillColor = AppColors.fillAccentMarigoldPrimary;
    } else {
      fillColor = AppColors.fillAccentVerdantPrimary;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double fillWidth = totalWidth * clampedFill;

        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            width: totalWidth,
            color: trackColor ?? AppColors.surfaceTertiary,
            child: Stack(
              children: [
                // Base progress fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: fillWidth,
                  height: height,
                  color: fillColor,
                ),
                // If exceeded, show distinct overflow indicator on the end
                if (isExceeded)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 4.0,
                      height: height,
                      color: AppColors.ruby14,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
