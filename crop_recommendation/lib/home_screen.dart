

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart'; // Added
import 'storage_service.dart';
import 'search_history_item.dart';
import 'favorite_item.dart';
import 'generated/app_localizations.dart';
import 'settings_screen.dart';
import 'notification_service.dart'; // Import NotificationService
import 'what_if_history_screen.dart'; // Import WhatIfHistoryScreen

import 'crop_planner_screen.dart';
import 'what_if_screen.dart';
import 'market_price_service.dart';
import 'sustainability_service.dart';
import 'quiz_service.dart';
import 'quiz_screen.dart';

import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _marketLocationController = TextEditingController();
  String _selectedLanguage = 'en';
  String _recommendation = '';
  bool _isLoading = false;
  final StorageService _storageService = StorageService();
  final Uuid _uuid = Uuid(); // Added
  final MarketPriceService _marketPriceService = MarketPriceService();
  final SustainabilityService _sustainabilityService = SustainabilityService();
  final NotificationService _notificationService = NotificationService(); // Instantiate NotificationService
  final QuizService _quizService = QuizService();
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  Map<String, dynamic> _marketPricesData = {}; // Renamed to avoid conflict with _marketPrices in _getOnlineRecommendation
  bool _isLoadingMarketPrices = true;
  String? _marketPricesError;

  late AnimationController _quizButtonAnimationController;
  late Animation<double> _quizButtonAnimation;
  late AnimationController _leaderboardButtonAnimationController;
  late Animation<double> _leaderboardButtonAnimation;

  bool _isQuizCompletedToday = false;
  bool _hasViewedLeaderboardAfterQuiz = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _loadLocalRecommendations();
    _fetchMarketPrices(); // Call the new method here
    _districtController.addListener(() {
      _marketLocationController.text = _districtController.text;
    });

    _quizButtonAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _quizButtonAnimation = Tween(begin: 1.0, end: 0.5).animate(_quizButtonAnimationController);

    _leaderboardButtonAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _leaderboardButtonAnimation = Tween(begin: 1.0, end: 0.5).animate(_leaderboardButtonAnimationController);

    _checkQuizAndLeaderboardStatus();
  }

  Future<void> _checkQuizAndLeaderboardStatus() async {
    final currentUserId = await _storageService.getCurrentUserId();
    if (currentUserId != null) {
      final profiles = await _storageService.getProfiles();
      final currentUserProfile = profiles.where((p) => p.id == currentUserId).firstOrNull;
      if (currentUserProfile == null || !mounted) return;

      final today = DateTime.now().toIso8601String().substring(0, 10);

      setState(() {
        _isQuizCompletedToday = (currentUserProfile.lastQuizDate == today);
        _hasViewedLeaderboardAfterQuiz = currentUserProfile.hasViewedLeaderboardAfterQuiz;
      });

      if (_isQuizCompletedToday && !_hasViewedLeaderboardAfterQuiz) {
        _quizButtonAnimationController.stop();
        _leaderboardButtonAnimationController.repeat(reverse: true);
      } else if (!_isQuizCompletedToday) {
        _leaderboardButtonAnimationController.stop();
        _quizButtonAnimationController.repeat(reverse: true);
      } else {
        _quizButtonAnimationController.stop();
        _leaderboardButtonAnimationController.stop();
      }
    }
  }

  Future<void> _startDailyQuiz() async {
    final currentUserId = await _storageService.getCurrentUserId();
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a profile first.')),
      );
      return;
    }

    final profiles = await _storageService.getProfiles();
    final currentUserProfile = profiles.where((p) => p.id == currentUserId).firstOrNull;
    if (currentUserProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a profile first.')),
      );
      return;
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (currentUserProfile.lastQuizDate == today && currentUserProfile.dailyQuizQuestions != null) {
      // Quiz already taken today, navigate to review or inform user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already completed the quiz today. Reviewing your answers.')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(questions: currentUserProfile.dailyQuizQuestions!))).then((_) {
        _checkQuizAndLeaderboardStatus(); // Recheck status after returning from quiz
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final questions = await _quizService.generateQuizQuestions(_geminiApiKey, _selectedLanguage);
      currentUserProfile.dailyQuizQuestions = questions;
      currentUserProfile.lastQuizDate = today; // Mark quiz as taken today
      await _storageService.saveProfile(currentUserProfile);

      setState(() {
        _isQuizCompletedToday = true;
        _hasViewedLeaderboardAfterQuiz = false; // Reset this flag
      });
      _quizButtonAnimationController.stop();
      _leaderboardButtonAnimationController.repeat(reverse: true); // Start leaderboard animation

      Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(questions: questions))).then((_) {
        _checkQuizAndLeaderboardStatus(); // Recheck status after returning from quiz
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load quiz questions: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // connectivity_plus >= 6 returns a list of results; [none] means offline.
  Future<bool> _isOffline() async {
    final results = await Connectivity().checkConnectivity();
    return results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  }

  Future<void> _fetchMarketPrices({String? location}) async {
    location = location?.trim();
    setState(() {
      _isLoadingMarketPrices = true;
      _marketPricesError = null;
    });
    try {
      if (await _isOffline()) {
        // No internet, try to load from cache
        final cachedData = await _storageService.readData('market_prices_${location ?? 'default'}');
        if (!mounted) return;
        if (cachedData != null) {
          setState(() {
            _marketPricesData = cachedData.cast<String, dynamic>();
            _isLoadingMarketPrices = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Showing cached market prices (offline).')),
          );
          return;
        } else {
          throw Exception('No internet connection and no cached data available.');
        }
      }

      final service = MarketPriceService();
      final cropList = _cropSeasonSuggestions.keys.toList(); // Get all crop names
      final data = await service.getPrices(cropList, location: location);
      if (!mounted) return;
      setState(() {
        _marketPricesData = data;
        _isLoadingMarketPrices = false;
      });
      // Save to cache
      await _storageService.saveData('market_prices_${location ?? 'default'}', data.cast<String, dynamic>());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _marketPricesError = 'Failed to load market prices: $e';
        _isLoadingMarketPrices = false;
      });
    }
  }

  Map<String, Map<String, String>> _cropSeasonSuggestions = {
    "Wheat": {"planting": "October-November", "harvesting": "March-April"},
    "Mustard": {"planting": "September-October", "harvesting": "February-March"},
    "Barley": {"planting": "October-November", "harvesting": "March-April"},
    "Potato": {"planting": "September-October", "harvesting": "January-February"},
    "Peas": {"planting": "October-November", "harvesting": "February-March"},
    "Rice": {"planting": "June-July", "harvesting": "November-December"},
    "Coconut": {"planting": "May-June", "harvesting": "Throughout the year"},
    "Sugarcane": {"planting": "February-March", "harvesting": "January-March (next year)"},
    "Cotton": {"planting": "April-May", "harvesting": "October-December"},
    "Ragi": {"planting": "June-July", "harvesting": "September-October"},
    "Groundnut": {"planting": "June-July", "harvesting": "October-November"},
    "Jowar": {"planting": "June-July", "harvesting": "October-November"},
    "Bajra": {"planting": "July-August", "harvesting": "October-November"},
    "Soybean": {"planting": "June-July", "harvesting": "September-October"},
    "Jute": {"planting": "March-April", "harvesting": "July-August"},
    "Tea": {"planting": "Throughout the year", "harvesting": "Throughout the year"},
    "Maize": {"planting": "June-July", "harvesting": "September-October"},
    "Pulses": {"planting": "June-July", "harvesting": "September-October"},
  };

  Map<String, dynamic>? _localRecommendations;
  Map<String, dynamic>? _weatherData;
  String? _weatherError;
  Map<String, dynamic>? _marketPrices;
  Map<String, Map<String, dynamic>>? _sustainabilityData;
  // English crop names drive price/sustainability lookups; translated names
  // (when a non-English language is selected) are only used for display.
  List<String> _recommendedCrops = [];
  Map<String, String> _translatedCropNames = {};
  String? _recommendationNote;

  // Gemini sometimes returns numbered/bulleted lists or newlines instead of a
  // plain comma-separated line, so normalise before splitting.
  List<String> _parseCropList(String text) {
    return text
        .split(RegExp(r'[,\n]'))
        .map((e) => e.replaceAll(RegExp(r'^\s*(\d+[.)]|[-*•])\s*'), '').replaceAll('*', '').trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .toList();
  }


  @override
  void dispose() {
    _districtController.dispose();
    _marketLocationController.dispose();
    _speech.stop();
    _flutterTts.stop();
    _quizButtonAnimationController.dispose();
    _leaderboardButtonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalRecommendations() async {
    try {
      final String data = await rootBundle.loadString('assets/local_recommendations.json');
      if (!mounted) return;
      setState(() {
        _localRecommendations = json.decode(data);
      });
    } catch (e) {
      // If asset not present, keep null and allow offline handler to error gracefully.
      debugPrint('Could not load local recommendations: $e');
    }
  }

  Future<void> _getWeather(String district) async {
    district = district.trim();
    if (district.isEmpty) return;
    _weatherError = null;
    // Clear the previous district's weather so a failed lookup can't silently
    // reuse stale data for the new district.
    if (mounted) {
      setState(() {
        _weatherData = null;
      });
    }
    try {
      if (_weatherApiKey.isEmpty) {
        _weatherError =
            'Weather API key is missing. Run with --dart-define-from-file=env.json.';
        debugPrint(_weatherError);
        return;
      }
      final weatherUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(district)},IN&appid=$_weatherApiKey&units=metric');
      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode != 200) {
        // Capture the real reason so the caller can surface it to the user.
        if (weatherResponse.statusCode == 404) {
          _weatherError =
              'District "$district" not found. Check the spelling or try a nearby city.';
        } else if (weatherResponse.statusCode == 401) {
          _weatherError =
              'Weather API key is invalid or not yet activated (new keys take a few hours).';
        } else {
          _weatherError =
              'Weather service error (${weatherResponse.statusCode}).';
        }
        debugPrint("Failed to fetch weather data: ${weatherResponse.body}");
        return;
      }

      final weatherData = json.decode(weatherResponse.body);
      await _storageService.saveWeatherData(district.toLowerCase(), weatherData);
      if (mounted) {
        setState(() {
          _weatherData = weatherData;
        });
      }
    } catch (e) {
      _weatherError = 'Could not reach the weather service. Check your internet connection.';
      debugPrint("Failed to get weather: $e");
    }
  }

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'ta', 'name': 'Tamil'},
    {'code': 'te', 'name': 'Telugu'},
    {'code': 'kn', 'name': 'Kannada'},
    {'code': 'ml', 'name': 'Malayalam'},
    {'code': 'bn', 'name': 'Bengali'},
    {'code': 'mr', 'name': 'Marathi'},
    {'code': 'gu', 'name': 'Gujarati'},
    {'code': 'pa', 'name': 'Punjabi'},
  ];

  // API keys are injected at build time via --dart-define so they are never
  // committed to source control. See README ("Configuration") for usage, e.g.
  //   flutter run --dart-define=WEATHER_API_KEY=xxx --dart-define=GEMINI_API_KEY=yyy
  static const String _weatherApiKey =
      String.fromEnvironment('WEATHER_API_KEY');
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = false;
      try {
        available = await _speech.initialize(
          onStatus: (val) {
            if (val == "done") {
              setState(() => _isListening = false);
            }
          },
          onError: (val) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.speakAgain)),
            );
            setState(() => _isListening = false);
          },
        );
      } on PlatformException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition not available: ${e.message}')),
        );
        setState(() => _isListening = false);
        return; // Exit the function if speech recognition is not available
      }

      if (available) {
        bool hasPermission = await _speech.hasPermission;
        if (hasPermission) {
          setState(() => _isListening = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.listening)),
          );
          _speech.listen(
            onResult: (val) {
              setState(() {
                _districtController.text = val.recognizedWords;
                _districtController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _districtController.text.length),
                );
              });
            },
            listenFor: Duration(seconds: 10),
            pauseFor: Duration(seconds: 3),
            partialResults: true,
            localeId: "en_IN",
            cancelOnError: true,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.grantMicrophonePermission)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.speechRecognitionNotAvailable)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    // Some platforms need locale codes like "en-US" or "hi-IN".
    // If the selected language is just short code, TTS may choose fallback voice.
    try {
      await _flutterTts.setLanguage(_selectedLanguage);
      await _flutterTts.speak(text);
    } catch (e) {
      // TTS is a nice-to-have; never let it break the recommendation flow.
      debugPrint('TTS failed: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) throw Exception('No address found for this location.');
      Placemark place = placemarks[0];
      // Use subAdministrativeArea if available, else locality or administrativeArea.
      // Empty strings are common on some devices, so skip those too.
      final district = [place.subAdministrativeArea, place.locality, place.administrativeArea]
          .firstWhere((s) => s != null && s.trim().isNotEmpty, orElse: () => '')!
          .trim();
      if (district.isEmpty) throw Exception('Could not determine your district.');
      if (!mounted) return;
      setState(() {
        _districtController.text = district;
      });
      await _getWeather(district);
      if (_weatherError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_weatherError!)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get your location: $e')),
      );
    }
  }

  Future<void> _getRecommendation() async {
    final district = _districtController.text.trim();
    if (district.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterDistrictName)),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _recommendation = '';
      _recommendedCrops = [];
      _translatedCropNames = {};
      _marketPrices = null;
      _sustainabilityData = null;
      _weatherData = null;
    });

    if (await _isOffline()) {
      await _getOfflineRecommendation();
    } else {
      await _getOnlineRecommendation();
    }
  }

  Future<void> _scheduleSmartReminder(String cropName, String district) async {
    final now = DateTime.now();
    final scheduledDate = now.add(Duration(days: 7)); // Example: 7 days from now
    try {
      await _notificationService.showNotification(
        0, // Notification ID
        'Smart Reminder',
        '🌾 Best time to sow $cropName is this week in $district.',
        scheduledDate,
      );
    } catch (e) {
      debugPrint('Could not schedule reminder: $e');
    }
  }

  Future<void> _checkAndSendRiskAlert(Map<String, dynamic> weatherData, String district) async {
    final temp = weatherData['main']?['temp'] ?? 0;
    final rainfall = weatherData['rain'] != null ? (weatherData['rain']['1h'] ?? 0) : 0;

    String? alertMessage;

    if (rainfall > 50) { // Example threshold for flood risk
      alertMessage = '⚠️ Flood risk detected in $district! Heavy rainfall expected.';
    } else if (rainfall < 5 && temp > 35) { // Example threshold for drought risk
      alertMessage = '⚠️ Drought risk detected in $district! Low rainfall and high temperatures.';
    } else if (temp > 40) { // Example for extreme heat
      alertMessage = '⚠️ Extreme heat warning in $district! Protect your crops.';
    } else if (temp < 5) { // Example for extreme cold
      alertMessage = '⚠️ Frost warning in $district! Protect your crops from cold.';
    }

    if (alertMessage != null) {
      try {
        await _notificationService.showNotification(
          1, // Notification ID
          'Risk Alert',
          alertMessage,
          DateTime.now().add(Duration(seconds: 5)), // Show immediately
        );
      } catch (e) {
        // A notification failure must not stop the recommendation from showing.
        debugPrint('Could not show risk alert: $e');
      }
    }
  }

  Future<void> _getOnlineRecommendation() async {
    final district = _districtController.text.trim();
    try {
      // 1. Get Weather Data
      await _getWeather(district);
      final weatherData = _weatherData; // Use the state variable

      if (weatherData == null) {
        throw Exception(
            _weatherError ?? AppLocalizations.of(context)!.couldNotFetchWeatherData);
      }
      if (_geminiApiKey.isEmpty) {
        throw Exception('Gemini API key is missing. Run with --dart-define-from-file=env.json.');
      }

      // Check and send risk alert based on current weather
      await _checkAndSendRiskAlert(weatherData, district);

      final temp = weatherData['main']?['temp'] ?? 0;
      final humidity = weatherData['main']?['humidity'] ?? 0;
      final rainfall = weatherData['rain'] != null ? (weatherData['rain']['1h'] ?? 0) : 0;

      // 2. Get Crop Recommendation from Gemini
      final geminiUrl = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey');
      final prompt =
          'Given the weather conditions in $district, India:\n- Temperature: $temp°C\n- Humidity: $humidity%\n- Rainfall: $rainfall mm\n\nRecommend 3 suitable crops for cultivation in this district.\nOutput format: Just the crop names separated by commas, no explanation.';

      final http.Response geminiResponse;
      try {
        geminiResponse = await http.post(
          geminiUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }),
        );
      } catch (e) {
        debugPrint('Error sending request to Gemini API: $e');
        throw Exception(AppLocalizations.of(context)!.couldNotFetchCropRecommendations);
      }

      if (geminiResponse.statusCode != 200) {
        if (geminiResponse.statusCode == 400 || geminiResponse.statusCode == 403) {
          debugPrint('Gemini API Error: ${geminiResponse.body}');
          throw Exception('Invalid Gemini API Key. Please check your API key.');
        } else {
          debugPrint('Gemini API Error: ${geminiResponse.statusCode}');
          debugPrint('Gemini API Response: ${geminiResponse.body}');
          throw Exception(AppLocalizations.of(context)!.couldNotFetchCropRecommendations);
        }
      }

      final geminiData = json.decode(geminiResponse.body);
      final englishOutput = (geminiData['candidates'] != null &&
              geminiData['candidates'].isNotEmpty &&
              geminiData['candidates'][0]['content'] != null &&
              geminiData['candidates'][0]['content']['parts'] != null)
          ? geminiData['candidates'][0]['content']['parts'][0]['text'].toString().trim()
          : '';

      // 3. Get Market Prices and Sustainability Data
      final crops = _parseCropList(englishOutput);
      if (crops.isEmpty) {
        throw Exception(AppLocalizations.of(context)!.couldNotFetchCropRecommendations);
      }
      final prices = await _marketPriceService.getPrices(crops, location: district);
      final sustainabilityData = <String, Map<String, dynamic>>{};
      for (var crop in crops) {
        sustainabilityData[crop] = await _sustainabilityService.getSustainabilityIndex(crop);
      }

      // 4. Translate if necessary (online). Translation is best-effort: on
      // failure we keep the English names rather than failing the request.
      final englishList = crops.join(', ');
      var translatedOutput = englishList;
      final translatedNames = <String, String>{};
      if (_selectedLanguage != 'en') {
        try {
          final translationUrl = Uri.parse(
              'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(englishList)}&langpair=en|$_selectedLanguage');
          final translationResponse = await http.get(translationUrl);
          final translationData = json.decode(translationResponse.body);
          translatedOutput = translationData['responseData']?['translatedText']?.toString() ?? englishList;
          final parts = translatedOutput.split(RegExp('[,،、]')).map((e) => e.trim()).toList();
          if (parts.length == crops.length) {
            for (var i = 0; i < crops.length; i++) {
              translatedNames[crops[i]] = parts[i];
            }
          }
        } catch (e) {
          debugPrint('Translation failed: $e');
          translatedOutput = englishList;
        }
      }

      final searchHistoryItem = SearchHistoryItem(
        district: district,
        recommendation: translatedOutput,
        dateTime: DateTime.now(),
      );
      await _storageService.saveSearchHistory(searchHistoryItem);
      await _storageService.addPoints(10);

      if (!mounted) return;
      setState(() {
        _recommendedCrops = crops;
        _translatedCropNames = translatedNames;
        _marketPrices = prices;
        _sustainabilityData = sustainabilityData;
        _recommendationNote = null;
        _recommendation = translatedOutput;
      });

      await _speak(translatedOutput);

      // Schedule smart reminder for the first recommended crop
      await _scheduleSmartReminder(crops.first, district);
    } catch (error) {
      // If the online services fail but the district is in the bundled data,
      // still show a result instead of only an error.
      bool fellBack = false;
      try {
        fellBack = await _applyOfflineRecommendation(district);
      } catch (e) {
        debugPrint('Offline fallback failed: $e');
      }
      if (mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fellBack
                ? '$message\nShowing offline suggestions instead.'
                : AppLocalizations.of(context)!.anErrorOccurred(message)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getOfflineRecommendation() async {
    final district = _districtController.text.trim();
    try {
      if (!await _applyOfflineRecommendation(district)) {
        throw Exception("District not found in local data.");
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.anErrorOccurred(error.toString().replaceFirst('Exception: ', '')))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Shows recommendations from the bundled JSON. Returns false when the
  // district isn't covered by the local data.
  Future<bool> _applyOfflineRecommendation(String district) async {
    // The asset loads asynchronously at startup; a quick search can beat it.
    if (_localRecommendations == null) await _loadLocalRecommendations();
    if (_localRecommendations == null) {
      throw Exception("Local recommendations not loaded.");
    }

    final key = district.trim().toLowerCase();
    final regions = (_localRecommendations!['regions'] as List).cast<Map<String, dynamic>>();
    final region = regions
        .where((r) => (r['districts'] as List).map((d) => d.toString().toLowerCase()).contains(key))
        .firstOrNull;
    if (region == null) return false;

    final recStrings = (region['recommendations'] as List).map((e) => e.toString()).toList();

    final prices = await _marketPriceService.getPrices(recStrings, location: district);
    final sustainabilityData = <String, Map<String, dynamic>>{};
    for (var crop in recStrings) {
      sustainabilityData[crop] = await _sustainabilityService.getSustainabilityIndex(crop);
    }

    final weatherData = _weatherData ?? await _storageService.getWeatherData(key);
    String weatherInfo;
    if (weatherData != null) {
      final temp = weatherData['main']?['temp'];
      final humidity = weatherData['main']?['humidity'];
      weatherInfo = "Cached Weather: $temp°C, $humidity% humidity";

      // Check and send risk alert based on cached weather
      await _checkAndSendRiskAlert(weatherData, district);
    } else {
      weatherInfo = "Connect to internet for more accurate recommendations";
    }

    final output = recStrings.join(', ');
    if (!mounted) return true;
    setState(() {
      _weatherData = weatherData;
      _recommendedCrops = recStrings;
      _translatedCropNames = {};
      _marketPrices = prices;
      _sustainabilityData = sustainabilityData;
      _recommendationNote = "Offline (${region['name']}) · $weatherInfo";
      _recommendation = "Offline: $output";
    });
    await _speak(output);

    // Schedule smart reminder for the first recommended crop
    if (recStrings.isNotEmpty) {
      await _scheduleSmartReminder(recStrings.first, district);
    }
    return true;
  }

  Future<void> _saveFavorite() async {
    final favoriteItem = FavoriteItem(
      id: _uuid.v4(), // Added id
      district: _districtController.text,
      recommendation: _recommendation,
      dateTime: DateTime.now(),
    );
    await _storageService.saveFavorite(favoriteItem);
    await _storageService.addPoints(5);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.savedToFavorites)),
    );
  }

  void _shareRecommendation() async {
    if (_districtController.text.isEmpty || _recommendation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noRecommendationToShare)),
      );
      return;
    }

    String shareText = 'Crop recommendations for ${_districtController.text}:\n$_recommendation';
    if (_marketPrices != null && _marketPrices!.isNotEmpty) {
      shareText += '\n\nMarket Prices:\n';
      _marketPrices!.forEach((crop, price) {
        shareText += '- $crop: ₹${price.toStringAsFixed(2)} per quintal\n';
      });
    }
    Share.share(shareText);
    await _storageService.addPoints(20);
  }

  void _shareLocalRecommendation(Map<String, dynamic> recommendation) async {
    String shareText = 'Local Crop Recommendation:\nCrop: ${recommendation['crop']}\nReason: ${recommendation['reason']}';
    Share.share(shareText);
    await _storageService.addPoints(5); // Smaller points for sharing local recs
  }

  void _onShareLocalRecommendationPressed(dynamic rec) {
    _shareLocalRecommendation(rec as Map<String, dynamic>);
  }

  Future<void> _saveFavoriteForCrop(String cropName) async {
    final favoriteItem = FavoriteItem(
      id: _uuid.v4(), // Added id
      district: _districtController.text,
      recommendation: cropName,
      dateTime: DateTime.now(),
    );
    await _storageService.saveFavorite(favoriteItem);
    await _storageService.addPoints(5);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.savedToFavorites)),
    );
  }

  void _shareRecommendationForCrop(String cropName, double? price, Map<String, dynamic>? sustainability) async {
    if (_districtController.text.isEmpty || cropName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noRecommendationToShare)),
      );
      return;
    }

    String shareText = 'Crop recommendation for ${_districtController.text}:\n$cropName';
    if (price != null) {
      shareText += '\nMarket Price: ₹${price.toStringAsFixed(2)} per quintal';
    }
    if (sustainability != null) {
      shareText += '\nSustainability: Water Requirement - ${(sustainability['water_requirement'] ?? 'Unknown').toString()}, Soil Health Impact - ${(sustainability['soil_health_impact'] ?? 'Unknown').toString()}';
    }
    Share.share(shareText);
    await _storageService.addPoints(20);
  }

  Color _getWaterColor(String? waterRequirement) {
    if (waterRequirement == null) return Colors.grey;
    final water = waterRequirement.toLowerCase();
    if (water == 'low') {
      return Colors.blue;
    } else if (water == 'medium') {
      return Colors.orange;
    } else if (water == 'high') {
      return Colors.red;
    }
    return Colors.grey;
  }

  Color _getSoilColor(String? soilImpact) {
    if (soilImpact == null) return Colors.grey;
    final soil = soilImpact.toLowerCase();
    if (soil == 'good') {
      return Colors.green;
    } else if (soil == 'average') {
      return Colors.yellow;
    } else if (soil == 'poor') {
      return Colors.brown;
    }
    return Colors.grey;
  }

  static const Map<String, String> _cropEmoji = {
    'rice': '🌾', 'wheat': '🌾', 'barley': '🌾', 'ragi': '🌾', 'jowar': '🌾', 'bajra': '🌾', 'millet': '🌾',
    'maize': '🌽', 'corn': '🌽', 'potato': '🥔', 'peas': '🫛', 'pulses': '🫘', 'soybean': '🫘',
    'groundnut': '🥜', 'coconut': '🥥', 'sugarcane': '🎋', 'cotton': '☁️', 'tea': '🍵', 'jute': '🧵',
    'mustard': '🌼', 'tomato': '🍅', 'onion': '🧅', 'banana': '🍌', 'mango': '🥭', 'chilli': '🌶️',
  };

  String _emojiFor(String crop) => _cropEmoji[crop.toLowerCase()] ?? '🌱';

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    final searchPanel = _buildSearchPanel(context);
    final results = <Widget>[
      if (_isLoading) _buildLoadingCard(context),
      if (_weatherData != null) ...[
        _WeatherWidget(weatherData: _weatherData!),
        const SizedBox(height: 16),
      ],
      if (_recommendedCrops.isNotEmpty) ...[
        _buildRecommendationsSection(context),
        const SizedBox(height: 16),
      ],
      if (!_isLoading && _recommendedCrops.isEmpty && _weatherData == null)
        _buildEmptyState(context),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🌱 '),
            Flexible(child: Text(l10n.appTitle, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        actions: [
          AnimatedBuilder(
            animation: _leaderboardButtonAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _leaderboardButtonAnimation.value,
                child: IconButton(
                  icon: const Icon(Icons.leaderboard_rounded),
                  tooltip: 'Leaderboard',
                  onPressed: () {
                    setState(() {
                      _hasViewedLeaderboardAfterQuiz = true;
                    });
                    _leaderboardButtonAnimationController.stop();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderboardScreen()));
                  },
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _quizButtonAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _quizButtonAnimation.value,
                child: IconButton(
                  icon: const Icon(Icons.quiz_rounded),
                  tooltip: 'Daily quiz',
                  onPressed: _startDailyQuiz,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/3bdb604adcaa41f51606b474953609d4.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient keeps the header text readable and fades into the cards.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0B2E13).withValues(alpha: 0.85),
                    const Color(0xFF0B2E13).withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1200 : 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      // Two columns on wide screens (tablet landscape/desktop/web),
                      // a single scrolling column on phones.
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [searchPanel, const SizedBox(height: 16), _buildMarketPricesCard(context)],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: results),
                            ),
                          ],
                        )
                      else ...[
                        searchPanel,
                        const SizedBox(height: 16),
                        ...results,
                        _buildMarketPricesCard(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting()} 👋',
          style: textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          'Find the best crops for your land',
          style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          'AI suggestions from live weather, market prices and sustainability data.',
          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSearchPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    InputDecoration glassInput({required String label, Widget? prefix, Widget? suffix}) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: Colors.white),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFA5D6A7), width: 2),
        ),
      );
    }

    final recommendButton = FilledButton.icon(
      onPressed: _isLoading ? null : _getRecommendation,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.auto_awesome_rounded),
      label: Text(
        l10n.getRecommendation,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF43A047).withValues(alpha: 0.55),
        disabledForegroundColor: Colors.white70,
      ),
    );

    final whatIfButton = OutlinedButton.icon(
      onPressed: () {
        if (_recommendedCrops.isEmpty || _weatherData == null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WhatIfHistoryScreen()),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WhatIfScreen(
              district: _districtController.text.trim(),
              weatherData: _weatherData!,
              recommendedCrops: _recommendedCrops,
              geminiApiKey: _geminiApiKey,
              selectedLanguage: _selectedLanguage,
            ),
          ),
        );
      },
      icon: const Icon(Icons.science_outlined),
      label: const Text('"What If" Analysis', overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
      ),
    );

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Where are you farming?',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _districtController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) {
              if (!_isLoading) _getRecommendation();
            },
            decoration: glassInput(
              label: l10n.enterDistrict,
              prefix: IconButton(
                icon: const Icon(Icons.my_location_rounded, color: Colors.white),
                tooltip: 'Use current location',
                onPressed: _getCurrentLocation,
              ),
              suffix: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening ? Colors.redAccent : Colors.white,
                ),
                tooltip: 'Speak district name',
                onPressed: _listen,
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            decoration: glassInput(
              label: l10n.selectLanguage,
              prefix: const Icon(Icons.translate_rounded, color: Colors.white),
            ),
            items: _languages.map((language) {
              return DropdownMenuItem<String>(
                value: language['code'],
                child: Text(language['name']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
            dropdownColor: const Color(0xFF1B3A20),
            borderRadius: BorderRadius.circular(14),
            iconEnabledColor: Colors.white,
          ),
          const SizedBox(height: 18),
          // Buttons sit side by side when there is room, stacked otherwise.
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [recommendButton, const SizedBox(height: 10), whatIfButton],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: recommendButton),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: whatIfButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysing weather & crops for ${_districtController.text.trim()}…',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                minHeight: 6,
                color: Color(0xFFA5D6A7),
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _GlassCard(
        child: Column(
          children: [
            const Text('🌦️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(
              'Enter a district, tap the location pin, or use your voice to get started.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.recommendedCrops,
                style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            if (_districtController.text.trim().isNotEmpty)
              Chip(
                avatar: const Icon(Icons.place_rounded, size: 16, color: Colors.white),
                label: Text(_districtController.text.trim()),
                labelStyle: const TextStyle(color: Colors.white),
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        if (_recommendationNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 16, color: Colors.amberAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _recommendationNote!,
                    style: textTheme.bodySmall?.copyWith(color: Colors.amberAccent),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        for (var i = 0; i < _recommendedCrops.length; i++)
          // Re-keyed per recommendation so each new result animates in.
          TweenAnimationBuilder<double>(
            key: ValueKey('$_recommendation-$i'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 350 + i * 120),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
            ),
            child: _buildCropCard(context, _recommendedCrops[i], i),
          ),
      ],
    );
  }

  Widget _buildCropCard(BuildContext context, String cropName, int rank) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = _translatedCropNames[cropName] ?? cropName;
    final double? price = (_marketPrices?[cropName] ?? _marketPricesData[cropName])?.toDouble();
    final sustainability = _sustainabilityData?[cropName];
    final season = _cropSeasonSuggestions[cropName];
    final water = sustainability?['water_requirement']?.toString();
    final soil = sustainability?['soil_health_impact']?.toString();

    Widget infoChip(IconData icon, String text, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: textTheme.labelMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 6,
      shadowColor: Colors.black38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(_emojiFor(cropName), style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rank == 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Best match',
                            style: textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      Text(
                        displayName,
                        style: textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700),
                      ),
                      if (displayName != cropName)
                        Text(cropName, style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
                if (price != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: textTheme.titleMedium?.copyWith(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w700),
                      ),
                      Text('per quintal', style: textTheme.labelSmall?.copyWith(color: Colors.black54)),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (water != null) infoChip(Icons.water_drop_rounded, 'Water: $water', _getWaterColor(water)),
                if (soil != null) infoChip(Icons.eco_rounded, 'Soil: $soil', _getSoilColor(soil)),
                if (season != null)
                  infoChip(Icons.event_available_rounded, 'Sow: ${season['planting']}', Colors.deepPurple),
                if (season != null)
                  infoChip(Icons.agriculture_rounded, 'Harvest: ${season['harvesting']}', Colors.teal),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded),
                  color: const Color(0xFF2E7D32),
                  tooltip: 'Listen',
                  onPressed: () => _speak(displayName),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border_rounded),
                  color: Colors.pink,
                  tooltip: 'Save to favourites',
                  onPressed: () => _saveFavoriteForCrop(cropName),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  color: Colors.deepPurple,
                  tooltip: 'Crop Planner',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CropPlannerScreen(cropName: cropName)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  color: Colors.blueGrey,
                  tooltip: 'Share',
                  onPressed: () => _shareRecommendationForCrop(cropName, price, sustainability),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPricesCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entries = _marketPricesData.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final maxPrice = entries.isEmpty ? 1.0 : (entries.first.value as num).toDouble();

    Widget body;
    if (_isLoadingMarketPrices) {
      body = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_marketPricesError != null) {
      body = Text(_marketPricesError!, style: textTheme.bodyMedium?.copyWith(color: Colors.red.shade700));
    } else if (entries.isEmpty) {
      body = Text('No overall market prices available.', style: textTheme.bodyMedium);
    } else {
      body = Column(
        children: entries.map((entry) {
          final value = (entry.value as num).toDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(_emojiFor(entry.key), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '₹${value.toStringAsFixed(2)}',
                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Relative price bar makes it easy to compare crops at a glance.
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: maxPrice == 0 ? 0 : value / maxPrice,
                    minHeight: 6,
                    color: const Color(0xFF66BB6A),
                    backgroundColor: const Color(0xFFE8F5E9),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Card(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 6,
      shadowColor: Colors.black38,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Market Prices', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('₹ per quintal · highest first', style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _marketLocationController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => _fetchMarketPrices(location: value),
                    decoration: InputDecoration(
                      labelText: 'Enter Location',
                      prefixIcon: const Icon(Icons.place_outlined),
                      fillColor: const Color(0xFFF1F8E9),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _isLoadingMarketPrices
                      ? null
                      : () => _fetchMarketPrices(location: _marketLocationController.text),
                  child: const Text('Get Prices'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(_isLoadingMarketPrices), child: body)),
          ],
        ),
      ),
    );
  }
}

// Frosted-glass container used for panels that sit directly on the photo.
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _WeatherWidget extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const _WeatherWidget({required this.weatherData});

  @override
  Widget build(BuildContext context) {
    if (weatherData.isEmpty || weatherData['weather'] == null || weatherData['weather'].isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final main = (weatherData['main'] as Map?) ?? const {};
    final String iconCode = (weatherData['weather'][0]['icon'] ?? '').toString();
    final String iconUrl = 'https://openweathermap.org/img/wn/$iconCode@2x.png';
    final num? rawTemp = main['temp'];
    final String temp = rawTemp?.toStringAsFixed(1) ?? '--';
    final String description = (weatherData['weather'][0]['description'] ?? '').toString();
    final String place = (weatherData['name'] ?? '').toString();
    final num? feelsLike = main['feels_like'];
    final num? humidity = main['humidity'];
    final num? windMs = weatherData['wind']?['speed'];
    final num rain = weatherData['rain']?['1h'] ?? 0;

    final stats = <(IconData, String, String)>[
      (Icons.thermostat_rounded, 'Feels like', feelsLike != null ? '${feelsLike.toStringAsFixed(1)}°C' : '--'),
      (Icons.water_drop_rounded, 'Humidity', humidity != null ? '$humidity%' : '--'),
      (Icons.air_rounded, 'Wind', windMs != null ? '${(windMs * 3.6).toStringAsFixed(1)} km/h' : '--'),
      (Icons.umbrella_rounded, 'Rain (1h)', '${rain.toStringAsFixed(1)} mm'),
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (place.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.place_rounded, color: Colors.white70, size: 18),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              place,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    // FittedBox keeps the large temperature from overflowing narrow screens.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$temp°C',
                        style: textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      description.isEmpty ? '' : description[0].toUpperCase() + description.substring(1),
                      style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Image.network(
                iconUrl,
                width: 90,
                height: 90,
                // Offline/cached weather: show a plain icon instead of a broken image.
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.cloud_rounded, size: 64, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // 4 tiles per row when wide enough, otherwise 2.
              final perRow = constraints.maxWidth >= 520 ? 4 : 2;
              final tileWidth = (constraints.maxWidth - 10 * (perRow - 1)) / perRow;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (icon, label, value) in stats)
                    Container(
                      width: tileWidth,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: textTheme.labelSmall?.copyWith(color: Colors.white70)),
                                Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
