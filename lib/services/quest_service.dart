import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest.dart';
import 'statistics_service.dart';

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
      final now = DateTime.now();
      final today = _dateString(now);
      final thisMonth = _monthKey(now);
      final lastDailyDate = prefs.getString('daily_last_date');
      final lastWeeklyDate = prefs.getString('weekly_last_date');
      final lastMonthlyMonth = prefs.getString('monthly_last_month');

      final selectedDailyIds = _getIdList(prefs.getString('selected_daily_ids'));
      final selectedWeeklyIds = _getIdList(prefs.getString('selected_weekly_ids'));
      final selectedMonthlyIds = _getIdList(prefs.getString('selected_monthly_ids'));

      List<Quest> daily;
      if (lastDailyDate == today && selectedDailyIds.isNotEmpty) {
        daily = _applySavedStatus(_mapIds(fullData.dailyQuests, selectedDailyIds), prefs);
      } else {
        daily = _pickDailyWithMandatory(fullData.dailyQuests);
        await prefs.setString('selected_daily_ids', json.encode(daily.map((q) => q.id).toList()));
        await prefs.setString('daily_last_date', today);
        for (final q in daily) {
          await _saveQuestStatus(prefs, q);
        }
      }

      List<Quest> weekly;
      final shouldResetWeekly = () {
        if (lastWeeklyDate == null) return true;
        try {
          final last = _parseDate(lastWeeklyDate);
          final days = _daysBetween(last, now);
          final weekChanged = _weekKey(last) != _weekKey(now);
          return days >= 7 || weekChanged;
        } catch (_) {
          return true;
        }
      }();
      if (!shouldResetWeekly && selectedWeeklyIds.isNotEmpty) {
        weekly = _applySavedStatus(_mapIds(fullData.weeklyQuests, selectedWeeklyIds), prefs);
      } else {
        weekly = _pickRandomAndReset(fullData.weeklyQuests, 5);
        await prefs.setString('selected_weekly_ids', json.encode(weekly.map((q) => q.id).toList()));
        await prefs.setString('weekly_last_date', today);
        for (final q in weekly) {
          await _saveQuestStatus(prefs, q);
        }
      }

      List<Quest> monthly;
      if (lastMonthlyMonth == thisMonth && selectedMonthlyIds.isNotEmpty) {
        monthly = _applySavedStatus(_mapIds(fullData.monthlyQuests, selectedMonthlyIds), prefs);
      } else {
        monthly = _pickRandomAndReset(fullData.monthlyQuests, 5);
        await prefs.setString('selected_monthly_ids', json.encode(monthly.map((q) => q.id).toList()));
        await prefs.setString('monthly_last_month', thisMonth);
        for (final q in monthly) {
          await _saveQuestStatus(prefs, q);
        }
      }
      _cachedQuestData = QuestData(dailyQuests: daily, weeklyQuests: weekly, monthlyQuests: monthly);

      // Migration: Reset progress for PDF page-count quests after format change
      final migrated = prefs.getBool('pdf_pages_migration_done') ?? false;
      if (!migrated) {
        _cachedQuestData = _migratePdfQuests(prefs, _cachedQuestData!);
        await prefs.setBool('pdf_pages_migration_done', true);
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

  void onPdfPageViewed() {
    _incrementIfExists('daily_4', 1);
    _incrementIfExists('weekly_5', 1);
    _incrementIfExists('monthly_4', 1);
  }

  QuestData _migratePdfQuests(SharedPreferences prefs, QuestData data) {
    Quest resetIfPdf(Quest q) {
      if (q.id == 'daily_4' || q.id == 'weekly_5' || q.id == 'monthly_4') {
        final updated = q.copyWith(progress: 0, completed: false, claimed: false);
        // Persist reset
        _saveQuestStatus(prefs, updated);
        return updated;
      }
      return q;
    }
    final migratedDaily = data.dailyQuests.map(resetIfPdf).toList();
    final migratedWeekly = data.weeklyQuests.map(resetIfPdf).toList();
    final migratedMonthly = data.monthlyQuests.map(resetIfPdf).toList();
    return QuestData(dailyQuests: migratedDaily, weeklyQuests: migratedWeekly, monthlyQuests: migratedMonthly);
  }

  void onAiInteracted() {
    // Increment across all AI-related quests if present
    _incrementIfExists('daily_6', 1);
    _incrementIfExists('weekly_7', 1);
    _incrementIfExists('monthly_8', 1);
  }

  void onDailyLogin() {
    incrementById('daily_1', 1);
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
    StatisticsService.instance.logRocketEarned(updated.reward);
  }

  // Helpers for persistence and selection
  String _dateString(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  String _monthKey(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
  String _weekKey(DateTime dt) {
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    return _dateString(DateTime(monday.year, monday.month, monday.day));
  }
  DateTime _parseDate(String s) {
    final parts = s.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
  int _daysBetween(DateTime a, DateTime b) {
    final a0 = DateTime(a.year, a.month, a.day);
    final b0 = DateTime(b.year, b.month, b.day);
    return b0.difference(a0).inDays;
  }
  List<Quest> _pickDailyWithMandatory(List<Quest> source) {
    final mandatory = source.where((q) => q.id == 'daily_1').toList();
    if (mandatory.isEmpty) {
      return _pickRandomAndReset(source, 5);
    }
    final rest = source.where((q) => q.id != 'daily_1').toList();
    final picked = _pickRandomAndReset(rest, 4);
    final m = mandatory.first.copyWith(progress: 0, completed: false, claimed: false);
    return [m, ...picked];
  }
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
