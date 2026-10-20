import 'package:flutter/material.dart';
import 'storage_service.dart';

class ForgotPinScreen extends StatefulWidget {
  @override
  _ForgotPinScreenState createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final StorageService _storageService = StorageService();

  String? _userId;
  bool _otpSent = false;

  void _sendOtp() async {
    if (_phoneController.text.isNotEmpty) {
      // In a real app, you would send an OTP to the phone number
      // and verify it. For this mock implementation, we will just
      // find the user by phone number and allow them to reset the PIN.
      final profiles = await _storageService.getProfiles();
      try {
        final profile = profiles.firstWhere((p) => p.id == _phoneController.text); // Using phone number as user id for mock
        setState(() {
          _userId = profile.id;
          _otpSent = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not found.'),
          ),
        );
      }
    }
  }

  void _resetPin() async {
    if (_formKey.currentState!.validate()) {
      if (_newPinController.text == _confirmPinController.text) {
        if (_userId != null) {
          final profiles = await _storageService.getProfiles();
          final profile = profiles.where((p) => p.id == _userId).firstOrNull;
          if (profile == null) return;
          profile.pin = _newPinController.text;
          await _storageService.saveProfile(profile);
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot PIN'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/3bdb604adcaa41f51606b474953609d4.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_otpSent)
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Registered Phone Number',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  if (!_otpSent)
                    SizedBox(height: 20),
                  if (!_otpSent)
                    ElevatedButton(
                      onPressed: _sendOtp,
                      child: Text('Send OTP'),
                    ),
                  if (_otpSent)
                    TextFormField(
                      controller: _otpController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'OTP',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        return null;
                      },
                    ),
                  if (_otpSent)
                    SizedBox(height: 20),
                  if (_otpSent)
                    TextFormField(
                      controller: _newPinController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New 4-digit PIN',
                        labelStyle: TextStyle(color: Colors.white70),
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
                        if (value == null || value.isEmpty || value.length != 4) {
                          return 'Please enter a 4-digit PIN';
                        }
                        return null;
                      },
                    ),
                  if (_otpSent)
                    SizedBox(height: 20),
                  if (_otpSent)
                    TextFormField(
                      controller: _confirmPinController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm New PIN',
                        labelStyle: TextStyle(color: Colors.white70),
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
                        if (value == null || value.isEmpty || value != _newPinController.text) {
                          return 'PINs do not match';
                        }
                        return null;
                      },
                    ),
                  if (_otpSent)
                    SizedBox(height: 20),
                  if (_otpSent)
                    ElevatedButton(
                      onPressed: _resetPin,
                      child: Text('Reset PIN'),
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
