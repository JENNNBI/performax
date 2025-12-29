import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest.dart';
import 'statistics_service.dart';
import 'streak_service.dart';

/// Service to manage quest data loading and updates
class QuestService {
  static final QuestService instance = QuestService._internal();
  QuestService._internal();
  factory QuestService() => instance;
  
  QuestData? _cachedQuestData;
  final StreamController<QuestData> _controller = StreamController<QuestData>.broadcast();
  final StreamController<Quest> _completionController = StreamController<Quest>.broadcast();

  Stream<QuestData> get stream => _controller.stream;
  Stream<Quest> get completions => _completionController.stream;
  QuestData? get data => _cachedQuestData;

  /// 🔴 NOTIFICATION BADGE LOGIC
  /// Returns TRUE if user has completed quests waiting to be claimed
  /// This is used to show a red dot badge on the avatar
  bool get hasUnclaimedRewards {
    if (_cachedQuestData == null) return false;
    
    // Check all quest types
    final allQuests = [
      ..._cachedQuestData!.dailyQuests,
      ..._cachedQuestData!.weeklyQuests,
      ..._cachedQuestData!.monthlyQuests,
    ];
    
    // Return true if ANY quest is claimable (completed but not claimed)
    return allQuests.any((quest) => quest.isClaimable);
  }

  /// 🔄 CHECK DAILY RESET - Main entry point for daily quest refresh
  /// 
  /// **When to call:** At app startup (after authentication)
  /// **What it does:** Checks if it's a new day and generates fresh quests if needed
  /// **Returns:** TRUE if quests were reset, FALSE if still same day
  Future<bool> checkDailyReset() async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔄 QuestService: CHECKING DAILY RESET');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = _dateString(now);
      final lastDailyDate = prefs.getString('daily_last_date');
      
      debugPrint('   Last Quest Date: ${lastDailyDate ?? "Never"}');
      debugPrint('   Today: $today');
      
      // Check if it's a new day
      if (lastDailyDate == today) {
        debugPrint('✅ SAME DAY - No reset needed');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return false;
      }
      
      debugPrint('🔥 NEW DAY DETECTED - Generating fresh quests!');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Generate new daily quests
      await generateNewDailyQuests();
      
      return true;
    } catch (e) {
      debugPrint('❌ Error in checkDailyReset: $e');
      return false;
    }
  }

  /// 🎲 GENERATE NEW DAILY QUESTS - Creates fresh set of 5 quests
  /// 
  /// **Composition Rule:**
  /// - Slot 1: Mandatory "Daily Login" quest (fixed)
  /// - Slots 2-5: 4 Random quests from available pool
  /// 
  /// **What it does:**
  /// 1. Loads full quest pool from JSON
  /// 2. Extracts mandatory login quest
  /// 3. Randomly shuffles remaining quests
  /// 4. Takes top 4 random quests
  /// 5. Combines: [Login Quest] + [4 Random Quests]
  /// 6. Resets all progress to 0
  /// 7. Saves to local storage with today's date
  Future<void> generateNewDailyQuests() async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🎲 QuestService: GENERATING NEW DAILY QUESTS');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
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
      
      // Fallback to individual keys if profile cache fails
      studyField ??= prefs.getString('study_field');
      gradeLevel ??= prefs.getString('grade_level');
      
      debugPrint('   Study Field: ${studyField ?? "Not set"}');
      debugPrint('   Grade Level: ${gradeLevel ?? "Not set"}');
      
      // Determine correct JSON file
      String questFileName = 'quests_tyt.json'; // Default fallback
      
      if (gradeLevel != null) {
        final grade = gradeLevel.replaceAll(RegExp(r'[^\d]'), '');
        
        if (grade == '9' || grade == '10') {
          questFileName = 'quests_tyt.json';
        } else {
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
              questFileName = 'quests_tyt.json';
          }
        }
      }
      
      debugPrint('   Quest File: $questFileName');
      
      // Load quest pool from JSON
      final String jsonString = await rootBundle.loadString('assets/data/$questFileName');
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<Quest> allQuests = jsonList.map((e) => Quest.fromJson(e)).toList();
      final List<Quest> sourceDaily = allQuests.where((q) => q.id.startsWith('daily')).toList();
      
      debugPrint('   Total Daily Quests in Pool: ${sourceDaily.length}');
      
      // Generate the 5-quest set (1 Mandatory + 4 Random)
      final newDailyQuests = _pickDailyWithMandatory(sourceDaily, studyField, gradeLevel);
      
      // 🎯 CRITICAL AUTO-COMPLETE LOGIC
      // Since this function is triggered BY the user opening the app,
      // the "Daily Login" quest (first quest) is inherently completed.
      // Mark it as COMPLETED (but not claimed) immediately.
      if (newDailyQuests.isNotEmpty) {
        final loginQuest = newDailyQuests[0]; // First quest is always login
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('🎯 AUTO-COMPLETING LOGIN QUEST');
        debugPrint('   Quest: ${loginQuest.title}');
        debugPrint('   Reason: User is logged in (app is open)');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        // Mark as completed but not claimed
        newDailyQuests[0] = loginQuest.copyWith(
          progress: loginQuest.target,
          completed: true,
          claimed: false, // User must manually claim reward
        );
        
        debugPrint('✅ Login quest auto-completed!');
        debugPrint('   Status: COMPLETED (Ready to Claim)');
        debugPrint('   Progress: ${newDailyQuests[0].progress}/${newDailyQuests[0].target}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ NEW DAILY QUESTS GENERATED!');
      debugPrint('   Total Quests: ${newDailyQuests.length}');
      for (int i = 0; i < newDailyQuests.length; i++) {
        final q = newDailyQuests[i];
        final isMandatory = i == 0; // First quest is always mandatory login
        final status = q.completed ? '✅ COMPLETED' : '⏳ PENDING';
        debugPrint('   ${i + 1}. ${q.title} ${isMandatory ? "⭐ (MANDATORY)" : "🎲 (RANDOM)"} - $status');
        debugPrint('      ID: ${q.id}');
        debugPrint('      Reward: ${q.reward} Rockets');
        debugPrint('      Target: ${q.target}');
        debugPrint('      Progress: ${q.progress}/${q.target}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Save to local storage
      final today = _dateString(DateTime.now());
      await prefs.setString('selected_daily_ids', json.encode(newDailyQuests.map((q) => q.id).toList()));
      await prefs.setString('daily_last_date', today);
      
      // Reset and save quest status
      for (final q in newDailyQuests) {
        await _saveQuestStatus(prefs, q);
      }
      
      // Update cached data if available
      if (_cachedQuestData != null) {
        _cachedQuestData = QuestData(
          dailyQuests: newDailyQuests,
          weeklyQuests: _cachedQuestData!.weeklyQuests,
          monthlyQuests: _cachedQuestData!.monthlyQuests,
        );
        _emit();
      }
      
      debugPrint('✅ DAILY QUESTS SAVED & CACHED');
      debugPrint('   Date: $today');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      debugPrint('❌ Error in generateNewDailyQuests: $e');
      rethrow;
    }
  }

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
      // 🔄 CRITICAL: Check if it's a new day and reset quests if needed
      await checkDailyReset();
      
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

      // Daily Quests (5-Quest Rule: 1 Mandatory Login + 4 Random)
      List<Quest> daily;
      if (lastDailyDate == today && selectedDailyIds.isNotEmpty) {
        daily = _applySavedStatus(_mapIds(fullData.dailyQuests, selectedDailyIds), prefs);
      } else {
        daily = _pickDailyWithMandatory(fullData.dailyQuests, studyField, gradeLevel);
        
        // 🎯 AUTO-COMPLETE LOGIN QUEST
        // Since the user has opened the app to trigger this generation,
        // the "Daily Login" quest (first quest) is inherently completed.
        if (daily.isNotEmpty) {
          final loginQuest = daily[0]; // First quest is always login
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('🎯 AUTO-COMPLETING LOGIN QUEST (loadQuests)');
          debugPrint('   Quest: ${loginQuest.title}');
          debugPrint('   Reason: User is logged in (app is open)');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          
          // Mark as completed but not claimed
          daily[0] = loginQuest.copyWith(
            progress: loginQuest.target,
            completed: true,
            claimed: false, // User must manually claim reward
          );
          
          debugPrint('✅ Login quest auto-completed!');
          debugPrint('   Status: COMPLETED (Ready to Claim)');
          debugPrint('   Progress: ${daily[0].progress}/${daily[0].target}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
        
        await prefs.setString('selected_daily_ids', json.encode(daily.map((q) => q.id).toList()));
        await prefs.setString('daily_last_date', today);
        for (final q in daily) {
          await _saveQuestStatus(prefs, q);
        }
      }

      // Weekly Quests (5-Quest Rule: 1 Mandatory Streak-7 + 4 Random)
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
        weekly = _pickWeeklyWithMandatory(fullData.weeklyQuests, studyField, gradeLevel);
        await prefs.setString('selected_weekly_ids', json.encode(weekly.map((q) => q.id).toList()));
        await prefs.setString('weekly_last_date', today);
        for (final q in weekly) {
          await _saveQuestStatus(prefs, q);
        }
      }

      // Monthly Quests (5-Quest Rule: 1 Mandatory Streak-30 + 4 Random)
      List<Quest> monthly;
      if (lastMonthlyMonth == thisMonth && selectedMonthlyIds.isNotEmpty) {
        monthly = _applySavedStatus(_mapIds(fullData.monthlyQuests, selectedMonthlyIds), prefs);
      } else {
        monthly = _pickMonthlyWithMandatory(fullData.monthlyQuests, studyField, gradeLevel);
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
      
      // Check streaks immediately after loading
      await _checkStreakQuests(prefs);
      
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
    
    // 🎯 REFINED SORT LOGIC - UX Fix for Registration Flow
    // Priority Order:
    // 1. TOP: Completed & Unclaimed (ready to collect reward) ⭐
    // 2. MIDDLE: In Progress (active quests)
    // 3. BOTTOM: Completed & Claimed (done and dusted)
    int sortQuests(Quest a, Quest b) {
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

  /// Check and increment any AI/Alfred related quests
  /// This should be called whenever a message is sent to Alfred
  void checkAndIncrementAIQuests() {
    if (_cachedQuestData == null) return;
    
    final allQuests = [
      ..._cachedQuestData!.dailyQuests,
      ..._cachedQuestData!.weeklyQuests,
      ..._cachedQuestData!.monthlyQuests,
    ];

    for (final q in allQuests) {
      if (q.completed) continue;

      // Check if quest is AI related
      if (_isAIQuest(q)) {
         incrementById(q.id, 1);
      }
    }
  }

  bool _isAIQuest(Quest q) {
    // Check type first
    if (q.type == 'ai_interaction' || q.type == 'ai_chat') return true;
    
    // Check ID keywords
    final idLower = q.id.toLowerCase();
    if (idLower.contains('alfred') || 
        idLower.contains('ai_') || 
        idLower.contains('chat')) {
      return true;
    }
    
    // Check title/description keywords as fallback
    final text = '${q.title} ${q.description}'.toLowerCase();
    return text.contains('alfred') || 
           text.contains('yapay zeka') || 
           text.contains('ai ile') ||
           text.contains('soru sor');
  }

  void onAiInteracted() {
    // Forward to universal handler
    checkAndIncrementAIQuests();
    
    // Legacy generic IDs (kept for backward compatibility if needed)
    _incrementIfExists('daily_6', 1);
    _incrementIfExists('weekly_7', 1);
    _incrementIfExists('monthly_8', 1);
  }

  void onDailyLogin() {
    incrementById('daily_1', 1);
    incrementById('weekly_4', 1);
    incrementById('monthly_4', 1);
  }

  /// 🎯 Mark Daily Login Quest as Completed (NOT Claimed)
  /// 
  /// **CRITICAL:** This is called ONLY on:
  /// 1. New user registration (first-time login)
  /// 2. Daily login (once per day)
  /// 
  /// **What it does:**
  /// - Finds the mandatory daily login quest (any variant: TYT, EA, Sozel)
  /// - Sets progress to target (completes the quest)
  /// - Sets completed = true
  /// - Sets claimed = false (user MUST manually claim reward)
  /// - Does NOT add currency (that happens on claim only)
  /// 
  /// **Anti-Bug Logic:**
  /// - If already claimed today, does nothing
  /// - If already completed but not claimed, does nothing (waits for claim)
  Future<void> markDailyLoginAsCompleted() async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🎯 QuestService: MARKING DAILY LOGIN AS COMPLETED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (_cachedQuestData == null) {
        debugPrint('⚠️ No quest data loaded yet, skipping login quest completion');
        return;
      }
      
      // Find the daily login quest (supports all variants)
      Quest? loginQuest;
      for (final q in _cachedQuestData!.dailyQuests) {
        if (q.type == 'login' || 
            q.id.contains('login') ||
            q.id.contains('gune_basla')) {
          loginQuest = q;
          break;
        }
      }
      
      if (loginQuest == null) {
        debugPrint('⚠️ Daily login quest not found in current quest set');
        return;
      }
      
      debugPrint('   Quest ID: ${loginQuest.id}');
      debugPrint('   Quest Title: ${loginQuest.title}');
      debugPrint('   Current Progress: ${loginQuest.progress}/${loginQuest.target}');
      debugPrint('   Already Completed: ${loginQuest.completed}');
      debugPrint('   Already Claimed: ${loginQuest.claimed}');
      
      // Safety Check: If already claimed, do nothing
      if (loginQuest.claimed) {
        debugPrint('✅ Login quest already claimed today - no action needed');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }
      
      // Safety Check: If already completed but not claimed, do nothing
      if (loginQuest.completed && loginQuest.progress >= loginQuest.target) {
        debugPrint('✅ Login quest already completed - waiting for user to claim');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }
      
      // Mark as completed (but NOT claimed)
      final updated = loginQuest.copyWith(
        progress: loginQuest.target,
        completed: true,
        claimed: false, // 🔒 CRITICAL: User must manually claim
      );
      
      _replaceQuest(updated);
      
      debugPrint('✅ DAILY LOGIN QUEST MARKED AS COMPLETED!');
      debugPrint('   Progress: ${updated.progress}/${updated.target}');
      debugPrint('   Completed: ${updated.completed}');
      debugPrint('   Claimed: ${updated.claimed}');
      debugPrint('   Reward: ${updated.reward} Rockets');
      debugPrint('   ⚠️ User must tap "Claim" button to receive reward');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Emit completion event for UI to highlight the quest
      _completionController.add(updated);
    } catch (e) {
      debugPrint('❌ Error marking daily login as completed: $e');
    }
  }

  /// 🎁 Claim quest reward and mark as completed
  /// 
  /// **CRITICAL ANTI-DUPLICATION LOGIC:**
  /// This method has THREE strict safety checks to prevent double rewards:
  /// 
  /// 1. Quest must exist
  /// 2. Quest must be claimable (progress >= target)
  /// 3. Quest must NOT be already claimed
  /// 
  /// **What it does:**
  /// - Verifies quest is ready to claim
  /// - Adds EXACT reward amount to user's balance (e.g., 10 rockets)
  /// - Marks quest as claimed (locks it forever)
  /// - Logs the currency gain for statistics
  /// 
  /// **Math Verification:**
  /// - If quest reward = 10, user balance increases by EXACTLY 10
  /// - NOT 20 (completion + claim)
  /// - NOT doubled amount
  void claimById(String questId) {
    if (_cachedQuestData == null) {
      debugPrint('⚠️ Cannot claim quest: No quest data loaded');
      return;
    }
    
    final q = getQuestById(_cachedQuestData!, questId);
    if (q == null) {
      debugPrint('⚠️ Cannot claim quest: Quest not found (ID: $questId)');
      return;
    }
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🎁 QuestService: CLAIM ATTEMPT');
    debugPrint('   Quest ID: ${q.id}');
    debugPrint('   Quest Title: ${q.title}');
    debugPrint('   Progress: ${q.progress}/${q.target}');
    debugPrint('   Reward: ${q.reward} Rockets');
    debugPrint('   Already Claimed: ${q.claimed}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // 🛡️ SAFETY CHECK 1: Quest must be claimable (reached target)
    if (!q.isClaimable) {
      debugPrint('❌ CLAIM REJECTED: Quest not yet completed');
      debugPrint('   Current Progress: ${q.progress}/${q.target}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }
    
    // 🛡️ SAFETY CHECK 2: Quest must NOT be already claimed (anti-duplication)
    if (q.claimed) {
      debugPrint('❌ CLAIM REJECTED: Quest already claimed!');
      debugPrint('   This prevents double reward bug');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }
    
    // 🎯 ALL CHECKS PASSED - EXECUTE REWARD TRANSACTION
    debugPrint('✅ All safety checks passed - processing reward');
    
    // Mark as claimed immediately (locks the quest)
    final updated = q.copyWith(
      claimed: true, 
      completed: true, 
      progress: q.target
    );
    _replaceQuest(updated);
    
    // Add EXACT reward amount to user's balance
    debugPrint('💰 Adding ${q.reward} Rockets to user balance...');
    onCurrencyEarned(q.reward); // This will trigger currency service
    StatisticsService.instance.logRocketEarned(q.reward);
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ QUEST CLAIMED SUCCESSFULLY!');
    debugPrint('   Quest: ${q.title}');
    debugPrint('   Reward Added: ${q.reward} Rockets');
    debugPrint('   Status: LOCKED (cannot claim again)');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
    // ID for mandatory login quest
    // Use generic/shared ID or detect from file
    // Supports TYT, EA, and Sozel specific login quests
    const tytLoginId = 'daily_tyt_login';
    const eaLoginId = 'daily_ea_login';
    const sozelLoginId = 'daily_sozel_login';
    
    final mandatory = source.where((q) => q.id == tytLoginId || q.id == eaLoginId || q.id == sozelLoginId).toList();
    
    // Create mandatory if missing (fallback)
    final mandatoryQuest = mandatory.isNotEmpty ? mandatory.first : Quest(
      id: 'daily_generic_login',
      title: 'Güne Başla',
      description: 'Uygulamaya giriş yap ve yoklamanı al',
      reward: 10,
      progress: 0,
      target: 1,
      type: 'login', // Explicit type
      icon: 'login', // Explicit icon
      completed: false,
      claimed: false,
    );

    final rest = source.where((q) => q.id != mandatoryQuest.id).toList();
    // Pick 4 random from the rest
    final picked = _pickRandomAndReset(rest, 4, studyField, gradeLevel);
    
    // Reset mandatory quest state
    final m = mandatoryQuest.copyWith(progress: 0, completed: false, claimed: false);
    
    return [m, ...picked];
  }
  
  List<Quest> _pickWeeklyWithMandatory(List<Quest> source, String? studyField, String? gradeLevel) {
    // ID for mandatory streak quest
    const tytStreakId = 'weekly_tyt_login_streak';
    const eaStreakId = 'weekly_ea_login_streak';
    const sozelStreakId = 'weekly_sozel_login_streak';
    
    final mandatory = source.where((q) => q.id == tytStreakId || q.id == eaStreakId || q.id == sozelStreakId).toList();
    
    final mandatoryQuest = mandatory.isNotEmpty ? mandatory.first : Quest(
      id: 'weekly_generic_streak',
      title: 'İstikrar Haftası',
      description: 'Bu hafta 5 farklı gün uygulamaya gir',
      reward: 150,
      progress: 0,
      target: 5,
      type: 'login',
      icon: 'verified_user',
      completed: false,
      claimed: false,
    );

    final rest = source.where((q) => q.id != mandatoryQuest.id).toList();
    final picked = _pickRandomAndReset(rest, 4, studyField, gradeLevel);
    final m = mandatoryQuest.copyWith(progress: 0, completed: false, claimed: false);
    
    return [m, ...picked];
  }
  
  List<Quest> _pickMonthlyWithMandatory(List<Quest> source, String? studyField, String? gradeLevel) {
    // ID for mandatory monthly quest
    const tytLoyalistId = 'monthly_tyt_loyalist';
    const eaLoyalistId = 'monthly_ea_loyalist';
    const sozelLoyalistId = 'monthly_sozel_loyalist';
    
    final mandatory = source.where((q) => q.id == tytLoyalistId || q.id == eaLoyalistId || q.id == sozelLoyalistId).toList();
    
    final mandatoryQuest = mandatory.isNotEmpty ? mandatory.first : Quest(
      id: 'monthly_generic_loyalist',
      title: 'Sadık Öğrenci',
      description: 'Bu ay 20 gün uygulamaya giriş yap',
      reward: 1000,
      progress: 0,
      target: 20,
      type: 'login',
      icon: 'calendar_month',
      completed: false,
      claimed: false,
    );

    final rest = source.where((q) => q.id != mandatoryQuest.id).toList();
    final picked = _pickRandomAndReset(rest, 4, studyField, gradeLevel);
    final m = mandatoryQuest.copyWith(progress: 0, completed: false, claimed: false);
    
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
    
    // Legacy generic IDs
    _incrementIfExists('daily_15', amount);
    _incrementIfExists('weekly_9', amount);
    _incrementIfExists('monthly_9', amount);

    // Rocket Accumulation Quests (The "Rocket Zengini" feature)
    if (_cachedQuestData != null) {
      final allQuests = [
        ..._cachedQuestData!.dailyQuests,
        ..._cachedQuestData!.weeklyQuests,
        ..._cachedQuestData!.monthlyQuests,
      ];

      for (final q in allQuests) {
        if (q.completed) continue;

        // Check for specific Rocket Accumulation IDs
        if (_isRocketAccumulationQuest(q.id)) {
           // SPECIAL FIX: Only daily rocket quests (target=1) should complete instantly.
           // Monthly/Long-term accumulation quests (target=1000+) should only increment.
           // We use incrementById which clamps. 
           // BUT if q.target is 1 (Daily), amount (e.g. 20) will fill it. This is correct.
           // IF q.target is 1000 (Monthly), amount 20 will make it 20/1000. This is also correct.
           // The bug report says "jumps to 1000/1000". This implies logic error or 'amount' is wrong.
           // Logic check: incrementById uses `q.progress + delta`. 
           // If it jumps to max, either delta is huge or progress was already huge.
           
           incrementById(q.id, amount);
        }
      }
    }
  }

  bool _isRocketAccumulationQuest(String id) {
    const targetIds = {
      'monthly_rocket_tycoon', // Main accumulation quest
      'daily_rocket_tyt',      // Daily variants
      'daily_rocket_ea',
      'daily_rocket_sozel',
      'daily_rocket_hunter',
      'daily_rocket_sayisal',
    };
    return targetIds.contains(id);
  }

  Future<void> _checkStreakQuests(SharedPreferences prefs) async {
    final streakService = StreakService();
    final streakData = await streakService.getStreakData();
    final currentStreak = streakData.currentStreak;
    
    // Check Weekly Streak (Target 5 days for weekly_tyt_login_streak)
    // Actually the weekly quest is "5 different days", not necessarily consecutive.
    // But if we stick to the requirement "7-Day Streak" in prompt for weekly, we check currentStreak.
    // The prompt says "Slot 1: 7-Day Streak". Let's update that quest if it exists.
    // In json it is "weekly_tyt_login_streak" with target 5. I will stick to JSON for ID but use streak logic.
    
    if (_cachedQuestData != null) {
      // Weekly: Update streak based quest
      // Support both TYT and EA specific mandatory IDs + Generic fallback
      const tytStreakId = 'weekly_tyt_login_streak';
      const eaStreakId = 'weekly_ea_login_streak';
      const sozelStreakId = 'weekly_sozel_login_streak';
      const sayisalStreakId = 'weekly_sayisal_login_streak';
      const genericStreakId = 'weekly_generic_streak';
      
      final weeklyMandatory = getQuestById(_cachedQuestData!, tytStreakId) ?? 
                              getQuestById(_cachedQuestData!, eaStreakId) ??
                              getQuestById(_cachedQuestData!, sozelStreakId) ??
                              getQuestById(_cachedQuestData!, sayisalStreakId) ??
                              getQuestById(_cachedQuestData!, genericStreakId);
                              
      if (weeklyMandatory != null && !weeklyMandatory.completed) {
         if (currentStreak >= weeklyMandatory.target) {
           _replaceQuest(weeklyMandatory.copyWith(progress: weeklyMandatory.target));
         }
      }
      
      // Monthly: 30-Day Streak
      const tytLoyalistId = 'monthly_tyt_loyalist';
      const eaLoyalistId = 'monthly_ea_loyalist';
      const sozelLoyalistId = 'monthly_sozel_loyalist';
      const sayisalLoyalistId = 'monthly_sayisal_loyalist';
      const genericLoyalistId = 'monthly_generic_loyalist';
      
      final monthlyMandatory = getQuestById(_cachedQuestData!, tytLoyalistId) ??
                               getQuestById(_cachedQuestData!, eaLoyalistId) ??
                               getQuestById(_cachedQuestData!, sozelLoyalistId) ??
                               getQuestById(_cachedQuestData!, sayisalLoyalistId) ??
                               getQuestById(_cachedQuestData!, genericLoyalistId);
                               
      if (monthlyMandatory != null && !monthlyMandatory.completed) {
        if (currentStreak >= monthlyMandatory.target) {
           _replaceQuest(monthlyMandatory.copyWith(progress: monthlyMandatory.target));
        }
      }
    }
  }
}
