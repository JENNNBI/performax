import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'video_grid_screen.dart';
import 'matematik_subcategory_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

class ExamTypeSelectionScreen extends StatefulWidget {
  final String subjectName;
  final String subjectKey;
  final String gradeLevel; // e.g., '9_sinif', '10_sinif', '11_sinif' (Grade 12 removed)
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  final String sectionType; // 'Video Lessons', 'PDF Notes', 'Question Solving'

  const ExamTypeSelectionScreen({
    super.key,
    required this.subjectName,
    required this.subjectKey,
    required this.gradeLevel,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
    required this.sectionType,
  });

  @override
  State<ExamTypeSelectionScreen> createState() => _ExamTypeSelectionScreenState();
}

class _ExamTypeSelectionScreenState extends State<ExamTypeSelectionScreen> with TickerProviderStateMixin {
  late AnimationController _animController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Auto-navigate logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoNavigate();
    });
  }

  void _checkAndAutoNavigate() {
    // UI Logic: Hide Exam Type Toggle (Global Rule)
    // If selectedGrade is 9 or 10, Hide the TYT/AYT selector immediately (implied TYT).
    // We achieve this by auto-navigating to TYT content.
    
    if (widget.gradeLevel == '9_sinif' || widget.gradeLevel == '10_sinif') {
      _navigateToContent('TYT', replace: true);
      return;
    }
    
    // Existing logic for subject-based auto-nav (if grade is 11)
    final tytOnly = ['Türkçe', 'Temel Matematik'];
    final aytOnly = ['Türk Dili ve Edebiyatı', 'İleri Matematik', 'Felsefe Grubu'];

    if (tytOnly.contains(widget.subjectName)) {
      _navigateToContent('TYT', replace: true);
    } else if (aytOnly.contains(widget.subjectName)) {
      _navigateToContent('AYT', replace: true);
    } else {
      // Show selection UI
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToContent(String examType, {bool replace = false}) {
    // examType: 'TYT' or 'AYT'
    // For Math Video Lessons TYT, we might have a subcategory screen.
    // For others, we go to the grid.
    
    Route route;
    
    if (widget.subjectKey == 'Matematik' && examType == 'TYT' && 
       (widget.sectionType.contains('Video') || widget.sectionType.contains('Konu'))) {
       route = MaterialPageRoute(
          builder: (context) => MatematikSubcategoryScreen(
            sectionType: widget.sectionType,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
          ),
        );
    } else {
      // Use VideoGridScreen as a generic content grid
      // It uses sectionType to query Firestore
      // Pass '9' or '10' if strictly selected, but this screen usually comes BEFORE grade filtering in grids?
      // Actually, VideoGridScreen has its own filters.
      // We just pass the Subject Key.
      
      route = MaterialPageRoute(
          builder: (context) => VideoGridScreen(
            subjectKey: '${examType}_${widget.subjectKey}', // e.g. TYT_Fizik
            subjectName: '${widget.subjectName} $examType',
            sectionType: widget.sectionType,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
          ),
        );
    }

    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final bgColor = NeumorphicColors.getBackground(context);
        final textColor = NeumorphicColors.getText(context);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      NeumorphicButton(
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: Icon(Icons.arrow_back_rounded, color: textColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subjectName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Sınav Türü Seçimi',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      NeumorphicContainer(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: Icon(
                          widget.subjectIcon,
                          color: widget.gradientStart,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: SpinKitPulsingGrid(
                            color: widget.gradientStart,
                            size: 60.0,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildExamCard('TYT', 'Temel Yeterlilik Testi', const Color(0xFFA8E063), 0, widget.subjectName),
                              const SizedBox(height: 24),
                              _buildExamCard('AYT', 'Alan Yeterlilik Testi', const Color(0xFFF5CBCB), 1, widget.subjectName),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamCard(String title, String subtitle, Color accentColor, int index, String subjectName) {
    // Determine visibility based on subject
    final isTytOnly = ['Türkçe', 'Temel Matematik'].contains(subjectName);
    final isAytOnly = ['Türk Dili ve Edebiyatı', 'İleri Matematik', 'Felsefe Grubu'].contains(subjectName);
    
    // Hide TYT card if AYT only
    if (title == 'TYT' && isAytOnly) return const SizedBox.shrink();
    // Hide AYT card if TYT only
    if (title == 'AYT' && isTytOnly) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: NeumorphicButton(
              onPressed: () => _navigateToContent(title),
              padding: const EdgeInsets.all(32),
              borderRadius: 30,
              child: Row(
                children: [
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(20),
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.1),
                    depth: -4,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: NeumorphicColors.getText(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: NeumorphicColors.getText(context).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: NeumorphicColors.getText(context).withValues(alpha: 0.3),
                    size: 32,
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
