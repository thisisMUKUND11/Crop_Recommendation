import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'locale_provider.dart';
import 'generated/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';

class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  PaletteGenerator? _paletteGenerator;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/77a959d0af926db99f636778907a7e89.jpg'),
      size: Size(200, 200),
    );
    setState(() {});
  }

  Future<void> _setLocale(BuildContext context, Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Wrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color overlayColor = _paletteGenerator?.darkMutedColor?.color?.withOpacity(0.6) ?? Colors.black.withOpacity(0.6);
    final Color titleColor = _paletteGenerator?.dominantColor?.color ?? Colors.white;
    final Color textColor = _paletteGenerator?.lightVibrantColor?.color ?? Colors.white;
    final Color buttonColor = _paletteGenerator?.vibrantColor?.color ?? Colors.green.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/77a959d0af926db99f636778907a7e89.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: overlayColor,
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'HARVEST-IQ',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      fontFamily: 'serif',
                    ),
                  ),
                  SizedBox(height: 48),
                  Text(
                    AppLocalizations.of(context)!.selectLanguage,
                    style: TextStyle(
                      fontSize: 24,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _setLocale(context, Locale('en')),
                    child: Text(AppLocalizations.of(context)!.english),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _setLocale(context, Locale('ta')),
                    child: Text(AppLocalizations.of(context)!.tamil),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
