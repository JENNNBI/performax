import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/pdf_resource.dart';
import '../blocs/bloc_exports.dart';
import '../services/user_service.dart';
import 'ai_assistant_widget.dart';

class FlipbookViewer extends StatefulWidget {
  final PDFResource resource;
  final bool fullscreen;

  const FlipbookViewer({
    super.key,
    required this.resource,
    this.fullscreen = false,
  });

  @override
  State<FlipbookViewer> createState() => _FlipbookViewerState();
}

class _FlipbookViewerState extends State<FlipbookViewer> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _progress = 0.0;
  String? _selectedText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Scaffold(
          appBar: widget.fullscreen ? null : AppBar(
            title: Text(widget.resource.title),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.psychology),
                onPressed: _openAIAssistant,
                tooltip: 'AI Asistan',
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlipbookViewer(
                        resource: widget.resource,
                        fullscreen: true,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
              ),
            ],
          ),
          body: Stack(
            children: [
              // WebView for flipbook
              InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.resource.url),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  iframeAllow: "camera; microphone",
                  iframeAllowFullscreen: true,
                  supportZoom: widget.resource.hasZoom,
                  builtInZoomControls: widget.resource.hasZoom,
                  displayZoomControls: false,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  useOnLoadResource: true,
                  useOnDownloadStart: true,
                  useShouldOverrideUrlLoading: true,
                  allowsBackForwardNavigationGestures: true,
                  allowsLinkPreview: false,
                  isFraudulentWebsiteWarningEnabled: false,
                  allowsAirPlayForMediaPlayback: true,
                  allowsPictureInPictureMediaPlayback: true,
                  disableHorizontalScroll: false,
                  disableVerticalScroll: false,
                  disableContextMenu: false,
                  transparentBackground: false,
                  supportMultipleWindows: false,
                  clearCache: false,
                  cacheEnabled: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  debugPrint('WebView created for URL: ${widget.resource.url}');
                },
                onLoadStart: (controller, url) {
                  debugPrint('Loading started: $url');
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                    _progress = 0.0;
                  });
                },
                onLoadStop: (controller, url) {
                  debugPrint('Loading completed: $url');
                  setState(() {
                    _isLoading = false;
                    _hasError = false;
                  });
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100.0;
                  });
                },
                onReceivedError: (controller, request, error) {
                  debugPrint('WebView Error: ${error.description} (Code: ${error.type})');
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage = '${error.description}\n\nPlease check your internet connection and try again.';
                  });
                },
                onReceivedHttpError: (controller, request, errorResponse) {
                  debugPrint('HTTP Error: ${errorResponse.statusCode} for ${request.url}');
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                    _errorMessage = 'HTTP Error ${errorResponse.statusCode}: ${errorResponse.reasonPhrase}\n\nThe server may be temporarily unavailable.';
                  });
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('Console: ${consoleMessage.message}');
                },
                contextMenu: ContextMenu(
                  menuItems: [
                    ContextMenuItem(
                      id: 1,
                      title: "AI ile Sor",
                      action: () async {
                        _getSelectedTextAndOpenAI();
                      },
                    ),
                  ],
                ),
              ),
              
              // Loading indicator
              if (_isLoading)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          languageBloc.currentLanguage == 'tr'
                              ? 'Flipbook yükleniyor...'
                              : 'Loading flipbook...',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Error state
              if (_hasError)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            languageBloc.currentLanguage == 'tr'
                                ? 'Flipbook yüklenirken hata oluştu'
                                : 'Error loading flipbook',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  languageBloc.currentLanguage == 'tr'
                                      ? 'Tekrar Dene'
                                      : 'Retry',
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                label: Text(
                                  languageBloc.currentLanguage == 'tr'
                                      ? 'Kapat'
                                      : 'Close',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Bottom navigation for fullscreen mode
          bottomNavigationBar: widget.fullscreen ? _buildFullscreenControls(languageBloc) : null,
        );
      },
    );
  }

  Widget _buildFullscreenControls(LanguageBloc languageBloc) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: languageBloc.currentLanguage == 'tr' ? 'Kapat' : 'Close',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: languageBloc.currentLanguage == 'tr' ? 'Yenile' : 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            onPressed: _zoomIn,
            tooltip: languageBloc.currentLanguage == 'tr' ? 'Yakınlaştır' : 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            onPressed: _zoomOut,
            tooltip: languageBloc.currentLanguage == 'tr' ? 'Uzaklaştır' : 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: languageBloc.currentLanguage == 'tr' ? 'Tam Ekrandan Çık' : 'Exit Fullscreen',
          ),
        ],
      ),
    );
  }

  void _refresh() {
    _webViewController?.reload();
  }

  void _zoomIn() {
    _webViewController?.evaluateJavascript(source: "document.body.style.zoom = '1.2'");
  }

  void _zoomOut() {
    _webViewController?.evaluateJavascript(source: "document.body.style.zoom = '0.8'");
  }

  Future<void> _getSelectedTextAndOpenAI() async {
    try {
      // Try to get selected text from WebView
      final result = await _webViewController?.evaluateJavascript(
        source: "window.getSelection().toString()",
      );
      
      if (result != null && result.toString().isNotEmpty) {
        setState(() {
          _selectedText = result.toString();
        });
        _openAIAssistant();
      } else {
        // Fallback: open AI assistant without selected text
        _openAIAssistant();
      }
    } catch (e) {
      debugPrint('Error getting selected text: $e');
      _openAIAssistant();
    }
  }

  Future<void> _openAIAssistant() async {
    // Fetch user profile for personalization
    final userService = UserService();
    final userProfile = await userService.getCurrentUserProfile();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIAssistantWidget(
        selectedText: _selectedText,
        userName: userProfile?.displayName,
        userProfile: userProfile, // Pass user profile for context
        onClose: () {
          Navigator.of(context).pop();
          setState(() {
            _selectedText = null;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _webViewController?.dispose();
    super.dispose();
  }
}
