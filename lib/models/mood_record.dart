class MoodRecord {
  final String weather;
  final Map<String, double> emotionPercents;
  final String memo;
  final DateTime createdAt;

  MoodRecord({
    required this.weather,
    required this.emotionPercents,
    required this.memo,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'weather': weather,
      'emotionPercents': emotionPercents,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MoodRecord.fromJson(Map<String, dynamic> json) {
    return MoodRecord(
      weather: json['weather'],
      emotionPercents: Map<String, double>.from(
        (json['emotionPercents'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as num).toDouble(),
          ),
        ),
      ),
      memo: json['memo'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }
}