import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class CurrencyService {
  static final CurrencyService instance = CurrencyService._internal();
  CurrencyService._internal();

  String _keyForUser(String userId) => 'rocket_balance_$userId';

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

  Future<void> add(UserProfile profile, int delta) async {
    if (delta == 0) return;
    final current = await loadBalance(profile);
    final next = current + delta;
    await saveBalance(profile, next);
  }
}
