import 'package:flutter/material.dart';
import '../models/avatar.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../services/user_provider.dart'; // Import UserProvider

class AvatarSelectionScreen extends StatefulWidget {
  final String userGender;
  final String? currentAvatarId;

  const AvatarSelectionScreen({
    super.key,
    required this.userGender,
    this.currentAvatarId,
  });

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  late PageController _pageController;
  int _currentPage = 1000; // Start in the middle for infinite illusion
  late List<Avatar> _availableAvatars;

  @override
  void initState() {
    super.initState();
    _availableAvatars = Avatar.getByGender(widget.userGender);
    if (_availableAvatars.isEmpty) {
       _availableAvatars = Avatar.allAvatars; // Fallback
    }

    // Determine initial page based on currentAvatarId or default to middle
    int initialIndex = 0;
    if (widget.currentAvatarId != null) {
      initialIndex = _availableAvatars.indexWhere((a) => a.id == widget.currentAvatarId);
      if (initialIndex == -1) initialIndex = 0;
    }
    
    // Set a large starting page index that matches the modulo of the selected avatar
    // Ensure we start at a clean multiple + offset
    _currentPage = 1000 * _availableAvatars.length + initialIndex;

    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.65,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _confirmSelection() async {
    // Calculate actual index from infinite page index
    final actualIndex = _currentPage % _availableAvatars.length;
    final selectedAvatar = _availableAvatars[actualIndex];

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🎨 AvatarSelection: User confirmed selection');
    debugPrint('   Selected Avatar: ${selectedAvatar.displayName}');
    debugPrint('   ID: ${selectedAvatar.id}');
    debugPrint('   Path: ${selectedAvatar.bust2DPath}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // 💾 Save to UserProvider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Save avatar (will persist to disk if userId available, otherwise RAM only)
      await userProvider.saveAvatar(
        selectedAvatar.bust2DPath, 
        selectedAvatar.id,
      );

      if (userProvider.currentUserId != null) {
        debugPrint('✅ Avatar saved to disk with userId: ${userProvider.currentUserId}');
      } else {
        debugPrint('✅ Avatar saved to RAM (will persist when registration completes)');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (mounted) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar "${selectedAvatar.displayName}" selected!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Return to previous screen
        Navigator.pop(context, selectedAvatar.id);
      }
    } catch (e) {
      debugPrint('❌ Unexpected error in avatar selection: $e');
      // Even on error, still return the selected ID
      if (mounted) {
        Navigator.pop(context, selectedAvatar.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualIndex = _currentPage % _availableAvatars.length;
    final currentAvatar = _availableAvatars[actualIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor.withValues(alpha: 0.1),
                  Colors.white,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Choose Your Character',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Live Preview Area (Headshot Cropping)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          key: ValueKey(currentAvatar.id), // Animate on change
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[100],
                            border: Border.all(
                              color: theme.primaryColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                            image: DecorationImage(
                              image: AssetImage(currentAvatar.bust2DPath),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter, // Headshot Focus
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 3D Infinite Carousel
                SizedBox(
                  height: 340, // Reduced from 400 to prevent overflow
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    // Use a large number for "infinite" feel
                    itemCount: 100000, 
                    itemBuilder: (context, index) {
                      final avatarIndex = index % _availableAvatars.length;
                      final avatar = _availableAvatars[avatarIndex];
                      
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          // Calculate relative position of this item
                          // Default to 0.0 if controller not ready
                          double page = 0.0;
                          try {
                            page = _pageController.page ?? _currentPage.toDouble();
                          } catch (_) {
                            page = _currentPage.toDouble();
                          }
                          
                          // Difference between this item's index and current scroll position
                          double diff = (index - page);
                          
                          // Clamp diff for safety (though not strictly needed with logic below)
                          // We care about items close to center (-1, 0, 1)
                          
                          // Animation Values
                          // Scale: 1.0 at center, 0.8 at sides
                          double scale = 1.0 - (diff.abs() * 0.2).clamp(0.0, 0.2);
                          
                          // Opacity: 1.0 at center, 0.5 at sides
                          double opacity = 1.0 - (diff.abs() * 0.5).clamp(0.0, 0.5);
                          
                          // Y-Rotation / Perspective (Simple matrix transform)
                          // Rotate slightly away from center
                          double rotationY = diff * -0.2; // Radians
                          
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // Perspective
                              ..rotateY(rotationY)
                              ..scale(scale),
                            alignment: Alignment.center,
                            child: Opacity(
                              opacity: opacity,
                              child: child,
                            ),
                          );
                        },
                        child: _buildAvatarItem(avatar),
                      );
                    },
                  ),
                ),

                const Spacer(),

                // Selected Avatar Info
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(currentAvatar.id),
                    children: [
                      Text(
                        currentAvatar.displayName,
                        style: const TextStyle(
                          fontSize: 20, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Reduced padding
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentAvatar.skinTone} • ${currentAvatar.hairStyle}',
                          style: TextStyle(
                            fontSize: 12, // Reduced font size
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20), // Reduced spacing

                // Confirm Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0), // Reduced vertical padding
                  child: SizedBox(
                    width: double.infinity,
                    height: 50, // Reduced height
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'Select Character',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarItem(Avatar avatar) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background decoration
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.8,
                    colors: [
                      Colors.grey[100]!,
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            
            // Avatar Image
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  avatar.bust2DPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 80, color: Colors.grey);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

