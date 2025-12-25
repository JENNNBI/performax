import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest.dart';
import 'statistics_service.dart';

/// Service to manage quest data loading and updates
class QuestService {
  // static const String _questDataPath = 'assets/data/quests.json'; // Deprecated in favor of dynamic loading
  static final QuestService instance = QuestService._internal();
  QuestService._internal();
  factory QuestService() => instance;
  
  QuestData? _cachedQuestData;
  final StreamController<QuestData> _controller = StreamController<QuestData>.broadcast();
  final StreamController<Quest> _completionController = StreamController<Quest>.broadcast();

  Stream<QuestData> get stream => _controller.stream;
  Stream<Quest> get completions => _completionController.stream;
  QuestData? get data => _cachedQuestData;

  /// Clear all local quest data (for new user registration)
  Future<void> resetLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('quest_status_') || 
          key.startsWith('selected_daily_ids') ||
          key.startsWith('selected_weekly_ids') ||
          key.startsWith('selected_monthly_ids') ||
          key.startsWith('daily_last_date') ||
          key.startsWith('weekly_last_date') ||
          key.startsWith('monthly_last_month')) {
        await prefs.remove(key);
      }
    }
    _cachedQuestData = null;
  }

  /// Load quest data from JSON asset
  Future<QuestData> loadQuests() async {
    try {
      // Return cached data if available
      if (_cachedQuestData != null) {
        return _cachedQuestData!;
      }

      final prefs = await SharedPreferences.getInstance();

      // Get user's study field and grade from cached profile
      String? studyField;
      String? gradeLevel;
      try {
        final cachedProfileJson = prefs.getString('cached_user_profile');
        if (cachedProfileJson != null) {
          final Map<String, dynamic> profileMap = json.decode(cachedProfileJson);
          studyField = profileMap['studyField'];
          gradeLevel = profileMap['gradeLevel'] ?? profileMap['class'];
        }
      } catch (_) {}
      
      // Fallback to individual keys if profile cache fails (legacy support)
      studyField ??= prefs.getString('study_field');
      gradeLevel ??= prefs.getString('grade_level');

      // Determine correct JSON file path based on user profile
      String questFileName = 'quests_tyt.json'; // Default fallback

      if (gradeLevel != null) {
        // Normalize grade string (e.g. "9. Sınıf" -> "9")
        final grade = gradeLevel.replaceAll(RegExp(r'[^\d]'), '');
        
        // RULE 1: Grade 9 & 10 get TYT (Field is irrelevant)
        if (grade == '9' || grade == '10') {
          questFileName = 'quests_tyt.json';
        } else {
          // RULE 2: Grade 11, 12, Mezun depend on FIELD
          switch (studyField) {
            case 'Sayısal':
              questFileName = 'quests_sayisal.json';
              break;
            case 'Eşit Ağırlık':
              questFileName = 'quests_ea.json';
              break;
            case 'Sözel':
              questFileName = 'quests_sozel.json';
              break;
            default:
              // Fallback/Safety (e.g., if field is null)
              questFileName = 'quests_tyt.json';
          }
        }
      }

      // Load JSON file
      final String jsonString = await rootBundle.loadString('assets/data/$questFileName');
      final List<dynamic> jsonList = json.decode(jsonString);

      // Parse and categorize quests
      final List<Quest> allQuests = jsonList.map((e) => Quest.fromJson(e)).toList();
      
      final sourceDaily = allQuests.where((q) => q.id.startsWith('daily')).toList();
      final sourceWeekly = allQuests.where((q) => q.id.startsWith('weekly')).toList();
      final sourceMonthly = allQuests.where((q) => q.id.startsWith('monthly')).toList();

      // Create full data object
      final fullData = QuestData(
        dailyQuests: sourceDaily, 
        weeklyQuests: sourceWeekly, 
        monthlyQuests: sourceMonthly
      );
      
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
        daily = _pickDailyWithMandatory(fullData.dailyQuests, studyField, gradeLevel);
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
        weekly = _pickRandomAndReset(fullData.weeklyQuests, 3, studyField, gradeLevel);
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
        monthly = _pickRandomAndReset(fullData.monthlyQuests, 2, studyField, gradeLevel);
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
    
    // Sort helper: Incomplete on top (false), Completed/Claimed on bottom (true)
    int sortQuests(Quest a, Quest b) {
      final aDone = a.isCompleted;
      final bDone = b.isCompleted;
      if (aDone == bDone) return 0;
      return aDone ? 1 : -1;
    }

    List<Quest> replaceAndSort(List<Quest> list) {
      final replaced = list.map((q) => q.id == updated.id ? updated : q).toList();
      replaced.sort(sortQuests);
      return replaced;
    }

    _cachedQuestData = QuestData(
      dailyQuests: replaceAndSort(d.dailyQuests),
      weeklyQuests: replaceAndSort(d.weeklyQuests),
      monthlyQuests: replaceAndSort(d.monthlyQuests),
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
  void onPerfectScoreAchieved() {
    incrementById('daily_5', 1);
  }

  // Legacy methods removed in favor of updateProgress


  void updateProgress({required String type, required int amount, String? subject}) {
    if (_cachedQuestData == null) return;
    if (amount <= 0) return;
    final d = _cachedQuestData!;
    
    // Build tokens from the incoming subject
    final subjTokens = subject != null && subject.isNotEmpty ? _buildSubjectTokens(subject) : const <String>[];
    
    Iterable<Quest> all = [
      ...d.dailyQuests,
      ...d.weeklyQuests,
      ...d.monthlyQuests,
    ];
    
    for (final q in all) {
      if (q.completed) continue;
      
      // 1. Check if type matches (e.g. 'watch_video', 'solve_questions')
      final haystack = '${q.id} ${q.title} ${q.description}'.toLowerCase();
      final normHaystack = _normalize(haystack);
      
      // If type doesn't match, skip this quest
      // Note: _matchesType uses keywords based on type, but we should also check explicit 'type' field if available
      // For now, we rely on _matchesType which checks keywords related to the action type
      if (!_matchesType(haystack, normHaystack, type)) continue;
      
      // 2. Check Subject Specificity
      // Check if the quest itself is specific to a subject (e.g. contains "math", "fizik")
      // We check if the quest contains any known subject keywords
      final questSpecificSubjects = _findSubjectKeywordsInQuest(haystack, normHaystack);
      
      if (questSpecificSubjects.isNotEmpty) {
        // Quest is specific (e.g. "Solve Math Questions")
        
        if (subjTokens.isEmpty) {
          // Incoming action has no subject -> NO UPDATE for specific quest
          continue;
        }
        
        // Check if incoming subject matches the quest's subject
        // The incoming subject tokens must overlap with the quest's subject keywords
        final bool matches = questSpecificSubjects.any((qSubj) => subjTokens.contains(qSubj));
        
        if (!matches) {
          // User watched "History", Quest is "Math" -> NO UPDATE
          continue;
        }
        // If matches, proceed to update
      } else {
        // Quest is Generic (e.g. "Watch ANY video") -> ALWAYS UPDATE
        // No subject check needed
      }

      final newProgress = (q.progress + amount).clamp(0, q.target);
      final updated = q.copyWith(progress: newProgress);
      _replaceQuest(updated);
    }
  }

  /// Helper to identify if a quest is subject-specific
  /// Returns a list of normalized subject tokens found in the quest text
  List<String> _findSubjectKeywordsInQuest(String haystack, String normHaystack) {
    // List of all possible subjects to check against
    final allSubjects = [
      'matematik', 'math', 'mat',
      'türkçe', 'turkce', 'turkish', 'turk',
      'fizik', 'physics', 'fiz',
      'kimya', 'chemistry', 'kim',
      'biyoloji', 'biology', 'bio',
      'tarih', 'history',
      'coğrafya', 'cografya', 'geography', 'geo',
      'felsefe', 'philosophy',
      'fen', 'science',
      'sosyal', 'social'
    ];
    
    final found = <String>[];
    for (final subj in allSubjects) {
      if (haystack.contains(subj) || normHaystack.contains(subj)) {
        found.add(subj);
      }
    }
    return found;
  }

  bool _matchesType(String haystack, String normHaystack, String type) {
    final tokens = <String>[];
    switch (type) {
      case 'watch_video':
        tokens.addAll(['video', 'izle', 'watch', 'konu anlatım']);
        break;
      case 'read_pages':
        tokens.addAll(['pdf', 'sayfa', 'page', 'oku', 'document']);
        break;
      case 'solve_questions':
        tokens.addAll(['soru', 'question', 'solve', 'çöz']);
        break;
      case 'login':
        tokens.addAll(['login', 'giriş', 'gir', 'enter', 'sign in']);
        break;
      default:
        return true; // unknown type, treat as generic
    }
    return tokens.any((t) => haystack.contains(t) || normHaystack.contains(t));
  }

  List<String> _buildSubjectTokens(String subjectName) {
    final lower = subjectName.toLowerCase();
    final norm = _normalize(lower);
    final syn = _subjectSynonyms(lower);
    return {lower, norm, ...syn}.toList();
  }

  String _normalize(String s) {
    return s
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  List<String> _subjectSynonyms(String lower) {
    switch (lower) {
      case 'matematik':
        return ['math', 'mat'];
      case 'türkçe':
        return ['turkce', 'turkish', 'turk'];
      case 'fizik':
        return ['physics', 'fiz'];
      case 'kimya':
        return ['chemistry', 'kim'];
      case 'biyoloji':
        return ['biology', 'bio'];
      case 'tarih':
        return ['history'];
      case 'coğrafya':
        return ['cografya', 'geography', 'geo'];
      case 'felsefe':
        return ['philosophy'];
      default:
        return [];
    }
  }

  Future<void> ensureDailyLoginTracked() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('last_login_date');
    final today = _dateString(DateTime.now());
    if (last == today) return;
    updateProgress(type: 'login', amount: 1);
    await prefs.setString('last_login_date', today);
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
  List<Quest> _pickDailyWithMandatory(List<Quest> source, String? studyField, String? gradeLevel) {
    final mandatory = source.where((q) => q.id == 'daily_1').toList();
    if (mandatory.isEmpty) {
      return _pickRandomAndReset(source, 5, studyField, gradeLevel);
    }
    final rest = source.where((q) => q.id != 'daily_1').toList();
    final picked = _pickRandomAndReset(rest, 4, studyField, gradeLevel);
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
  List<Quest> _pickRandomAndReset(List<Quest> source, int count, String? studyField, String? gradeLevel) {
    // Filter by study field first
    final filtered = source.where((q) => _isQuestRelevant(q, studyField, gradeLevel)).toList();
    
    final n = filtered.length;
    if (n <= count) {
      return filtered.map((q) => q.copyWith(progress: 0, completed: false, claimed: false)).toList();
    }
    final rng = DateTime.now().millisecondsSinceEpoch;
    // Simple deterministic shuffle based on current ms (good enough for daily rotation)
    final indices = List<int>.generate(n, (i) => i);
    indices.sort((a, b) => ((a * 1103515245 + rng) % 2147483647).compareTo((b * 1103515245 + rng) % 2147483647));
    final picked = indices.take(count).map((i) => filtered[i]).toList();
    return picked.map((q) => q.copyWith(progress: 0, completed: false, claimed: false)).toList();
  }

  bool _isQuestRelevant(Quest quest, String? studyField, String? gradeLevel) {
    // If grade is 9 or 10, show all quests (bypass study field filtering)
    if (gradeLevel != null) {
       final grade = gradeLevel.replaceAll(RegExp(r'[^\d]'), '');
       if (grade == '9' || grade == '10') {
         return true;
       }
    }

    if (studyField == null) return true; // No field selected, allow all

    final text = '${quest.title} ${quest.description} ${quest.id}'.toLowerCase();
    final normText = _normalize(text);
    final subjects = _findSubjectKeywordsInQuest(text, normText);

    // If no specific subject identified, assume it's generic/TYT and allow
    if (subjects.isEmpty) return true;

    // Check specific rules
    switch (studyField) {
      case 'Sayısal':
        // Block Edebiyat
        if (subjects.contains('edebiyat')) return false;
        // Block AYT History/Geography
        if ((subjects.contains('tarih') || subjects.contains('history')) && (text.contains('ayt') || text.contains('2'))) return false;
        if ((subjects.contains('cografya') || subjects.contains('geography') || subjects.contains('geo')) && (text.contains('ayt') || text.contains('2'))) return false;
        return true;

      case 'Eşit Ağırlık':
        // Block Science (Fizik, Kimya, Biyoloji)
        if (subjects.any((s) => ['fizik', 'physics', 'fiz', 'kimya', 'chemistry', 'kim', 'biyoloji', 'biology', 'bio'].contains(s))) return false;
        return true;

      case 'Sözel':
        // Block Science
        if (subjects.any((s) => ['fizik', 'physics', 'fiz', 'kimya', 'chemistry', 'kim', 'biyoloji', 'biology', 'bio'].contains(s))) return false;
        // Block AYT Math
        if (subjects.any((s) => ['matematik', 'math', 'mat'].contains(s)) && (text.contains('ayt'))) return false;
        return true;

      default:
        return true;
    }
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
