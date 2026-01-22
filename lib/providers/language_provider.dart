import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ko'); // 기본값 한국어

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLocale(); // 앱 시작 시 저장된 언어 불러오기
  }

  // ✅ 저장된 언어 불러오기
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  // ✅ 언어 변경 및 저장
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }
}