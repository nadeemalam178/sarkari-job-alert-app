import 'package:flutter/material.dart';

import '../models/job_post.dart';
import '../models/qualification.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/qualification_matcher.dart';
import '../widgets/custom_bottom_dock.dart';
import '../widgets/dashboard_grid_card.dart';
import '../widgets/hero_metric_card.dart';
import '../widgets/job_card.dart';
import '../widgets/portal_filter_bar.dart';
import '../widgets/tactile_fade_slide.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode currentThemeMode;

  const MainDashboardScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentTab = 0; // 0: Home, 1: Explore, 2: Saved, 3: Alerts
  final TextEditingController _searchController = TextEditingController();

  List<JobPost> _allJobs = [];
  List<Qualification> _masterQualifications = [];
  List<String> _selectedQualifications = ['B.SC', 'GRADUATE', '12TH / 10+2'];
  Set<int> _savedJobIds = {};
  String _candidateName = 'Candidate';
  bool _bannerDismissed = false;

  String _selectedSource = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isScraping = false;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() => _isLoading = true);
    final quals = await StorageService.getSelectedQualifications();
    final saved = await StorageService.getSavedJobIds();
    final masterQuals = await ApiService.fetchQualifications();
    final profile = await StorageService.getCandidateProfile();
    final dismissed = await StorageService.isBannerDismissed();

    if (mounted) {
      setState(() {
        _selectedQualifications = quals.isNotEmpty ? quals : ['B.SC', 'GRADUATE', '12TH / 10+2'];
        _savedJobIds = saved;
        _masterQualifications = masterQuals;
        _candidateName = profile['name']?.split(' ').first ?? 'Candidate';
        _bannerDismissed = dismissed;
      });
    }

    await _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    final jobs = await ApiService.fetchJobs(
      source: _selectedSource,
      search: _searchQuery,
    );

    if (mounted) {
      setState(() {
        _allJobs = jobs;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerManualScrape() async {
    if (_isScraping) return;
    setState(() => _isScraping = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing latest government vacancies from Sarkari Result & RRB...'),
        duration: Duration(seconds: 2),
      ),
    );

    final ok = await ApiService.triggerScrape();
    await _fetchJobs();

    if (mounted) {
      setState(() => _isScraping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Synced latest vacancies successfully'
                : 'Vacancies up to date (viewing latest recruitment notices)',
          ),
        ),
      );
    }
  }

  Future<void> _toggleSaveJob(int id) async {
    await StorageService.toggleSaveJobId(id);
    final updated = await StorageService.getSavedJobIds();
    if (mounted) {
      setState(() => _savedJobIds = updated);
    }
  }

  void _dismissBanner() async {
    setState(() => _bannerDismissed = true);
    await StorageService.setBannerDismissed(true);
  }

  void _handleBannerClick() {
    _dismissBanner();
    setState(() => _currentTab = 3); // Navigate to Alerts tab
  }

  void _openProfile() async {
    final loggedOut = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => ProfileScreen(
          allQualifications: _masterQualifications,
          selectedQualifications: _selectedQualifications,
          currentThemeMode: widget.currentThemeMode,
          onQualificationsChanged: (newSelected) {
            setState(() => _selectedQualifications = newSelected);
            _fetchJobs();
          },
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );

    if (loggedOut == true && mounted) {
      // Transition to Auth screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => AuthScreen(
            onThemeChanged: widget.onThemeChanged,
            currentThemeMode: widget.currentThemeMode,
          ),
        ),
      );
    }
  }

  List<JobPost> _getMatchedJobs() {
    return _allJobs.where((job) {
      return QualificationMatcher.isJobEligible(job, _selectedQualifications);
    }).toList();
  }

  List<JobPost> _getSavedJobs() {
    return _allJobs.where((job) => _savedJobIds.contains(job.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            _buildTopHeader(palette),

            // Dismissible Notification Banner (As requested: gone after clicking & checking)
            if (!_bannerDismissed) _buildNotificationBanner(palette),

            // Main Content Views
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: palette.accentBlue))
                  : IndexedStack(
                      index: _currentTab,
                      children: [
                        _buildDashboardView(palette),
                        _buildExploreDirectoryView(palette),
                        _buildExploreListView(_getSavedJobs(), palette, isSavedTab: true),
                        _buildAlertsView(palette),
                      ],
                    ),
            ),

            // Floating Bottom Dock (No duplicates, center sync action)
            CustomBottomDock(
              currentIndex: _currentTab,
              onTabSelected: (idx) => setState(() => _currentTab = idx),
              onCenterAction: _triggerManualScrape,
              isSyncing: _isScraping,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Category / Sector Sheet (Deduplicated, not sync!)
              IconButton(
                onPressed: () {
                  setState(() => _currentTab = 1); // Open Explore tab
                },
                icon: Icon(
                  Icons.dashboard_customize_rounded,
                  color: palette.isDark ? Colors.white70 : const Color(0xFF1E293B),
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Explore Directory',
              ),

              // Right: Profile Avatar Click opens Profile Screen
              InkWell(
                onTap: _openProfile,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.accentBlue,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.isDark ? const Color(0xFF1E2D44) : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 22,
                        color: palette.isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Greeting & Active Degrees Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello $_candidateName 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sarkari Recruitment & RRB Alerts',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Pill (Opens Profile)
              InkWell(
                onTap: _openProfile,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: palette.glassDecoration(radius: 20),
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
                        _selectedQualifications.first,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
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
    );
  }

  // Dismissible Top Notification Banner
  Widget _buildNotificationBanner(AppPalette palette) {
    return TactileFadeSlide(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.accentBlue.withValues(alpha: palette.isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.accentBlue.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign_rounded, color: palette.accentCyan, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _handleBannerClick,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📢 3 New Notifications Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      'RRB NTPC 11,558 Posts & UPSC Civil Services. Tap to check.',
                      style: TextStyle(fontSize: 11, color: palette.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close_rounded, size: 16, color: palette.textSecondary),
              onPressed: _dismissBanner,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }

  // View 0: Tactile 2x2 Bento Home Dashboard (Candidate Command Center)
  Widget _buildDashboardView(AppPalette palette) {
    final matchedJobs = _getMatchedJobs();
    final topJobs = matchedJobs.isNotEmpty ? matchedJobs : _allJobs;

    return RefreshIndicator(
      color: palette.accentBlue,
      backgroundColor: palette.surfaceGlassHigh,
      onRefresh: _fetchJobs,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Metric Card
            TactileFadeSlide(
              delayMs: 100,
              child: HeroMetricCard(
                totalJobs: _allJobs.length,
                matchedCount: matchedJobs.length,
                onTap: () => setState(() => _currentTab = 1),
              ),
            ),

            // Sector Quick Access Pills
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSectorChip('🚆 Railways (RRB)', 'RRB', palette),
                    _buildSectorChip('🔬 Science & B.Sc', 'SCIENCE', palette),
                    _buildSectorChip('🏛 Central (UPSC/SSC)', 'UPSC', palette),
                    _buildSectorChip('💰 Banking', 'BANK', palette),
                    _buildSectorChip('👮 Defence / Police', 'POLICE', palette),
                  ],
                ),
              ),
            ),

            // Section Header: "Recommended For You" / "See all ->"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended For ${_selectedQualifications.join(", ")}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _currentTab = 1),
                    child: Row(
                      children: [
                        Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: palette.accentBlue,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: palette.accentBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2x2 Grid of Dashboard Bento Tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                itemCount: topJobs.take(6).length,
                itemBuilder: (context, index) {
                  final job = topJobs[index];
                  final isSaved = _savedJobIds.contains(job.id);
                  return TactileFadeSlide(
                    delayMs: 150 + index * 60,
                    child: DashboardGridCard(
                      job: job,
                      isSaved: isSaved,
                      onToggleSave: () => _toggleSaveJob(job.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorChip(String label, String query, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          _searchController.text = query;
          setState(() {
            _searchQuery = query;
            _currentTab = 1; // Switch to explore with query
          });
          _fetchJobs();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: palette.glassDecoration(radius: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // View 1: Explore Discovery & Portals (Logical difference from Home!)
  Widget _buildExploreDirectoryView(AppPalette palette) {
    return Column(
      children: [
        // Search bar with clear button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() => _searchQuery = val);
              _fetchJobs();
            },
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search RRB NTPC, B.Sc Science, UPSC, SSC...',
              hintStyle: TextStyle(fontSize: 13, color: palette.textSecondary),
              prefixIcon: Icon(Icons.search, size: 20, color: palette.accentBlue),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _fetchJobs();
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: palette.isDark ? const Color(0xFF0A0F1D) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: palette.cardBorder),
              ),
            ),
          ),
        ),

        // Portal filter chips
        PortalFilterBar(
          selectedSource: _selectedSource,
          onSourceSelected: (src) {
            setState(() => _selectedSource = src);
            _fetchJobs();
          },
        ),
        const SizedBox(height: 6),

        // Recruitment Feed
        Expanded(
          child: _buildJobList(
            _allJobs,
            palette,
            emptyTitle: 'No vacancies found',
            emptySubtitle: 'Try adjusting your search query or portal filters.',
          ),
        ),
      ],
    );
  }

  // View 2: Saved Bookmarks
  Widget _buildExploreListView(List<JobPost> list, AppPalette palette, {bool isSavedTab = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Row(
            children: [
              Icon(Icons.bookmark_rounded, color: palette.accentAmber, size: 20),
              const SizedBox(width: 8),
              Text(
                'My Saved Bookmarks (${list.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildJobList(
            list,
            palette,
            emptyTitle: 'No saved jobs yet',
            emptySubtitle: 'Toggle the bookmark switch on any card to track it here.',
          ),
        ),
      ],
    );
  }

  Widget _buildJobList(List<JobPost> list, AppPalette palette, {required String emptyTitle, required String emptySubtitle}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              emptyTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(emptySubtitle, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final job = list[index];
        final isSaved = _savedJobIds.contains(job.id);
        return TactileFadeSlide(
          delayMs: index < 5 ? index * 40 : 0,
          child: JobCard(
            job: job,
            isSaved: isSaved,
            onToggleSave: () => _toggleSaveJob(job.id),
          ),
        );
      },
    );
  }

  // View 3: Official Alerts & Notices Tab
  Widget _buildAlertsView(AppPalette palette) {
    final notices = [
      {
        'title': 'RRB NTPC Graduate Level CEN 05/2026 Application Window Open',
        'dept': 'Railway Recruitment Boards (RRB)',
        'date': 'Active Now • 11,558 Posts',
        'tag': 'Live',
        'color': 0xFF10B981,
      },
      {
        'title': 'UPSC Civil Services Prelims 2026 Examination Notice Released',
        'dept': 'Union Public Service Commission',
        'date': 'Today',
        'tag': 'Notice',
        'color': 0xFF2563EB,
      },
      {
        'title': 'UP TGT Exam Date & Admit Card Hall Ticket Notice Announced',
        'dept': 'UP Education Selection Commission',
        'date': '24 Oct',
        'tag': 'Admit Card',
        'color': 0xFFF59E0B,
      },
      {
        'title': 'BPSC Headmaster & Head Teacher Document Verification Schedule',
        'dept': 'Bihar Public Service Commission',
        'date': '22 Oct',
        'tag': 'Verification',
        'color': 0xFF8B5CF6,
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Official Alerts & Notices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            IconButton(
              onPressed: _triggerManualScrape,
              icon: Icon(Icons.refresh, color: palette.accentBlue, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...notices.map((n) {
          final color = Color(n['color'] as int);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: palette.glassDecoration(radius: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    n['tag'] as String,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title'] as String,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${n['dept']} • ${n['date']}',
                        style: TextStyle(fontSize: 11, color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
