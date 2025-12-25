import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Slick onboarding sequence for first-time users
class OnboardingScreen extends StatefulWidget {
  static const String id = 'onboarding_screen';
  
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.school_rounded,
      title: 'Akıllı Öğrenme',
      description: 'Yapay zeka destekli kişisel öğrenme asistanınız ile tüm derslerinizde başarıya ulaşın',
      accentColor: const Color(0xFF667eea),
    ),
    OnboardingPage(
      icon: Icons.psychology_rounded,
      title: 'AI Asistan',
      description: 'Sorularınızı anında yanıtlayan, konuları açıklayan ve size rehberlik eden AI öğretmeniniz',
      accentColor: const Color(0xFF00f2fe),
    ),
    OnboardingPage(
      icon: Icons.video_library_rounded,
      title: 'Zengin İçerik',
      description: 'Konu anlatımı, soru çözümü videoları ve interaktif PDF ders kitapları',
      accentColor: const Color(0xFF43e97b),
    ),
    OnboardingPage(
      icon: Icons.insights_rounded,
      title: 'İlerleme Takibi',
      description: 'Çalışma istatistiklerinizi takip edin ve hedeflerinize ulaşın',
      accentColor: const Color(0xFFfa709a),
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Restart animations
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = NeumorphicColors.getBackground(context);
    final textColor = NeumorphicColors.getText(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _currentPage < _pages.length - 1
                    ? TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Atla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : const SizedBox(height: 48), // Placeholder to keep layout stable
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index == _currentPage);
                },
              ),
            ),
            
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: _currentPage == index ? 24 : 12,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: _currentPage == index
                              ? _pages[_currentPage].accentColor
                              : textColor.withValues(alpha: 0.2),
                        ),
                      );
                    }),
                  ),
                  
                  // Next/Get Started button
                  NeumorphicButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    color: _pages[_currentPage].accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    borderRadius: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? 'Başlayalım' : 'İleri',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_currentPage != _pages.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, bool isActive) {
    final textColor = NeumorphicColors.getText(context);

    return FadeTransition(
      opacity: isActive ? _fadeAnimation : const AlwaysStoppedAnimation(1),
      child: SlideTransition(
        position: isActive ? _slideAnimation : const AlwaysStoppedAnimation(Offset.zero),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Card
              NeumorphicContainer(
                padding: const EdgeInsets.all(48),
                shape: BoxShape.circle,
                color: page.accentColor.withValues(alpha: 0.1),
                depth: -5, // Inset
                child: Icon(
                  page.icon,
                  size: 80,
                  color: page.accentColor,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Title
              Text(
                page.title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Description
              Text(
                page.description,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: textColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}
