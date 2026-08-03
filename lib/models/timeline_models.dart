

class TimelineEvent {
  final int year;
  final String title;
  final String category;

  TimelineEvent({
    required this.year,
    required this.title,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'title': title,
      'category': category,
    };
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      year: json['year'],
      title: json['title'],
      category: json['category'] ?? 'その他',
    );
  }
}


class JapanEvent {
  final int year;
  final String title;
  final String category;
  final String description;
  final List<String> keywords;
  final List<String> emotions;
  final int? affectedAgeMin;
  final int? affectedAgeMax;

  JapanEvent({
    required this.year,
    required this.title,
    required this.category,
    required this.description,
    required this.keywords,
    required this.emotions,
    this.affectedAgeMin,
    this.affectedAgeMax,
  });

  factory JapanEvent.fromJson(Map<String, dynamic> json) {
    final affectedAge = json['affectedAge'];

    return JapanEvent(
      year: json['year'],
      title: json['title'],
      category: json['category'],
      description: json['description'],

      // keywordsがない古いデータでもエラーにならない
      keywords: List<String>.from(
        json['keywords'] ?? [],
      ),

      // emotionsがない古いデータでもエラーにならない
      emotions: List<String>.from(
        json['emotions'] ?? [],
      ),

      // affectedAgeがないデータでもエラーにならない
      affectedAgeMin: affectedAge is Map
          ? affectedAge['min'] as int?
          : null,

      affectedAgeMax: affectedAge is Map
          ? affectedAge['max'] as int?
          : null,
    );
  }
}
