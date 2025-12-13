import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/localization_service.dart';

// Events
abstract class LanguageEvent {}

class LanguageInitialized extends LanguageEvent {}

class LanguageChanged extends LanguageEvent {
  final String languageCode;
  LanguageChanged(this.languageCode);
}

// States
abstract class LanguageState {
  final String languageCode;
  const LanguageState(this.languageCode);
}

class LanguageLoaded extends LanguageState {
  const LanguageLoaded(super.languageCode);
}

// Bloc
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const String _languageKey = 'selected_language';

  LanguageBloc() : super(const LanguageLoaded('tr')) {
    on<LanguageInitialized>(_onLanguageInitialized);
    on<LanguageChanged>(_onLanguageChanged);
  }

  Future<void> _onLanguageInitialized(
    LanguageInitialized event,
    Emitter<LanguageState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'tr';
    await LocalizationService.setLanguage(languageCode);
    emit(LanguageLoaded(languageCode));
  }

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<LanguageState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, event.languageCode);
    await LocalizationService.setLanguage(event.languageCode);
    emit(LanguageLoaded(event.languageCode));
  }

  String get currentLanguage => state.languageCode;

  String translate(String key) {
    return LocalizationService.translate(key);
  }
} 