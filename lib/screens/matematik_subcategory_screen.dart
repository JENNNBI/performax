import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'video_grid_screen.dart';
import 'tyt_matematik_video_dersleri_screen.dart';

/// Matematik Subcategory Selection Screen
/// Shows TYT Matematik, AYT Matematik, and other math subcategories
/// Special handling for TYT Matematik to load playlist: PLHk4O6pXTZyMWD71RVkNOvMBFO-RDH_KW
class MatematikSubcategoryScreen extends StatefulWidget {
  final String sectionType; // 'VİDEO DERSLER' or 'Soru Çözümü'
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  
  const MatematikSubcategoryScreen({
    super.key,
    required this.sectionType,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
  });

  @override
  State<MatematikSubcategoryScreen> createState() => _MatematikSubcategoryScreenState();
}

class _MatematikSubcategoryScreenState extends State<MatematikSubcategoryScreen>
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

  /// Get Matematik subcategories (only TYT and AYT - Geometri is now separate)
  List<Map<String, dynamic>> _getSubcategories(LanguageBloc languageBloc) {
    return [
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'TYT Matematik Video Dersleri' : 'TYT Mathematics Video Lessons',
        'key': 'TYT_Matematik',
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Temel Yeterlilik Testi - Matematik'
          : 'Basic Proficiency Test - Mathematics',
        'hasPlaylist': true,  // ← Special flag for playlist loading
        'playlistId': 'PLHk4O6pXTZyMWD71RVkNOvMBFO-RDH_KW',  // ← The specified playlist
        'videoCount': '20+',
        'difficulty': 'Temel',
        'icon': Icons.school_rounded,
        'accentColor': const Color(0xFF4facfe),
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'AYT Matematik Video Dersleri' : 'AYT Mathematics Video Lessons',
        'key': 'AYT_Matematik',
        'description': languageBloc.currentLanguage == 'tr'
          ? 'Alan Yeterlilik Testi - Matematik'
          : 'Field Proficiency Test - Mathematics',
        'hasPlaylist': false,
        'videoCount': '30+',
        'difficulty': 'İleri',
        'icon': Icons.auto_graph_rounded,
        'accentColor': const Color(0xFF667eea),
      },
    ];
  }

  void _navigateToVideoGrid(Map<String, dynamic> subcategory) {
    // Special handling for TYT Matematik - navigate to selection screen
    if (subcategory['key'] == 'TYT_Matematik') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => TYTMatematikVideoDersleriScreen(
            sectionType: widget.sectionType,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
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
      // Standard navigation for AYT Matematik
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => VideoGridScreen(
            subjectKey: subcategory['key'],
            subjectName: subcategory['name'],
            sectionType: widget.sectionType,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            playlistId: subcategory['hasPlaylist'] == true ? subcategory['playlistId'] : null,
            usePlaylistData: subcategory['hasPlaylist'] == true,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final subcategories = _getSubcategories(languageBloc);
        
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
                                        color: Colors.white.withValues(alpha: 0.2),
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
                                            languageBloc.translate('mathematics'),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.sectionType,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withValues(alpha: 0.9),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
                    color: widget.gradientStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.gradientStart.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_rounded,
                        color: widget.gradientStart,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        languageBloc.currentLanguage == 'tr'
                          ? 'Kategori seçin'
                          : 'Select category',
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
              
              // Loading or Subcategory Cards
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
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildSubcategoryCard(subcategories[index], index);
                        },
                        childCount: subcategories.length,
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: () => _navigateToVideoGrid(subcategory),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientStart.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Gradient accent on the left
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                subcategory['accentColor'],
                                subcategory['accentColor'].withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    subcategory['accentColor'],
                                    subcategory['accentColor'].withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: subcategory['accentColor'].withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                subcategory['icon'],
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          subcategory['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      // Special badge for TYT Matematik
                                      if (subcategory['hasPlaylist'] == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFFFD700),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.playlist_play_rounded,
                                                size: 14,
                                                color: Color(0xFFD4AF37),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Playlist',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFD4AF37),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subcategory['description'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildInfoChip(
                                        Icons.play_circle_outline,
                                        subcategory['videoCount'],
                                        subcategory['accentColor'],
                                      ),
                                      const SizedBox(width: 12),
                                      _buildInfoChip(
                                        Icons.bar_chart_rounded,
                                        subcategory['difficulty'],
                                        subcategory['accentColor'],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Arrow
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey[400],
                              size: 20,
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
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

