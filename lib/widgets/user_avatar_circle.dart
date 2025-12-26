import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../models/avatar.dart';

/// 🎯 UNIFIED AVATAR WIDGET
/// Single source of truth for displaying user's selected avatar across the entire app.
/// 
/// **Displays in 3 critical locations:**
/// 1. Home Screen - Top-right profile icon
/// 2. Drawer - Large header image
/// 3. Profile/Edit Profile - Central profile image
///
/// **Features:**
/// - Listens to UserProvider state changes via Consumer
/// - Displays cropped headshot (Alignment.topCenter)
/// - Falls back to person icon ONLY if no avatar is selected
/// - Handles both avatarPath and avatarId
class UserAvatarCircle extends StatelessWidget {
  final double radius;
  final Color? borderColor;
  final bool showBorder;

  const UserAvatarCircle({
    super.key,
    this.radius = 24,
    this.borderColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final avatarPath = userProvider.currentAvatarPath;
        final avatarId = userProvider.currentAvatarId;
        
        // 🔍 Debug logging to track state
        debugPrint('🎨 UserAvatarCircle Build: Path=$avatarPath, ID=$avatarId');
        
        // Resolve path if only ID is available
        String? finalPath = avatarPath;
        if (finalPath == null && avatarId != null) {
          try {
            final avatar = Avatar.getById(avatarId);
            finalPath = avatar.bust2DPath;
            debugPrint('✅ Resolved avatar path from ID: $finalPath');
          } catch (e) {
            debugPrint('❌ Failed to resolve avatar from ID $avatarId: $e');
          }
        }
        
        // 🎯 CRITICAL: Only show fallback icon if truly no avatar
        final hasAvatar = finalPath != null && finalPath.isNotEmpty;
        
        if (hasAvatar) {
          debugPrint('✅ Displaying avatar: $finalPath');
        } else {
          debugPrint('⚠️ No avatar found, showing fallback icon');
        }

        // 🎨 Build the avatar container
        Widget avatarWidget = Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B), // Dark background for transparency
            border: showBorder ? Border.all(
              color: borderColor ?? Colors.cyanAccent.withOpacity(0.5),
              width: 2,
            ) : null,
            image: hasAvatar
                ? DecorationImage(
                    image: AssetImage(finalPath!),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter, // 🎯 CRITICAL: Headshot cropping
                    onError: (exception, stackTrace) {
                      debugPrint('❌ Error loading avatar image: $exception');
                    },
                  )
                : null,
            boxShadow: showBorder ? [
              BoxShadow(
                color: (borderColor ?? Colors.cyanAccent).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ] : [],
          ),
          child: !hasAvatar
              ? Icon(
                  Icons.person,
                  size: radius * 1.2,
                  color: Colors.white.withOpacity(0.5),
                )
              : null,
        );
        
        // 🛡️ Wrap with ErrorWidget handler for asset loading failures
        return hasAvatar
            ? Image.asset(
                finalPath!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame == null) {
                    return Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E293B),
                        border: showBorder ? Border.all(
                          color: borderColor ?? Colors.cyanAccent.withOpacity(0.5),
                          width: 2,
                        ) : null,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                        ),
                      ),
                    );
                  }
                  // Clip to circle
                  return ClipOval(
                    child: Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: showBorder ? Border.all(
                          color: borderColor ?? Colors.cyanAccent.withOpacity(0.5),
                          width: 2,
                        ) : null,
                        boxShadow: showBorder ? [
                          BoxShadow(
                            color: (borderColor ?? Colors.cyanAccent).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : [],
                      ),
                      child: child,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ Failed to load avatar asset: $error');
                  // Show fallback icon on error
                  return Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E293B),
                      border: showBorder ? Border.all(
                        color: borderColor ?? Colors.cyanAccent.withOpacity(0.5),
                        width: 2,
                      ) : null,
                    ),
                    child: Icon(
                      Icons.person,
                      size: radius * 1.2,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  );
                },
              )
            : avatarWidget;
      },
    );
  }
}
