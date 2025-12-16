import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/quest.dart';

/// Service to manage quest data loading and updates
class QuestService {
  static const String _questDataPath = 'assets/data/quests.json';
  static final QuestService instance = QuestService._internal();
  QuestService._internal();
  factory QuestService() => instance;
  
  QuestData? _cachedQuestData;
  final StreamController<QuestData> _controller = StreamController<QuestData>.broadcast();

  Stream<QuestData> get stream => _controller.stream;
  QuestData? get data => _cachedQuestData;

  /// Load quest data from JSON asset
  Future<QuestData> loadQuests() async {
    try {
      // Return cached data if available
      if (_cachedQuestData != null) {
        return _cachedQuestData!;
      }

      // Load JSON file
      final String jsonString = await rootBundle.loadString(_questDataPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Parse and cache quest data
      _cachedQuestData = QuestData.fromJson(jsonData);
      _controller.add(_cachedQuestData!);
      
      return _cachedQuestData!;
    } catch (e) {
      throw Exception('Failed to load quest data: $e');
    }
  }

  /// Update quest progress
  Future<Quest> updateQuestProgress(Quest quest, int newProgress) async {
    final updatedQuest = quest.copyWith(
      progress: newProgress,
      completed: newProgress >= quest.target,
    );

    // In a real app, you would save this to a database or shared preferences
    // For now, we just return the updated quest
    
    return updatedQuest;
  }

  /// Mark quest as completed
  Future<Quest> completeQuest(Quest quest) async {
    return quest.copyWith(completed: true, progress: quest.target);
  }

  /// Reset quest progress
  Future<Quest> resetQuest(Quest quest) async {
    return quest.copyWith(completed: false, progress: 0);
  }

  /// Clear cached data (useful for testing or refreshing)
  void clearCache() {
    _cachedQuestData = null;
  }

  /// Get quest by ID from all quest types
  Quest? getQuestById(QuestData questData, String questId) {
    // Search in daily quests
    try {
      return questData.dailyQuests.firstWhere((q) => q.id == questId);
    } catch (_) {}

    // Search in weekly quests
    try {
      return questData.weeklyQuests.firstWhere((q) => q.id == questId);
    } catch (_) {}

    // Search in monthly quests
    try {
      return questData.monthlyQuests.firstWhere((q) => q.id == questId);
    } catch (_) {}

    return null;
  }

  /// Emit an update to listeners
  void _emit() {
    if (_cachedQuestData != null) {
      _controller.add(_cachedQuestData!);
    }
  }

  /// Increment a quest's progress by ID
  void incrementById(String questId, int delta) {
    if (_cachedQuestData == null) return;
    final q = getQuestById(_cachedQuestData!, questId);
    if (q == null) return;
    final newProgress = (q.progress + delta).clamp(0, q.target);
    final updated = q.copyWith(progress: newProgress, completed: newProgress >= q.target);
    _replaceQuest(updated);
  }

  void _replaceQuest(Quest updated) {
    if (_cachedQuestData == null) return;
    final d = _cachedQuestData!;
    List<Quest> replace(List<Quest> list) =>
        list.map((q) => q.id == updated.id ? updated : q).toList();
    _cachedQuestData = QuestData(
      dailyQuests: replace(d.dailyQuests),
      weeklyQuests: replace(d.weeklyQuests),
      monthlyQuests: replace(d.monthlyQuests),
    );
    _emit();
  }

  /// Reset all quests to zero (test mode)
  void resetAll() {
    if (_cachedQuestData == null) return;
    final d = _cachedQuestData!;
    Quest reset(Quest q) => q.copyWith(progress: 0, completed: false);
    _cachedQuestData = QuestData(
      dailyQuests: d.dailyQuests.map(reset).toList(),
      weeklyQuests: d.weeklyQuests.map(reset).toList(),
      monthlyQuests: d.monthlyQuests.map(reset).toList(),
    );
    _emit();
  }

  /// Event bindings
  void onQuestionAnswered() {
    // Tie to question solving quests (daily/weekly/monthly)
    incrementById('daily_1', 1);
    incrementById('weekly_1', 1);
    incrementById('monthly_1', 1);
  }

  void onPerfectScoreAchieved() {
    // Daily perfect score quest (must exist in JSON)
    incrementById('daily_5', 1);
  }

  void onVideoWatchedSeconds(int seconds) {
    // Convert to minutes for daily video quest (round down)
    final minutes = (seconds ~/ 60);
    if (minutes > 0) {
      incrementById('daily_2', minutes);
    }
  }

  void onPdfStudiedSeconds(int seconds) {
    final minutes = (seconds ~/ 60);
    if (minutes > 0) {
      incrementById('daily_3', minutes);
    }
  }

  void onAiInteracted() {
    incrementById('daily_6', 1);
  }

  void onDailyLogin() {
    incrementById('weekly_4', 1);
    incrementById('monthly_4', 1);
  }
}
