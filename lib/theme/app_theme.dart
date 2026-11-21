import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One set of colors for a theme. "Warm showroom": cream and charcoal like a
/// lit appliance showroom, so the appliances themselves are the most
/// saturated thing on screen, plus one terracotta accent reserved for the
/// buying moments (add to cart, checkout, the primary action).
/// Every text pairing below was checked for WCAG AA contrast.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.line,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.shadow,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color line;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color shadow;

  static const light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF6F0E8), // warm cream
    surface: Color(0xFFFFFBF5),
    surfaceHigh: Color(0xFFEEE4D7),
    line: Color(0xFFDCCFBF),
    text: Color(0xFF26201B), // 14.2:1 on bg
    muted: Color(0xFF6B6157), // 5.3:1 on bg, 4.8:1 on surfaceHigh
    accent: Color(0xFFA44A23), // terracotta, 5.2:1 on bg
    onAccent: Color(0xFFFFFFFF), // >5:1 on accent
    danger: Color(0xFFB3261E),
    shadow: Color(0xFF5A3A22),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF16120F), // warm charcoal
    surface: Color(0xFF1F1915),
    surfaceHigh: Color(0xFF2A231D),
    line: Color(0xFF3B3229),
    text: Color(0xFFF4ECE2), // 15.9:1 on bg
    muted: Color(0xFFA89B8C), // 6.9:1 on bg, 5.7:1 on surfaceHigh
    accent: Color(0xFFE58A5E), // copper, 7.2:1 on bg
    onAccent: Color(0xFF1C120C), // 7.1:1 on accent
    danger: Color(0xFFFF8A80),
    shadow: Color(0xFF000000),
  );
}

/// The active palette's colors, read by every widget.
// shortcut: colors are read statically and a theme switch remounts the app
// (see FacetApp), so screens reset on switch; move to a ThemeExtension if a
// switch ever needs to keep in-progress screens.
class AppColors {
  AppColors._();

  static AppPalette current = AppPalette.dark;

  static Color get bg => current.bg;
  static Color get surface => current.surface;
  static Color get surfaceHigh => current.surfaceHigh;
  static Color get line => current.line;
  static Color get text => current.text;
  static Color get muted => current.muted;
  static Color get accent => current.accent;
  static Color get onAccent => current.onAccent;
  static Color get danger => current.danger;
  static Color get shadow => current.shadow;
  static bool get isDark => current.brightness == Brightness.dark;
}

/// Fraunces: a soft, warm serif that reads as a premium showroom rather than
/// a tech product. Used for headlines, product names and prices.
TextStyle displayStyle(double size, {Color? color}) => GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: -size * 0.02,
      height: 1.0,
      color: color ?? AppColors.text,
    );

/// Small monospace labels styled like the spec plate on a real appliance
/// (category, SKU, totals). This is FACET's recurring identity motif.
TextStyle monoLabel({Color? color, double size = 11}) => GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
      color: color ?? AppColors.muted,
    );

ThemeData buildAppTheme(AppPalette p) {
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    surface: p.surface,
    onSurface: p.text,
    surfaceContainerHighest: p.surfaceHigh,
    outline: p.line,
    outlineVariant: p.line,
    error: p.danger,
    onError: p.brightness == Brightness.dark ? p.bg : Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    splashFactory: InkSparkle.splashFactory,
  );
  // Inter for body copy and form fields: neutral and very legible at the
  // small sizes used for prices, quantities and descriptions.
  final text = GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: p.text, displayColor: p.text);
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: p.text,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        side: BorderSide(color: p.line),
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.accent)),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.accent,
      side: BorderSide(color: p.line),
      shape: pill,
      labelStyle: TextStyle(color: p.text, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: p.onAccent, fontSize: 13),
      checkmarkColor: p.onAccent,
      showCheckmark: false,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.accent,
      inactiveTrackColor: p.line,
      thumbColor: p.accent,
      overlayColor: p.accent.withValues(alpha: 0.13),
      valueIndicatorColor: p.accent,
      valueIndicatorTextStyle: TextStyle(color: p.onAccent, fontWeight: FontWeight.w700),
      trackHeight: 3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      hintStyle: TextStyle(color: p.muted),
      labelStyle: TextStyle(color: p.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.accent, width: 1.6)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.text,
      contentTextStyle: TextStyle(color: p.bg),
      actionTextColor: p.brightness == Brightness.dark ? AppPalette.light.accent : AppPalette.dark.accent,
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surface),
    popupMenuTheme: PopupMenuThemeData(color: p.surface),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dividerTheme: DividerThemeData(color: p.line, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
  );
}
