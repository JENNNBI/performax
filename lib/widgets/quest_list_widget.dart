import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/quest.dart';
import '../services/quest_celebration_coordinator.dart';

/// Quest list widget with tabs for Daily/Weekly/Monthly quests
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
    final theme = Theme.of(context);
    
    // NO FIXED WIDTH - width determined by Positioned left/right constraints
    // NO MAX HEIGHT - height determined by Positioned top/bottom constraints
    // This allows the window to fill the available space defined by parent

    return Container(
      // Width and height determined by Positioned left/right/top/bottom constraints
      // Must fill available space to prevent collapse
      width: double.infinity, // Fill available width
      height: double.infinity, // Fill available height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max, // Changed from min to max to fill space
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Görevler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Günlük'),
                Tab(text: 'Haftalık'),
                Tab(text: 'Aylık'),
              ],
            ),
          ),

          // Tab content - Flexible to fill available height (scrollable within limited space)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestList(widget.questData.dailyQuests, theme),
                _buildQuestList(widget.questData.weeklyQuests, theme),
                _buildQuestList(widget.questData.monthlyQuests, theme),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildQuestList(List<Quest> quests, ThemeData theme) {
    final sorted = [...quests];
    sorted.sort((a, b) {
      final ac = a.isCompleted ? 1 : 0;
      final bc = b.isCompleted ? 1 : 0;
      return ac.compareTo(bc);
    });
    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: theme.primaryColor, size: 36),
              const SizedBox(height: 12),
              const Text(
                'Harika! Bu bölümde tüm görevler tamamlandı.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Diğer sekmelere geçerek haftalık ve aylık görevlere bakabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final quest = sorted[index];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _QuestCard(key: ValueKey(quest.id), quest: quest, theme: theme)
              .animate(delay: (index * 80).ms)
              .fadeIn(duration: 250.ms)
              .slideX(
                begin: 0.15,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOut,
              ),
        );
      },
    );
  }
}

/// Individual quest card with progress bar
class _QuestCard extends StatelessWidget {
  final Quest quest;
  final ThemeData theme;

  const _QuestCard({
    super.key,
    required this.quest,
    required this.theme,
  });


  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;
    final isClaimable = quest.isClaimable;

    return GestureDetector(
      onTap: isClaimable ? () => QuestCelebrationCoordinator.instance.claimQuest(quest) : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green
              : isClaimable
                  ? const Color(0xFFFFD700)
                  : Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isClaimable ? const Color(0xFFFFA500).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
            blurRadius: isClaimable ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isClaimable)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFA500).withValues(alpha: 0.35), blurRadius: 8),
                    ],
                  ),
                  child: const Text(
                    'Claim!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            // Title and description - MAXIMUM space allocation (GREEN FRAME LOGOS REMOVED)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.black87,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 6),
                Text(
                  quest.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar with prominent rocket logo at trailing end
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress text only (percentage REMOVED)
                Text(
                  quest.progressText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green : theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                // Progress bar with prominent rocket logo at trailing end
                Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: quest.progressPercentage,
                        backgroundColor: Colors.grey.withValues(alpha: 0.3), // More visible background
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? Colors.green : theme.primaryColor,
                        ),
                        minHeight: 10, // Increased from 8 for better visibility
                      ),
                    ),
                    // Rocket logo at trailing end (far right tip) - TOP LAYER, PROMINENT
                    Positioned(
                      right: -2,
                      child: Container(
                        key: _registerAndGetKey(context, quest.id),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/currency_rocket1.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.rocket_launch_rounded,
                                    color: Colors.orange,
                                    size: 22,
                                  );
                                },
                              ),
                              Positioned(
                                top: -12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${quest.reward}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Completed badge
            if (isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tamamlandı!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ));
  }
  GlobalKey _registerAndGetKey(BuildContext context, String id) {
    final key = GlobalKey();
    QuestCelebrationCoordinator.instance.registerQuestRocketKey(id, key);
    return key;
  }
}
