import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'search_history_item.dart';
import 'favorite_item.dart';
import 'profile.dart'; // Import UserProfile
import 'what_if_history_item.dart'; // Import WhatIfHistoryItem

class StorageService {
  static const String _searchHistoryKey = 'search_history';
  static const String _favoritesKey = 'favorites';
  static const String _whatIfHistoryKey = 'what_if_history'; // New key
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _acceptedTermsKey = 'acceptedTerms';
  static const String _currentUserIdKey = 'current_user_id';
  static const String _allUserIdsKey = 'all_user_ids';
  static const String _userPrefix = 'user_'; // Prefix for user-specific keys
  static const String _profilesKey = 'user_profiles';

  final Uuid _uuid = Uuid();

  // Helper to get user-specific key
  Future<String> _userKey(String baseKey, {String? userId}) async {
    final id = userId ?? await getCurrentUserId();
    if (id == null) {
      return baseKey; // Fallback, but ideally should not happen for user-specific data
    }
    return '$_userPrefix${id}_$baseKey';
  }

  // Profile Management
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    List<UserProfile> profiles = await getProfiles();
    int index = profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await prefs.setString(_profilesKey, json.encode(profiles.map((p) => p.toMap()).toList()));
  }

  Future<List<UserProfile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    String? profilesString = prefs.getString(_profilesKey);
    if (profilesString != null) {
      List<dynamic> jsonList = json.decode(profilesString);
      return jsonList.map((json) => UserProfile.fromMap(json)).toList();
    }
    return [];
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final currentUserId = await getCurrentUserId();
    if (currentUserId != null) {
      final profiles = await getProfiles();
      return profiles.where((p) => p.id == currentUserId).firstOrNull;
    }
    return null;
  }

  // User Management
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey);
  }

  Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
  }

  Future<void> saveUser(String userId, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = '$_userPrefix${userId}_credentials';
    final userData = json.encode({'email': email, 'password': password});
    await prefs.setString(userKey, userData);

    // Add user ID to the list of all user IDs
    final allUserIds = prefs.getStringList(_allUserIdsKey) ?? [];
    if (!allUserIds.contains(userId)) {
      allUserIds.add(userId);
      await prefs.setStringList(_allUserIdsKey, allUserIds);
    }
  }

  Future<Map<String, String?>?> getUserCredentialsByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final allUserIds = prefs.getStringList(_allUserIdsKey) ?? [];

    for (String userId in allUserIds) {
      final userKey = '$_userPrefix${userId}_credentials';
      final userDataString = prefs.getString(userKey);
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['email'] == email) {
          return {'userId': userId, 'email': userData['email'], 'password': userData['password']};
        }
      }
    }
    return null;
  }

  Future<Map<String, String?>?> getUserCredentialsByUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = '$_userPrefix${userId}_credentials';
    final userDataString = prefs.getString(userKey);
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      return {'userId': userId, 'email': userData['email'], 'password': userData['password']};
    }
    return null;
  }

  Future<bool> checkUserExists(String email) async {
    final user = await getUserCredentialsByEmail(email);
    return user != null;
  }

  Future<List<String>> getAllUserIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_allUserIdsKey) ?? [];
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = await getCurrentUserId();
    if (currentUserId != null) {
      final currentLoggedInKey = await _userKey(_isLoggedInKey, userId: currentUserId);
      await prefs.setBool(currentLoggedInKey, false);
    }
    await prefs.remove(_currentUserIdKey);
  }

  Future<void> deleteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    print('Attempting to delete user: $userId');

    // Remove user-specific data
    final credentialsKey = '$_userPrefix${userId}_credentials';
    final searchHistoryKey = '$_userPrefix${userId}_$_searchHistoryKey';
    final favoritesKey = '$_userPrefix${userId}_$_favoritesKey';
    final isLoggedInKey = '$_userPrefix${userId}_$_isLoggedInKey';
    final acceptedTermsKey = '$_userPrefix${userId}_$_acceptedTermsKey';
    final userPointsKey = '$_userPrefix${userId}_user_points';
    final isFirstTimeKey = '$_userPrefix${userId}_$_isFirstTimeKey';
    final whatIfHistoryKey = '$_userPrefix${userId}_$_whatIfHistoryKey';

    print('Removing key: $credentialsKey');
    await prefs.remove(credentialsKey);
    print('Removing key: $searchHistoryKey');
    await prefs.remove(searchHistoryKey);
    print('Removing key: $favoritesKey');
    await prefs.remove(favoritesKey);
    print('Removing key: $isLoggedInKey');
    await prefs.remove(isLoggedInKey);
    print('Removing key: $acceptedTermsKey');
    await prefs.remove(acceptedTermsKey);
    print('Removing key: $userPointsKey');
    await prefs.remove(userPointsKey);
    print('Removing key: $isFirstTimeKey');
    await prefs.remove(isFirstTimeKey);
    print('Removing key: $whatIfHistoryKey');
    await prefs.remove(whatIfHistoryKey);


    // Remove weather data for this user
    final allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (key.startsWith('$_userPrefix${userId}_weather_')) {
        print('Removing weather key: $key');
        await prefs.remove(key);
      }
    }


    // Remove user ID from the list of all user IDs
    final allUserIds = prefs.getStringList(_allUserIdsKey) ?? [];
    print('All user IDs before removal: $allUserIds');
    allUserIds.remove(userId);
    print('All user IDs after removal: $allUserIds');
    await prefs.setStringList(_allUserIdsKey, allUserIds);

    // If the deleted user was the current user, log out
    final currentUserId = await getCurrentUserId();
    if (currentUserId == userId) {
      print('Deleted user was current user, logging out.');
      await logout();
    }

    // Remove the profile from the list of profiles
    List<UserProfile> profiles = await getProfiles();
    print('Profiles before removal: ${profiles.map((p) => p.id).toList()}');
    profiles.removeWhere((p) => p.id == userId);
    print('Profiles after removal: ${profiles.map((p) => p.id).toList()}');
    await prefs.setString(_profilesKey, json.encode(profiles.map((p) => p.toMap()).toList()));
    print('User $userId deleted successfully.');
  }

  // Existing methods updated to be user-specific
  Future<void> saveSearchHistory(SearchHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_searchHistoryKey);
    final history = await getSearchHistory();
    history.insert(0, item);
    await prefs.setStringList(
        userSpecificKey, history.map((i) => json.encode(i.toJson())).toList());
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_searchHistoryKey);
    await prefs.remove(userSpecificKey);
  }

  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_searchHistoryKey);
    final historyStringList = prefs.getStringList(userSpecificKey) ?? [];
    return historyStringList
        .map((item) => SearchHistoryItem.fromJson(json.decode(item)))
        .toList();
  }

  Future<void> saveFavorite(FavoriteItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_favoritesKey);
    final favorites = await getFavorites();
    // Ensure the item has an ID before saving
    final itemToSave = item.id.isEmpty ? FavoriteItem(id: _uuid.v4(), district: item.district, recommendation: item.recommendation, dateTime: item.dateTime) : item;
    favorites.insert(0, itemToSave);
    await prefs.setStringList(
        userSpecificKey, favorites.map((i) => json.encode(i.toJson())).toList());
  }

  Future<void> removeFavorite(String favoriteId) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_favoritesKey);
    List<FavoriteItem> favorites = await getFavorites();
    favorites.removeWhere((item) => item.id == favoriteId);
    await prefs.setStringList(
        userSpecificKey, favorites.map((i) => json.encode(i.toJson())).toList());
  }

  Future<bool> isFavorite(String district, String recommendation) async {
    final favorites = await getFavorites();
    return favorites.any((item) => item.district == district && item.recommendation == recommendation);
  }

  Future<List<FavoriteItem>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_favoritesKey);
    final favoritesStringList = prefs.getStringList(userSpecificKey) ?? [];
    return favoritesStringList
        .map((item) => FavoriteItem.fromJson(json.decode(item)))
        .toList();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_isLoggedInKey);
    return prefs.getBool(userSpecificKey) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_isLoggedInKey);
    await prefs.setBool(userSpecificKey, value);
  }

  Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_acceptedTermsKey);
    return prefs.getBool(userSpecificKey) ?? false;
  }

  Future<void> setAcceptedTerms(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_acceptedTermsKey);
    await prefs.setBool(userSpecificKey, value);
  }

  static const String _isFirstTimeKey = 'isFirstTime';

  Future<bool> isFirstTime({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_isFirstTimeKey, userId: userId);
    return prefs.getBool(userSpecificKey) ?? true;
  }

  Future<void> setFirstTime(bool value, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_isFirstTimeKey, userId: userId);
    await prefs.setBool(userSpecificKey, value);
  }

  Future<void> saveWeatherData(String district, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey('weather_$district');
    await prefs.setString(userSpecificKey, json.encode(data));
  }

  Future<Map<String, dynamic>?> getWeatherData(String district) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey('weather_$district');
    final data = prefs.getString(userSpecificKey);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  // This saveData and readData might need to be re-evaluated if they are used for user-specific data
  // For now, they remain as-is, assuming they are for global data or their keys are already user-specific.
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  Future<Map<String, dynamic>?> readData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  static const String _pointsKey = 'user_points';

  Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_pointsKey);
    return prefs.getInt(userSpecificKey) ?? 0;
  }

  Future<void> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_pointsKey);
    int currentPoints = await getPoints();
    await prefs.setInt(userSpecificKey, currentPoints + points);
  }

  // What If Analysis History
  Future<void> saveWhatIfHistory(WhatIfHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_whatIfHistoryKey);
    final history = await getWhatIfHistory();
    history.insert(0, item);
    await prefs.setStringList(
        userSpecificKey, history.map((i) => json.encode(i.toJson())).toList());
  }

  Future<List<WhatIfHistoryItem>> getWhatIfHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userSpecificKey = await _userKey(_whatIfHistoryKey);
    final historyStringList = prefs.getStringList(userSpecificKey) ?? [];
    return historyStringList
        .map((item) => WhatIfHistoryItem.fromJson(json.decode(item)))
        .toList();
  }
}