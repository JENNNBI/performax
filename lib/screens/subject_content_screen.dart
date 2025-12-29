import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_screen.dart';
import 'dart:ui';

class SubjectContentScreen extends StatefulWidget {
  final String subjectName;
  final String sectionType;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData subjectIcon;

  const SubjectContentScreen({
    super.key,
    required this.subjectName,
    required this.sectionType,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subjectIcon,
  });

  @override
  State<SubjectContentScreen> createState() => _SubjectContentScreenState();
}

class _SubjectContentScreenState extends State<SubjectContentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getContentData() {
    if (widget.sectionType == 'Örnek Sınav Kağıtları') {
      return _getPDFContent();
    } else {
      return _getVideoContent();
    }
  }

  List<Map<String, String>> _getVideoContent() {
    // Sample video data - replace with real YouTube video IDs
    switch (widget.subjectName) {
      case 'Matematik':
        return [
          {
            'title': 'Fonksiyonlar ve Grafikler',
            'description': 'Temel fonksiyon kavramları ve grafik çizimi',
            'videoId': 'dQw4w9WgXcQ',
            'duration': '15:30',
          },
          {
            'title': 'Türev ve Uygulamaları',
            'description': 'Türev alma kuralları ve problemler',
            'videoId': 'dQw4w9WgXcQ',
            'duration': '22:45',
          },
          {
            'title': 'İntegral Hesaplama',
            'description': 'Belirli ve belirsiz integral çözümleri',
            'videoId': 'dQw4w9WgXcQ',
            'duration': '18:20',
          },
        ];
      case 'Fizik':
        return [
          {
            'title': 'Newton Yasaları',
            'description': 'Hareket yasaları ve dinamik problemler',
            'videoId': 'dQw4w9WgXcQ',
            'duration': '20:15',
          },
          {
            'title': 'Elektromanyetizma',
            'description': 'Elektrik ve manyetik alan kavramları',
            'videoId': 'dQw4w9WgXcQ',
            'duration': '25:30',
          },
        ];
      case 'Kimya':
        return [
          {
            'title': 'Atom Yapısı',
            'description': 'Elektronik yapı ve periyodik sistem',
            'videoId': 'dQw4w9WgXcQ',
            'duration': '16:45',
          },
          {
            'title': 'Kimyasal Bağlar',
            'description': 'İyonik ve kovalent bağ türleri',
            'videoId': 'dQw4w9WgXcQ',
            'duration': '19:20',
          },
        ];
      default:
        return [
          {
            'title': '${widget.subjectName} Temel Konular',
            'description': 'Temel kavramlar ve uygulamalar',
            'videoId': 'dQw4w9WgXcQ',
            'duration': '15:00',
          },
        ];
    }
  }

  List<Map<String, String>> _getPDFContent() {
    // Sample PDF data - replace with real PDF URLs
    switch (widget.subjectName) {
      case 'Matematik':
        return [
          {
            'title': 'Matematik Deneme Sınavı 1',
            'description': 'YKS tarzı matematik soruları - 40 soru',
            'url': 'https://example.com/math-exam-1.pdf',
            'size': '2.5 MB',
          },
          {
            'title': 'Geometri Test Soruları',
            'description': 'Düzlem ve analitik geometri problemleri',
            'url': 'https://example.com/geometry-test.pdf',
            'size': '1.8 MB',
          },
        ];
      case 'Fizik':
        return [
          {
            'title': 'Fizik Deneme Sınavı 1',
            'description': 'Mekanik ve termodinamik soruları',
            'url': 'https://example.com/physics-exam-1.pdf',
            'size': '2.1 MB',
          },
        ];
      case 'Kimya':
        return [
          {
            'title': 'Kimya Test Soruları',
            'description': 'Genel kimya ve organik kimya',
            'url': 'https://example.com/chemistry-test.pdf',
            'size': '1.9 MB',
          },
        ];
      default:
        return [
          {
            'title': '${widget.subjectName} Örnek Sınav',
            'description': 'Temel konular örnek sorular',
            'url': 'https://example.com/sample-exam.pdf',
            'size': '2.0 MB',
          },
        ];
    }
  }

  void _openVideo(String videoId, {String? title, String? description}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoId: videoId,
          videoTitle: title,
          channelName: widget.subjectName,
          description: description,
          subjectTag: widget.subjectName, // Pass subject name as tag
        ),
      ),
    );
  }

  Future<void> _openPDF(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentData = _getContentData();
    final isVideo = widget.sectionType != 'Örnek Sınav Kağıtları';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.gradientStart.withValues(alpha: 0.3),
              widget.gradientEnd.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.subjectName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.sectionType,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.gradientStart,
                                widget.gradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradientEnd.withValues(alpha: 0.4),
                                blurRadius: 15,
                                spreadRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.subjectIcon,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Count
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.gradientStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.gradientStart.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${contentData.length} ${isVideo ? "video" : "belge"} bulundu',
                      style: TextStyle(
                        color: widget.gradientStart,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Content List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: contentData.length,
                      itemBuilder: (context, index) {
                        final item = contentData[index];
                        return _buildContentCard(item, isVideo);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(Map<String, String> item, bool isVideo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: widget.gradientStart.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (isVideo) {
                  _openVideo(
                    item['videoId']!,
                    title: item['title'],
                    description: item['description'],
                  );
                } else {
                  _openPDF(item['url']!);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.gradientStart.withValues(alpha: 0.2),
                            widget.gradientEnd.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isVideo ? Icons.play_circle_outline : Icons.picture_as_pdf_outlined,
                        size: 30,
                        color: widget.gradientStart,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['description']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.gradientStart.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isVideo ? item['duration']! : item['size']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.gradientStart,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.gradientStart.withValues(alpha: 0.1),
                            widget.gradientEnd.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isVideo ? Icons.play_arrow_outlined : Icons.open_in_new_outlined,
                        size: 20,
                        color: widget.gradientStart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 