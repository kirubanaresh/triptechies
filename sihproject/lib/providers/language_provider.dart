import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _appLocale = const Locale('en');

  Locale get appLocale => _appLocale;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      _appLocale = Locale(langCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(Locale type) async {
    final prefs = await SharedPreferences.getInstance();
    if (_appLocale == type) return;
    
    if (type == const Locale('ta')) {
      _appLocale = const Locale('ta');
      await prefs.setString('language_code', 'ta');
    } else if (type == const Locale('hi')) {
      _appLocale = const Locale('hi');
      await prefs.setString('language_code', 'hi');
    } else if (type == const Locale('fr')) {
      _appLocale = const Locale('fr');
      await prefs.setString('language_code', 'fr');
    } else if (type == const Locale('de')) {
      _appLocale = const Locale('de');
      await prefs.setString('language_code', 'de');
    } else {
      _appLocale = const Locale('en');
      await prefs.setString('language_code', 'en');
    }
    notifyListeners();
  }
}
