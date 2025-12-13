/// Model for favorite books
class FavoriteBook {
  final String id;
  final String userId;
  final String testSeriesTitle;
  final String subject;
  final String grade;
  final String testSeriesKey;
  final String coverImagePath;
  final DateTime createdAt;

  FavoriteBook({
    required this.id,
    required this.userId,
    required this.testSeriesTitle,
    required this.subject,
    required this.grade,
    required this.testSeriesKey,
    required this.coverImagePath,
    required this.createdAt,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'testSeriesTitle': testSeriesTitle,
      'subject': subject,
      'grade': grade,
      'testSeriesKey': testSeriesKey,
      'coverImagePath': coverImagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firebase document
  factory FavoriteBook.fromMap(Map<String, dynamic> map) {
    return FavoriteBook(
      id: map['id'] as String,
      userId: map['userId'] as String,
      testSeriesTitle: map['testSeriesTitle'] as String,
      subject: map['subject'] as String,
      grade: map['grade'] as String,
      testSeriesKey: map['testSeriesKey'] as String,
      coverImagePath: map['coverImagePath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Copy with method for updates
  FavoriteBook copyWith({
    String? id,
    String? userId,
    String? testSeriesTitle,
    String? subject,
    String? grade,
    String? testSeriesKey,
    String? coverImagePath,
    DateTime? createdAt,
  }) {
    return FavoriteBook(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testSeriesTitle: testSeriesTitle ?? this.testSeriesTitle,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      testSeriesKey: testSeriesKey ?? this.testSeriesKey,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

