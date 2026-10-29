import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  bool _isLoading = false;
  bool _isPullRefreshing = false;
  bool _bannerDismissed = false;
  bool _isBarsVisible = true; // Controls header & footer visibility on scroll

  List<JobPost> _allJobs = [];
  List<String> _selectedQualifications = ['B.SC', 'GRADUATE', '12TH / 10+2'];
  Set<int> _savedJobIds = {};
  List<Qualification> _masterQualifications = [];
  String _candidateName = 'Candidate';

  // Explore tab filters (In-memory, instant)
  String _selectedSource = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialFastLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Instant 0ms cache load, followed by silent background sync
  Future<void> _initialFastLoad() async {
    // 1. Read local storage first (instant synchronous feel)
    final cachedJobs = await StorageService.getCachedJobs();
    final quals = await StorageService.getSelectedQualifications();
    final saved = await StorageService.getSavedJobIds();
    final profile = await StorageService.getCandidateProfile();
    final dismissed = await StorageService.isBannerDismissed();

    if (mounted) {
      setState(() {
        if (cachedJobs.isNotEmpty) {
          _allJobs = cachedJobs;
          _isLoading = false;
        } else {
          _isLoading = true;
        }
        _selectedQualifications = quals.isNotEmpty ? quals : ['B.SC', 'GRADUATE', '12TH / 10+2'];
        _savedJobIds = saved;
        _candidateName = (profile['name']?.isNotEmpty == true && profile['name'] != 'Candidate')
            ? profile['name']!.split(' ').first
            : 'Candidate';
        _bannerDismissed = dismissed;
      });
    }

    // 2. Background silent fetch & sync (no full-screen blocking spinner)
    _silentBackgroundSync();
  }

  Future<void> _silentBackgroundSync() async {
    try {
      final freshJobs = await ApiService.fetchJobs();
      final masterQuals = await ApiService.fetchQualifications();
      if (mounted) {
        setState(() {
          if (freshJobs.isNotEmpty) _allJobs = freshJobs;
          _masterQualifications = masterQuals;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Pull-to-refresh trigger: Shows top pull animation and refreshes jobs
  Future<void> _handlePullRefresh() async {
    if (_isPullRefreshing) return;
    setState(() => _isPullRefreshing = true);

    try {
      // Trigger background scrape if backend is connected
      await ApiService.triggerScrape();
      final freshJobs = await ApiService.fetchJobs(
        source: _selectedSource,
        search: _searchQuery,
      );
      if (mounted && freshJobs.isNotEmpty) {
        setState(() => _allJobs = freshJobs);
      }
    } finally {
      if (mounted) setState(() => _isPullRefreshing = false);
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
    setState(() {
      _currentTab = 3;
      _isBarsVisible = true;
    });
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
          },
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );

    if (loggedOut == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => AuthScreen(
            onThemeChanged: widget.onThemeChanged,
            currentThemeMode: widget.currentThemeMode,
          ),
        ),
      );
    } else {
      // Refresh candidate profile name
      final profile = await StorageService.getCandidateProfile();
      if (mounted) {
        setState(() {
          _candidateName = (profile['name']?.isNotEmpty == true && profile['name'] != 'Candidate')
              ? profile['name']!.split(' ').first
              : 'Candidate';
        });
      }
    }
  }

  // --- Home Tab: Matched recommendations based on candidate streams ---
  List<JobPost> _getMatchedJobs() {
    return _allJobs.where((job) {
      return QualificationMatcher.isJobEligible(job, _selectedQualifications);
    }).toList();
  }

  // --- Explore Tab: Universal Large Pool of ALL Jobs across 3 portals ---
  // Deduplicated and NOT choice-specific!
  List<JobPost> _getFilteredExploreJobs() {
    var list = _allJobs;

    // Filter by portal chip if not 'All'
    if (_selectedSource != 'All') {
      list = list.where((j) => j.source.toLowerCase() == _selectedSource.toLowerCase()).toList();
    }

    // Instant in-memory search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((j) =>
          j.title.toLowerCase().contains(q) ||
          j.org.toLowerCase().contains(q) ||
          j.eligibilitySnippet.toLowerCase().contains(q) ||
          j.qualificationsFound.any((qual) => qual.toLowerCase().contains(q))).toList();
    }

    return list;
  }

  List<JobPost> _getSavedJobs() {
    return _allJobs.where((job) => _savedJobIds.contains(job.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          // When scrolling down: collapse header and footer to give full screen to middle UI
          if (notification.direction == ScrollDirection.reverse) {
            if (_isBarsVisible) {
              setState(() => _isBarsVisible = false);
            }
          }
          // When scrolling up: smoothly reveal header and footer
          else if (notification.direction == ScrollDirection.forward) {
            if (!_isBarsVisible) {
              setState(() => _isBarsVisible = true);
            }
          }
          return false;
        },
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Collapsible Header (Shifts UP and gone on scroll)
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                height: _isBarsVisible ? null : 0.0,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  offset: _isBarsVisible ? Offset.zero : const Offset(0, -1),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isBarsVisible ? 1.0 : 0.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopHeader(palette),
                        if (!_bannerDismissed) _buildNotificationBanner(palette),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Middle Content Views (Expands to fill 100% of space)
              Expanded(
                child: _isLoading && _allJobs.isEmpty
                    ? Center(child: CircularProgressIndicator(color: palette.accentPrimary))
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

              // 3. Collapsible Footer Bottom Dock (Shifts DOWN and gone on scroll)
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                height: _isBarsVisible ? 80.0 : 0.0,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  offset: _isBarsVisible ? Offset.zero : const Offset(0, 1),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isBarsVisible ? 1.0 : 0.0,
                    child: CustomBottomDock(
                      currentIndex: _currentTab,
                      onTabSelected: (idx) {
                        setState(() {
                          _currentTab = idx;
                          _isBarsVisible = true; // Always reveal bars on tab switch
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header without left button as requested ---
  Widget _buildTopHeader(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: App Logo & Title
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.surfaceGlassHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.cardBorder, width: 1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 19,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sarkari Job Alert',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Official Recruitment Portal',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: palette.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Right: Profile Avatar
              InkWell(
                onTap: _openProfile,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.surfaceGlassHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Greeting & Active Degree Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Hello, $_candidateName',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              // Active Qualification Pill
              InkWell(
                onTap: _openProfile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.surfaceGlassHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.cardBorder, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _selectedQualifications.first,
                        style: TextStyle(
                          fontSize: 11,
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
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceGlassHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Color(0xFFFBBF24), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _handleBannerClick,
              child: Text(
                'Latest Notices: RRB NTPC Graduate Posts & SSC CGL. Tap to check.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.close_rounded, size: 16, color: palette.textSecondary),
            onPressed: _dismissBanner,
          ),
        ],
      ),
    );
  }

  // --- TAB 0: HOME COMMAND CENTER (Pull-to-refresh enabled) ---
  Widget _buildDashboardView(AppPalette palette) {
    final matchedJobs = _getMatchedJobs();
    final topJobs = matchedJobs.isNotEmpty ? matchedJobs : _allJobs;

    return RefreshIndicator(
      onRefresh: _handlePullRefresh,
      color: palette.accentPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Metric Card
            HeroMetricCard(
              totalJobs: _allJobs.length,
              matchedCount: matchedJobs.length,
              onTap: () => setState(() => _currentTab = 1),
            ),

            // Sector Quick Access Pills
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
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

            // Section Header: "Recommended For You"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Matched for ${_selectedQualifications.first}',
                    style: TextStyle(
                      fontSize: 14.5,
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
                          'View all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: palette.textSecondary,
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
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.92,
                ),
                itemCount: topJobs.take(6).length,
                itemBuilder: (context, index) {
                  final job = topJobs[index];
                  final isSaved = _savedJobIds.contains(job.id);
                  return DashboardGridCard(
                    job: job,
                    isSaved: isSaved,
                    onToggleSave: () => _toggleSaveJob(job.id),
                  );
                },
              ),
            ),
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
          setState(() {
            _searchController.text = query;
            _searchQuery = query;
            _currentTab = 1; // Switch to Explore view
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: palette.surfaceGlassHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.cardBorder, width: 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: EXPLORE DIRECTORY (Full Pool Across 3 Portals, Pull-to-refresh) ---
  Widget _buildExploreDirectoryView(AppPalette palette) {
    final exploreJobs = _getFilteredExploreJobs();

    return Column(
      children: [
        // Fast instant search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              // Instant in-memory filter with zero network delay!
              setState(() => _searchQuery = val);
            },
            style: TextStyle(color: palette.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search RRB NTPC, B.Sc Science, UPSC, SSC...',
              hintStyle: TextStyle(fontSize: 12.5, color: palette.textSecondary),
              prefixIcon: Icon(Icons.search, size: 18, color: palette.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: palette.isDark ? const Color(0xFF17151C) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.cardBorder),
              ),
            ),
          ),
        ),

        // Portal filter bar: All, SarkariResult ★, FreeJobAlert, RojgarResult
        PortalFilterBar(
          selectedSource: _selectedSource,
          onSourceSelected: (src) {
            setState(() => _selectedSource = src);
          },
        ),
        const SizedBox(height: 4),

        // Recruitment Feed with Pull-To-Refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handlePullRefresh,
            color: palette.accentPrimary,
            child: _buildJobList(
              exploreJobs,
              palette,
              emptyTitle: 'No vacancies found',
              emptySubtitle: 'Try adjusting your search query or portal filters.',
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: SAVED BOOKMARKS ---
  Widget _buildExploreListView(List<JobPost> list, AppPalette palette, {bool isSavedTab = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.bookmark_rounded, color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 8),
              Text(
                'Bookmarked Vacancies (${list.length})',
                style: TextStyle(
                  fontSize: 14.5,
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
            emptyTitle: 'No Bookmarked Vacancies',
            emptySubtitle: 'Tap Bookmark on any job notice to save it for quick reference.',
          ),
        ),
      ],
    );
  }

  // --- TAB 3: ALERTS TAB ---
  Widget _buildAlertsView(AppPalette palette) {
    final alertJobs = _getMatchedJobs().take(8).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Recruitment Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Instant notifications for vacancies matching your qualifications',
          style: TextStyle(fontSize: 12, color: palette.textSecondary),
        ),
        const SizedBox(height: 14),

        ...alertJobs.map((j) {
          final isSaved = _savedJobIds.contains(j.id);
          return JobCard(
            job: j,
            isSaved: isSaved,
            onToggleSave: () => _toggleSaveJob(j.id),
          );
        }),
      ],
    );
  }

  Widget _buildJobList(
    List<JobPost> list,
    AppPalette palette, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: palette.textSecondary),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final job = list[index];
        final isSaved = _savedJobIds.contains(job.id);
        return JobCard(
          job: job,
          isSaved: isSaved,
          onToggleSave: () => _toggleSaveJob(job.id),
        );
      },
    );
  }
}
