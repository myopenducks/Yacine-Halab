import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Inter';

  static TextTheme _buildTextTheme(Color onSurface) {
    const base = TextStyle(
      fontFamily: fontFamily,
      decoration: TextDecoration.none,
      textBaseline: TextBaseline.alphabetic,
    );
    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
        color: onSurface,
      ),
      displayMedium: base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
        color: onSurface,
      ),
      displaySmall: base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.2,
        color: onSurface,
      ),
      headlineLarge: base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
        color: onSurface,
      ),
      headlineMedium: base.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.3,
        color: onSurface,
      ),
      headlineSmall: base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      titleLarge: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.35,
        color: onSurface,
      ),
      titleMedium: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: onSurface,
      ),
      titleSmall: base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: onSurface,
      ),
      bodyLarge: base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: onSurface,
      ),
      bodyMedium: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: onSurface,
      ),
      bodySmall: base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: onSurface.withValues(alpha: 0.75),
      ),
      labelLarge: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelSmall: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: onSurface.withValues(alpha: 0.75),
      ),
    );
  }

  static ElevatedButtonThemeData _buildPillButton({
    required Color foreground,
    required Color background,
    required Color disabledBackground,
    required Color disabledForeground,
  }) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size.fromHeight(56)),
        textStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
            color: s.contains(WidgetState.disabled)
                ? disabledForeground
                : foreground,
          ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? disabledForeground
              : foreground,
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledBackground;
          if (states.contains(WidgetState.pressed)) {
            return Color.alphaBlend(
              AppColors.dark.withValues(alpha: 0.18),
              background,
            );
          }
          if (states.contains(WidgetState.hovered)) {
            return Color.alphaBlend(
              AppColors.accent.withValues(alpha: 0.22),
              background,
            );
          }
          return background;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButton({
    required Color foreground,
    required Color background,
  }) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: background,
        foregroundColor: foreground,
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedPill({
    required Color foreground,
    required Color border,
  }) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size.fromHeight(56)),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
            color: foreground,
          ),
        ),
        foregroundColor: WidgetStateProperty.all(foreground),
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        side: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed)) {
            return BorderSide(color: border, width: 1.6);
          }
          return BorderSide(color: border, width: 1.2);
        }),
      ),
    );
  }

  static TextButtonThemeData _buildTextButton({required Color foreground}) {
    return TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all(
          TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed)) {
            return foreground.withValues(alpha: 0.7);
          }
          return foreground;
        }),
      ),
    );
  }

  static ChipThemeData _buildChip({
    required Color background,
    required Color selectedBg,
    required Color onBg,
    required Color onSelected,
    required Color border,
  }) {
    return ChipThemeData(
      backgroundColor: background,
      selectedColor: selectedBg,
      labelStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onBg,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: onSelected,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      side: BorderSide(color: border, width: 1.2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      iconTheme: IconThemeData(color: onBg, size: 16),
    );
  }

  static NavigationBarThemeData _buildNavBar({
    required Color background,
    required Color indicator,
    required Color selected,
    required Color unselected,
  }) {
    return NavigationBarThemeData(
      backgroundColor: background,
      elevation: 0,
      height: 72,
      indicatorColor: indicator,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final isSelected = s.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? selected : unselected,
          letterSpacing: 0.1,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final isSelected = s.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected ? selected : unselected,
          size: 24,
        );
      }),
    );
  }

  static InputDecorationTheme _buildInput({
    required Color fill,
    required Color border,
    required Color focusedBorder,
    required Color hint,
    required Color label,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: TextStyle(
        fontFamily: fontFamily,
        color: hint,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: TextStyle(
        fontFamily: fontFamily,
        color: label,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: focusedBorder, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
      ),
    );
  }

  static AppBarTheme _buildAppBar({
    required Color background,
    required Color foreground,
    required SystemUiOverlayStyle systemOverlayStyle,
  }) {
    return AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: systemOverlayStyle,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: foreground,
      ),
      iconTheme: IconThemeData(color: foreground, size: 24),
    );
  }

  static ThemeData light() {
    const onSurface = AppColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surfaceLight,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onDark,
        surface: AppColors.card,
        onSurface: onSurface,
        surfaceContainerHighest: AppColors.gray100,
        error: AppColors.danger,
        onError: AppColors.onPrimary,
      ),
      textTheme: _buildTextTheme(onSurface),
      primaryTextTheme: _buildTextTheme(onSurface),
      appBarTheme: _buildAppBar(
        background: AppColors.surfaceLight,
        foreground: onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: _buildPillButton(
        foreground: AppColors.onPrimary,
        background: AppColors.primary,
        disabledBackground: AppColors.gray200,
        disabledForeground: AppColors.textMuted,
      ),
      filledButtonTheme: _buildFilledButton(
        foreground: AppColors.onPrimary,
        background: AppColors.primary,
      ),
      outlinedButtonTheme: _buildOutlinedPill(
        foreground: AppColors.secondary,
        border: AppColors.border,
      ),
      textButtonTheme: _buildTextButton(foreground: AppColors.primary),
      chipTheme: _buildChip(
        background: AppColors.card,
        selectedBg: AppColors.primary,
        onBg: AppColors.secondary,
        onSelected: AppColors.onPrimary,
        border: AppColors.border,
      ),
      navigationBarTheme: _buildNavBar(
        background: AppColors.card,
        indicator: AppColors.primary,
        selected: AppColors.onPrimary,
        unselected: AppColors.textMuted,
      ),
      inputDecorationTheme: _buildInput(
        fill: AppColors.inputFill,
        border: AppColors.border,
        focusedBorder: AppColors.primary,
        hint: AppColors.textMuted,
        label: AppColors.secondary,
      ),
      cardColor: AppColors.card,
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.border, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: onSurface, size: 26),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.onDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      fontFamily: fontFamily,
    );
  }

  static ThemeData dark() {
    const onSurface = AppColors.onDark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.accent,
        onPrimary: AppColors.dark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onDark,
        surface: AppColors.cardDark,
        onSurface: onSurface,
        surfaceContainerHighest: AppColors.gray700,
        error: AppColors.danger,
        onError: AppColors.onDark,
      ),
      textTheme: _buildTextTheme(onSurface),
      primaryTextTheme: _buildTextTheme(onSurface),
      appBarTheme: _buildAppBar(
        background: AppColors.dark,
        foreground: onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: _buildPillButton(
        foreground: AppColors.dark,
        background: AppColors.accent,
        disabledBackground: AppColors.gray700,
        disabledForeground: AppColors.textMutedDark,
      ),
      filledButtonTheme: _buildFilledButton(
        foreground: AppColors.dark,
        background: AppColors.accent,
      ),
      outlinedButtonTheme: _buildOutlinedPill(
        foreground: AppColors.onDark,
        border: AppColors.borderDark,
      ),
      textButtonTheme: _buildTextButton(foreground: AppColors.accent),
      chipTheme: _buildChip(
        background: AppColors.cardDark,
        selectedBg: AppColors.accent,
        onBg: AppColors.onDark,
        onSelected: AppColors.dark,
        border: AppColors.borderDark,
      ),
      navigationBarTheme: _buildNavBar(
        background: AppColors.cardDark,
        indicator: AppColors.accent,
        selected: AppColors.dark,
        unselected: AppColors.textMutedDark,
      ),
      inputDecorationTheme: _buildInput(
        fill: AppColors.inputFillDark,
        border: AppColors.borderDark,
        focusedBorder: AppColors.accent,
        hint: AppColors.textMutedDark,
        label: AppColors.onDark,
      ),
      cardColor: AppColors.cardDark,
      cardTheme: const CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.borderDark, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.dividerDark,
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: onSurface, size: 26),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      splashColor: AppColors.accent.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.accent,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.dark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      fontFamily: fontFamily,
    );
  }
}
