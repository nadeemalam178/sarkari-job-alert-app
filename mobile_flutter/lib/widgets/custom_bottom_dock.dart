import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'motion_spells.dart';

class CustomBottomDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const CustomBottomDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: palette.glassDecoration(
        radius: 34,
        glow: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            icon: Icons.person_pin_rounded,
            label: 'For You',
            isSelected: currentIndex == 0,
            palette: palette,
            onTap: () => onTabSelected(0),
          ),
          _buildItem(
            icon: Icons.explore_rounded,
            label: 'Explore',
            isSelected: currentIndex == 1,
            palette: palette,
            onTap: () => onTabSelected(1),
          ),
          _buildItem(
            icon: Icons.bookmark_rounded,
            label: 'Saved',
            isSelected: currentIndex == 2,
            palette: palette,
            onTap: () => onTabSelected(2),
          ),
          _buildItem(
            icon: Icons.notifications_rounded,
            label: 'Alerts',
            isSelected: currentIndex == 3,
            palette: palette,
            onTap: () => onTabSelected(3),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required AppPalette palette,
    required VoidCallback onTap,
  }) {
    final activeColor = palette.accentPrimary;
    final inactiveColor = palette.textSecondary;

    return TactilePress(
      scaleFactor: 0.92,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (palette.isDark
                  ? activeColor.withValues(alpha: 0.20)
                  : activeColor.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: palette.isDark ? 0.60 : 0.40)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: palette.isDark ? 0.35 : 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSelected ? 22 : 20,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: isSelected ? -0.1 : 0.0,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 3),
              Container(
                width: 12,
                height: 2.5,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.8),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
