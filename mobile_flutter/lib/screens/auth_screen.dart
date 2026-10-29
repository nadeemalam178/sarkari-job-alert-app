import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
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
  bool _isSignUp = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedDegree = 'B.SC';

  @override
  void initState() {
    super.initState();
    // Prompt Android system runtime permission for notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermission();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        final name = _nameCtrl.text.trim();
        final phone = _phoneCtrl.text.trim();

        if (name.isEmpty) {
          _showError('Please enter your full name');
          setState(() => _isLoading = false);
          return;
        }

        if (phone.isEmpty || phone.length < 10) {
          _showError('Please enter a valid 10-digit mobile number');
          setState(() => _isLoading = false);
          return;
        }

        // Register in local store
        final localRes = await StorageService.registerNewAccount(
          name: name,
          email: email,
          password: password,
          phone: phone,
          qualification: _selectedDegree,
        );

        if (localRes['success'] != true) {
          _showError(localRes['error'] ?? 'Registration failed');
          setState(() => _isLoading = false);
          return;
        }

        // Also register in backend database asynchronously
        ApiService.register(
          name: name,
          email: email,
          password: password,
          phone: phone,
          highestQualification: _selectedDegree,
          qualifications: [_selectedDegree, if (_selectedDegree == 'B.SC') 'GRADUATE', '12TH / 10+2'],
        ).catchError((_) => {'success': false});
      } else {
        // Sign In
        // Try backend login first, fallback to local registered accounts
        var loginRes = await ApiService.login(email: email, password: password);

        if (loginRes['success'] == true) {
          final user = loginRes['user'] ?? {};
          await StorageService.updateCandidateProfile(
            name: user['name'] ?? 'Candidate',
            email: email,
            phone: user['phone'] ?? '',
            qualification: user['highest_qualification'] ?? 'GRADUATE',
          );
          await StorageService.setLoggedIn(true);
        } else {
          // Verify with local registered store
          final localLogin = await StorageService.loginAccount(
            email: email,
            password: password,
          );

          if (localLogin['success'] != true) {
            _showError(localLogin['error'] ?? 'Account does not exist. Please create an account first.');
            setState(() => _isLoading = false);
            return;
          }
        }
      }

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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Emblem
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: palette.isDark
                            ? const [Color(0xFF45404F), Color(0xFF292531)]
                            : const [Color(0xFF716879), Color(0xFF45404F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: palette.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 38,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Sarkari Job Alert',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'Official Government Recruitment Portal',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Segmented Switch: Create Account vs Sign In
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: palette.surfaceGlass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isSignUp = true),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isSignUp
                                    ? (palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w500,
                                  color: _isSignUp
                                      ? (palette.isDark ? const Color(0xFFF3EEF8) : Colors.white)
                                      : palette.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isSignUp = false),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isSignUp
                                    ? (palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Sign In',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                                  color: !_isSignUp
                                      ? (palette.isDark ? const Color(0xFFF3EEF8) : Colors.white)
                                      : palette.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: palette.glassDecoration(radius: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSignUp) ...[
                          _buildFieldLabel('Full Name', palette),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _nameCtrl,
                            hint: 'Enter your legal full name',
                            icon: Icons.person_outline_rounded,
                            palette: palette,
                          ),
                          const SizedBox(height: 14),
                        ],

                        _buildFieldLabel('Email Address', palette),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _emailCtrl,
                          hint: 'aspirant@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          palette: palette,
                        ),
                        const SizedBox(height: 14),

                        if (_isSignUp) ...[
                          _buildFieldLabel('Mobile Number', palette),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _phoneCtrl,
                            hint: '10-digit mobile number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            palette: palette,
                          ),
                          const SizedBox(height: 14),

                          _buildFieldLabel('Highest Qualification Stream', palette),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: palette.isDark ? const Color(0xFF17151C) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDegree,
                                isExpanded: true,
                                dropdownColor: palette.isDark ? const Color(0xFF292531) : Colors.white,
                                items: const [
                                  DropdownMenuItem(value: 'B.SC', child: Text('B.Sc (Bachelor of Science)')),
                                  DropdownMenuItem(value: 'GRADUATE', child: Text('Graduate (Any Degree / BA / BCom)')),
                                  DropdownMenuItem(value: '12TH / 10+2', child: Text('12th Pass / Intermediate')),
                                  DropdownMenuItem(value: '10TH', child: Text('10th Pass / Matriculation')),
                                  DropdownMenuItem(value: 'B.TECH / B.E', child: Text('B.Tech / B.E (Engineering)')),
                                  DropdownMenuItem(value: 'B.ED', child: Text('B.Ed / Teaching Degree')),
                                  DropdownMenuItem(value: 'POST GRADUATE', child: Text('Post Graduate / Master Degree')),
                                  DropdownMenuItem(value: 'DIPLOMA', child: Text('Polytechnic / Diploma')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedDegree = val);
                                },
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        _buildFieldLabel('Password', palette),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _passwordCtrl,
                          hint: 'Enter your secure password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          palette: palette,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: palette.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submitAuth,
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.isDark ? const Color(0xFF45404F) : const Color(0xFF292531),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _isSignUp ? 'Create Candidate Account' : 'Sign In to Portal',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Direct access to RRB, SSC, UPSC & State PSC Vacancies',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, AppPalette palette) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required AppPalette palette,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: palette.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.5, color: palette.textSecondary.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, size: 18, color: palette.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: palette.isDark ? const Color(0xFF17151C) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accentPrimary, width: 1.5),
        ),
      ),
    );
  }
}
