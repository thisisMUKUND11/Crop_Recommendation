import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_history_item.dart';
import 'favorite_item.dart';

class StorageService {
  static const String _searchHistoryKey = 'search_history';
  static const String _favoritesKey = 'favorites';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _acceptedTermsKey = 'acceptedTerms';
  static const String _emailKey = 'email';
  static const String _passwordKey = 'password';

  Future<void> saveSearchHistory(SearchHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    history.insert(0, item);
    await prefs.setStringList(
        _searchHistoryKey, history.map((i) => json.encode(i.toJson())).toList());
  }

  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStringList = prefs.getStringList(_searchHistoryKey) ?? [];
    return historyStringList
        .map((item) => SearchHistoryItem.fromJson(json.decode(item)))
        .toList();
  }

  Future<void> saveFavorite(FavoriteItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.insert(0, item);
    await prefs.setStringList(
        _favoritesKey, favorites.map((i) => json.encode(i.toJson())).toList());
  }

  Future<List<FavoriteItem>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesStringList = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesStringList
        .map((item) => FavoriteItem.fromJson(json.decode(item)))
        .toList();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptedTermsKey) ?? false;
  }

  Future<void> setAcceptedTerms(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_acceptedTermsKey, value);
  }

  Future<void> saveUserCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passwordKey, password);
  }

  Future<Map<String, String?>> getUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);
    return {'email': email, 'password': password};
  }
}