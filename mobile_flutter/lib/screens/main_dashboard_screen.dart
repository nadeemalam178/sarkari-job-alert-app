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
import '../widgets/hero_metric_card.dart';
import '../widgets/job_card.dart';
import '../widgets/motion_spells.dart';
import '../widgets/portal_filter_bar.dart';
import '../widgets/qualification_picker_sheet.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';

class SectorHub {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> keywords;

  const SectorHub({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.keywords,
  });
}

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
  int _currentTab = 0; // 0: For You, 1: Explore, 2: Saved, 3: Alerts
  bool _isLoading = false;
  bool _bannerDismissed = false;
  bool _isBarsVisible = true;
  String? _expandedSectorIdForYou;
  String? _expandedSectorIdExplore;
  bool _exploreViewBySector = true;

  List<JobPost> _allJobs = [];
  List<String> _selectedQualifications = ['B.SC', 'GRADUATE', '12TH / 10+2'];
  Set<int> _savedJobIds = {};
  List<Qualification> _masterQualifications = [];
  String _candidateName = 'Candidate';

  // Explore tab filters
  String _selectedSource = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<SectorHub> _sectors = [
    SectorHub(
      id: 'railways',
      title: 'Railways & Metro (RRB)',
      subtitle: 'RRB NTPC, Technician, Station Master, ALP & Metro Rail',
      icon: Icons.train_rounded,
      accentColor: Color(0xFF38BDF8),
      keywords: ['RRB', 'RAILWAY', 'NTPC', 'TECHNICIAN', 'LOCO', 'STATION MASTER', 'GROUP D', 'METRO', 'ALP', 'TRAIN', 'RPF'],
    ),
    SectorHub(
      id: 'banking',
      title: 'Banking & Financial Services',
      subtitle: 'Bank PO, Clerk, RBI, SBI, IBPS, NABARD & PSBs',
      icon: Icons.account_balance_rounded,
      accentColor: Color(0xFF10B981),
      keywords: ['BANK', 'RBI', 'IBPS', 'SBI', 'NABARD', 'FINANCE', 'ACCOUNTANT', 'CLERK', 'PO', 'TMB', 'NABFINS', 'COOPERATIVE', 'CREDIT', 'INSURANCE', 'LIC'],
    ),
    SectorHub(
      id: 'teaching',
      title: 'Teaching & Academia',
      subtitle: 'BPSC TRE, UPESSC, CTET, STET, KVS, NVS & Professors',
      icon: Icons.school_rounded,
      accentColor: Color(0xFF2DD4BF),
      keywords: ['TEACH', 'TET', 'B.ED', 'CTET', 'PROFESSOR', 'BPSC TRE', 'UPESSC', 'LECTURER', 'BLET', 'LIBRARY', 'SCHOOL', 'EDUCATION', 'FACULTY', 'JEPC', 'INSTRUCTOR'],
    ),
    SectorHub(
      id: 'upsc_ssc',
      title: 'Central & State Commissions',
      subtitle: 'UPSC Civil Services, SSC CGL, CHSL, MTS & State PSCs',
      icon: Icons.assured_workload_rounded,
      accentColor: Color(0xFFA78BFA),
      keywords: ['UPSC', 'SSC', 'CGL', 'CHSL', 'CIVIL SERVICES', 'COMMISSION', 'MTS', 'PSC', 'JUDICIAL', 'COURT', 'HIGH COURT', 'DISTRICT COURT', 'SUPREME COURT', 'LAW CLERK'],
    ),
    SectorHub(
      id: 'defence_police',
      title: 'Defence & Police Forces',
      subtitle: 'Army, Navy, ITBP, CRPF, BSF, Fire & State Police SI',
      icon: Icons.shield_rounded,
      accentColor: Color(0xFFF87171),
      keywords: ['POLICE', 'DEFENCE', 'ARMY', 'NAVY', 'AIR FORCE', 'CRPF', 'ITBP', 'BSF', 'CONSTABLE', 'SI', 'SPORTS QUOTA', 'FIRE', 'FIRE OFFICER', 'JAIL', 'WARDER', 'SUB FIRE', 'COMMANDANT', 'ARMED'],
    ),
    SectorHub(
      id: 'technical_psu',
      title: 'Technical, PSU & Engineering',
      subtitle: 'ISRO, BDL, IREL, NPCC, ITI Trades, B.Tech & Diploma',
      icon: Icons.precision_manufacturing_rounded,
      accentColor: Color(0xFFFB923C),
      keywords: ['ENGINEER', 'TECHNICAL', 'PSU', 'ISRO', 'BDL', 'IREL', 'NPCC', 'B.TECH', 'DIPLOMA', 'ITI', 'TRADESMAN', 'DEVELOPER', 'PROGRAMMER', 'IOCL', 'ONGC', 'SAIL', 'GAIL', 'POWER GRID', 'BHANUR'],
    ),
    SectorHub(
      id: 'medical_health',
      title: 'Medical & Healthcare Services',
      subtitle: 'AIIMS, Medical Officers, Pharmacists, GNM Nursing & Staff',
      icon: Icons.local_hospital_rounded,
      accentColor: Color(0xFFF472B6),
      keywords: ['MEDICAL', 'HEALTH', 'HOSPITAL', 'DOCTOR', 'NURSE', 'PHARMACIST', 'CMO', 'RAEBARELI', 'AIIMS', 'PARAMEDICAL', 'RGSSH', 'DHFWS', 'AYUSH', 'DENTAL', 'VETERINARY'],
    ),
    SectorHub(
      id: 'admin_depts',
      title: 'State & Central Departments',
      subtitle: 'Secretariats, Municipal, Boards, Revenue & Housing',
      icon: Icons.location_city_rounded,
      accentColor: Color(0xFFFBBF24),
      keywords: ['DEPARTMENT', 'BOARD', 'MUNICIPAL', 'CORPORATION', 'DISTRICT', 'SECRETARIAT', 'MINISTRY', 'REVENUE', 'PANCHAYAT', 'EXCISE', 'DEVELOPMENT', 'AUTHORITY', 'HOUSING', 'TRANSPORT', 'RURAL'],
    ),
  ];

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

    _loadMasterQualifications();
    _syncLatestJobs();
  }

  Future<void> _loadMasterQualifications() async {
    try {
      final res = await ApiService.fetchQualifications();
      if (res.isNotEmpty && mounted) {
        setState(() => _masterQualifications = res);
      }
    } catch (_) {}
  }

  Future<void> _syncLatestJobs() async {
    try {
      final freshJobs = await ApiService.fetchJobs();
      if (freshJobs.isNotEmpty && mounted) {
        setState(() {
          _allJobs = freshJobs;
          _isLoading = false;
        });
        await StorageService.cacheJobs(freshJobs);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePullRefresh() async {
    try {
      final freshJobs = await ApiService.fetchJobs();
      if (freshJobs.isNotEmpty && mounted) {
        setState(() => _allJobs = freshJobs);
        await StorageService.cacheJobs(freshJobs);
      }
    } catch (_) {
    } finally {
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

  void _openQualificationPicker() {
    QualificationPickerSheet.show(
      context,
      allQualifications: _masterQualifications.isNotEmpty
          ? _masterQualifications
          : Qualification.defaultMasterList,
      initialSelected: _selectedQualifications,
      onSaved: (newSelected) async {
        setState(() => _selectedQualifications = newSelected);
        await StorageService.setSelectedQualifications(newSelected);
      },
    );
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

  List<JobPost> _getMatchedJobs() {
    return _allJobs.where((job) {
      return QualificationMatcher.isJobEligible(job, _selectedQualifications);
    }).toList();
  }

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
            if (delta > 8.0) {
              if (_isBarsVisible) setState(() => _isBarsVisible = false);
            } else if (delta < -8.0) {
              if (!_isBarsVisible) setState(() => _isBarsVisible = true);
            }
          }
          if (notification.metrics.pixels <= 10.0) {
            if (!_isBarsVisible) setState(() => _isBarsVisible = true);
          }
          return false;
        },
        child: Stack(
          children: [
            // 1. Content Views Layer with AnimatedSwitcher (Fade + subtle slide transition)
            Positioned.fill(
              child: _isLoading && _allJobs.isEmpty
                  ? Center(child: CircularProgressIndicator(color: palette.accentPrimary))
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.03),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_currentTab),
                        child: _buildCurrentTabContent(palette, topPadding, bottomPadding),
                      ),
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

  Widget _buildCurrentTabContent(AppPalette palette, double topPadding, double bottomPadding) {
    switch (_currentTab) {
      case 0:
        return _buildForYouDashboardView(palette, topPadding, bottomPadding);
      case 1:
        return _buildExploreDirectoryView(palette, topPadding, bottomPadding);
      case 2:
        return _buildSavedView(palette, topPadding, bottomPadding);
      case 3:
        return _buildAlertsView(palette, topPadding, bottomPadding);
      default:
        return _buildForYouDashboardView(palette, topPadding, bottomPadding);
    }
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.surfaceGlassHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.cardBorder, width: 1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 20,
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

          // Greeting & Active Qualifications Pill with Quick Change
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
                onTap: _openQualificationPicker,
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
                      if (_selectedQualifications.length > 1) ...[
                        const SizedBox(width: 3),
                        Text(
                          '+${_selectedQualifications.length - 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: palette.accentPrimary,
                          ),
                        ),
                      ],
                      const SizedBox(width: 3),
                      Icon(Icons.tune_rounded, size: 12, color: palette.textSecondary),
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

  // --- TAB 0: "FOR YOU" (Strictly Filtered Matched Vacancies Only) ---
  Widget _buildForYouDashboardView(AppPalette palette, double topInset, double bottomInset) {
    final matchedJobs = _getMatchedJobs();

    return RefreshIndicator(
      onRefresh: _handlePullRefresh,
      color: palette.accentPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, topInset + 6, 0, bottomInset + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Metric Card - FOR YOU (Strictly Matched Jobs, stays on For You)
            HeroMetricCard(
              totalJobs: matchedJobs.length,
              matchedCount: matchedJobs.length,
              title: '${matchedJobs.length} Eligible Vacancies',
              subtitle: 'Strictly matching your ${_selectedQualifications.length} qualifications • Tap to adjust',
              actionIcon: Icons.tune_rounded,
              onTap: _openQualificationPicker, // STAYS ON FOR YOU, OPENS QUALIFICATION PICKER
            ),

            // 2. Section Header: Recruitment Sectors for Candidate
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Eligible Sector Hubs',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Showing only vacancies you qualify for',
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _openQualificationPicker,
                    icon: const Icon(Icons.tune_rounded, size: 14),
                    label: const Text('Filters', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.accentPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Sector Accordion Cards (Each filtered strictly for candidate's qualifications)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _sectors.map((sec) {
                  return _buildSectorAccordionCard(
                    sector: sec,
                    sourceJobs: matchedJobs, // ONLY MATCHED JOBS ON FOR YOU!
                    palette: palette,
                    isForYouMode: true,
                    isExpanded: _expandedSectorIdForYou == sec.id,
                    onToggle: () {
                      setState(() {
                        _expandedSectorIdForYou = _expandedSectorIdForYou == sec.id ? null : sec.id;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Clean, spacious Sector Accordion Card (De-shrinked with full-width JobCards)
  Widget _buildSectorAccordionCard({
    required SectorHub sector,
    required List<JobPost> sourceJobs,
    required AppPalette palette,
    required bool isForYouMode,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final sectorJobs = sourceJobs.where((j) {
      final text = '${j.title} ${j.org} ${j.eligibilitySnippet} ${j.qualificationsFound.join(" ")}'.toUpperCase();
      return sector.keywords.any((k) => text.contains(k));
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isExpanded ? palette.surfaceGlassHigh : palette.surfaceGlass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpanded ? sector.accentColor.withValues(alpha: 0.6) : palette.cardBorder,
            width: isExpanded ? 1.2 : 0.8,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: sector.accentColor.withValues(alpha: palette.isDark ? 0.20 : 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Header Bar
            TactilePress(
              scaleFactor: 0.98,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: sector.accentColor.withValues(alpha: palette.isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sector.accentColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(sector.icon, color: sector.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sector.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sector.subtitle,
                            style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sector.accentColor.withValues(alpha: palette.isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sector.accentColor.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isForYouMode
                            ? '${sectorJobs.length} Eligible'
                            : '${sectorJobs.length} Openings',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: sector.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? sector.accentColor : palette.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Collapsible Accordion Subsection Body (Generous, de-shrinked layout)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(height: 1, color: palette.cardBorder),
                    const SizedBox(height: 10),
                    if (sectorJobs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          children: [
                            Text(
                              isForYouMode
                                  ? 'No vacancies currently match your qualification in this sector.'
                                  : 'No vacancies found in this sector.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: palette.textSecondary),
                            ),
                            if (isForYouMode) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _openQualificationPicker,
                                icon: const Icon(Icons.tune_rounded, size: 14),
                                label: const Text('Add / Edit Qualifications', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                style: TextButton.styleFrom(
                                  foregroundColor: sector.accentColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      ...sectorJobs.map((j) {
                        final isSaved = _savedJobIds.contains(j.id);
                        return JobCard(
                          job: j,
                          isSaved: isSaved,
                          onToggleSave: () => _toggleSaveJob(j.id),
                          margin: const EdgeInsets.only(bottom: 8), // DE-SHRINK: Zero horizontal margin so it uses full natural width
                        );
                      }),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: EXPLORE DIRECTORY (Total Vacancies with Sector Subsections + Flat List Toggle) ---
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
                      fillColor: palette.isDark ? const Color(0xFF16131D) : Colors.white,
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
                const SizedBox(height: 6),

                // Header with Total Vacancy Count and View Mode Toggle (By Sector vs Flat List)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Vacancies Directory',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total ${exploreJobs.length} postings across all qualifications',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // View Mode Toggle Button
                      TactilePress(
                        scaleFactor: 0.94,
                        onTap: () {
                          setState(() {
                            _exploreViewBySector = !_exploreViewBySector;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: palette.surfaceGlassHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: palette.cardBorder, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _exploreViewBySector ? Icons.view_list_rounded : Icons.folder_copy_rounded,
                                size: 14,
                                color: palette.accentPrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _exploreViewBySector ? 'Flat List' : 'Sector View',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: palette.accentPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sector Accordion View in Explore (Same as For You, but showing TOTAL vacancies)
          if (_exploreViewBySector)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sec = _sectors[index];
                    return _buildSectorAccordionCard(
                      sector: sec,
                      sourceJobs: exploreJobs, // TOTAL JOBS IN EXPLORE!
                      palette: palette,
                      isForYouMode: false,
                      isExpanded: _expandedSectorIdExplore == sec.id,
                      onToggle: () {
                        setState(() {
                          _expandedSectorIdExplore = _expandedSectorIdExplore == sec.id ? null : sec.id;
                        });
                      },
                    );
                  },
                  childCount: _sectors.length,
                ),
              ),
            )
          else
            // Flat List View in Explore
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
