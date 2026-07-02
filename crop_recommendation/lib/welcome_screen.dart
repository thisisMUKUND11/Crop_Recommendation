import 'package:flutter/material.dart';
import 'main.dart'; // Import MainPage

class WelcomeScreen extends StatelessWidget {
  final String profileName;

  WelcomeScreen({required this.profileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, $profileName!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                      (route) => false,
                    );
                  },
                  child: Text('Continue to App'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
