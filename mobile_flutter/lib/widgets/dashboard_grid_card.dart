import 'package:flutter/material.dart';

import '../models/job_post.dart';
import '../theme/app_theme.dart';
import 'job_details_sheet.dart';

class DashboardGridCard extends StatelessWidget {
  final JobPost job;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const DashboardGridCard({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onToggleSave,
  });

  IconData _getIconForJob() {
    final t = job.title.toLowerCase();
    final o = job.org.toLowerCase();
    if (t.contains('teacher') ||
        t.contains('tgt') ||
        t.contains('educator') ||
        t.contains('b.ed')) {
      return Icons.school_outlined;
    }
    if (t.contains('railway') ||
        o.contains('railway') ||
        t.contains('ntpc') ||
        t.contains('rrb')) {
      return Icons.train_outlined;
    }
    if (t.contains('police') ||
        t.contains('constable') ||
        t.contains('defence') ||
        t.contains('army')) {
      return Icons.shield_outlined;
    }
    if (t.contains('lic') || t.contains('bank') || t.contains('finance')) {
      return Icons.account_balance_outlined;
    }
    if (t.contains('science') ||
        t.contains('scientist') ||
        t.contains('lab') ||
        t.contains('b.sc')) {
      return Icons.biotech_outlined;
    }
    return Icons.work_outline_rounded;
  }

  String _getHighlightMetric() {
    if (job.totalPosts.isNotEmpty && job.totalPosts != 'Various Posts') {
      return job.totalPosts
          .replaceAll(' Posts', '')
          .replaceAll(' Vacancies', '');
    }
    final title = job.title;
    final postMatch = RegExp(
      r'(\d+[\d,]*)\s*Post',
      caseSensitive: false,
    ).firstMatch(title);
    if (postMatch != null) {
      return '${postMatch.group(1)}';
    }
    if (job.lastDate.isNotEmpty && job.lastDate != 'Check Notification') {
      return job.lastDate.replaceAll('/2026', '');
    }
    return 'Active';
  }

  void _openDetails(BuildContext context) {
    JobDetailsSheet.show(
      context,
      job: job,
      isSaved: isSaved,
      onToggleSave: onToggleSave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: palette.glassDecoration(
          radius: 18,
          customBorder: isSaved ? palette.accentPrimary : null,
          glow: isSaved,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Category Icon & Large Metric
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.surfaceGlassHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.cardBorder, width: 0.8),
                  ),
                  child: Icon(
                    _getIconForJob(),
                    color: palette.textPrimary,
                    size: 18,
                  ),
                ),
                Text(
                  _getHighlightMetric(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),

            // Middle: Organization & Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  job.org.isNotEmpty ? job.org : job.source,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: palette.accentPlum,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  job.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // Bottom: Last Date & Bookmark Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 11,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      job.lastDate,
                      style: TextStyle(
                        fontSize: 10,
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Compact tactile switch
                Transform.scale(
                  scale: 0.65,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: isSaved,
                    activeThumbColor: Colors.white,
                    activeTrackColor: palette.isDark
                        ? const Color(0xFF45404F)
                        : const Color(0xFF292531),
                    inactiveThumbColor: palette.textSecondary,
                    inactiveTrackColor: palette.surfaceGlassHigh,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (_) => onToggleSave(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
