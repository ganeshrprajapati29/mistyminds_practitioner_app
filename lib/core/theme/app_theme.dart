import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// The single light theme. Material defaults are overridden wherever they
/// would leak blue, heavy elevation or square corners into the brand.
abstract final class AppTheme {
  static ThemeData get light {
    final TextTheme text = AppTypography.build();

    const ColorScheme scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.mint,
      onSecondary: Colors.white,
      tertiary: AppColors.success,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: AppColors.surfaceMuted,
      surfaceContainerHigh: AppColors.surface,
      surfaceContainerHighest: AppColors.lavender,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    final OutlineInputBorder field = OutlineInputBorder(
      borderRadius: AppSizes.brMd,
      borderSide: const BorderSide(color: AppColors.border, width: 1.2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.headingMedium,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.lg,
        ),
        hintStyle: AppTypography.body(15, color: AppColors.textTertiary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: field.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: field.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        errorStyle: AppTypography.body(12.5, color: AppColors.error),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.body(14.5, weight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.headingMedium,
        contentTextStyle: AppTypography.bodyMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppSizes.brCard),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDeep,
        contentTextStyle: AppTypography.body(
          14.5,
          weight: FontWeight.w500,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppSizes.brMd),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lavenderStrong,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.textTertiary, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        dialBackgroundColor: AppColors.lavender,
        hourMinuteColor: AppColors.lavender,
        dayPeriodColor: AppColors.lavenderStrong,
        shape: const RoundedRectangleBorder(borderRadius: AppSizes.brCard),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
