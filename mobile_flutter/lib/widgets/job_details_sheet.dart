import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/job_post.dart';
import '../theme/app_theme.dart';

class JobDetailsSheet extends StatelessWidget {
  final JobPost job;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const JobDetailsSheet({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onToggleSave,
  });

  static void show(
    BuildContext context, {
    required JobPost job,
    required bool isSaved,
    required VoidCallback onToggleSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JobDetailsSheet(
        job: job,
        isSaved: isSaved,
        onToggleSave: onToggleSave,
      ),
    );
  }

  Future<void> _launchExternalUrl(BuildContext context, String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external link')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surfaceGlassHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: palette.isDark ? const Color(0x99000000) : const Color(0x220F172A),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border(
              top: BorderSide(color: palette.cardBorder, width: 1.2),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: palette.cardBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    // Top Bar: Source Tag, Close & Bookmark Action
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: palette.accentGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${job.source} Verified',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onToggleSave,
                          icon: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            color: isSaved ? palette.accentAmber : palette.textSecondary,
                            size: 24,
                          ),
                          tooltip: isSaved ? 'Saved in Bookmarks' : 'Save Job',
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: palette.textSecondary, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Organization
                    if (job.org.isNotEmpty) ...[
                      Text(
                        job.org.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: palette.accentCyan,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Job Title
                    Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        letterSpacing: -0.4,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // KEY HIGHLIGHTS CONTAINER (Bento Grid)
                    _buildHighlightsGrid(palette),
                    const SizedBox(height: 16),

                    // IMPORTANT DATES CONTAINER
                    _buildDatesContainer(palette),
                    const SizedBox(height: 16),

                    // QUALIFICATIONS & ELIGIBILITY CONTAINER
                    _buildQualificationsContainer(palette),
                    const SizedBox(height: 16),

                    // RELEVANT LINKS & ACTION CONTAINER
                    _buildRelevantLinksContainer(context, palette),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. Bento Grid: Posts, Age Limit & Fee
  Widget _buildHighlightsGrid(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.people_alt_rounded,
                  iconColor: palette.accentAmber,
                  title: 'Total Vacancies',
                  value: job.totalPosts.isNotEmpty ? job.totalPosts : 'Various Posts',
                  palette: palette,
                ),
              ),
              Container(width: 1, height: 48, color: palette.cardBorder),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.cake_rounded,
                  iconColor: palette.accentCyan,
                  title: 'Age Limit',
                  value: job.ageLimit.isNotEmpty ? job.ageLimit : '18-35+ Yrs',
                  palette: palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: palette.cardBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: palette.accentGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Fee',
                      style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      job.applicationFee.isNotEmpty ? job.applicationFee : 'General/OBC: ₹100 | SC/ST: ₹0',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required AppPalette palette,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: palette.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Application Dates Box: Start & End
  Widget _buildDatesContainer(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 20),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: palette.accentGreen),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Application Start', style: TextStyle(fontSize: 11, color: palette.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      job.startDate.isNotEmpty ? job.startDate : 'Active Now',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: palette.cardBorder),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: palette.accentRed),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last Date to Apply', style: TextStyle(fontSize: 11, color: palette.accentRed)),
                    const SizedBox(height: 2),
                    Text(
                      job.lastDate,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.accentRed),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Qualifications & Eligibility Box
  Widget _buildQualificationsContainer(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, size: 18, color: palette.accentBlue),
              const SizedBox(width: 8),
              Text(
                'Eligibility Criteria',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              if (job.qualificationsFound.isNotEmpty)
                Text(
                  '${job.qualificationsFound.length} degrees recognized',
                  style: TextStyle(fontSize: 11, color: palette.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips
          if (job.qualificationsFound.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.qualificationsFound.map((q) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.isDark ? const Color(0xFF1E2D44) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Text(
                    q,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: palette.accentBlue,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Eligibility snippet description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Text(
              job.eligibilitySnippet.isNotEmpty
                  ? job.eligibilitySnippet
                  : 'Refer to official notification PDF for exhaustive post-wise age relaxation and eligibility norms.',
              style: TextStyle(
                fontSize: 12,
                color: palette.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Relevant Links & Actions Container
  Widget _buildRelevantLinksContainer(BuildContext context, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: palette.glassDecoration(
        radius: 20,
        customBorder: palette.accentBlue.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Important Official Links',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // 1. PRIMARY BUTTON: Apply Online (Direct Link)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: () => _launchExternalUrl(context, job.applyLink.isNotEmpty ? job.applyLink : job.url),
            icon: const Icon(Icons.launch_rounded, size: 18),
            label: const Text(
              'Apply Online (Direct Link)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),

          // 2. SECONDARY BUTTON: Download Official Notification (PDF)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.accentBlue,
              side: BorderSide(color: palette.accentBlue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: palette.surfaceGlass,
            ),
            onPressed: () => _launchExternalUrl(context, job.notificationLink.isNotEmpty ? job.notificationLink : job.url),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Color(0xFFEF4444)),
            label: Text(
              'Download Official Notification (PDF)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.textPrimary),
            ),
          ),

          // 3. TERTIARY BUTTON: Official Department Website
          if (job.officialWebsite.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.textSecondary,
                side: BorderSide(color: palette.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _launchExternalUrl(context, job.officialWebsite),
              icon: const Icon(Icons.language_rounded, size: 16),
              label: Text(
                'Visit Official Department Website',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: palette.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
