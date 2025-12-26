import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../services/streak_service.dart';
import '../services/user_provider.dart';

/// High-Fidelity Holographic Streak Pop-up
/// Implements a futuristic, neon/cyber aesthetic with dynamic animations.
class StreakModal extends StatefulWidget {
  final StreakData streakData;

  const StreakModal({
    super.key,
    required this.streakData,
  });

  /// Show the streak modal with animation
  static Future<void> show(BuildContext context, StreakData streakData) async {
    return await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8), // Darker barrier for neon contrast
      useSafeArea: true,
      builder: (context) {
        return StreakModal(streakData: streakData);
      },
    );
  }

  @override
  State<StreakModal> createState() => _StreakModalState();
}

class _StreakModalState extends State<StreakModal> with TickerProviderStateMixin {
  // 1. Entrance Animation
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideTextAnimation;

  // 2. Loop Animations (Orbit, Pulse, Shimmer)
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _flameController;

  // 3. Button Interaction
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  // 4. Day Check-in Animation
  late AnimationController _checkInController;
  late Animation<double> _dayFillAnimation;
  late Animation<double> _checkScaleAnimation;

  @override
  void initState() {
    super.initState();

    // -- Entrance --
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.elasticOut, // The "Pop" effect
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _slideTextAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // -- Loops --
    _orbitController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true); // Breathing effect

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Continuous flow

    _flameController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this
    )..repeat(reverse: true);

    // -- Button --
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // -- Day Check-in --
    _checkInController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dayFillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkInController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _checkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkInController,
        curve: const Interval(0.4, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Start Entrance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      // Start check-in animation shortly after entrance
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _checkInController.forward();
      });
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _flameController.dispose();
    _buttonController.dispose();
    _checkInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakColor = const Color(0xFF00E5FF); // Cyan Neon
    final secondaryColor = const Color(0xFF9D00FF); // Purple Neon

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: 340,
            height: 420,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. The Holographic Card
                _buildHolographicCard(streakColor, secondaryColor),

                // 2. The Hero Icon (Orbits & Flame) - Positioned overlapping top
                Positioned(
                  top: -60,
                  child: _buildHeroIcon(streakColor, secondaryColor),
                ),

                // 3. Content (Text & Button)
                Positioned.fill(
                  top: 80, // Space for the icon
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Staggered Entrance for Text
                        SlideTransition(
                          position: _slideTextAnimation,
                          child: Column(
                            children: [
                              // Title
                              Text(
                                "Streak ${widget.streakData.currentStreak}!",
                                style: TextStyle(
                                  fontFamily: 'Orbitron', // Assuming a futuristic font, or fallback
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(color: streakColor, blurRadius: 20),
                                    Shadow(color: streakColor, blurRadius: 40),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Subtitle
                              Text(
                                "Bugün zaten giriş yaptınız!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 4. Weekly Tracker
                        _buildWeeklyTracker(streakColor),
                        
                        const Spacer(),
                        // Button
                        _buildActionButton(streakColor, secondaryColor),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTracker(Color activeColor) {
    // Current Day Logic (1 = Mon, 7 = Sun)
    final now = DateTime.now();
    final currentWeekday = now.weekday; 
    
    // Get actual user login history from Provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Logic:
    // "User registers on Friday -> Mon-Thu empty, Fri checked".
    // We simulate "Registration Date" based on the current streak count.
    // If Streak = 1, it means the user started today (or broke streak and restarted today).
    // If Streak = N, it means the user started N-1 days ago.
    
    // Calculate the "Start Date" of the current streak
    // Streak 1: Start = Today
    // Streak 2: Start = Yesterday
    // StartDate = Today - (Streak - 1) days
    final streakStartDate = now.subtract(Duration(days: widget.streakData.currentStreak - 1));
    
    // We only care about the weekday of the start date relative to the current week window (Mon-Sun).
    // Actually, we just need to check if a specific past day (Mon, Tue...) is >= StreakStartDate.
    
    // Let's normalize dates to midnight for comparison
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final streakStartMidnight = DateTime(streakStartDate.year, streakStartDate.month, streakStartDate.day);
    
    // Determine the Monday of the current week
    final currentMonday = todayMidnight.subtract(Duration(days: currentWeekday - 1));

    final days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          // Calculate the date for this specific column (Mon..Sun)
          final columnDate = currentMonday.add(Duration(days: index));
          
          final isFuture = columnDate.isAfter(todayMidnight);
          final isToday = columnDate.isAtSameMomentAs(todayMidnight);
          final isPast = columnDate.isBefore(todayMidnight);
          
          bool isCompleted = false;
          bool isPastEmpty = false;

          if (isToday) {
            isCompleted = true; // Today is always checked in this "Claim Reward" popup
          } else if (isPast) {
            // It is completed ONLY if the date is on or after the streak start date
            // e.g. If Streak starts Friday, then Mon-Thu are NOT completed (Empty)
            if (columnDate.isAtSameMomentAs(streakStartMidnight) || columnDate.isAfter(streakStartMidnight)) {
              isCompleted = true;
            } else {
              isCompleted = false;
              isPastEmpty = true; // User wasn't active/registered yet
            }
          }
          
          return _buildDayWidget(days[index], isPast && isCompleted, isToday, activeColor, isPastEmpty);
        }),
      ),
    );
  }

  Widget _buildDayWidget(String label, bool isPastCompleted, bool isToday, Color activeColor, bool isPastEmpty) {
    // 3 States:
    // Past Completed -> Orange Check
    // Past Empty -> Empty Circle (Greyed out)
    // Today -> Animates to Completed
    // Future -> Empty (Blue Outline)
    
    final orangeColor = const Color(0xFFFF6B35); // Reference Orange
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        if (isPastCompleted)
          // Static Completed State
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orangeColor,
              boxShadow: [
                BoxShadow(
                  color: orangeColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
          )
        else if (isToday)
          // Animated Check-in State
          AnimatedBuilder(
            animation: _checkInController,
            builder: (context, child) {
              // Interpolate between Outline Blue -> Filled Orange
              final progress = _dayFillAnimation.value;
              final currentColor = Color.lerp(
                activeColor.withOpacity(0.3), 
                orangeColor, 
                progress
              )!;
              
              final currentScale = 1.0 + (math.sin(progress * math.pi) * 0.2); // Bouncy scale
              
              return Transform.scale(
                scale: currentScale,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: progress > 0.1 ? currentColor : Colors.transparent,
                    border: Border.all(
                      color: progress > 0.1 ? currentColor : activeColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withOpacity(0.4 * progress),
                        blurRadius: 8 + (4 * progress),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: _checkScaleAnimation.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _checkScaleAnimation.value,
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        else if (isPastEmpty)
           // Past but MISSED/Empty
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05), // Faint fill
              border: Border.all(
                color: Colors.white.withOpacity(0.1), // Faint outline
                width: 1,
              ),
            ),
             child: Icon(
              Icons.close_rounded, // Optional: Show X or just empty
              color: Colors.white.withOpacity(0.1),
              size: 16,
            ),
          )
        else
          // Future State
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withOpacity(0.5), // Blue Glow Outline
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHolographicCard(Color primary, Color secondary) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shimmerController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _HolographicCardPainter(
            pulseValue: _pulseController.value,
            shimmerValue: _shimmerController.value,
            primaryColor: primary,
            secondaryColor: secondary,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              // Fallback/Base decoration
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroIcon(Color primary, Color secondary) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbit 1 (X-Axis dominant)
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateX(_orbitController.value * 2 * math.pi)
                  ..rotateY(_orbitController.value * math.pi * 0.5)
                  ..rotateZ(math.pi / 6),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(color: primary.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                ),
              );
            },
          ),
          // Orbit 2 (Y-Axis dominant)
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateY(_orbitController.value * 2 * math.pi) // Counter rotation
                  ..rotateX(_orbitController.value * math.pi * 0.3)
                  ..rotateZ(-math.pi / 6),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: secondary.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(color: secondary.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                ),
              );
            },
          ),
          // Inner Flame & Text
          AnimatedBuilder(
            animation: _flameController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_flameController.value * 0.05), // Subtle breathing
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primary.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Using Icon as flame placeholder
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 40,
                        color: primary,
                        shadows: [
                          Shadow(color: primary, blurRadius: 15),
                        ],
                      ),
                      Text(
                        "${widget.streakData.currentStreak}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Text(
                        "Gün",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Color primary, Color secondary) {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        Navigator.of(context).pop();
      },
      onTapCancel: () => _buttonController.reverse(),
      child: AnimatedBuilder(
        animation: _buttonController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _buttonScaleAnimation,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    // Dynamic glow on press could be added here
                    primary.withOpacity(0.8),
                    secondary.withOpacity(0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.5 + (_buttonController.value * 0.3)), // Glow up on press
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Devam Et",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom Painter for the Tech/Circuit Card Background
class _HolographicCardPainter extends CustomPainter {
  final double pulseValue;
  final double shimmerValue;
  final Color primaryColor;
  final Color secondaryColor;

  _HolographicCardPainter({
    required this.pulseValue,
    required this.shimmerValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint();

    // 1. Background Fill (Dark Tech Blue)
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0F172A).withOpacity(0.9), // Dark slate
        const Color(0xFF1E293B).withOpacity(0.95),
      ],
    ).createShader(rect);

    // Chamfered Corners (Tech Shape)
    final path = Path()
      ..moveTo(20, 0)
      ..lineTo(size.width - 20, 0)
      ..lineTo(size.width, 20)
      ..lineTo(size.width, size.height - 20)
      ..lineTo(size.width - 20, size.height)
      ..lineTo(20, size.height)
      ..lineTo(0, size.height - 20)
      ..lineTo(0, 20)
      ..close();

    canvas.drawPath(path, paint);

    // 2. Circuit Shimmer Effect
    // Create a gradient that moves horizontally
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          primaryColor.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(shimmerValue * math.pi * 2), // Rotate or Translate?
        // Actually, we want translation. Let's use matrix logic if GradientRotation isn't enough.
        // Simplified: just pulse opacity for now or use alignment
      ).createShader(rect);
    
    // Better Shimmer: Draw lines
    canvas.save();
    canvas.clipPath(path);
    final linePaint = Paint()
      ..color = primaryColor.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Grid pattern
    const step = 30.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
    
    // Moving shimmer highlight bar
    final highlightX = size.width * ((shimmerValue * 2) % 2 - 0.5); // Moves -0.5 to 1.5
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, primaryColor.withOpacity(0.2), Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(highlightX - 50, 0, 100, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), highlightPaint);
    canvas.restore();


    // 3. Neon Border (Breathing)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryColor, secondaryColor],
      ).createShader(rect);

    // Glow Shadow
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 + (pulseValue * 4) // Breathing width
      ..color = primaryColor.withOpacity(0.3 + (pulseValue * 0.3)) // Breathing opacity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, borderPaint);
    
    // 4. Tech Accents (Corner brackets)
    final accentPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    // Top-Left Bracket
    canvas.drawPath(
      Path()..moveTo(0, 40)..lineTo(0, 20)..lineTo(20, 0)..lineTo(40, 0), 
      accentPaint
    );
    // Bottom-Right Bracket
    canvas.drawPath(
      Path()..moveTo(size.width, size.height - 40)..lineTo(size.width, size.height - 20)..lineTo(size.width - 20, size.height)..lineTo(size.width - 40, size.height), 
      accentPaint
    );
  }

  @override
  bool shouldRepaint(covariant _HolographicCardPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.shimmerValue != shimmerValue;
  }
}

