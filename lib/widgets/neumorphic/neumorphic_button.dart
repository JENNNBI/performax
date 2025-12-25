import 'package:flutter/material.dart';
import 'neumorphic_container.dart';
import '../../theme/neumorphic_colors.dart';

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.color,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _onPointerDown(PointerEvent event) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = false;
      });
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: NeumorphicContainer(
        margin: widget.margin,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        borderRadius: widget.borderRadius,
        isPressed: _isPressed,
        color: widget.color,
        child: widget.child,
      ),
    );
  }
}
