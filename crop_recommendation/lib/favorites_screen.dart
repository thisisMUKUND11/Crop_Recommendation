import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'favorite_item.dart';
import 'generated/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<FavoriteItem>> _favoritesFuture;
  final StorageService _storageService = StorageService();
  PaletteGenerator? _paletteGenerator;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _storageService.getFavorites();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/da085bd6e9418897239f27f4e450d6ed.jpg'),
      size: Size(200, 200),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = _paletteGenerator?.dominantColor?.color ?? Colors.green.shade800;
    final Color accentColor = _paletteGenerator?.vibrantColor?.color ?? Colors.white;
    final Color textColor = _paletteGenerator?.lightVibrantColor?.color ?? Colors.white;
    final Color cardColor = _paletteGenerator?.darkMutedColor?.color?.withOpacity(0.2) ?? Colors.white.withOpacity(0.2);
    final Color subtitleColor = _paletteGenerator?.lightMutedColor?.color ?? Colors.white70;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.favorites),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/da085bd6e9418897239f27f4e450d6ed.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<FavoriteItem>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accentColor)));
            }
            if (snapshot.hasError) {
              return Center(child: Text(AppLocalizations.of(context)!.anErrorOccurred(snapshot.error.toString()), style: TextStyle(color: textColor)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(AppLocalizations.of(context)!.noFavoritesFound, style: TextStyle(color: textColor)));
            }

            final favorites = snapshot.data!;

            return ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return Card(
                  color: cardColor,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.district(item.district),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.recommendation(item.recommendation, item.dateTime.toString()),
                      style: TextStyle(color: subtitleColor),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
