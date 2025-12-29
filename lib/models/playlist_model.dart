/// Playlist Model for YouTube Playlists
/// Used for organizing video content by playlists
class PlaylistModel {
  final String title;
  final String? channelName; // Dynamically fetched from YouTube API
  final String playlistId;
  final String? description;
  final String? thumbnailUrl;
  final String? bannerUrl; // Channel banner image URL for card background
  final String? channelLogoUrl; // Channel logo/avatar URL for card background

  const PlaylistModel({
    required this.title,
    this.channelName, // Optional - will be populated from API
    required this.playlistId,
    this.description,
    this.thumbnailUrl,
    this.bannerUrl,
    this.channelLogoUrl,
  });
  
  /// Create a copy with updated channel name
  PlaylistModel copyWith({
    String? title,
    String? channelName,
    String? playlistId,
    String? description,
    String? thumbnailUrl,
    String? bannerUrl,
    String? channelLogoUrl,
  }) {
    return PlaylistModel(
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      playlistId: playlistId ?? this.playlistId,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      channelLogoUrl: channelLogoUrl ?? this.channelLogoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'channelName': channelName,
    'playlistId': playlistId,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'bannerUrl': bannerUrl,
    'channelLogoUrl': channelLogoUrl,
  };

  factory PlaylistModel.fromJson(Map<String, dynamic> json) => PlaylistModel(
    title: json['title'] as String,
    channelName: json['channelName'] as String?,
    playlistId: json['playlistId'] as String,
    description: json['description'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    bannerUrl: json['bannerUrl'] as String?,
    channelLogoUrl: json['channelLogoUrl'] as String?,
  );
}
