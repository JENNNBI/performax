import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Model class for leaderboard entries
class LeaderboardEntry {
  final int rank;
  final String name;
  final String grade;
  final int points;
  final String? avatar; // Optional image URL or asset path
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.grade,
    required this.points,
    this.avatar,
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<LeaderboardEntry> entries = [
      LeaderboardEntry(rank: 1, name: "Ali Yılmaz", grade: "12. Sınıf", points: 2450, isCurrentUser: false),
      LeaderboardEntry(rank: 2, name: "Zeynep Kaya", grade: "11. Sınıf", points: 2300, isCurrentUser: false),
      LeaderboardEntry(rank: 3, name: "Ahmet Demir", grade: "Mezun", points: 2150, isCurrentUser: false),
      LeaderboardEntry(rank: 4, name: "Selin Şahin", grade: "10. Sınıf", points: 1980, isCurrentUser: false),
      LeaderboardEntry(rank: 5, name: "Can Öztürk", grade: "12. Sınıf", points: 1850, isCurrentUser: true), // Current User
      LeaderboardEntry(rank: 6, name: "Elif Çelik", grade: "9. Sınıf", points: 1720, isCurrentUser: false),
      LeaderboardEntry(rank: 7, name: "Murat Aslan", grade: "11. Sınıf", points: 1650, isCurrentUser: false),
      LeaderboardEntry(rank: 8, name: "Ayşe Yıldız", grade: "Mezun", points: 1540, isCurrentUser: false),
      LeaderboardEntry(rank: 9, name: "Burak Arslan", grade: "12. Sınıf", points: 1420, isCurrentUser: false),
      LeaderboardEntry(rank: 10, name: "Ceren Ak", grade: "10. Sınıf", points: 1300, isCurrentUser: false),
    ];

    // Extract Top 3 for Podium
    final top3 = entries.take(3).toList();
    // Rest of the list
    final others = entries.skip(3).toList();
    
    final bgColor = NeumorphicColors.getBackground(context);
    final textColor = NeumorphicColors.getText(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Text(
                    "Sıralama",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Bu ayın en iyileri",
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Podium Section
            _buildPodium(context, top3),
            
            const SizedBox(height: 30),
            
            // List Section
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 120), // Space for bottom nav
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
        // Avatar
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            NeumorphicContainer(
              padding: const EdgeInsets.all(4),
              shape: BoxShape.circle,
              depth: 4,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(Icons.person, color: color),
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
          // Custom rounded corners only on top
          // Since NeumorphicContainer takes a single borderRadius double, we can't do mixed corners easily
          // unless we modify it or wrap it.
          // Let's use the container but modify it slightly or just accept rounded bottom.
          // Actually, let's keep it fully rounded for soft UI.
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
            // Rank
            SizedBox(
              width: 30,
              child: Text(
                "${entry.rank}",
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Avatar
            NeumorphicContainer(
              padding: const EdgeInsets.all(8),
              shape: BoxShape.circle,
              depth: 2,
              child: Icon(Icons.person, color: textColor.withValues(alpha: 0.5), size: 20),
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
