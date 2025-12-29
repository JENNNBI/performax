import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import 'exam_type_selection_screen.dart';
import 'video_grid_screen.dart';
import 'playlist_selection_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Generic Grade Selection Screen
/// Shows grade level buttons (9.SINIF, 10.SINIF, 11.SINIF) and exam types (TYT, AYT, Paragraf)
/// Standardized for Video, PDF, and Question Solving
class GradeSelectionScreen extends StatefulWidget {
  final String subjectName;
  final String subjectKey;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  final String sectionType; // 'Video Lessons', 'PDF Notes', 'Question Solving'
  
  const GradeSelectionScreen({
    super.key,
    required this.subjectName,
    required this.subjectKey,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
    this.sectionType = 'Video Lessons',
  });

  @override
  State<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends State<GradeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Grid animation
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _loadData();
  }

  @override
  void dispose() {
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

  /// Subject-Level Configuration Map
  /// Defines available levels for each subject
  static final Map<String, List<String>> subjectLevelConfig = {
    // Standard Sciences & Math (Grades 9-11 only, plus Exams)
    'Matematik': ['9. Sınıf', '10. Sınıf', '11. Sınıf', 'TYT', 'AYT', 'Problemler'],
    'Fizik':     ['9. Sınıf', '10. Sınıf', '11. Sınıf', 'TYT', 'AYT'],
    'Kimya':     ['9. Sınıf', '10. Sınıf', '11. Sınıf', 'TYT', 'AYT'],
    'Biyoloji':  ['9. Sınıf', '10. Sınıf', '11. Sınıf', 'TYT', 'AYT'],
    'Tarih':     ['9. Sınıf', '10. Sınıf', '11. Sınıf', 'TYT', 'AYT'],
    'Coğrafya':  ['9. Sınıf', '10. Sınıf', '11. Sınıf', 'TYT', 'AYT'],
    
    // Custom Subject Rules
    'Türkçe':    ['TYT', 'Paragraf'], // Only TYT and Paragraf (9. Sınıf removed)
    'Edebiyat':  ['9. Sınıf', '10. Sınıf', '11. Sınıf', 'AYT'], // No 12, No TYT
    'Geometri':  ['TYT-AYT'], // Combined single option
    'Felsefe':   ['TYT', 'AYT'], // Separate options
  };

  /// Get grade level options based on subject-level configuration
  List<Map<String, dynamic>> _getGradeLevels(LanguageBloc languageBloc) {
    final subjectName = widget.subjectName;
    final subjectKey = widget.subjectKey; // Use key for config lookup (e.g., 'Edebiyat' instead of 'Türk Dili ve Edebiyatı')
    final isEnglish = languageBloc.currentLanguage == 'en';
    
    // Get allowed levels for this subject (use subjectKey for lookup)
    final allowedLevels = subjectLevelConfig[subjectKey] ?? [];
    
    if (allowedLevels.isEmpty) {
      // Fallback: return empty list if subject not found
      return [];
    }

    // Build level options based on configuration
    List<Map<String, dynamic>> levels = [];
    
    for (final level in allowedLevels) {
      Map<String, dynamic> levelData;
      
      // Handle special combined option for Geometri
      if (level == 'TYT-AYT') {
        levelData = {
          'name': 'TYT-AYT',
          'key': 'tyt_ayt',
          'description': isEnglish
            ? 'TYT-AYT ${subjectName}'
            : 'TYT-AYT ${subjectName}',
          'accentColor': const Color(0xFF764ba2),
          'isCombined': true,
        };
      }
      // Handle Paragraf for Türkçe
      else if (level == 'Paragraf') {
        levelData = {
          'name': 'PARAGRAF',
          'key': 'paragraf',
          'description': isEnglish
            ? 'Paragraph ${subjectName}'
            : 'Paragraf ${subjectName}',
          'accentColor': const Color(0xFFfa709a),
        };
      }
      // Handle Problemler for Matematik
      else if (level == 'Problemler') {
        levelData = {
          'name': 'PROBLEMLER',
          'key': 'problemler',
          'description': isEnglish
            ? 'Problems ${subjectName}'
            : 'Problemler ${subjectName}',
          'accentColor': const Color(0xFF667eea),
        };
      }
      // Handle TYT
      else if (level == 'TYT') {
        levelData = {
          'name': 'TYT',
          'key': 'tyt',
          'description': isEnglish
            ? 'TYT ${subjectName}'
            : 'TYT ${subjectName}',
          'accentColor': const Color(0xFFA8E063),
        };
      }
      // Handle AYT
      else if (level == 'AYT') {
        levelData = {
          'name': 'AYT',
          'key': 'ayt',
          'description': isEnglish
            ? 'AYT ${subjectName}'
            : 'AYT ${subjectName}',
          'accentColor': const Color(0xFFF5CBCB),
        };
      }
      // Handle grade levels (9, 10, 11)
      else {
        final gradeNum = level.split('.')[0];
        final gradeKey = '${gradeNum}_sinif';
        Color accentColor;
        switch (gradeNum) {
          case '9':
            accentColor = const Color(0xFF667EEA);
            break;
          case '10':
            accentColor = const Color(0xFFF37335);
            break;
          case '11':
            accentColor = const Color(0xFFF38181);
            break;
          default:
            accentColor = const Color(0xFF667EEA);
        }
        
        levelData = {
          'name': level.toUpperCase(),
          'key': gradeKey,
          'description': isEnglish
            ? '${level} ${subjectName}'
            : '${level} ${subjectName}',
          'accentColor': accentColor,
        };
      }
      
      levels.add(levelData);
    }

    return levels;
  }

  void _onGradeSelected(Map<String, dynamic> gradeLevel) {
    final levelKey = gradeLevel['key'] as String;
    final levelName = gradeLevel['name'] as String;
    final isGradeLevel = levelKey.contains('_sinif'); // 9_sinif, 10_sinif, 11_sinif
    final isDirectExamType = ['tyt', 'ayt', 'paragraf', 'problemler', 'tyt_ayt'].contains(levelKey);
    
    // Special handling for Matematik levels - navigate directly to playlist selection
    if (widget.subjectKey == 'Matematik' && (isGradeLevel || ['tyt', 'ayt'].contains(levelKey))) {
      // Convert level key/name to standard format for playlist lookup
      String playlistLevel;
      if (isGradeLevel) {
        // Convert "9_sinif" -> "9. Sınıf"
        final gradeNum = levelKey.split('_')[0];
        playlistLevel = '$gradeNum. Sınıf';
      } else {
        // TYT or AYT
        playlistLevel = levelName.toUpperCase();
      }
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Fizik levels (9, 10, 11, TYT, AYT) - navigate directly to playlist selection
    if (widget.subjectKey == 'Fizik' && (isGradeLevel || ['tyt', 'ayt'].contains(levelKey))) {
      // Convert level key/name to standard format for playlist lookup
      String playlistLevel;
      if (isGradeLevel) {
        // Convert "9_sinif" -> "9. Sınıf"
        final gradeNum = levelKey.split('_')[0];
        playlistLevel = '$gradeNum. Sınıf';
      } else {
        // TYT or AYT
        playlistLevel = levelName.toUpperCase();
      }
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Kimya levels (9, 10, 11, TYT, AYT) - navigate directly to playlist selection
    if (widget.subjectKey == 'Kimya' && (isGradeLevel || ['tyt', 'ayt'].contains(levelKey))) {
      // Convert level key/name to standard format for playlist lookup
      String playlistLevel;
      if (isGradeLevel) {
        // Convert "9_sinif" -> "9. Sınıf"
        final gradeNum = levelKey.split('_')[0];
        playlistLevel = '$gradeNum. Sınıf';
      } else {
        // TYT or AYT
        playlistLevel = levelName.toUpperCase();
      }
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Biyoloji levels (9, 10, 11, TYT, AYT) - navigate directly to playlist selection
    if (widget.subjectKey == 'Biyoloji' && (isGradeLevel || ['tyt', 'ayt'].contains(levelKey))) {
      // Convert level key/name to standard format for playlist lookup
      String playlistLevel;
      if (isGradeLevel) {
        // Convert "9_sinif" -> "9. Sınıf"
        final gradeNum = levelKey.split('_')[0];
        playlistLevel = '$gradeNum. Sınıf';
      } else {
        // TYT or AYT
        playlistLevel = levelName.toUpperCase();
      }
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Felsefe levels (TYT, AYT) - navigate directly to playlist selection
    if (widget.subjectKey == 'Felsefe' && ['tyt', 'ayt'].contains(levelKey)) {
      // Convert level name to standard format for playlist lookup
      final playlistLevel = levelName.toUpperCase(); // TYT or AYT
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Coğrafya levels (9, 10, 11, TYT, AYT) - navigate directly to playlist selection
    if (widget.subjectKey == 'Coğrafya' && (isGradeLevel || ['tyt', 'ayt'].contains(levelKey))) {
      // Convert level key/name to standard format for playlist lookup
      String playlistLevel;
      if (isGradeLevel) {
        // Convert "9_sinif" -> "9. Sınıf"
        final gradeNum = levelKey.split('_')[0];
        playlistLevel = '$gradeNum. Sınıf';
      } else {
        // TYT or AYT
        playlistLevel = levelName.toUpperCase();
      }
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Tarih levels (9, 10, 11, TYT, AYT) - navigate directly to playlist selection
    if (widget.subjectKey == 'Tarih' && (isGradeLevel || ['tyt', 'ayt'].contains(levelKey))) {
      // Convert level key/name to standard format for playlist lookup
      String playlistLevel;
      if (isGradeLevel) {
        // Convert "9_sinif" -> "9. Sınıf"
        final gradeNum = levelKey.split('_')[0];
        playlistLevel = '$gradeNum. Sınıf';
      } else {
        // TYT or AYT
        playlistLevel = levelName.toUpperCase();
      }
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Türkçe levels (TYT and Paragraf) - navigate directly to playlist selection
    if (widget.subjectName == 'Türkçe' && ['tyt', 'paragraf'].contains(levelKey)) {
      // Convert level key/name to standard format for playlist lookup
      String playlistLevel;
      if (levelKey == 'paragraf') {
        playlistLevel = 'Paragraf'; // Capitalize first letter
      } else {
        playlistLevel = levelName.toUpperCase(); // TYT
      }
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Edebiyat (TDE) levels (9, 10, 11, AYT) - navigate directly to playlist selection
    if (widget.subjectKey == 'Edebiyat' && (isGradeLevel || levelKey == 'ayt')) {
      // Convert level key/name to standard format for playlist lookup
      String playlistLevel;
      if (isGradeLevel) {
        // Convert "9_sinif" -> "9. Sınıf" (with proper capitalization)
        final gradeNum = levelKey.split('_')[0];
        playlistLevel = '$gradeNum. Sınıf';
      } else {
        // AYT
        playlistLevel = 'AYT';
      }
      
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: playlistLevel,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: playlistLevel, // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // Special handling for Geometri TYT-AYT - navigate directly to playlist selection
    if (widget.subjectKey == 'Geometri' && levelKey == 'tyt_ayt') {
      // Navigate to Playlist Selection Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: 'TYT-AYT',
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            level: 'TYT-AYT', // Pass level for playlist lookup
          ),
        ),
      );
      return;
    }
    
    // If user selected a grade level (9, 10, 11), go to Exam Type Selection
    // If user selected TYT/AYT/Paragraf directly, skip Exam Type and go to content
    if (isGradeLevel) {
      // Grade level selected -> navigate to Exam Type Selection
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamTypeSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            gradeLevel: levelKey,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
            sectionType: widget.sectionType,
          ),
        ),
      );
    } else if (isDirectExamType) {
      // Direct exam type selected -> navigate to content directly
      // Import VideoGridScreen at the top if not already imported
      _navigateToContentDirectly(levelKey, gradeLevel);
    }
  }
  
  void _navigateToContentDirectly(String levelKey, Map<String, dynamic> gradeLevel) {
    // Special handling for "Problemler" - show playlist selection instead of direct videos
    if (levelKey == 'problemler' && widget.subjectName == 'Matematik') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistSelectionScreen(
            subjectName: widget.subjectName,
            subjectKey: widget.subjectKey,
            category: 'Problemler',
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
            subjectIcon: widget.subjectIcon,
          ),
        ),
      );
      return;
    }
    
    // Build subject key for VideoGridScreen
    // Format: "TYT_Matematik", "AYT_Fizik", "Paragraf_Türkçe", etc.
    String subjectKey;
    String displayName;
    
    if (levelKey == 'tyt_ayt') {
      // Special handling for TYT-AYT combined (Geometri)
      // For now, we'll show TYT content, but this could be customized
      subjectKey = 'TYT_${widget.subjectKey}';
      displayName = '${widget.subjectName} TYT-AYT';
    } else {
      final examType = levelKey.toUpperCase();
      subjectKey = '${examType}_${widget.subjectKey}';
      displayName = '${widget.subjectName} $examType';
    }
    
    // Import VideoGridScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoGridScreen(
          subjectKey: subjectKey,
          subjectName: displayName,
          sectionType: widget.sectionType,
          gradientStart: widget.gradientStart,
          gradientEnd: widget.gradientEnd,
          subjectIcon: widget.subjectIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final gradeLevels = _getGradeLevels(languageBloc);
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subjectName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              languageBloc.currentLanguage == 'tr'
                                  ? 'Sınıf Seçimi'
                                  : 'Select Grade',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      NeumorphicContainer(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: Icon(
                          widget.subjectIcon,
                          color: widget.gradientStart,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Grid
                Expanded(
                  child: _isLoading
                    ? Center(
                        child: SpinKitPulsingGrid(
                          color: widget.gradientStart,
                          size: 60.0,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: gradeLevels.length,
                        itemBuilder: (context, index) {
                          return _buildGradeCard(gradeLevels[index], index);
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

  Widget _buildGradeCard(Map<String, dynamic> gradeLevel, int index) {
    final name = gradeLevel['name'] as String;
    final isGradeLevel = name.contains('.');
    final isCombined = gradeLevel['isCombined'] == true;
    
    // Determine display text
    String mainText;
    String? subtitleText;
    
    if (isCombined) {
      // TYT-AYT combined option
      mainText = 'TYT-AYT';
      subtitleText = null;
    } else if (isGradeLevel) {
      // Grade level (9. SINIF, 10. SINIF, etc.)
      mainText = name.split('.')[0]; // "9"
      subtitleText = name.split(' ')[1]; // "SINIF"
    } else {
      // Exam type (TYT, AYT, PARAGRAF)
      mainText = name;
      subtitleText = null;
    }
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: NeumorphicButton(
              onPressed: () => _onGradeSelected(gradeLevel),
              padding: EdgeInsets.zero,
              borderRadius: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      mainText,
                      style: TextStyle(
                        fontSize: isCombined || !isGradeLevel ? 32 : 48,
                        fontWeight: FontWeight.bold,
                        color: gradeLevel['accentColor'],
                      ),
                    ),
                  ),
                  if (subtitleText != null)
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NeumorphicColors.getText(context).withValues(alpha: 0.6),
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
}
