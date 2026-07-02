import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' as services; // Import with alias
import 'storage_service.dart' as storage; // Import StorageService with alias
import 'what_if_history_item.dart'; // Import WhatIfHistoryItem
import 'what_if_history_screen.dart'; // Import WhatIfHistoryScreen

class WhatIfScreen extends StatefulWidget {
  final String district;
  final Map<String, dynamic> weatherData;
  final List<String> recommendedCrops;
  final String geminiApiKey;
  final String selectedLanguage;

  WhatIfScreen({
    required this.district,
    required this.weatherData,
    required this.recommendedCrops,
    required this.geminiApiKey,
    required this.selectedLanguage,
  });

  @override
  _WhatIfScreenState createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  final TextEditingController _questionController = TextEditingController();
  String _answer = '';
  bool _isLoading = false;
  late String _replyLanguage;
  final storage.StorageService _storageService = storage.StorageService(); // Instantiate StorageService

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

  @override
  void initState() {
    super.initState();
    _replyLanguage = widget.selectedLanguage;
  }

  Future<void> _getWhatIfAnalysis() async {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a "what if" question.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _answer = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: widget.geminiApiKey);

      final prompt = '''As an agricultural expert for the ${widget.district} district, consider the following:
- Current weather: Temperature ${widget.weatherData['main']['temp']}°C, Humidity ${widget.weatherData['main']['humidity']}%, Rainfall ${widget.weatherData['rain'] != null ? widget.weatherData['rain']['1h'] ?? 0 : 0} mm.
- Currently recommended crops: ${widget.recommendedCrops.join(', ')}.

Now, answer the farmer's question: "${_questionController.text}" in $_replyLanguage.

Provide a concise and practical analysis of how this scenario might impact the recommended crops and suggest any alternative crops if necessary. The reply must be limited to three lines only, not more.''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _answer = response.text ?? 'No answer from the model.';
      });

      // Save to What If History
      final whatIfItem = WhatIfHistoryItem(
        district: widget.district,
        weatherData: widget.weatherData,
        recommendedCrops: widget.recommendedCrops,
        question: _questionController.text,
        answer: _answer,
        dateTime: DateTime.now(),
      );
      await _storageService.saveWhatIfHistory(whatIfItem);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('"What If" Analysis', style: TextStyle(fontSize: screenWidth * 0.05)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WhatIfHistoryScreen()),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/33a5dd847966ceae3071cddfbb1d9382.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.15, screenWidth * 0.04, screenHeight * 0.01),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: TextField(
                      controller: _questionController,
                      style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                      textAlignVertical: TextAlignVertical.top, // Align text to the top
                      expands: false, // Ensure it doesn't expand infinitely
                      decoration: InputDecoration(
                        labelText: 'Ask a "what if" question',
                        labelStyle: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.04),
                        hintText: 'e.g., What if rainfall is low next week?',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        alignLabelWithHint: true, // Align label with hint text
                      ),
                      maxLines: 3,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: DropdownButtonFormField<String>(
                      value: _replyLanguage,
                      style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                      decoration: InputDecoration(
                        labelText: 'Reply Language',
                        labelStyle: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white),
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
                          _replyLanguage = value!;
                        });
                      },
                      dropdownColor: Colors.black,
                      iconEnabledColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getWhatIfAnalysis,
                  child: _isLoading
                      ? SizedBox(
                          height: screenWidth * 0.05,
                          width: screenWidth * 0.05,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Get Analysis', style: TextStyle(fontSize: screenWidth * 0.05)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                if (_answer.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        color: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Text(
                            _answer,
                            style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {
                        services.Clipboard.setData(services.ClipboardData(text: _answer));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Answer copied to clipboard')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        Share.share(_answer);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
