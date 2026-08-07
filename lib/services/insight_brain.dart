class InsightBrain {
  String createInsight({
    required String topic,
    required String emotion,
    required List<String> recentMessages,
  }) {
    // 同じ話題が何回出たか数える
    final count = recentMessages
        .where((m) => m.contains(_topicWord(topic)))
        .length;

    if (count >= 3) {
      switch (topic) {
        case "work":
          return "🌱 今日のルナの気づき\n\n最近は仕事のことを何度か話してくれているね。\n仕事そのものより、『安心して働ける場所』を探している気持ちが少し見えてきたよ。";

        case "love":
          return "🌱 今日のルナの気づき\n\n恋愛のことを何度か話してくれているね。\n本当に欲しいのは返信じゃなくて、『安心できるつながり』なのかもしれないね。";

        case "family":
          return "🌱 今日のルナの気づき\n\n家族の話が続いているね。\n分かってもらえない気持ちが心に残っているように感じたよ。";
      }
    }

    switch (emotion) {
      case "anxiety":
        return "🌱 今日のルナの気づき\n\n今日は少し不安さんが大きかったみたい。\n話してくれてありがとう。";

      case "sad":
        return "🌱 今日のルナの気づき\n\n今日は悲しい気持ちを話してくれてありがとう。\n少し心が軽くなっていたら嬉しいな。";

      case "happy":
        return "🌱 今日のルナの気づき\n\n嬉しい気持ちも話してくれてありがとう。\nその気持ちを大切にしていこうね。";

      default:
        return "🌱 今日のルナの気づき\n\n今日も話してくれてありがとう。";
    }
  }

  String _topicWord(String topic) {
    switch (topic) {
      case "work":
        return "仕事";

      case "love":
        return "彼";

      case "family":
        return "家族";

      case "school":
        return "学校";

      default:
        return "";
    }
  }
}