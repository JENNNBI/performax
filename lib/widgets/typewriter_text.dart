import 'package:flutter/material.dart';

/// Typewriter effect for AI responses
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final VoidCallback? onComplete;
  
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 30),
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _displayedText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration * widget.text.length,
      vsync: this,
    );

    _controller.addListener(() {
      final progress = _controller.value;
      final targetIndex = (progress * widget.text.length).floor();
      
      if (targetIndex != _currentIndex && targetIndex <= widget.text.length) {
        setState(() {
          _currentIndex = targetIndex;
          _displayedText = widget.text.substring(0, _currentIndex);
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _displayedText,
            style: widget.style,
          ),
        ),
        // Cursor
        if (_currentIndex < widget.text.length)
          AnimatedOpacity(
            opacity: (_controller.value * 2) % 1.0 > 0.5 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: 2,
              height: (widget.style?.fontSize ?? 14) * 1.2,
              margin: const EdgeInsets.only(left: 2, top: 2),
              decoration: BoxDecoration(
                color: widget.style?.color ?? Colors.black,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
      ],
    );
  }
}

