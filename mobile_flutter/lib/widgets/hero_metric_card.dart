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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: palette.glassDecoration(radius: 22, glow: true),
      child: Row(
        children: [
          // Left: Electric circular icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFBBF24),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),

          // Center: Main metric and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$matchedCount Matched Vacancies',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Out of $totalJobs active govt vacancies today',
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
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.isDark ? const Color(0xFF1E2D44) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: palette.isDark ? Colors.white70 : const Color(0xFF1E293B),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
