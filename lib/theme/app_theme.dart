import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Dark studio" palette: products are the only saturated color on screen,
/// lit like objects on a photo stage. One acid-lime accent for actions.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0B0B0E);
  static const surface = Color(0xFF131317);
  static const surfaceHigh = Color(0xFF1B1B21);
  static const line = Color(0xFF2A2A33);
  static const text = Color(0xFFF3F1EC);
  static const muted = Color(0xFF8F8D97);
  static const accent = Color(0xFFC8FF2E);
  static const danger = Color(0xFFFF6464);
}

TextStyle displayStyle(double size, {Color color = AppColors.text}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -size * 0.045,
      height: 0.95,
      color: color,
    );

TextStyle monoLabel({Color color = AppColors.muted, double size = 11}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.1,
      color: color,
    );

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: Colors.black,
    secondary: AppColors.accent,
    onSecondary: Colors.black,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    surfaceContainerHighest: AppColors.surfaceHigh,
    outline: AppColors.line,
    outlineVariant: AppColors.line,
    error: AppColors.danger,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
  );
  final text = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));

  return base.copyWith(
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.text,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accent,
      side: const BorderSide(color: AppColors.line),
      shape: pill,
      labelStyle: const TextStyle(color: AppColors.text, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.black, fontSize: 13),
      checkmarkColor: Colors.black,
      showCheckmark: false,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.line,
      thumbColor: AppColors.accent,
      overlayColor: Color(0x22C8FF2E),
      valueIndicatorColor: AppColors.accent,
      valueIndicatorTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      trackHeight: 3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
  );
}
