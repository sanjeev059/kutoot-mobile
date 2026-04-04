import 'package:flutter/material.dart';

/// Kutoot design system tokens (DESIGN.md)
class AppTheme {
  // Core brand colors (from Stitch design tokens)
  static const Color primary = Color(0xFF8A002B);
  static const Color primaryDark = Color(0xFF5A001C);
  static const Color primaryContainer = Color(0xFFAE1E3F);
  static const Color secondary = Color(0xFFA04100);
  static const Color secondaryContainer = Color(0xFFFF7A2E);
  static const Color tertiary = Color(0xFF725C00);
  static const Color tertiaryContainer = Color(0xFFCDA700);
  static const Color neutral = Color(0xFF221A14);

  // Light surface architecture (warm off-whites from Stitch)
  static const Color background = Color(0xFFFFF8F5);
  static const Color surface = Color(0xFFFFF8F5);
  static const Color surfaceBright = Color(0xFFFFF8F5);
  static const Color surfaceDim = Color(0xFFE7D7CD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF1E8);
  static const Color surfaceContainer = Color(0xFFFBEBE0);
  static const Color surfaceContainerHigh = Color(0xFFF5E5DB);
  static const Color surfaceContainerHighest = Color(0xFFEFE0D5);

  // Text
  static const Color textPrimary = neutral;
  static const Color textSecondary = Color(0xFF594042);

  // Borders
  static const Color outline = Color(0xFF8D7072);
  static const Color outlineVariant = Color(0xFFE1BEC0);

  // Assets
  static const String logoAsset = 'assets/images/k_logo.png';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        onSurface: neutral,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceContainerLowest,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Zomato-style dark: true black canvas, charcoal surfaces, muted grey labels.
  static ThemeData get darkTheme {
    const canvas = Color(0xFF000000);
    const surfaceCard = Color(0xFF1C1C1C);
    const surfaceElevated = Color(0xFF242424);
    const onSurfaceMuted = Color(0xFF8E8E93);

    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: const Color(0xFF1DB954),
    );
    final scheme = base.copyWith(
      surface: surfaceCard,
      onSurface: Colors.white,
      onSurfaceVariant: onSurfaceMuted,
      outline: const Color(0xFF3A3A3C),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2C2C2E)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        hintStyle: const TextStyle(color: onSurfaceMuted),
        labelStyle: const TextStyle(color: onSurfaceMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF1DB954),
        unselectedItemColor: onSurfaceMuted,
        backgroundColor: surfaceCard,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

/// Semantic colors for screens that still use hard-coded light fills.
extension KutootThemeExt on BuildContext {
  bool get isKutootDark => Theme.of(this).brightness == Brightness.dark;

  Color get kutootPageBg =>
      isKutootDark ? const Color(0xFF000000) : const Color(0xFFF8F8F8);

  Color get kutootCardSurface => isKutootDark ? const Color(0xFF1C1C1C) : Colors.white;

  Color get kutootSearchFill =>
      isKutootDark ? const Color(0xFF2C2C2E) : Colors.white;

  Color get kutootMutedText =>
      isKutootDark ? const Color(0xFF8E8E93) : const Color(0xFF9A9A9A);

  Color get kutootOnSurface => isKutootDark ? Colors.white : AppTheme.textPrimary;
}
