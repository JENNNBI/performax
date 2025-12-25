import 'package:flutter/material.dart';

class NeumorphicColors {
  // Light Mode
  static const Color backgroundLight = Color(0xFFE0E5EC);
  static const Color shadowLightTop = Colors.white;
  static const Color shadowLightBottom = Color(0xFFA3B1C6);
  static const Color textLight = Color(0xFF4A5568);
  
  // Dark Mode
  static const Color backgroundDark = Color(0xFF2B2E35);
  static const Color shadowDarkTop = Color(0xFF3E4450); // Lighter for top-left
  static const Color shadowDarkBottom = Color(0xFF1E2125); // Darker for bottom-right
  static const Color textDark = Color(0xFFE2E8F0);

  // Accents
  static const Color accentOrange = Color(0xFFFF9F43);
  static const Color accentBlue = Color(0xFF54A0FF);
  
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? backgroundDark 
        : backgroundLight;
  }

  static Color getShadowTop(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? shadowDarkTop 
        : shadowLightTop;
  }

  static Color getShadowBottom(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? shadowDarkBottom 
        : shadowLightBottom;
  }
  
  static Color getText(BuildContext context) {
     return Theme.of(context).brightness == Brightness.dark 
        ? textDark 
        : textLight;
  }
}
