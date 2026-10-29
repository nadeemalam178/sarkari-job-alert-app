import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeroMetricCard extends StatelessWidget {
  final int totalJobs;
  final int matchedCount;
  final VoidCallback onTap;

  const HeroMetricCard({
    super.key,
    required this.totalJobs,
    required this.matchedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 20, glow: true),
      child: Row(
        children: [
          // Left: Ambient circular icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.isDark
                    ? const [Color(0xFF45404F), Color(0xFF292531)]
                    : const [Color(0xFF716879), Color(0xFF45404F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: palette.cardBorder, width: 1),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFBBF24),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Center: Main metric and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$matchedCount Matched Vacancies',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'From $totalJobs live postings across 3 portals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Right: Action arrow button
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.surfaceGlassHigh,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: palette.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
