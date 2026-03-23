import 'package:flutter/material.dart';
import 'package:social_media_app/main.dart'; // Import main.dart to get AuthGate
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

// This screen is the very first thing the user sees. It displays a beautiful
// animation and then navigates to the correct starting screen of the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Multiple AnimationControllers are used to manage different parts of the
  // complex entry animation sequence.
  late AnimationController _logoController, _glowController, _textController, _loadController;
  late Animation<double> _logoScale, _logoOpacity, _glowRadius, _textOpacity, _loadProgress;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Sets the status bar style for a clean, immersive look.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // --- All Animation Controllers are initialized here --- 
    // Each controller manages the timing and duration for a specific UI element.

    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 20, end: 60).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _loadController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _loadProgress = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _loadController, curve: Curves.easeInOut));

    // This function starts the animation sequence when the screen is first built.
    _startSequence();
  }

  // This function orchestrates the animations in a timed sequence.
  Future<void> _startSequence() async {
    // A series of timed delays to ensure animations happen in the right order.
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _loadController.forward();

    // CRITICAL STEP: After the animations are complete, this is where the app moves on.
    // Instead of navigating to a hardcoded home screen, it navigates to our 'AuthGate'.
    // The AuthGate is a special widget that will decide which screen to show next
    // based on the user's login status.
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  void dispose() {
    // It's very important to dispose of controllers to prevent memory leaks.
    _logoController.dispose();
    _glowController.dispose();
    _textController.dispose();
    _loadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, radius: 1.2,
            colors: [Color(0xFF1A0A2E), Color(0xFF0A0A0F)],
          ),
        ),
        child: Stack(
          children: [
            ..._buildParticleDots(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Each animated element is wrapped in an AnimatedBuilder or a similar widget
                // that rebuilds the UI whenever the animation value changes.
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _glowController]),
                  builder: (_, __) {
                    return FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFCC44FF).withOpacity(0.5), blurRadius: _glowRadius.value, spreadRadius: _glowRadius.value * 0.3),
                              BoxShadow(color: const Color(0xFFFF44AA).withOpacity(0.3), blurRadius: _glowRadius.value * 1.5, spreadRadius: _glowRadius.value * 0.1),
                            ],
                          ),
                          child: ClipOval(child: Image.asset('assets/images/icon.png', fit: BoxFit.cover)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(text: 'GAME', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 6)),
                              TextSpan(text: 'FEED', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Play. Share. Dominate.', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, letterSpacing: 2, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _loadProgress,
                        builder: (_, __) {
                          return Column(
                            children: [
                              Container(
                                height: 3,
                                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _loadProgress.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [AppTheme.accentPink, AppTheme.accent]),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.6), blurRadius: 6)],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _loadProgress.value < 0.4 ? 'Loading assets...' : _loadProgress.value < 0.8 ? 'Connecting to servers...' : 'Ready!',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, letterSpacing: 1),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // This helper method builds the decorative background dots.
  List<Widget> _buildParticleDots() {
    final positions = [[0.1, 0.1], [0.9, 0.15], [0.05, 0.5], [0.95, 0.45], [0.2, 0.85], [0.8, 0.8], [0.5, 0.05], [0.3, 0.95], [0.7, 0.92], [0.15, 0.65], [0.85, 0.6]];
    return positions.map((pos) {
      return Positioned(
        left: MediaQuery.of(context).size.width * pos[0],
        top: MediaQuery.of(context).size.height * pos[1],
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (_, __) => Opacity(opacity: 0.15 + (_glowController.value * 0.25), child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle))),
        ),
      );
    }).toList();
  }
}
