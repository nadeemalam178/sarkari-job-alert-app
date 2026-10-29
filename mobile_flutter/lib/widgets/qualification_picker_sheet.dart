import 'package:flutter/material.dart';
import '../models/qualification.dart';
import '../theme/app_theme.dart';
import 'motion_spells.dart';

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
      backgroundColor: Colors.transparent,
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
  String _highestDegree = 'GRADUATE';
  late Set<String> _additionalSelected;
  String _searchQuery = '';
  int _activeTab = 0; // 0: Highest Degree, 1: Additional Certs

  @override
  void initState() {
    super.initState();
    // Resolve initial selection into highest degree vs additional
    final selected = widget.initialSelected.map((e) => e.toUpperCase().trim()).toList();
    final highestCodes = Qualification.highestDegrees.map((e) => e.code).toSet();

    String? foundHighest;
    final additionals = <String>{};

    for (final s in selected) {
      if (highestCodes.contains(s) && foundHighest == null) {
        foundHighest = s;
      } else {
        additionals.add(s);
      }
    }

    _highestDegree = foundHighest ?? (selected.isNotEmpty ? selected.first : 'GRADUATE');
    _additionalSelected = additionals;
  }

  void _saveAndClose() {
    final result = <String>[_highestDegree, ..._additionalSelected];
    widget.onSaved(result);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final search = _searchQuery.trim().toLowerCase();

    final filteredHighest = Qualification.highestDegrees.where((q) {
      if (search.isEmpty) return true;
      return q.code.toLowerCase().contains(search) || q.name.toLowerCase().contains(search);
    }).toList();

    final filteredAdditional = Qualification.additionalCertificates.where((q) {
      if (search.isEmpty) return true;
      return q.code.toLowerCase().contains(search) || q.name.toLowerCase().contains(search) || q.category.toLowerCase().contains(search);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.isDark ? const Color(0xFF16131D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: palette.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. Title & Done Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Candidate Qualifications',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Highest degree + additional certificates',
                          style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
                        ),
                      ],
                    ),
                    FilledButton(
                      onPressed: _saveAndClose,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accentPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save & Match', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                  ],
                ),
              ),

              // 3. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: palette.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search B.Sc, B.Ed, CTET, ITI, CCC, Typing...',
                    hintStyle: TextStyle(fontSize: 12, color: palette.textSecondary),
                    prefixIcon: Icon(Icons.search, size: 18, color: palette.textSecondary),
                    isDense: true,
                    filled: true,
                    fillColor: palette.surfaceGlassHigh,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: palette.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: palette.cardBorder),
                    ),
                  ),
                ),
              ),

              // 4. Two-Tier Segment Selector Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: palette.surfaceGlassHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Row(
                    children: [
                      _buildTierTab(
                        title: '1. Highest Degree',
                        subtitle: _highestDegree,
                        isActive: _activeTab == 0,
                        palette: palette,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                      _buildTierTab(
                        title: '2. Additional (${_additionalSelected.length})',
                        subtitle: 'B.Ed, CTET, CCC...',
                        isActive: _activeTab == 1,
                        palette: palette,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Scrollable List of Options
              Expanded(
                child: _activeTab == 0
                    ? _buildHighestDegreeList(filteredHighest, palette, scrollController)
                    : _buildAdditionalList(filteredAdditional, palette, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTierTab({
    required String title,
    required String subtitle,
    required bool isActive,
    required AppPalette palette,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? palette.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: palette.accentPrimary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? Colors.white : palette.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white.withValues(alpha: 0.9) : palette.textSecondary.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Single-choice highest regular degree list
  Widget _buildHighestDegreeList(List<Qualification> list, AppPalette palette, ScrollController controller) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final q = list[index];
        final isSelected = _highestDegree == q.code;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TactilePress(
            scaleFactor: 0.97,
            onTap: () {
              setState(() => _highestDegree = q.code);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.accentPrimary.withValues(alpha: palette.isDark ? 0.20 : 0.12)
                    : palette.surfaceGlassHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? palette.accentPrimary : palette.cardBorder,
                  width: isSelected ? 1.5 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? palette.accentPrimary : palette.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.code,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? palette.accentPrimary : palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          q.name,
                          style: TextStyle(fontSize: 11, color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      q.category,
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Multi-choice additional qualifications list
  Widget _buildAdditionalList(List<Qualification> list, AppPalette palette, ScrollController controller) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final q = list[index];
        final isSelected = _additionalSelected.contains(q.code);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TactilePress(
            scaleFactor: 0.97,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _additionalSelected.remove(q.code);
                } else {
                  _additionalSelected.add(q.code);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF10B981).withValues(alpha: palette.isDark ? 0.20 : 0.12)
                    : palette.surfaceGlassHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF10B981) : palette.cardBorder,
                  width: isSelected ? 1.5 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: isSelected ? const Color(0xFF10B981) : palette.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.code,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF10B981) : palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          q.name,
                          style: TextStyle(fontSize: 11, color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      q.category,
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
