

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
import 'gamification_screen.dart';
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
      final currentUserProfile = profiles.firstWhere((p) => p.id == currentUserId);

      final today = DateTime.now().toIso8601String().substring(0, 10);

      setState(() {
        _isQuizCompletedToday = (currentUserProfile.lastQuizDate == today);
        _hasViewedLeaderboardAfterQuiz = currentUserProfile.hasViewedLeaderboardAfterQuiz ?? false;
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
    final currentUserProfile = profiles.firstWhere((p) => p.id == currentUserId);

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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMarketPrices({String? location}) async {
    setState(() {
      _isLoadingMarketPrices = true;
      _marketPricesError = null;
    });
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        // No internet, try to load from cache
        final cachedData = await _storageService.readData('market_prices_${location ?? 'default'}');
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
      setState(() {
        _marketPricesData = data;
        _isLoadingMarketPrices = false;
      });
      // Save to cache
      await _storageService.saveData('market_prices_${location ?? 'default'}', data.cast<String, dynamic>());
    } catch (e) {
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
      setState(() {
        _localRecommendations = json.decode(data);
      });
    } catch (e) {
      // If asset not present, keep null and allow offline handler to error gracefully.
      debugPrint('Could not load local recommendations: $e');
    }
  }

  Future<void> _getWeather(String district) async {
    if (district.isEmpty) return;
    _weatherError = null;
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
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.speak(text);
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

    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    final district = place.subAdministrativeArea ?? place.locality ?? place.administrativeArea ?? '';
    setState(() {
      // Use subAdministrativeArea if available, else locality or administrativeArea
      _districtController.text = district;
    });
    await _getWeather(district);
  }

  Future<void> _getRecommendation() async {
    if (_districtController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterDistrictName)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _recommendation = '';
      _marketPrices = null;
      _sustainabilityData = null;
    });

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      await _getOfflineRecommendation();
    } else {
      await _getOnlineRecommendation();
    }
  }

  Future<void> _scheduleSmartReminder(String cropName, String district) async {
    final now = DateTime.now();
    final scheduledDate = now.add(Duration(days: 7)); // Example: 7 days from now
    await _notificationService.showNotification(
      0, // Notification ID
      'Smart Reminder',
      '🌾 Best time to sow $cropName is this week in $district.',
      scheduledDate,
    );
  }

  Future<void> _checkAndSendRiskAlert(Map<String, dynamic> weatherData, String district) async {
    final temp = weatherData['main']?['temp'] ?? 0;
    final humidity = weatherData['main']?['humidity'] ?? 0;
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
      await _notificationService.showNotification(
        1, // Notification ID
        'Risk Alert',
        alertMessage,
        DateTime.now().add(Duration(seconds: 5)), // Show immediately
      );
    }
  }

  Future<void> _getOnlineRecommendation() async {
    try {
      // 1. Get Weather Data
      await _getWeather(_districtController.text);
      final weatherData = _weatherData; // Use the state variable

      if (weatherData == null) {
        throw Exception(
            _weatherError ?? AppLocalizations.of(context)!.couldNotFetchWeatherData);
      }

      // Check and send risk alert based on current weather
      await _checkAndSendRiskAlert(weatherData, _districtController.text);

      final temp = weatherData['main']?['temp'] ?? 0;
      final humidity = weatherData['main']?['humidity'] ?? 0;
      final rainfall = weatherData['rain'] != null ? (weatherData['rain']['1h'] ?? 0) : 0;

      // 2. Get Crop Recommendation from Gemini
      final geminiUrl = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey');
      final prompt =
          'Given the weather conditions:\n- Temperature: $temp°C\n- Humidity: $humidity%\n- Rainfall: $rainfall mm\n\nRecommend 3 suitable crops for cultivation in Indian conditions.\nOutput format: Just the crop names separated by commas, no explanation.';

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
        if (geminiResponse.statusCode == 400) {
          debugPrint('Gemini API Error: Invalid API Key');
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

      if (englishOutput.isEmpty) {
        throw Exception(AppLocalizations.of(context)!.couldNotFetchCropRecommendations);
      }

      // 3. Get Market Prices and Sustainability Data
      final crops = englishOutput.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final prices = await _marketPriceService.getPrices(crops);
      final sustainabilityData = <String, Map<String, dynamic>>{};
      for (var crop in crops) {
        final sData = await _sustainabilityService.getSustainabilityIndex(crop);
        sustainabilityData[crop] = sData ?? <String, dynamic>{};
      }
      setState(() {
        _marketPrices = prices.cast<String, double>();
        _sustainabilityData = sustainabilityData;
      });

      // 4. Translate if necessary (online)
      var translatedOutput = englishOutput;
      if (_selectedLanguage != 'en') {
        final translationUrl = Uri.parse(
            'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(englishOutput)}&langpair=en|$_selectedLanguage');
        final translationResponse = await http.get(translationUrl);
        final translationData = json.decode(translationResponse.body);
        translatedOutput = translationData['responseData']?['translatedText']?.toString() ?? englishOutput;
      }

      final searchHistoryItem = SearchHistoryItem(
        district: _districtController.text,
        recommendation: translatedOutput,
        dateTime: DateTime.now(),
      );
      await _storageService.saveSearchHistory(searchHistoryItem);
      await _storageService.addPoints(10);

      setState(() {
        _recommendation = translatedOutput;
      });

      await _speak(translatedOutput);

      // Schedule smart reminder for the first recommended crop
      if (crops.isNotEmpty) {
        await _scheduleSmartReminder(crops.first, _districtController.text);
      }

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.anErrorOccurred(error.toString()))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getOfflineRecommendation() async {
    try {
      if (_localRecommendations == null) {
        throw Exception("Local recommendations not loaded.");
      }

      final district = _districtController.text.toLowerCase();
      String? region;
      for (var reg in (_localRecommendations!['regions'] as List)) {
        final r = reg as Map<String, dynamic>;
        final districtList = (r['districts'] as List).map((d) => d.toString().toLowerCase()).toList();
        if (districtList.contains(district)) {
          region = r['name'];
          break;
        }
      }

      if (region == null) {
        throw Exception("District not found in local data.");
      }

      var recommendations = (_localRecommendations!['regions'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((reg) => reg['name'] == region)['recommendations'] as List<dynamic>;

      final recStrings = recommendations.map((e) => e.toString()).toList();

      final prices = await _marketPriceService.getPrices(recStrings);
      final sustainabilityData = <String, Map<String, dynamic>>{};
      for (var crop in recStrings) {
        final sData = await _sustainabilityService.getSustainabilityIndex(crop);
        sustainabilityData[crop] = sData ?? <String, dynamic>{};
      }
      setState(() {
        _marketPrices = prices.cast<String, double>();
        _sustainabilityData = sustainabilityData;
      });

      final weatherData = await _storageService.getWeatherData(district);
      setState(() {
        _weatherData = weatherData;
      });
      String weatherInfo = "";
      if (weatherData != null) {
        final temp = weatherData['main']?['temp'];
        final humidity = weatherData['main']?['humidity'];
        weatherInfo = " (Cached Weather: ${temp}°C, ${humidity}% humidity)";

        // Check and send risk alert based on cached weather
        await _checkAndSendRiskAlert(weatherData, _districtController.text);
      } else {
        weatherInfo = " (Connect to internet for more accurate recommendations)";
      }

      var translatedOutput = recStrings.join(', ');

      setState(() {
        _recommendation = "Offline: " + translatedOutput + weatherInfo;
      });
      await _speak(translatedOutput);

      // Schedule smart reminder for the first recommended crop
      if (recStrings.isNotEmpty) {
        await _scheduleSmartReminder(recStrings.first, _districtController.text);
      }

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.anErrorOccurred(error.toString()))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Removed undefined _paletteGenerator reference and used safe defaults:
    final Color appBarColor = Colors.green.shade800;
    final Color accentColor = Colors.green.shade600;
    final Color textColor = Colors.white;
    final Color containerColor = Colors.white.withOpacity(0.12);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          AnimatedBuilder(
            animation: _leaderboardButtonAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _leaderboardButtonAnimation.value,
                child: IconButton(
                  icon: const Icon(Icons.leaderboard),
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
                  icon: const Icon(Icons.quiz),
                  onPressed: _startDailyQuiz,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings), // Changed icon to settings
            tooltip: 'Settings', // Changed tooltip to Settings
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
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _districtController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.enterDistrict,
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor, width: 2),
                      ),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.location_pin),
                        onPressed: _getCurrentLocation,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : textColor,
                        ),
                        onPressed: _listen,
                      ),
                      fillColor: Colors.white.withOpacity(0.05),
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.selectLanguage,
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor),
                      ),
                      fillColor: Colors.white.withOpacity(0.05),
                      filled: true,
                    ),
                    items: _languages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language['code'],
                        child: Text(language['name']!, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                    dropdownColor: Colors.black,
                    iconEnabledColor: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getRecommendation,
                        child: _isLoading
                            ? SizedBox(
                                height: screenWidth * 0.05,
                                width: screenWidth * 0.05,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.getRecommendation,
                                style: TextStyle(fontSize: screenWidth * 0.05),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor.withOpacity(0.9),
                          foregroundColor: textColor,
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02), // Made proportional
                    
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                  ElevatedButton(
                    onPressed: () {
                      if (_recommendation.isEmpty || _weatherData == null) {
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
                            district: _districtController.text,
                            weatherData: _weatherData!,
                            recommendedCrops: _recommendation.replaceFirst(RegExp(r'^Offline:\s*'), '').split(',').map((e) => e.trim()).toList(),
                            geminiApiKey: _geminiApiKey,
                            selectedLanguage: _selectedLanguage,
                          ),
                        ),
                      );
                    },
                    child: Text('"What If" Analysis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor.withOpacity(0.9),
                      foregroundColor: textColor,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.04),
                if (_weatherData != null)
                  _WeatherWidget(weatherData: _weatherData!),
                if (_recommendation.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: containerColor.withOpacity(0.8), // Background for visibility
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.recommendedCrops,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black), // Changed to black
                        ),
                        SizedBox(height: screenHeight * 0.02), // Made proportional
                        ..._recommendation
                            .replaceFirst(RegExp(r'^Offline:\s*'), '')
                            .split(',')
                            .map((cropName) => cropName.trim())
                            .where((cropName) => cropName.isNotEmpty)
                            .expand((cropName) { // Changed to expand directly on cropName
                          final price = _marketPricesData[cropName];
                          final sustainability = _sustainabilityData?[cropName];

                          return [
                            Card(
                              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                              color: containerColor.withOpacity(0.8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column( // Changed to Column to allow multiple children directly
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(screenWidth * 0.04),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cropName,
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black), // Changed to black
                                        ),
                                        SizedBox(height: screenHeight * 0.01),
                                        if (sustainability != null)
                                          Padding(
                                            padding: EdgeInsets.only(top: screenHeight * 0.01),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Sustainability:',
                                                  style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: screenWidth * 0.035), // Changed to black
                                                ),
                                                SizedBox(height: screenHeight * 0.005),
                                                Row(
                                                  children: [
                                                    Icon(Icons.water_drop, color: _getWaterColor(sustainability['water_requirement'])),
                                                    SizedBox(width: screenWidth * 0.02),
                                                    Text(
                                                      (sustainability['water_requirement'] ?? 'Unknown').toString(),
                                                      style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.035), // Changed to black
                                                    ),
                                                    SizedBox(width: 40),
                                                    Icon(Icons.eco, color: _getSoilColor(sustainability['soil_health_impact'])),
                                                    SizedBox(width: screenWidth * 0.02),
                                                    Text(
                                                      (sustainability['soil_health_impact'] ?? 'Unknown').toString(),
                                                      style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.035), // Changed to black
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (price != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.3), // New background for market price
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.currency_rupee, color: Colors.black),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${price.toStringAsFixed(2)} per quintal',
                                            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold), // Changed to black
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.volume_up, color: Colors.black),
                                  onPressed: () => _speak(cropName),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite_border, color: Colors.black),
                                  onPressed: () => _saveFavoriteForCrop(cropName),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.black),
                                  onPressed: () => _shareRecommendationForCrop(
                                    cropName,
                                    _marketPricesData[cropName],
                                    _sustainabilityData?[cropName],
                                  ),
                                ),
                              ],
                            ),
                          ];
                        }).toList(),
                      ],
                    ),
                  ),
                SizedBox(height: screenHeight * 0.04),
                // New Market Price Section
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: containerColor.withOpacity(0.8), // Background for visibility
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Prices',
                        style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextField(
                        controller: _marketLocationController,
                        style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
                        decoration: InputDecoration(
                          labelText: 'Enter Location',
                          labelStyle: TextStyle(color: Colors.black54, fontSize: screenWidth * 0.04),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black, width: 2),
                          ),
                          fillColor: Colors.white.withOpacity(0.2),
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _fetchMarketPrices(location: _marketLocationController.text),
                        child: Text('Get Prices', style: TextStyle(fontSize: screenWidth * 0.04)),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _isLoadingMarketPrices
                          ? Center(child: CircularProgressIndicator())
                          : _marketPricesError != null
                              ? Text(
                                  _marketPricesError!,
                                  style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.04),
                                )
                              : _marketPricesData.isEmpty
                                  ? Text(
                                      'No overall market prices available.',
                                      style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _marketPricesData.entries.map((entry) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Row(
                                            children: [
                                              Text(
                                                '${entry.key}: ',
                                                style: TextStyle(color: Colors.black, fontSize: (screenWidth * 0.04).toDouble()),
                                              ),
                                              Icon(Icons.currency_rupee, color: Colors.black),
                                              Text(
                                                '${entry.value.toStringAsFixed(2)} per quintal',
                                                style: TextStyle(color: Colors.black, fontSize: (screenWidth * 0.04).toDouble()),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
    
    final String iconCode = weatherData['weather'][0]['icon'];
    final String iconUrl = 'https://openweathermap.org/img/wn/$iconCode@2x.png';
    final String temp = weatherData['main']['temp'].toStringAsFixed(1);
    final String description = weatherData['weather'][0]['description'];
    final String place = weatherData['name'];

    return Card(
      color: Colors.white.withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(place, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(iconUrl),
                Text('$temp°C', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
            Text(description, style: TextStyle(fontSize: 18, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
