import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NeumorphicColors.accentBlue,
        brightness: Brightness.light,
        surface: NeumorphicColors.backgroundLight,
      ),
      scaffoldBackgroundColor: NeumorphicColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // Transparent to blend with background
        iconTheme: IconThemeData(color: NeumorphicColors.textLight),
        titleTextStyle: TextStyle(
          color: NeumorphicColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NeumorphicColors.accentBlue,
        brightness: Brightness.dark,
        surface: NeumorphicColors.backgroundDark,
      ),
      scaffoldBackgroundColor: NeumorphicColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: NeumorphicColors.textDark),
        titleTextStyle: TextStyle(
          color: NeumorphicColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
