import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../blocs/bloc_exports.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

class DenemelerScreen extends StatefulWidget {
  static const String id = 'denemeler_screen';

  const DenemelerScreen({super.key});

  @override
  State<DenemelerScreen> createState() => _DenemelerScreenState();
}

class _DenemelerScreenState extends State<DenemelerScreen> with TickerProviderStateMixin {
  late AnimationController _listController;
  final List<Map<String, dynamic>> _mockExams = [
    {
      'title': 'TYT Genel Deneme 1',
      'subtitle': 'Temel Yeterlilik Testi',
      'date': '24.12.2024',
      'status': 'Aktif',
      'color': const Color(0xFF667eea),
    },
    {
      'title': 'AYT Matematik Deneme',
      'subtitle': 'Alan Yeterlilik Testi',
      'date': '25.12.2024',
      'status': 'Yakında',
      'color': const Color(0xFF764ba2),
    },
    {
      'title': 'TYT Türkçe Deneme',
      'subtitle': 'Temel Yeterlilik Testi',
      'date': '26.12.2024',
      'status': 'Yakında',
      'color': const Color(0xFFf5576c),
    },
  ];

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void _showComingSoon() {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Yakında',
        message: 'Bu deneme sınavı henüz aktif değil.',
        contentType: ContentType.warning,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final languageBloc = context.read<LanguageBloc>();
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
                      Text(
                        languageBloc.currentLanguage == 'tr' ? 'Denemeler' : 'Mock Exams',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: _mockExams.length,
                    itemBuilder: (context, index) {
                      final exam = _mockExams[index];
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _listController,
                          curve: Interval(
                            index * 0.1,
                            0.5 + (index * 0.1),
                            curve: Curves.easeOutCubic,
                          ),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _listController,
                              curve: Interval(
                                index * 0.1,
                                0.5 + (index * 0.1),
                                curve: Curves.easeIn,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: NeumorphicButton(
                              onPressed: index == 0 ? () {} : _showComingSoon, // Demo logic
                              padding: const EdgeInsets.all(20),
                              borderRadius: 20,
                              child: Row(
                                children: [
                                  NeumorphicContainer(
                                    padding: const EdgeInsets.all(16),
                                    borderRadius: 16,
                                    color: exam['color'].withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.assignment_rounded,
                                      color: exam['color'],
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exam['title'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          exam['subtitle'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: exam['status'] == 'Aktif' 
                                                ? Colors.green.withValues(alpha: 0.1) 
                                                : Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            exam['status'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: exam['status'] == 'Aktif' ? Colors.green : Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: textColor.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
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
}
