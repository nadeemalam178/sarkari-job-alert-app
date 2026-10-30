import 'dart:async';

import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'main_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode currentThemeMode;

  const SplashScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _taglineOpacityAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Shimmer effect animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      reverseDuration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Pulse animation for glow ring
    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.0,
              end: 1.15,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.15,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _titleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _taglineOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
    _checkNextScreen();
  }

  @override
  void dispose() {
    _animController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _checkNextScreen() async {
    final loggedIn = await StorageService.isLoggedIn();
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, anim, secAnim) => MainDashboardScreen(
            onThemeChanged: widget.onThemeChanged,
            currentThemeMode: widget.currentThemeMode,
          ),
          transitionsBuilder: (context, animation, secAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, anim, secAnim) => AuthScreen(
            onThemeChanged: widget.onThemeChanged,
            currentThemeMode: widget.currentThemeMode,
          ),
          transitionsBuilder: (context, animation, secAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Alert Crest with Shimmer
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2563EB),
                                const Color(0xFF0284C7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.3, 0.7],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF38BDF8),
                              width: 2.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.notifications_active_rounded,
                              size: 52,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        );
                      },
                    ),
                    // Pulsing glow ring
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title with staggered animation
                    AnimatedBuilder(
                      animation: _titleOpacityAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _titleOpacityAnimation.value,
                          child: Text(
                            'Sarkari Job Alert',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: palette.textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 6),

                    // Tagline with staggered animation
                    AnimatedBuilder(
                      animation: _taglineOpacityAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _taglineOpacityAnimation.value,
                          child: Text(
                            'Official Gazette & Recruitment Network',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 36),

                    // Animated loading bar
                    SizedBox(
                      width: 60,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _animController.value,
                          backgroundColor: palette.cardBorder,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
