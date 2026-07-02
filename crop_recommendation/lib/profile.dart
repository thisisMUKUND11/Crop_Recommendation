
import 'quiz_question.dart';

class UserProfile {
  String id;
  String name;
  String? imagePath;
  String? pin;
  String? email;
  String? password; // TODO: Hash this password
  bool isFirstTime;
  int lastSelectedIndex;
  bool isConfigured;
  String? lastQuizDate; // YYYY-MM-DD format
  List<QuizQuestion>? dailyQuizQuestions;
  bool hasViewedLeaderboardAfterQuiz;
  int totalPoints;

  UserProfile({
    required this.id,
    required this.name,
    this.imagePath,
    this.pin,
    this.email,
    this.password,
    this.isFirstTime = true,
    this.lastSelectedIndex = 0,
    this.isConfigured = false,
    this.lastQuizDate,
    this.dailyQuizQuestions,
    this.hasViewedLeaderboardAfterQuiz = false,
    this.totalPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'pin': pin,
      'email': email,
      'password': password,
      'isFirstTime': isFirstTime,
      'lastSelectedIndex': lastSelectedIndex,
      'isConfigured': isConfigured,
      'lastQuizDate': lastQuizDate,
      'dailyQuizQuestions': dailyQuizQuestions?.map((q) => q.toJson()).toList(),
      'hasViewedLeaderboardAfterQuiz': hasViewedLeaderboardAfterQuiz,
      'totalPoints': totalPoints,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      pin: map['pin'],
      email: map['email'],
      password: map['password'],
      isFirstTime: map['isFirstTime'] ?? true,
      lastSelectedIndex: map['lastSelectedIndex'] ?? 0,
      isConfigured: map['isConfigured'] ?? false,
      lastQuizDate: map['lastQuizDate'],
      dailyQuizQuestions: (map['dailyQuizQuestions'] as List<dynamic>?)?.map((q) => QuizQuestion.fromJson(q)).toList(),
      hasViewedLeaderboardAfterQuiz: map['hasViewedLeaderboardAfterQuiz'] ?? false,
      totalPoints: map['totalPoints'] ?? 0,
    );
  }
}
