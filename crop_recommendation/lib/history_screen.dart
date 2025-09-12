import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'search_history_item.dart';
import 'generated/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SearchHistoryItem>> _historyFuture;
  final StorageService _storageService = StorageService();
  PaletteGenerator? _paletteGenerator;

  @override
  void initState() {
    super.initState();
    _historyFuture = _storageService.getSearchHistory();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/160fea8fb41001beab1df8bdb02c148d.jpg'),
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
        title: Text(AppLocalizations.of(context)!.searchHistory),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/160fea8fb41001beab1df8bdb02c148d.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<SearchHistoryItem>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accentColor)));
            }
            if (snapshot.hasError) {
              return Center(child: Text(AppLocalizations.of(context)!.anErrorOccurred(snapshot.error.toString()), style: TextStyle(color: textColor)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(AppLocalizations.of(context)!.noSearchHistoryFound, style: TextStyle(color: textColor)));
            }

            final history = snapshot.data!;

            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
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
