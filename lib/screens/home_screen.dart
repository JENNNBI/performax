import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/pulsing_ai_fab.dart';
import '../widgets/ai_assistant_widget.dart';
import '../utils/app_icons.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../blocs/bloc_exports.dart';
import '../models/user_profile.dart';
import 'profile_home_screen.dart';
import 'content_hub_screen.dart';
import 'my_drawer.dart';
import 'login_screen.dart';
import 'qr_scanner_screen.dart';
import 'enhanced_statistics_screen.dart';
import 'subjects_panel_screen.dart';
import '../services/user_service.dart';
import '../services/streak_service.dart';
import '../widgets/streak_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NEW Home Screen Structure
/// Bottom navigation with 4 main sections:
/// 1. Profile Home (3D Avatar + User Info)
/// 2. Learning Content (Videos)
/// 3. PDF Resources
/// 4. Statistics
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
  
  // SharedPreferences key to track last popup shown date (per calendar day)
  static const String _keyLastStreakPopupDate = 'last_streak_popup_date';

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
    
    _loadUserData();
  }

  /// Refresh user data from UserProfileBloc when it changes
  /// This ensures we always have the latest user profile data
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
  /// Shows popup only once per calendar day
  Future<void> _checkAndShowStreak() async {
    try {
      // Small delay to ensure everything is fully rendered
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      // Check if popup was already shown today
      final prefs = await SharedPreferences.getInstance();
      final lastShownDateStr = prefs.getString(_keyLastStreakPopupDate);
      
      // Get current date (normalized to midnight for consistent comparison)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Parse last shown date if it exists
      DateTime? lastShownDate;
      if (lastShownDateStr != null) {
        try {
          lastShownDate = DateTime.parse(lastShownDateStr);
        } catch (e) {
          debugPrint('⚠️ Error parsing last streak popup date: $e');
        }
      }
      
      // Check if we should show the popup
      // Show if: never shown before OR last shown on a different calendar day
      final shouldShowPopup = lastShownDate == null || 
          lastShownDate.isBefore(today);
      
      if (!shouldShowPopup) {
        debugPrint('ℹ️ Streak popup already shown today, skipping');
        return;
      }
      
      if (!mounted) return;
      
      // Get streak data
      final streakService = StreakService();
      final streakData = await streakService.checkAndUpdateStreak();
      
      // Show streak modal with valid context
      if (mounted) {
        // Save today's date BEFORE showing popup to prevent multiple shows if there's an error
        await prefs.setString(_keyLastStreakPopupDate, today.toIso8601String());
        
        // Check mounted again after async operation
        if (!mounted) return;
        
        await StreakModal.show(context, streakData);
        debugPrint('✅ Streak modal displayed: Streak ${streakData.currentStreak} (First time today)');
      }
    } catch (e) {
      debugPrint('❌ Error showing streak modal: $e');
      // Don't throw - allow app to continue even if streak fails
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
        
        debugPrint('✅ User profile loaded: ${profile.displayName} (${profile.formattedGrade ?? "No grade"})');
        if (profile.school != null) {
          debugPrint('   School: ${profile.school}');
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(LoginScreen.id);
        }
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Hata!',
            message: '${context.read<LanguageBloc>().translate('error_loading_user_data')}: ${e.toString()}',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Listen to UserProfileBloc changes to automatically update UI when user data changes
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
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu_rounded, color: theme.primaryColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            title: Text(
              _getAppBarTitle(languageBloc),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 0,
            actions: [
              if (_userData != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/avatars/2d/test_model_profil.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to initials if image fails to load
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                            child: Center(
                              child: Text(
                                (_userData!['fullName']?.split(' ')[0]?[0] ?? _userData!['firstName']?[0] ?? 'U').toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          drawer: MyDrawer(
            onTabChange: _onItemTapped,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    // Main content area - switched based on selected index
                    // Wrapped in Container to prevent child screens from covering bottom nav
                    Container(
                      color: Colors.transparent,
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          // Tab 0: Profile Home (3D Avatar + User Info)
                          _userProfile != null
                            ? ProfileHomeScreen(userProfile: _userProfile!)
                            : const Center(child: Text('Profile data not available')),
                          
                          // Tab 1: Learning Content Hub
                          const ContentHubScreen(),
                          
                          // Tab 2: Subjects Panel (PDF Resources)
                          const SubjectsPanelScreen(),
                          
                          // Tab 3: Statistics
                          EnhancedStatisticsScreen(isGuest: _isGuest),
                        ],
                      ),
                    ),
                    
                    // AI Assistant FAB - Bottom-right corner
                    Positioned(
                      bottom: 90,
                      right: 16,
                      child: PulsingAIFAB(
                        onTap: _openAIAssistant,
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: bottomNavState.isVisible ? _buildBottomNav(theme, languageBloc) : null,
          floatingActionButton: bottomNavState.isVisible ? GestureDetector(
            onTap: _openQRScanner,
            child: AppIcons.floatingIcon(
              AppIcons.qrScanner,
              size: 28,
              color: theme.primaryColor,
              isActive: true,
            ),
          ) : null,
          floatingActionButtonLocation: bottomNavState.isVisible ? FloatingActionButtonLocation.centerDocked : null,
              );
            },
          );
        },
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
        return languageBloc.currentLanguage == 'en' ? 'PDFs' : 'PDF\'LER';
      case 3:
        return languageBloc.currentLanguage == 'en' ? 'Statistics' : 'İstatistikler';
      default:
        return 'Performax';
    }
  }

  Widget _buildBottomNav(ThemeData theme, LanguageBloc languageBloc) {
    final isEnglish = languageBloc.currentLanguage == 'en';
    
    return Container(
      height: 75, // Increased from 58 to 75 for better visual presence and tap targets
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.95),
            theme.primaryColor.withValues(alpha: 0.85),
            const Color(0xFF667eea).withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            iconAsset: 'assets/images/konu_anlatim.png',
            label: isEnglish ? 'Profile' : 'Profil',
            index: 0,
            theme: theme,
          ),
          _buildNavItem(
            iconAsset: 'assets/images/soru_cozum.png',
            label: isEnglish ? 'Courses' : 'Dersler',
            index: 1,
            theme: theme,
          ),
          const SizedBox(width: 60), // Space for FAB
          _buildNavItem(
            iconAsset: 'assets/images/pdf.png',
            label: 'PDF',
            index: 2,
            theme: theme,
          ),
          _buildNavItem(
            iconAsset: 'assets/images/istatistik1.png',
            label: isEnglish ? 'Stats' : 'İstatistik',
            index: 3,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String iconAsset,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected 
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isSelected ? 1.4 : 1.0), // Increased from 1.3 to 1.4
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(isSelected ? 6 : 3), // Increased padding
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected 
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.3),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ] : [],
                      ),
                      child: Image.asset(
                        iconAsset,
                        width: 32, // Increased from 24 to 32
                        height: 32, // Increased from 24 to 32
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.circle,
                            size: 32, // Increased from 24 to 32
                            color: isSelected ? theme.primaryColor : Colors.white70,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4), // Increased from 1 to 4
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: isSelected ? 12 : 11, // Increased from 10/9 to 12/11
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: isSelected ? 0.5 : 0.3, // Increased spacing
                    height: 1.1, // Adjusted line height
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: isSelected ? 0.4 : 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: isSelected ? 3 : 2,
                      ),
                      if (isSelected)
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          offset: const Offset(0, 0),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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

