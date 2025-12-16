import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/quest.dart';
import '../blocs/bloc_exports.dart';
import '../widgets/avatar_3d_widget.dart';
import '../widgets/quest_speech_bubble.dart';
import '../widgets/quest_list_widget.dart';
import '../services/quest_service.dart';

/// Profile-Centric Home Screen
/// Displays user's avatar, name, and grade level with interactive quest system
/// This is the NEW primary landing screen focused on user profile
class ProfileHomeScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileHomeScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<ProfileHomeScreen> createState() => _ProfileHomeScreenState();
}

class _ProfileHomeScreenState extends State<ProfileHomeScreen> with TickerProviderStateMixin {
  final QuestService _questService = QuestService();
  QuestData? _questData;
  bool _showSpeechBubble = true;
  bool _showQuestList = false;
  late AnimationController _avatarBounceController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _avatarBounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0, // Center position
      end: -120.0, // Slide left by 120px
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));
    _loadQuests();
  }

  @override
  void dispose() {
    _avatarBounceController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    try {
      final questData = await _questService.loadQuests();
      if (mounted) {
        setState(() {
          _questData = questData;
        });
        // Subscribe to quest updates for real-time progress
        _questService.stream.listen((data) {
          if (!mounted) return;
          setState(() => _questData = data);
        });
        // Reset state for test mode as requested
        _questService.resetAll();
      }
    } catch (e) {
      debugPrint('❌ Error loading quests: $e');
    }
  }

  void _toggleQuest() {
    try {
      // Trigger bounce animation
      _avatarBounceController.forward(from: 0.0).then((_) {
        _avatarBounceController.reverse();
      });

      setState(() {
        if (_showSpeechBubble && !_showQuestList) {
          // State A: First tap - Hide speech bubble, show quest list, slide avatar left
          _showSpeechBubble = false;
          _showQuestList = true;
          _slideController.forward(); // Slide avatar left
        } else if (_showQuestList && !_showSpeechBubble) {
          // State B: Second tap - Hide quest list, restore speech bubble, slide avatar center
          _showQuestList = false;
          _slideController.reverse(); // Slide avatar back to center
          if (_questData != null && _questData!.hasPendingQuests) {
            // Delay speech bubble appearance until slide animation completes
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_showQuestList) {
                setState(() {
                  _showSpeechBubble = true;
                });
              }
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error in _toggleQuest: $e');
    }
  }

  /// Build 3D avatar display with iOS Simulator compatibility and bounce animation
  Widget _build3DAvatar(ThemeData theme) {
    return AnimatedBuilder(
      animation: _avatarBounceController,
      builder: (context, child) {
        final bounce = Curves.elasticOut.transform(_avatarBounceController.value);
        return Transform.scale(
          scale: 1.0 + (bounce * 0.15), // Subtle bounce effect
          child: Transform.translate(
            offset: Offset(0, -bounce * 8), // Slight upward movement
            child: const Avatar3DWidget(
              assetPath: 'assets/avatars/3d/Creative_Character_free.glb',
              width: 280,
              height: 380,
            ),
          ),
        );
      },
    );
  }

  String _getGradeDisplayText(BuildContext context) {
    final languageBloc = context.read<LanguageBloc>();
    final isEnglish = languageBloc.currentLanguage == 'en';
    
    if (widget.userProfile.gradeLevel == null || widget.userProfile.gradeLevel!.isEmpty) {
      return isEnglish ? 'Grade not specified' : 'Sınıf belirtilmedi';
    }
    
    // Map grade values to display text
    final gradeMap = {
      '9': isEnglish ? '9th Grade' : '9. Sınıf',
      '10': isEnglish ? '10th Grade' : '10. Sınıf',
      '11': isEnglish ? '11th Grade' : '11. Sınıf',
      '12': isEnglish ? '12th Grade' : '12. Sınıf',
    };
    
    return gradeMap[widget.userProfile.gradeLevel] ?? widget.userProfile.gradeLevel!;
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
                      
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Background circle (bottom layer)
                          Positioned(
                            child: Container(
                              width: 320,
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
                          
                          // Avatar + Stand group (middle layer) - slides left/right
                          AnimatedBuilder(
                            animation: _slideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_slideAnimation.value, 0),
                                child: SizedBox(
                                  width: 340,
                                  height: 480,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Stand image at the bottom
                                      Positioned(
                                        bottom: 0,
                                        child: Image.asset(
                                          'assets/images/stand.png',
                                          width: 220,
                                          height: 220,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
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
                                      // Avatar positioned with feet on the platform stand
                                      Positioned(
                                        bottom: 80, // Fine-tuned for precise feet alignment on platform surface
                                        child: GestureDetector(
                                          onTap: () {
                                            try {
                                              debugPrint('🎮 Avatar tapped! Toggling quest...');
                                              _toggleQuest();
                                            } catch (e, stackTrace) {
                                              debugPrint('❌ Fatal error on avatar tap: $e');
                                              debugPrint('Stack trace: $stackTrace');
                                            }
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: 280,
                                            height: 380, // Increased to prevent model overflow
                                            color: Colors.transparent,
                                            child: IgnorePointer(
                                              child: _build3DAvatar(theme),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Speech Bubble (top layer) - positioned on far right, clear of avatar
                          if (_questData != null && _questData!.hasPendingQuests && _showSpeechBubble)
                            Positioned(
                              right: 20, // Far right with padding
                              top: 80,
                              child: DismissSpeechBubble(
                                dismiss: !_showSpeechBubble,
                                child: QuestSpeechBubble(
                                  message: 'Görevlerin var!',
                                  pendingCount: _questData!.pendingCount,
                                  show: _showSpeechBubble,
                                ),
                              ),
                            ),
                          
                          // Quest List Overlay (top layer) - FIXED POSITIONING to prevent "skinny column" bug
                          if (_showQuestList && _questData != null)
                            AnimatedBuilder(
                              animation: _slideAnimation,
                              builder: (context, child) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                
                                // Calculate if window should be visible based on slide progress
                                final slideProgress = (-_slideAnimation.value) / 120.0; // 0.0 to 1.0
                                
                                // MANDATORY FIX: Use fixed coordinates to prevent collapse
                                // LEFT: Start at 35% from left (window will be 65% width)
                                final leftPosition = screenWidth * 0.16;
                                
                                // Only show when avatar has slid left
                                if (slideProgress <= 0) {
                                  return const SizedBox.shrink(); // Hide when avatar is centered
                                }
                                
                                return Positioned(
                                  left: leftPosition,
                                  right: -24,
                                  top: 0,
                                  bottom: 0,
                                  child: QuestListWidget(
                                    questData: _questData!,
                                    onClose: _toggleQuest,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 24), // REDUCED SPACING: From 24 to 12 to bring user data closer
                      
                      // User Full Name - CENTERED beneath avatar
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
                                  // User Name - CENTERED beneath avatar
                                  Text(
                                    _capitalizeFirstLetter(widget.userProfile.displayName),
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
                                      _buildAnimatedCurrencyDisplay(theme, widget.userProfile.rocketCurrency),
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
