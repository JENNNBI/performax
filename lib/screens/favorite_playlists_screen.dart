import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../models/favorite_playlist.dart';
import '../blocs/bloc_exports.dart';
import 'video_grid_screen.dart';

/// Screen to display all favorite playlists
class FavoritePlaylistsScreen extends StatefulWidget {
  static const String id = 'favorite_playlists_screen';
  
  const FavoritePlaylistsScreen({super.key});

  @override
  State<FavoritePlaylistsScreen> createState() => _FavoritePlaylistsScreenState();
}

class _FavoritePlaylistsScreenState extends State<FavoritePlaylistsScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  // Helper function to get gradient colors based on subject
  List<Color> _getGradientColors(String subjectKey) {
    final subjectLower = subjectKey.toLowerCase();
    if (subjectLower.contains('matematik')) {
      return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    } else if (subjectLower.contains('fizik')) {
      return [const Color(0xFFf093fb), const Color(0xFFf5576c)];
    } else if (subjectLower.contains('kimya')) {
      return [const Color(0xFF4facfe), const Color(0xFF00f2fe)];
    } else if (subjectLower.contains('biyoloji')) {
      return [const Color(0xFF43e97b), const Color(0xFF38f9d7)];
    } else if (subjectLower.contains('türkçe')) {
      return [const Color(0xFFfa709a), const Color(0xFFfee140)];
    }
    return [const Color(0xFF667eea), const Color(0xFF764ba2)];
  }
  
  /// Get instructor images for a playlist (if not already stored, detect dynamically)
  List<String> _getInstructorImagesForPlaylist(String subjectKey, String playlistName) {
    final subjectLower = subjectKey.toLowerCase();
    final playlistLower = playlistName.toLowerCase();
    
    // Problemler Kampı playlist uses both instructors
    final isMatematik = subjectLower.contains('matematik');
    final isProblemlerPlaylist = subjectLower.contains('problemler') ||
                                  playlistLower.contains('problemler') || 
                                  playlistLower.contains('problem') || 
                                  playlistLower.contains('kampi') || 
                                  playlistLower.contains('kamp');
    
    if (isMatematik && isProblemlerPlaylist) {
      return [
        'assets/hocalar/bunyamin_bayraktutar.png',
        'assets/hocalar/omer_faruk_cetinkaya.png',
      ];
    }
    
    return [];
  }

  // Helper function to get icon based on subject
  IconData _getSubjectIcon(String subjectKey) {
    final subjectLower = subjectKey.toLowerCase();
    if (subjectLower.contains('matematik')) return Icons.calculate_rounded;
    if (subjectLower.contains('fizik')) return Icons.science_rounded;
    if (subjectLower.contains('kimya')) return Icons.psychology_rounded;
    if (subjectLower.contains('biyoloji')) return Icons.eco_rounded;
    if (subjectLower.contains('türkçe')) return Icons.menu_book_rounded;
    return Icons.playlist_play_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final bool isEnglish = languageBloc.currentLanguage == 'en';
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: theme.primaryColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isEnglish ? 'Favorite Playlists' : 'Favori Playlistler',
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
          ),
          body: StreamBuilder<List<FavoritePlaylist>>(
            stream: _favoritesService.getFavoritePlaylists(),
            builder: (context, snapshot) {
              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.none) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        isEnglish ? 'Loading favorite playlists...' : 'Favori playlistler yükleniyor...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Handle errors
              if (snapshot.hasError) {
                debugPrint('❌ StreamBuilder error: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEnglish ? 'Error loading playlists' : 'Playlistler yüklenirken hata oluştu',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Handle empty state
              final playlists = snapshot.data ?? [];
              if (playlists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play_rounded,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isEnglish ? 'No favorite playlists yet' : 'Henüz favori playlist yok',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEnglish 
                          ? 'Add playlists to favorites to see them here'
                          : 'Favorilere eklediğiniz playlistler burada görünecek',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              // Display playlists in a grid
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final gradientColors = _getGradientColors(playlist.subjectKey);
                  final subjectIcon = _getSubjectIcon(playlist.subjectKey);
                  
                  // Debug logging for each playlist
                  debugPrint('📋 Rendering playlist card:');
                  debugPrint('   Name: ${playlist.playlistName}');
                  debugPrint('   Subject: ${playlist.subjectKey}');
                  debugPrint('   Instructor paths (stored): ${playlist.instructorImagePaths}');
                  debugPrint('   Path count (stored): ${playlist.instructorImagePaths.length}');
                  
                  // Get instructor images - use stored ones if available, otherwise detect dynamically
                  List<String> instructorImages = playlist.instructorImagePaths;
                  if (instructorImages.isEmpty) {
                    // Try to detect instructor images dynamically for existing playlists
                    instructorImages = _getInstructorImagesForPlaylist(
                      playlist.subjectKey,
                      playlist.playlistName,
                    );
                    debugPrint('   Instructor paths (detected): $instructorImages');
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // Navigate to video grid screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoGridScreen(
                                subjectKey: playlist.subjectKey,
                                subjectName: playlist.playlistName,
                                sectionType: playlist.sectionType,
                                gradientStart: gradientColors[0],
                                gradientEnd: gradientColors[1],
                                subjectIcon: subjectIcon,
                                playlistId: playlist.playlistId,
                                usePlaylistData: true,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Instructor images or fallback icon
                              _buildInstructorImagesWidget(
                                instructorImages,
                                subjectIcon,
                                gradientColors,
                              ),
                              const SizedBox(width: 16),
                              // Playlist info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlist.playlistName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      playlist.sectionType,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          size: 16,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${playlist.videoCount} ${isEnglish ? 'videos' : 'video'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow icon
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
  
  /// Build instructor images widget - displays multiple instructors or fallback icon
  Widget _buildInstructorImagesWidget(
    List<String> instructorImagePaths,
    IconData fallbackIcon,
    List<Color> gradientColors,
  ) {
    // Debug logging
    debugPrint('🖼️ Building instructor images widget:');
    debugPrint('   Paths: $instructorImagePaths');
    debugPrint('   Count: ${instructorImagePaths.length}');
    
    // If we have instructor images, display them
    if (instructorImagePaths.isNotEmpty) {
      // Display up to 2 instructors side by side
      final displayImages = instructorImagePaths.take(2).toList();
      
      if (displayImages.length == 1) {
        // Single instructor
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              displayImages[0],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Failed to load instructor image: ${displayImages[0]}');
                debugPrint('   Error: $error');
                return Container(
                  color: Colors.white.withValues(alpha: 0.1),
                  child: Icon(
                    fallbackIcon,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
        );
      } else {
        // Multiple instructors - stack them with overlap
        return SizedBox(
          width: 72,
          height: 64,
          child: Stack(
            children: [
              // First instructor (back)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      displayImages[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Failed to load instructor image (1st): ${displayImages[0]}');
                        debugPrint('   Error: $error');
                        return Container(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: Icon(
                            fallbackIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Second instructor (front, overlapping)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      displayImages[1],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Failed to load instructor image (2nd): ${displayImages[1]}');
                        debugPrint('   Error: $error');
                        return Container(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: Icon(
                            fallbackIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    
    // Fallback to subject icon if no instructor images
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        fallbackIcon,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}

