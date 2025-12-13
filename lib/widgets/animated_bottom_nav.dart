import 'package:flutter/material.dart';
import '../utils/app_icons.dart';

/// Modern animated bottom navigation bar with glowing indicator
class AnimatedBottomNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Color? primaryColor;
  
  const AnimatedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.primaryColor,
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<_NavItem> _items = [
    _NavItem(icon: AppIcons.videoLessons, label: 'Videolar'),
    _NavItem(icon: AppIcons.practiceVideos, label: 'Soru Çözüm'),
    _NavItem(icon: Icons.book, label: 'PDF'),
    _NavItem(icon: AppIcons.statistics, label: 'İstatistik'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _animations = _controllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    }).toList();

    // Animate the initially selected item
    _controllers[widget.selectedIndex].forward();
  }

  @override
  void didUpdateWidget(AnimatedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controllers[oldWidget.selectedIndex].reverse();
      _controllers[widget.selectedIndex].forward();
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
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      elevation: 8.0,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length + 1, (index) {
            // Add space for center FAB
            if (index == 2) {
              return const SizedBox(width: 20);
            }
            final itemIndex = index > 2 ? index - 1 : index;
            return _buildNavItem(
              item: _items[itemIndex],
              index: itemIndex,
              isSelected: widget.selectedIndex == itemIndex,
              animation: _animations[itemIndex],
              primaryColor: primaryColor,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required _NavItem item,
    required int index,
    required bool isSelected,
    required Animation<double> animation,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon with scale and glow
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect
                    if (isSelected)
                      Container(
                        width: 40 + (animation.value * 10),
                        height: 40 + (animation.value * 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.3 * animation.value),
                              primaryColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    // Icon
                    Transform.scale(
                      scale: 1.0 + (animation.value * 0.2),
                      child: isSelected
                          ? AppIcons.threeDIcon(
                              item.icon,
                              size: 28,
                              primaryColor: primaryColor,
                            )
                          : Icon(
                              item.icon,
                              color: Colors.grey,
                              size: 28,
                            ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 4),
            
            // Animated indicator line
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  height: 3,
                  width: 30 * animation.value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: animation.value),
                        primaryColor.withValues(alpha: 0.5 * animation.value),
                      ],
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.5 * animation.value),
                              blurRadius: 8 * animation.value,
                              spreadRadius: 1 * animation.value,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}

