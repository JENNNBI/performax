import 'package:equatable/equatable.dart';

/// Quest model representing a daily, weekly, or monthly task
class Quest extends Equatable {
  final String id;
  final String title;
  final String description;
  final int reward;
  final int progress;
  final int target;
  final String icon;
  final String type; // Added type field
  final bool completed;
  final bool claimed;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.progress,
    required this.target,
    required this.icon,
    required this.type, // Added type field
    required this.completed,
    this.claimed = false,
  });

  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (target == 0) return 0.0;
    return (progress / target).clamp(0.0, 1.0);
  }

  /// Check if quest is completed (claimed)
  bool get isCompleted => completed || (claimed && progress >= target);
  /// Ready to be claimed when target reached and not claimed yet
  bool get isClaimable => progress >= target && !claimed && !completed;

  /// Format progress as string (e.g., "5/10")
  String get progressText => '$progress/$target';

  /// Create Quest from JSON
  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String? ?? 'unknown',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      reward: (json['reward'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 1,
      icon: json['icon'] as String? ?? 'help_outline',
      type: json['type'] as String? ?? 'generic', // Added type field with default
      completed: json['completed'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
    );
  }

  /// Convert Quest to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward': reward,
      'progress': progress,
      'target': target,
      'icon': icon,
      'type': type, // Added type field
      'completed': completed,
      'claimed': claimed,
    };
  }

  /// Create a copy with updated fields
  Quest copyWith({
    String? id,
    String? title,
    String? description,
    int? reward,
    int? progress,
    int? target,
    String? icon,
    String? type, // Added type field
    bool? completed,
    bool? claimed,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      icon: icon ?? this.icon,
      type: type ?? this.type, // Added type field
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
    );
  }

  @override
  List<Object?> get props => [id, title, description, reward, progress, target, icon, type, completed, claimed];
}

/// Quest data container for all quest types
class QuestData extends Equatable {
  final List<Quest> dailyQuests;
  final List<Quest> weeklyQuests;
  final List<Quest> monthlyQuests;

  const QuestData({
    required this.dailyQuests,
    required this.weeklyQuests,
    required this.monthlyQuests,
  });

  /// Check if there are any pending (incomplete) quests
  bool get hasPendingQuests {
    return dailyQuests.any((q) => !q.isCompleted) ||
           weeklyQuests.any((q) => !q.isCompleted) ||
           monthlyQuests.any((q) => !q.isCompleted);
  }

  /// Get total number of pending quests
  int get pendingCount {
    return dailyQuests.where((q) => !q.isCompleted).length +
           weeklyQuests.where((q) => !q.isCompleted).length +
           monthlyQuests.where((q) => !q.isCompleted).length;
  }

  /// Create QuestData from JSON
  factory QuestData.fromJson(Map<String, dynamic> json) {
    return QuestData(
      dailyQuests: (json['daily_quests'] as List<dynamic>)
          .map((e) => Quest.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklyQuests: (json['weekly_quests'] as List<dynamic>)
          .map((e) => Quest.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyQuests: (json['monthly_quests'] as List<dynamic>)
          .map((e) => Quest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert QuestData to JSON
  Map<String, dynamic> toJson() {
    return {
      'daily_quests': dailyQuests.map((q) => q.toJson()).toList(),
      'weekly_quests': weeklyQuests.map((q) => q.toJson()).toList(),
      'monthly_quests': monthlyQuests.map((q) => q.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [dailyQuests, weeklyQuests, monthlyQuests];
}
