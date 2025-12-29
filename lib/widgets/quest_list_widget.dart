import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/quest.dart';
import '../services/quest_celebration_coordinator.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Quest list widget with tabs for Daily/Weekly/Monthly quests
/// Redesigned to match "Dark Neumorphic/Futuristic" theme
class QuestListWidget extends StatefulWidget {
  final QuestData questData;
  final VoidCallback onClose;

  const QuestListWidget({
    super.key,
    required this.questData,
    required this.onClose,
  });

  @override
  State<QuestListWidget> createState() => _QuestListWidgetState();
}

class _QuestListWidgetState extends State<QuestListWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark Futuristic Theme Colors
    const modalBgColor = Color(0xFF2B2E35);
    const accentColor = NeumorphicColors.accentBlue;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: modalBgColor.withValues(alpha: 0.95), // Dark Matte Grey
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 🎨 TROPHY ICON - Fixed Light Mode Glare
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    // 🎯 LIGHT MODE FIX: Subtle shadow instead of intense glow
                    boxShadow: isDarkMode 
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Görevler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // 🎨 CLOSE BUTTON - Fixed Light Mode Glare
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    // 🎯 LIGHT MODE FIX: Subtle shadow instead of intense glow
                    boxShadow: isDarkMode
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                  ),
                  child: IconButton(
                    onPressed: widget.onClose,
                    padding: const EdgeInsets.all(8),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Neumorphic Segmented Control (Tabs)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Günlük'),
                Tab(text: 'Haftalık'),
                Tab(text: 'Aylık'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestList(widget.questData.dailyQuests),
                _buildQuestList(widget.questData.weeklyQuests),
                _buildQuestList(widget.questData.monthlyQuests),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildQuestList(List<Quest> quests) {
    // 🎯 REFINED SORT LOGIC - UX Fix for Registration Flow
    // Priority Order:
    // 1. TOP: Completed & Unclaimed (ready to collect reward) ⭐
    // 2. MIDDLE: In Progress (active quests)
    // 3. BOTTOM: Completed & Claimed (done and dusted)
    final sorted = [...quests];
    sorted.sort((a, b) {
      // Calculate priority scores (lower = higher priority = top of list)
      int aPriority;
      int bPriority;
      
      if (a.completed && !a.claimed) {
        aPriority = 0; // 🎯 HIGHEST PRIORITY - Ready to claim!
      } else if (!a.completed) {
        aPriority = 1; // MEDIUM PRIORITY - In progress
      } else {
        aPriority = 2; // LOWEST PRIORITY - Claimed/done
      }
      
      if (b.completed && !b.claimed) {
        bPriority = 0; // 🎯 HIGHEST PRIORITY - Ready to claim!
      } else if (!b.completed) {
        bPriority = 1; // MEDIUM PRIORITY - In progress
      } else {
        bPriority = 2; // LOWEST PRIORITY - Claimed/done
      }
      
      return aPriority.compareTo(bPriority);
    });

    if (sorted.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white.withValues(alpha: 0.3), size: 48),
            const SizedBox(height: 16),
            Text(
              'Tüm görevler tamamlandı!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final quest = sorted[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _QuestCard(key: ValueKey(quest.id), quest: quest)
              .animate(delay: (index * 50).ms)
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut),
        );
      },
    );
  }
}

/// Individual quest card with Dark Neumorphic style
class _QuestCard extends StatelessWidget {
  final Quest quest;

  const _QuestCard({
    super.key,
    required this.quest,
  });

  @override
  Widget build(BuildContext context) {
    // 🎯 VISUAL STATE LOGIC FIX
    // We need to check the actual completed and claimed flags separately
    // NOT use the isCompleted getter which returns claimed status
    final isReadyToClaim = quest.isClaimable; // progress >= target && !claimed
    final isFullyDone = quest.claimed; // Reward already claimed
    
    // Create a GlobalKey to track the claim button position
    final GlobalKey buttonKey = GlobalKey();
    
    // Card Colors
    final cardColor = const Color(0xFF353941);
    final borderColor = isReadyToClaim 
        ? const Color(0xFFFFD700) // Golden border for claimable quests
        : (isFullyDone ? Colors.green : Colors.white.withValues(alpha: 0.1));

    return GestureDetector(
      onTap: isReadyToClaim ? () => QuestCelebrationCoordinator.instance.claimQuest(quest, buttonKey) : null,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor.withValues(alpha: isReadyToClaim ? 1.0 : 0.5),
            width: isReadyToClaim ? 1.5 : 1,
          ),
          boxShadow: [
            // Convex Shadow Effect
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
            if (isReadyToClaim)
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Reward
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            // 🎯 FIX: Only cross out if CLAIMED, not just completed
                            color: isFullyDone ? Colors.greenAccent : Colors.white,
                            decoration: isFullyDone ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quest.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Reward Pill
                  // 🎯 FIX: Show reward pill if NOT claimed yet
                  if (!isFullyDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/currency_rocket1.png',
                            width: 16,
                            height: 16,
                            errorBuilder: (_, __, ___) => const Icon(Icons.rocket, color: Colors.orange, size: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${quest.reward}',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Section
              // 🎯 FIX: Show claim button if ready to claim (completed but not claimed)
              if (isReadyToClaim)
                Align(
                  alignment: Alignment.centerRight,
                  child: NeumorphicButton(
                    key: buttonKey,
                    onPressed: () => QuestCelebrationCoordinator.instance.claimQuest(quest, buttonKey),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    borderRadius: 20,
                    color: const Color(0xFFFFD700),
                    child: const Text(
                      'Ödülü Al!',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              // 🎯 FIX: Show progress bar if NOT ready to claim and NOT fully done
              else if (!isFullyDone && !isReadyToClaim)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          quest.progressText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: NeumorphicColors.accentBlue,
                          ),
                        ),
                        Text(
                          '${(quest.progressPercentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Glowing Gradient Progress Bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: quest.progressPercentage.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFA500).withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // 🎯 FIX: Completed State (Claimed) - only show if fully done
                Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Tamamlandı',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
