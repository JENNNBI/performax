import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../widgets/avatar_3d_widget.dart';
import '../blocs/bloc_exports.dart';

/// Profile-Centric Home Screen
/// Displays user's 3D avatar, name, and grade level
/// This is the NEW primary landing screen focused on user profile
class ProfileHomeScreen extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileHomeScreen({
    super.key,
    required this.userProfile,
  });

  String _getGradeDisplayText(BuildContext context) {
    final languageBloc = context.read<LanguageBloc>();
    final isEnglish = languageBloc.currentLanguage == 'en';
    
    if (userProfile.gradeLevel == null || userProfile.gradeLevel!.isEmpty) {
      return isEnglish ? 'Grade not specified' : 'Sınıf belirtilmedi';
    }
    
    // Map grade values to display text
    final gradeMap = {
      '9': isEnglish ? '9th Grade' : '9. Sınıf',
      '10': isEnglish ? '10th Grade' : '10. Sınıf',
      '11': isEnglish ? '11th Grade' : '11. Sınıf',
      '12': isEnglish ? '12th Grade' : '12. Sınıf',
    };
    
    return gradeMap[userProfile.gradeLevel] ?? userProfile.gradeLevel!;
  }
  
  /// Capitalize first letter of user's name
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Build animated currency display with rocket icon
  Widget _buildAnimatedCurrencyDisplay(ThemeData theme, int finalAmount) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: finalAmount),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.9), // Gold
                const Color(0xFFFFA500).withValues(alpha: 0.85), // Orange
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rocket Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/currency_rocket1.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 24,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Animated Currency Value
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // "Rocket" Label
              Text(
                'Rocket',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final isEnglish = languageBloc.currentLanguage == 'en';
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor.withValues(alpha: 0.05),
                Colors.white,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false, // Don't apply SafeArea to bottom to respect BottomAppBar
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      // Welcome text
                      Text(
                        isEnglish ? 'Welcome!' : 'Hoş Geldin!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 3D Avatar - NO BOX, with Pedestal & Glow
                      // Always show avatar (uses default if avatarId is null)
                      TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.5 + (0.5 * value),
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Glow Effect Behind Avatar - ADJUSTED for expanded viewport
                                    Positioned(
                                      child: Container(
                                        width: 320, // Adjusted to match expanded model
                                        height: 320,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              theme.primaryColor.withValues(alpha: 0.3),
                                              theme.primaryColor.withValues(alpha: 0.15),
                                              theme.primaryColor.withValues(alpha: 0.05),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.4, 0.7, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // 3D Avatar Standing on Visual Stand - EXPANDED VIEWPORT
                                    // Using Stack to layer avatar ON TOP of stand asset
                                    SizedBox(
                                      width: 340, // EXPANDED from 320 to prevent clipping
                                      height: 480, // EXPANDED from 400 to show full head and feet
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        clipBehavior: Clip.none, // Allow overflow to prevent any clipping
                                        children: [
                                          // Stand Asset - BOTTOM LAYER
                                          Positioned(
                                            bottom: 0,
                                            child: Image.asset(
                                              'assets/images/stand.png',
                                              width: 220, // Slightly larger stand
                                              height: 220,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                // Fallback to gradient pedestal if stand.png fails
                                                return Container(
                                                  width: 180,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [
                                                        theme.primaryColor.withValues(alpha: 0.4),
                                                        theme.primaryColor.withValues(alpha: 0.2),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(100),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme.primaryColor.withValues(alpha: 0.3),
                                                        blurRadius: 15,
                                                        spreadRadius: 2,
                                                        offset: const Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          
                                          // 3D Avatar - TOP LAYER - ADJUSTED FOR PERFECT STAND PLACEMENT
                                          // CRITICAL: Wrap in error boundary to prevent crashes
                                          Positioned(
                                            bottom: 80, // ADJUSTED: Raised to sit perfectly on stand (increased from 40)
                                            child: Builder(
                                              builder: (context) {
                                                try {
                                                  return Avatar3DWidget(
                                                    avatar: userProfile.avatar,
                                                    size: 300, // ADJUSTED: Size for proper scale with 3.5m camera distance
                                                  );
                                                } catch (e, stackTrace) {
                                                  debugPrint('❌ FATAL ERROR creating Avatar3DWidget: $e');
                                                  debugPrint('Stack trace: $stackTrace');
                                                  // Return fallback avatar icon
                                                  return Container(
                                                    width: 300,
                                                    height: 300,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(150),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 120,
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      
                      const SizedBox(height: 12), // REDUCED SPACING: From 24 to 12 to bring user data closer
                      
                      // User Full Name - CENTERED beneath 3D model
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // User Name - CENTERED beneath 3D model
                                  Text(
                                    _capitalizeFirstLetter(userProfile.displayName),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      height: 1.2,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Grade Level and Rocket Currency - Side by side
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Grade Level Badge - beneath name
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.primaryColor,
                                              theme.primaryColor.withValues(alpha: 0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.primaryColor.withValues(alpha: 0.3),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.school_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _getGradeDisplayText(context),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 12),
                                      
                                      // Rocket Currency Display - to the right of grade level
                                      _buildAnimatedCurrencyDisplay(theme, userProfile.rocketCurrency),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

