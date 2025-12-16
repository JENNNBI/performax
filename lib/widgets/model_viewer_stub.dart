/// Stub implementation of ModelViewer for mobile platforms (iOS/Android)
/// This prevents the model_viewer_plus package from being imported on platforms
/// where it causes crashes (specifically iOS Simulator)
///
/// This file is imported conditionally:
/// - On Web: The real model_viewer_plus package is used
/// - On Mobile: This stub is used (but never actually called due to platform checks)
library;

import 'package:flutter/material.dart';

/// Stub ModelViewer widget that matches the API of the real ModelViewer
/// This is never actually used because platform checks return fallback before calling this
class ModelViewer extends StatelessWidget {
  final String src;
  final String? alt;
  final String? poster;
  final bool? loading;
  final bool? reveal;
  final bool? withCredentials;
  final bool? autoRotate;
  final double? autoRotateDelay;
  final double? rotationPerSecond;
  final InteractionPrompt? interactionPrompt;
  final double? interactionPromptThreshold;
  final String? cameraControls;
  final bool? disablePan;
  final bool? disableTap;
  final bool? touchAction;
  final bool? disableZoom;
  final String? orbitSensitivity;
  final String? interpolationDecay;
  final String? cameraOrbit;
  final String? cameraTarget;
  final String? fieldOfView;
  final String? maxCameraOrbit;
  final String? minCameraOrbit;
  final String? maxFieldOfView;
  final String? minFieldOfView;
  final String? bounds;
  final String? animationName;
  final bool? animationCrossfadeDuration;
  final bool? autoPlay;
  final String? skyboxImage;
  final String? environmentImage;
  final String? exposure;
  final String? shadowIntensity;
  final String? shadowSoftness;
  final Color? backgroundColor;
  final RelatedJsObject? relatedJs;
  final String? relatedCss;
  final String? iosSrc;
  final bool? ar;
  final String? arModes;
  final String? arScale;
  final String? arPlacement;
  final String? xrEnvironment;

  const ModelViewer({
    super.key,
    required this.src,
    this.alt,
    this.poster,
    this.loading,
    this.reveal,
    this.withCredentials,
    this.autoRotate,
    this.autoRotateDelay,
    this.rotationPerSecond,
    this.interactionPrompt,
    this.interactionPromptThreshold,
    this.cameraControls,
    this.disablePan,
    this.disableTap,
    this.touchAction,
    this.disableZoom,
    this.orbitSensitivity,
    this.interpolationDecay,
    this.cameraOrbit,
    this.cameraTarget,
    this.fieldOfView,
    this.maxCameraOrbit,
    this.minCameraOrbit,
    this.maxFieldOfView,
    this.minFieldOfView,
    this.bounds,
    this.animationName,
    this.animationCrossfadeDuration,
    this.autoPlay,
    this.skyboxImage,
    this.environmentImage,
    this.exposure,
    this.shadowIntensity,
    this.shadowSoftness,
    this.backgroundColor,
    this.relatedJs,
    this.relatedCss,
    this.iosSrc,
    this.ar,
    this.arModes,
    this.arScale,
    this.arPlacement,
    this.xrEnvironment,
  });

  @override
  Widget build(BuildContext context) {
    // This stub should never be called due to platform checks
    // But if it is, return a safe placeholder
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.view_in_ar_rounded,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// Stub InteractionPrompt enum to match the API
enum InteractionPrompt {
  auto,
  none,
}

/// Stub RelatedJsObject class to match the API
class RelatedJsObject {
  const RelatedJsObject();
}
