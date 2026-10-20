import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'quiz_question.dart';

class QuizService {
  Future<List<QuizQuestion>> generateQuizQuestions(String geminiApiKey, String language) async {
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);

    final prompt = 'Generate 10 multiple-choice questions about agriculture and farming (latest trends, crops, soil, irrigation, market practices). Each question should have 4 options (A, B, C, D) and a single correct answer. Provide the output in JSON format, like this: [{"question": "...", "options": ["A. ...", "B. ...", "C. ...", "D. ..."], "correctAnswer": "A"}, ...]. Ensure the questions are in $language.';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        print('Error: Empty response from Gemini API.');
        return [];
      }

      print('Gemini API Response: ${response.text}');

      // Gemini might return markdown, so extract the JSON part
      String jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();

      try {
        List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => QuizQuestion.fromJson(json)).toList();
      } catch (e) {
        print('Error decoding JSON: $e');
        print('Invalid JSON string: $jsonString');
        return [];
      }
    } catch (e) {
      print('Error generating quiz questions: $e');
      return [];
    }
  }
}
