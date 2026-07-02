import 'package:uuid/uuid.dart';

class WhatIfHistoryItem {
  String id;
  String district;
  Map<String, dynamic> weatherData;
  List<String> recommendedCrops;
  String question;
  String answer;
  DateTime dateTime;

  WhatIfHistoryItem({
    String? id,
    required this.district,
    required this.weatherData,
    required this.recommendedCrops,
    required this.question,
    required this.answer,
    required this.dateTime,
  }) : id = id ?? Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'district': district,
        'weatherData': weatherData,
        'recommendedCrops': recommendedCrops,
        'question': question,
        'answer': answer,
        'dateTime': dateTime.toIso8601String(),
      };

  factory WhatIfHistoryItem.fromJson(Map<String, dynamic> json) => WhatIfHistoryItem(
        id: json['id'],
        district: json['district'],
        weatherData: json['weatherData'],
        recommendedCrops: List<String>.from(json['recommendedCrops']),
        question: json['question'],
        answer: json['answer'],
        dateTime: DateTime.parse(json['dateTime']),
      );
}
