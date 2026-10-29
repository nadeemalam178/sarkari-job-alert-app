import 'package:flutter/material.dart';

/// App Theme & Refined Sovereign Aubergine-Iris Palette:
/// #100E17 - Deep Obsidian Plum Night (Darkest)
/// #1E1A27 - Frosted Charcoal Iris Surface
/// #2C2538 - Slate Heather Surface High
/// #7A6F87 - Muted Heather Slate
/// #9D6EFA - Vibrant Luminous Royal Iris / Violet (Hero Brand Accent)
/// #A78BFA - Radiant Electric Lavender
/// #F7F5FA - Crisp Pearl Lavender Mist (Lightest)
class AppTheme {
  static const Color darkBg = Color(0xFF100E17);
  static const Color darkSurface = Color(0xFF1E1A27);
  static const Color darkElevated = Color(0xFF2C2538);
  static const Color slateMauve = Color(0xFF7A6F87);
  static const Color lilacHeather = Color(0xFFA78BFA);
  static const Color royalIris = Color(0xFF9D6EFA);
  static const Color lightBg = Color(0xFFF7F5FA);
  static const Color lightElevatedBg = Color(0xFFEFEBF5);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: royalIris,
        secondary: lilacHeather,
        surface: darkSurface,
        onSurface: Color(0xFFFDFCFE),
        outline: Color(0xFF382F47),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFFFDFCFE),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF7C3AED),
        secondary: Color(0xFF6D28D9),
        surface: Colors.white,
        onSurface: Color(0xFF16131D),
        outline: Color(0xFFE4DFEA),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF16131D),
      ),
    );
  }
}

class AppPalette {
  final bool isDark;
  final Color background;
  final Color surfaceGlass;
  final Color surfaceGlassHigh;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentPrimary;
  final Color accentPlum;
  final Color accentLilac;
  final Color accentGreen;
  final Color accentAmber;
  final Color accentRed;
  final BoxShadow shadow;

  const AppPalette({
    required this.isDark,
    required this.background,
    required this.surfaceGlass,
    required this.surfaceGlassHigh,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentPrimary,
    required this.accentPlum,
    required this.accentLilac,
    required this.accentGreen,
    required this.accentAmber,
    required this.accentRed,
    required this.shadow,
  });

  // Backward-compatibility getters
  Color get accentBlue => accentPrimary;
  Color get accentCyan => accentLilac;

  factory AppPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const AppPalette(
        isDark: true,
        background: Color(0xFF100E17),
        surfaceGlass: Color(0xF01E1A27),
        surfaceGlassHigh: Color(0xFF2C2538),
        cardBorder: Color(0x38A78BFA),
        textPrimary: Color(0xFFFDFCFE),
        textSecondary: Color(0xFFA39AA8),
        accentPrimary: Color(0xFF9D6EFA), // Vibrant Electric Iris
        accentPlum: Color(0xFFC4B5FD),
        accentLilac: Color(0xFFA78BFA),
        accentGreen: Color(0xFF10B981),
        accentAmber: Color(0xFFFBBF24),
        accentRed: Color(0xFFF43F5E),
        shadow: BoxShadow(
          color: Color(0x73000000),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      );
    } else {
      return const AppPalette(
        isDark: false,
        background: Color(0xFFF7F5FA),
        surfaceGlass: Color(0xF8FFFFFF),
        surfaceGlassHigh: Color(0xFFFFFFFF),
        cardBorder: Color(0xFFE5DFEC),
        textPrimary: Color(0xFF16131D),
        textSecondary: Color(0xFF6E6678),
        accentPrimary: Color(0xFF7C3AED), // Commanding Royal Violet
        accentPlum: Color(0xFF5B21B6),
        accentLilac: Color(0xFF6D28D9),
        accentGreen: Color(0xFF059669),
        accentAmber: Color(0xFFD97706),
        accentRed: Color(0xFFE11D48),
        shadow: BoxShadow(
          color: Color(0x14292531),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      );
    }
  }

  /// Glassmorphic container decoration
  BoxDecoration glassDecoration({
    double radius = 24,
    Color? customBorder,
    bool glow = false,
  }) {
    return BoxDecoration(
      color: surfaceGlass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: customBorder ?? cardBorder,
        width: isDark ? 1.2 : 1.0,
      ),
      boxShadow: [
        shadow,
        if (glow && isDark)
          BoxShadow(
            color: accentPrimary.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 1,
          ),
      ],
    );
  }
}
