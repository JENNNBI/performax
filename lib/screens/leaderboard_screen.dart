import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';
import '../services/leaderboard_service.dart';
import '../services/user_service.dart';
import '../services/user_provider.dart'; // Import Provider
import 'package:provider/provider.dart'; // Import Provider
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToUser();
    });
  }

  void scrollToUser() {
    // We will scroll to the user in the "others" list
    // This requires us to know the list structure, which depends on the provider state.
    // We'll handle this in the build method or after first frame.
    // For now, let's leave it as best effort.
  }

  @override
  Widget build(BuildContext context) {
    // Watch UserProvider for immediate updates
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = UserService.instance.currentUserProfile;

    // Generate Leaderboard Data
    // We pass a modified UserProfile that reflects the Provider's current state
    // This ensures the leaderboard generation logic sees the updated score/rank
    final syncUser = userProfile?.copyWith(
      leaderboardScore: userProvider.score,
    );
    
    // However, LeaderboardService generates the list.
    // Let's modify the service call or post-process the list.
    // Better: Update the 'isCurrentUser' entry in the list with Provider data.
    
    var entries = syncUser != null 
        ? LeaderboardService.instance.getLeaderboard(syncUser) 
        : <LeaderboardEntry>[];
    
    // FIX: Override Current User Entry with Provider Data
    // This ensures the avatar and score are 100% in sync with the Home Screen
    final userIndex = entries.indexWhere((e) => e.isCurrentUser);
    if (userIndex != -1) {
      entries[userIndex] = entries[userIndex].copyWith(
        points: userProvider.score,
        rank: userProvider.rank,
        avatar: userProvider.currentAvatarPath, // Use provider's avatar path
      );
    }

    // Extract Top 3 for Podium
    final top3 = entries.take(3).toList();
    // Rest of the list
    final others = entries.skip(3).toList();
    
    final bgColor = NeumorphicColors.getBackground(context);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // Podium Section
            _buildPodium(context, top3),
            
            const SizedBox(height: 20),
            
            // List Section
            Expanded(
              child: ScrollablePositionedList.builder(
                itemScrollController: _itemScrollController,
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: others.length,
                itemBuilder: (context, index) {
                  final entry = others[index];
                  return _buildListItem(context, entry);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> top3) {
    if (top3.length < 3) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rank 2 (Left)
        _buildPodiumStep(context, top3[1], height: 160, color: const Color(0xFFC0C0C0), crown: false),
        const SizedBox(width: 16),
        // Rank 1 (Center)
        _buildPodiumStep(context, top3[0], height: 200, color: const Color(0xFFFFD700), crown: true),
        const SizedBox(width: 16),
        // Rank 3 (Right)
        _buildPodiumStep(context, top3[2], height: 130, color: const Color(0xFFCD7F32), crown: false),
      ],
    );
  }

  Widget _buildPodiumStep(BuildContext context, LeaderboardEntry entry, {required double height, required Color color, required bool crown}) {
    final textColor = NeumorphicColors.getText(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar with Headshot Logic
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            NeumorphicContainer(
              padding: const EdgeInsets.all(4),
              shape: BoxShape.circle,
              depth: 4,
              child: Container(
                width: 48, // Radius 24 * 2
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                  image: entry.avatar != null 
                      ? DecorationImage(
                          image: AssetImage(entry.avatar!),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        )
                      : null,
                ),
                child: entry.avatar == null ? Icon(Icons.person, color: color) : null,
              ),
            ),
            if (crown)
              const Positioned(
                top: -24,
                child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 32),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          entry.name.split(' ')[0], // First Name only
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          "${entry.points} P",
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        // Bar (Podium Block)
        NeumorphicContainer(
          width: 80,
          height: height,
          borderRadius: 16,
          color: color.withValues(alpha: 0.2),
          depth: 4,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                "${entry.rank}",
                style: TextStyle(
                  color: color,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, LeaderboardEntry entry) {
    final textColor = NeumorphicColors.getText(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: NeumorphicButton(
        onPressed: () {}, // Could show user profile
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        color: entry.isCurrentUser ? NeumorphicColors.accentBlue.withValues(alpha: 0.1) : null,
        child: Row(
          children: [
            // Rank - Fixed width to prevent wrapping
            SizedBox(
              width: 50,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "${entry.rank}",
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Avatar with Headshot Logic
            NeumorphicContainer(
              padding: const EdgeInsets.all(2), // Reduced padding
              shape: BoxShape.circle,
              depth: 2,
              child: Container(
                width: 36, 
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: entry.avatar != null 
                      ? DecorationImage(
                          image: AssetImage(entry.avatar!),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter, // Headshot Crop
                        )
                      : null,
                ),
                child: entry.avatar == null 
                    ? Icon(Icons.person, color: textColor.withValues(alpha: 0.5), size: 20)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: TextStyle(
                      color: entry.isCurrentUser ? NeumorphicColors.accentBlue : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    entry.grade,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${entry.points} P",
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
