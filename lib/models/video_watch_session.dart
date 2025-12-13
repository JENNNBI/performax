/// Video Watch Session Model
/// 
/// Tracks comprehensive data about a video watching session including:
/// - Branch (subject): e.g., "MATEMATİK"
/// - Grade Level: e.g., "TYT", "9", "10", "11"
/// - Time spent watching (accounting for pauses)
/// - Session metadata
class VideoWatchSession {
  final String branch;           // e.g., "MATEMATİK", "FİZİK"
  final String gradeLevel;       // e.g., "TYT", "AYT", "9", "10", "11"
  final String videoId;
  final String videoTitle;
  final DateTime sessionStart;
  
  DateTime? sessionEnd;
  int totalWatchTimeSeconds;     // Total accumulated watch time
  bool isActive;                 // Is session currently active
  DateTime? currentSegmentStart; // When current play segment started
  
  VideoWatchSession({
    required this.branch,
    required this.gradeLevel,
    required this.videoId,
    required this.videoTitle,
    required this.sessionStart,
    this.sessionEnd,
    this.totalWatchTimeSeconds = 0,
    this.isActive = false,
    this.currentSegmentStart,
  });
  
  /// Start playing (or resume)
  void startPlaying() {
    if (!isActive) {
      isActive = true;
      currentSegmentStart = DateTime.now();
    }
  }
  
  /// Pause or stop playing
  void stopPlaying() {
    if (isActive && currentSegmentStart != null) {
      final elapsed = DateTime.now().difference(currentSegmentStart!).inSeconds;
      totalWatchTimeSeconds += elapsed;
      isActive = false;
      currentSegmentStart = null;
    }
  }
  
  /// Finalize session (call on exit)
  void endSession() {
    stopPlaying(); // Stop any active playback
    sessionEnd = DateTime.now();
  }
  
  /// Get formatted metric: BRANCH-GRADELEVEL-SECONDS
  String getMetricFormat() {
    return '$branch-$gradeLevel-$totalWatchTimeSeconds saniye';
  }
  
  /// Get total session duration (start to end)
  int getTotalSessionDuration() {
    if (sessionEnd == null) return 0;
    return sessionEnd!.difference(sessionStart).inSeconds;
  }
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'branch': branch,
      'gradeLevel': gradeLevel,
      'videoId': videoId,
      'videoTitle': videoTitle,
      'sessionStart': sessionStart.toIso8601String(),
      'sessionEnd': sessionEnd?.toIso8601String(),
      'totalWatchTimeSeconds': totalWatchTimeSeconds,
      'isActive': isActive,
    };
  }
  
  /// Create from map
  factory VideoWatchSession.fromMap(Map<String, dynamic> map) {
    return VideoWatchSession(
      branch: map['branch'] as String,
      gradeLevel: map['gradeLevel'] as String,
      videoId: map['videoId'] as String,
      videoTitle: map['videoTitle'] as String,
      sessionStart: DateTime.parse(map['sessionStart'] as String),
      sessionEnd: map['sessionEnd'] != null 
          ? DateTime.parse(map['sessionEnd'] as String)
          : null,
      totalWatchTimeSeconds: map['totalWatchTimeSeconds'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? false,
    );
  }
  
  @override
  String toString() {
    return 'VideoWatchSession(branch: $branch, gradeLevel: $gradeLevel, '
           'watchTime: ${totalWatchTimeSeconds}s, metric: ${getMetricFormat()})';
  }
}

