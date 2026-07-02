import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'storage_service.dart';
import 'profile.dart';


class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final StorageService _storageService = StorageService();
  List<UserProfile> _rankedUsers = [];
  UserProfile? _currentUserProfile;
  int _currentUserRank = 0;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final allProfiles = await _storageService.getProfiles();
    // Filter out profiles that are not configured (i.e., haven't registered)
    final configuredProfiles = allProfiles.where((p) => p.isConfigured).toList();

    // Sort by points in descending order
    configuredProfiles.sort((a, b) => (b.totalPoints ?? 0).compareTo(a.totalPoints ?? 0));

    final currentUserId = await _storageService.getCurrentUserId();
    UserProfile? currentUser;
    if (currentUserId != null) {
      currentUser = configuredProfiles.firstWhereOrNull((p) => p.id == currentUserId);
    }

    setState(() {
      _rankedUsers = configuredProfiles;
      _currentUserProfile = currentUser;
      if (currentUser != null) {
        _currentUserRank = configuredProfiles.indexOf(currentUser) + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard', style: TextStyle(fontSize: screenWidth * 0.05)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/3bdb604adcaa41f51606b474953609d4.jpg'), // Placeholder image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_currentUserProfile != null)
                  Card(
                    color: Colors.green.withOpacity(0.7),
                    margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        children: [
                          Text(
                            'Your Rank: $_currentUserRank',
                            style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Your Score: ${_currentUserProfile!.totalPoints ?? 0}',
                            style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _rankedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _rankedUsers[index];
                      return Card(
                        color: Colors.white.withOpacity(0.8),
                        margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                        child: ListTile(
                          leading: Text('#${index + 1}', style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.black)),
                          title: Text(user.name, style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black)),
                          trailing: Text('${user.totalPoints ?? 0} pts', style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black)),
                        ),
                      );
                    },
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
