import 'mood_brain.dart';
import 'emotion_brain.dart';
import 'topic_brain.dart';
import 'question_brain.dart';
import 'memory_brain.dart';

class LunaBrainResult {
  final String emotion;
  final String topic;
  final String firstReply;
  final String nextQuestion;

  const LunaBrainResult({
    required this.emotion,
    required this.topic,
    required this.firstReply,
    required this.nextQuestion,
  });
}

class LunaBrain {
  final EmotionBrain emotionBrain = EmotionBrain();
  final TopicBrain topicBrain = TopicBrain();
  final QuestionBrain questionBrain = QuestionBrain();
  final MemoryBrain memoryBrain = MemoryBrain();
  final MoodBrain moodBrain = MoodBrain();

  LunaBrainResult think(
  String message, {
  List<String> recentUserMessages = const [],
  List<String> recentLunaMessages = const [],
  Map<String, double>? moodEmotionPercents,
}) {
    // 感情分析
    final emotionResult = emotionBrain.analyze(message);

    // 話題分析
    final topicResult = topicBrain.analyze(message);

    // 過去の会話確認
    final memoryResult = memoryBrain.recall(
      currentTopic: topicResult.topic,
      recentUserMessages: recentUserMessages,
    );

    final moodResult = moodBrain.analyze(
  moodEmotionPercents,
);

    // 最初の返答
    final firstReply = _firstReply(
      emotionResult.strongestEmotion,
    );

    // MemoryBrainの内容
    final memoryText = memoryResult.hasRelatedMemory
        ? memoryResult.memoryText
        : '';

      final moodText = moodResult.hasMood
    ? moodResult.moodText
    : '';  

    // 次の質問
    final question = questionBrain.createQuestion(
      text: message,
      topic: topicResult.topic,
      emotion: emotionResult.strongestEmotion,
      recentUserMessages: recentUserMessages,
      recentLunaMessages: recentLunaMessages,
    );

    return LunaBrainResult(
      emotion: emotionResult.strongestEmotion,
      topic: topicResult.topic,
     firstReply: [
  firstReply,
  if (memoryText.isNotEmpty) memoryText,
  if (moodText.isNotEmpty) moodText,
].join('\n\n'),
      nextQuestion: question,
    );
  }

  String _firstReply(String emotion) {
    switch (emotion) {
      case 'anxiety':
        return '話してくれてありがとう。\n少し不安が大きくなっているみたいだね。';

      case 'sad':
        return 'その気持ちを話してくれてありがとう。';

      case 'happy':
        return 'その気持ちを聞けて、ルナも嬉しいよ。';

      case 'angry':
        return 'イライラする気持ちがあるんだね。\nここではそのまま話して大丈夫だよ。';

      case 'tired':
        return '少し疲れがたまっているみたいだね。\nここでは力を抜いていいよ。';

      case 'lonely':
        return 'さみしい気持ちを話してくれてありがとう。\nここでは一人じゃないよ。';

      case 'peace':
        return '少し安心できる気持ちがあるんだね。';

      default:
        return '話してくれてありがとう。';
    }
  }
}