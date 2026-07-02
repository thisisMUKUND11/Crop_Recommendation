import 'email_profiles_screen.dart';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'register_screen.dart';
import 'terms_screen.dart';
import 'generated/app_localizations.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final StorageService _storageService = StorageService();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final user = await _storageService.getUserCredentialsByEmail(_emailController.text);

      if (user != null && user['password'] == _passwordController.text) {
        final userId = user['userId']!;
        await _storageService.setCurrentUserId(userId);
        await _storageService.setLoggedIn(true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailProfilesScreen(email: _emailController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.invalidEmailOrPassword)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/2c9ff41ef73ee64a237db67ab4c44c75.jpg'),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.login,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.08, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.06),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.email,
                        labelStyle: TextStyle(fontFamily: 'Times New Roman', color: Colors.white70, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                        labelStyle: TextStyle(fontFamily: 'Times New Roman', color: Colors.white70, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.02),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.login,
                        style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.045),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot_password');
                      },
                      child: Text(
                        AppLocalizations.of(context)!.forgotPassword,
                        style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.dontHaveAnAccount,
                        style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
