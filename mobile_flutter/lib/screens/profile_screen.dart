import 'package:flutter/material.dart';

import '../models/qualification.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/qualification_picker_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final List<Qualification> allQualifications;
  final List<String> selectedQualifications;
  final ValueChanged<List<String>> onQualificationsChanged;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode currentThemeMode;

  const ProfileScreen({
    super.key,
    required this.allQualifications,
    required this.selectedQualifications,
    required this.onQualificationsChanged,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<String> _currentQuals;
  late ThemeMode _themeMode;
  Map<String, String> _profileData = {};
  bool _isLoading = true;
  bool _pushNotifications = true;
  bool _admitCardAlerts = true;

  @override
  void initState() {
    super.initState();
    _currentQuals = List.from(widget.selectedQualifications);
    _themeMode = widget.currentThemeMode;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await StorageService.getCandidateProfile();
    final themeStr = await StorageService.getThemeMode();
    if (mounted) {
      setState(() {
        _profileData = data;
        _pushNotifications = data['notifEnabled'] == 'true';
        if (themeStr == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (themeStr == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
        _isLoading = false;
      });
    }
  }

  void _openQualificationPicker() {
    QualificationPickerSheet.show(
      context,
      allQualifications: widget.allQualifications.isNotEmpty
          ? widget.allQualifications
          : Qualification.defaultMasterList,
      initialSelected: _currentQuals,
      onSaved: (newSelected) async {
        await StorageService.setSelectedQualifications(newSelected);
        if (mounted) {
          setState(() => _currentQuals = newSelected);
        }
        widget.onQualificationsChanged(newSelected);
      },
    );
  }

  void _changeTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    String modeStr = 'system';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    await StorageService.setThemeMode(modeStr);
    widget.onThemeChanged(mode);
  }

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _profileData['name'] ?? '');
    final emailCtrl = TextEditingController(text: _profileData['email'] ?? '');
    final phoneCtrl = TextEditingController(text: _profileData['phone'] ?? '');
    final catCtrl = TextEditingController(text: _profileData['category'] ?? '');
    final stateCtrl = TextEditingController(text: _profileData['state'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = AppPalette.of(ctx);
        return AlertDialog(
          backgroundColor: palette.surfaceGlassHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: palette.cardBorder),
          ),
          title: Text(
            'Edit Candidate Info',
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField('Full Name', nameCtrl, palette),
                const SizedBox(height: 12),
                _buildDialogField('Email Address', emailCtrl, palette),
                const SizedBox(height: 12),
                _buildDialogField('Mobile Number', phoneCtrl, palette),
                const SizedBox(height: 12),
                _buildDialogField('Category (e.g. OBC / General)', catCtrl, palette),
                const SizedBox(height: 12),
                _buildDialogField('Target State / Region', stateCtrl, palette),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: palette.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accentBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Details', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await StorageService.updateCandidateProfile(
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
        category: catCtrl.text,
        state: stateCtrl.text,
        notifEnabled: _pushNotifications,
      );
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidate profile updated successfully')),
        );
      }
    }
  }

  Widget _buildDialogField(String label, TextEditingController ctrl, AppPalette palette) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: palette.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.textSecondary, fontSize: 13),
        filled: true,
        fillColor: palette.isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = AppPalette.of(ctx);
        return AlertDialog(
          backgroundColor: palette.surfaceGlassHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: palette.cardBorder),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: palette.accentRed, size: 24),
              const SizedBox(width: 8),
              Text('Log Out', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            'Are you sure you want to log out? You will be returned to the account login & registration section.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: palette.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accentRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await StorageService.logout();
      if (mounted) {
        Navigator.pop(context, true); // Return true indicating logout
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Candidate Profile',
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: palette.accentBlue, size: 22),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: palette.accentBlue))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              children: [
                // 1. Candidate Avatar & Primary Badge
                _buildCandidateHeader(palette),
                const SizedBox(height: 20),

                // 2. Candidate Identity & Details Card
                _buildCandidateDetailsCard(palette),
                const SizedBox(height: 20),

                // 3. Qualifications & Eligibility (THE ONLY PLACE)
                _buildQualificationsSection(palette),
                const SizedBox(height: 24),

                // 4. App Settings (Theme Auto-Select, Notifications)
                _buildAppSettingsSection(palette),
                const SizedBox(height: 24),

                // 5. Account Actions (Log Out)
                _buildLogoutSection(palette),
                const SizedBox(height: 24),

                // 6. Production App Metadata
                _buildProductionFooter(palette),
              ],
            ),
    );
  }

  Widget _buildCandidateHeader(AppPalette palette) {
    final name = _profileData['name'] ?? 'Nadeem Khan';
    final state = _profileData['state'] ?? 'All India Aspirant';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: palette.glassDecoration(radius: 24),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 38, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x3310B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reg ID: REG-2026-IND-8841',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: palette.accentCyan,
                    fontWeight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: palette.glassDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Candidate Credentials',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              InkWell(
                onTap: _showEditProfileDialog,
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: palette.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailRow(Icons.email_outlined, 'Email', _profileData['email'] ?? 'aspirant@sarkarialert.in', palette),
          Divider(color: palette.cardBorder, height: 18),
          _buildDetailRow(Icons.phone_android_outlined, 'Phone', _profileData['phone'] ?? '+91 98765 43210', palette),
          Divider(color: palette.cardBorder, height: 18),
          _buildDetailRow(Icons.badge_outlined, 'Category', _profileData['category'] ?? 'General / OBC', palette),
          Divider(color: palette.cardBorder, height: 18),
          _buildDetailRow(Icons.place_outlined, 'Target Region', _profileData['state'] ?? 'All India Central & States', palette),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, AppPalette palette) {
    return Row(
      children: [
        Icon(icon, size: 18, color: palette.accentBlue),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: palette.textSecondary, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
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

  // Sole place for qualification selection
  Widget _buildQualificationsSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: palette.glassDecoration(
        radius: 20,
        customBorder: palette.accentBlue.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.accentBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_rounded, color: palette.accentBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eligibility & Qualifications',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_currentQuals.length} qualifications active for matching',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openQualificationPicker,
                icon: const Icon(Icons.tune_rounded, size: 14, color: Colors.white),
                label: const Text('Change', style: TextStyle(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accentBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Your matched Sarkari alerts (including RRB NTPC, SSC CGL, BPSC) are filtered by these degrees:',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentQuals.map((q) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.isDark ? const Color(0xFF1E2D44) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      q,
                      style: TextStyle(
                        fontSize: 11.5,
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

  // App Settings: System Theme Auto-Select, Notification Preferences
  Widget _buildAppSettingsSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: palette.glassDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Theme Mode Selector
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: palette.accentBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Theme',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'System auto-select is active',
                      style: TextStyle(fontSize: 11, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-way Segmented Button: System (Auto) / Dark / Light
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.isDark ? const Color(0xFF0A0F1D) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 16),
          Divider(color: palette.cardBorder),

          // Notifications Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.white,
            activeTrackColor: palette.accentBlue,
            value: _pushNotifications,
            title: Text(
              'Recruitment Push Alerts',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: palette.textPrimary),
            ),
            subtitle: Text(
              'Instant alert when new vacancies are released',
              style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.white,
            activeTrackColor: palette.accentBlue,
            value: _admitCardAlerts,
            title: Text(
              'Admit Card & Exam Date Alerts',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: palette.textPrimary),
            ),
            subtitle: Text(
              'Hall tickets, exam city slips & Sarkari Result updates',
              style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
            ),
            onChanged: (val) => setState(() => _admitCardAlerts = val),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? palette.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : palette.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
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
        icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
        label: const Text(
          'Log Out Candidate Account',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEF4444),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: palette.surfaceGlass,
        ),
      ),
    );
  }

  Widget _buildProductionFooter(AppPalette palette) {
    return Column(
      children: [
        Text(
          'Sarkari Job Alert • Production v1.0.0',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Official Gazette & Sarkari Result Direct Sync',
          style: TextStyle(
            fontSize: 10.5,
            color: palette.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
