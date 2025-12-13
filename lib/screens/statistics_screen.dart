import 'package:flutter/material.dart';
import '../utils/app_icons.dart';
import '../blocs/bloc_exports.dart';
import 'register_screen.dart';

class StatisticsScreen extends StatefulWidget {
  static const String id = 'statistics_screen';
  final bool isGuest;
  
  const StatisticsScreen({super.key, this.isGuest = false});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Sample statistics data - replace with actual data from your backend
  final Map<String, dynamic> stats = {
    'videosWatched': 45,
    'totalWatchTime': 1200, // minutes
    'examsPracticed': 8,
    'averageScore': 85.5,
    'currentStreak': 7,
    'thisWeekProgress': 0.68,
    'subjectProgress': {
      'Matematik': 0.75,
      'Fizik': 0.60,
      'Kimya': 0.45,
      'Biyoloji': 0.80,
    },
  };

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
              Text(
                languageBloc.currentLanguage == 'tr' ? 'İstatistiklerim' : 'My Statistics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                languageBloc.currentLanguage == 'tr' 
                  ? 'Öğrenme ilerlemenizi ve başarılarınızı takip edin'
                  : 'Track your learning progress and achievements',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOverviewCards(languageBloc),
                      const SizedBox(height: 24),
                      _buildProgressSection(languageBloc),
                      const SizedBox(height: 24),
                      _buildSubjectProgress(languageBloc),
                      const SizedBox(height: 100), // Add bottom padding for navigation
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

  Widget _buildGuestMessage(ThemeData theme, LanguageBloc languageBloc) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    theme.primaryColor.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  AppIcons.holographicIcon(
                    AppIcons.statistics,
                    size: 80,
                    primaryColor: theme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    languageBloc.translate('guest_restriction_title'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    languageBloc.translate('guest_restriction_message'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed(RegisterScreen.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                AppIcons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                languageBloc.translate('create_account'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildOverviewCards(LanguageBloc languageBloc) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: AppIcons.playCircle,
            title: languageBloc.currentLanguage == 'tr' ? 'İzlenen Videolar' : 'Videos Watched',
            value: '${stats['videosWatched']}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: AppIcons.timer,
            title: languageBloc.currentLanguage == 'tr' ? 'Çalışma Süresi' : 'Study Time',
            value: '${(stats['totalWatchTime'] / 60).toStringAsFixed(1)}${languageBloc.currentLanguage == 'tr' ? 'sa' : 'h'}',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(LanguageBloc languageBloc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageBloc.currentLanguage == 'tr' ? 'Bu Hafta' : 'This Week',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                                 child: _buildStatCard(
                   icon: AppIcons.statistics,
                   title: languageBloc.currentLanguage == 'tr' ? 'Seri' : 'Streak',
                   value: '${stats['currentStreak']} ${languageBloc.translate('days')}',
                   color: Colors.orange,
                 ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: AppIcons.statistics,
                  title: languageBloc.currentLanguage == 'tr' ? 'Ortalama' : 'Average',
                  value: '${stats['averageScore']}%',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress(LanguageBloc languageBloc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageBloc.currentLanguage == 'tr' ? 'Ders İlerlemesi' : 'Subject Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...stats['subjectProgress'].entries.map<Widget>((entry) {
            // Translate subject names
            String translatedSubject = entry.key;
            if (languageBloc.currentLanguage == 'en') {
              switch (entry.key) {
                case 'Matematik':
                  translatedSubject = 'Mathematics';
                  break;
                case 'Fizik':
                  translatedSubject = 'Physics';
                  break;
                case 'Kimya':
                  translatedSubject = 'Chemistry';
                  break;
                case 'Biyoloji':
                  translatedSubject = 'Biology';
                  break;
              }
            }
            
            return _buildProgressBar(
              translatedSubject,
              entry.value,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcons.holographicIcon(
            icon,
            size: 24,
            primaryColor: color,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String subject, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 