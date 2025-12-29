import 'package:flutter/material.dart';
import '../blocs/bloc_exports.dart';
import '../utils/app_icons.dart';
import '../screens/home_screen.dart';

/// Persistent Bottom Navigation Widget
/// Can be used across different screens to maintain navigation persistence
/// Automatically hides on immersive screens (test/video/placeholder)
class PersistentBottomNav extends StatelessWidget {
  const PersistentBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavVisibilityBloc, BottomNavVisibilityState>(
      builder: (context, state) {
        // If not visible, return null (no bottom nav)
        if (!state.isVisible) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final languageBloc = context.read<LanguageBloc>();
        final isEnglish = languageBloc.currentLanguage == 'en';

        return Container(
          height: 75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor.withValues(alpha: 0.95),
                theme.primaryColor.withValues(alpha: 0.85),
                const Color(0xFF667eea).withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, -3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                iconAsset: 'assets/images/konu_anlatim.png',
                label: isEnglish ? 'Profile' : 'Profil',
                index: 0,
                theme: theme,
              ),
              _buildNavItem(
                context: context,
                iconAsset: 'assets/images/soru_cozum.png',
                label: isEnglish ? 'Courses' : 'Dersler',
                index: 1,
                theme: theme,
              ),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(
                context: context,
                iconAsset: 'assets/images/pdf.png',
                label: 'PDF',
                index: 2,
                theme: theme,
              ),
              _buildNavItem(
                context: context,
                iconAsset: 'assets/images/istatistik.png',
                label: isEnglish ? 'Stats' : 'İstatistik',
                index: 3,
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String iconAsset,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    // Since we're on a different screen, we can't rely on HomeScreen's selected index
    // All items shown as unselected, tapping will navigate back to HomeScreen with that tab

    return Expanded(
      child: InkWell(
        onTap: () => _navigateToHomeScreen(context, index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                child: Image.asset(
                  iconAsset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.circle,
                      size: 28,
                      color: Colors.white70,
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate back to HomeScreen with the selected tab
  void _navigateToHomeScreen(BuildContext context, int tabIndex) {
    // Pop until we reach HomeScreen
    Navigator.of(context).popUntil((route) {
      // Check if the current route is the HomeScreen
      return route.settings.name == HomeScreen.id || route.isFirst;
    });

    // Note: You would need to add a mechanism to select the tab
    // This could be done via a global key or by passing data through navigation
  }
}

/// Persistent FAB for QR Scanner
/// Matches the HomeScreen's floating action button
class PersistentQRFAB extends StatelessWidget {
  const PersistentQRFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavVisibilityBloc, BottomNavVisibilityState>(
      builder: (context, state) {
        // If bottom nav not visible, don't show FAB either
        if (!state.isVisible) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);

        return GestureDetector(
          onTap: () {
            // Import and navigate to QR scanner
            // Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('QR Scanner - Navigate back to home to use'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: AppIcons.floatingIcon(
            AppIcons.qrScanner,
            size: 28,
            color: theme.primaryColor,
            isActive: true,
          ),
        );
      },
    );
  }
}

