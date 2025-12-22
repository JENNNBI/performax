import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'register_screen.dart';
import '../services/statistics_service.dart';

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
        final theme = Theme.of(context);
        
        if (widget.isGuest) {
          return _buildGuestMessage(theme, languageBloc);
        }
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(languageBloc, theme),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSubjectRadar(languageBloc),
                      const SizedBox(height: 20),
                      _buildStudyPie(languageBloc),
                      const SizedBox(height: 20),
                      _buildConsistencyBar(languageBloc),
                      const SizedBox(height: 20),
                      _buildTestHistory(languageBloc),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(LanguageBloc languageBloc, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languageBloc.currentLanguage == 'tr' ? 'İstatistiklerim' : 'My Statistics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                languageBloc.currentLanguage == 'tr' 
                    ? 'Öğrenme ilerlemenizi takip edin'
                    : 'Track your learning progress',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectRadar(LanguageBloc languageBloc) {
    final baseOrder = ['Matematik','Türkçe','Fizik','Kimya','Biyoloji','Tarih','Coğrafya','Felsefe'];
    final prof = _snap?.subjectProficiency ?? {};
    final hasData = prof.values.any((v) => (v ?? 0) > 0);
    if (!hasData) {
      return _emptyCard(
        icon: Icons.school,
        title: languageBloc.currentLanguage == 'tr' ? 'Ders Başarısı' : 'Subject Mastery',
        subtitle: languageBloc.currentLanguage == 'tr' ? 'Henüz veri yok' : 'No data yet',
      );
    }
    final entries = baseOrder.map((k) => MapEntry(k, (prof[k] ?? 0.0))).toList();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  languageBloc.currentLanguage == 'tr' ? 'Ders Başarısı' : 'Subject Mastery',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.circle,
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                  gridBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  titleTextStyle: const TextStyle(fontSize: 12),
                  dataSets: [
                    RadarDataSet(
                      fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      borderColor: Theme.of(context).primaryColor,
                      entryRadius: 2,
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
      ),
    );
  }

  Widget _buildStudyPie(LanguageBloc languageBloc) {
    final v = _snap?.videoSeconds ?? 0;
    final p = _snap?.pdfSeconds ?? 0;
    final q = _snap?.quizSeconds ?? 0;
    final total = v + p + q;
    if (total == 0) {
      return _emptyCard(
        icon: Icons.timer,
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  languageBloc.currentLanguage == 'tr' ? 'Çalışma Alışkanlıkları' : 'Study Habits',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
                duration: const Duration(milliseconds: 800),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(color: const Color(0xFF667eea), text: languageBloc.currentLanguage == 'tr' ? 'Video' : 'Video'),
                _legendItem(color: const Color(0xFF43e97b), text: 'PDF'),
                _legendItem(color: const Color(0xFFfa709a), text: languageBloc.currentLanguage == 'tr' ? 'Quiz' : 'Quiz'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencyBar(LanguageBloc languageBloc) {
    final data = _snap?.last7DaysStudySeconds ?? List<int>.filled(7, 0);
    final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final maxSeconds = data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b);
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
    String formatFull(int seconds) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      if (languageBloc.currentLanguage == 'tr') {
        if (h > 0) return '${h}sa ${m}dk';
        return '${m}dk';
      } else {
        if (h > 0) return '${h}h ${m}m';
        return '${m}m';
      }
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  languageBloc.currentLanguage == 'tr' ? 'Günlük Çalışma Süresi' : 'Daily Study Time',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                              child: Text(dayLabels[i], style: const TextStyle(fontSize: 11)),
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
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final seconds = rod.toY.toInt();
                        final day = dayLabels[group.x];
                        return BarTooltipItem(
                          '$day: ${formatFull(seconds)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
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
                            colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.7)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 20,
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
      ),
    );
  }


  Widget _legendItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  Widget _emptyCard({required IconData icon, required String title, required String subtitle}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestHistory(LanguageBloc languageBloc) {
    final tests = _snap?.testHistory ?? [];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_edu, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  languageBloc.currentLanguage == 'tr' ? 'Test Geçmişi' : 'Test History',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tests.isEmpty)
              Text(
                languageBloc.currentLanguage == 'tr' ? 'Henüz test geçmişi yok' : 'No test history yet',
                style: const TextStyle(fontSize: 13),
              )
            else
              Column(
                children: tests.take(10).map((t) {
                  final source = t['source']?.toString() ?? '';
                  final lesson = t['lesson']?.toString() ?? '';
                  final percentage = t['percentage']?.toString() ?? '0';
                  final date = t['date']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.assignment_rounded, color: Theme.of(context).primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(source, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${languageBloc.currentLanguage == 'tr' ? 'Ders' : 'Lesson'}: $lesson • ${languageBloc.currentLanguage == 'tr' ? 'Başarı' : 'Success'}: %$percentage',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(date, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestMessage(ThemeData theme, LanguageBloc languageBloc) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitRing(
              color: theme.primaryColor,
              size: 80,
              lineWidth: 4,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: theme.primaryColor.withValues(alpha:0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      languageBloc.currentLanguage == 'tr'
                          ? 'İstatistikleri Görüntüle'
                          : 'View Statistics',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      languageBloc.currentLanguage == 'tr'
                          ? 'İlerlemenizi takip etmek ve istatistiklerinizi görmek için giriş yapın veya hesap oluşturun.'
                          : 'Sign in or create an account to track your progress and view statistics.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(RegisterScreen.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          languageBloc.currentLanguage == 'tr'
                              ? 'Hesap Oluştur'
                              : 'Create Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
