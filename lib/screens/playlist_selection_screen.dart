import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/playlist_model.dart';
import '../services/playlist_config_service.dart';
import '../services/youtube_playlist_service.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';
import 'playlist_detail_screen.dart';

/// Playlist Selection Screen
/// Shows available playlists for a specific subject/category or level
class PlaylistSelectionScreen extends StatefulWidget {
  final String subjectName;
  final String subjectKey;
  final String category; // Category like 'Problemler' or level like '9. Sınıf', 'TYT', etc.
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  final String? level; // Optional level parameter for Matematik levels

  const PlaylistSelectionScreen({
    super.key,
    required this.subjectName,
    required this.subjectKey,
    required this.category,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
    this.level,
  });

  @override
  State<PlaylistSelectionScreen> createState() => _PlaylistSelectionScreenState();
}

class _PlaylistSelectionScreenState extends State<PlaylistSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _gridController;
  bool _isLoading = true;
  List<PlaylistModel> _playlists = [];
  final YouTubePlaylistService _youtubeService = YouTubePlaylistService();

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadPlaylists();
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    // Get playlists from config
    List<PlaylistModel> playlists;
    if (widget.level != null) {
      playlists = PlaylistConfigService.getPlaylistsForLevel(
        subject: widget.subjectKey, // Use subjectKey for lookup (e.g., 'Edebiyat' instead of 'Türk Dili ve Edebiyatı')
        level: widget.level!,
      );
    } else {
      playlists = PlaylistConfigService.getPlaylistsForCategory(
        subject: widget.subjectKey, // Use subjectKey for lookup
        category: widget.category,
      );
    }
    
    // Fetch channel names from YouTube API for each playlist
    final enrichedPlaylists = <PlaylistModel>[];
    for (final playlist in playlists) {
      if (playlist.channelName == null) {
        // Fetch channel name from API
        final metadata = await _youtubeService.fetchPlaylistMetadata(playlist.playlistId);
        if (metadata != null && metadata['channelTitle'] != null) {
          enrichedPlaylists.add(playlist.copyWith(
            channelName: metadata['channelTitle'] as String,
          ));
        } else {
          // If metadata fetch fails, try to get from first video
          try {
            final videos = await _youtubeService.fetchPlaylistVideos(playlist.playlistId);
            if (videos.isNotEmpty && videos[0]['channelTitle'] != null) {
              enrichedPlaylists.add(playlist.copyWith(
                channelName: videos[0]['channelTitle'] as String,
              ));
            } else {
              enrichedPlaylists.add(playlist); // Keep original if fetch fails
            }
          } catch (e) {
            debugPrint('⚠️ Could not fetch channel name for ${playlist.playlistId}: $e');
            enrichedPlaylists.add(playlist); // Keep original if fetch fails
          }
        }
      } else {
        enrichedPlaylists.add(playlist); // Already has channel name
      }
    }
    
    if (mounted) {
      setState(() {
        _playlists = enrichedPlaylists;
        _isLoading = false;
      });
      _gridController.forward();
    }
  }

  List<PlaylistModel> _getPlaylists() {
    return _playlists;
  }

  void _navigateToPlaylistDetail(PlaylistModel playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(
          playlist: playlist,
          subjectName: widget.subjectName,
          gradientStart: widget.gradientStart,
          gradientEnd: widget.gradientEnd,
          subjectIcon: widget.subjectIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = NeumorphicColors.getBackground(context);
    final textColor = NeumorphicColors.getText(context);
    final playlists = _getPlaylists();

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
                          widget.level ?? widget.category, // Show level if available, otherwise category
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          widget.subjectName,
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

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: SpinKitPulsingGrid(
                        color: widget.gradientStart,
                        size: 60.0,
                      ),
                    )
                  : playlists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.playlist_play_rounded,
                                size: 64,
                                color: textColor.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz playlist bulunmuyor',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            return _buildPlaylistCard(playlists[index], index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(PlaylistModel playlist, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * animValue),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: NeumorphicButton(
                onPressed: () => _navigateToPlaylistDetail(playlist),
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: playlist.thumbnailUrl == null || playlist.thumbnailUrl!.isEmpty
                        ? widget.gradientStart.withValues(alpha: 0.2)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Background: Video Thumbnail Image (hqdefault - guaranteed to exist)
                      if (playlist.thumbnailUrl != null && playlist.thumbnailUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: playlist.thumbnailUrl!,
                            fit: BoxFit.cover, // Cover ensures full background coverage
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(
                              color: widget.gradientStart.withValues(alpha: 0.2),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: widget.gradientStart.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      // Gradient Overlay for Text Readability (CRITICAL - Always visible)
                      // Dark gradient: lighter at top, darker at bottom where text is
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3), // Lighter at top
                              Colors.black.withValues(alpha: 0.7), // Medium in middle
                              Colors.black.withValues(alpha: 0.9), // Darker at bottom where text is
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      // Content (Title and Channel Name at bottom)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Playlist Title
                            Text(
                              playlist.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Channel Name
                            Row(
                              children: [
                                Icon(
                                  Icons.account_circle_rounded,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  playlist.channelName ?? 'Yükleniyor...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (playlist.description != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                playlist.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Play Icon Overlay (top-right)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
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
