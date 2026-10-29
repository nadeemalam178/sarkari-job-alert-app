import 'dart:async';
import 'dart:ui';
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
import '../widgets/motion_spells.dart';
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

  // --- Explore Tab: Universal Large Pool of ALL Jobs across all portals ---
  // Deduplicated and NOT choice-specific!
  List<JobPost> _getFilteredExploreJobs() {
    var list = _allJobs;

    if (_selectedSource != 'All') {
      list = list.where((j) => j.source.toLowerCase() == _selectedSource.toLowerCase()).toList();
    }

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
    final topPadding = MediaQuery.of(context).padding.top + 98.0 + (_bannerDismissed ? 0.0 : 42.0);
    const bottomPadding = 92.0;

    return Scaffold(
      backgroundColor: palette.background,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final delta = notification.scrollDelta ?? 0;
            // Scrolling down -> hide bars smoothly to give 100% space to middle UI
            if (delta > 8.0) {
              if (_isBarsVisible) setState(() => _isBarsVisible = false);
            }
            // Scrolling up -> reveal bars smoothly
            else if (delta < -8.0) {
              if (!_isBarsVisible) setState(() => _isBarsVisible = true);
            }
          }
          // When user scrolls to top of view, guarantee bars are visible
          if (notification.metrics.pixels <= 10.0) {
            if (!_isBarsVisible) setState(() => _isBarsVisible = true);
          }
          return false;
        },
        child: Stack(
          children: [
            // 1. Content Views Layer (Constant fixed viewport, zero layout thrashing)
            Positioned.fill(
              child: _isLoading && _allJobs.isEmpty
                  ? Center(child: CircularProgressIndicator(color: palette.accentPrimary))
                  : IndexedStack(
                      index: _currentTab,
                      children: [
                        _buildDashboardView(palette, topPadding, bottomPadding),
                        _buildExploreDirectoryView(palette, topPadding, bottomPadding),
                        _buildSavedView(palette, topPadding, bottomPadding),
                        _buildAlertsView(palette, topPadding, bottomPadding),
                      ],
                    ),
            ),

            // 2. Floating Frosted Top Header (AnimatedSlide UP on scroll)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                offset: _isBarsVisible ? Offset.zero : const Offset(0, -1.2),
                child: IgnorePointer(
                  ignoring: !_isBarsVisible,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.background.withValues(alpha: 0.85),
                          border: Border(
                            bottom: BorderSide(
                              color: palette.cardBorder.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
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
                  ),
                ),
              ),
            ),

            // 3. Floating Bottom Dock (AnimatedSlide DOWN on scroll)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                offset: _isBarsVisible ? Offset.zero : const Offset(0, 1.2),
                child: IgnorePointer(
                  ignoring: !_isBarsVisible,
                  child: SafeArea(
                    top: false,
                    child: CustomBottomDock(
                      currentIndex: _currentTab,
                      onTabSelected: (idx) {
                        setState(() {
                          _currentTab = idx;
                          _isBarsVisible = true;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Top Header with Tactile Avatar and Status ---
  Widget _buildTopHeader(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
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

              // Right: Profile Avatar with TactilePress
              TactilePress(
                onTap: _openProfile,
                scaleFactor: 0.92,
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

              // Active Qualification Pill with TactilePress
              TactilePress(
                onTap: _openProfile,
                scaleFactor: 0.94,
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
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 6),
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
  Widget _buildDashboardView(AppPalette palette, double topInset, double bottomInset) {
    final matchedJobs = _getMatchedJobs();
    final topJobs = matchedJobs.isNotEmpty ? matchedJobs : _allJobs;

    return RefreshIndicator(
      onRefresh: _handlePullRefresh,
      color: palette.accentPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, topInset + 6, 0, bottomInset + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // 2x2 Grid of Dashboard Bento Tiles with Staggered Entrance
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
                  return StaggeredFadeSlide(
                    index: index,
                    child: DashboardGridCard(
                      job: job,
                      isSaved: isSaved,
                      onToggleSave: () => _toggleSaveJob(job.id),
                    ),
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
      child: TactilePress(
        scaleFactor: 0.94,
        onTap: () {
          setState(() {
            _searchController.text = query;
            _searchQuery = query;
            _currentTab = 1;
            _isBarsVisible = true;
          });
        },
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

  // --- TAB 1: EXPLORE DIRECTORY (Full Unified Pool Across All Portals) ---
  Widget _buildExploreDirectoryView(AppPalette palette, double topInset, double bottomInset) {
    final exploreJobs = _getFilteredExploreJobs();

    return RefreshIndicator(
      onRefresh: _handlePullRefresh,
      color: palette.accentPrimary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topInset + 4),
                // Fast instant search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
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

                // Portal Filter Bar with all sources
                PortalFilterBar(
                  selectedSource: _selectedSource,
                  onSourceSelected: (src) {
                    setState(() => _selectedSource = src);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (exploreJobs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                'No vacancies found',
                'Try adjusting your search query or portal filters.',
                palette,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(bottom: bottomInset + 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final job = exploreJobs[index];
                    final isSaved = _savedJobIds.contains(job.id);
                    return StaggeredFadeSlide(
                      index: index,
                      child: JobCard(
                        job: job,
                        isSaved: isSaved,
                        onToggleSave: () => _toggleSaveJob(job.id),
                      ),
                    );
                  },
                  childCount: exploreJobs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- TAB 2: SAVED BOOKMARKS ---
  Widget _buildSavedView(AppPalette palette, double topInset, double bottomInset) {
    final savedJobs = _getSavedJobs();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: Color(0xFFFBBF24), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Bookmarked Vacancies (${savedJobs.length})',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (savedJobs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(
              'No Bookmarked Vacancies',
              'Tap Bookmark on any job notice to save it for quick reference.',
              palette,
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.only(bottom: bottomInset + 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final job = savedJobs[index];
                  return StaggeredFadeSlide(
                    index: index,
                    child: JobCard(
                      job: job,
                      isSaved: true,
                      onToggleSave: () => _toggleSaveJob(job.id),
                    ),
                  );
                },
                childCount: savedJobs.length,
              ),
            ),
          ),
      ],
    );
  }

  // --- TAB 3: ALERTS TAB ---
  Widget _buildAlertsView(AppPalette palette, double topInset, double bottomInset) {
    final alertJobs = _getMatchedJobs().take(8).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, bottomInset + 20),
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

        ...alertJobs.asMap().entries.map((entry) {
          final index = entry.key;
          final j = entry.value;
          final isSaved = _savedJobIds.contains(j.id);
          return StaggeredFadeSlide(
            index: index,
            child: JobCard(
              job: j,
              isSaved: isSaved,
              onToggleSave: () => _toggleSaveJob(j.id),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, AppPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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
}
