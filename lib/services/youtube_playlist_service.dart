import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// YouTube Playlist Service
/// Fetches videos from a specific YouTube playlist using YouTube Data API v3
/// 
/// Uses provided API key for authentication
class YouTubePlaylistService {
  // ✅ VALID API KEY PROVIDED BY USER
  static const String _apiKey = 'AIzaSyDsm__BMkPjXGIPgixuGLPPTvzre0lDagc';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  /// Hardcoded duration map for Problemler Kampı playlist
  /// These durations are used as fallback when API fails or as primary source
  static const Map<String, String> _hardcodedDurations = {
    'rU_HpnKjYlw': '19:26',
    'YYL-WVxxVS4': '22:25',
    'RFpJXfWZqM4': '17:15',
    'XXn5s-b6Bzc': '22:01',
    '1hI8r1SXu8M': '18:18',
    'Trx7LVt1ChE': '20:20',
    'uJvmpFSNHP0': '20:47',
    'T43XIUbZWL4': '23:14',
    'XoU_rclORrQ': '22:15',
    'i1strLhLNZc': '25:12',
    'RMgeWRIOXLU': '24:34',
    '_f77hHW3z7c': '20:46',
    'unbLErAwQnA': '22:42',
    'xAVKN_K2waI': '24:02',
    'YAaydskuLCc': '16:47',
    'nX5fEaS5O-A': '17:42',
    'SW1NV3MXNyw': '20:23',
    'lZQ1XJAqbT0': '18:41',
    'YEqjj3jWRc0': '23:22',
    'WTvx2BkL9E8': '22:04',
    'Fbu85Xic80c': '19:35',
  };
  
  /// Get hardcoded duration for a video ID if available
  static String? getHardcodedDuration(String videoId) {
    return _hardcodedDurations[videoId];
  }
  
  /// Get API key (using hardcoded valid key)
  static String get _getApiKey {
    return _apiKey;
  }
  
  /// Safely extract thumbnail URL from YouTube API response
  /// Falls back through quality levels: maxres -> high -> medium -> default
  /// Returns empty string if no thumbnail is available
  String? _getThumbnailUrl(Map<String, dynamic>? thumbnails) {
    if (thumbnails == null) return null;
    
    // Try maxres first (highest quality)
    if (thumbnails['maxres'] != null && thumbnails['maxres']['url'] != null) {
      return thumbnails['maxres']['url'] as String;
    }
    
    // Fallback to high
    if (thumbnails['high'] != null && thumbnails['high']['url'] != null) {
      return thumbnails['high']['url'] as String;
    }
    
    // Fallback to medium
    if (thumbnails['medium'] != null && thumbnails['medium']['url'] != null) {
      return thumbnails['medium']['url'] as String;
    }
    
    // Fallback to default (always exists)
    if (thumbnails['default'] != null && thumbnails['default']['url'] != null) {
      return thumbnails['default']['url'] as String;
    }
    
    // If all fail, return null (caller should handle this)
    return null;
  }
  
  /// Fetch playlist metadata (title, channel name, description)
  /// Returns playlist information including channel name from YouTube API
  Future<Map<String, dynamic>?> fetchPlaylistMetadata(String playlistId) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 YouTube API: Fetching playlist metadata');
      debugPrint('   Playlist ID: $playlistId');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final url = Uri.parse(
        '$_baseUrl/playlists?part=snippet&id=$playlistId&key=$_apiKey'
      );
      
      debugPrint('DEBUG: Requesting Playlist Metadata URL -> $url');
      
      final response = await http.get(url);
      
      debugPrint('DEBUG: Playlist Metadata Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        
        if (items.isNotEmpty) {
          final snippet = items[0]['snippet'];
          final metadata = {
            'title': snippet['title'] ?? '',
            'channelTitle': snippet['channelTitle'] ?? '',
            'description': snippet['description'] ?? '',
            'thumbnailUrl': _getThumbnailUrl(snippet['thumbnails'] as Map<String, dynamic>?),
          };
          
          debugPrint('✅ Successfully fetched playlist metadata');
          debugPrint('   Title: ${metadata['title']}');
          debugPrint('   Channel: ${metadata['channelTitle']}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return metadata;
        }
      } else {
        debugPrint('❌ Playlist Metadata API ERROR: ${response.statusCode}');
        debugPrint('API ERROR Response Body: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ NETWORK EXCEPTION (Playlist Metadata): $e');
      debugPrint('Stack trace: $stackTrace');
    }
    return null;
  }

  /// Fetch all videos from a playlist
  /// Returns list of video data including: id, title, thumbnail, duration
  Future<List<Map<String, dynamic>>> fetchPlaylistVideos(String playlistId) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🎬 YouTube API: Fetching playlist videos');
      debugPrint('   Playlist ID: $playlistId');
      debugPrint('   API Key: ${_apiKey.substring(0, 10)}...');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final List<Map<String, dynamic>> videos = [];
      String? nextPageToken;
      
      // Fetch all pages (YouTube returns max 50 items per page)
      do {
        final url = Uri.parse(
          '$_baseUrl/playlistItems?part=snippet,contentDetails&maxResults=50&playlistId=$playlistId&key=$_apiKey${nextPageToken != null ? '&pageToken=$nextPageToken' : ''}'
        );
        
        debugPrint('DEBUG: Requesting URL -> $url');
        
        final response = await http.get(url);
        
        debugPrint('DEBUG: Status Code: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List<dynamic>;
          
          debugPrint('DEBUG: Found ${items.length} videos in this page');
          
          for (var item in items) {
            try {
              final snippet = item['snippet'] as Map<String, dynamic>?;
              if (snippet == null) {
                debugPrint('⚠️ Skipping item with null snippet');
                continue;
              }
              
              // Safely extract videoId
              final resourceId = snippet['resourceId'] as Map<String, dynamic>?;
              if (resourceId == null || resourceId['videoId'] == null) {
                debugPrint('⚠️ Skipping item with null resourceId or videoId');
                continue;
              }
              
              final videoId = resourceId['videoId'] as String;
              
              // Safely extract thumbnail
              final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
              final thumbnailUrl = _getThumbnailUrl(thumbnails);
              
              // If no thumbnail found, skip this video or use placeholder
              if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
                debugPrint('⚠️ Video $videoId has no thumbnail, using placeholder');
              }
              
              videos.add({
                'videoId': videoId,
                'title': snippet['title'] ?? 'Untitled Video',
                'description': snippet['description'] ?? '',
                'thumbnailUrl': thumbnailUrl ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                'thumbnailUrlMax': thumbnailUrl ?? 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                'channelTitle': snippet['channelTitle'] ?? snippet['videoOwnerChannelTitle'] ?? 'Unknown Channel',
                'publishedAt': snippet['publishedAt'] ?? '',
                'position': snippet['position'] ?? 0,
              });
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing video item: $e');
              debugPrint('Stack trace: $stackTrace');
              // Continue processing other videos instead of crashing
              continue;
            }
          }
          
          nextPageToken = data['nextPageToken'];
          if (nextPageToken != null) {
            debugPrint('DEBUG: More pages available, fetching next page...');
          }
        } else {
          debugPrint('❌ API ERROR: ${response.statusCode}');
          debugPrint('API ERROR Response Body: ${response.body}');
          throw Exception('API Error: ${response.statusCode} - ${response.body}');
        }
      } while (nextPageToken != null);
      
      debugPrint('✅ Successfully fetched ${videos.length} videos from playlist: $playlistId');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return videos;
      
    } catch (e, stackTrace) {
      debugPrint('❌ NETWORK EXCEPTION: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // Re-throw to allow UI to handle error
    }
  }
  
  /// Get video duration for a specific video
  /// Note: Requires separate API call as duration is not in playlist items
  Future<String?> getVideoDuration(String videoId) async {
    try {
      final apiKey = _getApiKey;
      if (apiKey.isEmpty) {
        return null;
      }
      
      final url = Uri.parse(
        '$_baseUrl/videos?part=contentDetails&id=$videoId&key=$apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        
        if (items.isNotEmpty) {
          final contentDetails = items[0]['contentDetails'] as Map<String, dynamic>?;
          if (contentDetails != null && contentDetails['duration'] != null) {
            final duration = contentDetails['duration'] as String;
            return _parseDuration(duration);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching video duration: $e');
    }
    return null;
  }
  
  /// Batch fetch video durations for multiple videos (more efficient)
  /// YouTube API allows up to 50 video IDs per request
  /// Uses hardcoded durations as fallback when available
  Future<Map<String, String>> getVideoDurationsBatch(List<String> videoIds) async {
    final Map<String, String> durationMap = {};
    
    // First, populate with hardcoded durations where available
    for (final videoId in videoIds) {
      final hardcodedDuration = getHardcodedDuration(videoId);
      if (hardcodedDuration != null) {
        durationMap[videoId] = hardcodedDuration;
      }
    }
    
    // Find video IDs that don't have hardcoded durations
    final missingVideoIds = videoIds.where((id) => !durationMap.containsKey(id)).toList();
    
    // If all videos have hardcoded durations, return early
    if (missingVideoIds.isEmpty) {
      debugPrint('✅ Using hardcoded durations for all ${videoIds.length} videos');
      return durationMap;
    }
    
    // Fetch missing durations from API
    try {
      final apiKey = _getApiKey;
      if (apiKey.isEmpty) {
        debugPrint('⚠️ YouTube API key not configured, using hardcoded durations only');
        debugPrint('⚠️ Missing durations for ${missingVideoIds.length} videos');
        return durationMap;
      }
      
      // Process in batches of 50 (YouTube API limit)
      for (int i = 0; i < missingVideoIds.length; i += 50) {
        final batch = missingVideoIds.skip(i).take(50).toList();
        final videoIdsParam = batch.join(',');
        
        final url = Uri.parse(
          '$_baseUrl/videos?part=contentDetails&id=$videoIdsParam&key=$apiKey'
        );
        
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List<dynamic>;
          
          for (var item in items) {
            try {
              final videoId = item['id'] as String?;
              if (videoId == null) continue;
              
              final contentDetails = item['contentDetails'] as Map<String, dynamic>?;
              if (contentDetails == null || contentDetails['duration'] == null) continue;
              
              final duration = contentDetails['duration'] as String;
              durationMap[videoId] = _parseDuration(duration);
            } catch (e) {
              debugPrint('⚠️ Error parsing duration for video: $e');
              continue;
            }
          }
        } else {
          debugPrint('❌ Error fetching video durations batch: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
      }
      
      debugPrint('✅ Fetched durations: ${durationMap.length - (videoIds.length - missingVideoIds.length)} from API, ${videoIds.length - missingVideoIds.length} from hardcoded map');
      return durationMap;
    } catch (e) {
      debugPrint('❌ Error fetching video durations batch: $e');
      debugPrint('⚠️ Falling back to hardcoded durations where available');
      return durationMap;
    }
  }
  
  /// Fetch comments for a specific video
  /// Returns list of comment data including: author, text, likeCount, publishedAt
  Future<List<Map<String, dynamic>>> fetchComments(String videoId) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💬 YouTube API: Fetching comments');
      debugPrint('   Video ID: $videoId');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final url = Uri.parse(
        '$_baseUrl/commentThreads?part=snippet&videoId=$videoId&maxResults=20&order=relevance&key=$_apiKey'
      );
      
      debugPrint('DEBUG: Requesting Comments URL -> $url');
      
      final response = await http.get(url);
      
      debugPrint('DEBUG: Comments Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        
        debugPrint('DEBUG: Found ${items.length} comments');
        
        final comments = items.map((item) {
          try {
            final snippet = item['snippet'] as Map<String, dynamic>?;
            if (snippet == null) return null;
            
            final topLevelComment = snippet['topLevelComment'] as Map<String, dynamic>?;
            if (topLevelComment == null) return null;
            
            final commentSnippet = topLevelComment['snippet'] as Map<String, dynamic>?;
            if (commentSnippet == null) return null;
            
            return {
              'author': commentSnippet['authorDisplayName'] ?? 'Anonymous',
              'text': commentSnippet['textDisplay'] ?? '',
              'likeCount': commentSnippet['likeCount'] ?? 0,
              'publishedAt': commentSnippet['publishedAt'] ?? '',
              'authorProfileImageUrl': commentSnippet['authorProfileImageUrl'] ?? '',
            };
          } catch (e) {
            debugPrint('⚠️ Error parsing comment: $e');
            return null;
          }
        }).whereType<Map<String, dynamic>>().toList(); // Filter out nulls
        
        debugPrint('✅ Successfully fetched ${comments.length} comments');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return comments;
      } else {
        debugPrint('❌ Comments API ERROR: ${response.statusCode}');
        debugPrint('Comments API Response Body: ${response.body}');
        // Return empty list instead of throwing - comments are optional
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('❌ NETWORK EXCEPTION (Comments): $e');
      debugPrint('Stack trace: $stackTrace');
      // Return empty list instead of throwing - comments are optional
      return [];
    }
  }

  /// Parse ISO 8601 duration (e.g., PT15M30S) to readable format (15:30)
  String _parseDuration(String isoDuration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);
    
    if (match != null) {
      final hours = match.group(1) != null ? int.parse(match.group(1)!) : 0;
      final minutes = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final seconds = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      
      if (hours > 0) {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    }
    
    return '0:00';
  }
  
  /// Fallback: Use dummy data if API is not configured
  /// This ensures app doesn't break without API key
  List<Map<String, dynamic>> getDummyPlaylistVideos(String playlistId) {
    debugPrint('⚠️ Using dummy data for playlist: $playlistId');
    debugPrint('⚠️ YouTube API key not configured');
    
    // Official TYT Matematik video sequence
    const videoSequence = [
      'rU_HpnKjYlw', 'YYL-WVxxVS4', 'RFpJXfWZqM4', 'XXn5s-b6Bzc', 
      '1hI8r1SXu8M', 'Trx7LVt1ChE', 'uJvmpFSNHP0', 'T43XIUbZWL4',
      'XoU_rclORrQ', 'i1strLhLNZc', 'RMgeWRIOXLU', '_f77hHW3z7c',
      'unbLErAwQnA', 'xAVKN_K2waI', 'YAaydskuLCc', 'nX5fEaS5O-A',
      'SW1NV3MXNyw', 'lZQ1XJAqbT0', 'YEqjj3jWRc0', 'WTvx2BkL9E8',
      'Fbu85Xic80c',
    ];
    
    return List.generate(videoSequence.length, (index) => {
      'videoId': videoSequence[index],
      'title': 'TYT Matematik - Ders ${index + 1}',
      'description': 'TYT Matematik konu anlatımı',
      'thumbnailUrl': 'https://img.youtube.com/vi/${videoSequence[index]}/hqdefault.jpg',
      'thumbnailUrlMax': 'https://img.youtube.com/vi/${videoSequence[index]}/maxresdefault.jpg',
      'channelTitle': 'Performax Matematik',
      'publishedAt': DateTime.now().toIso8601String(),
      'position': index,
    });
  }
}

// debugPrint is already available from Flutter, no need to redefine

