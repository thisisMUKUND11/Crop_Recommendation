import 'package:flutter/material.dart';
import 'storage_service.dart';

class GamificationScreen extends StatefulWidget {
  @override
  _GamificationScreenState createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  int _userPoints = 0;
  final StorageService _storageService = StorageService();

  // Mock leaderboard data
  final List<Map<String, dynamic>> _leaderboard = [
    {'name': 'Farmer John', 'points': 5200},
    {'name': 'Anita Patil', 'points': 4850},
    {'name': 'Rajesh Kumar', 'points': 4500},
    {'name': 'Deepa Singh', 'points': 3900},
    {'name': 'Sanjay Verma', 'points': 3200},
  ];

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    int points = await _storageService.getPoints();
    setState(() {
      _userPoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Points & Leaderboard'),
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
                image: AssetImage('assets/images/3bdb604adcaa41f51606b474953609d4.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Your Total Points',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          '$_userPoints',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  'Leaderboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                SizedBox(height: 8.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: _leaderboard.length,
                    itemBuilder: (context, index) {
                      final user = _leaderboard[index];
                      return Card(
                        color: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Text('${index + 1}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(user['name'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          trailing: Text('${user['points']} points', style: TextStyle(color: Colors.white70)),
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
