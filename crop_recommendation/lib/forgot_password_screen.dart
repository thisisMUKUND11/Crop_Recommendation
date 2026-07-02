import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'generated/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
      });

      final email = _emailController.text.trim();
      final userExists = await _storageService.checkUserExists(email);

      if (userExists) {
        // In a real app, you would send a password reset email here.
        // For this example, we'll just show a success message.
        setState(() {
          _message = 'A password reset link has been sent to your email.';
        });
      } else {
        setState(() {
          _message = 'No user found with that email address.';
        });
      }

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
        title: Text(AppLocalizations.of(context)!.forgotPassword),
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
                image: AssetImage('assets/images/0ecf5266f293425e38e96ce149f94145.jpg'),
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
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      labelStyle: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                    style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
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
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _sendPasswordResetEmail,
                          child: Text('Send Password Reset Email', style: TextStyle(fontSize: screenWidth * 0.04)),
                        ),
                  if (_message != null) ...[
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      _message!,
                      style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                    ),
                  ],
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
