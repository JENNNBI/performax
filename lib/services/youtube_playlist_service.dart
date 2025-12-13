import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// YouTube Playlist Service
/// Fetches videos from a specific YouTube playlist using YouTube Data API v3
/// 
/// Required: YouTube Data API key in .env file
class YouTubePlaylistService {
  static String? _apiKey;
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
  
  /// Get API key from environment variables, with fallback
  static String get _getApiKey {
    _apiKey ??= dotenv.env['YOUTUBE_API_KEY'] ?? '';
    if (_apiKey!.isEmpty || _apiKey == 'YOUR_YOUTUBE_API_KEY_HERE') {
      debugPrint('⚠️ YouTube API key not configured in .env file');
      return '';
    }
    return _apiKey!;
  }
  
  /// Fetch all videos from a playlist
  /// Returns list of video data including: id, title, thumbnail, duration
  Future<List<Map<String, dynamic>>> fetchPlaylistVideos(String playlistId) async {
    try {
      final List<Map<String, dynamic>> videos = [];
      String? nextPageToken;
      
      // Fetch all pages (YouTube returns max 50 items per page)
      do {
        final apiKey = _getApiKey;
        if (apiKey.isEmpty) {
          debugPrint('⚠️ YouTube API key not configured, returning empty list');
          return [];
        }
        
        final url = Uri.parse(
          '$_baseUrl/playlistItems?part=snippet&maxResults=50&playlistId=$playlistId&key=$apiKey${nextPageToken != null ? '&pageToken=$nextPageToken' : ''}'
        );
        
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List<dynamic>;
          
          for (var item in items) {
            final snippet = item['snippet'];
            final videoId = snippet['resourceId']['videoId'];
            
            videos.add({
              'videoId': videoId,
              'title': snippet['title'],
              'description': snippet['description'],
              'thumbnailUrl': snippet['thumbnails']['high']['url'],
              'thumbnailUrlMax': snippet['thumbnails']['maxres']?['url'] ?? snippet['thumbnails']['high']['url'],
              'channelTitle': snippet['channelTitle'],
              'publishedAt': snippet['publishedAt'],
              'position': snippet['position'],
            });
          }
          
          nextPageToken = data['nextPageToken'];
        } else {
          debugPrint('❌ YouTube API Error: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
          break;
        }
      } while (nextPageToken != null);
      
      debugPrint('✅ Fetched ${videos.length} videos from playlist: $playlistId');
      return videos;
      
    } catch (e) {
      debugPrint('❌ Error fetching playlist videos: $e');
      return [];
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
          final duration = items[0]['contentDetails']['duration'];
          return _parseDuration(duration);
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
            final videoId = item['id'] as String;
            final duration = item['contentDetails']['duration'] as String;
            durationMap[videoId] = _parseDuration(duration);
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

