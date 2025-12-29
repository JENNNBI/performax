import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../blocs/bloc_exports.dart';
import '../services/youtube_playlist_service.dart';
import '../services/quest_service.dart';
import '../services/statistics_service.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Video Player Screen with Details and Comments
/// Dedicated screen for watching videos with metadata and comments
class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String? videoTitle;
  final String? channelName;
  final String? description;
  final String? thumbnailUrl;
  final String? subjectTag; // e.g., 'Matematik', 'Fizik', 'General'

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.videoTitle,
    this.channelName,
    this.description,
    this.thumbnailUrl,
    this.subjectTag,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final YouTubePlaylistService _youtubeService = YouTubePlaylistService();
  bool _isDescriptionExpanded = false;
  
  // Watch time tracking
  DateTime? _currentSegmentStart;
  int _totalWatchTimeSeconds = 0;
  bool _isCurrentlyPlaying = false;

  @override
  void initState() {
    super.initState();
    
    // Hide bottom navigation bar when entering video player screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BottomNavVisibilityBloc>().add(const HideBottomNav());
      }
    });
    
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false, // User must tap play
        mute: false,
        forceHD: false, // Save data
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    )..addListener(_onPlayerStateChanged);
  }
  
  /// Listen to player state changes to track watch time
  void _onPlayerStateChanged() {
    if (!mounted) return;
    
    final isPlaying = _controller.value.isPlaying;
    
    if (isPlaying && !_isCurrentlyPlaying) {
      // Video started playing
      _isCurrentlyPlaying = true;
      _currentSegmentStart = DateTime.now();
      debugPrint('▶️ Video playback started');
    } else if (!isPlaying && _isCurrentlyPlaying) {
      // Video paused or stopped
      _isCurrentlyPlaying = false;
      if (_currentSegmentStart != null) {
        final elapsed = DateTime.now().difference(_currentSegmentStart!).inSeconds;
        _totalWatchTimeSeconds += elapsed;
        debugPrint('⏸️ Video paused. Segment: ${elapsed}s, Total: ${_totalWatchTimeSeconds}s');
        _currentSegmentStart = null;
      }
    }
  }

  
  /// Unified exit handler - called by both system back button and UI back button
  /// This ensures consistent behavior regardless of how user exits
  Future<void> _onExit() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚪 Exit handler triggered');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Step A: Pause video immediately
    try {
      if (_controller.value.isReady) {
        _controller.pause();
        debugPrint('⏸️ Video paused immediately');
      }
    } catch (e) {
      debugPrint('⚠️ Error pausing video: $e');
    }
    
    // Step B: Finalize watch time tracking
    if (_isCurrentlyPlaying && _currentSegmentStart != null) {
      final elapsed = DateTime.now().difference(_currentSegmentStart!).inSeconds;
      _totalWatchTimeSeconds += elapsed;
      _isCurrentlyPlaying = false;
      _currentSegmentStart = null;
      debugPrint('📊 Final watch segment: ${elapsed}s');
    }
    
    final durationInSeconds = _totalWatchTimeSeconds;
    final durationInMinutes = (durationInSeconds / 60).floor();
    final remainingSeconds = durationInSeconds % 60;
    
    debugPrint('   Total Watch Time: ${durationInSeconds}s (${durationInMinutes} minutes ${remainingSeconds} seconds)');
    debugPrint('   Subject Tag: ${widget.subjectTag ?? "General"}');
    
    // Format duration message
    String timeMessage;
    if (durationInMinutes > 0) {
      timeMessage = "$durationInMinutes dakika $remainingSeconds saniye boyunca çalıştın.";
    } else {
      timeMessage = "$durationInSeconds saniye boyunca çalıştın.";
    }
    
    // Step C: Show Summary Dialog (BLOCKING - MUST await)
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, cannot show dialog');
      return;
    }
    
    debugPrint('📊 Showing summary dialog (BLOCKING)...');
    await _showSummaryDialog(timeMessage, durationInSeconds);
    debugPrint('✅ Dialog dismissed by user');
    
    // Step D: Update Stats & Quests (AFTER dialog is closed)
    if (durationInSeconds > 30) {
      try {
        // Update Quest Progress
        QuestService.instance.updateProgress(
          type: 'watch_video',
          amount: durationInSeconds,
          subject: widget.subjectTag,
        );
        debugPrint('✅ Quest progress updated');
        
        // Update Statistics
        StatisticsService.instance.logStudyTime(video: durationInSeconds);
        StatisticsService.instance.logDailyActivity(increment: 1);
        debugPrint('✅ Statistics updated');
      } catch (e) {
        debugPrint('⚠️ Error updating stats/quests: $e');
      }
    } else {
      debugPrint('⏭️ Watch time too short (${durationInSeconds}s), skipping updates');
    }
    
    // Step E: Restore bottom navigation bar
    if (mounted) {
      try {
        context.read<BottomNavVisibilityBloc>().add(const ShowBottomNav());
        debugPrint('✅ Bottom nav restored');
      } catch (e) {
        debugPrint('⚠️ Error restoring bottom nav: $e');
      }
    }
    
    // Step F: Finally, close the video screen (ONLY after dialog is dismissed)
    if (mounted) {
      debugPrint('🚪 Closing video screen (after dialog)...');
      Navigator.of(context).pop();
    } else {
      debugPrint('⚠️ Widget not mounted, cannot pop');
    }
  }

  /// Show summary dialog with watch time
  /// CRITICAL: This method MUST be awaited to block navigation
  Future<void> _showSummaryDialog(String timeMessage, int seconds) async {
    if (!mounted) {
      debugPrint('⚠️ Cannot show dialog - widget not mounted');
      return;
    }
    
    final textColor = NeumorphicColors.getText(context);
    
    debugPrint('📊 Displaying dialog: $timeMessage');
    
    // CRITICAL: await this call - it blocks until dialog is dismissed
    await showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4CAF50), // Green
                          Color(0xFF66BB6A), // Light Green
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Tebrikler!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50), // Green
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Content with formatted duration
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                      children: [
                        TextSpan(
                          text: timeMessage,
                          style: TextStyle(
                            fontWeight: FontWeight.w600, // Make time bold for emphasis
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Button
                  NeumorphicButton(
                    onPressed: () {
                      // CRITICAL: Only close dialog, PopScope will handle screen close
                      Navigator.of(context).pop();
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    borderRadius: 16,
                    color: const Color(0xFF4CAF50), // Green
                    child: const Text(
                      'Devam Et',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  @override
  void dispose() {
    // Remove listener before disposing
    try {
      _controller.removeListener(_onPlayerStateChanged);
    } catch (e) {
      debugPrint('⚠️ Error removing listener: $e');
    }
    
    // Pause video immediately to stop audio
    try {
      if (_controller.value.isReady) {
        _controller.pause();
      }
    } catch (e) {
      debugPrint('⚠️ Error pausing video in dispose: $e');
    }
    
    // Dispose the controller to free resources and prevent memory leaks
    try {
      _controller.dispose();
    } catch (e) {
      debugPrint('⚠️ Error disposing controller: $e');
    }
    
    // Reset orientation to portrait (safety measure)
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (e) {
      debugPrint('⚠️ Error resetting orientation: $e');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = NeumorphicColors.getBackground(context);
    final textColor = NeumorphicColors.getText(context);

    return PopScope(
      canPop: false, // CRITICAL: Prevent automatic pop - must be false
      onPopInvoked: (didPop) async {
        // If pop already occurred, ignore (shouldn't happen with canPop: false)
        if (didPop) {
          debugPrint('⚠️ Pop already occurred, ignoring');
          return;
        }
        
        // Call unified exit handler and await it to ensure proper sequencing
        debugPrint('🔙 System back button intercepted');
        await _onExit();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Top Section: Video Player
              YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: NeumorphicColors.accentBlue,
                  progressColors: ProgressBarColors(
                    playedColor: NeumorphicColors.accentBlue,
                    handleColor: NeumorphicColors.accentBlue,
                    bufferedColor: NeumorphicColors.accentBlue.withValues(alpha: 0.3),
                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                builder: (context, player) {
                  return player;
                },
              ),

              // Middle Section: Video Metadata
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    if (widget.videoTitle != null)
                      Text(
                        widget.videoTitle!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    if (widget.videoTitle != null) const SizedBox(height: 8),
                    
                    // Channel Name
                    if (widget.channelName != null)
                      Text(
                        widget.channelName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    if (widget.channelName != null) const SizedBox(height: 16),
                    
                    // Description with Expansion
                    if (widget.description != null && widget.description!.isNotEmpty)
                      NeumorphicContainer(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Açıklama',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _isDescriptionExpanded
                                ? Text(
                                    widget.description!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withValues(alpha: 0.8),
                                      height: 1.5,
                                    ),
                                  )
                                : Text(
                                    widget.description!.length > 150
                                        ? '${widget.description!.substring(0, 150)}...'
                                        : widget.description!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withValues(alpha: 0.8),
                                      height: 1.5,
                                    ),
                                  ),
                            if (widget.description!.length > 150)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded = !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Text(
                                    _isDescriptionExpanded ? 'Daha Az Göster' : 'Daha Fazla Göster',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: NeumorphicColors.accentBlue,
                                      fontWeight: FontWeight.bold,
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

              // Bottom Section: Comments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yorumlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _youtubeService.fetchComments(widget.videoId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Yorumlar yüklenirken bir hata oluştu.',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }

                        final comments = snapshot.data ?? [];

                        if (comments.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Henüz yorum yok.',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return _buildCommentCard(comment, textColor);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ],
            ),
            ),
            // Floating Back Button Overlay
            Positioned(
              top: 16,
              left: 16,
              child: NeumorphicButton(
                onPressed: () {
                  // Call unified exit handler instead of direct Navigator.pop
                  debugPrint('🔙 UI back button pressed');
                  _onExit();
                },
                padding: const EdgeInsets.all(12),
                borderRadius: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: textColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: NeumorphicColors.accentBlue.withValues(alpha: 0.2),
              backgroundImage: comment['authorProfileImageUrl'] != null
                  ? NetworkImage(comment['authorProfileImageUrl'] as String)
                  : null,
              child: comment['authorProfileImageUrl'] == null
                  ? Text(
                      (comment['author'] as String? ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: NeumorphicColors.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Comment Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment['author'] as String? ?? 'Anonim',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (comment['likeCount'] != null && (comment['likeCount'] as int) > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up_outlined,
                              size: 14,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment['likeCount']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment['text'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.8),
                      height: 1.4,
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
} 