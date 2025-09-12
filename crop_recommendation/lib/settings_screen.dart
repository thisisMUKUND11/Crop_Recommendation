import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'storage_service.dart';
import 'generated/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';
import 'language_selection_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  String _email = '';
  PaletteGenerator? _paletteGenerator;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/51824997f5a470eaefa953ca2ef8b5fa.jpg'),
      size: Size(200, 200),
    );
    setState(() {});
  }

  Future<void> _loadCredentials() async {
    final credentials = await _storageService.getUserCredentials();
    setState(() {
      _email = credentials['email'] ?? '';
    });
  }

  Future<void> _signOut() async {
    await _storageService.setLoggedIn(false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = _paletteGenerator?.dominantColor?.color ?? Colors.green.shade800;
    final Color iconColor = _paletteGenerator?.vibrantColor?.color ?? Colors.white;
    final Color titleColor = _paletteGenerator?.lightVibrantColor?.color ?? Colors.white;
    final Color subtitleColor = _paletteGenerator?.lightMutedColor?.color ?? Colors.white70;
    final Color dividerColor = _paletteGenerator?.darkMutedColor?.color?.withOpacity(0.5) ?? Colors.white54;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/51824997f5a470eaefa953ca2ef8b5fa.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.email, color: iconColor),
              title: Text(
                AppLocalizations.of(context)!.email,
                style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _email,
                style: TextStyle(color: subtitleColor),
              ),
            ),
            Divider(color: dividerColor),
            ListTile(
              leading: Icon(Icons.language, color: iconColor),
              title: Text(
                AppLocalizations.of(context)!.language,
                style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LanguageSelectionScreen()),
                );
              },
            ),
            Divider(color: dividerColor),
            ListTile(
              leading: Icon(Icons.description, color: iconColor),
              title: Text(
                AppLocalizations.of(context)!.termsAndConditions,
                style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TermsScreen()),
                );
              },
            ),
            Divider(color: dividerColor),
            ListTile(
              leading: Icon(Icons.logout, color: iconColor),
              title: Text(
                AppLocalizations.of(context)!.signOut,
                style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
              ),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
