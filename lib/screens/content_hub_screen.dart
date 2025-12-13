import 'package:flutter/material.dart';
import '../blocs/bloc_exports.dart';
import 'subject_branch_selection_screen.dart';
import 'problem_solving_subjects_screen.dart';

/// Dersler (Courses) Screen - NEW DESIGN
/// Matches the provided visual reference with exact layout and styling
/// Three main sections: Topic Explanation, Problem Solving, and Activities (Coming Soon)
class ContentHubScreen extends StatefulWidget {
  const ContentHubScreen({super.key});

  @override
  State<ContentHubScreen> createState() => _ContentHubScreenState();
}

class _ContentHubScreenState extends State<ContentHubScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToContent(String contentType) {
    // Determine if this is problem solving or topic explanation
    final bool isProblemSolving = contentType.toLowerCase().contains('problem') || 
                                   contentType.toLowerCase().contains('çözüm');
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          // Navigate to Problem Solving Subjects Screen or Topic Videos
          if (isProblemSolving) {
            return const ProblemSolvingSubjectsScreen();
          } else {
            return SubjectBranchSelectionScreen(sectionType: contentType);
          }
        },
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
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final isEnglish = languageBloc.currentLanguage == 'en';
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE8F5E9), // Light green tint
                const Color(0xFFE3F2FD), // Light blue tint
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Top spacing
                  const SizedBox(height: 20),
                  
                  // Three Content Cards
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        // Card 1: KONU ANLATIMI (Topic Explanation)
                        _buildNewDesignCard(
                          context,
                          title: isEnglish ? 'TOPIC\nEXPLANATION' : 'KONU\nANLATIMI',
                          imagePath: 'assets/images/konu_anlatim2.png',
                          gradientColors: [
                            const Color(0xFF4DD0E1), // Cyan
                            const Color(0xFF1E88E5), // Blue
                          ],
                          onTap: () => _navigateToContent(
                            languageBloc.translate('topic_videos'),
                          ),
                          delay: 0,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Card 2: SORU ÇÖZÜMÜ (Problem Solving)
                        _buildNewDesignCard(
                          context,
                          title: isEnglish ? 'PROBLEM\nSOLVING' : 'SORU\nÇÖZÜMÜ',
                          imagePath: 'assets/images/soru_cozum2.png',
                          gradientColors: [
                            const Color(0xFF4DD0E1), // Cyan
                            const Color(0xFF1E88E5), // Blue
                          ],
                          onTap: () => _navigateToContent(
                            languageBloc.translate('problem_solving'),
                          ),
                          delay: 150,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Card 3: ETKİNLİK (Activities - Coming Soon)
                        _buildNewDesignCard(
                          context,
                          title: isEnglish ? 'ACTIVITIES\nCOMING SOON WITH YOU!' : 'ETKİNLİK\nYAKINDA SİZLERLE!',
                          imagePath: 'assets/images/etkinlik2.png',
                          gradientColors: [
                            const Color(0xFF4DD0E1), // Cyan
                            const Color(0xFF1E88E5), // Blue
                          ],
                          onTap: () => _showComingSoonDialog(context, isEnglish),
                          delay: 300,
                          isLocked: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Show Coming Soon dialog for locked features
  void _showComingSoonDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.schedule_rounded, color: Color(0xFF1E88E5)),
              const SizedBox(width: 12),
              Text(
                isEnglish ? 'Coming Soon' : 'Yakında Sizlerle',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            isEnglish 
              ? 'This feature is not yet available. Stay tuned!'
              : 'Bu özellik henüz hazır değil. Yakında sizlerle buluşacak!',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isEnglish ? 'OK' : 'Tamam',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// NEW DESIGN: Build card matching the visual reference
  Widget _buildNewDesignCard(
    BuildContext context, {
    required String title,
    required String imagePath,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required int delay,
    bool isLocked = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[1].withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Text on the left side
                      Positioned(
                        left: 24,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: title.contains('ANLATIMI') || title.contains('EXPLANATION')
                                  ? Colors.black
                                  : Colors.white,
                              height: 1.2,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      
                      // Image on the right side
                      Positioned(
                        right: -20,
                        top: 0,
                        bottom: 0,
                        child: Image.asset(
                          imagePath,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(width: 180);
                          },
                        ),
                      ),
                      
                      // Lock icon overlay for locked features
                      if (isLocked)
                        Positioned(
                          left: 20,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/lock.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFF1E88E5),
                                  size: 32,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
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

