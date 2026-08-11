import 'conversation_context.dart';
import 'conversation_state.dart';

enum ConversationAction {
  ask,
  reflect,
  support,
  help,
  pause,
}

class ConversationFlow {
  ConversationAction decide({
    required String text,
    required String emotion,
    required ConversationContext context,
  }) {
    final state = ConversationState(context);
    final normalized = text.trim();

    // 疲れている時は質問しない
    if (_containsAny(normalized, [
      '疲れた',
      'もう疲れた',
      'しんどい',
      '何もしたくない',
      '今日は休みたい',
      '考えたくない',
    ])) {
      return ConversationAction.pause;
    }

    // 具体的に助けを求めている
    if (context.wantsAdvice == true ||
        context.knows('love_needs_line_help')) {
      return ConversationAction.help;
    }

   // 十分情報が集まっていたら一度整理して返す
if (state.hasEnoughContextToReflect &&
    context.hasReflected == false) {
  return ConversationAction.reflect;
}

// 新しい重要情報が増えたら、もう一度まとめてもいい
if (context.knows('work_supervisor_scolding') &&
    !context.knows('work_supervisor_scolding_reflected')) {
  return ConversationAction.reflect;
}

// 人前で怒られた・恥ずかしかったという
// 新しい重要情報が出たら、一度受け止める
if ((context.knows('work_supervisor_public_scolding') ||
        context.knows('work_supervisor_scolding_embarrassing')) &&
    !context.knows('work_supervisor_public_scolding_reflected')) {
  return ConversationAction.reflect;
}

    // 短い相づちなら無理に質問しない
    if (_isShortResponse(normalized)) {
      return ConversationAction.support;
    }

    // 会話が重い感情の時も、時々質問せず受け止める
    if (emotion == 'sad' ||
        emotion == 'lonely' ||
        emotion == 'tired') {
      if (normalized.length <= 12) {
        return ConversationAction.support;
      }
    }

    return ConversationAction.ask;
  }

  bool _isShortResponse(String text) {
    return [
      'うん',
      'うんうん',
      'そう',
      'そうだね',
      'たしかに',
      '確かに',
      'わからない',
      '分からない',
      'そっか',
    ].contains(text);
  }

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(text.contains);
  }
}