class LunaMemory {
  final String topic;
  final String summary;
  final DateTime createdAt;

  LunaMemory({
    required this.topic,
    required this.summary,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LunaMemory.fromJson(Map<String, dynamic> json) {
    return LunaMemory(
      topic: json['topic'],
      summary: json['summary'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}