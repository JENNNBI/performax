import 'package:flutter/material.dart';
import '../blocs/bloc_exports.dart';
import 'grade_selection_screen.dart';

/// Subjects Panel Screen
/// Visual panel interface matching the provided screenshot design
/// Displays subject cards with gradients and 3D icons
class SubjectsPanelScreen extends StatefulWidget {
  static const String id = 'subjects_panel_screen';
  
  const SubjectsPanelScreen({super.key});

  @override
  State<SubjectsPanelScreen> createState() => _SubjectsPanelScreenState();
}

class _SubjectsPanelScreenState extends State<SubjectsPanelScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      7,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    // Start animations with stagger
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFB794F6).withOpacity(0.3),
                const Color(0xFF81E6D9).withOpacity(0.3),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Subject Cards
                _buildAnimatedCard(
                  index: 0,
                  title: 'MATEMATİK',
                  iconAsset: 'assets/images/math_pdf_logo.png',
                  gradientColors: [
                    const Color(0xFFB794F6), // Purple
                    const Color(0xFFE98586), // Coral/Pink
                    const Color(0xFFFBBC88), // Orange
                  ],
                  onTap: () => _navigateToSubject(context, 'matematik', languageBloc),
                ),
                
                const SizedBox(height: 16),
                
                _buildAnimatedCard(
                  index: 1,
                  title: 'TÜRKÇE',
                  iconAsset: 'assets/images/turkish_pdf_logo.png',
                  gradientColors: [
                    const Color(0xFF56CCF2), // Light cyan
                    const Color(0xFF2F80ED), // Blue
                  ],
                  onTap: () => _navigateToSubject(context, 'turkce', languageBloc),
                ),
                
                const SizedBox(height: 16),
                
                _buildAnimatedCard(
                  index: 2,
                  title: 'BİYOLOJİ',
                  iconAsset: 'assets/images/biology_pdf_logo.png',
                  gradientColors: [
                    const Color(0xFF11998E), // Teal
                    const Color(0xFF38EF7D), // Green
                  ],
                  onTap: () => _navigateToSubject(context, 'biyoloji', languageBloc),
                ),
                
                const SizedBox(height: 16),
                
                _buildAnimatedCard(
                  index: 3,
                  title: 'KİMYA',
                  iconAsset: 'assets/images/chemistry_pdf_logo.png',
                  gradientColors: [
                    const Color(0xFFEE9CA7), // Pink
                    const Color(0xFFB794F6), // Purple
                  ],
                  onTap: () => _navigateToSubject(context, 'kimya', languageBloc),
                ),
                
                const SizedBox(height: 16),
                
                _buildAnimatedCard(
                  index: 4,
                  title: 'FİZİK',
                  iconAsset: 'assets/images/physics_pdf_logo.png',
                  gradientColors: [
                    const Color(0xFF667EEA), // Blue
                    const Color(0xFF764BA2), // Purple
                  ],
                  onTap: () => _navigateToSubject(context, 'fizik', languageBloc),
                ),
                
                const SizedBox(height: 16),
                
                _buildAnimatedCard(
                  index: 5,
                  title: 'TARİH',
                  iconAsset: 'assets/images/history_pdf_logo.png',
                  gradientColors: [
                    const Color(0xFFD4A574), // Gold/Bronze
                    const Color(0xFF8B4513), // Saddle Brown
                  ],
                  onTap: () => _navigateToSubject(context, 'tarih', languageBloc),
                ),
                
                const SizedBox(height: 16),
                
                _buildAnimatedCard(
                  index: 6,
                  title: 'COĞRAFYA',
                  iconAsset: 'assets/images/geography_pdf_logo.png',
                  gradientColors: [
                    const Color(0xFF56AB2F), // Green
                    const Color(0xFFA8E063), // Light Green
                  ],
                  onTap: () => _navigateToSubject(context, 'cografya', languageBloc),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedCard({
    required int index,
    required String title,
    required String iconAsset,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _controllers[index % _controllers.length],
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimations[index % _fadeAnimations.length],
          child: SlideTransition(
            position: _slideAnimations[index % _slideAnimations.length],
            child: _buildSubjectCard(
              title: title,
              iconAsset: iconAsset,
              gradientColors: gradientColors,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard({
    required String title,
    required String iconAsset,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      shadowColor: gradientColors.first.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              // Title
              Positioned(
                left: 28,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              
              // 3D Icon
              Positioned(
                right: 20,
                top: 15,
                bottom: 15,
                child: Hero(
                  tag: 'subject_icon_$title',
                  child: Image.asset(
                    iconAsset,
                    height: 110,
                    width: 110,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.book_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Subtle shine effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubject(BuildContext context, String subjectKey, LanguageBloc languageBloc) {
    // Map subject keys to display names and colors
    final subjectConfig = _getSubjectConfig(subjectKey);
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GradeSelectionScreen(
          subjectName: subjectConfig['name'],
          subjectKey: subjectKey,
          gradientStart: subjectConfig['gradientStart'],
          gradientEnd: subjectConfig['gradientEnd'],
          subjectIcon: subjectConfig['icon'],
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
  
  Map<String, dynamic> _getSubjectConfig(String subjectKey) {
    switch (subjectKey) {
      case 'matematik':
        return {
          'name': 'Matematik',
          'gradientStart': const Color(0xFFB794F6),
          'gradientEnd': const Color(0xFFFBBC88),
          'icon': Icons.functions_rounded,
        };
      case 'turkce':
        return {
          'name': 'Türkçe',
          'gradientStart': const Color(0xFF56CCF2),
          'gradientEnd': const Color(0xFF2F80ED),
          'icon': Icons.menu_book_rounded,
        };
      case 'biyoloji':
        return {
          'name': 'Biyoloji',
          'gradientStart': const Color(0xFF11998E),
          'gradientEnd': const Color(0xFF38EF7D),
          'icon': Icons.biotech_rounded,
        };
      case 'kimya':
        return {
          'name': 'Kimya',
          'gradientStart': const Color(0xFFEE9CA7),
          'gradientEnd': const Color(0xFFB794F6),
          'icon': Icons.science_rounded,
        };
      case 'fizik':
        return {
          'name': 'Fizik',
          'gradientStart': const Color(0xFF667EEA),
          'gradientEnd': const Color(0xFF764BA2),
          'icon': Icons.bolt_rounded,
        };
      case 'tarih':
        return {
          'name': 'Tarih',
          'gradientStart': const Color(0xFFD4A574),
          'gradientEnd': const Color(0xFF8B4513),
          'icon': Icons.history_edu_rounded,
        };
      case 'cografya':
        return {
          'name': 'Coğrafya',
          'gradientStart': const Color(0xFF56AB2F),
          'gradientEnd': const Color(0xFFA8E063),
          'icon': Icons.public_rounded,
        };
      default:
        return {
          'name': 'Ders',
          'gradientStart': const Color(0xFF667eea),
          'gradientEnd': const Color(0xFF764ba2),
          'icon': Icons.book_rounded,
        };
    }
  }
}

