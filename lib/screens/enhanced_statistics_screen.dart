import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'register_screen.dart';
import '../services/statistics_service.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

class EnhancedStatisticsScreen extends StatefulWidget {
  static const String id = 'enhanced_statistics_screen';
  final bool isGuest;
  
  const EnhancedStatisticsScreen({super.key, this.isGuest = false});

  @override
  State<EnhancedStatisticsScreen> createState() => _EnhancedStatisticsScreenState();
}

class _EnhancedStatisticsScreenState extends State<EnhancedStatisticsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  StatisticsSnapshot? _snap;
  late final StatisticsService _service;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
    _service = StatisticsService.instance;
    _service.stream.listen((s) {
      if (!mounted) return;
      setState(() {
        _snap = s;
      });
    });
    _service.loadSnapshot().then((s) {
      if (!mounted) return;
      setState(() {
        _snap = s;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final bgColor = NeumorphicColors.getBackground(context);
        
        if (widget.isGuest) {
          return _buildGuestMessage(context, languageBloc);
        }
        
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildHeader(context, languageBloc), // Removed header
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSubjectRadar(context, languageBloc),
                        const SizedBox(height: 24),
                        _buildStudyPie(context, languageBloc),
                        const SizedBox(height: 24),
                        _buildConsistencyBar(context, languageBloc),
                        const SizedBox(height: 24),
                        _buildTestHistory(context, languageBloc),
                        const SizedBox(height: 100), // Bottom padding for dock
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildSubjectRadar(BuildContext context, LanguageBloc languageBloc) {
    final baseOrder = ['Matematik','Türkçe','Fizik','Kimya','Biyoloji','Tarih','Coğrafya','Felsefe'];
    final prof = _snap?.subjectProficiency ?? {};
    final hasData = prof.values.any((v) => (v) > 0);
    final textColor = NeumorphicColors.getText(context);

    if (!hasData) {
      return _emptyCard(
        context,
        icon: Icons.school_rounded,
        title: languageBloc.currentLanguage == 'tr' ? 'Ders Başarısı' : 'Subject Mastery',
        subtitle: languageBloc.currentLanguage == 'tr' ? 'Henüz veri yok' : 'No data yet',
      );
    }
    
    final entries = baseOrder.map((k) => MapEntry(k, (prof[k] ?? 0.0))).toList();
    
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: NeumorphicColors.accentBlue),
              const SizedBox(width: 8),
              Text(
                languageBloc.currentLanguage == 'tr' ? 'Ders Başarısı' : 'Subject Mastery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.circle,
                tickCount: 4,
                ticksTextStyle: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.5)),
                gridBorderData: BorderSide(color: textColor.withValues(alpha: 0.1)),
                titleTextStyle: TextStyle(fontSize: 12, color: textColor),
                dataSets: [
                  RadarDataSet(
                    fillColor: NeumorphicColors.accentBlue.withValues(alpha: 0.2),
                    borderColor: NeumorphicColors.accentBlue,
                    entryRadius: 3,
                    dataEntries: entries
                        .map((e) => RadarEntry(value: e.value.clamp(0, 100).toDouble()))
                        .toList(),
                  ),
                ],
                getTitle: (index, _) => RadarChartTitle(text: entries[index].key),
                radarBackgroundColor: Colors.transparent,
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPie(BuildContext context, LanguageBloc languageBloc) {
    final v = _snap?.videoSeconds ?? 0;
    final p = _snap?.pdfSeconds ?? 0;
    final q = _snap?.quizSeconds ?? 0;
    final total = v + p + q;
    final textColor = NeumorphicColors.getText(context);

    if (total == 0) {
      return _emptyCard(
        context,
        icon: Icons.timer_rounded,
        title: languageBloc.currentLanguage == 'tr' ? 'Çalışma Alışkanlıkları' : 'Study Habits',
        subtitle: languageBloc.currentLanguage == 'tr' ? 'Henüz veri yok' : 'No data yet',
      );
    }
    
    final sections = [
      PieChartSectionData(
        value: v.toDouble(),
        color: const Color(0xFF667eea),
        title: '${((v / total) * 100).round()}%',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: p.toDouble(),
        color: const Color(0xFF43e97b),
        title: '${((p / total) * 100).round()}%',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: q.toDouble(),
        color: const Color(0xFFfa709a),
        title: '${((q / total) * 100).round()}%',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ];
    
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: NeumorphicColors.accentBlue),
              const SizedBox(width: 8),
              Text(
                languageBloc.currentLanguage == 'tr' ? 'Çalışma Alışkanlıkları' : 'Study Habits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
              duration: const Duration(milliseconds: 800),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(context, color: const Color(0xFF667eea), text: languageBloc.currentLanguage == 'tr' ? 'Video' : 'Video'),
              _legendItem(context, color: const Color(0xFF43e97b), text: 'PDF'),
              _legendItem(context, color: const Color(0xFFfa709a), text: languageBloc.currentLanguage == 'tr' ? 'Quiz' : 'Quiz'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyBar(BuildContext context, LanguageBloc languageBloc) {
    final data = _snap?.last7DaysStudySeconds ?? List<int>.filled(7, 0);
    final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final maxSeconds = data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b);
    final textColor = NeumorphicColors.getText(context);

    String formatShort(double seconds) {
      if (seconds <= 0) return '0';
      if (seconds < 3600) {
        final m = (seconds / 60).round();
        return languageBloc.currentLanguage == 'tr' ? '${m}dk' : '${m}m';
      } else {
        final h = (seconds / 3600).round();
        return languageBloc.currentLanguage == 'tr' ? '${h}sa' : '${h}h';
      }
    }
    
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: NeumorphicColors.accentBlue),
              const SizedBox(width: 8),
              Text(
                languageBloc.currentLanguage == 'tr' ? 'Günlük Çalışma Süresi' : 'Daily Study Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (data.isEmpty ? 1 : (maxSeconds.toDouble() * 1.1)),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 0 && i < dayLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayLabels[i], 
                              style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.7)),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(
                            formatShort(value),
                            style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.5)),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: data.asMap().entries.map((e) {
                  final i = e.key;
                  final v = e.value.toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        gradient: LinearGradient(
                          colors: [
                            NeumorphicColors.accentBlue,
                            NeumorphicColors.accentBlue.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }


  Widget _legendItem(BuildContext context, {required Color color, required String text}) {
    final textColor = NeumorphicColors.getText(context);
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: textColor, fontSize: 12)),
      ],
    );
  }

  Widget _emptyCard(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    final textColor = NeumorphicColors.getText(context);
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Row(
        children: [
          Icon(icon, color: NeumorphicColors.accentBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestHistory(BuildContext context, LanguageBloc languageBloc) {
    final tests = _snap?.testHistory ?? [];
    final textColor = NeumorphicColors.getText(context);

    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu_rounded, color: NeumorphicColors.accentBlue),
              const SizedBox(width: 8),
              Text(
                languageBloc.currentLanguage == 'tr' ? 'Test Geçmişi' : 'Test History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tests.isEmpty)
            Text(
              languageBloc.currentLanguage == 'tr' ? 'Henüz test geçmişi yok' : 'No test history yet',
              style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.6)),
            )
          else
            Column(
              children: tests.take(10).map((t) {
                final source = t['source']?.toString() ?? '';
                final lesson = t['lesson']?.toString() ?? '';
                final percentage = t['percentage']?.toString() ?? '0';
                final date = t['date']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      NeumorphicContainer(
                        padding: const EdgeInsets.all(10),
                        borderRadius: 12,
                        depth: 2,
                        child: Icon(Icons.assignment_rounded, color: NeumorphicColors.accentBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(source, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(height: 2),
                            Text(
                              '${languageBloc.currentLanguage == 'tr' ? 'Ders' : 'Lesson'}: $lesson • ${languageBloc.currentLanguage == 'tr' ? 'Başarı' : 'Success'}: %$percentage',
                              style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(date, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.4))),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGuestMessage(BuildContext context, LanguageBloc languageBloc) {
    final textColor = NeumorphicColors.getText(context);
    final bgColor = NeumorphicColors.getBackground(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeumorphicContainer(
                padding: const EdgeInsets.all(40),
                shape: BoxShape.circle,
                depth: -5,
                child: SpinKitRing(
                  color: NeumorphicColors.accentBlue,
                  size: 60,
                  lineWidth: 4,
                ),
              ),
              const SizedBox(height: 40),
              NeumorphicContainer(
                padding: const EdgeInsets.all(32),
                borderRadius: 30,
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: NeumorphicColors.accentBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      languageBloc.currentLanguage == 'tr'
                          ? 'İstatistikleri Görüntüle'
                          : 'View Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      languageBloc.currentLanguage == 'tr'
                          ? 'İlerlemenizi takip etmek ve istatistiklerinizi görmek için giriş yapın veya hesap oluşturun.'
                          : 'Sign in or create an account to track your progress and view statistics.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    NeumorphicButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(RegisterScreen.id);
                      },
                      color: NeumorphicColors.accentBlue,
                      child: Center(
                        child: Text(
                          languageBloc.currentLanguage == 'tr'
                              ? 'Hesap Oluştur'
                              : 'Create Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
