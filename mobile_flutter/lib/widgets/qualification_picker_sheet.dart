import 'package:flutter/material.dart';
import '../models/qualification.dart';

class QualificationPickerSheet extends StatefulWidget {
  final List<Qualification> allQualifications;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onSaved;

  const QualificationPickerSheet({
    super.key,
    required this.allQualifications,
    required this.initialSelected,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Qualification> allQualifications,
    required List<String> initialSelected,
    required ValueChanged<List<String>> onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => QualificationPickerSheet(
        allQualifications: allQualifications,
        initialSelected: initialSelected,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<QualificationPickerSheet> createState() => _QualificationPickerSheetState();
}

class _QualificationPickerSheetState extends State<QualificationPickerSheet> {
  late Set<String> _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allQualifications.where((q) {
      if (_search.isEmpty) return true;
      final term = _search.toLowerCase();
      return q.code.toLowerCase().contains(term) ||
          q.name.toLowerCase().contains(term) ||
          q.category.toLowerCase().contains(term);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title & Done button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Select Your Qualifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onSaved(_selected.toList());
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                onChanged: (val) => setState(() => _search = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search degrees (B.Ed, CTET, Graduate, 12th...)',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // List of qualifications
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isChecked = _selected.contains(item.code);
                  return CheckboxListTile(
                    value: isChecked,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selected.add(item.code);
                        } else {
                          _selected.remove(item.code);
                        }
                      });
                    },
                    activeColor: const Color(0xFF0F172A),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      '${item.category} • Code: ${item.code}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
