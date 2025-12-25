import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../blocs/bloc_exports.dart';
import '../services/youtube_playlist_service.dart';
import '../services/favorites_service.dart';
import 'enhanced_video_player_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Strict 2-Column Grid Video Feed Screen - Neumorphic Refactor
class VideoGridScreen extends StatefulWidget {
  final String subjectKey;
  final String subjectName;
  final String sectionType;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  final String? playlistId;
  final bool usePlaylistData;

  const VideoGridScreen({
    super.key,
    required this.subjectKey,
    required this.subjectName,
    required this.sectionType,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
    this.playlistId,
    this.usePlaylistData = false,
  });

  @override
  State<VideoGridScreen> createState() => _VideoGridScreenState();
}

class _VideoGridScreenState extends State<VideoGridScreen> with TickerProviderStateMixin {
  late AnimationController _gridController;
  
  bool _isLoading = true;
  List<Map<String, String>> _videos = [];
  bool _isPlaylistFavorited = false;
  bool _isLoadingFavorite = false;
  final FavoritesService _favoritesService = FavoritesService();
  
  List<String> _getInstructorImagesForPlaylist(String subjectKey, String playlistName) {
    final subjectLower = subjectKey.toLowerCase();
    final playlistLower = playlistName.toLowerCase();
    
    final isMatematik = subjectLower.contains('matematik');
    final isProblemlerPlaylist = playlistLower.contains('problemler') || 
                                  playlistLower.contains('problem') || 
                                  playlistLower.contains('kampi') || 
                                  playlistLower.contains('kamp') ||
                                  playlistLower.contains('tyt_matematik_problemler');
    
    if (isMatematik && isProblemlerPlaylist) {
      return [
        'assets/hocalar/bunyamin_bayraktutar.png',
        'assets/hocalar/omer_faruk_cetinkaya.png',
      ];
    }
    return [];
  }
  
  @override
  void initState() {
    super.initState();
    
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _loadVideoData();
    
    if (widget.playlistId != null) {
      _checkFavoriteStatus();
    }
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _loadVideoData() async {
    if (widget.usePlaylistData && widget.playlistId != null) {
      final youtubeService = YouTubePlaylistService();
      final playlistVideos = await youtubeService.fetchPlaylistVideos(widget.playlistId!);
      
      if (playlistVideos.isNotEmpty) {
        final videoIds = playlistVideos.map((v) => v['videoId'] as String).toList();
        final durationMap = await youtubeService.getVideoDurationsBatch(videoIds);
        
        setState(() {
          _videos = playlistVideos.map((video) {
            final videoId = video['videoId'] as String;
            final thumbnailUrl = video['thumbnailUrlMax'] as String? ?? 
                                 video['thumbnailUrl'] as String? ?? 
                                 '';
            final duration = durationMap[videoId] ?? YouTubePlaylistService.getHardcodedDuration(videoId) ?? '0:00';
            
            return {
              'videoId': videoId,
              'title': video['title'] as String,
              'duration': duration,
              'channel': video['channelTitle'] as String,
              'thumbnailUrl': thumbnailUrl,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _videos = _convertDummyData(youtubeService.getDummyPlaylistVideos(widget.playlistId!));
          _isLoading = false;
        });
      }
    } else {
      try {
        final videos = await _getVideosBySubject(widget.subjectKey);
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _videos = _getSampleVideosBySubject(widget.subjectKey);
          _isLoading = false;
        });
      }
    }
    
    _gridController.forward();
  }
  
  List<Map<String, String>> _convertDummyData(List<Map<String, dynamic>> dummyData) {
    return dummyData.map((video) {
      final videoId = video['videoId'] as String;
      final duration = YouTubePlaylistService.getHardcodedDuration(videoId) ?? '15:00';
      
      return {
        'videoId': videoId,
        'title': video['title'] as String,
        'duration': duration,
        'channel': video['channelTitle'] as String,
      };
    }).toList();
  }

  Future<List<Map<String, String>>> _getVideosBySubject(String subjectKey) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .doc(subjectKey)
          .collection(widget.sectionType)
          .orderBy('popularityScore', descending: true)
          .limit(50)
          .get();

      if (snapshot.docs.isEmpty) {
        return _getSampleVideosBySubject(subjectKey);
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'title': data['title'] as String? ?? 'Untitled Video',
          'videoId': data['videoId'] as String? ?? '',
          'duration': data['duration'] as String? ?? '0:00',
          'channel': data['channel'] as String? ?? 'Performax',
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  List<Map<String, String>> _getSampleVideosBySubject(String subjectKey) {
    const sampleVideoId = 'rU_HpnKjYlw';
    
    // Sample data (simplified for brevity, assume full map exists as in previous version)
    return [
      {
        'title': '$subjectKey - Örnek Video 1',
        'videoId': sampleVideoId,
        'duration': '15:00',
        'channel': 'Performax',
      },
      {
        'title': '$subjectKey - Örnek Video 2',
        'videoId': sampleVideoId,
        'duration': '20:00',
        'channel': 'Performax',
      },
    ];
  }

  bool _isTYTMatematik() {
    return (widget.subjectKey == 'TYT_Matematik' || widget.subjectKey == 'TYT_Matematik_Problemler') 
        && widget.usePlaylistData;
  }
  
  void _showComingSoonMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: NeumorphicColors.getBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Yakında Sizlerle', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: NeumorphicColors.getText(context)
            )
          ),
          content: Text(
            'Bu içerik henüz hazır değil.',
            style: TextStyle(color: NeumorphicColors.getText(context)),
          ),
          actions: [
            NeumorphicButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tamam',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.gradientStart,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openVideoPlayer(String videoId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedVideoPlayerScreen(
          videoId: videoId,
          videoTitle: title,
          subjectKey: widget.subjectKey,
          sectionType: widget.sectionType,
        ),
      ),
    );
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.playlistId == null) return;
    try {
      setState(() => _isLoadingFavorite = true);
      final isFavorited = await _favoritesService.isPlaylistFavorited(playlistId: widget.playlistId!);
      if (mounted) setState(() { _isPlaylistFavorited = isFavorited; _isLoadingFavorite = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }
  
  Future<void> _toggleFavorite() async {
    if (widget.playlistId == null) return;
    try {
      setState(() => _isLoadingFavorite = true);
      final instructorImages = _getInstructorImagesForPlaylist(widget.subjectKey, widget.subjectName);
      final success = await _favoritesService.toggleFavoritePlaylist(
        playlistId: widget.playlistId!,
        playlistName: widget.subjectName,
        subjectKey: widget.subjectKey,
        sectionType: widget.sectionType,
        thumbnailUrl: _videos.isNotEmpty ? _videos[0]['thumbnailUrl'] : null,
        instructorImagePaths: instructorImages,
        videoCount: _videos.length,
      );
      
      if (success && mounted) {
        final isFavorited = await _favoritesService.isPlaylistFavorited(playlistId: widget.playlistId!);
        setState(() {
          _isPlaylistFavorited = isFavorited;
          _isLoadingFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isPlaylistFavorited ? 'Playlist favorilere eklendi' : 'Playlist favorilerden çıkarıldı'),
            backgroundColor: _isPlaylistFavorited ? Colors.green : Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = NeumorphicColors.getBackground(context);
    final textColor = NeumorphicColors.getText(context);

    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_videos.length} Video',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.playlistId != null)
                        NeumorphicButton(
                          onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                          padding: const EdgeInsets.all(12),
                          borderRadius: 12,
                          child: _isLoadingFavorite
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(
                                  _isPlaylistFavorited ? Icons.favorite : Icons.favorite_border,
                                  color: _isPlaylistFavorited ? Colors.red : textColor,
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
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
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
      },
    );
  }

  Widget _buildVideoCard(Map<String, String> video, int index) {
    final videoId = video['videoId']!;
    final bool isComingSoon = !_isTYTMatematik();
    final textColor = NeumorphicColors.getText(context);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 80)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: NeumorphicButton(
              onPressed: isComingSoon 
                ? () => _showComingSoonMessage()
                : () => _openVideoPlayer(videoId, video['title']!),
              padding: const EdgeInsets.all(0),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _YouTubeThumbnailWithFallback(
                            videoId: videoId,
                            apiThumbnailUrl: video['thumbnailUrl'],
                            gradientStart: widget.gradientStart,
                          ),
                          
                          // Play Overlay
                          Container(
                            color: Colors.black.withValues(alpha: 0.2),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          
                          // Duration
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                video['duration']!,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          
                          // Locked Overlay
                          if (isComingSoon)
                            Container(
                              color: Colors.black.withValues(alpha: 0.7),
                              child: Center(
                                child: Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.8), size: 32),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video['channel']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

class _YouTubeThumbnailWithFallback extends StatelessWidget {
  final String videoId;
  final String? apiThumbnailUrl;
  final Color gradientStart;

  const _YouTubeThumbnailWithFallback({
    required this.videoId,
    this.apiThumbnailUrl,
    required this.gradientStart,
  });

  @override
  Widget build(BuildContext context) {
    final url = (apiThumbnailUrl != null && apiThumbnailUrl!.isNotEmpty)
        ? apiThumbnailUrl!
        : 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
        
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: Center(child: SpinKitFadingCircle(color: gradientStart, size: 20)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      ),
    );
  }
}
