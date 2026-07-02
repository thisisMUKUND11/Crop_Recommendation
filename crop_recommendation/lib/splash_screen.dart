import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'profile_selection_screen.dart'; // Import ProfileSelectionScreen
import 'language_selection_screen.dart'; // Import LanguageSelectionScreen
import 'storage_service.dart'; // Import StorageService
import 'profile.dart'; // Import UserProfile

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkProfiles();
  }

  Future<void> _checkProfiles() async {
    // Wait for 5 seconds for the splash screen to be visible
    await Future.delayed(Duration(seconds: 5));
    if (!mounted) return; // Check if the widget is still mounted

    final List<UserProfile> profiles = await _storageService.getProfiles();

    if (profiles.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileSelectionScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LanguageSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/Black And White King Logo.png',
          height: 150,
        ),
      ),
    );
  }
}
