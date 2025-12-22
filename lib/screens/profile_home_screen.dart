import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/quest.dart';
import '../blocs/bloc_exports.dart';
import '../widgets/avatar_3d_widget.dart';
import '../widgets/quest_speech_bubble.dart';
import '../widgets/quest_list_widget.dart';
import '../services/quest_service.dart';
import '../services/quest_celebration_coordinator.dart';
import '../services/currency_service.dart';

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
  final GlobalKey _rocketIconKey = GlobalKey();
  int _displayedRocketCurrency = 0;
  int _lastAnimatedCurrency = 0;
  late AnimationController _avatarBounceController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late AnimationController _rocketIconBounceController;
  late Animation<double> _rocketIconBounce;
  bool _rocketIconControllerDisposed = false;

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
    _slideController.value = 0.0;
    _avatarBounceController.value = 0.0;
    _loadQuests();
    CurrencyService.instance.loadBalance(widget.userProfile).then((balance) {
      if (!mounted) return;
      setState(() {
        _displayedRocketCurrency = balance;
        _lastAnimatedCurrency = balance;
      });
    });
    _rocketIconBounceController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _rocketIconBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _rocketIconBounceController, curve: Curves.easeOutBack),
    );
  }

  bool get _hasUnclaimedRewards {
    if (_questData == null) return false;
    final d = _questData!;
    bool anyClaimable(List<Quest> list) => list.any((q) => q.isClaimable);
    return anyClaimable(d.dailyQuests) || anyClaimable(d.weeklyQuests) || anyClaimable(d.monthlyQuests);
  }

  @override
  void dispose() {
    _avatarBounceController.dispose();
    _slideController.dispose();
    _rocketIconControllerDisposed = true;
    _rocketIconBounceController.dispose();
    QuestCelebrationCoordinator.instance.unregisterHome();
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
        QuestCelebrationCoordinator.instance.registerHome(
          context,
          _rocketIconKey,
          _openQuestListIfHidden,
          _animateCurrencyIncrement,
          _bounceRocketIcon,
        );
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
        if (!_showQuestList) {
          _showQuestList = true;
          _slideController.forward();
        } else {
          _showQuestList = false;
          _slideController.reverse();
        }
      });
    } catch (e) {
      debugPrint('❌ Error in _toggleQuest: $e');
    }
  }
  void _openQuestListIfHidden() {
    if (!_showQuestList) {
      setState(() {
        _showSpeechBubble = false;
        _showQuestList = true;
      });
      _slideController.forward();
    }
  }
  void _animateCurrencyIncrement(int delta) {
    final prev = _displayedRocketCurrency;
    final next = prev + delta;
    setState(() {
      _lastAnimatedCurrency = prev;
      _displayedRocketCurrency = next;
    });
    CurrencyService.instance.add(widget.userProfile, delta);
  }
  void _bounceRocketIcon() {
    if (!mounted) return;
    if (_rocketIconControllerDisposed) return;
    _rocketIconBounceController.forward(from: 0.0).then((_) {
      if (!mounted || _rocketIconControllerDisposed) return;
      _rocketIconBounceController.reverse();
    });
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
      tween: IntTween(begin: _lastAnimatedCurrency, end: finalAmount),
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
                child: Container(
                  key: _rocketIconKey,
                  child: ScaleTransition(
                    scale: _rocketIconBounce,
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
                                      // Red dot indicator for unclaimed rewards
                                      if (_hasUnclaimedRewards)
                                        Positioned(
                                          right: 12,
                                          top: 12,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.red,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red.withValues(alpha: 0.4),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Speech Bubble (top layer) - positioned on far right, hides when quest list open
                          Positioned(
                            right: 20,
                            top: 80,
                            child: _showQuestList
                                ? const SizedBox.shrink()
                                : QuestSpeechBubble(
                                    message: (() {
                                      final remainingDaily = _questData?.dailyQuests.where((q) => !q.isCompleted).length ?? 0;
                                      return remainingDaily > 0 ? 'Günlük görevlerin var!' : 'Bugün bütün günlük görevlerimi yaptım!';
                                    })(),
                                    pendingCount: _questData?.dailyQuests.where((q) => !q.isCompleted).length ?? 0,
                                    show: true,
                                  ),
                          ),
                          
                          // Quest List Overlay (top layer) - emergency fallback to force render
                          Positioned.fill(
                            child: Visibility(
                              visible: _showQuestList,
                              child: QuestListWidget(
                                questData: _questData ?? const QuestData(dailyQuests: [], weeklyQuests: [], monthlyQuests: []),
                                onClose: _toggleQuest,
                              ),
                            ),
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
                                      _buildAnimatedCurrencyDisplay(theme, _displayedRocketCurrency),
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
