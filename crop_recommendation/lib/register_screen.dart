import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'storage_service.dart';
import 'terms_screen.dart';
import 'generated/app_localizations.dart';
import 'profile.dart';
import 'welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _profileImagePath;
  final StorageService _storageService = StorageService();
  final Uuid _uuid = Uuid();

  Future<void> _createProfile() async {
    if (_formKey.currentState!.validate()) {
      final profiles = await _storageService.getProfiles();
      final email = _emailController.text;
      final profilesWithSameEmail = profiles.where((p) => p.email == email).toList();

      if (profilesWithSameEmail.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only create 2 profiles per email address.'),
          ),
        );
        return;
      }

      final userId = _uuid.v4();

      final newProfile = UserProfile(
        id: userId,
        name: _usernameController.text,
        imagePath: _profileImagePath,
        pin: _pinController.text,
        email: email,
        password: _passwordController.text, // TODO: Hash this password
      );
      await _storageService.saveProfile(newProfile);
      await _storageService.setCurrentUserId(userId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen(profileName: newProfile.name)),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
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
                image: AssetImage('assets/images/33a5dd847966ceae3071cddfbb1d9382.jpg'),
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
                      'Create Profile',
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.08, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.06),
                    TextFormField(
                      controller: _usernameController,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Username',
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
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(fontFamily: 'Times New Roman', color: Colors.white70, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(fontFamily: 'Times New Roman', color: Colors.white70, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(fontFamily: 'Times New Roman', color: Colors.white70, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _pinController,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '4-digit PIN',
                        labelStyle: TextStyle(fontFamily: 'Times New Roman', color: Colors.white70, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a PIN';
                        }
                        if (value.length != 4) {
                          return 'PIN must be 4 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _confirmPinController,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.04, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm PIN',
                        labelStyle: TextStyle(fontFamily: 'Times New Roman', color: Colors.white70, fontSize: screenWidth * 0.04),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your PIN';
                        }
                        if (value != _pinController.text) {
                          return 'PINs do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Upload Profile Image', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ),
                    if (_profileImagePath != null)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.02),
                        child: Image.file(File(_profileImagePath!), height: screenHeight * 0.1, width: screenHeight * 0.1, fit: BoxFit.cover),
                      ),
                    SizedBox(height: screenHeight * 0.03),
                    ElevatedButton(
                      onPressed: _createProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.02),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Create Profile',
                        style: TextStyle(fontFamily: 'Times New Roman', fontSize: screenWidth * 0.045),
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
