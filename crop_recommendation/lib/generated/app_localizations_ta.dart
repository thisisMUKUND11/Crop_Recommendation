// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'ஹார்வெஸ்ட்-IQ';

  @override
  String get enterDistrict => 'மாவட்டம் உள்ளிடவும்';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get getRecommendation => 'பரிந்துரையைப் பெறுங்கள்';

  @override
  String get recommendedCrops => 'பரிந்துரைக்கப்பட்ட பயிர்கள்:';

  @override
  String get pleaseEnterDistrictName => 'மாவட்டத்தின் பெயரை உள்ளிடவும்.';

  @override
  String get couldNotFetchWeatherData =>
      'வானிலை தரவைப் பெற முடியவில்லை. மாவட்டத்தின் பெயரைச் சரிபார்க்கவும்.';

  @override
  String get couldNotFetchCropRecommendations =>
      'பயிர் பரிந்துரைகளைப் பெற முடியவில்லை.';

  @override
  String anErrorOccurred(Object error) {
    return 'ஒரு பிழை ஏற்பட்டது: $error';
  }

  @override
  String get savedToFavorites => 'பிடித்தவைகளில் சேமிக்கப்பட்டது.';

  @override
  String get login => 'உள்நுழைவு';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get dontHaveAnAccount => 'கணக்கு இல்லையா? பதிவு செய்யவும்';

  @override
  String get register => 'பதிவு';

  @override
  String get confirmPassword => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get passwordsDoNotMatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get termsAndConditions => 'விதிமுறைகள் மற்றும் நிபந்தனைகள்';

  @override
  String get accept => 'ஏற்கவும்';

  @override
  String get searchHistory => 'தேடல் வரலாறு';

  @override
  String get noSearchHistoryFound => 'தேடல் வரலாறு எதுவும் இல்லை.';

  @override
  String get favorites => 'பிடித்தவை';

  @override
  String get noFavoritesFound => 'பிடித்தவை எதுவும் இல்லை.';

  @override
  String district(Object district) {
    return 'மாவட்டம்: $district';
  }

  @override
  String recommendation(Object dateTime, Object recommendation) {
    return 'பரிந்துரை: $recommendation\n$dateTime';
  }

  @override
  String get speechRecognitionNotAvailable =>
      'இந்த சாதனத்தில் பேச்சு அங்கீகாரம் கிடைக்கவில்லை.';

  @override
  String get grantMicrophonePermission =>
      'இந்த அம்சத்தைப் பயன்படுத்த மைக்ரோஃபோன் அனுமதியை வழங்கவும்.';

  @override
  String get invalidEmailOrPassword => 'தவறான மின்னஞ்சல் அல்லது கடவுச்சொல்';

  @override
  String get termsAndConditionsContent =>
      'குறுகிய விதிமுறைகள் மற்றும் நிபந்தனைகள் உள்ளடக்கம்.';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get home => 'முகப்பு';

  @override
  String get history => 'வரலாறு';

  @override
  String get alreadyHaveAnAccount => 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழையவும்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get language => 'மொழி';

  @override
  String get listening => 'கேட்கிறது...';

  @override
  String get speakAgain => 'மீண்டும் பேசுங்கள்.';

  @override
  String get noRecommendationToShare => 'பகிர்வதற்கு பரிந்துரை இல்லை.';

  @override
  String get emailAlreadyRegistered =>
      'இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது.';

  @override
  String get forgotPassword => 'கடவுச்சொல்லை மறந்துவிட்டேன்';
}
