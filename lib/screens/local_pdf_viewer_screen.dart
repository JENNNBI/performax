import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../blocs/bloc_exports.dart';
import '../services/quest_service.dart';

/// Local PDF Viewer Screen
/// Displays PDF files from local assets with zoom and scroll functionality
class LocalPDFViewerScreen extends StatefulWidget {
  final String assetPath;
  final String title;
  final Color? gradientStart;
  final Color? gradientEnd;

  const LocalPDFViewerScreen({
    super.key,
    required this.assetPath,
    required this.title,
    this.gradientStart,
    this.gradientEnd,
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
        
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (widget.gradientStart ?? const Color(0xFF667eea)).withOpacity(0.1),
                  (widget.gradientEnd ?? const Color(0xFF764ba2)).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(languageBloc),
                  
                  // PDF Viewer or Loading/Error State
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingState()
                        : _hasError
                            ? _buildErrorState(languageBloc)
                            : _buildPDFViewer(),
                  ),
                  
                  // Page indicator
                  if (!_isLoading && !_hasError && _totalPages > 0)
                    _buildPageIndicator(languageBloc),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LanguageBloc languageBloc) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.gradientStart ?? const Color(0xFF667eea),
            widget.gradientEnd ?? const Color(0xFF764ba2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.gradientStart ?? const Color(0xFF667eea)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            languageBloc.currentLanguage == 'tr'
                                ? 'PDF Doküman'
                                : 'PDF Document',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
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
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LanguageBloc languageBloc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPDFFromAsset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                languageBloc.currentLanguage == 'tr'
                    ? 'Tekrar Dene'
                    : 'Try Again',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.gradientStart ?? const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PDFView(
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
            debugPrint('✅ PDF view controller created');
          },
          onPageChanged: (int? page, int? total) {
            if (page != null) {
              setState(() {
                _currentPage = page;
                _totalPages = total ?? 0;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPageIndicator(LanguageBloc languageBloc) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.gradientStart ?? const Color(0xFF667eea),
                  widget.gradientEnd ?? const Color(0xFF764ba2),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            languageBloc.currentLanguage == 'tr'
                ? 'Sayfa ${_currentPage + 1} / $_totalPages'
                : 'Page ${_currentPage + 1} / $_totalPages',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Stop timer and emit quest progress
    _studyTimer?.cancel();
    if (_elapsedSeconds > 0) {
      QuestService.instance.onPdfStudiedSeconds(_elapsedSeconds);
    }
    super.dispose();
  }
}
