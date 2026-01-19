import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit to manage app locale/language
class LocaleCubit extends Cubit<Locale> {
  static const String _localeKey = 'app_locale';

  LocaleCubit() : super(const Locale('en')) {
    _loadLocale();
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey);

      if (languageCode != null) {
        emit(Locale(languageCode));
      }
    } catch (e) {
      // If loading fails, keep default English
      emit(const Locale('en'));
    }
  }

  /// Change app language
  Future<void> setLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
      emit(Locale(languageCode));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get current language name
  String getLanguageName() {
    switch (state.languageCode) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      default:
        return 'English';
    }
  }

  /// Get current language code
  String get currentLanguageCode => state.languageCode;
}
