import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'currency_service.dart';

class StatisticsSnapshot {
  final Map<String, double> subjectRatios;
  final int videoSeconds;
  final int pdfSeconds;
  final int quizSeconds;
  final List<int> last7DaysCounts;
  final List<Map<String, dynamic>> rocketHistory;
  final List<Map<String, dynamic>> testHistory;
  StatisticsSnapshot({
    required this.subjectRatios,
    required this.videoSeconds,
    required this.pdfSeconds,
    required this.quizSeconds,
    required this.last7DaysCounts,
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
  }

  String _keySubjects() => 'stats_subject_${_uid ?? 'guest'}';
  String _keyStudy() => 'stats_study_time_${_uid ?? 'guest'}';
  String _keyActivity() => 'stats_activity_counts_${_uid ?? 'guest'}';
  String _keyRocket() => 'stats_rocket_history_${_uid ?? 'guest'}';
  String _keyTestHistory() => 'stats_test_history_${_uid ?? 'guest'}';

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

  Future<StatisticsSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsRaw = prefs.getString(_keySubjects());
    final studyRaw = prefs.getString(_keyStudy());
    final activityRaw = prefs.getString(_keyActivity());
    final rocketRaw = prefs.getString(_keyRocket());
    final testHistoryRaw = prefs.getString(_keyTestHistory());

    final subjectStats = subjectsRaw != null ? jsonDecode(subjectsRaw) as Map<String, dynamic> : {};
    final ratios = <String, double>{};
    subjectStats.forEach((k, v) {
      final m = v as Map<String, dynamic>;
      final total = (m['total'] as int?) ?? 0;
      final correct = (m['correct'] as int?) ?? 0;
      ratios[k] = total > 0 ? correct / total : 0.0;
    });

    final study = studyRaw != null ? jsonDecode(studyRaw) as Map<String, dynamic> : {'video': 0, 'pdf': 0, 'quiz': 0};
    final videoSeconds = (study['video'] as int?) ?? 0;
    final pdfSeconds = (study['pdf'] as int?) ?? 0;
    final quizSeconds = (study['quiz'] as int?) ?? 0;

    final activityMap = activityRaw != null ? jsonDecode(activityRaw) as Map<String, dynamic> : {};
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      return d.toIso8601String().split('T').first;
    });
    final last7 = days.map((d) => (activityMap[d] as int?) ?? 0).toList();

    final rocketList = rocketRaw != null ? (jsonDecode(rocketRaw) as List).map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    final tests = testHistoryRaw != null ? (jsonDecode(testHistoryRaw) as List).map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

    return StatisticsSnapshot(
      subjectRatios: ratios,
      videoSeconds: videoSeconds,
      pdfSeconds: pdfSeconds,
      quizSeconds: quizSeconds,
      last7DaysCounts: last7,
      rocketHistory: rocketList,
      testHistory: tests,
    );
  }

  Future<void> _emitSnapshot() async {
    final snap = await loadSnapshot();
    _controller.add(snap);
  }
}
