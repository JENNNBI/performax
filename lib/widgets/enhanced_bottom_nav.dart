import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';

class EnhancedBottomNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Color primaryColor;

  const EnhancedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.primaryColor,
  });

  @override
  State<EnhancedBottomNav> createState() => _EnhancedBottomNavState();
}

class _EnhancedBottomNavState extends State<EnhancedBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotateAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      );
    }).toList();

    _rotateAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 0.1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -0.15),
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        ),
      );
    }).toList();

    // Start animation for initially selected item
    if (widget.selectedIndex >= 0 && widget.selectedIndex < 4) {
      _controllers[widget.selectedIndex].forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Reverse old selection
      if (oldWidget.selectedIndex >= 0 && oldWidget.selectedIndex < 4) {
        _controllers[oldWidget.selectedIndex].reverse();
      }
      // Forward new selection
      if (widget.selectedIndex >= 0 && widget.selectedIndex < 4) {
        _controllers[widget.selectedIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 16,
      child: Container(
        height: 70, // Increased from 65 to 70 to prevent overflow
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).bottomAppBarTheme.color ?? Colors.white,
              Theme.of(context).bottomAppBarTheme.color?.withValues(alpha: 0.95) ?? 
                  Colors.white.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              iconAsset: 'assets/images/konu_anlatim.png',
              label: 'Konu Anlatımı',
            ),
            _buildNavItem(
              index: 1,
              iconAsset: 'assets/images/soru_cozum.png',
              label: 'Soru Çözümü',
            ),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(
              index: 2,
              iconAsset: 'assets/images/pdf.png',
              label: 'PDF',
            ),
            _buildNavItem(
              index: 3,
              iconAsset: 'assets/images/istatistik1.png',
              label: 'İstatistikler',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconAsset,
    required String label,
  }) {
    final isSelected = widget.selectedIndex == index;

    return AnimatedBuilder(
      animation: _controllers[index],
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimations[index],
          child: Transform.scale(
            scale: _scaleAnimations[index].value,
            child: Transform.rotate(
              angle: _rotateAnimations[index].value,
              child: _NavItemButton(
                isSelected: isSelected,
                primaryColor: widget.primaryColor,
                iconAsset: iconAsset,
                label: label,
                onTap: () {
                  widget.onItemTapped(index);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// Nav Item Button with Press Animation
class _NavItemButton extends StatefulWidget {
  final bool isSelected;
  final Color primaryColor;
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  const _NavItemButton({
    required this.isSelected,
    required this.primaryColor,
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        colors: [
                          widget.primaryColor.withValues(alpha: 0.15),
                          widget.primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark && 
                                 widget.primaryColor == NeumorphicColors.accentBlue
                            ? widget.primaryColor.withValues(alpha: 0.5) // Enhanced opacity for dark mode blue glow
                            : widget.primaryColor.withValues(alpha: 0.3),
                          blurRadius: Theme.of(context).brightness == Brightness.dark && 
                                     widget.primaryColor == NeumorphicColors.accentBlue
                            ? 10.0 // Tighter blur for dark mode blue glow
                            : 12.0,
                          spreadRadius: Theme.of(context).brightness == Brightness.dark && 
                                       widget.primaryColor == NeumorphicColors.accentBlue
                            ? 0.5 // Tighter spread for dark mode blue glow
                            : 2.0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image asset with color filter
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      widget.isSelected
                          ? widget.primaryColor
                          : Colors.grey[600]!,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      widget.iconAsset,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon if asset fails to load
                        return Icon(
                          Icons.error_outline,
                          size: 28,
                          color: widget.isSelected
                              ? widget.primaryColor
                              : Colors.grey[600],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            widget.isSelected ? FontWeight.bold : FontWeight.normal,
                        color: widget.isSelected
                            ? widget.primaryColor
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
