import 'package:flutter/material.dart';

/// The single source of truth for how the app looks.
///
/// Every screen pulls its colors and text styles from
/// `Theme.of(context)` — nothing in the screens hardcodes a color.
/// Only one theme exists at this checkpoint (no light/dark toggle
/// yet — that's part of the full submission).
class AppTheme {
  static const Color _seed = Color(0xFF2E5AAC); // HomeHub brand blue

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seed);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
