import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:performax/screens/login_screen.dart';
import '../widgets/profile_overlay.dart';
import '../services/user_service.dart';
import '../blocs/bloc_exports.dart';
import 'settings_screen.dart';
import 'denemeler_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';

class MyDrawer extends StatefulWidget {
  final Function(int)? onTabChange;

  const MyDrawer({
    super.key,
    this.onTabChange,
  });

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> with TickerProviderStateMixin {
  late final FirebaseAuth _auth;
  AnimationController? _headerController;
  AnimationController? _menuController;
  Animation<double>? _headerFadeAnimation;
  Animation<Offset>? _headerSlideAnimation;
  Animation<double>? _avatarScaleAnimation;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    try {
      _auth = FirebaseAuth.instance;
      
      // Header animation controller
      _headerController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      
      // Menu items animation controller
      _menuController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      
      // Header animations
      _headerFadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _headerController!,
        curve: Curves.easeOut,
      ));
      
      _headerSlideAnimation = Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _headerController!,
        curve: Curves.easeOutCubic,
      ));
      
      _avatarScaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _headerController!,
        curve: Curves.elasticOut,
      ));
      
      // Start animations
      _headerController?.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _menuController != null) {
          _menuController!.forward();
        }
      });
    } catch (e) {
      debugPrint('Error initializing drawer animations: $e');
    }
  }

  @override
  void dispose() {
    // Mark controllers as disposing to prevent new animations
    final headerCtrl = _headerController;
    final menuCtrl = _menuController;
    
    _headerController = null;
    _menuController = null;
    _headerFadeAnimation = null;
    _headerSlideAnimation = null;
    _avatarScaleAnimation = null;
    
    // Dispose after nulling to prevent access during disposal
    try {
      headerCtrl?.dispose();
      menuCtrl?.dispose();
    } catch (e) {
      debugPrint('Error disposing drawer controllers: $e');
    }
    super.dispose();
  }

  String _safeTranslate(LanguageBloc languageBloc, String key, [String fallback = '']) {
    try {
      return languageBloc.translate(key);
    } catch (e) {
      debugPrint('Translation error for key "$key": $e');
      return fallback.isEmpty ? key : fallback;
    }
  }

  /// Unified navigation method for all drawer items
  /// Ensures consistent behavior and prevents routing bugs
  /// Uses post-frame callback and stable NavigatorState to prevent context lifecycle issues
  Future<void> _navigateFromDrawer(BuildContext context, {
    int? tabIndex,
    String? routeName,
    Object? arguments,
  }) async {
    try {
      // CRITICAL: Capture NavigatorState BEFORE closing drawer
      // This ensures we have a stable reference even if drawer context becomes invalid
      final navigator = Navigator.of(context, rootNavigator: false);
      final navigatorState = navigator;
      
      // Validate widget is still mounted before proceeding
      if (!mounted) {
        debugPrint('⚠️ Drawer widget not mounted, aborting navigation');
        return;
      }
      
      // Close drawer first
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // CRITICAL: Wait for end of frame to ensure widget tree is stable after drawer close
      // This prevents race conditions during initial app load
      await WidgetsBinding.instance.endOfFrame;
      
      // Additional delay for drawer closing animation to complete
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Check widget state validity
      if (!mounted) {
        debugPrint('⚠️ Widget no longer mounted after drawer close, aborting navigation');
        return;
      }
      
      // Navigate based on type
      if (tabIndex != null) {
        // Tab-based navigation within HomeScreen
        if (widget.onTabChange != null) {
          // Use callback if available (preferred method - we're already in HomeScreen)
          // No context needed for callbacks
          widget.onTabChange!(tabIndex);
          debugPrint('✅ Navigated to tab $tabIndex via callback');
        } else {
          // Fallback: Navigate to HomeScreen with specific tab
          // Use the captured navigator state which is more stable
          debugPrint('ℹ️ Not in HomeScreen, navigating to HomeScreen with tab $tabIndex');
          
          try {
            await navigatorState.pushReplacementNamed(
              HomeScreen.id,
              arguments: tabIndex,
            );
            debugPrint('✅ Successfully navigated to HomeScreen with tab $tabIndex');
          } catch (e) {
            debugPrint('❌ Error navigating to HomeScreen: $e');
            // Fallback: Try with context if navigator failed
            if (context.mounted) {
              await Navigator.pushReplacementNamed(
                context,
                HomeScreen.id,
                arguments: tabIndex,
              );
            }
          }
        }
      } else if (routeName != null) {
        // Screen-based navigation using stable navigator state
        try {
          await navigatorState.pushNamed(
            routeName,
            arguments: arguments,
          );
          debugPrint('✅ Navigated to screen: $routeName');
        } catch (e) {
          debugPrint('❌ Error navigating to $routeName: $e');
          // Fallback: Try with context if navigator failed
          if (context.mounted) {
            await Navigator.pushNamed(
              context,
              routeName,
              arguments: arguments,
            );
          }
        }
      } else {
        debugPrint('❌ Warning: No navigation target specified (no tabIndex or routeName provided)');
      }
    } catch (e) {
      debugPrint('❌ Navigation error from drawer: $e');
      // Try to show error using ScaffoldMessenger
      // Note: We can't use context here due to async gap, so we'll just log
      // The navigation itself failed, so showing an error isn't critical
      debugPrint('   Error details: ${e.toString()}');
    }
  }

  String _getDisplayName(LanguageBloc languageBloc, Map<String, dynamic>? userData) {
    try {
      return userData?['fullName'] ?? 
             '${userData?['firstName'] ?? _safeTranslate(languageBloc, 'user', 'User')} ${userData?['lastName'] ?? ''}'.trim();
    } catch (e) {
      return userData?['fullName'] ?? userData?['firstName'] ?? 'User';
    }
  }

  String _getInitials(Map<String, dynamic>? userData) {
    final fullName = userData?['fullName'];
    if (fullName != null && fullName.isNotEmpty) {
      final nameParts = fullName.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        return fullName[0].toUpperCase();
      }
    }
    
    final firstName = userData?['firstName'];
    if (firstName != null && firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }
    
    return 'U';
  }

  Widget _buildAnimatedMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int index,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    bool isDanger = false,
  }) {
    // If no controller, return without animation
    if (_menuController == null) {
      return _AnimatedMenuTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        iconColor: iconColor,
        titleColor: titleColor,
        isDanger: isDanger,
        onTap: onTap,
      );
    }

    final delay = index * 80;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(50 * (1 - animation), 0),
            child: child,
          ),
        );
      },
      child: _AnimatedMenuTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        iconColor: iconColor,
        titleColor: titleColor,
        isDanger: isDanger,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, userProfileState) {
        // Extract user data from global state
        final Map<String, dynamic>? userData = userProfileState is UserProfileLoaded 
            ? userProfileState.userData 
            : null;
        final bool isGuest = userProfileState is UserProfileGuest || 
                             (userProfileState is UserProfileLoaded && userProfileState.isGuest);

        return BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            try {
              final theme = Theme.of(context);
              final languageBloc = context.read<LanguageBloc>();
        
        return Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Animated Header
                if (_headerFadeAnimation != null && _headerSlideAnimation != null)
                  FadeTransition(
                    opacity: _headerFadeAnimation!,
                    child: SlideTransition(
                      position: _headerSlideAnimation!,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: UserAccountsDrawerHeader(
                        decoration: const BoxDecoration(color: Colors.transparent),
                        currentAccountPicture: _avatarScaleAnimation != null 
                          ? ScaleTransition(
                              scale: _avatarScaleAnimation!,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 35,
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/avatars/2d/test_model_profil.png',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to initials if image fails to load
                                        return Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                theme.primaryColor,
                                                theme.primaryColor.withValues(alpha: 0.7),
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getInitials(userData),
                                              style: const TextStyle(
                                                fontSize: 32,
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
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 35,
                                child: Text(_getInitials(userData),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        accountName: Text(
                          isGuest 
                            ? _safeTranslate(languageBloc, 'guest_user', 'Guest User')
                            : _getDisplayName(languageBloc, userData),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        accountEmail: Text(
                          isGuest 
                            ? _safeTranslate(languageBloc, 'guest_account', 'Guest Account')
                            : (userData?['email'] ?? _safeTranslate(languageBloc, 'user', 'User')),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        otherAccountsPictures: [
                          if (!isGuest)
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: value * 6.28, // Full rotation
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      child: Icon(
                                        Icons.verified_user,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
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
                
                const SizedBox(height: 10),
                
                // Animated Menu Items
                if (!isGuest)
                  _buildAnimatedMenuItem(
                    icon: Icons.account_circle_rounded,
                    title: _safeTranslate(languageBloc, 'profile', 'Profile'),
                    iconColor: const Color(0xFF667eea),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        builder: (context) => ProfileOverlay(
                          userData: userData,
                        ),
                      );
                    },
                    index: 0,
                  ),
                
                if (isGuest)
                  _buildAnimatedMenuItem(
                    icon: Icons.account_circle_outlined,
                    title: _safeTranslate(languageBloc, 'profile', 'Profile'),
                    subtitle: _safeTranslate(languageBloc, 'guest_profile_restriction', 'Login required'),
                    iconColor: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      final snackBar = SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: AwesomeSnackbarContent(
                          title: _safeTranslate(languageBloc, 'restricted', 'Restricted'),
                          message: _safeTranslate(languageBloc, 'guest_profile_message', 'Please login to access this feature'),
                          contentType: ContentType.warning,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    index: 0,
                  ),
                
                // NEW: Home Page Navigation
                _buildAnimatedMenuItem(
                  icon: Icons.home_rounded,
                  title: languageBloc.currentLanguage == 'en' ? 'Home Page' : 'Ana Sayfa',
                  iconColor: const Color(0xFF43e97b),
                  onTap: () => _navigateFromDrawer(context, tabIndex: 0),
                  index: 1,
                ),
                
                // NEW: Dersler (Courses) Navigation
                _buildAnimatedMenuItem(
                  icon: Icons.school_rounded,
                  title: languageBloc.currentLanguage == 'en' ? 'Courses' : 'Dersler',
                  iconColor: const Color(0xFFf093fb),
                  onTap: () => _navigateFromDrawer(context, tabIndex: 1),
                  index: 2,
                ),
                
                // NEW: Denemeler (Mock Exams) Navigation
                _buildAnimatedMenuItem(
                  icon: Icons.assignment_rounded,
                  title: languageBloc.currentLanguage == 'en' ? 'Mock Exams' : 'DENEMELER',
                  iconColor: const Color(0xFF667eea),
                  onTap: () => _navigateFromDrawer(context, routeName: DenemelerScreen.id),
                  index: 3,
                ),

                // NEW: Favoriler (Favorites) Navigation
                _buildAnimatedMenuItem(
                  icon: Icons.favorite_rounded,
                  title: languageBloc.currentLanguage == 'en' ? 'Favorites' : 'FAVORİLER',
                  iconColor: const Color(0xFFff6b9d),
                  onTap: () => _navigateFromDrawer(context, routeName: FavoritesScreen.id),
                  index: 4,
                ),

                _buildAnimatedMenuItem(
                  icon: Icons.settings_rounded,
                  title: _safeTranslate(languageBloc, 'settings', 'Settings'),
                  iconColor: const Color(0xFF4facfe),
                  onTap: () => _navigateFromDrawer(
                    context,
                    routeName: SettingsScreen.id,
                    arguments: isGuest,
                  ),
                  index: 5,
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, animation, child) {
                      return Opacity(
                        opacity: animation,
                        child: Divider(
                          indent: 20,
                          endIndent: 20,
                          thickness: 1,
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      );
                    },
                  ),
                ),
                
                _buildAnimatedMenuItem(
                  icon: isGuest ? Icons.login_rounded : Icons.logout_rounded,
                  title: isGuest 
                    ? _safeTranslate(languageBloc, 'login', 'Login')
                    : _safeTranslate(languageBloc, 'logout', 'Logout'),
                  iconColor: const Color(0xFFfa709a),
                  titleColor: const Color(0xFFfa709a),
                  isDanger: true,
                  onTap: () async {
                    if (_isLoggingOut) return;
                    
                    setState(() {
                      _isLoggingOut = true;
                    });
                    
                    try {
                      // Clear UserProfileBloc state first
                      if (context.mounted) {
                        context.read<UserProfileBloc>().add(const ClearUserProfile());
                      }
                      
                      if (isGuest) {
                        await UserService.clearGuestStatus();
                      } else {
                        await _auth.signOut();
                        await UserService.clearGuestStatus();
                      }
                      
                      // Clear all cached user data
                      await UserService.clearAllUserData();
                      
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed(LoginScreen.id);
                      }
                    } catch (e) {
                      debugPrint('❌ Error during logout: $e');
                      // Still navigate to login even if there's an error
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed(LoginScreen.id);
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoggingOut = false;
                        });
                      }
                    }
                  },
                  index: 6,
                ),
                
                if (_isLoggingOut)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: SpinKitFadingCircle(
                        color: theme.primaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Animated footer
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  builder: (context, animation, child) {
                    return Opacity(
                      opacity: animation * 0.5,
                      child: Center(
                        child: Text(
                          'Performax Learning',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
        } catch (e) {
          debugPrint('Error building drawer: $e');
          return Drawer(
            child: Center(
              child: Text('Error loading drawer: $e'),
            ),
          );
        }
          },
        );
      },
    );
  }
}

// Animated Menu Tile Widget
class _AnimatedMenuTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final bool isDanger;
  final VoidCallback onTap;

  const _AnimatedMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.titleColor,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  State<_AnimatedMenuTile> createState() => _AnimatedMenuTileState();
}

class _AnimatedMenuTileState extends State<_AnimatedMenuTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  final bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (widget.iconColor ?? theme.primaryColor)
                      .withValues(alpha: _elevationAnimation.value * 0.15),
                  blurRadius: _elevationAnimation.value * 4,
                  spreadRadius: _elevationAnimation.value * 0.5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onTap,
                onTapDown: (_) => _hoverController.forward(),
                onTapUp: (_) => _hoverController.reverse(),
                onTapCancel: () => _hoverController.reverse(),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _isHovered
                        ? LinearGradient(
                            colors: [
                              (widget.iconColor ?? theme.primaryColor)
                                  .withValues(alpha: 0.1),
                              (widget.iconColor ?? theme.primaryColor)
                                  .withValues(alpha: 0.05),
                            ],
                          )
                        : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (widget.iconColor ?? theme.primaryColor)
                                .withValues(alpha: 0.2),
                            (widget.iconColor ?? theme.primaryColor)
                                .withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor ?? theme.primaryColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: widget.titleColor,
                      ),
                    ),
                    subtitle: widget.subtitle != null
                        ? Text(
                            widget.subtitle!,
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: (widget.iconColor ?? theme.primaryColor)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
