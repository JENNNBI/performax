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
  final String gradeLevel; // e.g., '12_sinif'
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
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToContent(String examType) {
    // examType: 'TYT' or 'AYT'
    // For Math Video Lessons TYT, we might have a subcategory screen.
    // For others, we go to the grid.
    
    if (widget.subjectKey == 'Matematik' && examType == 'TYT' && 
       (widget.sectionType.contains('Video') || widget.sectionType.contains('Konu'))) {
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatematikSubcategoryScreen(
            sectionType: widget.sectionType,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
          ),
        ),
      );
    } else {
      // Use VideoGridScreen as a generic content grid
      // It uses sectionType to query Firestore
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoGridScreen(
            subjectKey: '${examType}_${widget.subjectKey}', // e.g. TYT_Fizik
            subjectName: '${widget.subjectName} $examType',
            sectionType: widget.sectionType,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
          ),
        ),
      );
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
                              _buildExamCard('TYT', 'Temel Yeterlilik Testi', const Color(0xFFA8E063), 0),
                              const SizedBox(height: 24),
                              _buildExamCard('AYT', 'Alan Yeterlilik Testi', const Color(0xFFF5CBCB), 1),
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

  Widget _buildExamCard(String title, String subtitle, Color accentColor, int index) {
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
