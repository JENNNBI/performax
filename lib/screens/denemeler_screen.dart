import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'my_drawer.dart';

/// Denemeler (Mock Exams) Screen
/// Shows mock exam resources with book cover thumbnails
class DenemelerScreen extends StatefulWidget {
  static const String id = 'denemeler_screen';
  
  const DenemelerScreen({super.key});

  @override
  State<DenemelerScreen> createState() => _DenemelerScreenState();
}

class _DenemelerScreenState extends State<DenemelerScreen>
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

  /// Get mock exam category items
  List<Map<String, dynamic>> _getMockExamCategories(LanguageBloc languageBloc) {
    return [
      {
        'title': languageBloc.currentLanguage == 'tr' ? 'TYT DENEMELERİ' : 'TYT MOCK EXAMS',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Temel Yeterlilik Testi Denemeleri'
          : 'Basic Proficiency Test Mock Exams',
        'icon': Icons.article_rounded,
        'type': 'tyt',
        'isActive': true,
      },
      {
        'title': languageBloc.currentLanguage == 'tr' ? 'AYT DENEMELERİ' : 'AYT MOCK EXAMS',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Alan Yeterlilik Testi Denemeleri'
          : 'Field Proficiency Test Mock Exams',
        'icon': Icons.school_rounded,
        'type': 'ayt',
        'isActive': false,
      },
      {
        'title': languageBloc.currentLanguage == 'tr' ? 'BRANŞ DENEMELERİ' : 'SUBJECT MOCK EXAMS',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Ders Bazlı Deneme Sınavları'
          : 'Subject-Based Mock Exams',
        'icon': Icons.category_rounded,
        'type': 'branch',
        'isActive': true,
      },
    ];
  }

  void _navigateToCategory(Map<String, dynamic> category) {
    final type = category['type'];
    
    if (category['isActive'] == true) {
      if (type == 'tyt') {
        // Navigate to TYT Mock Exams Screen
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const TYTDenemelerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else if (type == 'branch') {
        // Navigate to Branch Mock Exams Screen
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const BranchDenemelerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } else {
      _showComingSoonMessage(category['title']);
    }
  }

  void _showComingSoonMessage(String categoryTitle) {
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
                '$categoryTitle içeriği yakında eklenecek!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Şu anda sadece TYT ve Branş Denemeleri aktif.',
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
                foregroundColor: const Color(0xFF667eea),
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
        final categories = _getMockExamCategories(languageBloc);
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              languageBloc.currentLanguage == 'tr' ? 'DENEMELER' : 'MOCK EXAMS',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
            ),
          ),
          drawer: const MyDrawer(),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageBloc.currentLanguage == 'tr'
                                  ? 'Deneme Sınavları'
                                  : 'Mock Exams',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              languageBloc.currentLanguage == 'tr'
                                  ? 'TYT ve AYT deneme sınavlarına buradan erişebilirsiniz'
                                  : 'Access TYT and AYT mock exams here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
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
                        ? const Center(
                            child: SpinKitPulsingGrid(
                              color: Color(0xFF667eea),
                              size: 60.0,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return _buildCategoryCard(categories[index], index);
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

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
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
              margin: const EdgeInsets.only(bottom: 20),
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToCategory(category),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            category['icon'],
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category['title'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category['subtitle'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow Icon
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
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

/// TYT Denemeler Screen
class TYTDenemelerScreen extends StatefulWidget {
  const TYTDenemelerScreen({super.key});

  @override
  State<TYTDenemelerScreen> createState() => _TYTDenemelerScreenState();
}

class _TYTDenemelerScreenState extends State<TYTDenemelerScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _isLoading = false);
      _controller.forward();
    }
  }

  List<Map<String, dynamic>> _getTYTExams(LanguageBloc languageBloc) {
    return [
      {
        'title': 'ENS TYT TG1',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'TYT Tüm Dersler Denemesi'
          : 'TYT All Subjects Mock Exam',
        'isActive': true,
        'hasCover': true,
        'coverAsset': 'assets/mockups/denemeler/ens_tyt_tg1.png',
      },
      {
        'title': 'YAKINDA SİZLERLE',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni TYT Denemeleri Ekleniyor'
          : 'New TYT Mock Exams Coming Soon',
        'isActive': false,
        'hasCover': false,
      },
      {
        'title': 'ENS TYT TG2',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'TYT Tüm Dersler - Yakında'
          : 'TYT All Subjects - Coming Soon',
        'isActive': false,
        'hasCover': false,
      },
      {
        'title': 'YAKINDA SİZLERLE',
        'subtitle': languageBloc.currentLanguage == 'tr'
          ? 'Yeni TYT Denemeleri Ekleniyor'
          : 'New TYT Mock Exams Coming Soon',
        'isActive': false,
        'hasCover': false,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final exams = _getTYTExams(languageBloc);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFB794F6).withOpacity(0.3),
                  const Color(0xFF81E6D9).withOpacity(0.3),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
                                languageBloc.currentLanguage == 'tr' ? 'TYT DENEMELERİ' : 'TYT MOCK EXAMS',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                languageBloc.currentLanguage == 'tr'
                                    ? 'Temel Yeterlilik Testi'
                                    : 'Basic Proficiency Test',
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
                  
                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: SpinKitPulsingGrid(
                              color: Color(0xFF667eea),
                              size: 60.0,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                            itemCount: exams.length,
                            itemBuilder: (context, index) {
                              return _buildExamCard(exams[index], index);
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

  Widget _buildExamCard(Map<String, dynamic> exam, int index) {
    final hasCover = exam['hasCover'] == true;
    
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
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF9B59B6),
                    Color(0xFFE67E80),
                    Color(0xFFF39C6B),
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
                  onTap: () {
                    if (exam['isActive'] == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _MockupViewerScreen(
                            imagePath: exam['coverAsset'],
                            title: exam['title'],
                            gradientStart: const Color(0xFF667eea),
                            gradientEnd: const Color(0xFF764ba2),
                          ),
                        ),
                      );
                    } else {
                      _showComingSoon(exam['title']);
                    }
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                exam['title'],
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
                                exam['subtitle'],
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
                        Expanded(
                          flex: 2,
                          child: hasCover && exam['coverAsset'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    exam['coverAsset'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder();
                                    },
                                  ),
                                )
                              : _buildPlaceholder(),
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

  Widget _buildPlaceholder() {
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
          Icons.assignment_rounded,
          size: 48,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  void _showComingSoon(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yakında Gelecek'),
        content: Text('$title içeriği yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

/// Branch Denemeler Screen
class BranchDenemelerScreen extends StatefulWidget {
  const BranchDenemelerScreen({super.key});

  @override
  State<BranchDenemelerScreen> createState() => _BranchDenemelerScreenState();
}

class _BranchDenemelerScreenState extends State<BranchDenemelerScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _isLoading = false);
      _controller.forward();
    }
  }

  List<Map<String, dynamic>> _getBranchSubjects(LanguageBloc languageBloc) {
    return [
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Matematik' : 'Mathematics',
        'icon': '📐',
        'color': const Color(0xFF667eea),
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Türkçe' : 'Turkish',
        'icon': '📚',
        'color': const Color(0xFFf093fb),
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Biyoloji' : 'Biology',
        'icon': '🧬',
        'color': const Color(0xFF4facfe),
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Kimya' : 'Chemistry',
        'icon': '⚗️',
        'color': const Color(0xFFfa709a),
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Fizik' : 'Physics',
        'icon': '⚛️',
        'color': const Color(0xFF43e97b),
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Tarih' : 'History',
        'icon': '🏛️',
        'color': const Color(0xFFfeca57),
      },
      {
        'name': languageBloc.currentLanguage == 'tr' ? 'Coğrafya' : 'Geography',
        'icon': '🌍',
        'color': const Color(0xFF48dbfb),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final subjects = _getBranchSubjects(languageBloc);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFB794F6).withOpacity(0.3),
                  const Color(0xFF81E6D9).withOpacity(0.3),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
                                languageBloc.currentLanguage == 'tr' ? 'BRANŞ DENEMELERİ' : 'SUBJECT MOCK EXAMS',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                languageBloc.currentLanguage == 'tr'
                                    ? 'Ders Bazlı Denemeler'
                                    : 'Subject-Based Mock Exams',
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
                  
                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: SpinKitPulsingGrid(
                              color: Color(0xFF667eea),
                              size: 60.0,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              return _buildSubjectCard(subjects[index], index);
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

  Widget _buildSubjectCard(Map<String, dynamic> subject, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 60)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    subject['color'],
                    subject['color'].withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: subject['color'].withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showComingSoon(subject['name']),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              subject['icon'],
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Subject Name
                        Expanded(
                          child: Text(
                            subject['name'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Arrow
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
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

  void _showComingSoon(String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yakında Gelecek'),
        content: Text('$subjectName branş denemeleri yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
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

