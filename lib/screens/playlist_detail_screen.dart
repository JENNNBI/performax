import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/playlist_model.dart';
import '../services/youtube_playlist_service.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_button.dart';
import 'video_player_screen.dart';

/// Playlist Detail Screen
/// Displays videos from a playlist with inline playback
class PlaylistDetailScreen extends StatefulWidget {
  final PlaylistModel playlist;
  final String subjectName;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.subjectName,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final YouTubePlaylistService _youtubeService = YouTubePlaylistService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _videos = [];
  String? _errorMessage;
  PlaylistModel? _enrichedPlaylist; // Playlist with dynamically fetched channel name

  @override
  void initState() {
    super.initState();
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🎬 PlaylistDetailScreen: Initializing');
    debugPrint('   Playlist Title: ${widget.playlist.title}');
    debugPrint('   Playlist ID: ${widget.playlist.playlistId}');
    debugPrint('   Channel: ${widget.playlist.channelName ?? "Will be fetched from API"}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _loadPlaylistMetadataAndVideos();
  }
  
  /// Load playlist metadata (including channel name) and videos
  Future<void> _loadPlaylistMetadataAndVideos() async {
    // First, fetch playlist metadata to get channel name
    final metadata = await _youtubeService.fetchPlaylistMetadata(widget.playlist.playlistId);
    
    if (metadata != null) {
      // Update playlist with dynamically fetched channel name
      setState(() {
        _enrichedPlaylist = widget.playlist.copyWith(
          channelName: metadata['channelTitle'] as String?,
        );
      });
      debugPrint('✅ Channel name fetched: ${_enrichedPlaylist!.channelName}');
    } else {
      // If metadata fetch fails, use channel name from first video
      debugPrint('⚠️ Could not fetch playlist metadata, will use channel from first video');
      _enrichedPlaylist = widget.playlist;
    }
    
    // Then load videos
    await _loadPlaylistVideos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPlaylistVideos() async {
    try {
      debugPrint('🎬 Loading videos for playlist: ${widget.playlist.playlistId}');
      
      final videos = await _youtubeService.fetchPlaylistVideos(widget.playlist.playlistId);
      
      if (videos.isNotEmpty) {
        debugPrint('✅ Successfully loaded ${videos.length} videos');
        
        // If channel name wasn't fetched from metadata, extract from first video
        if (_enrichedPlaylist?.channelName == null && videos.isNotEmpty) {
          final firstVideoChannel = videos[0]['channelTitle'] as String?;
          if (firstVideoChannel != null) {
            setState(() {
              _enrichedPlaylist = (_enrichedPlaylist ?? widget.playlist).copyWith(
                channelName: firstVideoChannel,
              );
            });
            debugPrint('✅ Channel name extracted from first video: $firstVideoChannel');
          }
        }
        
        final videoIds = videos.map((v) => v['videoId'] as String).toList();
        final durationMap = await _youtubeService.getVideoDurationsBatch(videoIds);
        
        setState(() {
          _videos = videos.map((video) {
            final videoId = video['videoId'] as String;
            final thumbnailUrl = video['thumbnailUrlMax'] as String? ?? 
                                 video['thumbnailUrl'] as String? ?? 
                                 '';
            final duration = durationMap[videoId] ?? 
                           YouTubePlaylistService.getHardcodedDuration(videoId) ?? 
                           '0:00';
            
            return {
              'videoId': videoId,
              'title': video['title'] as String,
              'description': video['description'] as String?,
              'duration': duration,
              'channel': video['channelTitle'] as String, // Dynamically fetched from API
              'thumbnailUrl': thumbnailUrl,
            };
          }).toList();
          _isLoading = false;
          _errorMessage = null; // Clear any previous errors
        });
      } else {
        debugPrint('⚠️ No videos found in playlist');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Playlist boş görünüyor. Lütfen daha sonra tekrar deneyin.';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading playlist videos: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Hata: $e';
      });
    }
  }

  void _playVideo(Map<String, dynamic> video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoId: video['videoId'] as String,
          videoTitle: video['title'] as String,
          channelName: video['channel'] as String,
          description: video['description'] as String?,
          thumbnailUrl: video['thumbnailUrl'] as String?,
          subjectTag: widget.subjectName, // Pass subject name as tag
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          widget.playlist.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _enrichedPlaylist?.channelName ?? widget.playlist.channelName ?? 'Yükleniyor...',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            // Video List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: SpinKitPulsingGrid(
                        color: widget.gradientStart,
                        size: 60.0,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 64,
                                  color: Colors.red.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hata',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                NeumorphicButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _errorMessage = null;
                                    });
                                    _loadPlaylistVideos();
                                  },
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  borderRadius: 12,
                                  child: Text(
                                    'Tekrar Dene',
                                    style: TextStyle(
                                      color: widget.gradientStart,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                  : _videos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 64,
                                color: textColor.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Video bulunamadı',
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
                          itemCount: _videos.length,
                          itemBuilder: (context, index) {
                            return _buildVideoCard(_videos[index], index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    final title = video['title'] as String;
    final duration = video['duration'] as String;
    final thumbnailUrl = video['thumbnailUrl'] as String;
    final channel = video['channel'] as String? ?? _enrichedPlaylist?.channelName ?? 'Bilinmiyor';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeumorphicButton(
        onPressed: () => _playVideo(video),
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      width: 160,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 160,
                        height: 90,
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 160,
                        height: 90,
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Icon(Icons.error_outline),
                      ),
                    ),
                    // Play Icon Overlay
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // Duration Badge
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Video Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: NeumorphicColors.getText(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel, // Use video's channel name from API (already dynamic)
                        style: TextStyle(
                          fontSize: 12,
                          color: NeumorphicColors.getText(context)
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
