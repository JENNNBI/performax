import 'package:flutter/material.dart';
import '../../theme/neumorphic_colors.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isPressed;
  final Color? color;
  final double depth;
  final BoxShape shape;
  final double? width;
  final double? height;

  const NeumorphicContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.isPressed = false,
    this.color,
    this.depth = 4.0,
    this.shape = BoxShape.rectangle,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? NeumorphicColors.getBackground(context);
    final topShadow = NeumorphicColors.getShadowTop(context);
    final bottomShadow = NeumorphicColors.getShadowBottom(context);

    List<BoxShadow> shadows = [];
    
    // Use absolute value for blurRadius to prevent assertion errors
    final blurRadius = depth.abs() * 2;
    // Use actual depth for offsets to maintain direction
    final offsetDepth = depth;

    if (!isPressed) {
      shadows = [
        BoxShadow(
          color: topShadow.withValues(alpha: 0.6),
          offset: Offset(-offsetDepth, -offsetDepth),
          blurRadius: blurRadius,
        ),
        BoxShadow(
          color: bottomShadow.withValues(alpha: 0.3),
          offset: Offset(offsetDepth, offsetDepth),
          blurRadius: blurRadius,
        ),
      ];
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
        shape: shape,
        boxShadow: shadows,
        gradient: isPressed 
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _darken(bgColor, 0.05),
                _lighten(bgColor, 0.05),
              ],
            )
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }

  Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color _lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
