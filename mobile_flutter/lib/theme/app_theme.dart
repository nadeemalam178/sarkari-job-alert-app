import 'package:flutter/material.dart';

/// App Theme & Color Palette based on custom slate-plum / lavender palette:
/// #17151C - Deep Obsidian Plum Night (Darkest)
/// #292531 - Charcoal Violet Surface
/// #45404F - Slate Heather Plum
/// #716879 - Muted Heather Mauve
/// #AAA2B3 - Soft Lilac Heather
/// #E2DDE7 - Luminous Lavender Mist (Lightest)
class AppTheme {
  static const Color darkBg = Color(0xFF17151C);
  static const Color darkSurface = Color(0xFF292531);
  static const Color darkElevated = Color(0xFF45404F);
  static const Color slateMauve = Color(0xFF716879);
  static const Color lilacHeather = Color(0xFFAAA2B3);
  static const Color lightBg = Color(0xFFE2DDE7);
  static const Color lightElevatedBg = Color(0xFFF1EDF5);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: lilacHeather,
        secondary: slateMauve,
        surface: darkSurface,
        onSurface: Color(0xFFF3EEF8),
        outline: Color(0xFF45404F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFFF3EEF8),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightElevatedBg,
      colorScheme: const ColorScheme.light(
        primary: darkSurface,
        secondary: slateMauve,
        surface: Colors.white,
        onSurface: darkBg,
        outline: lilacHeather,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkBg,
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
        background: Color(0xFF17151C), // #17151C
        surfaceGlass: Color(0xEE292531), // #292531 with frosted opacity
        surfaceGlassHigh: Color(0xFF45404F), // #45404F
        cardBorder: Color(0x40AAA2B3), // #AAA2B3 subtle border
        textPrimary: Color(0xFFF3EEF8),
        textSecondary: Color(0xFFAAA2B3), // #AAA2B3
        accentPrimary: Color(0xFFAAA2B3), // #AAA2B3
        accentPlum: Color(0xFF716879), // #716879
        accentLilac: Color(0xFFAAA2B3), // #AAA2B3
        accentGreen: Color(0xFF10B981),
        accentAmber: Color(0xFFF59E0B),
        accentRed: Color(0xFFEF4444),
        shadow: BoxShadow(
          color: Color(0x66000000),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      );
    } else {
      return const AppPalette(
        isDark: false,
        background: Color(0xFFE2DDE7), // #E2DDE7
        surfaceGlass: Color(0xF4FFFFFF), // crisp frosted white
        surfaceGlassHigh: Color(0xFFFFFFFF),
        cardBorder: Color(0xFFD3CBD8), // soft plum border
        textPrimary: Color(0xFF17151C), // #17151C
        textSecondary: Color(0xFF716879), // #716879
        accentPrimary: Color(0xFF292531), // #292531
        accentPlum: Color(0xFF45404F), // #45404F
        accentLilac: Color(0xFF716879),
        accentGreen: Color(0xFF059669),
        accentAmber: Color(0xFFD97706),
        accentRed: Color(0xFFDC2626),
        shadow: BoxShadow(
          color: Color(0x1A292531),
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
            color: const Color(0xFFAAA2B3).withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 1,
          ),
      ],
    );
  }
}
