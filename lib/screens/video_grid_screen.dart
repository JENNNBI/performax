import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../blocs/bloc_exports.dart';
import '../services/youtube_playlist_service.dart';
import '../services/favorites_service.dart';
import 'enhanced_video_player_screen.dart';

/// Strict 2-Column Grid Video Feed Screen
/// Displays YouTube video thumbnails in a 2-column layout
/// Ensures proper YouTube view attribution
/// 
/// Special handling for TYT Matematik: loads videos from playlist PLHk4O6pXTZyMWD71RVkNOvMBFO-RDH_KW
class VideoGridScreen extends StatefulWidget {
  final String subjectKey;
  final String subjectName;
  final String sectionType;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;
  final String? playlistId;  // ← Optional: YouTube playlist ID for special categories
  final bool usePlaylistData;  // ← Flag to use playlist data instead of sample data

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

class _VideoGridScreenState extends State<VideoGridScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _gridController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  
  bool _isLoading = true;
  List<Map<String, String>> _videos = [];
  bool _isPlaylistFavorited = false;
  bool _isLoadingFavorite = false;
  final FavoritesService _favoritesService = FavoritesService();
  
  /// Get instructor image paths for a playlist based on subject and playlist info
  /// Returns list of instructor image asset paths
  List<String> _getInstructorImagesForPlaylist(String subjectKey, String playlistName) {
    final subjectLower = subjectKey.toLowerCase();
    final playlistLower = playlistName.toLowerCase();
    
    // Debug logging to help identify matching issues
    debugPrint('🔍 Checking instructor images for playlist:');
    debugPrint('   subjectKey: $subjectKey');
    debugPrint('   playlistName: $playlistName');
    
    // Problemler Kampı playlist uses both instructors
    // Check multiple conditions to ensure we catch all variations
    final isMatematik = subjectLower.contains('matematik');
    final isProblemlerPlaylist = playlistLower.contains('problemler') || 
                                  playlistLower.contains('problem') || 
                                  playlistLower.contains('kampi') || 
                                  playlistLower.contains('kamp') ||
                                  playlistLower.contains('tyt_matematik_problemler');
    
    if (isMatematik && isProblemlerPlaylist) {
      debugPrint('✅ Matched Problemler Kampı - returning instructor images');
      return [
        'assets/hocalar/bunyamin_bayraktutar.png',
        'assets/hocalar/omer_faruk_cetinkaya.png',
      ];
    }
    
    debugPrint('❌ No instructor images matched');
    // Default: Return empty list if no specific instructors match
    // Can be extended for other subjects/playlists
    return [];
  }

  @override
  void initState() {
    super.initState();
    
    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    
    // Grid animation
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Start animations
    _headerController.forward();
    
    // Load video data
    _loadVideoData();
    
    // Check favorite status if playlist ID exists
    if (widget.playlistId != null) {
      _checkFavoriteStatus();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _loadVideoData() async {
    // Special handling for playlist-based content (e.g., TYT Matematik)
    if (widget.usePlaylistData && widget.playlistId != null) {
      debugPrint('🎬 Loading playlist: ${widget.playlistId}');
      debugPrint('   Subject: ${widget.subjectKey}');
      debugPrint('   Section: ${widget.sectionType}');
      
      final youtubeService = YouTubePlaylistService();
      final playlistVideos = await youtubeService.fetchPlaylistVideos(widget.playlistId!);
      
      if (playlistVideos.isNotEmpty) {
        // Extract video IDs for batch duration fetching
        final videoIds = playlistVideos.map((v) => v['videoId'] as String).toList();
        
        // Fetch durations for all videos in batch (uses hardcoded map first, then API for missing)
        debugPrint('⏱️ Fetching durations for ${videoIds.length} videos...');
        final durationMap = await youtubeService.getVideoDurationsBatch(videoIds);
        
        // Convert playlist data to our video format with actual durations and thumbnails
        setState(() {
          _videos = playlistVideos.map((video) {
            final videoId = video['videoId'] as String;
            final thumbnailUrl = video['thumbnailUrlMax'] as String? ?? 
                                 video['thumbnailUrl'] as String? ?? 
                                 '';
            
            // Use duration from map, fallback to '0:00' if not found
            final duration = durationMap[videoId] ?? YouTubePlaylistService.getHardcodedDuration(videoId) ?? '0:00';
            
            return {
              'videoId': videoId,
              'title': video['title'] as String,
              'duration': duration,
              'channel': video['channelTitle'] as String,
              'thumbnailUrl': thumbnailUrl, // Store thumbnail URL for use in rendering
            };
          }).toList();
          _isLoading = false;
        });
        
        debugPrint('✅ Loaded ${_videos.length} videos from playlist with durations');
      } else {
        // Fallback to dummy data if API fails
        debugPrint('⚠️ Playlist loading failed, using fallback data');
        setState(() {
          _videos = _convertDummyData(youtubeService.getDummyPlaylistVideos(widget.playlistId!));
          _isLoading = false;
        });
      }
    } else {
      // Fetch from Firebase, fallback to sample data
      try {
        final videos = await _getVideosBySubject(widget.subjectKey);
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('⚠️ Error loading videos from Firebase: $e');
        // Fallback to sample data
        setState(() {
          _videos = _getSampleVideosBySubject(widget.subjectKey);
          _isLoading = false;
        });
      }
    }
    
    _gridController.forward();
  }
  
  /// Convert dummy playlist data to video format
  List<Map<String, String>> _convertDummyData(List<Map<String, dynamic>> dummyData) {
    return dummyData.map((video) {
      final videoId = video['videoId'] as String;
      // Use hardcoded duration if available, otherwise use placeholder
      final duration = YouTubePlaylistService.getHardcodedDuration(videoId) ?? '15:00';
      
      return {
        'videoId': videoId,
        'title': video['title'] as String,
        'duration': duration,
        'channel': video['channelTitle'] as String,
      };
    }).toList();
  }


  /// Get video data by subject from Firebase
  /// Falls back to sample data if Firebase is unavailable
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
        debugPrint('📭 No videos found in Firebase for $subjectKey/${widget.sectionType}, using sample data');
        return _getSampleVideosBySubject(subjectKey);
      }

      final videos = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'title': data['title'] as String? ?? 'Untitled Video',
          'videoId': data['videoId'] as String? ?? '',
          'duration': data['duration'] as String? ?? '0:00',
          'channel': data['channel'] as String? ?? 'Performax',
        };
      }).toList();

      debugPrint('✅ Loaded ${videos.length} videos from Firebase for $subjectKey/${widget.sectionType}');
      return videos;
    } catch (e) {
      debugPrint('❌ Error fetching videos from Firebase: $e');
      rethrow; // Let caller handle fallback
    }
  }

  /// Get sample video data by subject (fallback)
  /// Using videoId: rU_HpnKjYlw as sample content (from https://www.youtube.com/watch?v=rU_HpnKjYlw)
  List<Map<String, String>> _getSampleVideosBySubject(String subjectKey) {
    // Sample data structure using specified YouTube video ID: rU_HpnKjYlw
    const sampleVideoId = 'rU_HpnKjYlw'; // Official sample video from YouTube playlist
    
    final videoDatabase = {
      'Matematik': [
        {
          'title': 'Fonksiyonlar - Temel Kavramlar',
          'videoId': sampleVideoId,
          'duration': '15:30',
          'channel': 'Performax Matematik',
        },
        {
          'title': 'Türev Alma Kuralları',
          'videoId': sampleVideoId,
          'duration': '22:45',
          'channel': 'Performax Matematik',
        },
        {
          'title': 'İntegral Hesaplama',
          'videoId': sampleVideoId,
          'duration': '18:20',
          'channel': 'Performax Matematik',
        },
        {
          'title': 'Limit Kavramı ve Uygulamaları',
          'videoId': sampleVideoId,
          'duration': '20:15',
          'channel': 'Performax Matematik',
        },
        {
          'title': 'Trigonometri - Sin, Cos, Tan',
          'videoId': sampleVideoId,
          'duration': '17:40',
          'channel': 'Performax Matematik',
        },
        {
          'title': 'Logaritma ve Üstel Fonksiyonlar',
          'videoId': sampleVideoId,
          'duration': '19:25',
          'channel': 'Performax Matematik',
        },
      ],
      'Fizik': [
        {
          'title': 'Newton Yasaları',
          'videoId': sampleVideoId,
          'duration': '20:15',
          'channel': 'Performax Fizik',
        },
        {
          'title': 'Elektromanyetizma Temelleri',
          'videoId': sampleVideoId,
          'duration': '25:30',
          'channel': 'Performax Fizik',
        },
        {
          'title': 'Kuvvet ve Hareket',
          'videoId': sampleVideoId,
          'duration': '18:50',
          'channel': 'Performax Fizik',
        },
        {
          'title': 'Enerji ve İş',
          'videoId': sampleVideoId,
          'duration': '16:30',
          'channel': 'Performax Fizik',
        },
      ],
      'Kimya': [
        {
          'title': 'Atom Yapısı ve Periyodik Sistem',
          'videoId': sampleVideoId,
          'duration': '16:45',
          'channel': 'Performax Kimya',
        },
        {
          'title': 'Kimyasal Bağlar',
          'videoId': sampleVideoId,
          'duration': '19:20',
          'channel': 'Performax Kimya',
        },
        {
          'title': 'Asitler ve Bazlar',
          'videoId': sampleVideoId,
          'duration': '21:10',
          'channel': 'Performax Kimya',
        },
        {
          'title': 'Kimyasal Reaksiyonlar',
          'videoId': sampleVideoId,
          'duration': '17:55',
          'channel': 'Performax Kimya',
        },
      ],
      'Biyoloji': [
        {
          'title': 'Hücre Yapısı ve Organeller',
          'videoId': sampleVideoId,
          'duration': '18:30',
          'channel': 'Performax Biyoloji',
        },
        {
          'title': 'DNA ve Genetik',
          'videoId': sampleVideoId,
          'duration': '22:15',
          'channel': 'Performax Biyoloji',
        },
        {
          'title': 'Fotosentez ve Solunum',
          'videoId': sampleVideoId,
          'duration': '19:45',
          'channel': 'Performax Biyoloji',
        },
        {
          'title': 'Ekosistem ve Biyoçeşitlilik',
          'videoId': sampleVideoId,
          'duration': '16:20',
          'channel': 'Performax Biyoloji',
        },
      ],
      'Türkçe': [
        {
          'title': 'Dil Bilgisi - Fiiller',
          'videoId': sampleVideoId,
          'duration': '15:40',
          'channel': 'Performax Türkçe',
        },
        {
          'title': 'Edebiyat - Nazım Türleri',
          'videoId': sampleVideoId,
          'duration': '20:25',
          'channel': 'Performax Türkçe',
        },
        {
          'title': 'Anlam Bilgisi',
          'videoId': sampleVideoId,
          'duration': '17:30',
          'channel': 'Performax Türkçe',
        },
        {
          'title': 'Paragraf Soruları Çözüm Teknikleri',
          'videoId': sampleVideoId,
          'duration': '19:15',
          'channel': 'Performax Türkçe',
        },
      ],
    };
    
    return videoDatabase[subjectKey] ?? [
      {
        'title': '$subjectKey - Örnek Video',
        'videoId': sampleVideoId,
        'duration': '15:00',
        'channel': 'Performax',
      },
    ];
  }

  /// Check if current subject is TYT Matematik or Problems Camp (exceptions to "Coming Soon")
  bool _isTYTMatematik() {
    return (widget.subjectKey == 'TYT_Matematik' || widget.subjectKey == 'TYT_Matematik_Problemler') 
        && widget.usePlaylistData;
  }
  
  /// Show "Coming Soon" message when user taps on locked content
  void _showComingSoonMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.gradientStart, widget.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Yakında Sizlerle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu içerik henüz hazır değil.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Yakında sizlerle buluşacak! 🎓',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.gradientStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.gradientStart.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: widget.gradientStart,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TYT Matematik içeriği şu anda kullanılabilir durumda!',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.gradientStart,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: widget.gradientStart,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Tamam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EnhancedVideoPlayerScreen(
          videoId: videoId,
          videoTitle: title,
          subjectKey: widget.subjectKey,  // Pass subject key (e.g., "TYT_Matematik")
          sectionType: widget.sectionType,  // Pass section type (e.g., "Konu Anlatımı")
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var fadeAnimation = animation.drive(tween);
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: CustomScrollView(
            slivers: [
              // Animated App Bar
              SliverAppBar(
                expandedHeight: 160.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: widget.gradientStart,
                flexibleSpace: FlexibleSpaceBar(
                  background: FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.gradientStart,
                              widget.gradientEnd,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        widget.subjectIcon,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.subjectName,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.sectionType,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                // Favorite button in top-right corner (only if playlist ID exists)
                actions: widget.playlistId != null ? [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isLoadingFavorite
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _isPlaylistFavorited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isPlaylistFavorited ? Colors.red : Colors.white,
                              size: 24,
                            ),
                    ),
                    onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                    tooltip: languageBloc.currentLanguage == 'tr'
                        ? (_isPlaylistFavorited ? 'Favorilerden çıkar' : 'Favorilere ekle')
                        : (_isPlaylistFavorited ? 'Remove from favorites' : 'Add to favorites'),
                  ),
                ] : null,
              ),
              
              // Video Count Badge
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.gradientStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.gradientStart.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        color: widget.gradientStart,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_videos.length} ${languageBloc.currentLanguage == 'tr' ? 'video bulundu' : 'videos found'}',
                        style: TextStyle(
                          color: widget.gradientStart,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Loading or Video Grid
              _isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: SpinKitPulsingGrid(
                        color: widget.gradientStart,
                        size: 60.0,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // STRICT 2-column constraint
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75, // Aspect ratio for video cards
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildVideoCard(_videos[index], index);
                        },
                        childCount: _videos.length,
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoCard(Map<String, String> video, int index) {
    final videoId = video['videoId']!;
    // Check if this is TYT Matematik (the only exception to "Coming Soon")
    final bool isComingSoon = !_isTYTMatematik();
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 80)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animValue),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: isComingSoon 
                ? () => _showComingSoonMessage()
                : () => _openVideoPlayer(videoId, video['title']!),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientStart.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // YouTube Thumbnail with play overlay
                      Stack(
                        children: [
                          // Thumbnail image with fallback support
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _YouTubeThumbnailWithFallback(
                              videoId: videoId,
                              apiThumbnailUrl: video['thumbnailUrl'],
                              gradientStart: widget.gradientStart,
                            ),
                          ),
                          
                          // Play button overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Duration badge
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                video['duration']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          // "Coming Soon" overlay (except for TYT Matematik)
                          if (isComingSoon)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.7),
                                      Colors.black.withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Lock icon
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: widget.gradientStart.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: widget.gradientStart.withValues(alpha: 0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.lock_clock_rounded,
                                        color: widget.gradientStart.withValues(alpha: 0.9),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // "Yakında Sizlerle" text
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.gradientStart.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.gradientStart.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'YAKINDA SİZLERLE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      // Video info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                video['title']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const Spacer(),
                              
                              // Channel name
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_circle,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      video['channel']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
  
  /// Check if playlist is favorited
  Future<void> _checkFavoriteStatus() async {
    if (widget.playlistId == null) return;
    
    try {
      setState(() {
        _isLoadingFavorite = true;
      });
      
      final isFavorited = await _favoritesService.isPlaylistFavorited(
        playlistId: widget.playlistId!,
      );
      
      if (mounted) {
        setState(() {
          _isPlaylistFavorited = isFavorited;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking favorite status: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }
  
  /// Toggle favorite status
  Future<void> _toggleFavorite() async {
    if (widget.playlistId == null) return;
    
    final languageBloc = context.read<LanguageBloc>();
    
    try {
      setState(() {
        _isLoadingFavorite = true;
      });
      
      // Get instructor images for this playlist
      final instructorImages = _getInstructorImagesForPlaylist(
        widget.subjectKey,
        widget.subjectName,
      );
      
      final success = await _favoritesService.toggleFavoritePlaylist(
        playlistId: widget.playlistId!,
        playlistName: widget.subjectName,
        subjectKey: widget.subjectKey,
        sectionType: widget.sectionType,
        thumbnailUrl: _videos.isNotEmpty ? _videos[0]['thumbnailUrl'] : null,
        instructorImagePaths: instructorImages,
        videoCount: _videos.length,
      );
      
      if (success) {
        // Check new status
        final isFavorited = await _favoritesService.isPlaylistFavorited(
          playlistId: widget.playlistId!,
        );
        
        if (mounted) {
          setState(() {
            _isPlaylistFavorited = isFavorited;
            _isLoadingFavorite = false;
          });
          
          // Show snackbar feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isPlaylistFavorited
                    ? (languageBloc.currentLanguage == 'tr'
                        ? 'Playlist favorilere eklendi'
                        : 'Playlist added to favorites')
                    : (languageBloc.currentLanguage == 'tr'
                        ? 'Playlist favorilerden çıkarıldı'
                        : 'Playlist removed from favorites'),
              ),
              backgroundColor: _isPlaylistFavorited ? Colors.red[600] : Colors.grey[600],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingFavorite = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }
}

/// Widget that tries multiple YouTube thumbnail URLs in sequence
/// until one succeeds, with proper fallback handling
class _YouTubeThumbnailWithFallback extends StatefulWidget {
  final String videoId;
  final String? apiThumbnailUrl;
  final Color gradientStart;

  const _YouTubeThumbnailWithFallback({
    required this.videoId,
    this.apiThumbnailUrl,
    required this.gradientStart,
  });

  @override
  State<_YouTubeThumbnailWithFallback> createState() => _YouTubeThumbnailWithFallbackState();
}

class _YouTubeThumbnailWithFallbackState extends State<_YouTubeThumbnailWithFallback> {
  int _currentUrlIndex = 0;
  bool _hasError = false;
  
  List<String> get _thumbnailUrls {
    final urls = <String>[];
    
    // First try: API-provided thumbnail URL (most reliable)
    if (widget.apiThumbnailUrl != null && widget.apiThumbnailUrl!.isNotEmpty) {
      urls.add(widget.apiThumbnailUrl!);
    }
    
    // Second try: maxresdefault (highest quality)
    urls.add('https://img.youtube.com/vi/${widget.videoId}/maxresdefault.jpg');
    
    // Third try: hqdefault (high quality fallback)
    urls.add('https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg');
    
    // Fourth try: mqdefault (medium quality fallback)
    urls.add('https://img.youtube.com/vi/${widget.videoId}/mqdefault.jpg');
    
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _currentUrlIndex >= _thumbnailUrls.length - 1) {
      // All URLs failed, show placeholder
      return Container(
        color: Colors.grey[300],
        child: Icon(
          Icons.play_circle_outline,
          size: 40,
          color: Colors.grey[600],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: _thumbnailUrls[_currentUrlIndex],
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: Center(
          child: SpinKitFadingCircle(
            color: widget.gradientStart,
            size: 30.0,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        // Try next URL if available
        if (_currentUrlIndex < _thumbnailUrls.length - 1 && !_hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentUrlIndex++;
              });
            }
          });
          // Return placeholder while trying next URL
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: SpinKitFadingCircle(
                color: widget.gradientStart,
                size: 30.0,
              ),
            ),
          );
        } else {
          // All URLs exhausted, show error placeholder
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                });
              }
            });
          }
          return Container(
            color: Colors.grey[300],
            child: Icon(
              Icons.play_circle_outline,
              size: 40,
              color: Colors.grey[600],
            ),
          );
        }
      },
    );
  }
}

