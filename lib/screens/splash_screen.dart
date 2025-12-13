import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'onboarding_screen.dart';
import 'first_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// Enhanced Splash screen with captivating fluid logo animation
class SplashScreen extends StatefulWidget {
  static const String id = 'splash_screen';
  
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Scale animation - logo grows smoothly
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    // Fade animation - logo fades in
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Pulse animation - continuous glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer animation - light sweep effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _initializeApp() async {
    // Give animations time to play
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    try {
      // Check if user has completed onboarding
      SharedPreferences? prefs;
      bool hasCompletedOnboarding = false;
      bool hasSeenFirstScreen = false;
      
      try {
        prefs = await SharedPreferences.getInstance();
        hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
        hasSeenFirstScreen = prefs.getBool('has_seen_first_screen') ?? false;
      } catch (e) {
        debugPrint('Error reading SharedPreferences: $e');
        // Continue with default values
      }
      
      // Check authentication status with error handling
      User? currentUser;
      try {
        // Wait a bit for Firebase to be fully initialized
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          currentUser = FirebaseAuth.instance.currentUser;
        }
      } catch (e) {
        debugPrint('Error checking Firebase Auth: $e');
        // Continue without user - will go to onboarding/login
        currentUser = null;
      }
      
      if (!mounted) return;
      
      // Fade out before navigation
      await _fadeController.reverse();
      
      if (!mounted) return;
      
      // Navigate to appropriate screen with proper error handling
      if (currentUser != null) {
        // User is logged in, go to home (streak check happens in HomeScreen)
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacementNamed(HomeScreen.id);
        }
      } else if (!hasCompletedOnboarding) {
        // First time user, show onboarding
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacementNamed(OnboardingScreen.id);
        }
      } else if (hasSeenFirstScreen) {
        // User has seen first screen before, go to login
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacementNamed(LoginScreen.id);
        }
      } else {
        // Show first screen
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacementNamed(FirstScreen.id);
        }
      }
    } catch (e, stackTrace) {
      // On error, go to onboarding with detailed logging
      debugPrint('Error during initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted && context.mounted) {
        try {
          Navigator.of(context).pushReplacementNamed(OnboardingScreen.id);
        } catch (navError) {
          debugPrint('Navigation error: $navError');
          // Last resort: try to navigate to first screen
          try {
            if (mounted && context.mounted) {
              Navigator.of(context).pushReplacementNamed(FirstScreen.id);
            }
          } catch (finalError) {
            debugPrint('Final navigation error: $finalError');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _scaleAnimation, _pulseAnimation, _shimmerAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                  theme.colorScheme.secondary,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(20, (index) {
                  final offset = (index * 0.1) % 1.0;
                  final size = 4.0 + (index % 3) * 2.0;
                  return Positioned(
                    left: (index * 47) % MediaQuery.of(context).size.width,
                    top: ((index * 83) % MediaQuery.of(context).size.height),
                    child: Opacity(
                      opacity: 0.1 + (_shimmerAnimation.value + offset) % 1.0 * 0.2,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
                
                // Main content
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated logo container with pulse effect
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3 * _pulseAnimation.value),
                                    blurRadius: 40 * _pulseAnimation.value,
                                    spreadRadius: 10 * _pulseAnimation.value,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Logo text
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        colors: const [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2),
                                          Color(0xFF667eea),
                                        ],
                                        stops: [
                                          (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                                          _shimmerAnimation.value.clamp(0.0, 1.0),
                                          (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: const Text(
                                      'Performax',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Animated tagline
                          Opacity(
                            opacity: _fadeAnimation.value * 0.9,
                            child: const Text(
                              'Akıllı Öğrenme Asistanı',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 60),
                          
                          // Modern SpinKit loading indicator
                          SpinKitPulsingGrid(
                            color: Colors.white,
                            size: 60.0,
                            duration: const Duration(milliseconds: 1200),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
