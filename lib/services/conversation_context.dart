class ConversationContext {
  String? topic;

  final Set<String> knownFacts = {};

  bool? isStillInContact;
  bool? canTalkNormally;
  bool? wantsToReconnect;
  bool? isWaitingForReply;
  bool? wantsToApologize;
bool? wantsToTalk;
bool? wantsDistance;
bool? wantsAdvice;

// 会話全体で分かったこと
String? currentPerson;
String? currentProblem;

String? workProblemType;

String? difficultTime;
String? difficultSituation;

String? difficultPerson;

String? lastQuestionType;

String? loveMessageContent;

String? loveMessageMethod;

bool? problemIsOngoing;
bool? happenedRepeatedly;
bool? feelsScared;
bool? feelsGuilty;
bool? wantsToAvoid;
bool? wantsToSolve;
bool? wantsSupport;
bool hasReflected = false;

  String? relationshipStatus;

  void reset() {
    topic = null;

    knownFacts.clear();

    hasReflected = false;

    isStillInContact = null;
    canTalkNormally = null;
    wantsToReconnect = null;
    isWaitingForReply = null;

    relationshipStatus = null;

     wantsToApologize = null;
  wantsToTalk = null;
  wantsDistance = null;
  wantsAdvice = null;

  currentPerson = null;
currentProblem = null;

workProblemType = null;

difficultTime = null;
difficultSituation = null;

lastQuestionType = null;

loveMessageContent = null;

loveMessageMethod = null;

problemIsOngoing = null;
happenedRepeatedly = null;
feelsScared = null;
feelsGuilty = null;
wantsToAvoid = null;
wantsToSolve = null;
wantsSupport = null;

  }

  void updateTopic(String newTopic) {
    topic = newTopic;
  }

  void rememberFact(String fact) {
  knownFacts.add(fact);
}

bool knows(String fact) {
  return knownFacts.contains(fact);
}

void forgetFact(String fact) {
  knownFacts.remove(fact);
}

  void updateFromUserMessage(
    String text, {
    String lastLunaMessage = '',
  }) {
    final normalized = text
        .replaceAll('。', '')
        .replaceAll('！', '')
        .replaceAll('!', '')
        .replaceAll('？', '')
        .replaceAll('?', '')
        .trim();



    final isYes = [
      'うん',
      'はい',
      'そう',
      'そうだね',
      'うんうん',
    ].contains(normalized);

    final isNo = [
      'ううん',
      'いいえ',
      '違う',
      'ちがう',
      'いや',
    ].contains(normalized);

    // 恋愛：連絡状況への回答
if (lastQuestionType == 'loveContactStatus') {
  if (isYes) {
    isStillInContact = true;
    rememberFact('love_still_in_contact');
  } else if (isNo) {
    isStillInContact = false;
    rememberFact('love_not_in_contact');
  }

  lastQuestionType = null;
}

// 恋愛：何か伝えたい気持ちがあるか
if (lastQuestionType == 'loveWantsToSaySomething') {
  if (isYes) {
    wantsToTalk = true;
    rememberFact('love_wants_to_say_something');
  } else if (isNo) {
    wantsToTalk = false;
    rememberFact('love_does_not_want_to_say_something');
  }

  lastQuestionType = null;
}

// // 恋愛：何を伝えたいか
if (lastQuestionType == 'loveWhatToSay') {
  loveMessageContent = text.trim();

  if (text.contains('謝りたい') ||
      text.contains('ごめん') ||
      text.contains('謝る')) {
    wantsToApologize = true;
    rememberFact('love_message_apology');
  }

  if (text.contains('好き') ||
      text.contains('大切') ||
      text.contains('まだ気持ちがある')) {
    rememberFact('love_message_love');
  }

  if (text.contains('傷ついた') ||
      text.contains('悲しかった') ||
      text.contains('つらかった') ||
      text.contains('辛かった')) {
    rememberFact('love_message_hurt');
  }

  lastQuestionType = null;
}

// 恋愛：どう伝えたいか
if (lastQuestionType == 'loveMessageMethod') {
  loveMessageMethod = text.trim();

  if (text.contains('LINE') ||
      text.contains('ライン')) {
    rememberFact('love_method_line');
  }

  if (text.contains('直接') ||
      text.contains('会って')) {
    rememberFact('love_method_direct');
  }

  if (text.contains('電話') ||
      text.contains('通話')) {
    rememberFact('love_method_call');
  }

  if (text.contains('ごめん') ||
      text.contains('謝ってから')) {
    rememberFact('love_method_apology_first');
  }

  lastQuestionType = null;
}

// 恋愛：LINEの最初の一言が分からない
if (lastQuestionType == 'loveLineOpening') {
  final normalizedAnswer = text
      .replaceAll('。', '')
      .replaceAll('！', '')
      .replaceAll('!', '')
      .replaceAll('？', '')
      .replaceAll('?', '')
      .trim();

  if (normalizedAnswer.contains('わからない') ||
      normalizedAnswer.contains('分からない') ||
      normalizedAnswer.contains('思いつかない') ||
      normalizedAnswer.contains('なんて送ればいい') ||
      normalizedAnswer.contains('何て送ればいい')) {
    rememberFact('love_needs_line_help');
  }

  lastQuestionType = null;
}

// 恋愛：LINE文章をどう調整したいか
if (lastQuestionType == 'loveLineStyle') {

  // やわらかくしたい
  if (text.contains('やわらか') ||
      text.contains('柔らか') ||
      text.contains('優しく')) {

    forgetFact('love_line_style_short');
    forgetFact('love_line_style_apology');

    rememberFact('love_line_style_soft');
  }

  // 短くしたい
  else if (text.contains('短く') ||
      text.contains('短め') ||
      text.contains('もっと短い')) {

    forgetFact('love_line_style_soft');
    forgetFact('love_line_style_apology');

    rememberFact('love_line_style_short');
  }

  // 謝る気持ちを強くしたい
  else if (text.contains('謝りたい') ||
      text.contains('ちゃんと謝') ||
      text.contains('ごめん')) {

    forgetFact('love_line_style_soft');
    forgetFact('love_line_style_short');

    rememberFact('love_line_style_apology');
  }

  lastQuestionType = null;
}

    // 直前の質問への「うん / ううん」を理解
    if (lastLunaMessage.contains('連絡を取ってる') ||
        lastLunaMessage.contains('連絡は取ってる')) {
      if (isYes) {
        isStillInContact = true;
      } else if (isNo) {
        isStillInContact = false;
      }
    }

    if (lastLunaMessage.contains('普通に話せてる') ||
        lastLunaMessage.contains('話せてる')) {
      if (isYes) {
        canTalkNormally = true;
      } else if (isNo) {
        canTalkNormally = false;
      }
    }

    if (lastLunaMessage.contains('返事を待ってる') ||
        lastLunaMessage.contains('返信を待ってる')) {
      if (isYes) {
        isWaitingForReply = true;
      } else if (isNo) {
        isWaitingForReply = false;
      }
    }

    // ユーザーが直接言った内容も保存
    if (text.contains('仲直りしたい') ||
        text.contains('仲直りはしたい')) {
      wantsToReconnect = true;
    }

    // 謝りたい
if (text.contains('謝りたい') ||
    text.contains('ごめんって言いたい') ||
    text.contains('謝ろうと思ってる')) {
  wantsToApologize = true;
}

// 話したい
if (text.contains('話したい') ||
    text.contains('ちゃんと話したい') ||
    text.contains('話し合いたい')) {
  wantsToTalk = true;
}

// 距離を置きたい
if (text.contains('距離を置きたい') ||
    text.contains('少し離れたい') ||
    text.contains('しばらく離れたい')) {
  wantsDistance = true;
}

// アドバイスがほしい
if (text.contains('相談したい') ||
    text.contains('どうしたらいい') ||
    text.contains('どうすればいい')) {
  wantsAdvice = true;
}

    if (text.contains('連絡取ってない') ||
        text.contains('連絡してない')) {
      isStillInContact = false;
    }

    if (text.contains('連絡取ってる') ||
        text.contains('連絡してる')) {
      isStillInContact = true;
    }
  
// -------------------------
// 会話全体で分かったこと
// -------------------------

// 怖い・不安
if (text.contains('怖い') ||
    text.contains('こわい') ||
    text.contains('不安')) {
  feelsScared = true;
}

// 罪悪感
if (text.contains('申し訳ない') ||
    text.contains('悪かった') ||
    text.contains('自分が悪い') ||
    text.contains('罪悪感')) {
  feelsGuilty = true;
}

// 避けたい・行きたくない
if (text.contains('行きたくない') ||
    text.contains('会いたくない') ||
    text.contains('避けたい') ||
    text.contains('逃げたい')) {
  wantsToAvoid = true;
}

// 解決したい
if (text.contains('解決したい') ||
    text.contains('どうにかしたい') ||
    text.contains('何とかしたい')) {
  wantsToSolve = true;
}

// 支えてほしい・聞いてほしい
if (text.contains('助けてほしい') ||
    text.contains('支えてほしい') ||
    text.contains('聞いてほしい') ||
    text.contains('頼りたい')) {
  wantsSupport = true;
}

// 同じことが何度も起きている
if (text.contains('何回も') ||
    text.contains('何度も') ||
    text.contains('いつも')) {
  happenedRepeatedly = true;
}

// 今も続いている
if (text.contains('まだ続いてる') ||
    text.contains('今も続いてる') ||
    text.contains('ずっと続いてる')) {
  problemIsOngoing = true;
}

if ((text.contains('上司') ||
        text.contains('店長') ||
        text.contains('先輩')) &&
    (text.contains('怖い') ||
        text.contains('こわい') ||
        text.contains('不安'))) {
  rememberFact('work_scared_of_supervisor');
}

// 同じ問題が何度もある
if (text.contains('何度も') ||
    text.contains('何回も') ||
    text.contains('いつも')) {
  rememberFact('repeated_problem');
}

// 仕事に行きたくない
if (text.contains('仕事に行きたくない') ||
    text.contains('会社に行きたくない') ||
    text.contains('職場に行きたくない')) {
  rememberFact('work_wants_to_avoid');
}

// 仕事：人間関係がつらい
if (text.contains('人間関係') &&
    (text.contains('つらい') ||
        text.contains('辛い') ||
        text.contains('しんどい') ||
        text.contains('疲れた'))) {
  workProblemType = 'humanRelations';
  rememberFact('work_human_relations');
}

// -------------------------
// つらくなる時間・場面
// -------------------------

// 朝
if (text == '朝' ||
    text.contains('朝がつらい') ||
    text.contains('朝が辛い') ||
    text.contains('朝になると')) {
  difficultTime = 'morning';
  rememberFact('difficult_morning');
}

// 前日の夜
if (text.contains('前日の夜') ||
    text.contains('前の日の夜') ||
    text.contains('夜になると')) {
  difficultTime = 'nightBefore';
  rememberFact('difficult_night_before');
}

// 上司と話す時
if (text.contains('上司と話す') ||
    text.contains('上司と話す時') ||
    text.contains('上司と関わる時')) {
  difficultSituation = 'talkingToSupervisor';
  rememberFact('difficult_talking_to_supervisor');
}

// 明日の仕事：何が嫌なのか
if (lastQuestionType == 'workTomorrowProblemType') {

  // 職場の人・人間関係
  if (text.contains('職場の人') ||
      text.contains('人間関係') ||
      text.contains('上司') ||
      text.contains('先輩') ||
      text.contains('同僚')) {

    workProblemType = 'humanRelations';
    rememberFact('work_human_relations');
    rememberFact('work_tomorrow_human_relations');
  }

  // 仕事内容・仕事そのもの
  else if (text.contains('仕事そのもの') ||
      text.contains('仕事内容') ||
      text.contains('業務') ||
      text.contains('仕事自体')) {

    workProblemType = 'workItself';
    rememberFact('work_itself');
    rememberFact('work_tomorrow_work_itself');
  }

  lastQuestionType = null;
}

// 仕事：特にしんどい相手は誰か
if (lastQuestionType == 'workDifficultPerson') {

  if (text.contains('上司')) {
    difficultPerson = 'supervisor';
    rememberFact('work_difficult_person_supervisor');
  }

  else if (text.contains('先輩')) {
    difficultPerson = 'senior';
    rememberFact('work_difficult_person_senior');
  }

  else if (text.contains('同僚')) {
    difficultPerson = 'coworker';
    rememberFact('work_difficult_person_coworker');
  }

  lastQuestionType = null;
}

// 仕事：上司との何がつらいか
if (lastQuestionType == 'workSupervisorProblem') {

  // 怒られることがつらい
  if (text.contains('怒られる') ||
      text.contains('怒られた') ||
      text.contains('怒られる時') ||
      text.contains('叱られる') ||
      text.contains('注意される')) {

    difficultSituation = 'beingScoldedBySupervisor';

    rememberFact('work_scared_of_supervisor');
    rememberFact('work_supervisor_scolding');
  }

  // 話し方・接し方がつらい
  else if (text.contains('話し方') ||
      text.contains('言い方') ||
      text.contains('態度') ||
      text.contains('接し方')) {

    difficultSituation = 'supervisorAttitude';

    rememberFact('work_supervisor_attitude');
  }

  lastQuestionType = null;
}

// 仕事：今どうしたいか
if (lastQuestionType == 'workSupportPreference') {
  if (text.contains('話したい') ||
      text.contains('もう少し話したい') ||
      text.contains('聞いてほしい')) {
    wantsSupport = true;
    wantsToSolve = false;

    rememberFact('work_wants_to_talk_more');
    forgetFact('work_wants_to_solve_now');
  }

  else if (text.contains('一緒に考えたい') ||
      text.contains('どうしたらいい') ||
      text.contains('楽になりたい') ||
      text.contains('解決したい')) {
    wantsToSolve = true;
    wantsSupport = false;

    rememberFact('work_wants_to_solve_now');
    forgetFact('work_wants_to_talk_more');
  }

  lastQuestionType = null;
}

}
}