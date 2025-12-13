import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../models/avatar.dart';

/// Real 3D Avatar Widget with GLB Model Rendering
/// Uses model_viewer_plus for interactive 3D model display
/// STRICT Y-axis rotation ONLY (horizontal spin) - all other movement locked
class Avatar3DWidget extends StatefulWidget {
  final Avatar avatar;
  final double size;
  final bool enable3D; // Feature flag to disable 3D if causing issues

  const Avatar3DWidget({
    super.key,
    required this.avatar,
    this.size = 300,
    this.enable3D = true, // Default to enabled, but can be disabled
  });

  @override
  State<Avatar3DWidget> createState() => _Avatar3DWidgetState();
}

class _Avatar3DWidgetState extends State<Avatar3DWidget> with AutomaticKeepAliveClientMixin {
  bool _hasError = false;
  bool _isLoading = true;
  bool _shouldLoadModel = false;
  bool _texturesReady = false;
  bool _modelViewerCreated = false;
  late String _effectiveModelPath;
  bool _assetAvailable = false;
  static const String _defaultModel = 'assets/avatars/3d/scene_with_textures.glb';
  static const String _defaultPoster = 'assets/avatars/2d/test_model_profil.png';
  static const Duration _loadTimeout = Duration(seconds: 3); // Reduced timeout
  static const Duration _deferDelay = Duration(milliseconds: 1200); // Increased defer for stability
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    
    // CRITICAL: If 3D is disabled, show fallback immediately
    if (!widget.enable3D) {
      _hasError = true;
      _isLoading = false;
      debugPrint('⚠️ Avatar3DWidget: 3D rendering disabled via feature flag');
      return;
    }
    
    final Stopwatch sw = Stopwatch()..start();
    debugPrint('🎬 Avatar3DWidget: Initializing for ${widget.avatar.id}');
    
    // Determine effective model path
    _effectiveModelPath = widget.avatar.full3DPath ?? _defaultModel;
    if (_effectiveModelPath.contains('male_') || _effectiveModelPath.contains('female_')) {
      _effectiveModelPath = _defaultModel;
    }
    debugPrint('📦 Avatar3DWidget: Using model path: $_effectiveModelPath');
    
    // CRITICAL: Initialize assets asynchronously without blocking UI
    // Use microtask to ensure UI renders first and remains responsive
    Future.microtask(() {
      // Additional check to ensure widget is still mounted
      if (mounted && widget.enable3D) {
        _initializeAssets(sw);
      }
    });
  }
  
  /// Initialize assets with proper synchronization and error handling
  /// CRITICAL: All operations are non-blocking to prevent UI freeze
  Future<void> _initializeAssets(Stopwatch sw) async {
    if (!mounted || !widget.enable3D) return;
    
    try {
      debugPrint('⏳ Avatar3DWidget: Starting non-blocking asset preload...');
      
      // CRITICAL: Load assets with proper error handling
      // Note: rootBundle.load() should be async, but we add extra safeguards
      ByteData? modelData;
      ByteData? posterData;
      
      try {
        // Load assets with timeout - these should be non-blocking
        final futures = [
          rootBundle.load(_effectiveModelPath).timeout(_loadTimeout),
          rootBundle.load(_defaultPoster).timeout(_loadTimeout),
        ];
        
        final results = await Future.wait(futures, eagerError: false).catchError((error) {
          debugPrint('⚠️ Avatar3DWidget: Asset loading error: $error');
          return <ByteData>[];
        });
        
        if (results.length >= 2) {
          modelData = results[0];
          posterData = results[1];
        }
      } catch (e) {
        debugPrint('⚠️ Avatar3DWidget: Exception during asset load: $e');
      }
      
      if (!mounted || !widget.enable3D) return;
      
      // Validate results
      if (modelData == null || posterData == null) {
        debugPrint('❌ Avatar3DWidget: Failed to load required assets');
        debugPrint('   Model data: ${modelData != null ? "✓" : "✗"}');
        debugPrint('   Poster data: ${posterData != null ? "✓" : "✗"}');
        throw Exception('Asset loading failed');
      }
      
      // CRITICAL: Update state only after assets are confirmed loaded
      // Use microtask to ensure state update doesn't block
      await Future.microtask(() {
        if (mounted && widget.enable3D) {
          setState(() {
            _assetAvailable = true;
          });
          debugPrint('✅ Avatar3DWidget: Assets preloaded successfully at ${sw.elapsedMilliseconds}ms');
          
          // Step 2: Defer ModelViewer creation significantly to avoid WebView init issues
          // Use multiple frame callbacks to ensure UI is stable
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !widget.enable3D) return;
            
            // Additional defer to ensure UI is completely stable
            Future.delayed(_deferDelay, () {
              if (!mounted || !widget.enable3D) return;
              
              // Final check before enabling ModelViewer
              if (mounted && _assetAvailable && widget.enable3D) {
                setState(() {
                  _shouldLoadModel = true;
                  _texturesReady = true;
                });
                debugPrint('✅ Avatar3DWidget: Model loading enabled at ${sw.elapsedMilliseconds}ms');
                
                // Auto-hide loading after reasonable time to show the 3D model
                // The ModelViewer will show the poster until the model loads, then display the 3D model
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted && _isLoading) {
                    setState(() {
                      _isLoading = false;
                    });
                    debugPrint('⏱️ Avatar3DWidget: Loading indicator hidden, ModelViewer should now display 3D model at ${sw.elapsedMilliseconds}ms');
                  }
                });
              }
            });
          });
        }
      });
      
    } catch (e, stackTrace) {
      debugPrint('❌ Avatar3DWidget: Critical error during asset initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // CRITICAL: Report texture loading dependency issue
      debugPrint('🔴 TEXTURE LOADING DEPENDENCY ISSUE DETECTED');
      debugPrint('   Model path: $_effectiveModelPath');
      debugPrint('   Poster path: $_defaultPoster');
      debugPrint('   Error: $e');
      debugPrint('   Stack: $stackTrace');
      
      // Use microtask to prevent blocking during error handling
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
            _assetAvailable = false;
          });
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // CRITICAL: If 3D is disabled, show poster image immediately
    if (!widget.enable3D) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: _buildPosterImage(context),
      );
    }
    
    // CRITICAL: Always show poster image immediately - don't wait for assets
    // This ensures users always see something while loading
    // Show poster if 3D model is not ready yet (assets loading, or not enabled)
    if (!_assetAvailable || !_shouldLoadModel || !_texturesReady) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: _buildPosterWithLoading(context),
      );
    }
    
    // Only show fallback if there's an actual critical error
    if (_hasError) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: _buildFallbackAvatar(context),
      );
    }
    
    // If we reach here, 3D model is ready - show it!
    // The ModelViewer will display the 3D model with textures
    
    // CRITICAL: Wrap ModelViewer in multiple safety layers to prevent UI freeze
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        // Isolate rendering to prevent UI blocking
        child: Builder(
          builder: (context) {
            try {
              return Stack(
                children: [
                  // ModelViewer - only create when assets are ready and textures are synchronized
                  // CRITICAL: This is wrapped in RepaintBoundary to isolate rendering
                  // The ModelViewer will show the 3D model with textures when ready
                  _buildModelViewer(_effectiveModelPath),
                  
                  // Loading indicator - show while model is initializing (fade out after model loads)
                  if (_isLoading)
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text(
                                'Loading 3D Avatar...',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } catch (e, stackTrace) {
              // CRITICAL: Catch any exception during ModelViewer creation
              debugPrint('❌ FATAL ERROR in Avatar3DWidget build: $e');
              debugPrint('Stack trace: $stackTrace');
              
              // Set error state and show fallback - use microtask to prevent blocking
              Future.microtask(() {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                    _modelViewerCreated = false;
                  });
                }
              });
              
              return _buildFallbackAvatar(context);
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildModelViewer(String modelPath) {
    // CRITICAL: Only create ModelViewer when assets and textures are ready
    if (!_assetAvailable || !_texturesReady || !_shouldLoadModel || !widget.enable3D) {
      // Show poster while waiting
      return _buildPosterImage(context);
    }
    
    // CRITICAL: Prevent multiple ModelViewer creations that could cause freeze
    // If already created, return existing widget structure (ModelViewer will handle its own state)
    // Note: We don't cache the widget itself, but we prevent multiple build calls
    
    try {
      // Only log on first creation attempt
      if (!_modelViewerCreated) {
        debugPrint('🎨 Avatar3DWidget: Creating ModelViewer for $modelPath');
        _modelViewerCreated = true;
      }
      
      // CRITICAL: Wrap ModelViewer in a way that prevents blocking
      // Use RepaintBoundary to isolate rendering
      return RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: ModelViewer(
            // Use the avatar's specific 3D model asset
            // CRITICAL: ModelViewer requires asset:// scheme for Flutter assets
            src: 'asset://$modelPath',
            alt: '${widget.avatar.displayName} 3D Avatar',
            // Poster also needs asset:// scheme - shows while 3D model loads
            poster: 'asset://$_defaultPoster',
        
        // CRITICAL: Use Loading.auto to load model immediately with textures
        // This ensures the model displays properly with all textures loaded
        loading: Loading.auto,
        
        // Basic display settings - SAFE CONFIGURATION to prevent GL errors
        ar: false,
        autoRotate: false,
        cameraControls: true,
        
        // Camera position - fixed angle, only Y-axis rotation allowed
        cameraOrbit: '0deg 75deg 4.5m',
        fieldOfView: '35deg', // Fixed FOV
        
        // STRICT Y-AXIS ROTATION ONLY - Lock X-axis tilt and Z-axis zoom completely
        // Format: 'Y-rotation X-tilt Z-distance'
        // Y-rotation: -Infinity to Infinity (unlimited horizontal spin)
        // X-tilt: 75deg (LOCKED - no vertical tilting)
        // Z-distance: 4.5m (LOCKED - no zooming)
        minCameraOrbit: '-360deg 75deg 4.5m',
        maxCameraOrbit: '360deg 75deg 4.5m',
        
        disableZoom: true,
        
        interactionPrompt: InteractionPrompt.none,
        cameraTarget: 'auto auto auto',
        
        // Lighting and rendering settings for proper texture display
        exposure: 1.5,
        shadowIntensity: 0.5,
        shadowSoftness: 0.5,
        
        backgroundColor: Colors.transparent,
        
        // Ensure model is visible immediately when loaded with textures
        reveal: Reveal.auto,
        
        // CSS to ensure proper display and texture loading
        relatedCss: '''
          model-viewer { 
            --poster-color: transparent; 
            width: 100%; 
            height: 100%; 
            display: block;
            background-color: transparent;
          }
          model-viewer::part(default-ar-button) {
            display: none;
          }
        ''',
          ),
        ),
      );
    } catch (e, stackTrace) {
      // CRITICAL: Catch any exception during ModelViewer widget creation
      debugPrint('❌ FATAL ERROR creating ModelViewer: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Reset creation flag on error
      _modelViewerCreated = false;
      
      // Report texture loading issue
      debugPrint('🔴 MODELVIEWER CREATION FAILURE');
      debugPrint('   Model path: $modelPath');
      debugPrint('   Assets available: $_assetAvailable');
      debugPrint('   Textures ready: $_texturesReady');
      debugPrint('   Error: $e');
      
      // Update state to show fallback - use microtask to prevent blocking
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      });
      
      // Return fallback immediately
      return _buildFallbackAvatar(context);
    }
  }
  
  /// Build poster image (simple version without loading overlay)
  Widget _buildPosterImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: Image.asset(
        _defaultPoster,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('⚠️ Avatar3DWidget: Poster image load error: $error');
          return _buildFallbackAvatar(context);
        },
      ),
    );
  }
  
  /// Build poster image with loading indicator while assets are being prepared
  Widget _buildPosterWithLoading(BuildContext context) {
    return Stack(
      children: [
        // Show poster image immediately with error handling
        _buildPosterImage(context),
        // Loading overlay - show while assets are loading or model is initializing
        if (_isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading Avatar...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  /// Fallback avatar display when 3D model fails to load
  Widget _buildFallbackAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.3),
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(widget.size / 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              size: widget.size * 0.4,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              widget.avatar.displayName,
              style: TextStyle(
                fontSize: widget.size * 0.05,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
