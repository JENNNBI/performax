import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest.dart';

/// Service to manage quest data loading and updates
class QuestService {
  static const String _questDataPath = 'assets/data/quests.json';
  static final QuestService instance = QuestService._internal();
  QuestService._internal();
  factory QuestService() => instance;
  
  QuestData? _cachedQuestData;
  final StreamController<QuestData> _controller = StreamController<QuestData>.broadcast();
  final StreamController<Quest> _completionController = StreamController<Quest>.broadcast();

  Stream<QuestData> get stream => _controller.stream;
  Stream<Quest> get completions => _completionController.stream;
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

      // Parse full quest data
      final fullData = QuestData.fromJson(jsonData);
      final prefs = await SharedPreferences.getInstance();
      final today = _dateString(DateTime.now());
      final lastDate = prefs.getString('quests_last_date');

      final selectedDailyIds = _getIdList(prefs.getString('selected_daily_ids'));
      final selectedWeeklyIds = _getIdList(prefs.getString('selected_weekly_ids'));
      final selectedMonthlyIds = _getIdList(prefs.getString('selected_monthly_ids'));

      if (lastDate == today &&
          selectedDailyIds.isNotEmpty &&
          selectedWeeklyIds.isNotEmpty &&
          selectedMonthlyIds.isNotEmpty) {
        // Same day: load selected IDs and restore saved progress/flags
        final daily = _applySavedStatus(_mapIds(fullData.dailyQuests, selectedDailyIds), prefs);
        final weekly = _applySavedStatus(_mapIds(fullData.weeklyQuests, selectedWeeklyIds), prefs);
        final monthly = _applySavedStatus(_mapIds(fullData.monthlyQuests, selectedMonthlyIds), prefs);
        _cachedQuestData = QuestData(dailyQuests: daily, weeklyQuests: weekly, monthlyQuests: monthly);
      } else {
        // New day: randomize selection, reset progress, persist selection and date
        final daily = _pickRandomAndReset(fullData.dailyQuests, 5);
        final weekly = _pickRandomAndReset(fullData.weeklyQuests, 5);
        final monthly = _pickRandomAndReset(fullData.monthlyQuests, 5);
        _cachedQuestData = QuestData(dailyQuests: daily, weeklyQuests: weekly, monthlyQuests: monthly);
        // Persist selection and zeroed status
        await prefs.setString('selected_daily_ids', json.encode(daily.map((q) => q.id).toList()));
        await prefs.setString('selected_weekly_ids', json.encode(weekly.map((q) => q.id).toList()));
        await prefs.setString('selected_monthly_ids', json.encode(monthly.map((q) => q.id).toList()));
        await prefs.setString('quests_last_date', today);
        // Save initial status for each quest
        for (final q in [...daily, ...weekly, ...monthly]) {
          await _saveQuestStatus(prefs, q);
        }
      }
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
      // Do not auto-complete; manual claim flow handles completion
      completed: quest.completed,
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
    final updated = q.copyWith(progress: newProgress);
    final wasClaimable = q.isClaimable;
    _replaceQuest(updated);
    if (!wasClaimable && updated.isClaimable) {
      // Notify UI to highlight and prompt claim (no particles here)
      _completionController.add(updated);
    }
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
    // Persist status
    SharedPreferences.getInstance().then((prefs) => _saveQuestStatus(prefs, updated));
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
    // Increment across all AI-related quests if present
    _incrementIfExists('daily_6', 1);
    _incrementIfExists('weekly_7', 1);
    _incrementIfExists('monthly_8', 1);
  }

  void onDailyLogin() {
    incrementById('weekly_4', 1);
    incrementById('monthly_4', 1);
  }

  /// Claim quest reward and mark as completed
  void claimById(String questId) {
    if (_cachedQuestData == null) return;
    final q = getQuestById(_cachedQuestData!, questId);
    if (q == null) return;
    final updated = q.copyWith(claimed: true, completed: true, progress: q.target);
    _replaceQuest(updated);
    onCurrencyEarned(updated.reward);
  }

  // Helpers for persistence and selection
  String _dateString(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  List<String> _getIdList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> raw = json.decode(jsonStr);
      return raw.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
  List<Quest> _mapIds(List<Quest> source, List<String> ids) {
    final map = {for (final q in source) q.id: q};
    final list = <Quest>[];
    for (final id in ids) {
      final q = map[id];
      if (q != null) list.add(q);
    }
    return list;
  }
  List<Quest> _applySavedStatus(List<Quest> quests, SharedPreferences prefs) {
    return quests.map((q) {
      final raw = prefs.getString('quest_status_${q.id}');
      if (raw == null) return q;
      try {
        final data = json.decode(raw) as Map<String, dynamic>;
        return q.copyWith(
          progress: (data['progress'] as int?) ?? q.progress,
          completed: (data['completed'] as bool?) ?? q.completed,
          claimed: (data['claimed'] as bool?) ?? q.claimed,
        );
      } catch (_) {
        return q;
      }
    }).toList();
  }
  Future<void> _saveQuestStatus(SharedPreferences prefs, Quest q) async {
    final data = {
      'progress': q.progress,
      'completed': q.completed,
      'claimed': q.claimed,
    };
    await prefs.setString('quest_status_${q.id}', json.encode(data));
  }
  List<Quest> _pickRandomAndReset(List<Quest> source, int count) {
    final n = source.length;
    if (n <= count) {
      return source.map((q) => q.copyWith(progress: 0, completed: false, claimed: false)).toList();
    }
    final rng = DateTime.now().millisecondsSinceEpoch;
    // Simple deterministic shuffle based on current ms (good enough for daily rotation)
    final indices = List<int>.generate(n, (i) => i);
    indices.sort((a, b) => ((a * 1103515245 + rng) % 2147483647).compareTo((b * 1103515245 + rng) % 2147483647));
    final picked = indices.take(count).map((i) => source[i]).toList();
    return picked.map((q) => q.copyWith(progress: 0, completed: false, claimed: false)).toList();
  }

  void _incrementIfExists(String questId, int delta) {
    if (_cachedQuestData == null) return;
    final q = getQuestById(_cachedQuestData!, questId);
    if (q == null) return;
    incrementById(questId, delta);
  }

  /// Reward-dependent progress: increase meta quests based on currency earned
  void onCurrencyEarned(int amount) {
    if (amount <= 0) return;
    _incrementIfExists('daily_15', amount);
    _incrementIfExists('weekly_9', amount);
    _incrementIfExists('monthly_9', amount);
  }
}
