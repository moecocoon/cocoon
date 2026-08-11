class MemoryBrainResult {
  final bool hasRelatedMemory;
  final String memoryText;

  const MemoryBrainResult({
    required this.hasRelatedMemory,
    required this.memoryText,
  });
}

class MemoryBrain {
  MemoryBrainResult recall({
    required String currentTopic,
    required List<String> recentUserMessages,
    String currentMessage = '',
  }) {
    if (recentUserMessages.isEmpty) {
      return const MemoryBrainResult(
        hasRelatedMemory: false,
        memoryText: '',
      );
    }

    final history = List<String>.from(recentUserMessages);

    // 今回の発言がすでに履歴の最後に入っていたら除外
    if (currentMessage.isNotEmpty &&
        history.isNotEmpty &&
        history.last.trim() == currentMessage.trim()) {
      history.removeLast();
    }

    if (history.isEmpty) {
      return const MemoryBrainResult(
        hasRelatedMemory: false,
        memoryText: '',
      );
    }

    // 直近6件だけを見る
    final start =
        history.length > 6 ? history.length - 6 : 0;

    final recentHistory = history.sublist(start);

    // 今の話題と関連する過去発言を探す
    final relatedMessages = recentHistory.where((message) {
      return _matchesTopic(
        message.toLowerCase(),
        currentTopic,
      );
    }).toList();

    if (relatedMessages.isEmpty) {
      return const MemoryBrainResult(
        hasRelatedMemory: false,
        memoryText: '',
      );
    }

    // 一番最近の関連発言を使う
    final latestRelated = relatedMessages.last;

    return MemoryBrainResult(
      hasRelatedMemory: true,
      memoryText: _buildMemoryMessage(
        currentTopic,
        latestRelated,
      ),
    );
  }

  bool _matchesTopic(
    String text,
    String topic,
  ) {
    switch (topic) {
      case 'work':
        return _containsAny(text, [
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
        ]);

      case 'school':
        return _containsAny(text, [
          '学校',
          '授業',
          '先生',
          '勉強',
          'クラス',
          'テスト',
          '受験',
          '部活',
        ]);

      case 'love':
        return _containsAny(text, [
          '彼氏',
          '彼女',
          '好きな人',
          '恋愛',
          '返信',
          '既読',
          '未読',
          'LINE',
          'デート',
          '別れ',
          '仲直り',
          '喧嘩',
          'ケンカ',
        ]);

      case 'family':
        return _containsAny(text, [
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
        ]);

      case 'friend':
        return _containsAny(text, [
          '友達',
          '友だち',
          '友人',
          '親友',
          'クラスメイト',
        ]);

      case 'health':
        return _containsAny(text, [
          '体調',
          '病気',
          '薬',
          '通院',
          '病院',
          '眠れない',
          '痛い',
          '食欲',
        ]);

      default:
        return false;
    }
  }

  String _buildMemoryMessage(
    String topic,
    String previousMessage,
  ) {
    final shortMessage =
        _shortenMessage(previousMessage);

    switch (topic) {
      case 'work':
        return 'さっき「$shortMessage」って話してくれてたね。';

      case 'school':
        return 'さっき「$shortMessage」って話してたこと、まだ気になってるのかな。';

      case 'love':
        return 'さっき「$shortMessage」って話してくれてたね。';

      case 'family':
        return 'さっき話してくれた「$shortMessage」のこと、まだ心に残ってるのかな。';

      case 'friend':
        return 'さっき「$shortMessage」って話してくれてたね。';

      case 'health':
        return 'さっき話してくれた「$shortMessage」のこと、その後どうかな。';

      default:
        return '';
    }
  }

  String _shortenMessage(String message) {
    final cleaned = message
        .replaceAll('\n', ' ')
        .trim();

    if (cleaned.length <= 30) {
      return cleaned;
    }

    return '${cleaned.substring(0, 30)}…';
  }

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(text.contains);
  }
}