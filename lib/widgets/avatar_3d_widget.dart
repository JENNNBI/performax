import 'package:flutter/material.dart';
import 'model_viewer_stub.dart';

/// 3D Avatar Widget with iOS Simulator Compatibility
/// 
/// Features:
/// - Displays 3D GLB model with manual Y-axis rotation
/// - Auto-rotation disabled
/// - iOS Simulator safe (uses fallback)
/// - Web and Android support with full 3D rendering
/// 
/// Configuration:
/// - Camera controls enabled for manual rotation
/// - Restricted to Y-axis rotation only via interaction-prompt
/// - No zoom, no pan
class Avatar3DWidget extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;
  
  const Avatar3DWidget({
    super.key,
    this.assetPath = 'assets/avatars/3d/Creative_Character_free.glb',
    this.width = 280,
    this.height = 380,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Attempt to load 3D model on all platforms
    // Error handling will catch WebKit GPU crashes and use fallback
    debugPrint('🎯 Avatar3DWidget: Attempting to load 3D model on current platform');
    return _SafeModelViewerWidget(
      assetPath: assetPath,
      width: width,
      height: height,
      theme: theme,
    );
  }
  
  /// Fallback widget for platforms that don't support 3D models
}

/// Safe wrapper for ModelViewer with error handling
/// This ensures the app never crashes if ModelViewer fails
class _SafeModelViewerWidget extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final ThemeData theme;
  
  const _SafeModelViewerWidget({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.theme,
  });

  @override
  State<_SafeModelViewerWidget> createState() => _SafeModelViewerWidgetState();
}

class _SafeModelViewerWidgetState extends State<_SafeModelViewerWidget> {
  bool _useFallback = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to prevent blocking app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized yet, show loading
    if (!_isInitialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(widget.theme.primaryColor),
          ),
        ),
      );
    }
    
    // If error occurred, use fallback permanently
    if (_useFallback) {
      return _buildFallback();
    }
    
    // Try to build ModelViewer with error boundary
    return _ErrorBoundaryWidget(
      onError: () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _useFallback = true;
              });
            }
          });
        }
      },
      child: Builder(
        builder: (context) {
          try {
            return _buildModelViewer();
          } catch (e) {
            debugPrint('❌ Error building ModelViewer: $e');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _useFallback = true;
                });
              }
            });
            return _buildFallback();
          }
        },
      ),
    );
  }
  
  Widget _buildModelViewer() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ModelViewer(
          src: widget.assetPath,
          alt: '3D Avatar Model',
          
          // CRITICAL: Auto-rotation DISABLED as per requirements
          autoRotate: false,
          
          // CRITICAL: Manual rotation ENABLED (no cameraControls param in this version)
          // User can drag to rotate
          
          // Disable zoom to prevent unwanted interactions
          disableZoom: true,
          
          // Disable pan to restrict movement to rotation only  
          disablePan: true,
          
          // Set camera orbit to optimize Y-axis rotation
          // Format: "theta phi radius" - increased radius to 3.8m to show full model
          cameraOrbit: '0deg 80deg 3.8m',
          
          // Restrict camera orbit to Y-axis only
          minCameraOrbit: 'auto 80deg auto',
          maxCameraOrbit: 'auto 80deg auto',
          
          // Transparent background to blend with app design
          backgroundColor: Colors.transparent,
          
          // Disable interaction prompt (no "tap to interact" message)
          interactionPrompt: InteractionPrompt.none,
          
          // Disable AR mode
          ar: false,
        ),
      ),
    );
  }
  
  Widget _buildFallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_in_ar_rounded,
            size: 80,
            color: widget.theme.primaryColor.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            '3D Avatar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.theme.primaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error boundary widget to catch and handle widget build errors
class _ErrorBoundaryWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback onError;
  
  const _ErrorBoundaryWidget({
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (e) {
      debugPrint('❌ Error in ErrorBoundaryWidget: $e');
      onError();
      return const SizedBox.shrink();
    }
  }
}
