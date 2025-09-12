// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HARVEST-IQ';

  @override
  String get enterDistrict => 'Enter District';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get getRecommendation => 'Get Recommendation';

  @override
  String get recommendedCrops => 'Recommended Crops:';

  @override
  String get pleaseEnterDistrictName => 'Please enter a district name.';

  @override
  String get couldNotFetchWeatherData =>
      'Could not fetch weather data. Check the district name.';

  @override
  String get couldNotFetchCropRecommendations =>
      'Could not fetch crop recommendations.';

  @override
  String anErrorOccurred(Object error) {
    return 'An error occurred: $error';
  }

  @override
  String get savedToFavorites => 'Saved to favorites.';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get dontHaveAnAccount => 'Don\'t have an account? Register';

  @override
  String get register => 'Register';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get accept => 'Accept';

  @override
  String get searchHistory => 'Search History';

  @override
  String get noSearchHistoryFound => 'No search history found.';

  @override
  String get favorites => 'Favorites';

  @override
  String get noFavoritesFound => 'No favorites found.';

  @override
  String district(Object district) {
    return 'District: $district';
  }

  @override
  String recommendation(Object dateTime, Object recommendation) {
    return 'Recommendation: $recommendation\n$dateTime';
  }

  @override
  String get speechRecognitionNotAvailable =>
      'Speech recognition not available on this device.';

  @override
  String get grantMicrophonePermission =>
      'Please grant microphone permission to use this feature.';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password';

  @override
  String get termsAndConditionsContent => 'Short terms and conditions content.';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get alreadyHaveAnAccount => 'Already have an account? Login';

  @override
  String get settings => 'Settings';

  @override
  String get signOut => 'Sign Out';

  @override
  String get language => 'Language';
}
