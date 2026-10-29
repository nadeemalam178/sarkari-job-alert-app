import 'package:flutter/material.dart';

import '../models/job_post.dart';
import '../theme/app_theme.dart';
import 'job_details_sheet.dart';

class JobCard extends StatelessWidget {
  final JobPost job;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const JobCard({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onToggleSave,
  });

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
    final isSarkariResult = job.source.toLowerCase().contains('sarkari');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: palette.glassDecoration(
        radius: 20,
        customBorder: isSaved ? palette.accentBlue : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Portal Source & Last Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSarkariResult
                            ? const Color(0xFFF59E0B).withValues(alpha: palette.isDark ? 0.25 : 0.15)
                            : (palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSarkariResult
                              ? const Color(0xFFF59E0B)
                              : palette.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSarkariResult) ...[
                            const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            job.source,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: isSarkariResult
                                  ? const Color(0xFFD97706)
                                  : palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (job.totalPosts.isNotEmpty && job.totalPosts != 'Various Posts') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.accentBlue.withValues(alpha: palette.isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          job.totalPosts,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: palette.accentBlue,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 13,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.lastDate,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Organization
                if (job.org.isNotEmpty) ...[
                  Text(
                    job.org.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.accentCyan,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                ],

                // Post Title
                Text(
                  job.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Eligibility snippet
                if (job.eligibilitySnippet.isNotEmpty) ...[
                  Text(
                    job.eligibilitySnippet,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                ],

                // Qualifications tags
                if (job.qualificationsFound.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: job.qualificationsFound.take(4).map((q) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: palette.isDark ? const Color(0xFF1E2D44) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: palette.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          q,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                Divider(height: 1, color: palette.cardBorder),
                const SizedBox(height: 10),

                // Bottom Action Bar
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onToggleSave,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: isSaved ? palette.accentBlue : palette.cardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 15,
                        color: isSaved ? palette.accentBlue : palette.textSecondary,
                      ),
                      label: Text(
                        isSaved ? 'Saved' : 'Bookmark',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isSaved ? palette.accentBlue : palette.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _openDetails(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: const Text(
                        'Details & Apply',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
