import 'profile_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'package:flutter/services.dart';

// Local imports
import 'locale_provider.dart';
import 'theme_provider.dart';
import 'generated/app_localizations.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'terms_screen.dart';
import 'language_selection_screen.dart';
import 'settings_screen.dart';
import 'storage_service.dart'; // Import StorageService
import 'notification_service.dart'; // Import NotificationService
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'profile.dart';
import 'welcome_screen.dart';
import 'quiz_screen.dart';
import 'leaderboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().init(); // Initialize NotificationService
  } catch (e) {
    // Notifications are optional; don't block app start on unsupported platforms.
    debugPrint('Notification init failed: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

// App-wide Material 3 theme. Poppins is a clean, highly legible sans-serif;
// Noto Sans Tamil is the fallback so Tamil text renders with a matching style.
ThemeData buildAppTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    brightness: brightness,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  final fallback = [GoogleFonts.notoSansTamil().fontFamily!];
  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme)
      .apply(fontFamilyFallback: fallback);
  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: GoogleFonts.poppinsTextTheme(base.primaryTextTheme)
        .apply(fontFamilyFallback: fallback),
    scaffoldBackgroundColor: isLight ? const Color(0xFFF3F8EF) : const Color(0xFF111611),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: rounded,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: rounded,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: rounded,
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HARVEST-IQ',
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('ta', ''),
          ],
          home: AuthWrapper(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/terms': (context) => TermsScreen(),
            '/main': (context) => MainPage(),
            '/language': (context) => LanguageSelectionScreen(),
            '/forgot_password': (context) => ForgotPasswordScreen(),
            '/welcome': (context) => WelcomeScreen(profileName: ''), // Placeholder, actual name passed in AuthWrapper
            '/quiz': (context) => QuizScreen(questions: []), // Placeholder, questions passed dynamically
            '/leaderboard': (context) => LeaderboardScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _storageService.isLoggedIn();
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileSelectionScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  UserProfile? _currentUserProfile;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile().then((_) {
      if (_currentUserProfile != null) {
        setState(() {
          _selectedIndex = _currentUserProfile!.lastSelectedIndex;
        });
      }
    });
  }

  Future<void> _loadCurrentUserProfile() async {
    final currentUserId = await _storageService.getCurrentUserId();
    if (currentUserId != null) {
      final profiles = await _storageService.getProfiles();
      _currentUserProfile = profiles.where((p) => p.id == currentUserId).firstOrNull;
      // No setState here, as it's called after the future completes in initState
    }
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    if (profile.imagePath != null) {
      return CircleAvatar(
        backgroundImage: FileImage(File(profile.imagePath!)),
        radius: 12, // Adjusted radius
      );
    } else if (profile.name.isNotEmpty) {
      return CircleAvatar(
        child: Text(profile.name.substring(0, 2).toUpperCase(), style: TextStyle(fontSize: 10)), // Adjusted font size
        radius: 12, // Adjusted radius
      );
    } else {
      return CircleAvatar(
        child: Text('P', style: TextStyle(fontSize: 10)), // Adjusted font size
        radius: 12, // Adjusted radius
      );
    }
  }

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    if (_currentUserProfile != null) {
      _currentUserProfile!.lastSelectedIndex = index;
      await _storageService.saveProfile(_currentUserProfile!); // Save the updated profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: [
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
            BottomNavigationBarItem(
              icon: _currentUserProfile != null ? _buildProfileAvatar(_currentUserProfile!) : Icon(Icons.settings, size: 24),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            _onItemTapped(index);
          },
          backgroundColor: Colors.white,
          elevation: 8,
        ),
      ),
    );
  }
}
