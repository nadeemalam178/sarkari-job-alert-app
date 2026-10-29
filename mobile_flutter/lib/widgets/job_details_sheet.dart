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
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external link')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to open link: $e')));
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
            color: palette.isDark ? const Color(0xFF292531) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: palette.isDark
                    ? const Color(0x99000000)
                    : const Color(0x2217151C),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceGlassHigh,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                job.source,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (job.totalPosts.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceGlassHigh,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: Text(
                              job.totalPosts,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          onPressed: onToggleSave,
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved
                                ? palette.accentPrimary
                                : palette.textSecondary,
                            size: 22,
                          ),
                          tooltip: 'Bookmark Vacancy',
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Organization Banner
                    if (job.org.isNotEmpty) ...[
                      Text(
                        job.org.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: palette.accentPlum,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Full Job Title
                    Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Key Timeline & Metric Matrix
                    _buildTimelineCard(palette),
                    const SizedBox(height: 16),

                    // 2. Fees & Age Limit Card
                    _buildFeeAndAgeCard(palette),
                    const SizedBox(height: 16),

                    // 3. Eligibility & Qualifications Section
                    _buildEligibilityCard(palette),
                    const SizedBox(height: 18),

                    // 4. Relevant Action Links Container
                    _buildRelevantLinksContainer(context, palette),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. Timeline Card (Application Begin & Last Date)
  Widget _buildTimelineCard(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Text(
                'Important Recruitment Dates',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricBlock(
                  label: 'Application Start',
                  value: job.startDate.isNotEmpty
                      ? job.startDate
                      : 'Active Now',
                  icon: Icons.play_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                  palette: palette,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBlock(
                  label: 'Last Date to Apply',
                  value: job.lastDate.isNotEmpty
                      ? job.lastDate
                      : 'Check Notification',
                  icon: Icons.alarm_rounded,
                  color: const Color(0xFFEF4444),
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Fee and Age Limit Card
  Widget _buildFeeAndAgeCard(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monetization_on_outlined,
                size: 16,
                color: palette.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Application Fee & Age Limit',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            label: 'Application Fee',
            value: job.applicationFee.isNotEmpty
                ? job.applicationFee
                : 'Refer to official notification PDF',
            icon: Icons.receipt_long_rounded,
            palette: palette,
          ),
          Divider(color: palette.cardBorder, height: 16),
          _buildInfoRow(
            label: 'Age Eligibility',
            value: job.ageLimit.isNotEmpty
                ? job.ageLimit
                : 'As per recruitment rules & relaxations',
            icon: Icons.person_outline_rounded,
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required AppPalette palette,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: palette.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBlock({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required AppPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceGlassHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Eligibility & Qualifications Section
  Widget _buildEligibilityCard(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 16,
                color: palette.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Eligibility Criteria & Qualifications',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Found Qualifications Tags
          if (job.qualificationsFound.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.qualificationsFound.map((q) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceGlassHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Text(
                    q,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Eligibility snippet description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.isDark ? const Color(0xFF17151C) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Text(
              job.eligibilitySnippet.isNotEmpty ? job.eligibilitySnippet : 'Refer to official notification PDF for exhaustive post-wise age relaxation and eligibility norms.',
              style: TextStyle(
                fontSize: 12,
                color: palette.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Relevant Links & Actions Container
  Widget _buildRelevantLinksContainer(
    BuildContext context,
    AppPalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Important Official Links',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // 1. PRIMARY BUTTON: Apply Online (Direct Link)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: palette.isDark
                  ? const Color(0xFF45404F)
                  : const Color(0xFF292531),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => _launchExternalUrl(
              context,
              job.applyLink.isNotEmpty ? job.applyLink : job.url,
            ),
            icon: const Icon(Icons.launch_rounded, size: 16),
            label: const Text(
              'Apply Online (Direct Link)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),

          // 2. SECONDARY BUTTON: Download Official Notification (PDF)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: palette.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: palette.surfaceGlass,
            ),
            onPressed: () => _launchExternalUrl(
              context,
              job.notificationLink.isNotEmpty ? job.notificationLink : job.url,
            ),
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 16,
              color: Color(0xFFEF4444),
            ),
            label: Text(
              'Download Notification (PDF)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),

          // 3. TERTIARY BUTTON: Official Department Website
          if (job.officialWebsite.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: palette.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _launchExternalUrl(context, job.officialWebsite),
              icon: const Icon(Icons.language_rounded, size: 15),
              label: Text(
                'Official Department Website',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
