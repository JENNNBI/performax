import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import '../services/quest_service.dart';
import '../services/statistics_service.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Local PDF Viewer Screen
/// Refactored to Neumorphic Design System (Floating Controls)
class LocalPDFViewerScreen extends StatefulWidget {
  final String assetPath;
  final String title;
  final Color? gradientStart;
  final Color? gradientEnd;
  final String? subject;

  const LocalPDFViewerScreen({
    super.key,
    required this.assetPath,
    required this.title,
    this.gradientStart,
    this.gradientEnd,
    this.subject,
  });

  @override
  State<LocalPDFViewerScreen> createState() => _LocalPDFViewerScreenState();
}

class _LocalPDFViewerScreenState extends State<LocalPDFViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 0;
  int _totalPages = 0;
  Timer? _studyTimer;
  int _elapsedSeconds = 0;
  Timer? _pageViewTimer;
  final Set<int> _countedPages = {};
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _loadPDFFromAsset();
  }

  /// Load PDF from assets and save to temporary directory
  Future<void> _loadPDFFromAsset() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Load PDF from assets
      final ByteData data = await rootBundle.load(widget.assetPath);
      
      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = widget.assetPath.split('/').last;
      final File tempFile = File('${tempDir.path}/$fileName');
      
      // Write to temporary file
      await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      
      setState(() {
        _localPath = tempFile.path;
        _isLoading = false;
      });

      debugPrint('✅ PDF loaded successfully: ${tempFile.path}');
    } catch (e) {
      debugPrint('❌ Error loading PDF: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'PDF yüklenirken hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final languageBloc = context.read<LanguageBloc>();
        final bgColor = NeumorphicColors.getBackground(context);
        
        return Scaffold(
          backgroundColor: Colors.white, // Keep background clean/white for PDF contrast
          body: Stack(
            children: [
              // PDF Viewer (Full Screen)
              if (_isLoading)
                _buildLoadingState(context)
              else if (_hasError)
                _buildErrorState(context, languageBloc)
              else
                _buildPDFViewer(),

              // Floating Header (Neumorphic)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        NeumorphicButton(
                          onPressed: () => Navigator.pop(context),
                          padding: const EdgeInsets.all(12),
                          borderRadius: 12,
                          color: bgColor.withValues(alpha: 0.9), // Slightly transparent
                          child: Icon(Icons.arrow_back_rounded, color: NeumorphicColors.getText(context)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: NeumorphicContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            borderRadius: 12,
                            color: bgColor.withValues(alpha: 0.9),
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf_rounded, size: 20, color: widget.gradientStart ?? NeumorphicColors.accentBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: NeumorphicColors.getText(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Floating Page Controls (Bottom)
              if (!_isLoading && !_hasError && _totalPages > 0)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      borderRadius: 30,
                      color: bgColor.withValues(alpha: 0.95),
                      depth: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () {
                              if (_currentPage > 0) {
                                _pdfViewController?.setPage(_currentPage - 1);
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (widget.gradientStart ?? NeumorphicColors.accentBlue).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentPage + 1} / $_totalPages',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.gradientStart ?? NeumorphicColors.accentBlue,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () {
                              if (_currentPage < _totalPages - 1) {
                                _pdfViewController?.setPage(_currentPage + 1);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitPulsingGrid(
            color: widget.gradientStart ?? const Color(0xFF667eea),
            size: 60.0,
          ),
          const SizedBox(height: 24),
          Text(
            'PDF yükleniyor...',
            style: TextStyle(
              fontSize: 16,
              color: NeumorphicColors.getText(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, LanguageBloc languageBloc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.1),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              languageBloc.currentLanguage == 'tr'
                  ? 'PDF Yüklenemedi'
                  : 'Failed to Load PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: NeumorphicColors.getText(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: NeumorphicColors.getText(context).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            NeumorphicButton(
              onPressed: _loadPDFFromAsset,
              color: widget.gradientStart ?? NeumorphicColors.accentBlue,
              child: Text(
                languageBloc.currentLanguage == 'tr'
                    ? 'Tekrar Dene'
                    : 'Try Again',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFViewer() {
    if (_localPath == null) {
      return const SizedBox.shrink();
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
        debugPrint('✅ PDF rendered with $_totalPages pages');
        // Start study timer
        _studyTimer?.cancel();
        _studyTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          _elapsedSeconds++;
          // Show feedback every 60 seconds
          if (_elapsedSeconds % 60 == 0 && mounted) {
            final minutes = (_elapsedSeconds ~/ 60);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF çalışması: ${minutes} dk'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
        // Start page view debounce for initial page
        _pageViewTimer?.cancel();
        _pageViewTimer = Timer(const Duration(seconds: 1), () {
          if (mounted && !_countedPages.contains(_currentPage)) {
            _countedPages.add(_currentPage);
            QuestService.instance.updateProgress(type: 'read_pages', amount: 1, subject: widget.subject);
            StatisticsService.instance.incrementPageCount(1);
          }
        });
      },
      onError: (error) {
        debugPrint('❌ PDF render error: $error');
        setState(() {
          _hasError = true;
          _errorMessage = error.toString();
        });
      },
      onPageError: (page, error) {
        debugPrint('❌ Page $page error: $error');
      },
      onViewCreated: (PDFViewController controller) {
        _pdfViewController = controller;
        debugPrint('✅ PDF view controller created');
      },
      onPageChanged: (int? page, int? total) {
        if (page != null) {
          setState(() {
            _currentPage = page;
            _totalPages = total ?? 0;
          });
          _pageViewTimer?.cancel();
          _pageViewTimer = Timer(const Duration(seconds: 1), () {
            if (mounted && !_countedPages.contains(_currentPage)) {
              _countedPages.add(_currentPage);
              QuestService.instance.updateProgress(type: 'read_pages', amount: 1, subject: widget.subject);
              StatisticsService.instance.incrementPageCount(1);
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    // Stop timer and emit quest progress
    _studyTimer?.cancel();
    _pageViewTimer?.cancel();
    if (_elapsedSeconds > 0) {
      StatisticsService.instance.logStudyTime(pdf: _elapsedSeconds);
      StatisticsService.instance.logDailyActivity(increment: 1);
    }
    super.dispose();
  }
}
