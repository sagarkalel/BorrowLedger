import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
  late AnimationController _particleController;

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

    // Particle controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
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

    // Start particle animation
    _particleController.forward();

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
    _particleController.dispose();
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
              AppTheme.primaryGreen.withValues(alpha: 0.9),
              AppTheme.primaryGreen.withValues(alpha: 0.7),
              AppTheme.lightGreen.withValues(alpha: 0.6),
              AppTheme.primaryBlue.withValues(alpha: 0.75),
              AppTheme.primaryBlue.withValues(alpha: 0.9),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Radial gradient overlay for depth
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Animated background particles
            ...List.generate(8, (index) {
              return _buildFloatingCircle(index);
            }),

            // Additional decorative elements
            ...List.generate(12, (index) {
              return _buildParticle(index);
            }),

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

                  const SizedBox(height: 48),

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

                  const SizedBox(height: 40),

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
            text: "Borrow",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(255, 132, 185, 71)
                  : Color.fromARGB(255, 115, 182, 21),
            ),
          ),
          TextSpan(
            text: "Ledger",
            style: TextStyle(color: Color.fromARGB(255, 71, 158, 206)),
          ),
        ],
      ),
      // 'BorrowLedger',
      style: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        // color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
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
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // color: AppTheme.lightGreen,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.lightGreen, width: 1),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/borrow_ledger_icon.jpeg',
                  width: 154,
                  height: 154,
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
                          Icons.menu_book_rounded,
                          size: 70,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    );
                  },
                ),
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
          return const CupertinoActivityIndicator(
            radius: 16,
            color: Colors.white,
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
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
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
        fontSize: 14,
        color: Colors.white,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFloatingCircle(int index) {
    final random = math.Random(index);
    final size = 80.0 + random.nextDouble() * 140;
    final duration = 4000 + random.nextInt(3000);
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;

    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: duration),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: (0.08 + math.sin(value * math.pi * 2) * 0.08).clamp(
              0.0,
              0.15,
            ),
            child: Transform.translate(
              offset: Offset(
                math.sin(value * math.pi * 2) * 30,
                math.cos(value * math.pi * 2) * 30,
              ),
              child: Transform.scale(
                scale: 1.0 + math.sin(value * math.pi * 4) * 0.1,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        onEnd: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index + 100);
    final size = 3.0 + random.nextDouble() * 6;
    final duration = 2000 + random.nextInt(2000);
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    final delay = random.nextInt(1000);

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final adjustedValue =
              ((_particleController.value * duration + delay) % duration) /
              duration;
          return Opacity(
            opacity: (math.sin(adjustedValue * math.pi)).clamp(0.0, 0.6),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
