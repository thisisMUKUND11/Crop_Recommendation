class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'],
        options: List<String>.from(json['options']),
        correctAnswer: json['correctAnswer'],
      );
}
