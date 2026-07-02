import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'storage_service.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';
import 'quiz_question.dart';
import 'profile.dart';
import 'language_selection_screen.dart';
import 'pin_entry_dialog.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';

class ProfileManagementScreen extends StatefulWidget {
  @override
  _ProfileManagementScreenState createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final StorageService _storageService = StorageService();
  List<UserProfile> _profiles = [];
  final Uuid _uuid = Uuid();

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

  Future<void> _addOrEditProfile({UserProfile? profile}) async {
    final isEditing = profile != null;
    final nameController = TextEditingController(text: profile?.name);
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? tempImagePath = profile?.imagePath;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    await showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(isEditing ? 'Edit Profile' : 'Add Profile', style: TextStyle(fontSize: screenWidth * 0.05)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Profile Name', labelStyle: TextStyle(fontSize: screenWidth * 0.04)),
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
          SizedBox(height: screenHeight * 0.02),
          TextField(
            controller: pinController,
            decoration: InputDecoration(labelText: '4-digit PIN', labelStyle: TextStyle(fontSize: screenWidth * 0.04)),
            style: TextStyle(fontSize: screenWidth * 0.04),
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
          ),
          SizedBox(height: screenHeight * 0.02),
          TextField(
            controller: confirmPinController,
            decoration: InputDecoration(labelText: 'Confirm PIN', labelStyle: TextStyle(fontSize: screenWidth * 0.04)),
            style: TextStyle(fontSize: screenWidth * 0.04),
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
          ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: () async {
              final ImagePicker _picker = ImagePicker();
              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setState(() {
                  tempImagePath = image.path;
                });
              }
            },
            child: Text('Upload Image', style: TextStyle(fontSize: screenWidth * 0.04)),
          ),
          if (tempImagePath != null)
            Image.file(File(tempImagePath!), height: screenHeight * 0.1, width: screenHeight * 0.1, fit: BoxFit.cover),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.04))),
        TextButton(onPressed: () async {
          if (nameController.text.isNotEmpty) {
            if (pinController.text.length == 4 && pinController.text == confirmPinController.text) {
              if (isEditing) {
                profile!.name = nameController.text;
                profile.imagePath = tempImagePath;
                profile.pin = pinController.text;
                await _storageService.saveProfile(profile);
              } else {
                final profiles = await _storageService.getProfiles();
                final email = profiles.first.email;
                final profilesWithSameEmail = profiles.where((p) => p.email == email).toList();

                if (profilesWithSameEmail.length >= 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You can only create 2 profiles per email address.'),
                    ),
                  );
                  return;
                }

                final newProfile = UserProfile(
                  id: _uuid.v4(),
                  name: nameController.text,
                  imagePath: tempImagePath,
                  pin: pinController.text,
                  email: email,
                );
                await _storageService.saveProfile(newProfile);
                await _storageService.setCurrentUserId(newProfile.id);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeScreen(profileName: newProfile.name)),
                  (route) => false,
                );
              }
              _loadProfiles();
              Navigator.pop(context);
            }
          }
        }, child: Text(isEditing ? 'Save' : 'Add', style: TextStyle(fontSize: screenWidth * 0.04))),
      ],
    ));
  }

  Future<void> _changePin(UserProfile profile) async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmNewPinController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              decoration: InputDecoration(labelText: 'Old PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            TextField(
              controller: newPinController,
              decoration: InputDecoration(labelText: 'New PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            TextField(
              controller: confirmNewPinController,
              decoration: InputDecoration(labelText: 'Confirm New PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (oldPinController.text == profile.pin) {
                if (newPinController.text.length == 4 && newPinController.text == confirmNewPinController.text) {
                  profile.pin = newPinController.text;
                  await _storageService.saveProfile(profile);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('New PINs do not match or are not 4 digits.'),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Wrong old PIN.'),
                  ),
                );
              }
            },
            child: Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    final screenWidth = MediaQuery.of(context).size.width;
    return CircleAvatar(
      backgroundImage: profile.imagePath != null ? FileImage(File(profile.imagePath!)) : null,
      radius: screenWidth * 0.075,
      child: profile.imagePath == null && profile.name.isNotEmpty
          ? Text(profile.name.substring(0, 2).toUpperCase(), style: TextStyle(fontSize: screenWidth * 0.04))
          : profile.imagePath == null
              ? Text('P${_profiles.indexOf(profile) + 1}', style: TextStyle(fontSize: screenWidth * 0.04))
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Profiles', style: TextStyle(fontSize: screenWidth * 0.05)),
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
          ListView.builder(
            itemCount: _profiles.length + (_profiles.length < 3 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _profiles.length) {
                final profile = _profiles[index];
                return Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
                  child: ListTile(
                    leading: _buildProfileAvatar(profile),
                    title: Text(profile.name, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
                    onTap: () async {
                      await _storageService.setCurrentUserId(profile.id);
                      Navigator.pop(context);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit, size: screenWidth * 0.06, color: Colors.white), onPressed: () => _addOrEditProfile(profile: profile)),
                        IconButton(icon: Icon(Icons.vpn_key, size: screenWidth * 0.06, color: Colors.white), onPressed: () => _changePin(profile)),
                        IconButton(icon: Icon(Icons.delete, size: screenWidth * 0.06, color: Colors.red), onPressed: () async {
                          final pin = await showDialog<String>(
                            context: context,
                            builder: (context) => PinEntryDialog(),
                          );

                          if (pin != null) {
                            if (pin == profile.pin) {
                              final confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Profile', style: TextStyle(fontSize: screenWidth * 0.05)),
                                  content: Text('Are you sure you want to delete this profile? All associated data will be lost.', style: TextStyle(fontSize: screenWidth * 0.04)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.04))),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(fontSize: screenWidth * 0.04))),
                                  ],
                                ),
                              );

                              if (confirmDelete == true) {
                                await _storageService.deleteUser(profile.id);
                                _loadProfiles(); // Reload profiles after deletion
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Wrong PIN. Please try again.'),
                                ),
                              );
                            }
                          }
                        }),
                      ],
                    ),
                  ),
                );
              } else {
                return Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
                  child: ListTile(
                    leading: Icon(Icons.add, size: screenWidth * 0.06, color: Colors.white), // Add icon for new profile
                    title: Text('Add New Profile', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
                    onTap: _profiles.length < 3 ? () => _addOrEditProfile() : null,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
