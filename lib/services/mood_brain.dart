class MoodBrainResult {
  final bool hasMood;
  final String moodText;
  final String strongestMood;

  const MoodBrainResult({
    required this.hasMood,
    required this.moodText,
    required this.strongestMood,
  });
}

class MoodBrain {
  MoodBrainResult analyze(
    Map<String, double>? emotionPercents,
  ) {
    if (emotionPercents == null ||
        emotionPercents.isEmpty) {
      return const MoodBrainResult(
        hasMood: false,
        moodText: '',
        strongestMood: '',
      );
    }

    final strongest = emotionPercents.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    final normalizedValue = strongest.value > 1
        ? strongest.value / 100
        : strongest.value;

    final percent = (normalizedValue * 100)
        .clamp(0, 100)
        .round();

    return MoodBrainResult(
      hasMood: true,
      strongestMood: strongest.key,
      moodText: _createMoodText(
        strongest.key,
        percent,
      ),
    );
  }

  String _createMoodText(
    String emotion,
    int percent,
  ) {
    final emotionName = _emotionName(emotion);

    if (percent >= 70) {
      return '今日の気分記録では、'
          '$emotionNameがかなり大きかったみたいだね。';
    }

    if (percent >= 40) {
      return '今日の気分記録では、'
          '$emotionNameが少し大きかったみたいだね。';
    }

    return '今日の気分記録には、'
        '$emotionNameもいたみたいだね。';
  }

  String _emotionName(String key) {
    if (key.contains('不安') || key.contains('😰')) {
      return '不安さん';
    }

    if (key.contains('安心') || key.contains('😌')) {
      return '安心さん';
    }

    if (key.contains('悲しい') ||
        key.contains('さみしい') ||
        key.contains('寂しい') ||
        key.contains('😢')) {
      return 'さみしいさん';
    }

    if (key.contains('疲れ') ||
        key.contains('おつかれ') ||
        key.contains('😴')) {
      return 'おつかれさん';
    }

    if (key.contains('怒り') ||
        key.contains('イライラ') ||
        key.contains('😡')) {
      return 'イライラさん';
    }

    if (key.contains('嬉しい') ||
        key.contains('うれしい') ||
        key.contains('😊')) {
      return 'うれしいさん';
    }

    return key;
  }
}