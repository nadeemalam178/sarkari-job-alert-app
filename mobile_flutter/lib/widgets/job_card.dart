import 'package:flutter/material.dart';

import '../models/job_post.dart';
import '../theme/app_theme.dart';
import 'job_details_sheet.dart';
import 'motion_spells.dart';

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

  bool get _isUrgent {
    final lower = job.lastDate.toLowerCase();
    return lower.contains('today') ||
        lower.contains('extend') ||
        lower.contains('29 oct') ||
        lower.contains('30 oct') ||
        lower.contains('31 oct') ||
        lower.contains('01 nov');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isSarkariResult = job.source.toLowerCase().contains('sarkari');

    return TactilePress(
      onTap: () => _openDetails(context),
      scaleFactor: 0.975,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: palette.glassDecoration(
          radius: 18,
          customBorder: isSaved ? palette.accentPrimary : null,
        ),
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
                      if (_isUrgent) ...[
                        const PulsingBadgeDot(size: 7, color: Color(0xFFEF4444)),
                        const SizedBox(width: 5),
                      ] else ...[
                        const Icon(
                          Icons.event_outlined,
                          size: 13,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 3),
                      ],
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

              // Bottom Action Bar with FavoriteBurst
              Row(
                children: [
                  FavoriteBurst(
                    isSaved: isSaved,
                    onToggle: onToggleSave,
                    activeColor: palette.accentPrimary,
                    inactiveColor: palette.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSaved ? 'Saved to Vault' : 'Save Vacancy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSaved ? palette.accentPrimary : palette.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TactilePress(
                    onTap: () => _openDetails(context),
                    scaleFactor: 0.94,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.visibility_outlined, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
