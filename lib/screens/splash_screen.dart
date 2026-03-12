import 'package:flutter/material.dart';
import 'dart:async';
import '../models/app_colors.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.5)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_textController);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _logoController.forward().then((_) {
      _textController.forward();
    });

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0x1200E5FF), AppColors.bg],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _logoController,
                builder: (_, child) => Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accent2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🤟', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign',
                              style: TextStyle(color: AppColors.textColor),
                            ),
                            TextSpan(
                              text: 'Bridge',
                              style: TextStyle(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'AI Sign Language & Accessibility Platform',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              FadeTransition(
                opacity: _textOpacity,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
