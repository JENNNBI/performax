import 'package:flutter/material.dart';
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
import 'pdf_resources_screen.dart';
import '../services/user_service.dart';

/// NEW Home Screen Structure
/// Bottom navigation with 4 main sections:
/// 1. Profile Home (3D Avatar + User Info)
/// 2. Learning Content (Videos)
/// 3. PDF Resources
/// 4. Statistics
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const id = 'home_screen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final UserService _userService = UserService();
  Map<String, dynamic>? _userData;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Scaffold(
          appBar: AppBar(
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
                    backgroundColor: theme.primaryColor,
                    child: Text(
                      (_userData!['fullName']?.split(' ')[0]?[0] ?? _userData!['firstName']?[0] ?? 'U').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                    IndexedStack(
                      index: _selectedIndex,
                      children: [
                        // Tab 0: Profile Home (3D Avatar + User Info)
                        _userProfile != null
                          ? ProfileHomeScreen(userProfile: _userProfile!)
                          : const Center(child: Text('Profile data not available')),
                        
                        // Tab 1: Learning Content Hub
                        const ContentHubScreen(),
                        
                        // Tab 2: PDF Resources
                        const PDFResourcesScreen(),
                        
                        // Tab 3: Statistics
                        EnhancedStatisticsScreen(isGuest: _isGuest),
                      ],
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
          bottomNavigationBar: _buildBottomNav(theme, languageBloc),
          floatingActionButton: GestureDetector(
            onTap: _openQRScanner,
            child: AppIcons.floatingIcon(
              AppIcons.qrScanner,
              size: 28,
              color: theme.primaryColor,
              isActive: true,
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  String _getAppBarTitle(LanguageBloc languageBloc) {
    switch (_selectedIndex) {
      case 0:
        return languageBloc.currentLanguage == 'en' ? 'My Profile' : 'Profilim';
      case 1:
        return languageBloc.currentLanguage == 'en' ? 'Learning' : 'Öğrenme';
      case 2:
        return languageBloc.currentLanguage == 'en' ? 'Resources' : 'Kaynaklar';
      case 3:
        return languageBloc.currentLanguage == 'en' ? 'Statistics' : 'İstatistikler';
      default:
        return 'Performax';
    }
  }

  Widget _buildBottomNav(ThemeData theme, LanguageBloc languageBloc) {
    final isEnglish = languageBloc.currentLanguage == 'en';
    
    return BottomAppBar(
      height: 70,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.person_rounded,
            label: isEnglish ? 'Profile' : 'Profil',
            index: 0,
            theme: theme,
          ),
          _buildNavItem(
            icon: Icons.school_rounded,
            label: isEnglish ? 'Learn' : 'Öğren',
            index: 1,
            theme: theme,
          ),
          const SizedBox(width: 60), // Space for FAB
          _buildNavItem(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            index: 2,
            theme: theme,
          ),
          _buildNavItem(
            icon: Icons.bar_chart_rounded,
            label: isEnglish ? 'Stats' : 'İstatistik',
            index: 3,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected ? theme.primaryColor : Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? theme.primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

