import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'local_pdf_viewer_screen.dart';

/// Matematik TYT Content Selection Screen
/// Shows available content options for TYT Matematik
class MatematikTYTContentScreen extends StatefulWidget {
  final Color gradientStart;
  final Color gradientEnd;
  
  const MatematikTYTContentScreen({
    super.key,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  State<MatematikTYTContentScreen> createState() => _MatematikTYTContentScreenState();
}

class _MatematikTYTContentScreenState extends State<MatematikTYTContentScreen>
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

  /// Get TYT content items
  List<Map<String, dynamic>> _getContentItems(LanguageBloc languageBloc) {
    return [
      {
        'title': 'ENS-PROBLEMLER',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'TYT Matematik Problem Çözümleri'
          : 'TYT Mathematics Problem Solutions',
        'isActive': true,
        'isPDF': true,
        'icon': Icons.picture_as_pdf_rounded,
      },
      {
        'title': 'ENS-TYT SORU BANKASI',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Kapsamlı Soru Bankası - Yakında'
          : 'Comprehensive Question Bank - Coming Soon',
        'isActive': false,
        'icon': Icons.quiz_rounded,
      },
      {
        'title': 'ENS-TYT KONU ANLATIMI',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Video Konu Anlatımları - Yakında'
          : 'Video Lessons - Coming Soon',
        'isActive': false,
        'icon': Icons.play_circle_outline_rounded,
      },
      {
        'title': 'YAKINDA GELECEK',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni İçerik Ekleniyor'
          : 'New Content Coming',
        'isActive': false,
        'icon': Icons.schedule_rounded,
      },
      {
        'title': 'YAKINDA GELECEK',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni İçerik Ekleniyor'
          : 'New Content Coming',
        'isActive': false,
        'icon': Icons.schedule_rounded,
      },
      {
        'title': 'YAKINDA GELECEK',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni İçerik Ekleniyor'
          : 'New Content Coming',
        'isActive': false,
        'icon': Icons.schedule_rounded,
      },
      {
        'title': 'YAKINDA GELECEK',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni İçerik Ekleniyor'
          : 'New Content Coming',
        'isActive': false,
        'icon': Icons.schedule_rounded,
      },
      {
        'title': 'YAKINDA GELECEK',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni İçerik Ekleniyor'
          : 'New Content Coming',
        'isActive': false,
        'icon': Icons.schedule_rounded,
      },
    ];
  }

  void _navigateToContent(Map<String, dynamic> contentItem) {
    if (contentItem['isActive'] == true && contentItem['isPDF'] == true) {
      // Open PDF viewer for ENS-PROBLEMLER
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LocalPDFViewerScreen(
            assetPath: 'assets/pdfs/ens_problemler.pdf',
            title: 'ENS Problemler - TYT Matematik',
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subject: 'Matematik',
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
      // Show coming soon message
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
                  color: widget.gradientStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Şu anda sadece ENS-PROBLEMLER içeriği aktif.',
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
                  const Color(0xFFF7A3A3).withValues(alpha: 0.6), // Coral/Pink
                  const Color(0xFFFCC89B).withValues(alpha: 0.6), // Peach
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
                                    languageBloc.currentLanguage == 'tr'
                                        ? 'TYT Matematik'
                                        : 'TYT Mathematics',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    languageBloc.currentLanguage == 'tr'
                                        ? 'İçerik Seçimi'
                                        : 'Select Content',
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
    final isActive = contentItem['isActive'] == true;
    
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isActive
                      ? [
                          const Color(0xFF667EEA), // Blue
                          const Color(0xFF56CCF2), // Cyan
                        ]
                      : [
                          const Color(0xFF667EEA).withValues(alpha: 0.6),
                          const Color(0xFF56CCF2).withValues(alpha: 0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: isActive ? 0.4 : 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToContent(contentItem),
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    child: Row(
                      children: [
                        // Icon
                        if (contentItem['icon'] != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              contentItem['icon'],
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        
                        if (contentItem['icon'] != null)
                          const SizedBox(width: 16),
                        
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contentItem['title'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.5,
                                  shadows: isActive ? [] : [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              if (contentItem['subtitle'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  contentItem['subtitle'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Active indicator or arrow
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        else
                          Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 20,
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
}
