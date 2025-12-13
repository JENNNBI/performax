import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'problem_solving_content_screen.dart';

/// Problem Solving Grade Selection Screen
/// Shows grade level buttons for problem solving content
class ProblemSolvingGradeSelectionScreen extends StatefulWidget {
  final String subjectName;
  final String subjectKey;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  
  const ProblemSolvingGradeSelectionScreen({
    super.key,
    required this.subjectName,
    required this.subjectKey,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
  });

  @override
  State<ProblemSolvingGradeSelectionScreen> createState() => _ProblemSolvingGradeSelectionScreenState();
}

class _ProblemSolvingGradeSelectionScreenState extends State<ProblemSolvingGradeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _gridController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    
    _headerSlideAnimation = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );
    
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
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
      setState(() => _isLoading = false);
      _gridController.forward();
    }
  }

  List<Map<String, dynamic>> _getGradeLevels(LanguageBloc languageBloc) {
    return [
      {'name': '9.SINIF', 'key': '9_sinif', 'gradientColors': [const Color(0xFF667EEA), const Color(0xFF00D4FF)], 'icon': Icons.looks_one_rounded},
      {'name': '10.SINIF', 'key': '10_sinif', 'gradientColors': [const Color(0xFFFDC830), const Color(0xFFF37335)], 'icon': Icons.looks_two_rounded},
      {'name': '11.SINIF', 'key': '11_sinif', 'gradientColors': [const Color(0xFFFCE38A), const Color(0xFFF38181)], 'icon': Icons.looks_3_rounded},
      {'name': 'TYT', 'key': 'tyt', 'gradientColors': [const Color(0xFF56CCF2), const Color(0xFFA8E063)], 'icon': Icons.school_rounded, 'hasContent': widget.subjectKey == 'matematik'},
      {'name': 'AYT', 'key': 'ayt', 'gradientColors': [const Color(0xFFFCE38A), const Color(0xFFF5CBCB)], 'icon': Icons.auto_awesome_rounded},
    ];
  }

  void _navigateToContent(Map<String, dynamic> gradeLevel) {
    if (gradeLevel['hasContent'] == true) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ProblemSolvingContentScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            gradeLevel: gradeLevel['name'],
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      _showComingSoonMessage(gradeLevel['name']);
    }
  }

  void _showComingSoonMessage(String gradeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.gradientStart, widget.gradientEnd]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Yakında Gelecek', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.subjectName} - $gradeName içeriği yakında eklenecek!', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: widget.gradientStart.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Text('Şu anda sadece Matematik TYT içeriği aktif.', style: TextStyle(fontSize: 12, color: Color(0xFF667eea), fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final languageBloc = context.read<LanguageBloc>();
        final gradeLevels = _getGradeLevels(languageBloc);
        
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160.0,
                floating: false,
                pinned: true,
                backgroundColor: widget.gradientStart,
                flexibleSpace: FlexibleSpaceBar(
                  background: FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: Container(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.gradientStart, widget.gradientEnd])),
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
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                      child: Icon(widget.subjectIcon, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(widget.subjectName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                          Text('Soru Çözümü', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.gradientStart.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.gradientStart.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.class_rounded, color: widget.gradientStart, size: 20),
                      const SizedBox(width: 8),
                      Text('Sınıf seviyesi seçin', style: TextStyle(color: widget.gradientStart, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              _isLoading
                  ? SliverFillRemaining(child: Center(child: SpinKitPulsingGrid(color: widget.gradientStart, size: 60.0)))
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
                          (context, index) => _buildGradeCard(gradeLevels[index], index),
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
                  gradient: LinearGradient(colors: gradeLevel['gradientColors']),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: gradeLevel['gradientColors'][0].withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        gradeLevel['name'],
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black, fontStyle: FontStyle.italic, letterSpacing: 1.2),
                      ),
                    ),
                    if (gradeLevel['hasContent'] == true)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Aktif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.05)],
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

