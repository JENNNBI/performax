/// Model for favorite playlists
class FavoritePlaylist {
  final String id;
  final String userId;
  final String playlistId;
  final String playlistName;
  final String subjectKey;
  final String sectionType;
  final String? thumbnailUrl;
  final List<String> instructorImagePaths; // List of instructor image asset paths
  final int videoCount;
  final DateTime createdAt;

  FavoritePlaylist({
    required this.id,
    required this.userId,
    required this.playlistId,
    required this.playlistName,
    required this.subjectKey,
    required this.sectionType,
    this.thumbnailUrl,
    this.instructorImagePaths = const [], // Default to empty list
    required this.videoCount,
    required this.createdAt,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'playlistId': playlistId,
      'playlistName': playlistName,
      'subjectKey': subjectKey,
      'sectionType': sectionType,
      'thumbnailUrl': thumbnailUrl,
      'instructorImagePaths': instructorImagePaths,
      'videoCount': videoCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firebase document
  factory FavoritePlaylist.fromMap(Map<String, dynamic> map) {
    return FavoritePlaylist(
      id: map['id'] as String,
      userId: map['userId'] as String,
      playlistId: map['playlistId'] as String,
      playlistName: map['playlistName'] as String,
      subjectKey: map['subjectKey'] as String,
      sectionType: map['sectionType'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      instructorImagePaths: map['instructorImagePaths'] != null
          ? List<String>.from(map['instructorImagePaths'] as List)
          : const [],
      videoCount: map['videoCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Copy with method for updates
  FavoritePlaylist copyWith({
    String? id,
    String? userId,
    String? playlistId,
    String? playlistName,
    String? subjectKey,
    String? sectionType,
    String? thumbnailUrl,
    List<String>? instructorImagePaths,
    int? videoCount,
    DateTime? createdAt,
  }) {
    return FavoritePlaylist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      playlistId: playlistId ?? this.playlistId,
      playlistName: playlistName ?? this.playlistName,
      subjectKey: subjectKey ?? this.subjectKey,
      sectionType: sectionType ?? this.sectionType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructorImagePaths: instructorImagePaths ?? this.instructorImagePaths,
      videoCount: videoCount ?? this.videoCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

