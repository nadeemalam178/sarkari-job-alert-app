import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
      height: 64,
      decoration: palette.glassDecoration(
        radius: 32,
        glow: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildItem(
            icon: Icons.home_rounded,
            label: 'Home',
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
    final selectedColor = palette.isDark ? const Color(0xFFF3EEF8) : const Color(0xFF17151C);
    final unselectedColor = palette.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
