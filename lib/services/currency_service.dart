import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class CurrencyService {
  static final CurrencyService instance = CurrencyService._internal();
  CurrencyService._internal();

  String _keyForUser(String userId) => 'rocket_balance_$userId';
  String _scoreKeyForUser(String userId) => 'leaderboard_score_$userId';

  Future<int> loadBalance(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyForUser(profile.userId);
      final saved = prefs.getInt(key);
      if (saved != null) {
        return saved;
      }
      final initial = profile.rocketCurrency;
      await prefs.setInt(key, initial);
      return initial;
    } catch (e) {
      debugPrint('⚠️ Currency load error: $e');
      return profile.rocketCurrency;
    }
  }

  Future<int> loadScore(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _scoreKeyForUser(profile.userId);
      final saved = prefs.getInt(key);
      if (saved != null) {
        return saved;
      }
      final initial = profile.leaderboardScore;
      await prefs.setInt(key, initial);
      return initial;
    } catch (e) {
      debugPrint('⚠️ Score load error: $e');
      return profile.leaderboardScore;
    }
  }

  Future<void> saveBalance(UserProfile profile, int amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyForUser(profile.userId);
      await prefs.setInt(key, amount);
      debugPrint('✅ Rocket balance saved: $amount');
    } catch (e) {
      debugPrint('❌ Currency save error: $e');
    }
  }
  
  Future<void> saveScore(UserProfile profile, int amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _scoreKeyForUser(profile.userId);
      await prefs.setInt(key, amount);
      debugPrint('✅ Leaderboard score saved: $amount');
    } catch (e) {
      debugPrint('❌ Score save error: $e');
    }
  }

  Future<void> add(UserProfile profile, int delta) async {
    if (delta == 0) return;
    
    // Update Spendable Balance
    final currentBalance = await loadBalance(profile);
    final nextBalance = currentBalance + delta;
    await saveBalance(profile, nextBalance);
    
    // Update Leaderboard Score (Only on gain, never decrease)
    if (delta > 0) {
      final currentScore = await loadScore(profile);
      final nextScore = currentScore + delta;
      await saveScore(profile, nextScore);
    }
  }
  
  /// Special method for spending currency
  /// Reduces balance but NOT leaderboard score
  Future<bool> spend(UserProfile profile, int amount) async {
    if (amount <= 0) return false;
    final current = await loadBalance(profile);
    if (current < amount) return false;
    
    final next = current - amount;
    await saveBalance(profile, next);
    return true;
  }
}
