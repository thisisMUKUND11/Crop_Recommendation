import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'what_if_history_item.dart';

class WhatIfHistoryScreen extends StatefulWidget {
  @override
  _WhatIfHistoryScreenState createState() => _WhatIfHistoryScreenState();
}

class _WhatIfHistoryScreenState extends State<WhatIfHistoryScreen> {
  final StorageService _storageService = StorageService();
  List<WhatIfHistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _storageService.getWhatIfHistory();
    setState(() {
      _history = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('What If Analysis History', style: TextStyle(fontSize: screenWidth * 0.05)),
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
                image: AssetImage('assets/images/3bdb604adcaa41f51606b474953609d4.jpg'), // Placeholder image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          _history.isEmpty
              ? Center(
                  child: Text(
                    'No What If Analysis history found.',
                    style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return Card(
                      color: Colors.white.withOpacity(0.8),
                      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                          item.question,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04, color: Colors.black),
                        ),
                        subtitle: Text(
                          '${item.district} - ${item.dateTime.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.black54),
                        ),
                        onTap: () {
                          // Optionally navigate back to WhatIfScreen with this history item's data
                          // For now, just show a dialog with the full details
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('What If Analysis Details'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('District: ${item.district}'),
                                    Text('Question: ${item.question}'),
                                    Text('Answer: ${item.answer}'),
                                    Text('Date: ${item.dateTime.toLocal().toString().split(' ')[0]}'),
                                    // You can add more details from weatherData, recommendedCrops if needed
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
