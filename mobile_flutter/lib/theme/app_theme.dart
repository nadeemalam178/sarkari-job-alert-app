import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF070B14),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2563EB),
        surface: Color(0xFF111C2E),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
  final Color accentBlue;
  final Color accentCyan;
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
    required this.accentBlue,
    required this.accentCyan,
    required this.accentGreen,
    required this.accentAmber,
    required this.accentRed,
    required this.shadow,
  });

  factory AppPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const AppPalette(
        isDark: true,
        background: Color(0xFF070B14),
        surfaceGlass: Color(0xCC111C2E),
        surfaceGlassHigh: Color(0xE61E2D44),
        cardBorder: Color(0x3338BDF8),
        textPrimary: Colors.white,
        textSecondary: Color(0xFF94A3B8),
        accentBlue: Color(0xFF2563EB),
        accentCyan: Color(0xFF38BDF8),
        accentGreen: Color(0xFF10B981),
        accentAmber: Color(0xFFF59E0B),
        accentRed: Color(0xFFEF4444),
        shadow: BoxShadow(
          color: Color(0x4D000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      );
    } else {
      return const AppPalette(
        isDark: false,
        background: Color(0xFFF1F5F9),
        surfaceGlass: Color(0xF2FFFFFF),
        surfaceGlassHigh: Colors.white,
        cardBorder: Color(0xFFCBD5E1),
        textPrimary: Color(0xFF0F172A),
        textSecondary: Color(0xFF475569),
        accentBlue: Color(0xFF2563EB),
        accentCyan: Color(0xFF0284C7),
        accentGreen: Color(0xFF059669),
        accentAmber: Color(0xFFD97706),
        accentRed: Color(0xFFDC2626),
        shadow: BoxShadow(
          color: Color(0x120F172A),
          blurRadius: 14,
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
        color: customBorder ?? (isDark ? cardBorder : cardBorder),
        width: isDark ? 1.2 : 1.0,
      ),
      boxShadow: [
        shadow,
        if (glow && isDark)
          BoxShadow(
            color: accentBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 1,
          ),
      ],
    );
  }
}
