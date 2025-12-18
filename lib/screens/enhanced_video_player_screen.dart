import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/bloc_exports.dart';
import '../models/video_watch_session.dart';
import '../services/video_session_service.dart';
import '../services/quest_service.dart';
import '../services/statistics_service.dart';

/// Enhanced Video Player Screen with Proper YouTube View Attribution
/// 
/// This player is configured to ensure all views are counted towards the
/// external YouTube channel's view count. The player uses YouTube's official
/// embed method which properly attributes views.
/// 
/// Features watch time tracking for TYT Matematik Lesson Narratives
class EnhancedVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String? subjectKey;  // e.g., "TYT_Matematik"
  final String? sectionType;  // e.g., "Konu Anlatımı" (Lesson Narratives)

  const EnhancedVideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.videoTitle,
    this.subjectKey,
    this.sectionType,
  });

  @override
  State<EnhancedVideoPlayerScreen> createState() => _EnhancedVideoPlayerScreenState();
}

class _EnhancedVideoPlayerScreenState extends State<EnhancedVideoPlayerScreen> 
    with TickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  
  // Comprehensive session tracking
  VideoWatchSession? _watchSession;
  final VideoSessionService _sessionService = VideoSessionService();
  bool _hasShownDialog = false; // Prevent duplicate dialogs
  int _lastEmittedWatchSeconds = 0;

  @override
  void initState() {
    super.initState();
    
    // Hide bottom navigation bar when entering video player screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BottomNavVisibilityBloc>().add(const HideBottomNav());
      }
    });
    
    // Fade animation for UI elements
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    // Initialize YouTube player controller
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true, // Auto-play ensures immediate engagement
        mute: false,
        enableCaption: true,
        // CRITICAL: These flags ensure proper YouTube view attribution
        forceHD: false, // Let YouTube decide quality based on connection
        hideThumbnail: false, // Show thumbnail before playing
        loop: false,
        isLive: false,
        // Controls visibility
        controlsVisibleAtStart: true,
        // Note: useHybridComposition removed to fix iOS WebKit crashes
        // Views are still properly attributed via YouTube IFrame API
      ),
    )..addListener(_listener);
    
    _fadeController.forward();
    
    // Initialize watch session for ALL videos (not just TYT Matematik)
    // This ensures watch time tracking and pop-up work for all content
    _initializeWatchSession();
    
    debugPrint('🎬 Video Player Initialized: ${widget.videoId}');
    debugPrint('   Title: ${widget.videoTitle}');
    debugPrint('   Subject: ${widget.subjectKey}');
    debugPrint('   Section: ${widget.sectionType}');
    debugPrint('   View attribution: ✅ Enabled via YouTube Player API');
  }
  
  /// Initialize comprehensive watch session
  void _initializeWatchSession() {
    // Extract branch from subject key (e.g., "TYT_Matematik" -> "MATEMATİK")
    final branch = _extractBranch(widget.subjectKey ?? '');
    // Extract grade level (e.g., "TYT_Matematik" -> "TYT")
    final gradeLevel = _extractGradeLevel(widget.subjectKey ?? '');
    
    _watchSession = VideoWatchSession(
      branch: branch,
      gradeLevel: gradeLevel,
      videoId: widget.videoId,
      videoTitle: widget.videoTitle,
      sessionStart: DateTime.now(),
    );
    
    debugPrint('');
    debugPrint('📊 ═══════════════════════════════════════════');
    debugPrint('📊 WATCH SESSION INITIALIZED');
    debugPrint('📊 ═══════════════════════════════════════════');
    debugPrint('📊 Branch: $branch');
    debugPrint('📊 Grade Level: $gradeLevel');
    debugPrint('📊 Video ID: ${widget.videoId}');
    debugPrint('📊 Session Start: ${_watchSession!.sessionStart}');
    debugPrint('📊 ═══════════════════════════════════════════');
    debugPrint('');
  }
  
  /// Extract branch name from subject key
  String _extractBranch(String subjectKey) {
    // TYT_Matematik -> MATEMATİK
    if (subjectKey.contains('Matematik')) return 'MATEMATİK';
    if (subjectKey.contains('Fizik')) return 'FİZİK';
    if (subjectKey.contains('Kimya')) return 'KİMYA';
    if (subjectKey.contains('Biyoloji')) return 'BİYOLOJİ';
    return 'UNKNOWN';
  }
  
  /// Extract grade level from subject key
  String _extractGradeLevel(String subjectKey) {
    // TYT_Matematik -> TYT
    if (subjectKey.contains('TYT')) return 'TYT';
    if (subjectKey.contains('AYT')) return 'AYT';
    if (subjectKey.contains('9')) return '9';
    if (subjectKey.contains('10')) return '10';
    if (subjectKey.contains('11')) return '11';
    return 'TYT'; // Default
  }
  
  void _listener() {
    if (_isPlayerReady && mounted) {
      // Track play/pause state changes for watch session
      if (_watchSession != null) {
        if (_controller.value.isPlaying && !_watchSession!.isActive) {
          // Video started/resumed playing
          _watchSession!.startPlaying();
          debugPrint('▶️ Playback started - timer resumed');
        } else if (!_controller.value.isPlaying && _watchSession!.isActive) {
          // Video paused/stopped
          _watchSession!.stopPlaying();
          debugPrint('⏸️ Playback paused - timer stopped');
          debugPrint('   Total watch time: ${_watchSession!.totalWatchTimeSeconds}s');
          // Emit quest progress in real-time on each pause
          final total = _watchSession!.totalWatchTimeSeconds;
          final delta = total - _lastEmittedWatchSeconds;
          if (delta > 0) {
            QuestService.instance.onVideoWatchedSeconds(delta);
            StatisticsService.instance.logStudyTime(video: delta);
            StatisticsService.instance.logDailyActivity(increment: 1);
            _lastEmittedWatchSeconds = total;
          }
        }
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Stop any active playback and finalize session if not already done
    try {
      if (_watchSession != null) {
        if (_watchSession!.isActive) {
          _watchSession!.stopPlaying();
        }
        if (_watchSession!.sessionEnd == null) {
          _watchSession!.endSession();
          // Save session even if dialog wasn't shown
          try {
            _sessionService.saveCurrentSession(_watchSession!);
            _sessionService.saveToHistory(_watchSession!);
            debugPrint('💾 Session saved in dispose (dialog may not have been shown)');
          } catch (e) {
            debugPrint('⚠️ Failed to save session in dispose: $e');
          }
          // Emit any remaining watch time to quests
          final total = _watchSession!.totalWatchTimeSeconds;
          final delta = total - _lastEmittedWatchSeconds;
          if (delta > 0) {
            QuestService.instance.onVideoWatchedSeconds(delta);
            StatisticsService.instance.logStudyTime(video: delta);
            StatisticsService.instance.logDailyActivity(increment: 1);
            _lastEmittedWatchSeconds = total;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error finalizing watch session in dispose: $e');
    }
    
    // Clean up controllers
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  /// Handle back button press - FORCE dialog and bottom nav restoration
  Future<bool> _onWillPop() async {
    debugPrint('');
    debugPrint('🔙 ═══════════════════════════════════════════');
    debugPrint('🔙 BACK BUTTON INTERCEPTED');
    debugPrint('🔙 ═══════════════════════════════════════════');
    debugPrint('   Subject Key: "${widget.subjectKey}"');
    debugPrint('   Section Type: "${widget.sectionType}"');
    debugPrint('   Has Session: ${_watchSession != null}');
    debugPrint('   Already Shown: $_hasShownDialog');
    
    // ALWAYS pause video first
    try {
      if (_controller.value.isPlaying) {
        _controller.pause();
        debugPrint('⏸️ Video PAUSED');
      }
    } catch (e) {
      debugPrint('⚠️ Error pausing video: $e');
    }
    
    // ALWAYS SHOW DIALOG if watch session exists (regardless of subject/section)
    // This ensures users always see their watch time when exiting any video
    final shouldShowDialog = _watchSession != null;
    
    debugPrint('   Should Show Dialog: $shouldShowDialog');
    debugPrint('   Watch Session Exists: ${_watchSession != null}');
    if (_watchSession != null) {
      debugPrint('   Watch Time: ${_watchSession!.totalWatchTimeSeconds} seconds');
    }
    
    if (shouldShowDialog && !_hasShownDialog) {
      _hasShownDialog = true; // Mark immediately to prevent duplicate
      
      // If session exists, finalize it
      if (_watchSession != null) {
        _watchSession!.endSession();
        debugPrint('📊 Session finalized: ${_watchSession!.getMetricFormat()}');
        
        try {
          await _sessionService.saveCurrentSession(_watchSession!);
          await _sessionService.saveToHistory(_watchSession!);
          debugPrint('💾 Session saved to persistence');
        } catch (e) {
          debugPrint('⚠️ Failed to save session: $e');
        }
      } else {
        // NO SESSION - Create emergency fallback session
        debugPrint('⚠️ NO SESSION - Creating fallback');
        final branch = _extractBranch(widget.subjectKey ?? 'UNKNOWN');
        final grade = _extractGradeLevel(widget.subjectKey ?? 'TYT');
        
        _watchSession = VideoWatchSession(
          branch: branch,
          gradeLevel: grade,
          videoId: widget.videoId,
          videoTitle: widget.videoTitle,
          sessionStart: DateTime.now().subtract(const Duration(seconds: 30)),
          totalWatchTimeSeconds: 30, // Fallback time
        );
        _watchSession!.endSession();
        debugPrint('✅ Fallback session created: ${_watchSession!.getMetricFormat()}');
      }
      
      // FORCE SHOW DIALOG - Multiple attempts
      debugPrint('🎨 FORCING DIALOG DISPLAY...');
      bool dialogSuccess = false;
      
      try {
        // Attempt 1: Direct show
        await _showSessionMetricDialog();
        dialogSuccess = true;
        debugPrint('✅ Dialog shown successfully (Attempt 1)');
      } catch (e) {
        debugPrint('❌ Dialog Attempt 1 failed: $e');
        
        // Attempt 2: After delay
        try {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            await _showSessionMetricDialog();
            dialogSuccess = true;
            debugPrint('✅ Dialog shown successfully (Attempt 2)');
          }
        } catch (e2) {
          debugPrint('❌ Dialog Attempt 2 failed: $e2');
          
          // Attempt 3: Emergency simple dialog
          try {
            await _showEmergencyDialog();
            dialogSuccess = true;
            debugPrint('✅ Emergency dialog shown (Attempt 3)');
          } catch (e3) {
            debugPrint('❌ All dialog attempts failed: $e3');
          }
        }
      }
      
      if (!dialogSuccess) {
        debugPrint('');
        debugPrint('❌ ═══════════════════════════════════════════');
        debugPrint('❌ CRITICAL: DIALOG FAILED TO DISPLAY');
        debugPrint('❌ Metric: ${_watchSession?.getMetricFormat() ?? "N/A"}');
        debugPrint('❌ ═══════════════════════════════════════════');
        debugPrint('');
      }
    }
    
    // FORCE BOTTOM NAV RESTORATION - Multiple attempts
    debugPrint('🔄 FORCING BOTTOM NAV RESTORATION...');
    if (mounted) {
      try {
        context.read<BottomNavVisibilityBloc>().add(const ShowBottomNav());
        debugPrint('✅ Bottom nav event dispatched');
      } catch (e) {
        debugPrint('❌ Failed to dispatch bottom nav event: $e');
      }
      
      // Wait for state propagation
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Second attempt
      if (mounted) {
        try {
          context.read<BottomNavVisibilityBloc>().add(const ShowBottomNav());
          debugPrint('✅ Bottom nav event dispatched (2nd attempt)');
        } catch (e) {
          debugPrint('❌ Failed 2nd bottom nav attempt: $e');
        }
      }
    }
    
    debugPrint('➡️ ALLOWING NAVIGATION');
    debugPrint('');
    
    return true; // Always allow navigation
  }
  
  /// Emergency simple dialog as fallback
  Future<void> _showEmergencyDialog() async {
    if (!mounted || _watchSession == null) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('İzleme Metriği'),
        content: Text(_watchSession!.getMetricFormat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }
  
  /// Show session metric dialog with guaranteed display
  /// Returns true if dialog was shown successfully
  Future<bool> _showSessionMetricDialog() async {
    if (_watchSession == null) {
      debugPrint('❌ Cannot show dialog: No watch session');
      return false;
    }
    
    if (!mounted) {
      debugPrint('❌ Cannot show dialog: Widget not mounted');
      return false;
    }
    
    final metric = _watchSession!.getMetricFormat();
    final branch = _watchSession!.branch;
    final gradeLevel = _watchSession!.gradeLevel;
    final seconds = _watchSession!.totalWatchTimeSeconds;
    
    debugPrint('');
    debugPrint('🎨 ═══════════════════════════════════════════');
    debugPrint('🎨 BUILDING DIALOG');
    debugPrint('🎨 ═══════════════════════════════════════════');
    debugPrint('🎨 Metric: $metric');
    debugPrint('🎨 Branch: $branch');
    debugPrint('🎨 Grade: $gradeLevel');
    debugPrint('🎨 Seconds: $seconds');
    debugPrint('🎨 ═══════════════════════════════════════════');
    debugPrint('');
    
    try {
      final languageBloc = context.read<LanguageBloc>();
      final isTurkish = languageBloc.currentLanguage == 'tr';
      
      // CRITICAL: Use showDialog with proper context
      await showDialog(
      context: context,
      barrierDismissible: false, // CRITICAL: User cannot dismiss by tapping outside
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false, // CRITICAL: Prevent Android back button
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    isTurkish ? 'İzleme Metriği' : 'Watch Time Metric',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Metric Display - PRIMARY FORMAT
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // PRIMARY METRIC: MATEMATİK-TYT-45 saniye
                        Text(
                          metric,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Divider(height: 1),
                        
                        const SizedBox(height: 16),
                        
                        // Breakdown
                        _buildMetricRow(
                          Icons.book_rounded,
                          isTurkish ? 'Ders' : 'Subject',
                          branch,
                        ),
                        const SizedBox(height: 8),
                        _buildMetricRow(
                          Icons.category_rounded,
                          isTurkish ? 'Seviye' : 'Level',
                          gradeLevel,
                        ),
                        const SizedBox(height: 8),
                        _buildMetricRow(
                          Icons.timer_rounded,
                          isTurkish ? 'İzleme Süresi' : 'Watch Time',
                          isTurkish ? '$seconds saniye' : '$seconds second${seconds != 1 ? 's' : ''}',
                        ),
                        const SizedBox(height: 12),
                        // Prominent display of watch time in seconds
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF667eea).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: const Color(0xFF667eea),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isTurkish 
                                  ? '$seconds saniye izlendi'
                                  : '$seconds second${seconds != 1 ? 's' : ''} watched',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF667eea),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Info text
                  Text(
                    isTurkish 
                      ? 'Bu video oturumu için harcanan zamanınız kaydedildi.'
                      : 'Your time spent on this video session has been recorded.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // TAMAM button - MUST BE CLICKED to proceed
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('');
                        debugPrint('✅ ═══════════════════════════════════════════');
                        debugPrint('✅ USER CLICKED TAMAM BUTTON');
                        debugPrint('✅ Metric acknowledged: $metric');
                        debugPrint('✅ Closing dialog...');
                        debugPrint('✅ ═══════════════════════════════════════════');
                        debugPrint('');
                        Navigator.of(dialogContext).pop(true); // Return true on success
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'TAMAM',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
      
      debugPrint('');
      debugPrint('✅ ═══════════════════════════════════════════');
      debugPrint('✅ DIALOG SUCCESSFULLY DISPLAYED AND DISMISSED');
      debugPrint('✅ ═══════════════════════════════════════════');
      debugPrint('');
      
      return true; // Dialog was shown successfully
      
    } catch (e) {
      debugPrint('');
      debugPrint('❌ ═══════════════════════════════════════════');
      debugPrint('❌ ERROR SHOWING DIALOG: $e');
      debugPrint('❌ ═══════════════════════════════════════════');
      debugPrint('');
      return false; // Dialog failed to show
    }
  }
  
  /// Build metric row widget
  Widget _buildMetricRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF667eea),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Open video on YouTube app/website
  /// This provides an alternative way for users to view the video
  /// which also contributes to view count
  Future<void> _openOnYouTube() async {
    final youtubeUrl = 'https://www.youtube.com/watch?v=${widget.videoId}';
    final uri = Uri.parse(youtubeUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('🔗 Opened video on YouTube: $youtubeUrl');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LanguageBloc>().currentLanguage == 'tr'
                  ? 'YouTube açılamadı'
                  : 'Could not open YouTube',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error opening YouTube: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageBloc>().currentLanguage == 'tr'
                ? 'Hata: YouTube açılamadı'
                : 'Error: Could not open YouTube',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share video
  Future<void> _shareVideo() async {
    final youtubeUrl = 'https://www.youtube.com/watch?v=${widget.videoId}';
    final languageBloc = context.read<LanguageBloc>();
    final videoTitle = widget.videoTitle.isNotEmpty 
        ? widget.videoTitle 
        : (languageBloc.currentLanguage == 'tr' ? 'Video' : 'Video');
    
    try {
      // ignore: deprecated_member_use
      await Share.share(
        youtubeUrl,
        subject: videoTitle,
      );
    } catch (e) {
      // Fallback to clipboard if share fails
      await Clipboard.setData(ClipboardData(text: youtubeUrl));
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageBloc.currentLanguage == 'tr'
                ? 'Video linki kopyalandı'
                : 'Video link copied',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // CRITICAL: Always call _onWillPop to show dialog if session exists
          // This ensures dialog appears regardless of how navigation is triggered
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          final languageBloc = context.read<LanguageBloc>();
          
          return YoutubePlayerBuilder(
          onEnterFullScreen: () {
            setState(() {
              _isFullScreen = true;
            });
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          },
          onExitFullScreen: () {
            setState(() {
              _isFullScreen = false;
            });
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
          },
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFF667eea),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFF667eea),
              handleColor: Color(0xFF764ba2),
              backgroundColor: Colors.grey,
              bufferedColor: Colors.white70,
            ),
            onReady: () {
              setState(() {
                _isPlayerReady = true;
              });
              
              // Start watch session tracking for TYT Matematik Lesson Narratives
              if (_watchSession != null) {
                _watchSession!.startPlaying();
                debugPrint('▶️ Video ready and playing - watch timer started');
              }
              
              debugPrint('✅ YouTube Player Ready - Views will be attributed');
            },
            onEnded: (metaData) {
              debugPrint('📊 Video ended: ${metaData.videoId}');
              debugPrint('   Duration: ${metaData.duration}');
            },
          ),
          builder: (context, player) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: _isFullScreen 
                ? null 
                : AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                      onPressed: () async {
                        // CRITICAL: Trigger PopScope logic to show dialog and restore bottom nav
                        final shouldPop = await _onWillPop();
                        if (shouldPop && mounted && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    title: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        languageBloc.translate('video_player'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    actions: [
                      // Open on YouTube button
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.open_in_new_rounded,
                            color: Colors.red,
                          ),
                        ),
                        tooltip: languageBloc.currentLanguage == 'tr'
                          ? "YouTube'da Aç"
                          : 'Open on YouTube',
                        onPressed: _openOnYouTube,
                      ),
                      // Share button
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.share_rounded),
                        ),
                        tooltip: languageBloc.currentLanguage == 'tr'
                          ? 'Paylaş'
                          : 'Share',
                        onPressed: _shareVideo,
                      ),
                    ],
                  ),
              body: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Video player
                    player,
                    
                    // Video information section
                    if (!_isFullScreen)
                      Expanded(
                        child: Container(
                          color: Colors.grey[900],
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Video title and info
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        widget.videoTitle,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Player state info
                                      if (_controller.value.isPlaying)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.green.withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.play_circle_filled,
                                                color: Colors.green,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                languageBloc.currentLanguage == 'tr'
                                                  ? 'Oynatılıyor'
                                                  : 'Playing',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Action buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildActionButton(
                                              icon: Icons.open_in_new_rounded,
                                              label: languageBloc.currentLanguage == 'tr'
                                                ? "YouTube'da Aç"
                                                : 'Open on YouTube',
                                              color: Colors.red,
                                              onTap: _openOnYouTube,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildActionButton(
                                              icon: Icons.share_rounded,
                                              label: languageBloc.currentLanguage == 'tr'
                                                ? 'Paylaş'
                                                : 'Share',
                                              color: Colors.blue,
                                              onTap: _shareVideo,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // View attribution info
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.green.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.verified_rounded,
                                              color: Colors.green[400],
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                languageBloc.currentLanguage == 'tr'
                                                  ? 'Bu video izlendiğinde YouTube kanalının görüntülenme sayısı artacaktır.'
                                                  : 'This video playback contributes to the YouTube channel view count.',
                                                style: TextStyle(
                                                  color: Colors.green[400],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Additional info section
                                const Divider(color: Colors.grey, height: 1),
                                
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        languageBloc.translate('video_information'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        languageBloc.currentLanguage == 'tr'
                                          ? 'Bu eğitim videosu size özel olarak hazırlanmıştır. İyi seyirler!'
                                          : 'This educational video has been prepared especially for you. Enjoy!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                          height: 1.5,
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
                  ],
                ),
              ),
            );
          },
        );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
