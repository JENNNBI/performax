import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Speech bubble widget that appears next to the avatar
/// Shows quest notification with bounce animation
class QuestSpeechBubble extends StatelessWidget {
  final String message;
  final int pendingCount;
  final VoidCallback? onTap;
  final bool show;

  const QuestSpeechBubble({
    super.key,
    required this.message,
    required this.pendingCount,
    this.onTap,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!show) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        child: CustomPaint(
          painter: _SpeechBubblePainter(
            color: theme.primaryColor,
            tailPosition: _TailPosition.left,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pending_actions,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingCount görev',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 500.ms,
            curve: Curves.elasticOut,
          )
          .then() // Wait for initial animation
          .shake(
            duration: 300.ms,
            hz: 2,
            curve: Curves.easeInOut,
          )
          .then(delay: 2000.ms) // Wait 2 seconds
          .shake(
            duration: 300.ms,
            hz: 2,
            curve: Curves.easeInOut,
          ),
    );
  }
}

/// Animated dismissal of speech bubble with bounce out effect
class DismissSpeechBubble extends StatelessWidget {
  final Widget child;
  final bool dismiss;
  final VoidCallback? onDismissComplete;

  const DismissSpeechBubble({
    super.key,
    required this.child,
    required this.dismiss,
    this.onDismissComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (!dismiss) {
      return child;
    }

    return child
        .animate(onComplete: (controller) => onDismissComplete?.call())
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.0, 0.0),
          duration: 400.ms,
          curve: Curves.easeInBack,
        )
        .fadeOut(duration: 300.ms);
  }
}

/// Custom painter for speech bubble shape with tail
class _SpeechBubblePainter extends CustomPainter {
  final Color color;
  final _TailPosition tailPosition;

  _SpeechBubblePainter({
    required this.color,
    required this.tailPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const radius = 12.0;
    const tailWidth = 12.0;
    const tailHeight = 10.0;

    // Main bubble rounded rectangle
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(radius),
      ),
    );

    // Add tail based on position
    if (tailPosition == _TailPosition.left) {
      // Tail pointing left
      final tailPath = Path();
      tailPath.moveTo(-tailHeight, size.height / 2);
      tailPath.lineTo(0, size.height / 2 - tailWidth / 2);
      tailPath.lineTo(0, size.height / 2 + tailWidth / 2);
      tailPath.close();
      path.addPath(tailPath, Offset.zero);
    }

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.3), 4, true);
    
    // Draw bubble
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpeechBubblePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.tailPosition != tailPosition;
  }
}

enum _TailPosition { left, right, top, bottom }
