
class FavoriteItem {
  final String district;
  final String recommendation;
  final DateTime dateTime;

  FavoriteItem({
    required this.district,
    required this.recommendation,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
        'district': district,
        'recommendation': recommendation,
        'dateTime': dateTime.toIso8601String(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        district: json['district'],
        recommendation: json['recommendation'],
        dateTime: DateTime.parse(json['dateTime']),
      );
}
