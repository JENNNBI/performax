import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/qr_content.dart';
import '../screens/video_player_screen.dart';
import '../screens/grade_selection_screen.dart';
import '../screens/biology_9th_grade_screen.dart';
import '../utils/app_icons.dart';

/// Service for handling QR code content parsing and execution
class QRCodeService {
  static final QRCodeService _instance = QRCodeService._internal();
  factory QRCodeService() => _instance;
  QRCodeService._internal();

  static QRCodeService get instance => _instance;

  /// Parse QR code data and return QRContent object
  QRContent? parseQRData(String qrData) {
    try {
      // First, try to parse as JSON (embedded action format)
      if (qrData.trim().startsWith('{') && qrData.trim().endsWith('}')) {
        final Map<String, dynamic> jsonData = json.decode(qrData);
        return QRContent.fromJson(jsonData);
      }

      // Handle YouTube URLs
      if (qrData.contains('youtube.com') || qrData.contains('youtu.be')) {
        final videoId = YoutubePlayer.convertUrlToId(qrData);
        if (videoId != null) {
          return QRContent.video(
            id: videoId,
            title: 'YouTube Video',
            videoId: videoId,
            description: 'Video from QR code',
          );
        }
      }

      // Handle direct YouTube video ID (11 characters)
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(qrData)) {
        return QRContent.video(
          id: qrData,
          title: 'YouTube Video',
          videoId: qrData,
          description: 'Video from QR code',
        );
      }

      // Handle URLs
      if (Uri.tryParse(qrData)?.hasAbsolutePath == true) {
        return QRContent.url(
          id: qrData,
          title: 'External Link',
          url: qrData,
          description: 'External website',
        );
      }

      // Handle subject codes (format: subject:Matematik:topic_videos)
      final subjectMatch = RegExp(r'^subject:([^:]+):([^:]+)$').firstMatch(qrData);
      if (subjectMatch != null) {
        final subjectName = subjectMatch.group(1)!;
        final sectionType = subjectMatch.group(2)!;
        
        return QRContent.subject(
          id: qrData,
          title: 'Subject Content',
          subjectName: subjectName,
          sectionType: sectionType,
          description: 'Navigate to $subjectName - $sectionType',
        );
      }

      // Handle Biology 9th Grade special case
      if (qrData.toLowerCase().contains('biology') && qrData.toLowerCase().contains('9')) {
        return QRContent.subject(
          id: 'biology_9th_grade',
          title: 'Biology 9th Grade Textbook',
          subjectName: 'Biology',
          sectionType: 'textbook',
          description: 'Interactive digital flipbook for Biology 9th Grade',
          metadata: {'flipbook': true, 'special': true},
        );
      }

      // Handle exam codes (format: exam:Matematik:12)
      final examMatch = RegExp(r'^exam:([^:]+):(\d+)$').firstMatch(qrData);
      if (examMatch != null) {
        final subjectName = examMatch.group(1)!;
        final grade = examMatch.group(2)!;
        
        return QRContent.subject(
          id: qrData,
          title: 'Exam Content',
          subjectName: subjectName,
          sectionType: 'sample_exams',
          description: 'Grade $grade exam for $subjectName',
          metadata: {'grade': grade},
        );
      }

      // Handle practice codes (format: practice:Matematik:12)
      final practiceMatch = RegExp(r'^practice:([^:]+):(\d+)$').firstMatch(qrData);
      if (practiceMatch != null) {
        final subjectName = practiceMatch.group(1)!;
        final grade = practiceMatch.group(2)!;
        
        return QRContent.subject(
          id: qrData,
          title: 'Practice Content',
          subjectName: subjectName,
          sectionType: 'problem_solving',
          description: 'Grade $grade practice for $subjectName',
          metadata: {'grade': grade},
        );
      }

      // Handle video codes (format: video:VIDEO_ID:Title)
      final videoMatch = RegExp(r'^video:([^:]+):(.+)$').firstMatch(qrData);
      if (videoMatch != null) {
        final videoId = videoMatch.group(1)!;
        final title = videoMatch.group(2)!;
        
        return QRContent.video(
          id: qrData,
          title: title,
          videoId: videoId,
          description: 'Educational video content',
        );
      }

      // Default to text content
      return QRContent.text(
        id: qrData,
        title: 'QR Code Content',
        text: qrData,
        description: 'Text content from QR code',
      );

    } catch (e) {
      debugPrint('Error parsing QR data: $e');
      return null;
    }
  }

  /// Execute the embedded action from QR content
  Future<void> executeAction(BuildContext context, QRContent content) async {
    try {
      switch (content.type) {
        case QRContentType.video:
          await _executeVideoAction(context, content);
          break;
        case QRContentType.subject:
          await _executeSubjectAction(context, content);
          break;
        case QRContentType.url:
          await _executeUrlAction(context, content);
          break;
        case QRContentType.text:
          await _executeTextAction(context, content);
          break;
        default:
          _showErrorDialog(context, 'Unsupported content type: ${content.type}');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error executing action: $e');
      }
    }
  }

  /// Execute video action
  Future<void> _executeVideoAction(BuildContext context, QRContent content) async {
    if (content.videoId == null) {
      if (context.mounted) {
        _showErrorDialog(context, 'Video ID not found');
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoId: content.videoId!,
          videoTitle: content.title,
          channelName: content.subjectName ?? 'Performax',
          description: content.description,
          subjectTag: content.subjectName, // Pass subject name as tag
        ),
      ),
    );
  }

  /// Execute subject action
  Future<void> _executeSubjectAction(BuildContext context, QRContent content) async {
    if (content.subjectName == null || content.sectionType == null) {
      if (context.mounted) {
        _showErrorDialog(context, 'Subject information not found');
      }
      return;
    }

    if (!context.mounted) return;
    // Special handling for Biology 9th Grade flipbook
    if (content.metadata?['special'] == true && 
        content.subjectName == 'Biology' && 
        content.sectionType == 'textbook') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Biology9thGradeScreen(),
        ),
      );
      return;
    }

    // Get subject gradient colors and icon
    final subjectData = _getSubjectData(content.subjectName!);
    
    // Convert subject name to subject key (lowercase, no spaces)
    final subjectKey = content.subjectName!.toLowerCase().replaceAll('ğ', 'g').replaceAll('ç', 'c').replaceAll('ş', 's').replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ü', 'u');
    
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradeSelectionScreen(
          subjectName: content.subjectName!,
          subjectKey: subjectKey,
          gradientStart: subjectData['gradientStart'],
          gradientEnd: subjectData['gradientEnd'],
          subjectIcon: subjectData['icon'],
        ),
      ),
    );
  }

  /// Execute URL action
  Future<void> _executeUrlAction(BuildContext context, QRContent content) async {
    if (content.url == null) {
      if (context.mounted) {
        _showErrorDialog(context, 'URL not found');
      }
      return;
    }

    final uri = Uri.parse(content.url!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showErrorDialog(context, 'Could not launch URL: ${content.url}');
      }
    }
  }

  /// Execute text action
  Future<void> _executeTextAction(BuildContext context, QRContent content) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(content.title),
        content: Text(content.text ?? 'No text content'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Get subject data for navigation
  Map<String, dynamic> _getSubjectData(String subjectName) {
    final subjectMap = {
      'Matematik': {
        'gradientStart': const Color(0xFF667eea),
        'gradientEnd': const Color(0xFF764ba2),
        'icon': AppIcons.subjects['Matematik']!,
      },
      'Fizik': {
        'gradientStart': const Color(0xFFf093fb),
        'gradientEnd': const Color(0xFFf5576c),
        'icon': AppIcons.subjects['Fizik']!,
      },
      'Kimya': {
        'gradientStart': const Color(0xFF4facfe),
        'gradientEnd': const Color(0xFF00f2fe),
        'icon': AppIcons.subjects['Kimya']!,
      },
      'Biyoloji': {
        'gradientStart': const Color(0xFF43e97b),
        'gradientEnd': const Color(0xFF38f9d7),
        'icon': AppIcons.subjects['Biyoloji']!,
      },
      'Türkçe': {
        'gradientStart': const Color(0xFFfa709a),
        'gradientEnd': const Color(0xFFfee140),
        'icon': AppIcons.subjects['Türkçe']!,
      },
      'Tarih': {
        'gradientStart': const Color(0xFFa8edea),
        'gradientEnd': const Color(0xFFfed6e3),
        'icon': AppIcons.subjects['Tarih']!,
      },
      'Coğrafya': {
        'gradientStart': const Color(0xFFffecd2),
        'gradientEnd': const Color(0xFFfcb69f),
        'icon': AppIcons.subjects['Coğrafya']!,
      },
      'Felsefe': {
        'gradientStart': const Color(0xFFa18cd1),
        'gradientEnd': const Color(0xFFfbc2eb),
        'icon': AppIcons.subjects['Felsefe']!,
      },
    };

    return subjectMap[subjectName] ?? subjectMap['Matematik']!;
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Generate QR code data for different content types
  String generateQRData(QRContent content) {
    return json.encode(content.toJson());
  }

  /// Generate QR data for video
  String generateVideoQRData(String videoId, String title) {
    final content = QRContent.video(
      id: videoId,
      title: title,
      videoId: videoId,
    );
    return generateQRData(content);
  }

  /// Generate QR data for subject
  String generateSubjectQRData(String subjectName, String sectionType, String title) {
    final content = QRContent.subject(
      id: 'subject:$subjectName:$sectionType',
      title: title,
      subjectName: subjectName,
      sectionType: sectionType,
    );
    return generateQRData(content);
  }

  /// Generate QR data for exam
  String generateExamQRData(String subjectName, String grade, String title) {
    final content = QRContent.subject(
      id: 'exam:$subjectName:$grade',
      title: title,
      subjectName: subjectName,
      sectionType: 'sample_exams',
      metadata: {'grade': grade},
    );
    return generateQRData(content);
  }

  /// Generate QR data for practice
  String generatePracticeQRData(String subjectName, String grade, String title) {
    final content = QRContent.subject(
      id: 'practice:$subjectName:$grade',
      title: title,
      subjectName: subjectName,
      sectionType: 'problem_solving',
      metadata: {'grade': grade},
    );
    return generateQRData(content);
  }
}
