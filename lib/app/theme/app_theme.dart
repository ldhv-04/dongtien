import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Consolidated Material 3 ThemeData Specification for Đồng Tiền.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final textTheme = AppTypography.createTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surfaceSecondary,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.fillAccentVerdantPrimary,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.textAccentVerdantSecondary,
        onSecondary: AppColors.textInverse,
        error: AppColors.fillAccentRubyPrimary,
        onError: AppColors.textInverse,
        surface: AppColors.surfacePrimary,
        onSurface: AppColors.textPrimary,
        outline: AppColors.borderSecondary,
        surfaceContainerHighest: AppColors.surfaceTertiary,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
        iconTheme: IconThemeData(color: AppColors.iconPrimary),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: AppColors.borderSecondary, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfacePrimary,
        elevation: 2,
        indicatorColor: AppColors.surfaceAccentVerdantSecondary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textAccentVerdantPrimary,
            );
          }
          return AppTypography.caption.copyWith(color: AppColors.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
                color: AppColors.textAccentVerdantPrimary);
          }
          return const IconThemeData(color: AppColors.iconSecondary);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.fillAccentVerdantPrimary,
        foregroundColor: AppColors.textInverse,
        elevation: 3,
        shape: StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderPrimary,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
