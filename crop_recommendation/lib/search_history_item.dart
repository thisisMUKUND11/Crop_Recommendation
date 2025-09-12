
class SearchHistoryItem {
  final String district;
  final String recommendation;
  final DateTime dateTime;

  SearchHistoryItem({
    required this.district,
    required this.recommendation,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
        'district': district,
        'recommendation': recommendation,
        'dateTime': dateTime.toIso8601String(),
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) => SearchHistoryItem(
        district: json['district'],
        recommendation: json['recommendation'],
        dateTime: DateTime.parse(json['dateTime']),
      );
}
