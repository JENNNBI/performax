import 'package:equatable/equatable.dart';

/// Represents different types of PDF resources
enum PDFResourceType {
  textbook,
  workbook,
  exam,
  practice,
  reference,
  other,
}

/// Model for PDF resources like textbooks
class PDFResource extends Equatable {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String grade;
  final PDFResourceType type;
  final String url;
  final String? thumbnailUrl;
  final int? totalPages;
  final String? author;
  final String? publisher;
  final DateTime? publishDate;
  final Map<String, dynamic>? metadata;
  final bool isInteractive;
  final bool isOfflineAvailable;

  const PDFResource({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.grade,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.totalPages,
    this.author,
    this.publisher,
    this.publishDate,
    this.metadata,
    this.isInteractive = true,
    this.isOfflineAvailable = false,
  });

  /// Create PDFResource from JSON
  factory PDFResource.fromJson(Map<String, dynamic> json) {
    return PDFResource(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      subject: json['subject'] as String,
      grade: json['grade'] as String,
      type: PDFResourceType.values.firstWhere(
        (e) => e.toString() == 'PDFResourceType.${json['type']}',
        orElse: () => PDFResourceType.other,
      ),
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      totalPages: json['totalPages'] as int?,
      author: json['author'] as String?,
      publisher: json['publisher'] as String?,
      publishDate: json['publishDate'] != null 
          ? DateTime.parse(json['publishDate'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isInteractive: json['isInteractive'] as bool? ?? true,
      isOfflineAvailable: json['isOfflineAvailable'] as bool? ?? false,
    );
  }

  /// Convert PDFResource to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'grade': grade,
      'type': type.toString().split('.').last,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'totalPages': totalPages,
      'author': author,
      'publisher': publisher,
      'publishDate': publishDate?.toIso8601String(),
      'metadata': metadata,
      'isInteractive': isInteractive,
      'isOfflineAvailable': isOfflineAvailable,
    };
  }

  /// Create PDFResource for Biology 9th Grade textbook
  factory PDFResource.biology9thGrade() {
    return const PDFResource(
      id: 'biology_9th_grade',
      title: 'Biology 9th Grade Textbook',
      description: 'Interactive digital flipbook for 9th Grade Biology',
      subject: 'Biology',
      grade: '9',
      type: PDFResourceType.textbook,
      url: 'https://fliphtml5.com/bookcase/hxqgs',
      totalPages: 200,
      author: 'Ministry of Education',
      publisher: 'Educational Publishing',
      isInteractive: true,
      isOfflineAvailable: false,
      metadata: {
        'flipbook': true,
        'swipeNavigation': true,
        'zoomEnabled': true,
        'fullscreen': true,
      },
    );
  }

  /// Create PDFResource for a generic textbook
  factory PDFResource.textbook({
    required String id,
    required String title,
    required String subject,
    required String grade,
    required String url,
    String? description,
    String? thumbnailUrl,
    int? totalPages,
    String? author,
    String? publisher,
    Map<String, dynamic>? metadata,
  }) {
    return PDFResource(
      id: id,
      title: title,
      description: description ?? 'Interactive digital textbook',
      subject: subject,
      grade: grade,
      type: PDFResourceType.textbook,
      url: url,
      thumbnailUrl: thumbnailUrl,
      totalPages: totalPages,
      author: author,
      publisher: publisher,
      isInteractive: true,
      isOfflineAvailable: false,
      metadata: metadata,
    );
  }

  /// Get display name for the resource
  String get displayName => '$subject $grade - $title';

  /// Get short description
  String get shortDescription {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }

  /// Check if this is a flipbook resource
  bool get isFlipbook => metadata?['flipbook'] == true;

  /// Check if swipe navigation is enabled
  bool get hasSwipeNavigation => metadata?['swipeNavigation'] == true;

  /// Check if zoom is enabled
  bool get hasZoom => metadata?['zoomEnabled'] == true;

  /// Check if fullscreen is supported
  bool get supportsFullscreen => metadata?['fullscreen'] == true;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        subject,
        grade,
        type,
        url,
        thumbnailUrl,
        totalPages,
        author,
        publisher,
        publishDate,
        metadata,
        isInteractive,
        isOfflineAvailable,
      ];
}
