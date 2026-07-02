import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import 'search_history_item.dart';
import 'favorite_item.dart';
import 'generated/app_localizations.dart';


class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SearchHistoryItem>> _historyFuture;
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  List<SearchHistoryItem> _allHistoryItems = [];

  @override
  void initState() {
    super.initState();
    _historyFuture = _storageService.getSearchHistory(); // Initialize here
    _loadHistory();
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadHistory() async {
    _allHistoryItems = await _storageService.getSearchHistory();
    setState(() {
      _historyFuture = Future.value(_allHistoryItems); // Update _historyFuture here
    });
    _filterHistory(); // Apply initial filter
  }

  void _filterHistory() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _historyFuture = Future.value(_allHistoryItems);
      } else {
        _historyFuture = Future.value(_allHistoryItems.where((item) {
          return item.district.toLowerCase().contains(query) ||
                 item.recommendation.toLowerCase().contains(query);
        }).toList());
      }
    });
  }

  void _clearHistory() async {
    final confirmClear = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text('Clear History'),
      content: Text('Are you sure you want to clear all search history? This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Clear')),
      ],
    ));

    if (confirmClear == true) {
      await _storageService.clearSearchHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchHistory, style: TextStyle(fontSize: screenWidth * 0.05)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.black),
            onPressed: _clearHistory,
          ),
        ],
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
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    labelText: 'Search History',
                    labelStyle: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.04),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<SearchHistoryItem>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text(AppLocalizations.of(context)!.anErrorOccurred(snapshot.error.toString()), style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(AppLocalizations.of(context)!.noSearchHistoryFound, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)));
                    }

                    final history = snapshot.data!;

                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Card(
                          color: Colors.white.withOpacity(0.2),
                          margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01, horizontal: screenWidth * 0.04),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Icon(Icons.history, color: Colors.white, size: screenWidth * 0.06),
                            title: Text(
                              item.district,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04),
                            ),
                            subtitle: Text(
                              item.recommendation,
                              style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.035),
                            ),
                            trailing: Text(
                              '${item.dateTime.day}/${item.dateTime.month}/${item.dateTime.year}',
                              style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.03),
                            ),
                            onTap: () => _showItemDetails(context, item, history),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showItemDetails(BuildContext context, SearchHistoryItem item, List<SearchHistoryItem> history) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final random = Random();
    final relatedItems = <SearchHistoryItem>{};
    if (history.length > 1) {
      while (relatedItems.length < 3 && relatedItems.length < history.length - 1) {
        final randomIndex = random.nextInt(history.length);
        final randomItem = history[randomIndex];
        if (randomItem != item) {
          relatedItems.add(randomItem);
        }
      }
    }

    bool isCurrentlyFavorite = await _storageService.isFavorite(item.district, item.recommendation);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(item.district, style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.recommendation, style: TextStyle(fontSize: screenWidth * 0.04)),
                    SizedBox(height: screenHeight * 0.02),
                    if (relatedItems.isNotEmpty)
                      Text('Related Outputs:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
                    ...relatedItems.map((related) => Card(
                      color: Colors.white.withOpacity(0.5),
                      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                      child: ListTile(
                        title: Text(related.district, style: TextStyle(fontSize: screenWidth * 0.04)),
                        subtitle: Text(related.recommendation, style: TextStyle(fontSize: screenWidth * 0.035)),
                      ),
                    )),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isCurrentlyFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isCurrentlyFavorite ? Colors.red : Colors.red,
                    size: screenWidth * 0.06,
                  ),
                  onPressed: () async {
                    if (isCurrentlyFavorite) {
                      // Find the favorite item to remove by its content
                      final favorites = await _storageService.getFavorites();
                      final favoriteToRemove = favorites.firstWhere(
                        (fav) => fav.district == item.district && fav.recommendation == item.recommendation,
                      );
                      await _storageService.removeFavorite(favoriteToRemove.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed from favorites.')),
                      );
                    } else {
                      final favoriteItem = FavoriteItem(
                        id: Uuid().v4(), // Generate a new ID for the favorite
                        district: item.district,
                        recommendation: item.recommendation,
                        dateTime: DateTime.now(),
                      );
                      await _storageService.saveFavorite(favoriteItem);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.savedToFavorites)),
                      );
                    }
                    setState(() {
                      isCurrentlyFavorite = !isCurrentlyFavorite;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.blue, size: screenWidth * 0.06),
                  onPressed: () {
                    Share.share('Crop recommendation for ${item.district}:\n${item.recommendation}');
                  },
                ),
                TextButton(
                  child: Text('Close', style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
