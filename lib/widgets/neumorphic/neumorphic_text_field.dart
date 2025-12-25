import 'package:flutter/material.dart';
import '../../theme/neumorphic_colors.dart';
import 'inner_shadow.dart';

class NeumorphicTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const NeumorphicTextField({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = NeumorphicColors.getBackground(context);
    final topShadow = NeumorphicColors.getShadowTop(context);
    final bottomShadow = NeumorphicColors.getShadowBottom(context);
    final textColor = NeumorphicColors.getText(context);

    return InnerShadow(
      shadows: [
        Shadow(
          color: bottomShadow.withValues(alpha: 0.5),
          blurRadius: 4,
          offset: const Offset(2, 2),
        ),
        Shadow(
          color: topShadow.withValues(alpha: 0.8),
          blurRadius: 4,
          offset: const Offset(-2, -2),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }
}
