import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'register_screen.dart';

class EnhancedStatisticsScreen extends StatefulWidget {
  static const String id = 'enhanced_statistics_screen';
  final bool isGuest;
  
  const EnhancedStatisticsScreen({super.key, this.isGuest = false});

  @override
  State<EnhancedStatisticsScreen> createState() => _EnhancedStatisticsScreenState();
}

class _EnhancedStatisticsScreenState extends State<EnhancedStatisticsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Sample statistics data - replace with actual data from your backend
  final Map<String, dynamic> stats = {
    'videosWatched': 45,
    'totalWatchTime': 1200, // minutes
    'examsPracticed': 8,
    'averageScore': 85.5,
    'currentStreak': 7,
    'thisWeekProgress': 0.68,
    'weeklyData': [12, 18, 15, 22, 25, 20, 28], // Last 7 days study minutes
    'subjectProgress': {
      'Matematik': 0.75,
      'Fizik': 0.60,
      'Kimya': 0.45,
      'Biyoloji': 0.80,
      'Türkçe': 0.70,
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
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
                      _buildStaggeredStatsGrid(languageBloc),
                      const SizedBox(height: 20),
                      _buildWeeklyChart(languageBloc),
                      const SizedBox(height: 20),
                      _buildSubjectProgressChart(languageBloc),
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

  Widget _buildStaggeredStatsGrid(LanguageBloc languageBloc) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildAnimatedStatCard(
          icon: Icons.play_circle_outline,
          title: languageBloc.currentLanguage == 'tr' ? 'Videolar' : 'Videos',
          value: '${stats['videosWatched']}',
          gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
          delay: 0,
        ),
        _buildAnimatedStatCard(
          icon: Icons.schedule,
          title: languageBloc.currentLanguage == 'tr' ? 'Süre' : 'Time',
          value: '${(stats['totalWatchTime'] / 60).toStringAsFixed(1)}sa',
          gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
          delay: 100,
        ),
        _buildAnimatedStatCard(
          icon: Icons.local_fire_department,
          title: languageBloc.currentLanguage == 'tr' ? 'Seri' : 'Streak',
          value: '${stats['currentStreak']} gün',
          gradient: const [Color(0xFFfa709a), Color(0xFFfee140)],
          delay: 200,
        ),
        _buildAnimatedStatCard(
          icon: Icons.star,
          title: languageBloc.currentLanguage == 'tr' ? 'Ortalama' : 'Average',
          value: '${stats['averageScore']}%',
          gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
          delay: 300,
        ),
      ],
    );
  }

  Widget _buildAnimatedStatCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradient,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: Opacity(
            opacity: animation.clamp(0.0, 1.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.white.withValues(alpha:0.9), size: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha:0.8),
                          ),
                        ),
                      ],
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

  Widget _buildWeeklyChart(LanguageBloc languageBloc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  languageBloc.currentLanguage == 'tr' 
                      ? 'Haftalık İlerleme'
                      : 'Weekly Progress',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                _createWeeklyChartData(),
                duration: const Duration(milliseconds: 800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _createWeeklyChartData() {
    final weeklyData = stats['weeklyData'] as List<int>;
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha:0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < days.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}dk',
                  style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 30,
      lineBarsData: [
        LineChartBarData(
          spots: weeklyData.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.toDouble());
          }).toList(),
          isCurved: true,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: const Color(0xFF667eea),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667eea).withValues(alpha:0.3),
                const Color(0xFF764ba2).withValues(alpha:0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectProgressChart(LanguageBloc languageBloc) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  languageBloc.currentLanguage == 'tr' 
                      ? 'Ders Başarısı'
                      : 'Subject Progress',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                _createSubjectChartData(),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _createSubjectChartData() {
    final subjectProgress = stats['subjectProgress'] as Map<String, dynamic>;
    final subjects = subjectProgress.keys.toList();
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFF43e97b),
      const Color(0xFF4facfe),
      const Color(0xFFfa709a),
      const Color(0xFFffecd2),
    ];

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 1,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Colors.grey[800]!,
          tooltipBorder: const BorderSide(color: Colors.transparent),
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${(rod.toY * 100).toInt()}%',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < subjects.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    subjects[value.toInt()],
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text('${(value * 100).toInt()}%',
                  style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 0.2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha:0.2),
            strokeWidth: 1,
          );
        },
      ),
      barGroups: subjects.asMap().entries.map((entry) {
        final index = entry.key;
        final subject = entry.value;
        final progress = subjectProgress[subject] as double;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: progress,
              gradient: LinearGradient(
                colors: [
                  colors[index % colors.length],
                  colors[index % colors.length].withValues(alpha:0.7),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 30,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        );
      }).toList(),
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

