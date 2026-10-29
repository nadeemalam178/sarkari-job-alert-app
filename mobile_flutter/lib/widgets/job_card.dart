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
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: palette.glassDecoration(
        radius: 18,
        customBorder: isSaved ? palette.accentPrimary : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(context),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Portal Badge, Vacancy Pill & Last Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isSarkariResult
                            ? const Color(0xFFF59E0B).withValues(alpha: palette.isDark ? 0.22 : 0.12)
                            : palette.surfaceGlassHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSarkariResult
                              ? const Color(0xFFF59E0B)
                              : palette.cardBorder,
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSarkariResult) ...[
                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            job.source,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: palette.surfaceGlassHigh,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: palette.cardBorder, width: 0.8),
                        ),
                        child: Text(
                          job.totalPosts,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 13,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          job.lastDate,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Organization
                if (job.org.isNotEmpty) ...[
                  Text(
                    job.org.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: palette.accentPlum,
                      letterSpacing: 0.4,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),

                // Eligibility snippet
                if (job.eligibilitySnippet.isNotEmpty) ...[
                  Text(
                    job.eligibilitySnippet,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Qualifications tags
                if (job.qualificationsFound.isNotEmpty) ...[
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: job.qualificationsFound.take(4).map((q) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: palette.surfaceGlassHigh,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: palette.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          q,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                Divider(height: 1, color: palette.cardBorder),
                const SizedBox(height: 8),

                // Bottom Action Bar
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onToggleSave,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: isSaved ? palette.accentPrimary : palette.cardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 14,
                        color: isSaved ? palette.accentPrimary : palette.textSecondary,
                      ),
                      label: Text(
                        isSaved ? 'Saved' : 'Bookmark',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSaved ? palette.accentPrimary : palette.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _openDetails(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text(
                        'View Details',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
