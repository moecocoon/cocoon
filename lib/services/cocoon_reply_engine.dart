import 'luna_brain.dart';

class CocoonReplyEngine {
  const CocoonReplyEngine();

 String compose({
  required LunaBrainResult brainResult,
  required String legacyReply,
  required String userText,
  List<String> recentUserMessages = const [],
  List<String> recentLunaMessages = const [],
}) {
  final intro = brainResult.firstReply.trim();
  final oldReply = legacyReply.trim();
  final question = brainResult.nextQuestion.trim();

  final acknowledgement = _createAcknowledgement(
    userText,
    recentUserMessages,
  );

final shortenedLegacy =
    _shortenLegacyReply(
  oldReply,
  allowQuestion: question.isNotEmpty,
);

  final parts = <String>[];

  // ① 前の会話とつながる受け止めが作れた場合は、
  // Brainの一般的な導入よりこちらを優先
  if (acknowledgement.isNotEmpty) {
    parts.add(acknowledgement);
  } else if (intro.isNotEmpty) {
    parts.add(intro);
  }

  // ② 昔の返答は、
  // 「今の受け止め」と違う情報を持っている場合だけ使う
  if (shortenedLegacy.isNotEmpty &&
      !_shouldSkipLegacy(
        intro: parts.join(' '),
        legacy: shortenedLegacy,
      )) {
    parts.add(shortenedLegacy);
  }

  // ③ すでに返答の中に質問がなければ、
  // QuestionBrainの質問を1つだけ追加
  final replySoFar = parts.join('\n\n');

  if (question.isNotEmpty &&
      !_containsQuestion(replySoFar)) {
    parts.add(question);
  }

  if (question.isEmpty) {
  final pauseReply = _createPauseReply(
  userText,
  recentLunaMessages: recentLunaMessages,
);

  if (pauseReply.isNotEmpty &&
      !_isNearlySame(
        parts.join(' '),
        pauseReply,
      )) {
    parts.add(pauseReply);
  }
}

  return parts.join('\n\n');
}

  String _shortenLegacyReply(
  String text, {
  required bool allowQuestion,
}) {
    if (text.isEmpty) {
      return '';
    }

final blocks = text
    .split('\n')
    .map((part) => part.trim())
    .where((part) => part.isNotEmpty)
    .where((part) => !_isClosingPhrase(part))
    .where(
      (part) =>
          allowQuestion ||
          !_containsQuestion(part),
    )
    .toList();

    if (blocks.isEmpty) {
      return '';
    }

    // 質問がある行を優先して残す
    final questionIndex = blocks.indexWhere(
      _containsQuestion,
    );

    if (questionIndex >= 0) {
      if (questionIndex == 0) {
        return blocks[0];
      }

      return '${blocks[0]}\n${blocks[questionIndex]}';
    }

    // 質問がなければ最初の1文だけ
    return blocks.first;
  }

  bool _shouldSkipLegacy({
    required String intro,
    required String legacy,
  }) {
    if (intro.isEmpty || legacy.isEmpty) {
      return false;
    }

    final normalizedIntro =
        _normalize(intro);

    final normalizedLegacy =
        _normalize(legacy);

    // かなり似ている場合
    if (normalizedIntro.contains(normalizedLegacy) ||
        normalizedLegacy.contains(normalizedIntro)) {
      return true;
    }

    // 同じような「受け止め」の言葉が
    // 両方にある場合はlegacyを省く
    final empathyWords = [
      '話してくれてありがとう',
      '不安',
      'つらい',
      '疲れ',
      '悲しい',
      '寂しい',
      'さみしい',
      'イライラ',
      '安心',
      '嬉しい',
      'うれしい',
    ];

    var overlapCount = 0;

    for (final word in empathyWords) {
      if (intro.contains(word) &&
          legacy.contains(word)) {
        overlapCount++;
      }
    }

    return overlapCount >= 2;
  }

  bool _containsQuestion(String text) {
    return text.contains('？') ||
        text.contains('?');
  }

  String _normalize(String text) {
    return text
        .replaceAll('\n', '')
        .replaceAll(' ', '')
        .replaceAll('。', '')
        .replaceAll('、', '')
        .replaceAll('！', '')
        .replaceAll('!', '')
        .trim();
  }
bool _isClosingPhrase(String text) {
  final closingPhrases = [
    '話してくれてありがとう',
    '今日はここまで話してくれてありがとう',
    'またいつでも話してね',
    'また話しに来てね',
    '今日はゆっくり休んでね',
  ];

  return closingPhrases.any(
    (phrase) => text.contains(phrase),
  );
}

String _createAcknowledgement(
  String text,
  List<String> recentUserMessages,
) {
  final lower = text.toLowerCase();

  if (lower.contains('怒られた') ||
      lower.contains('注意された') ||
      lower.contains('責められた')) {
    return 'そっか、その時のことがまだ心に残ってるんだね。';
  }

  if (lower.contains('ミス') ||
      lower.contains('失敗') ||
      lower.contains('間違えた')) {
    return 'その出来事を思い出すと、また同じことにならないか気になってしまうんだね。';
  }

  if (lower.contains('返信') ||
      lower.contains('既読') ||
      lower.contains('未読')) {
    return '相手の反応が分からない時間って、いろいろ考えてしまうよね。';
  }

  if (lower.contains('疲れた') ||
      lower.contains('しんどい')) {
    return 'かなり頑張ってきた感じがするね。';
  }

  if (lower.contains('寂しい') ||
      lower.contains('さみしい')) {
    return 'その寂しさを、ずっと抱えていたのかな。';
  }

  return '';
}

bool _containsAny(
  String text,
  List<String> keywords,
) {
  return keywords.any(text.contains);
}
String _createPauseReply(
  String text, {
  List<String> recentLunaMessages = const [],
}) {
  final lower = text.toLowerCase();

  final normalized = lower
      .replaceAll('。', '')
      .replaceAll('！', '')
      .replaceAll('!', '')
      .replaceAll('？', '')
      .replaceAll('?', '')
      .trim();

  final lastLuna = recentLunaMessages.isNotEmpty
      ? recentLunaMessages.last
      : '';

  if (lower.contains('疲れた') ||
      lower.contains('しんどい') ||
      lower.contains('今日は休みたい') ||
      lower.contains('何もしたくない') ||
      lower.contains('考えたくない')) {
    return '今は無理に整理しなくても大丈夫。'
        '少しここで力を抜いていこう。';
  }

  // 「うん」系
  if ([
    'うん',
    'うんうん',
    'そう',
    'そうだね',
    'はい',
  ].contains(normalized)) {

    if (lastLuna.contains('話せてる') ||
        lastLuna.contains('普通に話せてる')) {
      return 'そっか、話すことはできてるんだね。';
    }

    if (lastLuna.contains('返事を待ってる') ||
        lastLuna.contains('返信を待ってる')) {
      return 'そっか、今は返事を待ってるんだね。';
    }

  }

  // 「違う」系
  if ([
    'ううん',
    'いや',
    '違う',
    'ちがう',
    'いいえ',
  ].contains(normalized)) {
    if (lastLuna.contains('連絡を取ってる') ||
        lastLuna.contains('連絡は取ってる')) {
      return 'そっか、今は連絡を取ってないんだね。';
    }

    return 'そっか。';
  }

  if (lower.contains('わからない') ||
      lower.contains('分からない')) {
    return '今すぐ言葉にできなくてもいいよ。'
        '気持ちがまとまるまで、ゆっくりで大丈夫。';
  }

  return '';
}

bool _isNearlySame(
  String first,
  String second,
) {
  if (first.isEmpty || second.isEmpty) {
    return false;
  }

  final normalizedFirst = _normalize(first);
  final normalizedSecond = _normalize(second);

  return normalizedFirst.contains(normalizedSecond) ||
      normalizedSecond.contains(normalizedFirst);
}

}