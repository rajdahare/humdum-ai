import 'package:flutter/material.dart';

class AppTheme {
  // Modern, vibrant color palette
  static const Color primarySeed = Color(0xFF6366F1); // Indigo-500
  static const Color secondarySeed = Color(0xFFEC4899); // Pink-500

  static final ThemeData lightTheme = _base(brightness: Brightness.light);
  static final ThemeData darkTheme = _base(brightness: Brightness.dark);

  static ThemeData _base({required Brightness brightness}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      secondary: secondarySeed,
      brightness: brightness,
    ).copyWith(
      // Add custom colors for better visual appeal
      tertiary: brightness == Brightness.dark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
    );
    final textTheme = Typography.material2021(platform: TargetPlatform.android)
        .black
        .apply(
          bodyColor: brightness == Brightness.dark ? Colors.white : Colors.black87,
          displayColor: brightness == Brightness.dark ? Colors.white : Colors.black87,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
      ),
    );
  }
}


