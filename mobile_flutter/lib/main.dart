import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SarkariJobAlertApp());
}

class SarkariJobAlertApp extends StatefulWidget {
  const SarkariJobAlertApp({super.key});

  @override
  State<SarkariJobAlertApp> createState() => _SarkariJobAlertAppState();
}

class _SarkariJobAlertAppState extends State<SarkariJobAlertApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final modeStr = await StorageService.getThemeMode();
    if (mounted) {
      setState(() {
        if (modeStr == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (modeStr == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      });
    }
  }

  void _updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarkari Job Alert',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: SplashScreen(
        onThemeChanged: _updateThemeMode,
        currentThemeMode: _themeMode,
      ),
    );
  }
}
