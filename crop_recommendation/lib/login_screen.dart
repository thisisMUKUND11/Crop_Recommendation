
import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'register_screen.dart';
import 'main.dart';
import 'terms_screen.dart';
import 'generated/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final StorageService _storageService = StorageService();
  PaletteGenerator? _paletteGenerator;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/1d8511b11ec30fb28ae1b248401b9b12.jpg'),
      size: Size(200, 200),
    );
    setState(() {});
  }

  Future<void> _login() async {
    final credentials = await _storageService.getUserCredentials();
    final email = credentials['email'];
    final password = credentials['password'];

    if (email == _emailController.text && password == _passwordController.text) {
      await _storageService.setLoggedIn(true);
      final acceptedTerms = await _storageService.hasAcceptedTerms();
      if (acceptedTerms) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TermsScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidEmailOrPassword)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color overlayColor = _paletteGenerator?.darkMutedColor?.color?.withOpacity(0.6) ?? Colors.black.withOpacity(0.6);
    final Color textColor = _paletteGenerator?.lightVibrantColor?.color ?? Colors.white70;
    final Color buttonColor = _paletteGenerator?.vibrantColor?.color ?? Colors.green.shade800;
    final Color textButtonColor = _paletteGenerator?.lightMutedColor?.color ?? Colors.lightGreen.shade200;
    final Color titleColor = _paletteGenerator?.dominantColor?.color ?? Colors.white;

    return Scaffold(
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
            color: overlayColor,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
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
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: titleColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    style: TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.password,
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: titleColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text(AppLocalizations.of(context)!.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.dontHaveAnAccount,
                      style: TextStyle(color: textButtonColor),
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
