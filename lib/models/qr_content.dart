import 'package:equatable/equatable.dart';

/// Represents different types of content that can be embedded in QR codes
enum QRContentType {
  video,
  subject,
  exam,
  practice,
  url,
  text,
  unknown,
}

/// Model for QR code content with embedded actions
class QRContent extends Equatable {
  final String id;
  final QRContentType type;
  final String title;
  final String? description;
  final String? videoId;
  final String? subjectName;
  final String? sectionType;
  final String? url;
  final String? text;
  final Map<String, dynamic>? metadata;

  const QRContent({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.videoId,
    this.subjectName,
    this.sectionType,
    this.url,
    this.text,
    this.metadata,
  });

  /// Create QRContent from JSON
  factory QRContent.fromJson(Map<String, dynamic> json) {
    return QRContent(
      id: json['id'] as String,
      type: QRContentType.values.firstWhere(
        (e) => e.toString() == 'QRContentType.${json['type']}',
        orElse: () => QRContentType.unknown,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      videoId: json['videoId'] as String?,
      subjectName: json['subjectName'] as String?,
      sectionType: json['sectionType'] as String?,
      url: json['url'] as String?,
      text: json['text'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert QRContent to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'videoId': videoId,
      'subjectName': subjectName,
      'sectionType': sectionType,
      'url': url,
      'text': text,
      'metadata': metadata,
    };
  }

  /// Create QRContent for video content
  factory QRContent.video({
    required String id,
    required String title,
    required String videoId,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return QRContent(
      id: id,
      type: QRContentType.video,
      title: title,
      description: description,
      videoId: videoId,
      metadata: metadata,
    );
  }

  /// Create QRContent for subject content
  factory QRContent.subject({
    required String id,
    required String title,
    required String subjectName,
    required String sectionType,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return QRContent(
      id: id,
      type: QRContentType.subject,
      title: title,
      description: description,
      subjectName: subjectName,
      sectionType: sectionType,
      metadata: metadata,
    );
  }

  /// Create QRContent for URL content
  factory QRContent.url({
    required String id,
    required String title,
    required String url,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return QRContent(
      id: id,
      type: QRContentType.url,
      title: title,
      description: description,
      url: url,
      metadata: metadata,
    );
  }

  /// Create QRContent for text content
  factory QRContent.text({
    required String id,
    required String title,
    required String text,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return QRContent(
      id: id,
      type: QRContentType.text,
      title: title,
      description: description,
      text: text,
      metadata: metadata,
    );
  }

  /// Check if this content can be executed directly
  bool get canExecuteDirectly {
    return type == QRContentType.video || 
           type == QRContentType.subject ||
           type == QRContentType.url;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        videoId,
        subjectName,
        sectionType,
        url,
        text,
        metadata,
      ];
}
