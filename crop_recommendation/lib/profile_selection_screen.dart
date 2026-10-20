import 'main.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'custom_page_route.dart';
import 'profile.dart';
import 'profile_management_screen.dart';
import 'storage_service.dart';
import 'welcome_screen.dart';
import 'pin_entry_dialog.dart';
import 'forgot_pin_screen.dart';

class ProfileSelectionScreen extends StatefulWidget {
  @override
  _ProfileSelectionScreenState createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final StorageService _storageService = StorageService();
  List<UserProfile> _profiles = [];
  int _wrongPinAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await _storageService.getProfiles();
    setState(() {
      _profiles = profiles;
    });
  }

  void _onProfileSelected(UserProfile profile) async {
    await _storageService.setCurrentUserId(profile.id); // Set current user ID regardless

    if (profile.isFirstTime) { // This flag should ideally be false for new profiles now
      // If for some reason an old profile still has isFirstTime true,
      // we'll treat it as a new login for that profile and go to WelcomeScreen.
      // The language selection is now handled globally before any profiles are created.
      Navigator.pushReplacement(
        context,
        CustomPageRoute(
          child: WelcomeScreen(profileName: profile.name),
        ),
      );
      // Also, update the profile to mark it as not first time anymore
      profile.isFirstTime = false;
      profile.isConfigured = true;
      await _storageService.saveProfile(profile);
    } else {
      final pin = await showDialog<String>(
        context: context,
        builder: (context) => PinEntryDialog(),
      );

      if (pin != null) {
        if (pin == profile.pin) {
          _wrongPinAttempts = 0;
          // currentUserId is already set above
          Navigator.pushReplacement(
            context,
            CustomPageRoute(
              child: MainPage(),
            ),
          );
        } else {
          setState(() {
            _wrongPinAttempts++;
          });
          if (_wrongPinAttempts >= 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ForgotPinScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Wrong PIN. Please try again.'),
              ),
            );
          }
        }
      }
    }
  }

  void _addProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileManagementScreen(),
      ),
    ).then((_) => _loadProfiles());
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    if (profile.imagePath != null && profile.imagePath!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: FileImage(File(profile.imagePath!)),
        radius: 50,
      );
    } else {
      return CircleAvatar(
        radius: 50,
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 40),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/5142c15b2e424349261ebadff624dcd0.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Text(
                    'Select Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: _profiles.map((profile) {
                    return GestureDetector(
                      onTap: () => _onProfileSelected(profile),
                      child: Column(
                        children: [
                          _buildProfileAvatar(profile),
                          SizedBox(height: 10),
                          Text(
                            profile.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (_profiles.length < 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: ElevatedButton.icon(
                      onPressed: _addProfile,
                      icon: Icon(Icons.add),
                      label: Text('Add Profile'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
