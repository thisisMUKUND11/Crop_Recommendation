import 'profile_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'storage_service.dart';
import 'generated/app_localizations.dart';

import 'language_selection_screen.dart';
import 'terms_screen.dart';
import 'register_screen.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  String _email = '';
  

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  

  Future<void> _loadCredentials() async {
    final currentUserId = await _storageService.getCurrentUserId();
    if (currentUserId != null) {
      final userCredentials = await _storageService.getUserCredentialsByUserId(currentUserId);
      if (userCredentials != null) {
        setState(() {
          _email = userCredentials['email'] ?? '';
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _storageService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _switchAccount() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileSelectionScreen()),
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                final currentUserId = await _storageService.getCurrentUserId();
                if (currentUserId != null) {
                  await _storageService.deleteUser(currentUserId);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isFirstTime', true);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings, style: TextStyle(fontSize: screenWidth * 0.05)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/160fea8fb41001beab1df8bdb02c148d.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            child: ListView(
              children: [
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.email, color: Colors.white),
                    title: Text(
                      AppLocalizations.of(context)!.email,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                    ),
                    subtitle: Text(
                      _email,
                      style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.035),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.language, color: Colors.white),
                    title: Text(
                      AppLocalizations.of(context)!.language,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LanguageSelectionScreen()),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.description, color: Colors.white),
                    title: Text(
                      AppLocalizations.of(context)!.termsAndConditions,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TermsScreen()),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.lock_reset, color: Colors.white),
                    title: Text(
                      'Forgot Password',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onTap: () {
                      Navigator.pushNamed(context, '/forgot_password');
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                    ),
                    secondary: const Icon(Icons.dark_mode, color: Colors.white),
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (bool value) {
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                    },
                    activeColor: Colors.green,
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.01),
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.switch_account, color: Colors.white),
                    title: Text(
                      'Switch Account',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                    ),
                    onTap: _switchAccount,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                    ),
                    onTap: _deleteAccount,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      AppLocalizations.of(context)!.signOut,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                    ),
                    onTap: _signOut,
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