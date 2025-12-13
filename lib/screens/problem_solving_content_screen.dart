import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'test_selection_screen.dart';

/// Problem Solving Content Screen with Book Covers
/// Shows content with book cover thumbnails on the right
class ProblemSolvingContentScreen extends StatefulWidget {
  final String subjectName;
  final String subjectKey;
  final String gradeLevel;
  final Color gradientStart;
  final Color gradientEnd;
  
  const ProblemSolvingContentScreen({
    super.key,
    required this.subjectName,
    required this.subjectKey,
    required this.gradeLevel,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  State<ProblemSolvingContentScreen> createState() => _ProblemSolvingContentScreenState();
}

class _ProblemSolvingContentScreenState extends State<ProblemSolvingContentScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
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
    
    // List animation
    _listController = AnimationController(
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
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _listController.forward();
    }
  }

  /// Get content items based on subject and grade
  List<Map<String, dynamic>> _getContentItems(LanguageBloc languageBloc) {
    // Check if this is Matematik TYT (has mockup)
    final hasContent = widget.subjectKey == 'matematik' && widget.gradeLevel.toLowerCase() == 'tyt';
    
    return [
      {
        'title': 'ENS PROBLEMLER',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? '${widget.subjectName} Problem Çözümleri'
          : '${widget.subjectName} Problem Solutions',
        'isActive': hasContent,
        'hasCover': hasContent,
        'coverAsset': hasContent ? 'assets/mockups/matematik/tyt/ens_problemler_mockup.png' : null,
      },
      {
        'title': 'YAKINDA SİZLERLE',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni İçerikler Ekleniyor'
          : 'New Content Coming Soon',
        'isActive': false,
        'hasCover': false,
      },
      {
        'title': 'ENS PROBLEMLER',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Ek Problemler - Yakında'
          : 'Additional Problems - Coming Soon',
        'isActive': false,
        'hasCover': false,
      },
      {
        'title': 'YAKINDA SİZLERLE',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni İçerikler Ekleniyor'
          : 'New Content Coming Soon',
        'isActive': false,
        'hasCover': false,
      },
    ];
  }

  void _navigateToContent(Map<String, dynamic> contentItem) {
    if (contentItem['isActive'] == true) {
      // Check if this is ENS Problemler for Matematik TYT (test selection)
      if (widget.subjectKey == 'matematik' && 
          widget.gradeLevel.toLowerCase() == 'tyt' &&
          contentItem['title'] == 'ENS PROBLEMLER') {
        // Navigate to Test Selection Screen
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => TestSelectionScreen(
              testSeriesTitle: 'ENS Problemler',
              subject: 'matematik',
              grade: 'tyt',
              testSeriesKey: 'ens_problemler',
              coverImagePath: contentItem['coverAsset'] ?? 'assets/mockups/matematik/tyt/ens_problemler_mockup.png',
              totalTests: 5,
              gradientStart: widget.gradientStart,
              gradientEnd: widget.gradientEnd,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
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
        // Show mockup image in full screen for other content
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _MockupViewerScreen(
              imagePath: contentItem['coverAsset'],
              title: contentItem['title'],
              gradientStart: widget.gradientStart,
              gradientEnd: widget.gradientEnd,
            ),
          ),
        );
      }
    } else {
      _showComingSoonMessage(contentItem['title']);
    }
  }

  void _showComingSoonMessage(String contentTitle) {
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
                '$contentTitle içeriği yakında eklenecek!',
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
        final contentItems = _getContentItems(languageBloc);
        
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFB794F6).withOpacity(0.3), // Purple
                  const Color(0xFF81E6D9).withOpacity(0.3), // Cyan
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [widget.gradientStart, widget.gradientEnd],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.subjectName} - ${widget.gradeLevel.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    languageBloc.currentLanguage == 'tr'
                                        ? 'Soru Çözümü'
                                        : 'Problem Solving',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
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
                  
                  // Content List
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: SpinKitPulsingGrid(
                              color: widget.gradientStart,
                              size: 60.0,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                            itemCount: contentItems.length,
                            itemBuilder: (context, index) {
                              return _buildContentCard(contentItems[index], index);
                            },
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

  Widget _buildContentCard(Map<String, dynamic> contentItem, int index) {
    final hasCover = contentItem['hasCover'] == true;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 80)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF9B59B6), // Purple
                    const Color(0xFFE67E80), // Coral
                    const Color(0xFFF39C6B), // Orange
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToContent(contentItem),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Text Content
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                contentItem['title'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                contentItem['subtitle'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Book Cover or Placeholder
                        Expanded(
                          flex: 2,
                          child: hasCover && contentItem['coverAsset'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    contentItem['coverAsset'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderCover();
                                    },
                                  ),
                                )
                              : _buildPlaceholderCover(),
                        ),
                      ],
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

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 48,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
}

/// Mockup Viewer Screen
class _MockupViewerScreen extends StatelessWidget {
  final String imagePath;
  final String title;
  final Color gradientStart;
  final Color gradientEnd;

  const _MockupViewerScreen({
    required this.imagePath,
    required this.title,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientStart, gradientEnd],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Image
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: 64,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Görsel yüklenemedi',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

