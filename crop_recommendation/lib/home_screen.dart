import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'storage_service.dart';
import 'search_history_item.dart';
import 'favorite_item.dart';
import 'generated/app_localizations.dart';
import 'settings_screen.dart';
import 'package:palette_generator/palette_generator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _districtController = TextEditingController();
  String _selectedLanguage = 'en';
  String _recommendation = '';
  bool _isLoading = false;
  final StorageService _storageService = StorageService();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  PaletteGenerator? _paletteGenerator;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/254ff1db7128864fe8f4da0993bd23c2.jpg'),
      size: Size(200, 200),
    );
    setState(() {});
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

  final String _weatherApiKey = '8eb898d0791bcfbcdc92ef8aac59c52d';
  final String _geminiApiKey = 'AIzaSyCvGuEhPTOrNT7vrx5uvNGWGH0AJgaTjg0';

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == "done") {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          print('onError: $val');
          setState(() => _isListening = false);
        },
      );

      if (available) {
        if (await _speech.hasPermission) {
          setState(() => _isListening = true);
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
      setState(() => _isListening = false);
      _speech.stop();
    }
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
    });

    try {
      // 1. Get Weather Data
      final weatherUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=${_districtController.text},IN&appid=$_weatherApiKey&units=metric');
      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode != 200) {
        throw Exception(AppLocalizations.of(context)!.couldNotFetchWeatherData);
      }

      final weatherData = json.decode(weatherResponse.body);
      final temp = weatherData['main']['temp'];
      final humidity = weatherData['main']['humidity'];
      final rainfall = weatherData['rain'] != null ? weatherData['rain']['1h'] ?? 0 : 0;

      // 2. Get Crop Recommendation from Gemini
      final geminiUrl = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey');
      final prompt =
          'Given the weather conditions:\n- Temperature: $temp°C\n- Humidity: $humidity%\n- Rainfall: $rainfall mm\n\nRecommend 3 suitable crops for cultivation in Indian conditions.\nOutput format: Just the crop names separated by commas, no explanation.';

      final geminiResponse = await http.post(
        geminiUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ]
        }),
      );

      if (geminiResponse.statusCode != 200) {
        throw Exception(AppLocalizations.of(context)!.couldNotFetchCropRecommendations);
      }

      final geminiData = json.decode(geminiResponse.body);
      final englishOutput = geminiData['candidates'][0]['content']['parts'][0]['text'].trim();

      // 3. Translate if necessary
      var translatedOutput = englishOutput;
      if (_selectedLanguage != 'en') {
        final translationUrl = Uri.parse(
            'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(englishOutput)}&langpair=en|$_selectedLanguage');
        final translationResponse = await http.get(translationUrl);
        final translationData = json.decode(translationResponse.body);
        translatedOutput = translationData['responseData']['translatedText'];
      }

      final searchHistoryItem = SearchHistoryItem(
        district: _districtController.text,
        recommendation: translatedOutput,
        dateTime: DateTime.now(),
      );
      await _storageService.saveSearchHistory(searchHistoryItem);

      setState(() {
        _recommendation = translatedOutput;
      });
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
      district: _districtController.text,
      recommendation: _recommendation,
      dateTime: DateTime.now(),
    );
    await _storageService.saveFavorite(favoriteItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.savedToFavorites)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = _paletteGenerator?.dominantColor?.color ?? Colors.green.shade800;
    final Color accentColor = _paletteGenerator?.vibrantColor?.color ?? Colors.green.shade600;
    final Color textColor = _paletteGenerator?.lightVibrantColor?.color ?? Colors.white;
    final Color containerColor = _paletteGenerator?.darkMutedColor?.color?.withOpacity(0.5) ?? Colors.white.withOpacity(0.2);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
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
              'assets/images/254ff1db7128864fe8f4da0993bd23c2.jpg',
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
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : textColor,
                        ),
                        onPressed: _listen,
                      ),
                      fillColor: Colors.white.withOpacity(0.1),
                      filled: true,
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.selectLanguage,
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor),
                      ),
                      fillColor: Colors.white.withOpacity(0.1),
                      filled: true,
                    ),
                    items: _languages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language['code'],
                        child: Text(language['name']!, style: TextStyle(color: Colors.black)), // Ensure text is visible
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                ),
                SizedBox(height: 32.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getRecommendation,
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        )
                      : Text(
                          AppLocalizations.of(context)!.getRecommendation,
                          style: TextStyle(fontSize: 18),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor.withOpacity(0.7),
                    foregroundColor: textColor,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 32.0),
                if (_recommendation.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.recommendedCrops,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor),
                            ),
                            IconButton(
                              icon: Icon(Icons.favorite_border, color: textColor),
                              onPressed: _saveFavorite,
                            ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          _recommendation,
                          style: TextStyle(color: textColor, fontSize: 16),
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
