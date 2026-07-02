import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'favorite_item.dart';
import 'generated/app_localizations.dart';
import 'crop_planner_screen.dart';
import 'custom_page_route.dart';


class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<FavoriteItem>> _favoritesFuture;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _storageService.getFavorites();
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.favorites),
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
                image: AssetImage('assets/images/1d8511b11ec30fb28ae1b248401b9b12.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          FutureBuilder<List<FavoriteItem>>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
              }
              if (snapshot.hasError) {
                return Center(child: Text(AppLocalizations.of(context)!.anErrorOccurred(snapshot.error.toString()), style: TextStyle(color: Colors.white)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(AppLocalizations.of(context)!.noFavoritesFound, style: TextStyle(color: Colors.white)));
              }

              final favorites = snapshot.data!;

              return ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final item = favorites[index];
                  return Card(
                    color: Colors.white.withOpacity(0.2),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.favorite, color: Colors.red),
                      title: Text(
                        item.district,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item.recommendation,
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.dateTime.day}/${item.dateTime.month}/${item.dateTime.year}',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_calendar, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                CustomPageRoute(
                                  child: CropPlannerScreen(cropName: item.recommendation),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
