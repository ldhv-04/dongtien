import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 7 Typography Scales for Đồng Tiền matching Untitled-2.png.
/// Every scale MUST include [FontFeature.tabularFigures()] by default to
/// prevent layout jitter when numbers, dates, or currency dynamic updates occur.
class AppTypography {
  AppTypography._();

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  // 1. Large Title / displayLarge (32px / 48px, w500)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    height: 48 / 32,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle largeTitle = displayLarge;

  // 2. Title / titleLarge (24px / 36px, w500)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    height: 36 / 24,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle title = titleLarge;

  // 3. Headline / headlineMedium (20px / 30px, w500)
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    height: 30 / 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle headline = headlineMedium;

  // 4. Body / bodyLarge (16px / 24px, w400)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle body = bodyLarge;

  // 5. Body Medium / bodyMedium (16px / 24px, w500)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );

  // 6. Subheadline / labelMedium (14px / 20px, w400)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle subheadline = labelMedium;

  // 7. Caption / Footnote (12px / 16px, w400)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    fontFeatures: tabularFigures,
  );
  static const TextStyle footnote = caption;

  // Micro Caption (10px / 14px, w400)
  static const TextStyle microCaption = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    fontFeatures: tabularFigures,
  );

  /// Helper to convert styles to Material 3 TextTheme.
  static TextTheme createTextTheme() {
    return const TextTheme(
      displayLarge: displayLarge,
      headlineMedium: headlineMedium,
      titleLarge: titleLarge,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelMedium: labelMedium,
      labelSmall: caption,
    );
  }
}
