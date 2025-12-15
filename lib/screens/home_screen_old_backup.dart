import 'package:flutter/material.dart';

import '../widgets/animated_subject_card.dart';
import '../widgets/slidable_subject_card.dart';
import '../widgets/ai_assistant_widget.dart';
import '../widgets/pulsing_ai_fab.dart';
import '../widgets/enhanced_bottom_nav.dart';
import '../utils/app_icons.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../blocs/bloc_exports.dart';
import '../models/user_profile.dart';
import 'subject_branch_selection_screen.dart';
import 'my_drawer.dart';
import 'login_screen.dart';
import 'qr_scanner_screen.dart';
import 'enhanced_statistics_screen.dart';
import 'pdf_resources_screen.dart';
import '../services/user_service.dart';


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

  // Get localized subject data
  List<Map<String, dynamic>> _getLocalizedSubjects(LanguageBloc languageBloc) {
    return [
      {
        'name': languageBloc.translate('mathematics'),
        'description': languageBloc.currentLanguage == 'tr' 
          ? 'Temel matematik konuları ve ileri düzey problemler'
          : 'Basic mathematics topics and advanced problems',
        'icon': AppIcons.subjects['Matematik']!,
        'gradientStart': const Color(0xFF667eea),
        'gradientEnd': const Color(0xFF764ba2),
        'contentCount': 45,
      },
      {
        'name': languageBloc.translate('physics'),
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Fizik yasaları, formüller ve pratik uygulamalar'
          : 'Physics laws, formulas and practical applications',
        'icon': AppIcons.subjects['Fizik']!,
        'gradientStart': const Color(0xFFf093fb),
        'gradientEnd': const Color(0xFFf5576c),
        'contentCount': 38,
      },
      {
        'name': languageBloc.translate('chemistry'),
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Kimyasal reaksiyonlar ve moleküler yapılar'
          : 'Chemical reactions and molecular structures',
        'icon': AppIcons.subjects['Kimya']!,
        'gradientStart': const Color(0xFF4facfe),
        'gradientEnd': const Color(0xFF00f2fe),
        'contentCount': 32,
      },
      {
        'name': languageBloc.translate('biology'),
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Canlı organizmaları ve yaşam süreçleri'
          : 'Living organisms and life processes',
        'icon': AppIcons.subjects['Biyoloji']!,
        'gradientStart': const Color(0xFF43e97b),
        'gradientEnd': const Color(0xFF38f9d7),
        'contentCount': 28,
      },
      {
        'name': languageBloc.translate('turkish'),
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Dil bilgisi, edebiyat ve okuma anlama'
          : 'Grammar, literature and reading comprehension',
        'icon': AppIcons.subjects['Türkçe']!,
        'gradientStart': const Color(0xFFfa709a),
        'gradientEnd': const Color(0xFFfee140),
        'contentCount': 42,
      },
      {
        'name': languageBloc.translate('history'),
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Türk tarihi ve dünya medeniyetleri'
          : 'Turkish history and world civilizations',
        'icon': AppIcons.subjects['Tarih']!,
        'gradientStart': const Color(0xFFa8edea),
        'gradientEnd': const Color(0xFFfed6e3),
        'contentCount': 25,
      },
      {
        'name': languageBloc.translate('geography'),
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Fiziki ve beşeri coğrafya konuları'
          : 'Physical and human geography topics',
        'icon': AppIcons.subjects['Coğrafya']!,
        'gradientStart': const Color(0xFFffecd2),
        'gradientEnd': const Color(0xFFfcb69f),
        'contentCount': 22,
      },
      {
        'name': languageBloc.translate('philosophy'),
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Düşünce tarihi ve felsefi akımlar'
          : 'History of thought and philosophical movements',
        'icon': AppIcons.subjects['Felsefe']!,
        'gradientStart': const Color(0xFFa18cd1),
        'gradientEnd': const Color(0xFFfbc2eb),
        'contentCount': 18,
      },
    ];
  }

  Future<void> _loadUserData() async {
    try {
      // Fetch complete user profile
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
        // No profile found, redirect to login
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
        userProfile: _userProfile, // Pass complete user profile for personalization
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  String _getWelcomeMessage(LanguageBloc languageBloc) {
    final firstName = _userData?['fullName']?.split(' ')[0] ?? _userData?['firstName'] ?? languageBloc.translate('user');
    return '${languageBloc.translate('welcome_to_performax')}, $firstName!';
  }

  void _navigateToSubjectBranchSelection(String sectionType) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SubjectBranchSelectionScreen(
          sectionType: sectionType,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final subjects = _getLocalizedSubjects(languageBloc);
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Performax ${languageBloc.translate('learning')}',
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
                    // Main content
                    Column(
                      children: [
                        // Welcome message
                        Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withValues(alpha: 0.8),
                            theme.primaryColor.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.waving_hand_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getWelcomeMessage(languageBloc),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content area
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          _buildConceptVideosTab(languageBloc, subjects),
                          _buildPracticeVideosTab(languageBloc, subjects),
                          const PDFResourcesScreen(),
                          EnhancedStatisticsScreen(isGuest: _isGuest),
                        ],
                      ),
                        ),
                      ],
                    ),
                    // AI Assistant FAB - Positioned in bottom-right corner with pulsing animation
                    Positioned(
                      bottom: 90,
                      right: 16,
                      child: PulsingAIFAB(
                        onTap: _openAIAssistant,
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: EnhancedBottomNav(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            primaryColor: theme.primaryColor,
          ),
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


  Widget _buildConceptVideosTab(LanguageBloc languageBloc, List<Map<String, dynamic>> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar section removed to keep display area empty
        
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languageBloc.translate('topic_videos'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                languageBloc.currentLanguage == 'tr'
                  ? 'Temel konuların detaylı açıklamalarını izleyin'
                  : 'Watch detailed explanations of fundamental topics',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 110),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              // Alternate between slidable and animated cards for variety
              if (index % 2 == 0) {
                return SlidableSubjectCard(
                  index: index,
                  subjectName: subject['name'],
                  icon: subject['icon'],
                  gradientStart: subject['gradientStart'],
                  gradientEnd: subject['gradientEnd'],
                  contentCount: subject['contentCount'],
                  onTap: () {
                    _navigateToSubjectBranchSelection(
                      languageBloc.translate('topic_videos'),
                    );
                  },
                );
              } else {
                return AnimatedSubjectCard(
                  index: index,
                  subjectName: subject['name'],
                  icon: subject['icon'],
                  gradientStart: subject['gradientStart'],
                  gradientEnd: subject['gradientEnd'],
                  contentCount: subject['contentCount'],
                  onTap: () {
                    _navigateToSubjectBranchSelection(
                      languageBloc.translate('topic_videos'),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeVideosTab(LanguageBloc languageBloc, List<Map<String, dynamic>> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languageBloc.translate('problem_solving'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                languageBloc.currentLanguage == 'tr'
                  ? 'Problemlerin adım adım çözümlerini öğrenin'
                  : 'Learn step-by-step solutions to problems',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 110),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return AnimatedSubjectCard(
                index: index,
                subjectName: subject['name'],
                icon: subject['icon'],
                gradientStart: subject['gradientStart'],
                gradientEnd: subject['gradientEnd'],
                contentCount: subject['contentCount'],
                onTap: () {
                  _navigateToSubjectBranchSelection(
                    languageBloc.translate('problem_solving'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }


} 
