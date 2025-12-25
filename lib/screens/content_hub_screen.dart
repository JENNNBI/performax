import 'package:flutter/material.dart';
import '../blocs/bloc_exports.dart';
import 'subject_branch_selection_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Dersler (Courses) Screen - Neumorphic Refactor
class ContentHubScreen extends StatefulWidget {
  const ContentHubScreen({super.key});

  @override
  State<ContentHubScreen> createState() => _ContentHubScreenState();
}

class _ContentHubScreenState extends State<ContentHubScreen> {
  void _navigateToContent(String contentType) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return SubjectBranchSelectionScreen(sectionType: contentType);
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
        final bgColor = NeumorphicColors.getBackground(context);
        
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120), // Space for floating dock
                      children: [
                        // Card 1: KONU ANLATIMI
                        _buildNeumorphicContentCard(
                          context,
                          title: isEnglish ? 'TOPIC\nEXPLANATION' : 'KONU\nANLATIMI',
                          subtitle: isEnglish ? 'Watch video lessons' : 'Video dersleri izle',
                          icon: Icons.play_circle_filled_rounded,
                          accentColor: const Color(0xFF4DD0E1),
                          onTap: () => _navigateToContent(
                            languageBloc.translate('topic_videos'),
                          ),
                          delay: 0,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Card 2: SORU ÇÖZÜMÜ
                        _buildNeumorphicContentCard(
                          context,
                          title: isEnglish ? 'PROBLEM\nSOLVING' : 'SORU\nÇÖZÜMÜ',
                          subtitle: isEnglish ? 'Practice questions' : 'Soru çözümleri izle',
                          icon: Icons.quiz_rounded,
                          accentColor: const Color(0xFF1E88E5),
                          onTap: () => _navigateToContent(
                            languageBloc.translate('problem_solving'),
                          ),
                          delay: 150,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Card 3: DERS NOTLARI
                        _buildNeumorphicContentCard(
                          context,
                          title: isEnglish ? 'LECTURE\nNOTES (PDF)' : 'DERS\nNOTLARI',
                          subtitle: isEnglish ? 'Download PDFs' : 'PDF notlarını incele',
                          icon: Icons.picture_as_pdf_rounded,
                          accentColor: const Color(0xFFFF5722),
                          onTap: () => _navigateToContent(
                            isEnglish ? 'PDF Notes' : 'PDF Notları',
                          ),
                          delay: 300,
                        ),

                        const SizedBox(height: 24),

                        // Card 4: ETKİNLİK
                        _buildNeumorphicContentCard(
                          context,
                          title: isEnglish ? 'ACTIVITIES' : 'ETKİNLİK',
                          subtitle: isEnglish ? 'Coming Soon' : 'Yakında',
                          icon: Icons.event_note_rounded,
                          accentColor: const Color(0xFF7B1FA2),
                          onTap: () => _showComingSoonDialog(context, isEnglish),
                          delay: 450,
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
  
  void _showComingSoonDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: NeumorphicColors.getBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.schedule_rounded, color: NeumorphicColors.getText(context)),
              const SizedBox(width: 12),
              Text(
                isEnglish ? 'Coming Soon' : 'Yakında Sizlerle',
                style: TextStyle(
                  color: NeumorphicColors.getText(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            isEnglish 
              ? 'This feature is not yet available. Stay tuned!'
              : 'Bu özellik henüz hazır değil. Yakında sizlerle buluşacak!',
            style: TextStyle(color: NeumorphicColors.getText(context)),
          ),
          actions: [
            NeumorphicButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isEnglish ? 'OK' : 'Tamam',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: NeumorphicColors.accentBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNeumorphicContentCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required int delay,
    bool isLocked = false,
  }) {
    final textColor = NeumorphicColors.getText(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: NeumorphicButton(
              onPressed: onTap,
              padding: const EdgeInsets.all(24),
              borderRadius: 30,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            height: 1.1,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(20),
                    shape: BoxShape.circle,
                    color: isLocked 
                        ? Colors.grey.withValues(alpha: 0.1) 
                        : accentColor.withValues(alpha: 0.1),
                    depth: isLocked ? 2 : -4, // Inset for active, outset for locked/flat
                    child: Icon(
                      isLocked ? Icons.lock_rounded : icon,
                      size: 32,
                      color: isLocked ? Colors.grey : accentColor,
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
}
