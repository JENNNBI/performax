import 'package:flutter/material.dart';
import '../../theme/neumorphic_colors.dart';

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
    // Override colors for explicit visibility as requested
    // Background: Solid Dark Grey #252830
    const bgColor = Color(0xFF252830);
    
    // Text Color: Pure White #FFFFFF
    const textColor = Colors.white;
    
    // Placeholder Color: Light Gray #9CA3AF
    const placeholderColor = Color(0xFF9CA3AF);

    // Border: Subtle White/Transparent
    final border = Border.all(
      color: Colors.white.withValues(alpha: 0.15),
      width: 1,
    );

    return Container(
      height: 60, // Consistent height
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
        // No heavy shadows for this flat/clean override.
        // The prompt asked for "Solid, lighter surface color", implying less reliance on heavy neumorphic shadows 
        // and more on distinct visibility.
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: NeumorphicColors.accentBlue,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: placeholderColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
