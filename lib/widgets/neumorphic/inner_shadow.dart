import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class InnerShadow extends SingleChildRenderObjectWidget {
  const InnerShadow({
    super.key,
    this.shadows = const <Shadow>[],
    super.child,
  });

  final List<Shadow> shadows;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderInnerShadow(shadows);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderInnerShadow renderObject) {
    renderObject.shadows = shadows;
  }
}

class _RenderInnerShadow extends RenderProxyBox {
  _RenderInnerShadow(this._shadows);

  List<Shadow> _shadows;

  set shadows(List<Shadow> value) {
    if (_shadows == value) return;
    _shadows = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    
    final bounds = offset & size;

    context.canvas.saveLayer(bounds, Paint());
    context.paintChild(child!, offset);

    for (final shadow in _shadows) {
      // shadowRect removed - unused
      final shadowPaint = Paint()
        ..blendMode = BlendMode.srcATop
        ..colorFilter = ColorFilter.mode(shadow.color, BlendMode.srcOut)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: shadow.blurSigma, sigmaY: shadow.blurSigma);

      context.canvas.saveLayer(bounds, shadowPaint);
      context.canvas.translate(shadow.offset.dx, shadow.offset.dy);
      context.paintChild(child!, offset);
      context.canvas.restore();
    }

    context.canvas.restore();
  }
}
