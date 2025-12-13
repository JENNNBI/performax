/// Model for favorite questions
class FavoriteQuestion {
  final String id;
  final String userId;
  final int questionNumber;
  final String imagePath;
  final String testName;
  final String? userAnswer;
  final String? correctAnswer;
  final DateTime createdAt;
  final String? notes;

  FavoriteQuestion({
    required this.id,
    required this.userId,
    required this.questionNumber,
    required this.imagePath,
    required this.testName,
    this.userAnswer,
    this.correctAnswer,
    required this.createdAt,
    this.notes,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'questionNumber': questionNumber,
      'imagePath': imagePath,
      'testName': testName,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from Firebase document
  factory FavoriteQuestion.fromMap(Map<String, dynamic> map) {
    return FavoriteQuestion(
      id: map['id'] as String,
      userId: map['userId'] as String,
      questionNumber: map['questionNumber'] as int,
      imagePath: map['imagePath'] as String,
      testName: map['testName'] as String,
      userAnswer: map['userAnswer'] as String?,
      correctAnswer: map['correctAnswer'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      notes: map['notes'] as String?,
    );
  }

  // Copy with method for updates
  FavoriteQuestion copyWith({
    String? id,
    String? userId,
    int? questionNumber,
    String? imagePath,
    String? testName,
    String? userAnswer,
    String? correctAnswer,
    DateTime? createdAt,
    String? notes,
  }) {
    return FavoriteQuestion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionNumber: questionNumber ?? this.questionNumber,
      imagePath: imagePath ?? this.imagePath,
      testName: testName ?? this.testName,
      userAnswer: userAnswer ?? this.userAnswer,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

