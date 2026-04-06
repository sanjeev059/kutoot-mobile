import 'package:flutter/material.dart';

/// Kutoot design system — aligned with OphoneFoodUI / food-delivery spec:
/// primary #E23744, background #FFFFFF, text #1C1C1C / #696969, secondary ink #000000.
/// [accentWarm] keeps orange accents for promos/chips without breaking layouts.
class AppTheme {
  // Spec tokens
  static const Color primary = Color(0xFFE23744);
  static const Color primaryDark = Color(0xFFC62828);
  static const Color primaryContainer = Color(0xFFFF5252);
  static const Color ink = Color(0xFF000000);
  static const Color backgroundSpec = Color(0xFFFFFFFF);
  static const Color textPrimarySpec = Color(0xFF1C1C1C);
  static const Color textSecondarySpec = Color(0xFF696969);

  /// Warm accent (promos, location highlights) — not in JSON; preserves contrast vs ink.
  static const Color accentWarm = Color(0xFFFF7A2E);

  /// Back-compat alias: legacy code used `secondary` for this orange accent (not spec black).
  static const Color secondary = accentWarm;

  static const Color secondaryContainer = Color(0xFFFFE0CC);
  static const Color tertiary = Color(0xFF725C00);
  static const Color tertiaryContainer = Color(0xFFCDA700);

  /// Primary text (spec)
  static const Color textPrimary = textPrimarySpec;
  static const Color textSecondary = textSecondarySpec;

  /// Legacy surface aliases used across screens (light theme).
  static const Color background = backgroundSpec;
  static const Color surface = backgroundSpec;
  static const Color neutral = textPrimarySpec;
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFAFAFA);
  static const Color surfaceContainer = Color(0xFFF0F0F0);
  static const Color surfaceContainerHigh = Color(0xFFF5F5F5);
  static const Color surfaceContainerHighest = Color(0xFFEEEEEE);

  static const Color outline = Color(0xFFBDBDBD);
  static const Color outlineVariant = Color(0xFFE0E0E0);

  static const String logoAsset = 'assets/images/k_logo.png';

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFDAD8),
      onPrimaryContainer: primaryDark,
      secondary: ink,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF5F5F5),
      onSecondaryContainer: textPrimarySpec,
      tertiary: accentWarm,
      onTertiary: Colors.white,
      tertiaryContainer: secondaryContainer,
      onTertiaryContainer: textPrimarySpec,
      surface: backgroundSpec,
      onSurface: textPrimarySpec,
      onSurfaceVariant: textSecondarySpec,
      surfaceContainerHighest: const Color(0xFFF5F5F5),
      surfaceContainerHigh: const Color(0xFFFAFAFA),
      surfaceContainer: const Color(0xFFF0F0F0),
      outline: outline,
      outlineVariant: outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundSpec,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSpec,
        foregroundColor: textPrimarySpec,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: backgroundSpec,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: textSecondarySpec,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Dark: keep OLED-friendly surfaces; brand primary matches spec red.
  static ThemeData get darkTheme {
    const canvas = Color(0xFF000000);
    const surfaceCard = Color(0xFF1C1C1C);
    const surfaceElevated = Color(0xFF242424);
    const onSurfaceMuted = Color(0xFFAEAEB2);

    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: ink,
    );
    final scheme = base.copyWith(
      onPrimary: Colors.white,
      primaryContainer: primaryDark,
      onPrimaryContainer: Colors.white,
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
          backgroundColor: primary,
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
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceMuted,
        backgroundColor: surfaceCard,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

extension KutootThemeExt on BuildContext {
  bool get isKutootDark => Theme.of(this).brightness == Brightness.dark;

  Color get kutootPageBg =>
      isKutootDark ? const Color(0xFF000000) : AppTheme.backgroundSpec;

  Color get kutootCardSurface =>
      isKutootDark ? const Color(0xFF1C1C1C) : AppTheme.backgroundSpec;

  Color get kutootSearchFill =>
      isKutootDark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F5);

  Color get kutootMutedText => isKutootDark
      ? const Color(0xFFAEAEB2)
      : AppTheme.textSecondarySpec;

  Color get kutootOnSurface =>
      isKutootDark ? Colors.white : AppTheme.textPrimarySpec;

  Color get kutootTopBarBg =>
      isKutootDark ? const Color(0xFF121212) : AppTheme.backgroundSpec;

  Color get kutootHairlineBorder =>
      isKutootDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8);
}
