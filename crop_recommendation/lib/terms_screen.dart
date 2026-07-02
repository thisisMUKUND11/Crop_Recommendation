import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'login_screen.dart';
import 'generated/app_localizations.dart';
import 'main.dart';
import 'welcome_screen.dart';

class TermsScreen extends StatefulWidget {
  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final StorageService _storageService = StorageService();
  bool _isAccepted = false;

  

  Future<void> _acceptTerms(BuildContext context) async {
    await _storageService.setAcceptedTerms(true);
    final profile = await _storageService.getCurrentUserProfile();
    if (profile != null) {
      profile.isFirstTime = false;
      await _storageService.saveProfile(profile);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen(profileName: profile.name)),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          /// Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/254ff1db7128864fe8f4da0993bd23c2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Dark overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          /// Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Heading
                  Text(
                    AppLocalizations.of(context)!.termsAndConditions,
                    style: TextStyle(
                      fontFamily: 'serif', // or custom TimesNewRoman
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  /// Terms text
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        AppLocalizations.of(context)!.termsAndConditionsContent,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: screenWidth * 0.04,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  /// Accept / Decline buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07, vertical: screenHeight * 0.02),
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Decline",  // hardcoded fix
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isAccepted ? () => _acceptTerms(context) : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07, vertical: screenHeight * 0.02),
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.accept,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _isAccepted,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _isAccepted = newValue!;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      Text(
                        'I accept the terms and conditions',
                        style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
