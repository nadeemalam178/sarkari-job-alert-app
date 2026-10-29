import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterAction;
  final bool isSyncing;

  const CustomBottomDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterAction,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      height: 68,
      decoration: palette.glassDecoration(
        radius: 34,
        glow: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Tab 0: Home (Dashboard)
          _buildItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: currentIndex == 0,
            palette: palette,
            onTap: () => onTabSelected(0),
          ),

          // Tab 1: Explore (Discovery & Portals)
          _buildItem(
            icon: Icons.explore_rounded,
            label: 'Explore',
            isSelected: currentIndex == 1,
            palette: palette,
            onTap: () => onTabSelected(1),
          ),

          // Center Elevated Floating Action: Live Vacancy Sync
          GestureDetector(
            onTap: onCenterAction,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isSyncing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.sync_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
            ),
          ),

          // Tab 2: Saved / Bookmarks
          _buildItem(
            icon: Icons.bookmark_rounded,
            label: 'Saved',
            isSelected: currentIndex == 2,
            palette: palette,
            onTap: () => onTabSelected(2),
          ),

          // Tab 3: Official Alerts & Notices
          _buildItem(
            icon: Icons.notifications_active_rounded,
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
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: Icon(
        icon,
        size: 24,
        color: isSelected ? palette.accentBlue : palette.textSecondary,
      ),
    );
  }
}
