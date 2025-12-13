import 'package:flutter/material.dart';

/// Modern 3D-style icons for the Performax app
/// These icons provide a more visually appealing and modern look
class AppIcons {
  // Subject Icons - Modern Futuristic 3D themed
  static const Map<String, IconData> subjects = {
    'Matematik': Icons.functions_rounded, // 🔢 Modern mathematical functions
    'Geometri': Icons.pentagon_rounded, // 🔺 Geometry shapes
    'Fizik': Icons.electric_bolt_rounded, // ⚡ Energy and physics forces
    'Kimya': Icons.scatter_plot_rounded, // 🧬 Molecular structures
    'Biyoloji': Icons.nature_people_rounded, // 🧬 Living systems
    'Türkçe': Icons.translate_rounded, // 🌐 Language and communication
    'Tarih': Icons.timeline_rounded, // 📈 Historical timeline
    'Coğrafya': Icons.satellite_alt_rounded, // 🛰️ Earth observation
    'Felsefe': Icons.psychology_alt_rounded, // 🧠 Deep thinking
  };

  // Navigation Icons - Modern 3D style
  static const IconData home = Icons.home_rounded;
  static const IconData profile = Icons.account_circle_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData statistics = Icons.analytics_rounded;
  static const IconData logout = Icons.logout_rounded;

  // Content Type Icons - 3D Media style
  static const IconData videoLessons = Icons.smart_display_rounded;
  static const IconData practiceVideos = Icons.quiz_rounded;
  static const IconData examPapers = Icons.description_rounded;
  static const IconData qrScanner = Icons.qr_code_2_rounded;

  // Action Icons - Modern 3D interaction style
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData save = Icons.save_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData bookmark = Icons.bookmark_rounded;
  static const IconData bookmarkAdd = Icons.bookmark_add_rounded;
  static const IconData bookmarkRemove = Icons.bookmark_remove_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteAdd = Icons.favorite_border_rounded;

  // UI Control Icons - Smooth 3D controls
  static const IconData search = Icons.search_rounded;
  static const IconData clear = Icons.clear_rounded;
  static const IconData add = Icons.add_circle_rounded;
  static const IconData remove = Icons.remove_circle_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData check = Icons.check_circle_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData info = Icons.info_rounded;

  // Navigation Arrow Icons - Sleek directional
  static const IconData arrowForward = Icons.arrow_forward_ios_rounded;
  static const IconData arrowBack = Icons.arrow_back_ios_rounded;
  static const IconData arrowUp = Icons.keyboard_arrow_up_rounded;
  static const IconData arrowDown = Icons.keyboard_arrow_down_rounded;

  // Form Icons - Clean input style
  static const IconData email = Icons.email_rounded;
  static const IconData person = Icons.person_rounded;
  static const IconData lock = Icons.lock_rounded;
  static const IconData visibility = Icons.visibility_rounded;
  static const IconData visibilityOff = Icons.visibility_off_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData school = Icons.school_rounded;
  static const IconData location = Icons.location_city_rounded;
  static const IconData cake = Icons.cake_rounded;

  // Status Icons - Modern indicators
  static const IconData verified = Icons.verified_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData starOutline = Icons.star_outline_rounded;
  static const IconData trending = Icons.trending_up_rounded;
  static const IconData timer = Icons.timer_rounded;
  static const IconData playCircle = Icons.play_circle_filled_rounded;

  // Communication Icons - 3D messaging style
  static const IconData send = Icons.send_rounded;
  static const IconData emailRead = Icons.mark_email_read_rounded;
  static const IconData notification = Icons.notifications_rounded;

  // System Icons - Clean interface elements
  static const IconData menu = Icons.menu_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData moreVert = Icons.more_vert_rounded;
  static const IconData moreHoriz = Icons.more_horiz_rounded;

  // Device Icons - Modern tech style
  static const IconData flashOn = Icons.flash_on_rounded;
  static const IconData flashOff = Icons.flash_off_rounded;
  static const IconData camera = Icons.camera_alt_rounded;

  // Utility function to get subject icon by name
  static IconData getSubjectIcon(String subjectName) {
    return subjects[subjectName] ?? Icons.school_rounded;
  }

  // Utility function to create icon with consistent styling
  static Widget styledIcon(
    IconData icon, {
    double size = 24.0,
    Color? color,
    double? opacity,
  }) {
    return Icon(
      icon,
      size: size,
      color: opacity != null ? color?.withValues(alpha: opacity) : color,
    );
  }

  // Create truly 3D-style icon with depth and shadows
  static Widget threeDIcon(
    IconData icon, {
    double size = 24.0,
    Color primaryColor = const Color(0xFF6C63FF),
    Color? secondaryColor,
    bool isPressed = false,
  }) {
    final secondary = secondaryColor ?? primaryColor.withValues(alpha: 0.6);
    final double pressOffset = isPressed ? 2.0 : 0.0;
    final double shadowBlur = isPressed ? 4.0 : 8.0;
    final double shadowSpread = isPressed ? 1.0 : 3.0;
    
    return Transform.translate(
      offset: Offset(0, pressOffset),
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((size + 16) / 4),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withValues(alpha: 0.9),
              primaryColor,
              secondary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            // Main shadow
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: shadowBlur,
              spreadRadius: shadowSpread,
              offset: Offset(0, 4 - pressOffset),
            ),
            // Inner highlight
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 2,
              spreadRadius: -1,
              offset: const Offset(-1, -1),
            ),
            // Deep shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: shadowBlur * 1.5,
              spreadRadius: 0,
              offset: Offset(0, 6 - pressOffset),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: size,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Create floating 3D icon with hover/glow effect
  static Widget floatingIcon(
    IconData icon, {
    double size = 24.0,
    Color color = const Color(0xFF6C63FF),
    bool isActive = false,
  }) {
    return Container(
      width: size + 20,
      height: size + 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((size + 20) / 3),
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [
            color.withValues(alpha: 0.8),
            color,
            color.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          // Outer glow
          BoxShadow(
            color: color.withValues(alpha: isActive ? 0.6 : 0.3),
            blurRadius: isActive ? 20 : 12,
            spreadRadius: isActive ? 8 : 4,
            offset: const Offset(0, 0),
          ),
          // Bottom shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          // Top highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: -2,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: size,
          color: Colors.white,
        ),
      ),
    );
  }

  // Animated bouncing 3D icon
  static Widget bouncingIcon(
    IconData icon, {
    required AnimationController controller,
    double size = 24.0,
    Color color = const Color(0xFF6C63FF),
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final bounce = Curves.elasticOut.transform(controller.value);
        return Transform.scale(
          scale: 1.0 + (bounce * 0.3),
          child: Transform.translate(
            offset: Offset(0, -bounce * 10),
            child: threeDIcon(
              icon,
              size: size,
              primaryColor: color,
              isPressed: controller.value > 0.5,
            ),
          ),
        );
      },
    );
  }

  // Glassmorphism 3D icon
  static Widget glassMorphIcon(
    IconData icon, {
    double size = 24.0,
    Color color = const Color(0xFF6C63FF),
  }) {
    return Container(
      width: size + 24,
      height: size + 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((size + 24) / 4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
            color.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }

  // Futuristic Holographic Icon for Subject Cards - High Contrast Version
  static Widget holographicIcon(
    IconData icon, {
    double size = 35.0,
    Color primaryColor = Colors.white,
    Color? accentColor,
  }) {
    // Use dark contrasting colors for better visibility
    final iconColor = const Color(0xFF1A1A2E); // Dark navy for icon
    final glowColor = const Color(0xFF00D4FF); // Bright cyan for glow
    final bgColor = const Color(0xFFF0F0F0); // Light background
    
    return Container(
      width: size + 25,
      height: size + 25,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            bgColor,
            bgColor.withValues(alpha: 0.9),
            glowColor.withValues(alpha: 0.3),
            glowColor.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        ),
        border: Border.all(
          width: 2,
          color: glowColor.withValues(alpha: 0.8),
        ),
        boxShadow: [
          // Bright cyan glow
          BoxShadow(
            color: glowColor.withValues(alpha: 0.6),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          // Secondary glow
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
          // Depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background gradient overlay
          Container(
            width: size + 15,
            height: size + 15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor.withValues(alpha: 0.8),
                  bgColor.withValues(alpha: 0.6),
                  glowColor.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          // Main icon with high contrast
          Icon(
            icon,
            size: size,
            color: iconColor,
            shadows: [
              Shadow(
                color: glowColor.withValues(alpha: 0.7),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
              Shadow(
                color: glowColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          // Holographic scan lines for futuristic effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    glowColor.withValues(alpha: 0.15),
                    Colors.transparent,
                    glowColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.4, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cyberpunk Neon Icon
  static Widget cyberpunkIcon(
    IconData icon, {
    double size = 35.0,
    Color neonColor = const Color(0xFF00FFFF),
  }) {
    return Container(
      width: size + 30,
      height: size + 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ],
        ),
        border: Border.all(
          width: 2,
          color: neonColor.withValues(alpha: 0.8),
        ),
        boxShadow: [
          // Neon glow
          BoxShadow(
            color: neonColor.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          // Inner shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: size,
          color: neonColor,
          shadows: [
            Shadow(
              color: neonColor.withValues(alpha: 0.8),
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
            Shadow(
              color: neonColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }
} 