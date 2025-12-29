import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../models/user_profile.dart';
import '../services/user_provider.dart'; // Import UserProvider
import '../models/quest.dart';
import '../blocs/bloc_exports.dart';
import '../widgets/quest_speech_bubble.dart';
import '../widgets/quest_list_widget.dart';
import '../widgets/ai_assistant_widget.dart'; // Import AI Assistant
import '../services/quest_service.dart';
import '../services/quest_celebration_coordinator.dart';
import '../services/currency_service.dart';
import '../theme/neumorphic_colors.dart';

/// Profile-Centric Home Screen
/// Redesigned to match "Futuristic Blue" theme (image_5.png) with dynamic background support
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
  bool _showQuestList = false;
  final GlobalKey _rocketIconKey = GlobalKey();
  // Removed unused _displayedRocketCurrency and _lastAnimatedCurrency fields
  
  late AnimationController _avatarBounceController;
  late AnimationController _slideController;
  
  // ignore: unused_field
  late Animation<double> _slideAnimation;
  
  // ignore: unused_field
  late AnimationController _rocketIconBounceController;
  // ignore: unused_field
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
      begin: 0.0, 
      end: -120.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));
    _slideController.value = 0.0;
    _avatarBounceController.value = 0.0;
    
    _loadQuests();
    // Load rocket currency balance (for display purposes)
    CurrencyService.instance.loadBalance(widget.userProfile).then((balance) {
      if (!mounted) return;
      // Balance loaded successfully - no need to store in removed fields
    });
    
    _rocketIconBounceController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _rocketIconBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _rocketIconBounceController, curve: Curves.easeOutBack),
    );
  }

  // ignore: unused_element
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
        _showQuestList = true;
      });
      _slideController.forward();
    }
  }
  
  void _animateCurrencyIncrement(int delta) {
    // ✅ FIXED: Removed obsolete hardcoded reward logic
    // The new system uses QuestService.claimById() which correctly applies
    // the exact reward amount from quest.reward (e.g., 10, not 20)
    // 
    // This callback is now only used for UI bounce animation
    // The actual currency addition happens in QuestService.claimById()
    
    debugPrint('🎨 Currency animation triggered with delta: $delta');
  }
  
  void _bounceRocketIcon() {
    if (!mounted) return;
    if (_rocketIconControllerDisposed) return;
    _rocketIconBounceController.forward(from: 0.0).then((_) {
      if (!mounted || _rocketIconControllerDisposed) return;
      _rocketIconBounceController.reverse();
    });
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final languageBloc = context.read<LanguageBloc>();
    final isEnglish = languageBloc.currentLanguage == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get Rank & Gamification Data from Provider
    final userProvider = Provider.of<UserProvider>(context);
    final userRank = userProvider.rank;
    final userRockets = userProvider.rockets;
    
    // Dynamic Background Gradient based on Theme
    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark 
        ? [
            const Color(0xFF2B2E35), // Neumorphic Dark Background
            const Color(0xFF1E2125), // Darker shade
          ]
        : [
            const Color(0xFF42A5F5), // Lighter Blue Top
            const Color(0xFF1976D2), // Medium Blue
            const Color(0xFF0D47A1), // Dark Blue Bottom
          ],
    );

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          bottom: false, // Handle bottom padding manually for custom footer position
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Welcome Text
                  Text(
                    isEnglish ? 'Welcome!' : 'Hoş Geldin!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: isDark ? NeumorphicColors.textDark : Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Central Glass Card Area
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Glassmorphism Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 320,
                                height: 480,
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // 2D Avatar
                          Positioned(
                            bottom: 20, // Position inside the glass card
                            child: GestureDetector(
                              onTap: _toggleQuest,
                              child: AnimatedBuilder(
                                animation: _avatarBounceController,
                                builder: (context, child) {
                                  // Simple bounce scale
                                  final scale = 1.0 + (_avatarBounceController.value * 0.05);
                                  
                                  // Get Avatar from Provider (Reactive)
                                  final userProvider = Provider.of<UserProvider>(context);
                                  final avatarPath = userProvider.currentAvatarPath ?? 'assets/avatars/2d/MALE_AVATAR_1.png';

                                  return Transform.scale(
                                    scale: scale,
                                    child: Image.asset(
                                      avatarPath,
                                      width: 280,
                                      height: 400,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                           'assets/avatars/2d/MALE_AVATAR_1.png',
                                           width: 280,
                                           height: 400,
                                           fit: BoxFit.contain,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // Speech Bubble (Futuristic)
                          Positioned(
                            top: -20,
                            child: _showQuestList
                                ? const SizedBox.shrink()
                                : QuestSpeechBubble(
                                    message: (() {
                                      final remainingDaily = _questData?.dailyQuests.where((q) => !q.isCompleted).length ?? 0;
                                      return remainingDaily > 0 ? 'Günlük görevlerin var!' : 'Tüm görevler tamamlandı!';
                                    })(),
                                    pendingCount: _questData?.dailyQuests.where((q) => !q.isCompleted).length ?? 0,
                                    show: true,
                                  ),
                          ),
                          
                          // Quest List Overlay
                          Positioned.fill(
                            child: Visibility(
                              visible: _showQuestList,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: QuestListWidget(
                                  questData: _questData ?? const QuestData(dailyQuests: [], weeklyQuests: [], monthlyQuests: []),
                                  onClose: _toggleQuest,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Floating Stats Bar (Glassmorphic Capsule)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 150.0, left: 20, right: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center, // Center alignment
                            children: [
                              // User Name
                              Text(
                                _capitalizeFirstLetter(widget.userProfile.displayName),
                                style: TextStyle(
                                  color: isDark ? NeumorphicColors.textDark : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Separator
                              Container(
                                width: 1,
                                height: 20,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Currency
                              Container(
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
                              const SizedBox(width: 8),
                              Text(
                                '$userRockets', // Use reactive provider value
                                style: TextStyle(
                                  color: isDark ? NeumorphicColors.textDark : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              const SizedBox(width: 16),
                              
                              // Separator 2
                              Container(
                                width: 1,
                                height: 20,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              
                              const SizedBox(width: 16),

                              // Rank
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: Color(0xFFFFD700), // Gold
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '#$userRank',
                                style: TextStyle(
                                  color: isDark ? NeumorphicColors.textDark : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // 🤖 Alfred AI Assistant - Standing to the RIGHT of Stats Bar
              Positioned(
                bottom: 150, // ✅ Aligned with stats bar vertical position
                right: 16, // ✅ Independent positioning on the right side of screen
                child: _buildAlfredAssistant(context, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🤖 Build Alfred AI Assistant - With Yellow Glow Effect
  /// Anchored to bottom-right corner with yellow highlight and mini speech bubble
  Widget _buildAlfredAssistant(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Open AI Assistant modal with glassmorphism theme
        debugPrint('🤖 Alfred tapped - Opening AI Assistant');
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AIAssistantWidget(
            userName: widget.userProfile.displayName,
            userProfile: widget.userProfile,
            onClose: () => Navigator.pop(context),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 💬 Konuşma Balonu (Speech Bubble)
          Positioned(
            top: -40, // Alfred'in kafasının üzerine
            child: Column(
              children: [
                // Balonun Kendisi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Yardım?",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Balonun Altındaki Küçük Üçgen
                ClipPath(
                  clipper: _TriangleClipper(),
                  child: Container(
                    height: 10,
                    width: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // 🤖 Alfred Görseli ve Sarı Parlama Efekti
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.yellowAccent.withValues(alpha: 0.25), // Subtle opacity
                  blurRadius: 8.0, // ✅ TIGHTER: Reduced blur for contained glow (was 12.0)
                  spreadRadius: -8.0, // ✅ TIGHTER: More negative for tight aura (was -2.0)
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/AI.png', // Alfred'in görsel yolu
              height: 90, // Alfred'in boyutunu buradan ayarla
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback gradient icon with yellow glow
                return Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellowAccent.withValues(alpha: 0.25), // Subtle opacity
                        blurRadius: 8.0, // ✅ TIGHTER: Reduced blur
                        spreadRadius: -6.0, // ✅ TIGHTER: More negative for tight aura
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 45,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Triangle Clipper for Speech Bubble Tail
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TriangleClipper oldClipper) => false;
}

