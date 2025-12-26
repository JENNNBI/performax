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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ✨ THEME-AWARE SHADOW SYSTEM - Perfect Balance ✨
    // Dark Mode: Restore subtle premium glow
    // Light Mode: Clean, neutral soft shadows
    
    final Color topShadow;
    final Color bottomShadow;
    final Color ambientShadow;
    final Color highlightColor;
    final Color borderColor;
    
    if (isDark) {
      // --- DARK MODE (Subtle Premium Glow - RESTORED) ---
      // Elegant colored rim light for depth without bloom
      topShadow = Colors.black.withOpacity(0.3); // Soft structural shadow
      bottomShadow = Colors.black.withOpacity(0.4); // Depth definition
      ambientShadow = NeumorphicColors.accentBlue.withOpacity(0.15); // ✨ RESTORED - Subtle blue glow
      highlightColor = Colors.white.withOpacity(0.03); // Gentle highlight
      borderColor = Colors.white.withOpacity(0.08); // Subtle rim
    } else {
      // --- LIGHT MODE (Clean Soft UI) ---
      // Neutral grey shadows, no colored glow
      topShadow = Colors.white; // Light source from top
      bottomShadow = Colors.black.withOpacity(0.06); // 🎯 NEUTRAL grey shadow (not colored)
      ambientShadow = Colors.transparent; // No colored glow in light mode
      highlightColor = Colors.white.withOpacity(0.8); // Bright highlight
      borderColor = Colors.black.withOpacity(0.05); // Subtle neutral border
    }

    List<BoxShadow> shadows = [];
    
    // ✨ Balanced Shadow Parameters
    final blurRadius = isDark ? 10.0 : 12.0; // Moderate blur for both modes
    final offsetDistance = isDark ? 3.0 : 4.0; // Gentle offset
    final spreadRadius = isDark ? 0.0 : 0.0; // No spread in both modes

    if (!isPressed) {
      shadows = [
        // Top-Left Light Source (Highlight)
        BoxShadow(
          color: isDark ? highlightColor : topShadow,
          offset: Offset(-offsetDistance/2, -offsetDistance/2),
          blurRadius: blurRadius,
          spreadRadius: isDark ? 0 : 1.0, // Slight spread for light mode highlight
        ),
        // Bottom-Right Drop Shadow (Depth)
        BoxShadow(
          color: bottomShadow,
          offset: Offset(offsetDistance, offsetDistance),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
        // Ambient Glow (Dark Mode Only) - RESTORED with subtlety
        if (isDark)
          BoxShadow(
            color: ambientShadow, // 0.15 opacity - visible but controlled
            offset: const Offset(0, 2), // Gentle offset
            blurRadius: 12, // Moderate bloom
            spreadRadius: 0, // No spread - contained glow
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
        border: Border.all(
          color: borderColor,
          width: isDark ? 0.6 : 1.0, // Visible border for both modes
        ),
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
