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
  }) {
    if (recentUserMessages.isEmpty) {
      return const MemoryBrainResult(
        hasRelatedMemory: false,
        memoryText: '',
      );
    }

    final relatedMessages = recentUserMessages.where((message) {
      return _matchesTopic(
        message.toLowerCase(),
        currentTopic,
      );
    }).toList();

    if (relatedMessages.length >= 2) {
      return MemoryBrainResult(
        hasRelatedMemory: true,
        memoryText: _memoryMessage(currentTopic),
      );
    }

    return const MemoryBrainResult(
      hasRelatedMemory: false,
      memoryText: '',
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
          '出勤',
        ]);

      case 'school':
        return _containsAny(text, [
          '学校',
          '授業',
          '先生',
          '勉強',
          'クラス',
        ]);

      case 'love':
        return _containsAny(text, [
          '彼氏',
          '彼女',
          '好きな人',
          '恋愛',
          '返信',
          '既読',
        ]);

      case 'family':
        return _containsAny(text, [
          '家族',
          '母',
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
          '眠れない',
          '痛い',
        ]);

      default:
        return false;
    }
  }

  String _memoryMessage(String topic) {
    switch (topic) {
      case 'work':
        return '最近も仕事のことを何度か話してくれているね。';

      case 'school':
        return '最近、学校のことが何度か心に残っているみたいだね。';

      case 'love':
        return '最近も、その人とのことを何度か考えていたんだね。';

      case 'family':
        return '家族のことが、少し前から心に残っているみたいだね。';

      case 'friend':
        return '友達とのことを、最近も何度か話してくれているね。';

      case 'health':
        return '体や心の調子について、最近も気になることが続いているんだね。';

      default:
        return '';
    }
  }

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(text.contains);
  }
}