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
      // --- DARK MODE (BOOSTED Glow - Better Separation) ---
      // Stronger colored rim light for clear depth and layering
      topShadow = Colors.black.withValues(alpha: 0.4); // Deeper structural shadow
      bottomShadow = Colors.black.withValues(alpha: 0.5); // Enhanced depth definition
      ambientShadow = NeumorphicColors.accentBlue.withValues(alpha: 0.5); // ✨ ENHANCED - Punchier blue glow (increased from 0.30)
      highlightColor = Colors.white.withValues(alpha: 0.05); // Brighter highlight
      borderColor = Colors.white.withValues(alpha: 0.12); // More visible rim
    } else {
      // --- LIGHT MODE (REDUCED Glow - Cleaner Look) ---
      // Neutral grey shadows only, very subtle
      topShadow = Colors.white; // Light source from top
      bottomShadow = Colors.grey.shade400.withValues(alpha: 0.05); // 🎯 Very faint grey shadow
      ambientShadow = Colors.transparent; // No colored glow in light mode
      highlightColor = Colors.white.withValues(alpha: 0.9); // Bright highlight
      borderColor = Colors.grey.shade300.withValues(alpha: 0.08); // Very subtle neutral border
    }

    List<BoxShadow> shadows = [];
    
    // ✨ CALIBRATED Shadow Parameters (Theme-Aware)
    final blurRadius = isDark ? 15.0 : 8.0; // Stronger blur for dark mode backlight effect
    final offsetDistance = isDark ? 3.0 : 3.0; // Consistent offset
    final spreadRadius = 0.0; // No spread in both modes for tight control

    if (!isPressed) {
      shadows = [
        // Top-Left Light Source (Highlight)
        BoxShadow(
          color: isDark ? highlightColor : topShadow,
          offset: Offset(-offsetDistance/2, -offsetDistance/2),
          blurRadius: blurRadius,
          spreadRadius: 0.0,
        ),
        // Bottom-Right Drop Shadow (Depth)
        BoxShadow(
          color: bottomShadow,
          offset: Offset(offsetDistance, offsetDistance),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
        // Ambient Glow (Dark Mode Only) - ENHANCED for tighter, punchier glow
        if (isDark)
          BoxShadow(
            color: ambientShadow, // 0.5 opacity - punchier blue glow
            offset: const Offset(0, 3), // Slightly offset for depth
            blurRadius: 10.0, // Tighter blur for closer, more focused glow (reduced from 15.0)
            spreadRadius: 0.5, // Reduced spread for tighter glow (reduced from 1.0)
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
          width: isDark ? 0.8 : 0.5, // More visible border for dark mode
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
