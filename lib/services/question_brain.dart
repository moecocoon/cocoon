import 'conversation_state.dart';
import 'conversation_context.dart';
class QuestionBrain {
  String createQuestion({
    required String text,
    required String topic,
    required String emotion,
    required ConversationContext conversationContext,
    List<String> recentUserMessages = const [],
    List<String> recentLunaMessages = const [],
  }) {
    final recentText = recentUserMessages
        .reversed
        .take(4)
        .toList()
        .reversed
        .join(' ')
        .toLowerCase();

    final currentText = text.toLowerCase();


    final conversationDepth = recentUserMessages.length;
    final state = ConversationState(
  conversationContext,
);

// -------------------------
// 直前の質問への「うん / ううん」を理解
// -------------------------

final lastLunaMessage = recentLunaMessages.isNotEmpty
    ? recentLunaMessages.last
    : '';

final isYesReply = [
  'うん',
  'はい',
  'そう',
  'そうだね',
  'うんうん',
].contains(currentText.trim());

final isNoReply = [
  'ううん',
  'いいえ',
  '違う',
  'ちがう',
  'いや',
].contains(currentText.trim());

// -------------------------
// 短い回答を直前の質問とつなげる
// -------------------------

// 「人間関係」
if ((currentText.trim() == '人間関係' ||
        currentText.trim() == '職場の人間関係') &&
    lastLunaMessage.contains('人間関係')) {
  return 'そっか、仕事そのものより職場の人間関係の方がしんどいんだね。';
}

// 「仕事内容」
if ((currentText.trim() == '仕事内容' ||
        currentText.trim() == '仕事そのもの') &&
    (lastLunaMessage.contains('仕事内容') ||
        lastLunaMessage.contains('仕事そのもの'))) {
  return 'そっか、職場の人間関係より仕事内容そのものがつらいんだね。';
}

// 「上司」
if ((currentText.trim() == '上司' ||
        currentText.trim() == '店長' ||
        currentText.trim() == '先輩') &&
    lastLunaMessage.contains('どんな人')) {
  return 'そっか、その人との関わりが一番しんどいんだね。';
}

// 「朝」
if (currentText.trim() == '朝' &&
    lastLunaMessage.contains('朝')) {
  return '朝が特につらいんだね。';
}

// 「前日の夜」
if ((currentText.trim() == '前日の夜' ||
        currentText.trim() == '前の日の夜' ||
        currentText.trim() == '夜') &&
    lastLunaMessage.contains('夜')) {
  return '前日の夜からもう気持ちが重くなるんだね。';
}

// 「怒られること」
if ((currentText.trim() == '怒られること' ||
        currentText.trim() == '怒られるのが怖い') &&
    lastLunaMessage.contains('避けたい')) {
  return 'そっか、今いちばん避けたいのは、また怒られることなんだね。';
}

// 「ミス」
if ((currentText.trim() == 'ミス' ||
        currentText.trim() == '失敗') &&
    lastLunaMessage.contains('どっち')) {
  return 'そっか、今はミスしたことの方が強く引っかかってるんだね。';
}

// 「相手の言い方」
if ((currentText.trim() == '言い方' ||
        currentText.trim() == '相手の言い方') &&
    lastLunaMessage.contains('言い方')) {
  return 'そっか、何を言われるかより、言われ方そのものが怖いんだね。';
}

// 朝について聞かれた後の「うん」
if (isYesReply &&
    (lastLunaMessage.contains('起きた時から') ||
        lastLunaMessage.contains('起きた瞬間') ||
        lastLunaMessage.contains('朝が特につらい'))) {
  return 'そっか、起きた時からもう仕事のことが頭に浮かんで、'
      '気持ちが重くなるんだね。';
}

// 仕事へ行く前から緊張する？ → うん
if (isYesReply &&
    lastLunaMessage.contains('仕事に行く前から')) {
  return 'そっか、仕事に着く前からもう緊張してしまうんだね。';
}

// 人間関係の方が大きい？ → うん
if (isYesReply &&
    lastLunaMessage.contains('職場の人間関係')) {
  return 'そっか、仕事そのものより、人間関係のしんどさが大きいんだね。';
}


if (state.hasEnoughContextToReflect &&
    conversationContext.hasReflected == false) {
  conversationContext.hasReflected = true;

  if (topic == 'work') {
    final parts = <String>[];

    if (conversationContext.knows('work_scared_of_supervisor')) {
      parts.add('上司に怒られることが怖くて');
    } else if (state.knowsUserIsScared) {
      parts.add('仕事のことで不安や怖さがあって');
    }

    if (conversationContext.workProblemType == 'humanRelations') {
  parts.add('職場の人間関係でもかなり疲れていて');
}

if (conversationContext.difficultTime == 'morning') {
  parts.add('特に朝になるとつらくなって');
}

if (conversationContext.difficultTime == 'nightBefore') {
  parts.add('特に前日の夜になるとつらくなって');
}

if (conversationContext.difficultSituation ==
    'talkingToSupervisor') {
  parts.add('上司と関わる時には特に緊張して');
}

    if (state.knowsProblemIsRepeated) {
      parts.add('それが何度も続いていて');
    }

    if (state.knowsUserWantsToAvoid) {
      parts.add('仕事に行きたくないくらいしんどくなっているんだね');
    }

    if (parts.isNotEmpty) {
      return '${parts.join('、')}。';
    }
  }
}

    final shouldPauseQuestion =
    _shouldPauseQuestion(
  text: currentText,
  emotion: emotion,
  conversationDepth: conversationDepth,
);

if (shouldPauseQuestion) {
  return '';
}

    String choose(List<String> candidates) {
      for (final candidate in candidates) {
        final alreadyUsed = recentLunaMessages.any(
          (message) => message.contains(candidate),
        );

        if (!alreadyUsed) {
          return candidate;
        }
      }

      return 'ここまで話してみて、今いちばん心に残っていることは何かな？';
    }

    // -------------------------
// 直前の質問への短い回答を優先
// -------------------------

if (currentText == '朝' &&
    conversationContext.difficultTime == 'morning') {
  return choose([
    '朝なんだね。起きた時からもう仕事のことを考えてしまう感じ？',
    '朝が特につらいんだね。仕事に向かう準備をしている時から気持ちが重くなる？',
    '朝になると、どんなことを一番考えてしまう？',
  ]);
}

if ((currentText == '前日の夜' ||
        currentText == '前の日の夜') &&
    conversationContext.difficultTime == 'nightBefore') {
  return choose([
    '前日の夜からつらくなるんだね。次の日の仕事を考えると気持ちが重くなる感じ？',
    '夜になると、明日の仕事のどんなことが一番浮かんでくる？',
    '前日の夜が特につらいんだね。その時はどんなことを考えてる？',
  ]);
}

// 解決モード完了後に不安が戻ってきた
if (conversationContext.solutionFlow.isComplete &&
    conversationContext.knows('work_plan_memo_ready') &&
    _containsAny(
      currentText,
      [
        '明日怖い',
        '明日が怖い',
        'やっぱり怖い',
        'でも怖い',
        '不安',
        'まだ不安',
      ],
    )) {

  return 'うん。明日のことを考えると、やっぱり怖くなるよね。\n\n'
      '上司にまた怒られるかもしれないって思うと、'
      '「メモしてから話す」って決めても、'
      '不安が全部なくなるわけじゃないよね。\n\n'
      '明日は不安をゼロにしようとしなくて大丈夫。'
      'まずは決めた通り、確認したいことを1〜2個メモしてから話す。'
      'それだけを目標にしてみよう。';
}
    

    if (conversationDepth >= 3) {
      if (emotion == 'anxiety') {
        return choose([
          'その不安の奥には、どんな気持ちがありそう？',
          '一番怖いことが起きるとしたら、何が浮かぶ？',
          'その不安って、いつ頃から強くなってきた感じがする？',
        ]);
      }

      if (emotion == 'sad' || emotion == 'lonely') {
        return choose([
          '本当は、どうしてほしかった気持ちが一番大きいかな？',
          'その中で、一番寂しかったのはどんなところ？',
          'もし分かってもらえるなら、何を一番分かってほしい？',
        ]);
      }

      if (emotion == 'angry') {
        return choose([
          '怒りの奥に、悲しさや悔しさも混ざっていそうかな？',
          '本当はどうしてほしかった？',
          '一番納得できなかったのは、どんなところ？',
        ]);
      }
    }


    // -------------------------
    // 仕事
    // -------------------------
    if (topic == 'work') {
      // -------------------------
// 解決モード完了
// -------------------------
if (conversationContext.solutionFlow.isComplete &&
    conversationContext.knows('work_plan_memo_ready') &&
    !conversationContext.knows('work_plan_completed_message')) {

  conversationContext.rememberFact(
    'work_plan_completed_message',
  );

  return 'じゃあ明日は、まず確認したいことを1〜2個だけメモしてから'
      '上司に話してみよう。\n\n'
      '全部を完璧にやろうとしなくて大丈夫。'
      '明日は「メモしてから話す」だけできたら十分だよ。';
}

      // -------------------------
// 実行プラン：確認事項をメモする
// -------------------------
if (conversationContext.knows('work_action_prepare_memo')) {
  conversationContext.lastQuestionType =
      'workMemoPlan';

  return 'じゃあ明日は、上司に話しかける前に'
      '確認したいことを1〜2個だけメモしておこうか。\n\n'
      'たとえば、'
      '\n・確認したい内容'
      '\n・自分がすでにやったこと'
      '\nだけ書いておくと、話す時に少し整理しやすいよ。\n\n'
      '明日メモしてから話してみる、でいけそう？';
}

    // -------------------------
// 仕事：もう少し話したい
// -------------------------
if (conversationContext.knows('work_wants_to_talk_more')) {
  return choose([
    'うん、もう少し聞かせて。上司とのことで、まだ話しておきたいことはある？',
    'ここでは急いで答えを出さなくて大丈夫。今いちばん話したいことから聞かせて。',
    'もう少し話したいんだね。最近いちばん心に残っている出来事って何かな？',
  ]);
}

// -------------------------
// 解決モード：上司との関わりを減らしたい
// -------------------------
if (conversationContext.knows(
    'work_solution_supervisor_contact')) {

conversationContext.lastQuestionType = 'workActionChoice';

  return 'じゃあ、上司との関わりの負担を少し減らす方向で考えてみよう。\n\n'
      'たとえば、\n'
      '・確認したいことを先にメモして、話す時間を短くする\n'
      '・できる範囲で一対一になりにくいタイミングを選ぶ\n'
      '・必要なことだけ簡潔に伝える\n\n'
      'この中で、明日なら一番やりやすそうなのはどれかな？';
}

// -------------------------
// 解決モード：誰かに相談したい
// -------------------------
if (conversationContext.knows(
    'work_solution_consult')) {

  return 'じゃあ、職場で一人で抱え込まない方法を考えてみよう。\n\n'
      '相談できそうなのは、別の上司、先輩、同僚みたいな人かな。\n'
      '「最近ちょっと上司とのやり取りがしんどくて」と、'
      '全部説明せずに少しだけ話すところからでもいいよ。\n\n'
      '職場で話しやすそうな人はいる？';
}

// -------------------------
// 解決モード：怒られた後の気持ちを切り替えたい
// -------------------------
if (conversationContext.knows(
    'work_solution_emotional_recovery')) {

  return 'じゃあ、怒られた後に気持ちを引きずりすぎない方法を一緒に考えよう。\n\n'
      'まずは「怒られたこと」と「自分自身の価値」を分けて考えるのが一つだよ。\n'
      'その場を離れたあとに、短く深呼吸したり、'
      '起きたことを一度メモに出したりするのもあり。\n\n'
      '怒られた後って、どんなことを一番考え続けてしまう？';
}

// -------------------------
// 仕事：一緒に考えたい
// -------------------------
if (conversationContext.knows('work_wants_to_solve_now')) {

  // 上司に怒られることがつらい場合
  if (conversationContext.knows('work_supervisor_scolding')) {
    conversationContext.lastQuestionType =
        'workSolutionChoice';

    return 'じゃあ、明日を少しでも楽にする方法を一緒に考えよう。\n\n'
        'たとえば、\n'
        '・上司と関わる時の負担を少し減らす\n'
        '・職場で相談できる人を考える\n'
        '・怒られた時に気持ちを引きずりすぎない方法を考える\n\n'
        'この中だと、今いちばん一緒に考えたいのはどれかな？';
  }

  // その他の仕事の悩み
  conversationContext.lastQuestionType =
      'workSolutionChoice';

  return 'じゃあ一緒に考えよう。\n\n'
      '今の状況を少し楽にするために、'
      '「仕事そのもの」「職場の人間関係」「休み方」の中だと、'
      'どこから考えてみたい？';
}

// -------------------------
// 人前で怒られた・恥ずかしかった
// → まず質問せず受け止める
// -------------------------
if ((conversationContext.knows('work_supervisor_public_scolding') ||
        conversationContext.knows('work_supervisor_scolding_embarrassing')) &&
    !conversationContext.knows(
        'work_supervisor_public_scolding_reflected')) {

  conversationContext.rememberFact(
    'work_supervisor_public_scolding_reflected',
  );

  return 'みんなの前で強く怒られたことが、かなり心に残ってるんだね。'
      '\n\nその場で恥ずかしさもあって、しんどかったんだと思う。';
}

      // 上司に怒られることがつらいと分かったら一度まとめる
if (conversationContext.knows('work_supervisor_scolding')) {
  if (!conversationContext.knows(
      'work_supervisor_scolding_reflected')) {

    conversationContext.rememberFact(
      'work_supervisor_scolding_reflected',
    );

    return '明日の仕事を考えるだけでも気が重くて、'
        '特に職場の人間関係、その中でも上司に怒られる時がつらいんだね。'
        '\n\n何度もそういうことがあると、'
        '上司と関わるだけでも身構えてしまいそうだね。';
  }
}

// -------------------------
// 上司に怒られる話を一度まとめた後
// → ユーザーがどうしたいか確認する
// -------------------------
if (conversationContext.knows(
        'work_supervisor_scolding_reflected') &&
    !conversationContext.knows(
        'work_supervisor_next_step_asked')) {

  final normalized = currentText
      .replaceAll('。', '')
      .replaceAll('！', '')
      .replaceAll('!', '')
      .trim();

  final isShortYes = [
    'うん',
    'うんうん',
    'そう',
    'そうだね',
    'はい',
  ].contains(normalized);

  if (isShortYes) {
    conversationContext.rememberFact(
      'work_supervisor_next_step_asked',
    );

    conversationContext.lastQuestionType =
        'workSupportPreference';

    return 'うん。ここまで話してくれてありがとう。\n\n'
        '今は、もう少し話したい？'
        'それとも、どうしたら少し楽になれそうか一緒に考えてみたい？';
  }
}

      // 仕事：しんどい相手が上司だと分かっている
if (conversationContext.knows('work_difficult_person_supervisor')) {
  conversationContext.lastQuestionType = 'workSupervisorProblem';

  return choose([
    '上司との関わりが一番しんどいんだね。どんな時が特につらい？',
    '上司のことなんだね。怒られることが怖い？それとも話し方や接し方がしんどい感じ？',
    '明日その上司と関わると思うと気が重いんだね。何が一番不安？',
  ]);
}

     // -------------------------
// 明日の仕事：職場の人が嫌
// -------------------------
if (conversationContext.knows('work_tomorrow_human_relations')) {
  conversationContext.lastQuestionType = 'workDifficultPerson';

  return choose([
    '職場の人のことなんだね。特に誰との関わりが一番しんどい？',
    '人間関係の方が大きいんだね。上司、先輩、同僚とか、特にしんどい相手はいる？',
    '明日その人と関わることを考えると、気が重くなる感じなのかな？',
  ]);
} 

   // -------------------------
// 仕事：明日の仕事が嫌
// -------------------------
if (_containsAny(
  currentText,
  [
    '明日の仕事も嫌',
    '明日の仕事が嫌',
    '明日仕事行きたくない',
    '明日の仕事行きたくない',
    '明日が嫌',
  ],
)) {
conversationContext.lastQuestionType = 'workTomorrowProblemType';

  return choose([
    '明日のことを考えるだけでも気が重いんだね。特に嫌なのは、仕事そのもの？それとも職場の人のこと？',
    '明日を考えるとしんどくなるんだね。いちばん引っかかってるのは、人間関係？仕事内容？',
    '明日の仕事を思うと嫌になるんだね。何が一番「行きたくない」って気持ちにさせてる？',
  ]);
}   
    
// 仕事：行きたくない・避けたい
if (state.knowsUserWantsToAvoid) {
  conversationContext.lastQuestionType = 'workProblemType';

  return '仕事そのものがつらい感じ？それとも職場の人間関係の方が大きい？';
}

if (conversationContext.knows('work_scared_of_supervisor')) {
  return choose([
    '上司に怒られることが続いてる中で、今いちばんしんどいのはどんなところ？',
    '仕事に行く前から、そのことを考えて緊張する感じはある？',
    '今の状況で、一番変わってほしいのはどんなところ？',
  ]);
}  

    // 仕事：何度も同じことが起きている
if (state.knowsProblemIsRepeated) {
  return choose([
    '何度も続いてるんだね。今いちばん変わってほしいのはどんなところ？',
    '同じことが続く中で、一番しんどいのはどんな時？',
    '今の状況が少し楽になるとしたら、何が変わってほしい？',
  ]);
}

// 仕事：怖さがある
if (state.knowsUserIsScared) {
  return choose([
    'その怖さって、相手の言い方が怖い感じ？それとも次に何をされるか分からない感じ？',
    '一番緊張するのは、どんな場面？',
    'その人と関わる時、体まで緊張する感じはある？',
  ]);
}


// 仕事：解決したい
if (state.knowsUserWantsToSolve) {
  return choose([
    'まず一番変えたいことって何かな？',
    '今の状況を変えるなら、どこからなら動けそう？',
    '自分だけで変えられそうなことと、誰かに相談した方がよさそうなこと、どっちが多そう？',
  ]);
}

// 仕事：支えてほしい・聞いてほしい
if (state.knowsUserWantsSupport) {
  return choose([
    '今は解決策より、まず話を聞いてほしい感じ？',
    '誰かに分かってもらえるだけでも少し違いそう？',
    '今いちばん誰かに分かってほしいことって何かな？',
  ]);
}


      if (_containsAny(
        '$recentText $currentText',
        [
          '上司',
          '店長',
          '先輩',
          '同僚',
          '怒られ',
          '怖い人',
        ],
      )) {
        if (_containsAny(
          currentText,
          [
            '怒られた',
            '怒られる',
            '注意された',
            '責められた',
          ],
        )) {
          return choose([
            'その出来事の中で、一番心に残っているのはどんなところ？',
            '怒られたことと、ミスしたことなら、どっちの方が今も気になってる？',
            'その時、自分ではどんな気持ちだった？',
          ]);
        }

        return choose([
          'その人とのことで、前にも似たようなことがあったのかな？',
          'その人と関わる時、どんな瞬間が一番緊張する？',
          'その人のことで、今いちばん怖いのは何かな？',
        ]);
      }

      if (_containsAny(
        '$recentText $currentText',
        [
          'ミス',
          '失敗',
          '間違え',
          'やらかした',
        ],
      )) {
        return choose([
          'ミスそのものより、「また同じことが起きるかも」という不安の方が大きい？',
          'その時、自分のことをどんなふうに考えてしまった？',
          'その出来事のあと、仕事に行く気持ちは変わった？',
        ]);
      }

      if (emotion == 'anxiety') {
        return choose([
          '仕事の中で、今いちばん不安なのは人間関係？仕事内容？それとも明日のこと？',
          '明日の仕事を考えた時、一番最初に浮かぶ心配って何かな？',
          '仕事の中で、今いちばん避けたいことは何？',
        ]);
      }

      if (emotion == 'tired') {
        return choose([
          '最近、仕事で一番エネルギーを使っているのはどんなこと？',
          '仕事が終わったあと、どんな疲れ方をすることが多い？',
          '今いちばん休みたいと思うのは、どんな部分かな？',
        ]);
      }

      return choose([
        '仕事のことで、今いちばん心に残っていることは何かな？',
        '最近、仕事で気になっていることってある？',
        '仕事について、今一番話したいことは何かな？',
      ]);
    }

    // -------------------------
    // 恋愛
    // -------------------------
    if (topic == 'love') {

      // -------------------------
// 恋愛：解決モード完了
// -------------------------
if (conversationContext.solutionFlow.isComplete &&
    conversationContext.knows('love_plan_opening_ready') &&
    !conversationContext.knows('love_plan_completed_message')) {

  conversationContext.rememberFact(
    'love_plan_completed_message',
  );

  return 'じゃあ、まずはその一言から送ってみよう。\n\n'
      '最初から全部の気持ちを伝えなくても大丈夫。'
      'まずは会話を始めることだけを目標にしてみよう。';
}

    // -------------------------
// 恋愛：LINEの最初の一言を作る
// -------------------------
if (conversationContext.knows('love_line_action_opening')) {
  conversationContext.lastQuestionType =
      'loveOpeningPlan';

  return 'じゃあ、最初の一言を一緒に作ろう。\n\n'
      'たとえば、\n'
      '「急にごめんね。少し話したくてLINEしたよ。」\n'
      'くらいの短さでも大丈夫。\n\n'
      'この感じなら送れそう？';
}  

      // -------------------------
// 恋愛：LINEする方向を選んだ
// -------------------------
if (conversationContext.knows('love_solution_line')) {
  conversationContext.lastQuestionType =
      'loveLineActionChoice';

  return 'じゃあ、LINEする方向で一緒に考えよう。\n\n'
      'たとえば、\n'
      '・送るタイミングを決める\n'
      '・最初の一言を考える\n'
      '・何を伝えるか整理する\n\n'
      'この中だと、どれから考えたい？';
}

      // -------------------------
// 恋愛：一緒に考えたい
// -------------------------
if (conversationContext.knows('love_wants_to_solve_now')) {
  conversationContext.lastQuestionType =
      'loveSolutionChoice';

  return 'じゃあ、一緒に整理してみよう。\n\n'
      'たとえば、\n'
      '・今は少し待つ\n'
      '・自分からLINEしてみる\n'
      '・まず自分の気持ちを整理する\n\n'
      'この中だと、今いちばん一緒に考えたいのはどれかな？';
}



      // 仲直りしたいことはすでに分かっていて、
// 連絡も取れている場合
if (conversationContext.wantsToReconnect == true &&
    conversationContext.isStillInContact == true &&
    conversationContext.wantsToTalk != true) {
  conversationContext.lastQuestionType =
      'loveWantsToSaySomething';

  return '今、自分から何か伝えてみたい気持ちはある？';
}

// 伝えたい内容：謝りたい
if (conversationContext.knows('love_message_apology')) {
  return choose([
    'どんなことを一番謝りたいと思ってる？',
    '謝るなら、まず何を伝えたい？',
    '自分の中で「ここはちゃんと謝りたい」って思ってるのはどこかな？',
  ]);
}

// LINE文章：やわらかくしたい
if (conversationContext.knows('love_line_style_soft')) {
  return 'もう少しやわらかくするなら、'
      '\n\n「この前はいろいろごめんね。'
      'もしよかったら、少し話せたらいいなって思ってる。」'
      '\n\nくらいでもいいかも。'
      '\n相手に返事を急がせない感じにすると、送りやすくなると思うよ。';
}

// LINE文章：短くしたい
if (conversationContext.knows('love_line_style_short')) {
  return '短くするなら、'
      '\n\n「この前はごめんね。少し話せたら嬉しい。」'
      '\n\nくらいでも気持ちは伝えられるよ。';
}

// LINE文章：ちゃんと謝りたい
if (conversationContext.knows('love_line_style_apology')) {
  return 'ちゃんと謝りたい気持ちを入れるなら、'
      '\n\n「この前はごめんね。'
      '自分の言い方もよくなかったと思ってる。'
      'ちゃんと謝りたいし、もしよかったら少し話したい。」'
      '\n\nみたいに、謝りたいことと話したいことを分けて伝えるのもよさそうだよ。';
}

// LINEでどう送ればいいか分からない
if (conversationContext.knows('love_needs_line_help')) {
  conversationContext.lastQuestionType = 'loveLineStyle';

  return 'じゃあ、一緒に最初の一言を考えよう。'
      '\n\nたとえば、'
      '\n「この前はごめんね。ちゃんと話したくてLINEしたよ。」'
      '\nみたいに、最初は短くても大丈夫だよ。'
      '\n\nこの文章、もう少しやわらかくしたい？'
      'それとも短くしたい？';
}

// 伝え方：LINE
if (conversationContext.knows('love_method_line')) {
  conversationContext.lastQuestionType = 'loveLineOpening';

  return choose([
    'LINEで伝えたいんだね。最初の一言は、どんな感じなら送りやすそう？',
    'LINEで伝えるなら、最初はどんなふうに話しかけたい？',
  ]);
}

// 伝え方：直接
if (conversationContext.knows('love_method_direct')) {
  return choose([
    '直接伝えたいんだね。会った時、最初に何から話したい？',
    '直接なら、相手の顔を見て伝えたいことは何かな？',
    '会って話すとしたら、落ち着いて話せそうな場所はありそう？',
  ]);
}

// 伝え方：電話
if (conversationContext.knows('love_method_call')) {
  return choose([
    '電話で伝えたいんだね。最初にどんなふうに切り出したい？',
    '電話なら、まず謝ってから気持ちを伝えたい感じ？',
    '声で伝えるなら、一番言葉にしたいことは何かな？',
  ]);
}

// 伝えたい内容：まだ好き
if (conversationContext.knows('love_message_love')) {
  conversationContext.lastQuestionType = 'loveMessageMethod';

  return choose([
    'その「好き」って気持ちを、どんなふうに伝えたい？',
    'まだ好きだって伝えるなら、どんな言葉が一番近いかな？',
  ]);
}

// 伝えたい内容：傷ついた
if (conversationContext.knows('love_message_hurt')) {
  return choose([
    'どんなところが一番傷ついた？',
    '相手に分かってほしいのは、どんな気持ちかな？',
    '傷ついたことを伝えるなら、どんな言い方なら伝えやすそう？',
  ]);
}

   // 謝りたい気持ちがある
if (conversationContext.wantsToApologize == true) {
  return choose([
    'どんなことを一番謝りたいと思ってる？',
    '相手に伝えるなら、まず何から話したい？',
    '謝るとしたら、今いちばん伝えたいことは何かな？',
  ]);
}

// ちゃんと話したい気持ちがある
if (conversationContext.wantsToTalk == true) {
  conversationContext.lastQuestionType = 'loveWhatToSay';

  return '相手に一番伝えたいことって何かな？';
}

// 少し距離を置きたい
if (conversationContext.wantsDistance == true) {
  return choose([
    '少し距離を置きたいと思ったのは、どんなところが一番しんどかった？',
    '今は関係を終わらせたいというより、少し休みたい感じに近い？',
    '距離を置くなら、どんな距離感が一番楽そう？',
  ]);
}   

  // 仲直りしたい気持ちがはっきり出た時
  // 仲直りしたい気持ちがはっきり出た時
if (_containsAny(
  currentText,
  [
    '仲直りしたい',
    '仲直りはしたい',
    '仲直りしたくて',
    '仲直りできたら',
  ],
)) {
  // すでに「連絡を取っている」と分かっている
if (conversationContext.isStillInContact == true) {
  conversationContext.lastQuestionType = 'loveWantsToSaySomething';

  return '今、自分から何か伝えてみたい気持ちはある？';
}

  // すでに「連絡を取っていない」と分かっている
  if (conversationContext.isStillInContact == false) {
    return choose([
      '自分から連絡してみたい気持ちはある？',
      'もし連絡するとしたら、どんなことを伝えたい？',
      '今は連絡するのが少し怖い感じ？',
    ]);
  }

  // まだ連絡状況が分からない場合だけ聞く
conversationContext.lastQuestionType = 'loveContactStatus';

return '今はまだ連絡を取ってる？';
}

  // 喧嘩・言い合い
  if (_containsAny(
    '$recentText $currentText',
    [
      '喧嘩',
      'けんか',
      'ケンカ',
      '言い合い',
      '揉めた',
      'もめた',
    ],
  )) {
    return choose([
      '何がきっかけで言い合いになったの？',
      'その時、相手はどんな感じだった？',
      '今はまだ連絡を取ってる？',
    ]);
  }

  // 返信・既読・連絡
  if (_containsAny(
    '$recentText $currentText',
    [
      '返信',
      '既読',
      '未読',
      '連絡',
      'LINE',
    ],
  )) {
    return choose([
      '最後にやり取りしたのはいつ頃？',
      '今は返事を待ってる感じ？',
      '相手からの連絡が止まったのは、何かきっかけがあった？',
    ]);
  }

  // 別れ・距離を置く話
  if (_containsAny(
    '$recentText $currentText',
    [
      '別れ',
      '別れたい',
      '別れた',
      '距離を置く',
      '距離置く',
    ],
  )) {
    return choose([
      '今は相手と話せる状態なの？',
      'その話になったきっかけって何だったの？',
      '今いちばん引っかかってるのは、どんなところ？',
    ]);
  }

  // 不安
  if (emotion == 'anxiety') {
    return choose([
      '何が一番気になってる？',
      'その不安って、何かきっかけがあったの？',
      '今は相手とは普通に話せてる？',
    ]);
  }

  // 悲しい・寂しい
  if (emotion == 'sad' || emotion == 'lonely') {
    return choose([
      '何が一番寂しかった？',
      'その時、相手とはどんな感じだったの？',
      '今もそのことが引っかかってる？',
    ]);
  }

  // 恋愛の普通の会話
  return choose([
    'どんなことがあったの？',
    '今は相手とどんな感じ？',
    'そのこと、もう少し聞いてもいい？',
  ]);
}

    // -------------------------
    // 学校
    // -------------------------
    if (topic == 'school') {
      if (emotion == 'anxiety') {
        return choose([
          '学校の中で、今いちばん不安なのは何？',
          '学校のことを考えた時、一番気が重くなるのはどんなこと？',
          '明日の学校で、いちばん心配なのは何かな？',
        ]);
      }

      if (emotion == 'tired') {
        return choose([
          '最近、学校で一番疲れたのはどんな時間だった？',
          '学校にいる中で、どんな時に一番ぐったりする？',
          '今いちばん休みたいと思うのはどんな部分？',
        ]);
      }

      return choose([
        '学校では、どんなことが一番心に残っている？',
        '最近、学校で気になっていることってある？',
        '学校のことで、今一番話したいことは何かな？',
      ]);
    }

    // -------------------------
    // 家族
    // -------------------------
    if (topic == 'family') {
      if (emotion == 'angry') {
        return choose([
          'その出来事で、本当は家族にどうしてほしかった？',
          '一番納得できなかったのは、どんなところ？',
          'その時、言いたかったけど言えなかったことってある？',
        ]);
      }

      if (emotion == 'sad' || emotion == 'lonely') {
        return choose([
          '「分かってほしかった」としたら、どんな気持ちを一番分かってほしかった？',
          '家族とのことで、一番寂しかったのはどんな時？',
          '本当はどんなふうに接してほしかった？',
        ]);
      }

      return choose([
        '家族とのことで、今一番心に引っかかっていることは何かな？',
        '家族について、今一番話したいことって何？',
        '最近、家族とのことで気になっていることはある？',
      ]);
    }

    // -------------------------
    // 友達
    // -------------------------
    if (topic == 'friend') {
      if (emotion == 'anxiety') {
        return choose([
          '友達とのことで、今いちばん気になっていることは何？',
          '相手にどう思われているかが、一番不安なのかな？',
          'その友達とのことで、今一番知りたいことは何？',
        ]);
      }

      if (emotion == 'sad' || emotion == 'lonely') {
        return choose([
          'その友達に、本当はどんなふうにしてほしかった？',
          '一番寂しかったのは、どんな出来事だった？',
          '今、その友達に一番伝えたいことは何かな？',
        ]);
      }

      return choose([
        '友達との間で、どんなことがあったの？',
        'その友達について、今一番気になっていることは何？',
        '最近、その友達とのことで心に残っていることはある？',
      ]);
    }

    // -------------------------
    // general
    // -------------------------
    if (emotion == 'anxiety') {
      return choose([
        'その不安の中で、いちばん頭から離れないことは何かな？',
        '今いちばん怖いと思っていることは何？',
        'その不安って、どんな時に一番大きくなる？',
      ]);
    }

    if (emotion == 'sad') {
      return choose([
        'その出来事の中で、一番つらかったところはどこだった？',
        '今も一番心に残っているのはどんな部分？',
        'その時、本当はどうしてほしかった？',
      ]);
    }

    if (emotion == 'tired') {
      return choose([
        '最近、「もう疲れたな」と感じるのはどんな時？',
        '今いちばん休みたいと思っているのは何からかな？',
        '最近、何に一番エネルギーを使ってる感じがする？',
      ]);
    }

    if (emotion == 'lonely') {
      return choose([
        '誰かに分かってほしかったことがあるのかな？',
        '今、一番誰かに聞いてほしいことって何？',
        'どんな時に一番ひとりだなって感じる？',
      ]);
    }

    if (emotion == 'happy') {
      return choose([
        'その嬉しいこと、もう少し聞かせてくれる？',
        '一番嬉しかったのはどんなところ？',
        'その時、どんな気持ちになった？',
      ]);
    }

    return choose([
      'その話の中で、今いちばん気になっているところはどこかな？',
      'もう少しだけ、そのことを聞かせてくれる？',
      '今、一番話したいことは何かな？',
    ]);
  }

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(text.contains);
  }
bool _shouldPauseQuestion({
  required String text,
  required String emotion,
  required int conversationDepth,
}) {
  final normalized = text
      .replaceAll('。', '')
      .replaceAll('！', '')
      .replaceAll('!', '')
      .replaceAll('？', '')
      .replaceAll('?', '')
      .trim();

  // 疲れている時は質問を重ねない
  if (_containsAny(text, [
    'もう疲れた',
    '疲れた',
    'しんどい',
    '何もしたくない',
    '考えたくない',
    '今日は休みたい',
  ])) {
    return true;
  }

  // 短い相づちの時だけ質問を止める
final shortResponses = [
  'たしかに',
  '確かに',
  'そうかも',
];

  if (shortResponses.contains(normalized) &&
      conversationDepth >= 2) {
    return true;
  }

  // 「分からない」だけの短い返事なら深掘りしない
  if ((normalized == '分からない' ||
          normalized == 'わからない' ||
          normalized == 'わかんない') &&
      conversationDepth >= 2) {
    return true;
  }

  // 会話が長くなっていて、疲れ・悲しさ・寂しさが強い時は休む
  if (conversationDepth >= 7 &&
      (emotion == 'tired' ||
          emotion == 'sad' ||
          emotion == 'lonely')) {
    return true;
  }

  return false;
}

}
