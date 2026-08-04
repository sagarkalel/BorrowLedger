import 'dart:async';
import 'dart:io';

import 'package:borrow_ledger/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();

    // Main animation controller for logo entrance
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse effect controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Scale animation with bounce
    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.75, curve: Curves.elasticOut),
      ),
    );

    // Slide up animation
    _slideAnimation = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Pulse animation - very subtle
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text fade in
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    // Text slide up
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Start animations in sequence
    _startAnimations();

    // Navigate to main screen after delay
    _schedule(const Duration(milliseconds: 4500), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  void _schedule(Duration duration, VoidCallback callback) {
    _timers.add(
      Timer(duration, () {
        if (mounted) {
          callback();
        }
      }),
    );
  }

  void _startAnimations() {
    // Start main animation
    _mainController.forward();

    // Start pulse effect
    _schedule(const Duration(milliseconds: 1200), () {
      _pulseController.repeat(reverse: true);
    });

    // Start text animation
    _schedule(const Duration(milliseconds: 1600), () {
      _textController.forward();
    });

    // Start progress animation
    _schedule(const Duration(milliseconds: 2200), () {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _mainController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF7FBFA),
              const Color(0xFFEFF7F5),
              AppTheme.lightGreen.withValues(alpha: 0.14),
              AppTheme.primaryBlue.withValues(alpha: 0.12),
            ],
            stops: const [0.0, 0.45, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Radial gradient overlay for depth
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.18),
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.86),
                      Colors.white.withValues(alpha: 0.42),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _buildAnimatedLogo(),
                  ),

                  const SizedBox(height: 34),

                  // Animated text
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          // App name - clean and minimal
                          _buildAppTitle(),

                          const SizedBox(height: 12),

                          // Tagline - minimal
                          _buildTagline(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  // Loading indicator - minimal
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: _buildLoadingIndicator(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "Hisaab",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(255, 132, 185, 71)
                  : Color.fromARGB(255, 115, 182, 21),
            ),
          ),
          TextSpan(
            text: "Mate",
            style: TextStyle(color: Color.fromARGB(255, 71, 158, 206)),
          ),
        ],
      ),
      // 'HisaabMate',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  blurRadius: 22,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.72),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Image.asset(
                'assets/images/hisaab_mate_icon.png',
                width: 148,
                height: 148,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.lightGreen,
                          AppTheme.primaryBlue,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.currency_rupee_rounded,
                        size: 70,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    final isIOS = Platform.isIOS;

    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        if (isIOS) {
          return CupertinoActivityIndicator(
            radius: 16,
            color: AppTheme.primaryGreen,
          );
        } else {
          return Column(
            children: [
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.14,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGreen,
                    ),
                    minHeight: 3,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildTagline() {
    final tr = AppLocalizations.of(context)!;
    return Text(
      tr.appSlogan,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
