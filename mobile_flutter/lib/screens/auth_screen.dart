import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'main_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode currentThemeMode;

  const AuthScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = true; // Opens at create account section as requested!

  final _nameCtrl = TextEditingController(text: 'Nadeem Khan');
  final _emailCtrl = TextEditingController(text: 'nadeem.aspirant@sarkarialert.in');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _passwordCtrl = TextEditingController(text: 'Sarkari@2026');
  String _selectedDegree = 'B.SC';
  bool _notificationsPermissionGranted = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _quickFillDemo() {
    setState(() {
      _emailCtrl.text = 'nadeem.aspirant@sarkarialert.in';
      _passwordCtrl.text = 'Sarkari@2026';
      _nameCtrl.text = 'Nadeem Khan';
      _phoneCtrl.text = '+91 98765 43210';
      _selectedDegree = 'B.SC';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-inserted Candidate credentials & phone number'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitAuth() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (email.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid credentials')),
      );
      return;
    }

    // Save profile with selected qualification (B.SC included)
    await StorageService.updateCandidateProfile(
      name: name.isNotEmpty ? name : 'Nadeem Khan',
      email: email,
      phone: phone.isNotEmpty ? phone : '+91 98765 43210',
      category: 'General / OBC',
      state: 'Central & All India States',
      notifEnabled: _notificationsPermissionGranted,
    );

    // Ensure B.SC & Graduate are selected in qualifications
    await StorageService.setSelectedQualifications([
      _selectedDegree,
      if (_selectedDegree == 'B.SC') 'GRADUATE',
      '12TH / 10+2',
    ]);

    await StorageService.setLoggedIn(true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => MainDashboardScreen(
            onThemeChanged: widget.onThemeChanged,
            currentThemeMode: widget.currentThemeMode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // 1. Logo & App Branding Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 40,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Sarkari Job Alert',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Govt Recruitment & Gazette Engine',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Active Credentials Card (Directly lists credentials requested)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: palette.isDark ? 0.7 : 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.key_rounded, size: 18, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        Text(
                          'Your Demo Candidate Credentials',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: palette.isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _quickFillDemo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Auto-Fill',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF60A5FA),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildCredRow('Candidate ID', 'nadeem.aspirant@sarkarialert.in'),
                    const SizedBox(height: 4),
                    _buildCredRow('Password', 'Sarkari@2026'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Segmented Tab Selector: Create Account vs Sign In
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.isDark ? const Color(0xFF131D2E) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignUp ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isSignUp ? Colors.white : palette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: !_isSignUp ? Colors.white : palette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Glassmorphic Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: palette.glassDecoration(radius: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Google 1-Tap Auto-Insert Pill
                    if (_isSignUp) ...[
                      InkWell(
                        onTap: _quickFillDemo,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: palette.isDark ? 0.8 : 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.g_mobiledata_rounded, color: Color(0xFF10B981), size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Google Account Verified',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF34D399)),
                                    ),
                                    Text(
                                      'Auto-insert phone number & email',
                                      style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Name Field
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Candidate Full Name',
                        icon: Icons.person_outline_rounded,
                        palette: palette,
                      ),
                      const SizedBox(height: 12),

                      // Phone Field (Automatic insertion)
                      _buildTextField(
                        controller: _phoneCtrl,
                        label: 'Mobile Number (for SMS & OTP Alerts)',
                        icon: Icons.phone_android_rounded,
                        palette: palette,
                        suffix: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(height: 12),

                      // Degree Stream Picker
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.isDark ? const Color(0xFF0A0F1D) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDegree,
                            dropdownColor: palette.isDark ? const Color(0xFF131D2E) : Colors.white,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            icon: Icon(Icons.arrow_drop_down_rounded, color: palette.accentBlue),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'B.SC', child: Text('B.Sc (Bachelor of Science) - All RRB & UPSC')),
                              DropdownMenuItem(value: 'GRADUATE', child: Text('Graduate in Any Stream (BA / B.Com / B.Tech)')),
                              DropdownMenuItem(value: 'B.TECH / B.E', child: Text('B.Tech / B.E (Engineering)')),
                              DropdownMenuItem(value: '12TH / 10+2', child: Text('12th Pass / Intermediate')),
                              DropdownMenuItem(value: '10TH', child: Text('10th Pass / High School')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDegree = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Email Field
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Email Address / Candidate ID',
                      icon: Icons.email_outlined,
                      palette: palette,
                    ),
                    const SizedBox(height: 12),

                    // Password Field
                    _buildTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      palette: palette,
                    ),
                    const SizedBox(height: 14),

                    // System Notification Permission checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _notificationsPermissionGranted,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (v) => setState(() => _notificationsPermissionGranted = v ?? true),
                        ),
                        Expanded(
                          child: Text(
                            'Grant Android system notification permission for instant vacancy alerts',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: _submitAuth,
                      child: Text(
                        _isSignUp ? 'Create Account & Start Matching' : 'Sign In to Portal',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Production footer
              Center(
                child: Text(
                  'Verified Gazette & Official Recruitment Network • India',
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredRow(String label, String val) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
        Text(
          val,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            color: Color(0xFF38BDF8),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppPalette palette,
    bool isPassword = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.textSecondary, fontSize: 12.5),
        prefixIcon: Icon(icon, color: palette.accentBlue, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: palette.isDark ? const Color(0xFF0A0F1D) : Colors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
      ),
    );
  }
}
