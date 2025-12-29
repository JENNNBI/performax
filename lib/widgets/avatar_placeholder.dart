import 'package:flutter/material.dart';
import '../models/avatar.dart';

/// Enhanced avatar placeholder with visual representation
/// Shows colorful circular avatars with initials and visual elements
class AvatarPlaceholder extends StatelessWidget {
  final Avatar avatar;
  final double size;
  final bool showBorder;

  const AvatarPlaceholder({
    super.key,
    required this.avatar,
    this.size = 100,
    this.showBorder = true,
  });

  Color _getAvatarColor() {
    // Assign colors based on avatar ID with better visual distinction
    const colors = {
      'male_1': Color(0xFF4A90E2),   // Bright blue
      'male_2': Color(0xFF50C878),   // Emerald green
      'male_3': Color(0xFFE94B3C),   // Vivid red
      'male_4': Color(0xFFFF9F40),   // Warm orange
      'female_1': Color(0xFFB565D8),   // Vibrant purple
      'female_2': Color(0xFF00CED1),   // Dark turquoise
      'female_3': Color(0xFFFF69B4),   // Hot pink
      'female_4': Color(0xFFFF85C0),   // Rose pink
    };
    
    return colors[avatar.id] ?? const Color(0xFF4A90E2);
  }

  Color _getSecondaryColor() {
    // Secondary/accent colors for gradient effect
    const colors = {
      'male_1': Color(0xFF357ABD),
      'male_2': Color(0xFF3FA368),
      'male_3': Color(0xFFD13A2B),
      'male_4': Color(0xFFE8832F),
      'female_1': Color(0xFF9B4FC4),
      'female_2': Color(0xFF00B8BB),
      'female_3': Color(0xFFE5559F),
      'female_4': Color(0xFFE66FA8),
    };
    
    return colors[avatar.id] ?? const Color(0xFF357ABD);
  }

  IconData _getGenderIcon() {
    return avatar.gender == 'male' 
        ? Icons.face 
        : Icons.face_3;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getAvatarColor();
    final secondaryColor = _getSecondaryColor();
    final initial = avatar.displayName[0].toUpperCase();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: size * 0.03,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: size * 0.15,
            spreadRadius: size * 0.02,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: size * 0.1,
            spreadRadius: size * 0.01,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main initial
          Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(size * 0.01, size * 0.01),
                    blurRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          ),
          // Gender icon badge
          Positioned(
            bottom: size * 0.05,
            right: size * 0.05,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: size * 0.04,
                  ),
                ],
              ),
              child: Icon(
                _getGenderIcon(),
                size: size * 0.15,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

