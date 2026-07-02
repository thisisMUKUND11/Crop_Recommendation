
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = Locale('en');
  final StorageService _storageService = StorageService();

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('languageCode');
    if (savedLanguageCode != null) {
      _locale = Locale(savedLanguageCode);
      notifyListeners();
    }
  }

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
