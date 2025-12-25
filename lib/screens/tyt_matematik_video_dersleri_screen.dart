import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'video_grid_screen.dart';

/// TYT Matematik Video Dersleri Selection Screen
/// Displays Problemler Kampı and coming soon sections
/// Matches the visual design from the provided image
class TYTMatematikVideoDersleriScreen extends StatefulWidget {
  final String sectionType;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  
  const TYTMatematikVideoDersleriScreen({
    super.key,
    required this.sectionType,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
  });

  @override
  State<TYTMatematikVideoDersleriScreen> createState() => _TYTMatematikVideoDersleriScreenState();
}

class _TYTMatematikVideoDersleriScreenState extends State<TYTMatematikVideoDersleriScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  
  bool _isLoading = true;

  // CONFIGURATION: Problems Course (Problemler Kampı) playlist ID
  // Expected: 21 videos dedicated to problem-solving techniques
  // Currently using TYT Matematik playlist as fallback
  // Update this constant when the Problems Course playlist becomes available
  static const String _problemsKampiPlaylistId = 'PLHk4O6pXTZyMWD71RVkNOvMBFO-RDH_KW';

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
    
    // Content animation
    _contentController = AnimationController(
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
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _contentController.forward();
    }
  }

  void _navigateToProblemsKampi() {
    final languageBloc = context.read<LanguageBloc>();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VideoGridScreen(
          subjectKey: 'TYT_Matematik_Problemler',
          subjectName: languageBloc.currentLanguage == 'tr' ? 'Problemler Kampı' : 'Problems Camp',
          sectionType: widget.sectionType,
          gradientStart: const Color(0xFFFFD700), // Gold gradient for Problems Camp
          gradientEnd: const Color(0xFFFF6B35), // Orange gradient
          subjectIcon: widget.subjectIcon,
          playlistId: _problemsKampiPlaylistId, // Problems Course playlist
          usePlaylistData: true,
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

  void _showComingSoonDialog(String title, Color gradientStart) {
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
                  ? '$title content is currently under development.'
                  : '$title içeriği şu anda hazırlanıyor.',
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
        final isEnglish = languageBloc.currentLanguage == 'en';
        
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1030), // Deep purple
                  Color(0xFF4A1E1E), // Dark orange/red
                ],
              ),
            ),
            child: CustomScrollView(
            slivers: [
              // Animated App Bar
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
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
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                                          isEnglish ? 'TYT Mathematics Video Lessons' : 'TYT Matematik Video Dersleri',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.sectionType,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.7),
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
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              // Content Section
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // PROBLEM KAMPI Banner
                        _buildProblemKampiBanner(isEnglish),
                        
                        const SizedBox(height: 20),
                        
                        // YAKINDA SİZLERLE Sections (3 identical cards)
                        ...List.generate(3, (index) => Padding(
                          padding: EdgeInsets.only(bottom: index < 2 ? 16 : 0),
                          child: _buildComingSoonCard(isEnglish, index),
                        )),
                      ]),
                    ),
                  ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayButton(Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: color,
        size: 36,
      ),
    );
  }

  Widget _buildProblemKampiBanner(bool isEnglish) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: _navigateToProblemsKampi,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Instructors on the left
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            // Doktor. Benjamin
                            _buildInstructorCard(
                              'assets/hocalar/bunyamin_bayraktutar.png',
                              isEnglish ? 'Dr. Benjamin' : 'Doktor. Benjamin',
                              Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            // Öf Hoca
                            _buildInstructorCard(
                              'assets/hocalar/omer_faruk_cetinkaya.png',
                              isEnglish ? 'Öf Teacher' : 'Öf Hoca',
                              Colors.black87,
                            ),
                          ],
                        ),
                      ),
                      
                      // Text in the middle
                      Positioned(
                        left: 180,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEnglish ? 'PROBLEMS\nCAMP' : 'PROBLEM\nKAMPI',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2D1B4E), // Deep Purple text
                                  height: 1.1,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEnglish ? 'Dr. Benjamin & Öf Teacher' : 'Doktor Benjamin & Öf Hoca',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Play button on the right
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _buildPlayButton(const Color(0xFFFFA000)), // Gold/Orange
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

  Widget _buildInstructorCard(String imagePath, String name, Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.person, size: 30, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildComingSoonCard(bool isEnglish, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: () => _showComingSoonDialog(
                isEnglish ? 'Coming Soon Content' : 'Yakında Sizlerle',
                const Color(0xFF4DD0E1),
              ),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Text on the left
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            isEnglish ? 'COMING SOON\nWITH YOU!' : 'YAKINDA\nSİZLERLE',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1030), // Deep Dark Purple
                              height: 1.2,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      
                      // Play button on the right
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _buildPlayButton(Colors.grey),
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

