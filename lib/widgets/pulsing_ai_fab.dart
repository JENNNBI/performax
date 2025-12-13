import 'package:flutter/material.dart';

/// Glowing, pulsing AI Assistant FAB with expand/collapse animation
class PulsingAIFAB extends StatefulWidget {
  final VoidCallback onTap;
  final bool isExpanded;
  
  const PulsingAIFAB({
    super.key,
    required this.onTap,
    this.isExpanded = false,
  });

  @override
  State<PulsingAIFAB> createState() => _PulsingAIFABState();
}

class _PulsingAIFABState extends State<PulsingAIFAB> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation - size changes
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow animation - opacity and blur changes
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Rotation animation for icon
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation, _rotationAnimation]),
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Outer glow
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.4 * _glowAnimation.value),
                  blurRadius: 25 * _glowAnimation.value,
                  spreadRadius: 5 * _glowAnimation.value,
                ),
                // Inner glow
                BoxShadow(
                  color: const Color(0xFF764ba2).withValues(alpha: 0.3 * _glowAnimation.value),
                  blurRadius: 15 * _glowAnimation.value,
                  spreadRadius: 2 * _glowAnimation.value,
                  offset: const Offset(0, 2),
                ),
                // Pulsing ring
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2 * _pulseAnimation.value),
                  blurRadius: 30 * _pulseAnimation.value,
                  spreadRadius: 8 * _pulseAnimation.value,
                ),
              ],
            ),
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated background effect
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.3 * _glowAnimation.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          
                          // Rotating subtle ring
                          Transform.rotate(
                            angle: _rotationAnimation.value * 2 * 3.14159,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          
                          // AI Icon with subtle animation
                          Transform.rotate(
                            angle: _rotationAnimation.value * 0.1,
                            child: const Icon(
                              Icons.psychology,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          
                          // Sparkle effects
                          ..._buildSparkles(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSparkles() {
    return [
      Positioned(
        top: 8,
        right: 12,
        child: _buildSparkle(0.9, 8, _glowAnimation.value),
      ),
      Positioned(
        bottom: 12,
        left: 10,
        child: _buildSparkle(0.7, 6, 1.0 - _glowAnimation.value),
      ),
      Positioned(
        top: 18,
        left: 8,
        child: _buildSparkle(0.8, 5, _pulseAnimation.value - 1.0),
      ),
    ];
  }

  Widget _buildSparkle(double opacity, double size, double intensity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity * intensity.abs()),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5 * intensity.abs()),
            blurRadius: 4 * intensity.abs(),
            spreadRadius: 1 * intensity.abs(),
          ),
        ],
      ),
    );
  }
}

