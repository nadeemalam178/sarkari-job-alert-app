import 'package:flutter/material.dart';

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
    {'id': 'FreeJobAlert', 'label': 'FreeJobAlert'},
    {'id': 'RojgarResult', 'label': 'RojgarResult'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: portals.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final portal = portals[index];
          final isSelected = selectedSource == portal['id'];
          return ChoiceChip(
            label: Text(portal['label']!),
            selected: isSelected,
            onSelected: (_) => onSourceSelected(portal['id']!),
            selectedColor: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFF131D2E),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF1E2D44),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
