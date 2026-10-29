import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'motion_spells.dart';

class PortalFilterBar extends StatelessWidget {
  final String selectedSource;
  final ValueChanged<String> onSourceSelected;

  const PortalFilterBar({
    super.key,
    required this.selectedSource,
    required this.onSourceSelected,
  });

  static const List<Map<String, String>> portals = [
    {'id': 'All', 'label': 'All Portals'},
    {'id': 'SarkariResult', 'label': 'SarkariResult ★'},
    {'id': 'GovtJobsAlert', 'label': 'GovtJobsAlert'},
    {'id': 'IndGovtJobs', 'label': 'IndGovtJobs'},
    {'id': 'SarkariExam', 'label': 'SarkariExam'},
    {'id': 'FreeJobAlert', 'label': 'FreeJobAlert'},
    {'id': 'RojgarResult', 'label': 'RojgarResult'},
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: portals.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final portal = portals[index];
          final isSelected = selectedSource.toLowerCase() == portal['id']!.toLowerCase();
          return TactilePress(
            scaleFactor: 0.94,
            onTap: () => onSourceSelected(portal['id']!),
            child: ChoiceChip(
              label: Text(portal['label']!),
              selected: isSelected,
              onSelected: (_) => onSourceSelected(portal['id']!),
              selectedColor: palette.isDark ? const Color(0xFFAAA2B3) : const Color(0xFF292531),
              backgroundColor: palette.isDark ? const Color(0xFF292531) : Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (palette.isDark ? const Color(0xFF17151C) : Colors.white)
                    : palette.textSecondary,
              ),
              side: BorderSide(
                color: isSelected
                    ? (palette.isDark ? const Color(0xFFAAA2B3) : const Color(0xFF292531))
                    : (palette.isDark ? const Color(0xFF45404F) : const Color(0xFFD3CBD8)),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}
