class TopicResult {
  final String topic;
  final double confidence;

  const TopicResult({
    required this.topic,
    required this.confidence,
  });
}

class TopicBrain {
  TopicResult analyze(
    String text, {
    List<String> recentUserMessages = const [],
  }) {
    final currentResult = _analyzeSingle(text);

    // 今の発言だけで話題がはっきり分かるなら、そのまま使う
    if (currentResult.topic != 'general' &&
        currentResult.confidence >= 0.7) {
      return currentResult;
    }

    // 今回の文章だけでは分からない場合、
    // 直前のユーザー発言から話題を探す
    final previousTopic = _detectTopicFromHistory(
      recentUserMessages,
      currentText: text,
    );

    if (previousTopic != null) {
      return TopicResult(
        topic: previousTopic,
        confidence: 0.65,
      );
    }

    return currentResult;
  }

  TopicResult _analyzeSingle(String text) {
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
      '先輩',
      '後輩',
      '出勤',
      '残業',
      '転職',
      '面接',
      '就活',
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
      '宿題',
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
      '未読',
      '返信',
      '別れ',
      '仲直り',
      '付き合って',
      '会いたい',
    ])) {
      add('love', 0.9);
    }

    // 家族
    if (_containsAny(text, [
      '家族',
      'お母さん',
      '母親',
      '母',
      'お父さん',
      '父親',
      '父',
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
      '友だち',
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
      '病院',
      'しんどい',
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

  String? _detectTopicFromHistory(
    List<String> recentUserMessages, {
    required String currentText,
  }) {
    if (recentUserMessages.isEmpty) {
      return null;
    }

    // sendMessage後は今回の発言も履歴に入っているので、
    // 一番最後が同じ文章なら除外する
    final history = List<String>.from(recentUserMessages);

    if (history.isNotEmpty &&
        history.last.trim() == currentText.trim()) {
      history.removeLast();
    }

    if (history.isEmpty) {
      return null;
    }

    // 直近5件だけを見る
    final start =
        history.length > 5 ? history.length - 5 : 0;

    final recent = history.sublist(start).reversed;

    for (final message in recent) {
      final result = _analyzeSingle(message);

      if (result.topic != 'general' &&
          result.confidence >= 0.7) {
        return result.topic;
      }
    }

    return null;
  }

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(text.contains);
  }
}