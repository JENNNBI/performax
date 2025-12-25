import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'onboarding_screen.dart';
import 'first_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';

/// Enhanced Splash screen with Neumorphic logo animation
class SplashScreen extends StatefulWidget {
  static const String id = 'splash_screen';
  
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    try {
      SharedPreferences? prefs;
      bool hasCompletedOnboarding = false;
      bool hasSeenFirstScreen = false;
      
      try {
        prefs = await SharedPreferences.getInstance();
        hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
        hasSeenFirstScreen = prefs.getBool('has_seen_first_screen') ?? false;
      } catch (e) {
        debugPrint('Error reading SharedPreferences: $e');
      }
      
      User? currentUser;
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          currentUser = FirebaseAuth.instance.currentUser;
        }
      } catch (e) {
        debugPrint('Error checking Firebase Auth: $e');
        currentUser = null;
      }
      
      if (!mounted) return;
      await _fadeController.reverse();
      if (!mounted) return;
      
      if (currentUser != null) {
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacementNamed(HomeScreen.id);
        }
      } else if (!hasCompletedOnboarding) {
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacementNamed(OnboardingScreen.id);
        }
      } else if (hasSeenFirstScreen) {
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacementNamed(LoginScreen.id);
        }
      } else {
        if (mounted && context.mounted) {
          Navigator.of(context).pushReplacementNamed(FirstScreen.id);
        }
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      if (mounted && context.mounted) {
        Navigator.of(context).pushReplacementNamed(OnboardingScreen.id);
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use light theme background for splash or a brand color
    // Let's use the standard background to be consistent
    final bgColor = NeumorphicColors.backgroundLight; 
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Neumorphic Logo Container
                NeumorphicContainer(
                  padding: const EdgeInsets.all(40),
                  borderRadius: 40,
                  depth: 10,
                  color: bgColor,
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 80,
                        color: NeumorphicColors.accentBlue,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Performax',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: NeumorphicColors.textLight,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Loading
                SpinKitPulsingGrid(
                  color: NeumorphicColors.accentBlue,
                  size: 50.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
