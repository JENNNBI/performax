import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/app_icons.dart';
import '../blocs/bloc_exports.dart';
import 'video_grid_screen.dart';
import 'matematik_subcategory_screen.dart';

/// Multi-tiered Subject Branch Selection Screen
/// Displays all available subject branches (Matematik, Fizik, etc.) as animated cards
/// User taps a subject to navigate to the video grid feed
class SubjectBranchSelectionScreen extends StatefulWidget {
  final String sectionType; // 'VİDEO DERSLER' or 'Soru Çözümü'
  
  const SubjectBranchSelectionScreen({
    super.key,
    required this.sectionType,
  });

  @override
  State<SubjectBranchSelectionScreen> createState() => _SubjectBranchSelectionScreenState();
}

class _SubjectBranchSelectionScreenState extends State<SubjectBranchSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimController;
  late AnimationController _gridAnimController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  
  final List<AnimationController> _cardControllers = [];
  bool _isLoading = true;

  // Subject branch data with gradients and icons
  List<Map<String, dynamic>> _getSubjectBranches(LanguageBloc languageBloc) {
    return [
      {
        'name': languageBloc.translate('mathematics'),
        'key': 'Matematik',
        'icon': AppIcons.subjects['Matematik']!,
        'gradientStart': const Color(0xFF667eea),
        'gradientEnd': const Color(0xFF764ba2),
        'videoCount': 45,
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Geometri' : 'Geometry',
        'key': 'Geometri',
        'icon': AppIcons.subjects['Geometri']!,
        'gradientStart': const Color(0xFF764ba2),
        'gradientEnd': const Color(0xFF9b59b6),
        'videoCount': 30,
      },
      {
        'name': languageBloc.translate('physics'),
        'key': 'Fizik',
        'icon': AppIcons.subjects['Fizik']!,
        'gradientStart': const Color(0xFFf093fb),
        'gradientEnd': const Color(0xFFf5576c),
        'videoCount': 38,
      },
      {
        'name': languageBloc.translate('chemistry'),
        'key': 'Kimya',
        'icon': AppIcons.subjects['Kimya']!,
        'gradientStart': const Color(0xFF4facfe),
        'gradientEnd': const Color(0xFF00f2fe),
        'videoCount': 32,
      },
      {
        'name': languageBloc.translate('biology'),
        'key': 'Biyoloji',
        'icon': AppIcons.subjects['Biyoloji']!,
        'gradientStart': const Color(0xFF43e97b),
        'gradientEnd': const Color(0xFF38f9d7),
        'videoCount': 28,
      },
      {
        'name': languageBloc.translate('turkish'),
        'key': 'Türkçe',
        'icon': AppIcons.subjects['Türkçe']!,
        'gradientStart': const Color(0xFFfa709a),
        'gradientEnd': const Color(0xFFfee140),
        'videoCount': 42,
      },
      {
        'name': languageBloc.translate('history'),
        'key': 'Tarih',
        'icon': AppIcons.subjects['Tarih']!,
        'gradientStart': const Color(0xFFa8edea),
        'gradientEnd': const Color(0xFFfed6e3),
        'videoCount': 25,
      },
      {
        'name': languageBloc.translate('geography'),
        'key': 'Coğrafya',
        'icon': AppIcons.subjects['Coğrafya']!,
        'gradientStart': const Color(0xFFffecd2),
        'gradientEnd': const Color(0xFFfcb69f),
        'videoCount': 22,
      },
      {
        'name': languageBloc.translate('philosophy'),
        'key': 'Felsefe',
        'icon': AppIcons.subjects['Felsefe']!,
        'gradientStart': const Color(0xFFa18cd1),
        'gradientEnd': const Color(0xFFfbc2eb),
        'videoCount': 18,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    
    // Header animation
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    
    // Grid animation controller
    _gridAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Start animations
    _headerAnimController.forward();
    
    // Simulate loading and initialize card animations
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
    _headerAnimController.dispose();
    _gridAnimController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateToVideoGrid(
    String subjectKey,
    String subjectName,
    Color gradientStart,
    Color gradientEnd,
    IconData icon,
    {bool isComingSoon = false}
  ) {
    // Show coming soon dialog only if explicitly flagged (not for Geometri anymore)
    if (isComingSoon) {
      _showComingSoonDialog(subjectName, gradientStart);
      return;
    }
    
    // Special handling for Matematik: show subcategory selection (TYT, AYT, etc.)
    if (subjectKey == 'Matematik') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MatematikSubcategoryScreen(
            sectionType: widget.sectionType,
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            subjectIcon: icon,
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
    } else {
      // Standard navigation for other subjects
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => VideoGridScreen(
            subjectKey: subjectKey,
            subjectName: subjectName,
            sectionType: widget.sectionType,
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            subjectIcon: icon,
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
  }

  void _showComingSoonDialog(String subjectName, Color gradientStart) {
    final languageBloc = context.read<LanguageBloc>();
    final isEnglish = languageBloc.currentLanguage == 'en';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientStart, gradientStart.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEnglish ? 'Coming Soon' : 'Yakında Gelecek',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEnglish 
                  ? '$subjectName content is currently under development.'
                  : '$subjectName içeriği şu anda hazırlanıyor.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gradientStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gradientStart.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.construction_rounded, color: gradientStart, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEnglish
                          ? 'This feature will be available soon!'
                          : 'Bu özellik yakında kullanıma sunulacak!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isEnglish ? 'OK' : 'Tamam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: gradientStart,
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
        
        // Gradient colors based on section type
        final Color primaryColor = widget.sectionType.contains('VİDEO') || widget.sectionType.contains('Video') || widget.sectionType.contains('Konu')
          ? const Color(0xFF667eea) 
          : const Color(0xFFf093fb);
        final Color secondaryColor = widget.sectionType.contains('VİDEO') || widget.sectionType.contains('Video') || widget.sectionType.contains('Konu')
          ? const Color(0xFF764ba2)
          : const Color(0xFFf5576c);
        
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.9),
                  primaryColor,
                  secondaryColor,
                  secondaryColor.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Animated Header
                  FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: _buildHeader(languageBloc, primaryColor, secondaryColor),
                    ),
                  ),
                  
                  // Loading or Grid Content
                  Expanded(
                    child: _isLoading
                      ? Center(
                          child: SpinKitPulsingGrid(
                            color: Colors.white,
                            size: 60.0,
                          ),
                        )
                      : _buildSubjectGrid(subjects),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LanguageBloc languageBloc, Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Back button and title row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sectionType,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageBloc.currentLanguage == 'tr'
                        ? 'Bir ders seçin'
                        : 'Select a subject',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Decorative icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.sectionType.contains('VİDEO') || widget.sectionType.contains('Video') || widget.sectionType.contains('Konu')
                    ? Icons.school_rounded 
                    : Icons.quiz_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Instruction badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  languageBloc.currentLanguage == 'tr'
                    ? 'Video izlemek için bir ders seçin'
                    : 'Tap a subject to watch videos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGrid(List<Map<String, dynamic>> subjects) {
    return AnimatedBuilder(
      animation: _gridAnimController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final languageBloc = context.read<LanguageBloc>();
              return _buildSubjectCard(subjects[index], index, languageBloc);
            },
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, int index, LanguageBloc languageBloc) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animValue)),
            child: Opacity(
              opacity: animValue.clamp(0.0, 1.0),
              child: GestureDetector(
                onTapDown: (_) => setState(() {}),
                onTapUp: (_) {
                  setState(() {});
                  _navigateToVideoGrid(
                    subject['key'],
                    subject['name'],
                    subject['gradientStart'],
                    subject['gradientEnd'],
                    subject['icon'],
                    isComingSoon: subject['isComingSoon'] ?? false,
                  );
                },
                onTapCancel: () => setState(() {}),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        subject['gradientStart'],
                        subject['gradientEnd'],
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: subject['gradientEnd'].withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                            child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _navigateToVideoGrid(
                              subject['key'],
                              subject['name'],
                              subject['gradientStart'],
                              subject['gradientEnd'],
                              subject['icon'],
                              isComingSoon: subject['isComingSoon'] ?? false,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon with glow
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          blurRadius: 15,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      subject['icon'],
                                      size: 42,
                                      color: Colors.white,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Subject name
                                  Text(
                                    subject['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Video count badge or Coming Soon badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${subject['videoCount']} video',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

