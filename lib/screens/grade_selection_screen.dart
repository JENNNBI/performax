import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'exam_type_selection_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Generic Grade Selection Screen
/// Shows grade level buttons (9.SINIF, 10.SINIF, 11.SINIF, 12.SINIF)
/// Standardized for Video, PDF, and Question Solving
class GradeSelectionScreen extends StatefulWidget {
  final String subjectName;
  final String subjectKey;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  final String sectionType; // 'Video Lessons', 'PDF Notes', 'Question Solving'
  
  const GradeSelectionScreen({
    super.key,
    required this.subjectName,
    required this.subjectKey,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
    this.sectionType = 'Video Lessons',
  });

  @override
  State<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends State<GradeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Grid animation
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _loadData();
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _gridController.forward();
    }
  }

  /// Get grade level options
  List<Map<String, dynamic>> _getGradeLevels(LanguageBloc languageBloc) {
    var grades = [
      {
        'name': '9. SINIF',
        'key': '9_sinif',
        'description': languageBloc.currentLanguage == 'tr'
          ? '9. Sınıf ${widget.subjectName}'
          : '9th Grade ${widget.subjectName}',
        'accentColor': const Color(0xFF667EEA),
      },
      {
        'name': '10. SINIF',
        'key': '10_sinif',
        'description': languageBloc.currentLanguage == 'tr'
          ? '10. Sınıf ${widget.subjectName}'
          : '10th Grade ${widget.subjectName}',
        'accentColor': const Color(0xFFF37335),
      },
      {
        'name': '11. SINIF',
        'key': '11_sinif',
        'description': languageBloc.currentLanguage == 'tr'
          ? '11. Sınıf ${widget.subjectName}'
          : '11th Grade ${widget.subjectName}',
        'accentColor': const Color(0xFFF38181),
      },
      {
        'name': '12. SINIF',
        'key': '12_sinif',
        'description': languageBloc.currentLanguage == 'tr'
          ? '12. Sınıf ${widget.subjectName}'
          : '12th Grade ${widget.subjectName}',
        'accentColor': const Color(0xFF43E97B),
      },
    ];

    // Strict Data Constraint: Subject vs. Grade Mapping
    // Matrix:
    // * Türkçe: 9, 10
    // * Türk Dili ve Edebiyatı: 9, 10, 11, 12
    // * Matematik: 9, 10, 11, 12
    // * Geometri: 9, 10, 11, 12
    // * Fizik: 9, 10, 11, 12
    // * Kimya: 9, 10, 11, 12
    // * Biyoloji: 9, 10, 11, 12
    // * Tarih: 9, 10, 11, 12
    // * Coğrafya: 9, 10, 11, 12
    // * Felsefe: 10, 11 (No 9 or 12)
    // * Din Kültürü: 9, 10, 11, 12

    final subjectName = widget.subjectName;
    final subjectKey = widget.subjectKey; // e.g. 'Felsefe', 'Turkce'

    // Determine allowed grades based on Subject Name (or Key)
    List<String> allowedGrades;

    if (subjectName == 'Türkçe' || subjectName == 'Turkish') {
      allowedGrades = ['9_sinif', '10_sinif'];
    } else if (subjectName == 'Felsefe' || subjectName == 'Philosophy') {
      allowedGrades = ['10_sinif', '11_sinif'];
    } else {
      // All others (Matematik, Edebiyat, Fizik, etc.) -> 9, 10, 11, 12
      allowedGrades = ['9_sinif', '10_sinif', '11_sinif', '12_sinif'];
    }

    // Filter the grades list
    grades = grades.where((g) => allowedGrades.contains(g['key'])).toList();

    return grades;
  }

  void _onGradeSelected(Map<String, dynamic> gradeLevel) {
    // For Video Lessons, we go to Step 3: Exam Type Selection
    // For consistency, let's apply this to others or handle appropriately
    
    // For now, Video Lessons definitely goes to Exam Type
    if (widget.sectionType.contains('Video') || widget.sectionType.contains('Konu')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamTypeSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            gradeLevel: gradeLevel['key'],
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            sectionType: widget.sectionType,
          ),
        ),
      );
    } else {
      // For PDF/Questions, show Coming Soon or navigate to content if ready
      // The user didn't explicitly ask for Exam Type on PDF/Questions, but implied "Synchronize".
      // If I don't show Exam Type, where do I go? Content list for that grade?
      // I'll show Coming Soon for now as safe default or ExamType if appropriate.
      // Let's route to ExamTypeSelectionScreen for ALL to ensure "Identical Flow" logic where possible,
      // or just show coming soon if content missing.
      
      // Let's try to route to ExamType for all, assuming content structure is similar.
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamTypeSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            gradeLevel: gradeLevel['key'],
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            sectionType: widget.sectionType,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final gradeLevels = _getGradeLevels(languageBloc);
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
                              languageBloc.currentLanguage == 'tr'
                                  ? 'Sınıf Seçimi'
                                  : 'Select Grade',
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
                
                // Grid
                Expanded(
                  child: _isLoading
                    ? Center(
                        child: SpinKitPulsingGrid(
                          color: widget.gradientStart,
                          size: 60.0,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: gradeLevels.length,
                        itemBuilder: (context, index) {
                          return _buildGradeCard(gradeLevels[index], index);
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> gradeLevel, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: NeumorphicButton(
              onPressed: () => _onGradeSelected(gradeLevel),
              padding: EdgeInsets.zero,
              borderRadius: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gradeLevel['name'].split('.')[0], // "9"
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: gradeLevel['accentColor'],
                    ),
                  ),
                  Text(
                    gradeLevel['name'].split(' ')[1], // "SINIF"
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: NeumorphicColors.getText(context).withValues(alpha: 0.6),
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
