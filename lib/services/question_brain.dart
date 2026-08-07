class QuestionBrain {
  String createQuestion({
    required String text,
    required String topic,
    required String emotion,
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

    // 会話が深くなってきた時
    if (conversationDepth >= 5) {
      return choose([
        'ここまで話してみて、今いちばん心に残っていることは何かな？',
        '最初に話していた時と比べて、今の気持ちは少し変わった？',
        'ここまでの話の中で、一番大きかった気持ちはどれかな？',
      ]);
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
      if (_containsAny(
        '$recentText $currentText',
        [
          '返信',
          '既読',
          '未読',
          '連絡',
        ],
      )) {
        return choose([
          '返信そのものより、「相手がどう思っているのか分からないこと」が不安なのかな？',
          '返事を待っている間、どんなことを考えてしまう？',
          '今いちばん知りたいのは、相手の気持ちかな？',
        ]);
      }

      if (_containsAny(
        '$recentText $currentText',
        [
          '喧嘩',
          'けんか',
          '仲直り',
          '別れ',
        ],
      )) {
        return choose([
          '本当はその人との関係を、これからどうしていきたい？',
          '一番伝えたいのに伝えられていないことってある？',
          '今は離れたい気持ちと、つながっていたい気持ち、どっちが近い？',
        ]);
      }

      if (emotion == 'anxiety') {
        return choose([
          'その人とのことで、今いちばん心配していることは何かな？',
          '相手のことで、今一番分からなくて不安なのはどこ？',
          'その不安は、相手の行動と自分の想像なら、どっちが大きい感じがする？',
        ]);
      }

      if (emotion == 'sad' || emotion == 'lonely') {
        return choose([
          '本当はその人に、どんなふうにしてほしかった？',
          'その人とのことで、一番寂しかったのはどんな時？',
          'もし一言だけ伝えられるなら、何を伝えたい？',
        ]);
      }

      return choose([
        'その人とのことで、今一番話したいことは何かな？',
        '今、その人について一番考えていることは何？',
        'その関係で、今いちばん気になっていることは何かな？',
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

  if (_containsAny(text, [
        'うん',
        'そう',
        'そうだね',
        'たしかに',
        '分からない',
        'わからない',
      ]) &&
      conversationDepth >= 3) {
    return true;
  }

  if (conversationDepth >= 7 &&
      (emotion == 'tired' ||
          emotion == 'sad' ||
          emotion == 'lonely')) {
    return true;
  }

  return false;
}
}