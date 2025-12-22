import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'currency_service.dart';

class StatisticsSnapshot {
  final Map<String, double> subjectRatios;
  final Map<String, double> subjectProficiency;
  final int videoSeconds;
  final int pdfSeconds;
  final int quizSeconds;
  final int pagesRead;
  final List<int> last7DaysCounts;
  final List<int> last7DaysStudySeconds;
  final List<Map<String, dynamic>> rocketHistory;
  final List<Map<String, dynamic>> testHistory;
  StatisticsSnapshot({
    required this.subjectRatios,
    required this.subjectProficiency,
    required this.videoSeconds,
    required this.pdfSeconds,
    required this.quizSeconds,
    required this.pagesRead,
    required this.last7DaysCounts,
    required this.last7DaysStudySeconds,
    required this.rocketHistory,
    required this.testHistory,
  });
}

class StatisticsService {
  static final StatisticsService instance = StatisticsService._internal();
  StatisticsService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _controller = StreamController<StatisticsSnapshot>.broadcast();
  String? _uid;

  Stream<StatisticsSnapshot> get stream => _controller.stream;

  Future<void> initialize() async {
    final isGuest = await UserService.isGuestUser();
    final user = _auth.currentUser;
    _uid = isGuest ? 'guest' : user?.uid ?? 'guest';
    await _emitSnapshot();
    _auth.authStateChanges().listen((u) async {
      final guest = await UserService.isGuestUser();
      final nextUid = guest ? 'guest' : (u?.uid ?? 'guest');
      if (_uid != nextUid) {
        _uid = nextUid;
        await _emitSnapshot();
      }
    });
  }

  String _keySubjects() => 'stats_subject_${_uid ?? 'guest'}';
  String _keySubjectProficiency() => 'stats_subject_proficiency_${_uid ?? 'guest'}';
  String _keyStudy() => 'stats_study_time_${_uid ?? 'guest'}';
  String _keyActivity() => 'stats_activity_counts_${_uid ?? 'guest'}';
  String _keyRocket() => 'stats_rocket_history_${_uid ?? 'guest'}';
  String _keyTestHistory() => 'stats_test_history_${_uid ?? 'guest'}';
  String _keyPages() => 'stats_pages_read_${_uid ?? 'guest'}';
  String _keyDailyStudy() => 'stats_daily_study_${_uid ?? 'guest'}';

  Future<void> logQuizResult(String subject, int correct, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySubjects());
    final map = raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
    final current = map[subject] as Map<String, dynamic>? ?? {'correct': 0, 'total': 0};
    final next = {
      'correct': (current['correct'] as int) + correct,
      'total': (current['total'] as int) + total,
    };
    map[subject] = next;
    await prefs.setString(_keySubjects(), jsonEncode(map));
    final score = total > 0 ? ((correct / total) * 100).roundToDouble() : 0.0;
    final profRaw = prefs.getString(_keySubjectProficiency());
    final profMap = profRaw != null ? Map<String, double>.from((jsonDecode(profRaw) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))) : _defaultProficiency();
    final currentAvg = profMap[subject] ?? 0.0;
    final newAvg = currentAvg == 0.0 ? score : ((currentAvg + score) / 2.0);
    profMap[subject] = newAvg.clamp(0.0, 100.0);
    await prefs.setString(_keySubjectProficiency(), jsonEncode(profMap));
    await _emitSnapshot();
  }

  Future<void> logStudyTime({int video = 0, int pdf = 0, int quiz = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyStudy());
    final m = raw != null ? jsonDecode(raw) as Map<String, dynamic> : {'video': 0, 'pdf': 0, 'quiz': 0};
    m['video'] = (m['video'] as int) + video;
    m['pdf'] = (m['pdf'] as int) + pdf;
    m['quiz'] = (m['quiz'] as int) + quiz;
    await prefs.setString(_keyStudy(), jsonEncode(m));
    // Update per-day study aggregation
    final dailyRaw = prefs.getString(_keyDailyStudy());
    final daily = dailyRaw != null ? jsonDecode(dailyRaw) as Map<String, dynamic> : {};
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).toIso8601String().split('T').first;
    final dayEntry = daily[day] as Map<String, dynamic>? ?? {'video': 0, 'pdf': 0, 'quiz': 0};
    dayEntry['video'] = (dayEntry['video'] as int) + video;
    dayEntry['pdf'] = (dayEntry['pdf'] as int) + pdf;
    dayEntry['quiz'] = (dayEntry['quiz'] as int) + quiz;
    daily[day] = dayEntry;
    await prefs.setString(_keyDailyStudy(), jsonEncode(daily));
    await _emitSnapshot();
  }

  Future<void> logDailyActivity({int increment = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyActivity());
    final map = raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).toIso8601String().split('T').first;
    final current = map[day] as int? ?? 0;
    map[day] = current + increment;
    await prefs.setString(_keyActivity(), jsonEncode(map));
    await _emitSnapshot();
  }

  Future<void> logRocketEarned(int delta) async {
    final profile = await UserService().getCurrentUserProfile(useCache: true);
    if (profile != null) {
      await CurrencyService.instance.add(profile, delta);
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRocket());
    final list = raw != null ? (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).toIso8601String().split('T').first;
    int total = 0;
    if (profile != null) {
      total = await CurrencyService.instance.loadBalance(profile);
    } else {
      if (list.isNotEmpty) {
        total = list.last['total'] as int;
        total += delta;
      } else {
        total = delta;
      }
    }
    final existingIndex = list.indexWhere((e) => e['date'] == day);
    if (existingIndex >= 0) {
      list[existingIndex] = {'date': day, 'total': total};
    } else {
      list.add({'date': day, 'total': total});
    }
    await prefs.setString(_keyRocket(), jsonEncode(list));
    await _emitSnapshot();
  }

  Future<void> logTestCompleted({
    required String lesson,
    required String source,
    required int correct,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTestHistory());
    final list = raw != null ? (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day).toIso8601String().split('T').first;
    final percentage = total > 0 ? ((correct / total) * 100).round() : 0;
    list.insert(0, {
      'lesson': lesson,
      'source': source,
      'percentage': percentage,
      'date': date,
      'correct': correct,
      'total': total,
    });
    // keep last 50
    while (list.length > 50) {
      list.removeLast();
    }
    await prefs.setString(_keyTestHistory(), jsonEncode(list));
    await _emitSnapshot();
  }

  Future<void> incrementPageCount(int delta) async {
    if (delta <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyPages()) ?? 0;
    final next = current + delta;
    await prefs.setInt(_keyPages(), next);
    await _emitSnapshot();
  }

  Future<StatisticsSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsRaw = prefs.getString(_keySubjects());
    final subjectProficiencyRaw = prefs.getString(_keySubjectProficiency());
    final studyRaw = prefs.getString(_keyStudy());
    final activityRaw = prefs.getString(_keyActivity());
    final rocketRaw = prefs.getString(_keyRocket());
    final testHistoryRaw = prefs.getString(_keyTestHistory());
    final pagesRead = prefs.getInt(_keyPages()) ?? 0;
    final dailyStudyRaw = prefs.getString(_keyDailyStudy());

    final subjectStats = subjectsRaw != null ? jsonDecode(subjectsRaw) as Map<String, dynamic> : {};
    final ratios = <String, double>{};
    subjectStats.forEach((k, v) {
      final m = v as Map<String, dynamic>;
      final total = (m['total'] as int?) ?? 0;
      final correct = (m['correct'] as int?) ?? 0;
      ratios[k] = total > 0 ? correct / total : 0.0;
    });
    var proficiency = subjectProficiencyRaw != null
        ? Map<String, double>.from((jsonDecode(subjectProficiencyRaw) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
        : _defaultProficiency();

    final study = studyRaw != null ? jsonDecode(studyRaw) as Map<String, dynamic> : {'video': 0, 'pdf': 0, 'quiz': 0};
    final videoSeconds = (study['video'] as int?) ?? 0;
    final pdfSeconds = (study['pdf'] as int?) ?? 0;
    final quizSeconds = (study['quiz'] as int?) ?? 0;

    var activityMap = activityRaw != null ? jsonDecode(activityRaw) as Map<String, dynamic> : {};
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      return d.toIso8601String().split('T').first;
    });
    final last7 = days.map((d) => (activityMap[d] as int?) ?? 0).toList();
    final dailyStudyMap = dailyStudyRaw != null ? jsonDecode(dailyStudyRaw) as Map<String, dynamic> : {};
    final last7StudySeconds = days.map((d) {
      final entry = dailyStudyMap[d] as Map<String, dynamic>?;
      if (entry == null) return 0;
      return ((entry['video'] as int?) ?? 0) + ((entry['pdf'] as int?) ?? 0) + ((entry['quiz'] as int?) ?? 0);
    }).toList();

    final rocketList = rocketRaw != null ? (jsonDecode(rocketRaw) as List).map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    final tests = testHistoryRaw != null ? (jsonDecode(testHistoryRaw) as List).map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

    if (ratios.isEmpty && tests.isNotEmpty) {
      final aggregate = <String, Map<String, int>>{};
      for (final t in tests) {
        final lesson = (t['lesson'] as String?) ?? 'Unknown';
        final correct = (t['correct'] as int?) ?? 0;
        final total = (t['total'] as int?) ?? 0;
        final entry = aggregate[lesson] ?? {'correct': 0, 'total': 0};
        entry['correct'] = (entry['correct'] ?? 0) + correct;
        entry['total'] = (entry['total'] ?? 0) + total;
        aggregate[lesson] = entry;
      }
      aggregate.forEach((k, v) {
        final total = v['total'] ?? 0;
        final correct = v['correct'] ?? 0;
        ratios[k] = total > 0 ? correct / total : 0.0;
      });
    }
    if (tests.isNotEmpty) {
      final aggregate = <String, Map<String, int>>{};
      for (final t in tests) {
        final lesson = (t['lesson'] as String?) ?? 'Unknown';
        final correct = (t['correct'] as int?) ?? 0;
        final total = (t['total'] as int?) ?? 0;
        final entry = aggregate[lesson] ?? {'correct': 0, 'total': 0};
        entry['correct'] = (entry['correct'] ?? 0) + correct;
        entry['total'] = (entry['total'] ?? 0) + total;
        aggregate[lesson] = entry;
      }
      aggregate.forEach((k, v) {
        final total = v['total'] ?? 0;
        final correct = v['correct'] ?? 0;
        final pct = total > 0 ? (correct * 100.0) / total : 0.0;
        if (proficiency.containsKey(k)) {
          proficiency[k] = pct;
        } else {
          proficiency[k] = pct;
        }
      });
    }

    if (activityMap.isEmpty && tests.isNotEmpty) {
      final byDate = <String, int>{};
      for (final t in tests) {
        final date = (t['date'] as String?) ?? now.toIso8601String().split('T').first;
        final total = (t['total'] as int?) ?? 0;
        byDate[date] = (byDate[date] ?? 0) + total;
      }
      activityMap = byDate;
    }

    return StatisticsSnapshot(
      subjectRatios: ratios,
      subjectProficiency: proficiency,
      videoSeconds: videoSeconds,
      pdfSeconds: pdfSeconds,
      quizSeconds: quizSeconds,
      pagesRead: pagesRead,
      last7DaysCounts: last7,
      last7DaysStudySeconds: last7StudySeconds,
      rocketHistory: rocketList,
      testHistory: tests,
    );
  }

  Future<void> _emitSnapshot() async {
    final snap = await loadSnapshot();
    _controller.add(snap);
  }

  Map<String, double> _defaultProficiency() {
    return {
      'Matematik': 0.0,
      'Türkçe': 0.0,
      'Fizik': 0.0,
      'Kimya': 0.0,
      'Biyoloji': 0.0,
      'Tarih': 0.0,
      'Coğrafya': 0.0,
      'Felsefe': 0.0,
    };
  }
}
