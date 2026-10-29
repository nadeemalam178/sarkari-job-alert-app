import 'package:flutter/material.dart';

import '../models/qualification.dart';
import '../services/ota_update_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/qualification_picker_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final List<Qualification> allQualifications;
  final List<String> selectedQualifications;
  final ThemeMode currentThemeMode;
  final ValueChanged<List<String>> onQualificationsChanged;
  final ValueChanged<ThemeMode> onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.allQualifications,
    required this.selectedQualifications,
    required this.currentThemeMode,
    required this.onQualificationsChanged,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<String> _currentQuals;
  late ThemeMode _themeMode;
  bool _pushNotifications = true;
  bool _isCheckingOta = false;

  Map<String, String> _profileData = {
    'name': 'Candidate',
    'email': '',
    'phone': '',
    'category': 'General / OBC',
    'state': 'All India',
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentQuals = List.from(widget.selectedQualifications);
    _themeMode = widget.currentThemeMode;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await StorageService.getCandidateProfile();
    final modeStr = await StorageService.getThemeMode();

    if (mounted) {
      setState(() {
        _profileData = data;
        _pushNotifications = data['notifEnabled'] == 'true';
        if (modeStr == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (modeStr == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    widget.onThemeChanged(mode);
    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    await StorageService.setThemeMode(modeStr);
  }

  void _openQualificationPicker() {
    QualificationPickerSheet.show(
      context,
      allQualifications: widget.allQualifications.isNotEmpty
          ? widget.allQualifications
          : Qualification.defaultMasterList,
      initialSelected: _currentQuals,
      onSaved: (newSelected) async {
        setState(() => _currentQuals = newSelected);
        await StorageService.setSelectedQualifications(newSelected);
        widget.onQualificationsChanged(newSelected);
      },
    );
  }

  Future<void> _checkOtaUpdate() async {
    setState(() => _isCheckingOta = true);
    final palette = AppPalette.of(context);

    try {
      final updateInfo = await OtaUpdateService.checkForUpdate();
      if (!mounted) return;

      if (updateInfo != null && updateInfo.hasUpdate) {
        final sizeMb = (updateInfo.downloadSizeBytes / (1024 * 1024)).toStringAsFixed(1);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: palette.surfaceGlassHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.system_update_rounded, color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 10),
                Text('Update Available (v${updateInfo.latestVersion})', style: TextStyle(fontSize: 16, color: palette.textPrimary, fontWeight: FontWeight.w700)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A new version of Sarkari Job Alert is available.', style: TextStyle(fontSize: 13, color: palette.textPrimary)),
                const SizedBox(height: 8),
                Text('Size: $sizeMb MB (Optimized Release)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.accentPrimary)),
                const SizedBox(height: 12),
                Text(updateInfo.releaseNotes, style: TextStyle(fontSize: 11.5, color: palette.textSecondary), maxLines: 4, overflow: TextOverflow.ellipsis),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Later', style: TextStyle(color: palette.textSecondary)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  OtaUpdateService.launchDownload(updateInfo.downloadUrl);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531),
                ),
                child: const Text('Download APK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App is up to date (v2.0.0) • OTA Engine Active'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOta = false);
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _profileData['name'] ?? '');
    final emailCtrl = TextEditingController(text: _profileData['email'] ?? '');
    final phoneCtrl = TextEditingController(text: _profileData['phone'] ?? '');
    final stateCtrl = TextEditingController(text: _profileData['state'] ?? 'All India');
    String category = _profileData['category'] ?? 'General / OBC';

    final palette = AppPalette.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: palette.surfaceGlassHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Profile Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogField('Full Name', nameCtrl, palette),
                const SizedBox(height: 10),
                _buildDialogField('Email Address', emailCtrl, palette),
                const SizedBox(height: 10),
                _buildDialogField('Mobile Number', phoneCtrl, palette),
                const SizedBox(height: 10),
                _buildDialogField('Target State / Region', stateCtrl, palette),
                const SizedBox(height: 12),
                Text(
                  'Reservation Category',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: palette.isDark ? const Color(0xFF17151C) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      dropdownColor: palette.isDark ? const Color(0xFF292531) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'General / UR', child: Text('General / Unreserved')),
                        DropdownMenuItem(value: 'General / OBC', child: Text('OBC (Other Backward Classes)')),
                        DropdownMenuItem(value: 'EWS', child: Text('EWS (Economically Weaker Section)')),
                        DropdownMenuItem(value: 'SC', child: Text('SC (Scheduled Caste)')),
                        DropdownMenuItem(value: 'ST', child: Text('ST (Scheduled Tribe)')),
                        DropdownMenuItem(value: 'Ex-Servicemen', child: Text('Ex-Servicemen (ESM)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                      style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: palette.textSecondary)),
            ),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                await StorageService.updateCandidateProfile(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  category: category,
                  state: stateCtrl.text.trim(),
                  notifEnabled: _pushNotifications,
                );
                navigator.pop();
                if (mounted) _loadProfile();
              },
              style: FilledButton.styleFrom(
                backgroundColor: palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531),
              ),
              child: const Text('Save Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController ctrl, AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 13, color: palette.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: palette.isDark ? const Color(0xFF17151C) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.cardBorder)),
          ),
        ),
      ],
    );
  }

  void _confirmLogout() {
    final palette = AppPalette.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surfaceGlassHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out Candidate Session?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary),
        ),
        content: Text(
          'You will be returned to the Create Account / Sign In screen.',
          style: TextStyle(fontSize: 13, color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: palette.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.logout();
              if (mounted) {
                Navigator.pop(context, true); // Signal logout to MainDashboardScreen
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Confirm Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Candidate Profile & Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: palette.accentPrimary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // 1. Candidate Header Card
                _buildCandidateHeader(palette),
                const SizedBox(height: 16),

                // 2. Personal & Credentials Card
                _buildCandidateDetailsCard(palette),
                const SizedBox(height: 16),

                // 3. Educational Qualifications & Eligibility Streams Card
                _buildQualificationsSection(palette),
                const SizedBox(height: 16),

                // 4. App Settings (System Theme Auto-select, Notifications, OTA)
                _buildAppSettingsSection(palette),
                const SizedBox(height: 20),

                // 5. Account Actions (Log Out)
                _buildLogoutSection(palette),
                const SizedBox(height: 20),

                // 6. Production App Metadata
                _buildProductionFooter(palette),
              ],
            ),
    );
  }

  Widget _buildCandidateHeader(AppPalette palette) {
    final name = _profileData['name']?.isNotEmpty == true ? _profileData['name']! : 'Registered Candidate';
    final state = _profileData['state']?.isNotEmpty == true ? _profileData['state']! : 'All India';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: palette.glassDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceGlassHigh,
              border: Border.all(color: palette.cardBorder, width: 1.5),
            ),
            child: Center(
              child: Icon(Icons.person_rounded, size: 32, color: palette.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  state,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x2510B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Active Aspirant Account',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateDetailsCard(AppPalette palette) {
    final email = _profileData['email']?.isNotEmpty == true ? _profileData['email']! : 'Not provided';
    final phone = _profileData['phone']?.isNotEmpty == true ? _profileData['phone']! : 'Not provided';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Candidate Credentials',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              InkWell(
                onTap: _showEditProfileDialog,
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.email_outlined, 'Email', email, palette),
          Divider(color: palette.cardBorder, height: 16),
          _buildDetailRow(Icons.phone_android_outlined, 'Mobile', phone, palette),
          Divider(color: palette.cardBorder, height: 16),
          _buildDetailRow(Icons.badge_outlined, 'Category', _profileData['category'] ?? 'General / OBC', palette),
          Divider(color: palette.cardBorder, height: 16),
          _buildDetailRow(Icons.place_outlined, 'Target Region', _profileData['state'] ?? 'All India', palette),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, AppPalette palette) {
    return Row(
      children: [
        Icon(icon, size: 16, color: palette.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: palette.textSecondary, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQualificationsSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualification Streams',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_currentQuals.length} qualifications active for matching',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _openQualificationPicker,
                icon: const Icon(Icons.tune_rounded, size: 13),
                label: const Text('Change', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(color: palette.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _currentQuals.map((q) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.surfaceGlassHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                    Text(
                      q,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.glassDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Theme Selector
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 18, color: palette.textSecondary),
              const SizedBox(width: 8),
              Text(
                'App Theme (Dynamic)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: palette.surfaceGlassHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: [
                _buildThemeOption(
                  label: 'System (Auto)',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: _themeMode == ThemeMode.system,
                  palette: palette,
                  onTap: () => _changeTheme(ThemeMode.system),
                ),
                _buildThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isSelected: _themeMode == ThemeMode.dark,
                  palette: palette,
                  onTap: () => _changeTheme(ThemeMode.dark),
                ),
                _buildThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  isSelected: _themeMode == ThemeMode.light,
                  palette: palette,
                  onTap: () => _changeTheme(ThemeMode.light),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: palette.cardBorder),

          // Notifications Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.white,
            activeTrackColor: palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531),
            value: _pushNotifications,
            title: Text(
              'Recruitment Push Alerts',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.textPrimary),
            ),
            subtitle: Text(
              'Instant alert when new vacancies are released',
              style: TextStyle(fontSize: 11, color: palette.textSecondary),
            ),
            onChanged: (val) {
              setState(() => _pushNotifications = val);
              StorageService.updateCandidateProfile(
                name: _profileData['name'] ?? 'Candidate',
                email: _profileData['email'] ?? '',
                phone: _profileData['phone'] ?? '',
                category: _profileData['category'] ?? '',
                state: _profileData['state'] ?? '',
                notifEnabled: val,
              );
            },
          ),
          Divider(color: palette.cardBorder),

          // Over-The-Air (OTA) Updates Tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: palette.surfaceGlassHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Icon(Icons.system_update_rounded, size: 17, color: palette.textPrimary),
            ),
            title: Text(
              'Check for App Updates (OTA)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.textPrimary),
            ),
            subtitle: Text(
              'Current version: v2.0.0 (Release)',
              style: TextStyle(fontSize: 11, color: palette.textSecondary),
            ),
            trailing: _isCheckingOta
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : OutlinedButton(
                    onPressed: _checkOtaUpdate,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: BorderSide(color: palette.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Check', style: TextStyle(fontSize: 11.5)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required AppPalette palette,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: isSelected ? Colors.white : palette.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection(AppPalette palette) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
        label: const Text(
          'Log Out Candidate Account',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEF4444),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: palette.surfaceGlass,
        ),
      ),
    );
  }

  Widget _buildProductionFooter(AppPalette palette) {
    return Column(
      children: [
        Text(
          'Sarkari Job Alert • v2.0.0 (OTA Enabled)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Direct Live Synchronization across 3 Portals',
          style: TextStyle(
            fontSize: 10,
            color: palette.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
