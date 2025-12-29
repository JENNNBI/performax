import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; // Modern icon library
import 'package:performax/screens/login_screen.dart';
import '../widgets/profile_overlay.dart';
import '../services/user_service.dart';
import '../services/user_provider.dart';
import '../blocs/bloc_exports.dart';
import 'settings_screen.dart';
import 'denemeler_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

import '../widgets/user_avatar_circle.dart';

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
  // Removed unused _auth field
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // Removed _auth initialization - use FirebaseAuth.instance directly
  }

  String _safeTranslate(LanguageBloc languageBloc, String key, [String fallback = '']) {
    try {
      return languageBloc.translate(key);
    } catch (e) {
      debugPrint('Translation error for key "$key": $e');
      return fallback.isEmpty ? key : fallback;
    }
  }

  Future<void> _navigateFromDrawer(BuildContext context, {
    int? tabIndex,
    String? routeName,
    Object? arguments,
  }) async {
    try {
      final navigator = Navigator.of(context, rootNavigator: false);
      final navigatorState = navigator;
      
      if (!mounted) return;
      
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) return;
      
      if (tabIndex != null) {
        if (widget.onTabChange != null) {
          widget.onTabChange!(tabIndex);
        } else {
          try {
            await navigatorState.pushReplacementNamed(
              HomeScreen.id,
              arguments: tabIndex,
            );
          } catch (e) {
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
        try {
          await navigatorState.pushNamed(
            routeName,
            arguments: arguments,
          );
        } catch (e) {
          if (context.mounted) {
            await Navigator.pushNamed(
              context,
              routeName,
              arguments: arguments,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Navigation error from drawer: $e');
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


  Widget _buildNeumorphicMenuItem({
    required PhosphorIconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? iconColor,
    bool isDanger = false,
  }) {
    final textColor = NeumorphicColors.getText(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: NeumorphicButton(
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        borderRadius: 16,
        child: Row(
          children: [
            NeumorphicContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              depth: 2,
              color: isDanger ? Colors.red.withValues(alpha: 0.1) : null,
              child: PhosphorIcon(
                icon,
                color: isDanger ? Colors.red : (iconColor ?? NeumorphicColors.accentBlue),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDanger ? Colors.red : textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PhosphorIcon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: textColor.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, userProfileState) {
        final Map<String, dynamic>? userData = userProfileState is UserProfileLoaded 
            ? userProfileState.userData 
            : null;
        final bool isGuest = userProfileState is UserProfileGuest || 
                             (userProfileState is UserProfileLoaded && userProfileState.isGuest);

        return BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            final languageBloc = context.read<LanguageBloc>();
            final bgColor = NeumorphicColors.getBackground(context);
            final textColor = NeumorphicColors.getText(context);

            return Drawer(
              backgroundColor: bgColor,
              child: SafeArea(
                child: Column(
                  children: [
                    // User Header
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: NeumorphicContainer(
                        borderRadius: 24,
                        child: Column(
                          children: [
                            const UserAvatarCircle(
                              radius: 40,
                              showBorder: true,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isGuest 
                                ? _safeTranslate(languageBloc, 'guest_user', 'Guest User')
                                : _getDisplayName(languageBloc, userData),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (!isGuest && userData?['email'] != null)
                              Text(
                                userData!['email'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Menu Items
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (!isGuest)
                            _buildNeumorphicMenuItem(
                              icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
                              title: _safeTranslate(languageBloc, 'profile', 'Profile'),
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
                            ),
                          
                          _buildNeumorphicMenuItem(
                            icon: PhosphorIcons.house(PhosphorIconsStyle.duotone),
                            title: languageBloc.currentLanguage == 'en' ? 'Home' : 'Ana Sayfa',
                            onTap: () => _navigateFromDrawer(context, tabIndex: 0),
                          ),

                          _buildNeumorphicMenuItem(
                            icon: PhosphorIcons.graduationCap(PhosphorIconsStyle.duotone),
                            title: languageBloc.currentLanguage == 'en' ? 'Courses' : 'Dersler',
                            onTap: () => _navigateFromDrawer(context, tabIndex: 1),
                          ),

                          _buildNeumorphicMenuItem(
                            icon: PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
                            title: languageBloc.currentLanguage == 'en' ? 'Mock Exams' : 'Denemeler',
                            onTap: () => _navigateFromDrawer(context, routeName: DenemelerScreen.id),
                          ),

                          _buildNeumorphicMenuItem(
                            icon: PhosphorIcons.heart(PhosphorIconsStyle.duotone),
                            title: languageBloc.currentLanguage == 'en' ? 'Favorites' : 'Favoriler',
                            onTap: () => _navigateFromDrawer(context, routeName: FavoritesScreen.id),
                          ),

                          _buildNeumorphicMenuItem(
                            icon: PhosphorIcons.gear(PhosphorIconsStyle.duotone),
                            title: _safeTranslate(languageBloc, 'settings', 'Settings'),
                            onTap: () => _navigateFromDrawer(
                              context,
                              routeName: SettingsScreen.id,
                              arguments: isGuest,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Divider(color: textColor.withValues(alpha: 0.1)),
                          ),

                          _buildNeumorphicMenuItem(
                            icon: isGuest 
                              ? PhosphorIcons.signIn(PhosphorIconsStyle.bold)
                              : PhosphorIcons.signOut(PhosphorIconsStyle.bold),
                            title: isGuest 
                              ? _safeTranslate(languageBloc, 'login', 'Login')
                              : _safeTranslate(languageBloc, 'logout', 'Logout'),
                            isDanger: true,
                            onTap: () async {
                              if (_isLoggingOut) return;
                              setState(() => _isLoggingOut = true);
                              try {
                                debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                                debugPrint('🚪 LOGOUT FLOW STARTED');
                                debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                                
                                // 1️⃣ Clear UserProvider RAM state (preserves disk data)
                                if (context.mounted) {
                                  await Provider.of<UserProvider>(context, listen: false).clearSession();
                                  debugPrint('✅ Step 1: UserProvider session cleared (RAM only)');
                                }
                                
                                // 2️⃣ Clear UserProfileBloc state
                                if (context.mounted) {
                                  context.read<UserProfileBloc>().add(const ClearUserProfile());
                                  debugPrint('✅ Step 2: UserProfileBloc cleared');
                                }
                                
                                // 3️⃣ Sign out from Firebase
                                await FirebaseAuth.instance.signOut();
                                debugPrint('✅ Step 3: Firebase sign-out complete');
                                
                                // 4️⃣ Clear other user services
                                await UserService.clearAllUserData();
                                debugPrint('✅ Step 4: UserService data cleared');
                                
                                debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                                debugPrint('✅ LOGOUT COMPLETE');
                                debugPrint('📁 User data preserved on disk for next login');
                                debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                                
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacementNamed(LoginScreen.id);
                                }
                              } catch (e) {
                                debugPrint('❌ Error during logout: $e');
                              } finally {
                                if (mounted) setState(() => _isLoggingOut = false);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
