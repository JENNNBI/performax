import 'package:flutter/material.dart';
import '../widgets/ai_assistant_widget.dart';
import '../blocs/bloc_exports.dart';
import '../models/user_profile.dart';
import 'profile_home_screen.dart';
import 'content_hub_screen.dart';
import 'my_drawer.dart';
import 'login_screen.dart';
import 'qr_scanner_screen.dart';
import 'enhanced_statistics_screen.dart';
import 'leaderboard_screen.dart';
import '../services/user_service.dart';
import '../services/streak_service.dart';
import '../widgets/streak_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/debug_manager.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// NEW Home Screen Structure
/// Refactored to Neumorphic Design System
class HomeScreen extends StatefulWidget {
  final int? initialTabIndex;
  
  const HomeScreen({super.key, this.initialTabIndex});
  static const id = 'home_screen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  final UserService _userService = UserService();
  Map<String, dynamic>? _userData;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isGuest = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // SharedPreferences key to track last popup shown date (per calendar day)
  static const String _keyLastStreakPopupDate = 'last_streak_popup_date';

  // Debug Tap Logic
  int _debugTapCount = 0;
  Timer? _debugTapTimer;

  @override
  void initState() {
    super.initState();
    
    // Set initial tab index from widget parameter, or default to 0
    _selectedIndex = widget.initialTabIndex ?? 0;
    
    // Ensure bottom navigation is visible when HomeScreen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BottomNavVisibilityBloc>().add(const ShowBottomNav());
        // Check and show streak modal after screen is fully built
        _checkAndShowStreak();
      }
    });
    
    // Load user profile via bloc (loads from cache first, then syncs)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProfileBloc>().add(const LoadUserProfile());
      }
    });
    
    // Also load directly for backward compatibility
    _loadUserData();
  }

  /// Refresh user data from UserProfileBloc when it changes
  void _updateUserDataFromBloc(UserProfileState state) {
    if (state is UserProfileLoaded) {
      setState(() {
        _userProfile = state.userProfile;
        _userData = state.userData;
        _isGuest = state.isGuest;
        _isLoading = false;
      });
      debugPrint('✅ HomeScreen: User data updated from UserProfileBloc for ${state.userProfile.displayName}');
    } else if (state is UserProfileLoading) {
      setState(() {
        _isLoading = true;
      });
    } else if (state is UserProfileInitial || state is UserProfileGuest) {
      // User logged out or is guest
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Check streak and show modal after HomeScreen is fully loaded
  Future<void> _checkAndShowStreak() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      final lastShownDateStr = prefs.getString(_keyLastStreakPopupDate);
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      DateTime? lastShownDate;
      if (lastShownDateStr != null) {
        try {
          lastShownDate = DateTime.parse(lastShownDateStr);
        } catch (e) {
          debugPrint('⚠️ Error parsing last streak popup date: $e');
        }
      }
      
      final shouldShowPopup = lastShownDate == null || 
          lastShownDate.isBefore(today);
      
      if (!shouldShowPopup) {
        return;
      }
      
      if (!mounted) return;
      
      final streakService = StreakService();
      final streakData = await streakService.checkAndUpdateStreak();
      
      if (mounted) {
        await prefs.setString(_keyLastStreakPopupDate, today.toIso8601String());
        if (!mounted) return;
        await StreakModal.show(context, streakData);
      }
    } catch (e) {
      debugPrint('❌ Error showing streak modal: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _userService.getCurrentUserProfile();
      
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _userData = profile.toMap();
          _isGuest = profile.isGuest;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(LoginScreen.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }

  void _openAIAssistant() {
    final userName = _userProfile?.displayName ?? 
                     _userData?['fullName']?.split(' ')[0] ?? 
                     _userData?['firstName'] ?? 
                     'Öğrenci';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIAssistantWidget(
        selectedText: null,
        userName: userName,
        userProfile: _userProfile,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleDebugTap() {
    _debugTapCount++;
    _debugTapTimer?.cancel();
    _debugTapTimer = Timer(const Duration(seconds: 1), () {
      _debugTapCount = 0;
    });

    if (_debugTapCount == 5) {
      final newValue = !DebugManager.showDebugStats.value;
      DebugManager.showDebugStats.value = newValue;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Developer Mode: ${newValue ? "ON" : "OFF"}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      _debugTapCount = 0;
      _debugTapTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserProfileBloc, UserProfileState>(
      listener: (context, state) {
        _updateUserDataFromBloc(state);
      },
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          final languageBloc = context.read<LanguageBloc>();
          
          return BlocBuilder<BottomNavVisibilityBloc, BottomNavVisibilityState>(
            builder: (context, bottomNavState) {
              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: NeumorphicColors.getBackground(context),
                drawer: MyDrawer(
                  onTabChange: _onItemTapped,
                ),
                body: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Custom Neumorphic Header
                      _buildNeumorphicHeader(context, languageBloc),
                      
                      // Body
                      Expanded(
                        child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Stack(
                              children: [
                                IndexedStack(
                                  index: _selectedIndex,
                                  children: [
                                    _userProfile != null
                                      ? ProfileHomeScreen(userProfile: _userProfile!)
                                      : const Center(child: Text('Profile data not available')),
                                    const ContentHubScreen(),
                                    const LeaderboardScreen(),
                                    EnhancedStatisticsScreen(isGuest: _isGuest),
                                  ],
                                ),
                                
                                // AI Assistant Avatar
                                Positioned(
                                  bottom: 120, // Adjusted for floating dock
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: _openAIAssistant,
                                    child: Image.asset(
                                      'assets/images/AI.png',
                                      width: 70,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: bottomNavState.isVisible 
                  ? _buildNeumorphicDock(context, languageBloc) 
                  : null,
                extendBody: true, // Allows content to go behind nav bar
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNeumorphicHeader(BuildContext context, LanguageBloc languageBloc) {
    final title = _getAppBarTitle(languageBloc);
    final userInitials = (_userData?['fullName']?.split(' ')[0]?[0] ?? _userData?['firstName']?[0] ?? 'U').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu Button
          NeumorphicButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            padding: const EdgeInsets.all(12),
            borderRadius: 14,
            child: Icon(
              Icons.menu_rounded,
              color: NeumorphicColors.getText(context),
            ),
          ),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NeumorphicColors.getText(context),
            ),
          ),
          
          // Profile/Debug Button
          GestureDetector(
            onTap: _handleDebugTap,
            child: NeumorphicContainer(
              padding: const EdgeInsets.all(4),
              borderRadius: 30,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: NeumorphicColors.accentBlue,
                child: Text(
                  userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicDock(BuildContext context, LanguageBloc languageBloc) {
    final isEnglish = languageBloc.currentLanguage == 'en';
    
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
        color: Colors.transparent,
        child: NeumorphicContainer(
          borderRadius: 30,
          depth: 8,
          color: NeumorphicColors.getBackground(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDockItem(
                context: context,
                index: 0,
                icon: Icons.person_rounded,
                label: isEnglish ? 'Profile' : 'Profil',
              ),
              _buildDockItem(
                context: context,
                index: 1,
                icon: Icons.play_circle_filled_rounded,
                label: isEnglish ? 'Courses' : 'Dersler',
              ),
              
              // QR Button (Middle)
              Transform.translate(
                offset: const Offset(0, -20),
                child: GestureDetector(
                  onTap: _openQRScanner,
                  child: NeumorphicContainer(
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(16),
                    color: NeumorphicColors.accentBlue,
                    depth: 6,
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              
              _buildDockItem(
                context: context,
                index: 2,
                icon: Icons.leaderboard_rounded,
                label: isEnglish ? 'Rank' : 'Sıralama',
              ),
              _buildDockItem(
                context: context,
                index: 3,
                icon: Icons.bar_chart_rounded,
                label: isEnglish ? 'Stats' : 'İstatistik',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? NeumorphicColors.accentBlue : NeumorphicColors.getText(context).withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeumorphicContainer(
            isPressed: isSelected, // Pressed/Concave when selected
            padding: const EdgeInsets.all(10),
            borderRadius: 12,
            depth: isSelected ? -3 : 3, // Invert depth for concave effect
            color: isSelected ? NeumorphicColors.getBackground(context) : null,
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(LanguageBloc languageBloc) {
    switch (_selectedIndex) {
      case 0:
        return languageBloc.currentLanguage == 'en' ? 'My Profile' : 'Profilim';
      case 1:
        return languageBloc.currentLanguage == 'en' ? 'Courses' : 'Dersler';
      case 2:
        return languageBloc.currentLanguage == 'en' ? 'Leaderboard' : 'Sıralama';
      case 3:
        return languageBloc.currentLanguage == 'en' ? 'Statistics' : 'İstatistikler';
      default:
        return 'Performax';
    }
  }
}
