import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/app_icons.dart';
import '../blocs/bloc_exports.dart';
import 'grade_selection_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Multi-tiered Subject Branch Selection Screen
/// Displays all available subject branches (Matematik, Fizik, etc.)
class SubjectBranchSelectionScreen extends StatefulWidget {
  final String sectionType; // 'VİDEO DERSLER', 'Soru Çözümü', 'PDF Notları'
  
  const SubjectBranchSelectionScreen({
    super.key,
    required this.sectionType,
  });

  @override
  State<SubjectBranchSelectionScreen> createState() => _SubjectBranchSelectionScreenState();
}

class _SubjectBranchSelectionScreenState extends State<SubjectBranchSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _gridAnimController;
  bool _isLoading = true;

  // Subject branch data with gradients and icons
  List<Map<String, dynamic>> _getSubjectBranches(LanguageBloc languageBloc) {
    return [
      {
        'name': languageBloc.translate('mathematics'),
        'key': 'Matematik',
        'icon': AppIcons.subjects['Matematik']!,
        'accentColor': const Color(0xFF667eea),
        'videoCount': 45,
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Geometri' : 'Geometry',
        'key': 'Geometri',
        'icon': AppIcons.subjects['Geometri']!,
        'accentColor': const Color(0xFF764ba2),
        'videoCount': 30,
      },
      {
        'name': languageBloc.translate('physics'),
        'key': 'Fizik',
        'icon': AppIcons.subjects['Fizik']!,
        'accentColor': const Color(0xFFf5576c),
        'videoCount': 38,
      },
      {
        'name': languageBloc.translate('chemistry'),
        'key': 'Kimya',
        'icon': AppIcons.subjects['Kimya']!,
        'accentColor': const Color(0xFF00f2fe),
        'videoCount': 32,
      },
      {
        'name': languageBloc.translate('biology'),
        'key': 'Biyoloji',
        'icon': AppIcons.subjects['Biyoloji']!,
        'accentColor': const Color(0xFF43e97b),
        'videoCount': 28,
      },
      {
        'name': languageBloc.translate('turkish'),
        'key': 'Türkçe',
        'icon': AppIcons.subjects['Türkçe']!,
        'accentColor': const Color(0xFFfa709a),
        'videoCount': 42,
      },
      {
        'name': languageBloc.translate('history'),
        'key': 'Tarih',
        'icon': AppIcons.subjects['Tarih']!,
        'accentColor': const Color(0xFFfed6e3),
        'videoCount': 25,
      },
      {
        'name': languageBloc.translate('geography'),
        'key': 'Coğrafya',
        'icon': AppIcons.subjects['Coğrafya']!,
        'accentColor': const Color(0xFFfcb69f),
        'videoCount': 22,
      },
      {
        'name': languageBloc.translate('philosophy'),
        'key': 'Felsefe',
        'icon': AppIcons.subjects['Felsefe']!,
        'accentColor': const Color(0xFFa18cd1),
        'videoCount': 18,
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Türk Dili ve Edebiyatı' : 'Literature',
        'key': 'Edebiyat',
        'icon': Icons.menu_book_rounded, // Using standard icon as AppIcons might not have it yet
        'accentColor': const Color(0xFFff9a9e),
        'videoCount': 35,
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Din Kültürü' : 'Religious Culture',
        'key': 'Din',
        'icon': Icons.mosque_rounded, // Using standard icon
        'accentColor': const Color(0xFF84fab0),
        'videoCount': 15,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    
    // Grid animation controller
    _gridAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _gridAnimController.forward();
      }
    });
  }

  @override
  void dispose() {
    _gridAnimController.dispose();
    super.dispose();
  }

  void _navigateToNextStep(
    String subjectKey,
    String subjectName,
    Color accentColor,
    IconData icon,
    {bool isComingSoon = false}
  ) {
    if (isComingSoon) {
      _showComingSoonDialog(subjectName, accentColor);
      return;
    }
    
    // Updated Flow: Branch -> Grade -> Exam Type (for Video)
    // We navigate to GradeSelectionScreen for ALL types to maintain consistency
    // GradeSelectionScreen will handle the next step based on sectionType
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradeSelectionScreen(
          subjectName: subjectName,
          subjectKey: subjectKey,
          gradientStart: accentColor,
          gradientEnd: accentColor.withValues(alpha: 0.7),
          subjectIcon: icon,
          sectionType: widget.sectionType,
        ),
      ),
    );
  }

  void _showComingSoonDialog(String subjectName, Color accentColor) {
    final languageBloc = context.read<LanguageBloc>();
    final isEnglish = languageBloc.currentLanguage == 'en';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: NeumorphicColors.getBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.schedule_rounded, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEnglish ? 'Coming Soon' : 'Yakında Gelecek',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicColors.getText(context),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isEnglish 
              ? '$subjectName content is currently under development.'
              : '$subjectName içeriği şu anda hazırlanıyor.',
            style: TextStyle(
              fontSize: 16,
              color: NeumorphicColors.getText(context).withValues(alpha: 0.8),
            ),
          ),
          actions: [
            NeumorphicButton(
              onPressed: () => Navigator.of(context).pop(),
              borderRadius: 12,
              child: Text(
                isEnglish ? 'OK' : 'Tamam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final subjects = _getSubjectBranches(languageBloc);
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
                              widget.sectionType,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              languageBloc.currentLanguage == 'tr'
                                ? 'Bir ders seçin'
                                : 'Select a subject',
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
                          widget.sectionType.contains('VİDEO') || widget.sectionType.contains('Video') || widget.sectionType.contains('Konu')
                            ? Icons.school_rounded 
                            : (widget.sectionType.contains('PDF') ? Icons.picture_as_pdf_rounded : Icons.quiz_rounded),
                          color: NeumorphicColors.accentBlue,
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
                          color: NeumorphicColors.accentBlue,
                          size: 60.0,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          return _buildSubjectCard(subjects[index], index, languageBloc);
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

  Widget _buildSubjectCard(Map<String, dynamic> subject, int index, LanguageBloc languageBloc) {
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
              onPressed: () => _navigateToNextStep(
                subject['key'],
                subject['name'],
                subject['accentColor'],
                subject['icon'],
                isComingSoon: subject['isComingSoon'] ?? false,
              ),
              padding: EdgeInsets.zero,
              borderRadius: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 50,
                    shape: BoxShape.circle,
                    depth: -3, // Inset for icon
                    child: Icon(
                      subject['icon'],
                      size: 32,
                      color: subject['accentColor'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subject['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeumorphicColors.getText(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Optional: Hide video count for non-video sections if desired, or keep it generic
                  if (widget.sectionType.contains('Video') || widget.sectionType.contains('Konu'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${subject['videoCount']} video',
                        style: TextStyle(
                          fontSize: 12,
                          color: NeumorphicColors.getText(context).withValues(alpha: 0.5),
                        ),
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
