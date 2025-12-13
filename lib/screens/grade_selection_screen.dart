import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'matematik_tyt_content_screen.dart';

/// Generic Grade Selection Screen
/// Shows grade level buttons (9.SINIF, 10.SINIF, 11.SINIF, TYT, AYT)
/// Used by all subjects to maintain consistent hierarchy
class GradeSelectionScreen extends StatefulWidget {
  final String subjectName;
  final String subjectKey;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  
  const GradeSelectionScreen({
    super.key,
    required this.subjectName,
    required this.subjectKey,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
  });

  @override
  State<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends State<GradeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _gridController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    
    // Grid animation
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Start animations
    _headerController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _headerController.dispose();
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
    return [
      {
        'name': '9.SINIF',
        'key': '9_sinif',
        'description': languageBloc.currentLanguage == 'tr'
          ? '9. Sınıf ${widget.subjectName}'
          : '9th Grade ${widget.subjectName}',
        'gradientColors': [
          const Color(0xFF667EEA), // Blue
          const Color(0xFF00D4FF), // Cyan
        ],
        'icon': Icons.looks_one_rounded,
      },
      {
        'name': '10.SINIF',
        'key': '10_sinif',
        'description': languageBloc.currentLanguage == 'tr'
          ? '10. Sınıf ${widget.subjectName}'
          : '10th Grade ${widget.subjectName}',
        'gradientColors': [
          const Color(0xFFFDC830), // Yellow
          const Color(0xFFF37335), // Orange
        ],
        'icon': Icons.looks_two_rounded,
      },
      {
        'name': '11.SINIF',
        'key': '11_sinif',
        'description': languageBloc.currentLanguage == 'tr'
          ? '11. Sınıf ${widget.subjectName}'
          : '11th Grade ${widget.subjectName}',
        'gradientColors': [
          const Color(0xFFFCE38A), // Light Yellow
          const Color(0xFFF38181), // Pink
        ],
        'icon': Icons.looks_3_rounded,
      },
      {
        'name': 'TYT',
        'key': 'tyt',
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Temel Yeterlilik Testi'
          : 'Basic Proficiency Test',
        'gradientColors': [
          const Color(0xFF56CCF2), // Cyan
          const Color(0xFFA8E063), // Green
        ],
        'icon': Icons.school_rounded,
        'hasPDF': widget.subjectKey == 'matematik', // Only Matematik has PDF for now
      },
      {
        'name': 'AYT',
        'key': 'ayt',
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Alan Yeterlilik Testi'
          : 'Field Proficiency Test',
        'gradientColors': [
          const Color(0xFFFCE38A), // Light Yellow
          const Color(0xFFF5CBCB), // Light Pink
        ],
        'icon': Icons.auto_awesome_rounded,
      },
    ];
  }

  void _navigateToContent(Map<String, dynamic> gradeLevel) {
    // Check if this is Matematik TYT with content
    if (widget.subjectKey == 'matematik' && gradeLevel['key'] == 'tyt') {
      // Navigate to TYT content selection screen
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MatematikTYTContentScreen(
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
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
      // Show coming soon for all other combinations
      _showComingSoonMessage(gradeLevel['name']);
    }
  }

  /// Show "Coming Soon" message
  void _showComingSoonMessage(String gradeName) {
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
                    colors: [widget.gradientStart, widget.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Yakında Gelecek',
                  style: TextStyle(
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
                '${widget.subjectName} - $gradeName içeriği yakında eklenecek!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.gradientStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Şu anda sadece Matematik TYT içeriği aktif.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: widget.gradientStart,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Tamam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
        final gradeLevels = _getGradeLevels(languageBloc);
        
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: CustomScrollView(
            slivers: [
              // Animated App Bar
              SliverAppBar(
                expandedHeight: 160.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: widget.gradientStart,
                flexibleSpace: FlexibleSpaceBar(
                  background: FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.gradientStart,
                              widget.gradientEnd,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        widget.subjectIcon,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.subjectName,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            languageBloc.currentLanguage == 'tr'
                                                ? 'Sınıf Seçimi'
                                                : 'Select Grade',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              // Info Badge
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.gradientStart.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.gradientStart.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.class_rounded,
                        color: widget.gradientStart,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        languageBloc.currentLanguage == 'tr'
                            ? 'Sınıf seviyesi seçin'
                            : 'Select grade level',
                        style: TextStyle(
                          color: widget.gradientStart,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Loading or Grade Level Grid
              _isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: SpinKitPulsingGrid(
                        color: widget.gradientStart,
                        size: 60.0,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildGradeCard(gradeLevels[index], index);
                        },
                        childCount: gradeLevels.length,
                      ),
                    ),
                  ),
            ],
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
            child: GestureDetector(
              onTap: () => _navigateToContent(gradeLevel),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradeLevel['gradientColors'],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: gradeLevel['gradientColors'][0].withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Grade name
                    Center(
                      child: Text(
                        gradeLevel['name'],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    
                    // PDF badge for Matematik TYT
                    if (gradeLevel['hasPDF'] == true)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 14,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'PDF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
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
                              Colors.white.withOpacity(0.3),
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
          ),
        );
      },
    );
  }
}
