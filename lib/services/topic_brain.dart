class TopicResult {
  final String topic;
  final double confidence;

  const TopicResult({
    required this.topic,
    required this.confidence,
  });
}

class TopicBrain {
  TopicResult analyze(String text) {
    final scores = <String, double>{
      'work': 0,
      'school': 0,
      'love': 0,
      'family': 0,
      'friend': 0,
      'health': 0,
      'general': 0.1,
    };

    void add(String topic, double score) {
      scores[topic] = (scores[topic] ?? 0) + score;
    }

    // 仕事
    if (_containsAny(text, [
      '仕事',
      '会社',
      '職場',
      '上司',
      '同僚',
      '出勤',
      '残業',
      '転職',
    ])) {
      add('work', 0.9);
    }

    // 学校
    if (_containsAny(text, [
      '学校',
      '授業',
      '先生',
      'クラス',
      '勉強',
      'テスト',
      '受験',
      '部活',
    ])) {
      add('school', 0.9);
    }

    // 恋愛
    if (_containsAny(text, [
      '彼氏',
      '彼女',
      '好きな人',
      '恋愛',
      'デート',
      '既読',
      '返信',
      '別れ',
      '仲直り',
    ])) {
      add('love', 0.9);
    }

    // 家族
    if (_containsAny(text, [
      '家族',
      'お母さん',
      '母親',
      'お父さん',
      '父親',
      '親',
      '兄',
      '姉',
      '弟',
      '妹',
    ])) {
      add('family', 0.9);
    }

    // 友達
    if (_containsAny(text, [
      '友達',
      '友人',
      '親友',
      'クラスメイト',
      '仲間外れ',
    ])) {
      add('friend', 0.9);
    }

    // 健康
    if (_containsAny(text, [
      '体調',
      '病気',
      '通院',
      '薬',
      '痛い',
      '眠れない',
      '食欲',
    ])) {
      add('health', 0.9);
    }

    final strongest = scores.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    return TopicResult(
      topic: strongest.key,
      confidence: strongest.value.clamp(0.0, 1.0),
    );
  }

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(text.contains);
  }
}