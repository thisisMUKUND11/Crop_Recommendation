import 'package:flutter/material.dart';
import 'quiz_question.dart';
import 'storage_service.dart';

import 'main.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;

  QuizScreen({required this.questions});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  Map<int, String> _userAnswers = {}; // Stores user's selected option for each question
  int _score = 0;
  bool _quizFinished = false;
  final StorageService _storageService = StorageService();

  void _handleAnswer(String selectedOption) {
    if (_quizFinished) return; // Prevent answering after quiz is finished

    setState(() {
      _userAnswers[_currentQuestionIndex] = selectedOption;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < widget.questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _quizFinished = true;
        _saveQuizResult();
      }
    });
  }

  void _previousQuestion() {
    setState(() {
      if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      }
    });
  }

  Future<void> _saveQuizResult() async {
    final currentUserId = await _storageService.getCurrentUserId();
    if (currentUserId != null) {
      // Calculate final score
      int finalScore = 0;
      for (int i = 0; i < widget.questions.length; i++) {
        if (_userAnswers.containsKey(i) && _userAnswers[i]!.startsWith(widget.questions[i].correctAnswer)) {
          finalScore++;
        }
      }
      setState(() {
        _score = finalScore;
      });

      final profiles = await _storageService.getProfiles();
      final currentUserProfile = profiles.where((p) => p.id == currentUserId).firstOrNull;
      if (currentUserProfile == null) return;
      // Update user's total score
      await _storageService.addPoints(_score);
      // Save quiz questions and date to user profile
      currentUserProfile.lastQuizDate = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      currentUserProfile.dailyQuizQuestions = widget.questions;
      await _storageService.saveProfile(currentUserProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_quizFinished) {
      return _buildReviewScreen(screenWidth, screenHeight);
    }

    final currentQuestion = widget.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Quiz', style: TextStyle(fontSize: screenWidth * 0.05)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/3bdb604adcaa41f51606b474953609d4.jpg'), // Placeholder image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.green,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  'Question ${_currentQuestionIndex + 1}/${widget.questions.length}',
                  style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenHeight * 0.02),
                Card(
                  color: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Text(
                      currentQuestion.question,
                      style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, index) {
                      final option = currentQuestion.options[index];
                      final isSelected = _userAnswers[_currentQuestionIndex] == option;
                      return Card(
                        color: isSelected ? Colors.green.withOpacity(0.7) : Colors.white.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                        child: ListTile(
                          title: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: screenWidth * 0.04)),
                          onTap: () => _handleAnswer(option),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                      child: Text('Previous', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ),
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      child: Text(_currentQuestionIndex < widget.questions.length - 1 ? 'Next' : 'Finish', style: TextStyle(fontSize: screenWidth * 0.04)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewScreen(double screenWidth, double screenHeight) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Review', style: TextStyle(fontSize: screenWidth * 0.05)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/3bdb604adcaa41f51606b474953609d4.jpg'), // Placeholder image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'You scored $_score/${widget.questions.length} 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.02),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.questions.length,
                    itemBuilder: (context, index) {
                      final question = widget.questions[index];
                      final userAnswer = _userAnswers[index];
                      final isCorrect = userAnswer != null && userAnswer.startsWith(question.correctAnswer);
                      return Card(
                        color: Colors.white.withOpacity(0.8),
                        margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${index + 1}: ${question.question}',
                                style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              ...question.options.map((option) {
                                Color textColor = Colors.black;
                                FontWeight fontWeight = FontWeight.normal;

                                if (option.startsWith(question.correctAnswer)) {
                                  textColor = Colors.green;
                                  fontWeight = FontWeight.bold;
                                } else if (option == userAnswer) {
                                  textColor = Colors.red;
                                  fontWeight = FontWeight.bold;
                                }

                                return Text(
                                  '${option}',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    color: textColor,
                                    fontWeight: fontWeight,
                                  ),
                                );
                              }).toList(),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Your Answer: ${userAnswer ?? 'Not answered'}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: isCorrect ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Correct Answer: ${question.options.firstWhere((o) => o.startsWith(question.correctAnswer), orElse: () => question.correctAnswer)}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                      (route) => false,
                    );
                  },
                  child: Text('Back to Home', style: TextStyle(fontSize: screenWidth * 0.045)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
