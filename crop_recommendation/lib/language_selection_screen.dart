import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_provider.dart';
import 'generated/app_localizations.dart';
import 'storage_service.dart';
import 'login_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final StorageService _storageService = StorageService();
  bool _hasProfiles = false;

  @override
  void initState() {
    super.initState();
    _checkIfProfilesExist();
  }

  Future<void> _checkIfProfilesExist() async {
    final profiles = await _storageService.getProfiles();
    if (mounted) {
      setState(() {
        _hasProfiles = profiles.isNotEmpty;
      });
    }
  }

  Future<void> _setLocale(BuildContext context, Locale locale) async {
    Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);

    // Persist language choice
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);

    if (!_hasProfiles) {
      // New user, navigate to registration
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } else {
      // Existing user, just pop the screen (coming from settings)
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _hasProfiles ? IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/1d8511b11ec30fb28ae1b248401b9b12.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'HARVEST-IQ',
                    style: TextStyle(
                      fontSize: screenWidth * 0.12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06),
                  Text(
                    AppLocalizations.of(context)!.selectLanguage,
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Wrap(
                    spacing: screenWidth * 0.05,
                    runSpacing: screenHeight * 0.02,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _setLocale(context, Locale('en')),
                        child: Text(
                          AppLocalizations.of(context)!.english,
                          style: TextStyle(fontSize: screenWidth * 0.045),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: screenHeight * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _setLocale(context, Locale('ta')),
                        child: Text(
                          AppLocalizations.of(context)!.tamil,
                          style: TextStyle(fontSize: screenWidth * 0.045),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: screenHeight * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
