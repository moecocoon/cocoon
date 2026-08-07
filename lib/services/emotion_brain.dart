class EmotionResult {
  final Map<String, double> emotions;
  final String strongestEmotion;

  EmotionResult({
    required this.emotions,
    required this.strongestEmotion,
  });
}

class EmotionBrain {
  EmotionResult analyze(String text) {
    final emotions = <String, double>{
      'happy': 0.0,
      'peace': 0.0,
      'anxiety': 0.0,
      'sad': 0.0,
      'angry': 0.0,
      'tired': 0.0,
      'lonely': 0.0,
    };

    void add(String emotion, double score) {
      emotions[emotion] =
          (emotions[emotion] ?? 0) + score;
    }

    final normalizedText = text.toLowerCase();

    // -------------------------
    // 不安
    // -------------------------
    if (_containsAny(normalizedText, [
      '不安',
      '怖い',
      'こわい',
      '心配',
      '緊張',
      'どうしよう',
      '怒られそう',
      'また怒られる',
    ])) {
      add('anxiety', 0.9);
    }

    // ミス・失敗＋怒られた
    // → 次も同じことになる不安につながりやすい
    if (_containsAny(normalizedText, [
      'ミス',
      '失敗',
      '間違えた',
      'やらかした',
    ])) {
      add('anxiety', 0.55);
      add('sad', 0.30);
    }

    if (_containsAny(normalizedText, [
      '怒られた',
      '注意された',
      '責められた',
      '怒鳴られた',
    ])) {
      add('anxiety', 0.65);
      add('sad', 0.35);
    }

    // -------------------------
    // 悲しい
    // -------------------------
    if (_containsAny(normalizedText, [
      '悲しい',
      'かなしい',
      '泣きたい',
      '泣いた',
      'つらい',
      '傷ついた',
      'ショック',
      '落ち込ん',
    ])) {
      add('sad', 0.9);
    }

    // -------------------------
    // 怒り
    // -------------------------
    if (_containsAny(normalizedText, [
      'イライラ',
      '腹が立つ',
      'むかつく',
      'ムカつく',
      '納得できない',
      '許せない',
    ])) {
      add('angry', 0.9);
    }

    // -------------------------
    // 疲れ
    // -------------------------
    if (_containsAny(normalizedText, [
      '疲れ',
      'しんどい',
      '眠い',
      'だるい',
      '休みたい',
      'くたくた',
    ])) {
      add('tired', 0.9);
    }

    // -------------------------
    // 寂しい
    // -------------------------
    if (_containsAny(normalizedText, [
      '寂しい',
      'さみしい',
      'ひとり',
      '孤独',
      '誰もいない',
    ])) {
      add('lonely', 0.9);
    }

    // -------------------------
    // 安心
    // -------------------------
    if (_containsAny(normalizedText, [
      '安心',
      'ほっとした',
      '落ち着いた',
      '気が楽',
    ])) {
      add('peace', 0.9);
    }

    // -------------------------
    // 嬉しい
    // -------------------------
    if (_containsAny(normalizedText, [
      '嬉しい',
      'うれしい',
      '楽しい',
      '幸せ',
      'よかった',
      '楽しみ',
      'ワクワク',
    ])) {
      add('happy', 0.9);
    }

    // すべて0ならneutralにする
    final hasEmotion =
        emotions.values.any((score) => score > 0);

    if (!hasEmotion) {
      return EmotionResult(
        emotions: emotions,
        strongestEmotion: 'neutral',
      );
    }

    final strongest = emotions.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    return EmotionResult(
      emotions: emotions,
      strongestEmotion: strongest.key,
    );
  }

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(text.contains);
  }
}