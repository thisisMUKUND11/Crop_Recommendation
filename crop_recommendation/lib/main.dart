import 'package:crop_recommendation/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'terms_screen.dart';
import 'language_selection_screen.dart';
import 'package:palette_generator/palette_generator.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'HARVEST-IQ',
          theme: ThemeData(
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: Colors.green.shade100,
            fontFamily: 'serif',
          ),
          locale: provider.locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', ''),
            Locale('ta', ''),
          ],
          home: Wrapper(),
        );
      },
    );
  }
}

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');

    if (languageCode == null) {
      return LanguageSelectionScreen();
    }

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final acceptedTerms = prefs.getBool('acceptedTerms') ?? false;

    if (isLoggedIn) {
      if (acceptedTerms) {
        return MainPage();
      } else {
        return TermsScreen();
      }
    } else {
      return LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        return Scaffold(body: Center(child: Text('An error occurred.')));
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  PaletteGenerator? _paletteGenerator;

  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    FavoritesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/33a5dd847966ceae3071cddfbb1d9382.jpg'),
      size: Size(200, 200),
    );
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = _paletteGenerator?.vibrantColor?.color ?? Colors.green.shade800;
    final Color unselectedColor = _paletteGenerator?.lightVibrantColor?.color ?? Colors.green.shade400;
    final Color overlayColor = _paletteGenerator?.darkMutedColor?.color?.withOpacity(0.6) ?? Colors.black.withOpacity(0.6);

    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body behind app bar
      backgroundColor: Colors.transparent, // Make scaffold background transparent
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/33a5dd847966ceae3071cddfbb1d9382.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: overlayColor,
          ),
          Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: AppLocalizations.of(context)!.history,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: AppLocalizations.of(context)!.favorites,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent, // Make bottom navigation bar transparent
        elevation: 0, // Remove shadow
      ),
    );
  }
}
