import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CocoonApp());
}

class CocoonApp extends StatelessWidget {
  const CocoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COCOON',
      theme: ThemeData(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

class MoodRecord {
  final String weather;
  final Map<String, double> emotionPercents;
  final String memo;

  MoodRecord({
    required this.weather,
    required this.emotionPercents,
    required this.memo,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class EmotionInfo {
  final String id;
  final String key;
  final String name;
  final String imagePath;
  final String guideText;

  const EmotionInfo({
    required this.id,
    required this.key,
    required this.name,
    required this.imagePath,
    required this.guideText,
  });
}

const List<EmotionInfo> emotionInfos = [
  EmotionInfo(
    id: 'anxiety',
    key: '😰 不安',
    name: '不安さん',
    imagePath: 'assets/images/emotion_anxiety.png',
    guideText: '不安さんが今日は少し落ち着かないみたい。',
  ),
  EmotionInfo(
    id: 'peace',
    key: '🌿 安心',
    name: '安心さん',
    imagePath: 'assets/images/emotion_peace.png',
    guideText: '安心さんが今日はふわっと見守ってくれてるみたい。',
  ),
  EmotionInfo(
    id: 'lonely',
    key: '🫂 さみしい',
    name: 'さみしいさん',
    imagePath: 'assets/images/emotion_lonely.png',
    guideText: 'さみしいさんが今日は少し心細そうにしてるみたい。',
  ),
  EmotionInfo(
    id: 'tired',
    key: '😴 疲れ',
    name: 'おつかれさん',
    imagePath: 'assets/images/emotion_tired.png',
    guideText: 'おつかれさんが今日はゆっくり休みたがってるみたい。',
  ),
  EmotionInfo(
    id: 'angry',
    key: '😡 イライラ',
    name: 'イライラさん',
    imagePath: 'assets/images/emotion_angry.png',
    guideText: 'イライラさんが今日はもやもやしてるみたい。',
  ),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
MoodRecord? latestMood;
String? petImagePath;
@override
void initState() {
  super.initState();
  loadPetImage();
}

Future<void> loadPetImage() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    petImagePath = prefs.getString('petImagePath');
  });
}

Future<void> updatePetImage(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('petImagePath', path);

  setState(() {
    petImagePath = path;
  });
}


  final List<ChatMessage> chatMessages = [
    ChatMessage(
      text: 'ここでは、ゆっくり気持ちを整理できるよ。',
      isUser: false,
    ),
  ];

  void saveMood(MoodRecord mood) {
    setState(() {
      latestMood = mood;
    });
  }

  void goToChatWithEmotion(EmotionInfo emotion) {
    setState(() {
      selectedIndex = 2;

      chatMessages.add(
        ChatMessage(
          text: '${emotion.name}の話を聞いてほしい',
          isUser: true,
        ),
      );

      chatMessages.add(
        ChatMessage(
          text: '${emotion.guideText} 何が一番近い気持ち？',
          isUser: false,
        ),
      );
    });
  }

  void goToBreathingGuide() {
    setState(() {
      selectedIndex = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
  latestMood: latestMood,
  petImagePath: petImagePath,
),

      MoodRecordScreen(onSave: saveMood),
      ChatScreen(messages: chatMessages),
      KokoroHirobaScreen(
        latestMood: latestMood,
        onListen: goToChatWithEmotion,
        onBreathing: goToBreathingGuide,
      ),
      MyPageScreen(
  petImagePath: petImagePath,
  onPetImageChanged: updatePetImage,
),

      const BreathingGuideScreen(),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: selectedIndex == 5
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF8E7BBE),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'ホーム',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.spa),
                  label: '気分記録',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: 'COCOON',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.park),
                  label: '心の広場',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'マイページ',
                ),
              ],
            ),
    );
  }
}
class HomeScreen extends StatelessWidget {
  final MoodRecord? latestMood;
  final String? petImagePath;

  const HomeScreen({
    super.key,
    this.latestMood,
    this.petImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final lunaHeight = (size.height * 0.42).clamp(250.0, 460.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          SafeArea(
            child: SizedBox.expand(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 500 ? 24 : size.width * 0.18,
                ),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.04),
                    const Text(
                      'COCOON',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Color(0xFF8E7BBE),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'おかえり。今日もここにいていいよ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6D6478),
                      ),
                    ),
                    SizedBox(height: size.height * 0.025),
                    SizedBox(
  height: lunaHeight,
  width: double.infinity,
  child: petImagePath != null
      ? Image.file(
          File(petImagePath!),
          fit: BoxFit.contain,
        )
      : Image.asset(
          'assets/images/luna.png',
          fit: BoxFit.contain,
        ),
),
                    const SizedBox(height: 16),
                    if (latestMood != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '今日の記録',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6F5F8F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              latestMood!.weather,
                              style: const TextStyle(fontSize: 34),
                            ),
                            const SizedBox(height: 8),
                            ...latestMood!.emotionPercents.entries.map(
                              (entry) => Text(
                                '${entry.key}：${entry.value.round()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6F5F8F),
                                ),
                              ),
                            ),
                            if (latestMood!.memo.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                latestMood!.memo,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6D6478),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodRecordScreen extends StatefulWidget {
  final Function(MoodRecord) onSave;

  const MoodRecordScreen({
    super.key,
    required this.onSave,
  });

  @override
  State<MoodRecordScreen> createState() => _MoodRecordScreenState();
}

class _MoodRecordScreenState extends State<MoodRecordScreen> {
  String? selectedWeather;
  final Map<String, double> emotionPercents = {};
  final TextEditingController memoController = TextEditingController();

  final List<String> weathers = [
    '☀️',
    '🌤️',
    '☁️',
    '🌧️',
    '🌪️',
    '🌙',
  ];

  final List<String> emotions = [
    '😰 不安',
    '😢 悲しい',
    '😡 イライラ',
    '😴 疲れ',
    '🫂 さみしい',
    '🌿 安心',
    '🥹 がんばった',
  ];

  void toggleEmotion(String emotion) {
    setState(() {
      if (emotionPercents.containsKey(emotion)) {
        emotionPercents.remove(emotion);
      } else {
        emotionPercents[emotion] = 50;
      }
    });
  }

  void saveRecord() {
    if (selectedWeather == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日の心の天気を選んでね')),
      );
      return;
    }

    if (emotionPercents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('近い感情を1つ以上選んでね')),
      );
      return;
    }

    widget.onSave(
      MoodRecord(
        weather: selectedWeather!,
        emotionPercents: Map.from(emotionPercents),
        memo: memoController.text,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('記録できたよ🌿')),
    );
  }
   @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F3FA),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '気分記録',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E7BBE),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '今の気持ちを、ここにそっと置いていこう',
                style: TextStyle(color: Color(0xFF6D6478)),
              ),
              const SizedBox(height: 30),

              const Text(
                '今日の心の天気は？',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: weathers.map((weather) {
                  final selected = selectedWeather == weather;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedWeather = weather;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE7DCF8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        weather,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              const Text(
                '近い感情は？',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: emotions.map((emotion) {
                  final selected = emotionPercents.containsKey(emotion);

                  return ChoiceChip(
                    label: Text(emotion),
                    selected: selected,
                    onSelected: (_) => toggleEmotion(emotion),
                    selectedColor: const Color(0xFFE7DCF8),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Column(
                children: emotionPercents.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}：${entry.value.round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6F5F8F),
                          ),
                        ),
                        Slider(
                          value: entry.value,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          activeColor: const Color(0xFF8E7BBE),
                          onChanged: (value) {
                            setState(() {
                              emotionPercents[entry.key] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              const Text(
                'ひとことメモ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: memoController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '今日のひとこと',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E7BBE),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('記録する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final List<ChatMessage> messages;

  const ChatScreen({
    super.key,
    required this.messages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController chatController = TextEditingController();
  final Random random = Random();

  String pick(List<String> replies) {
    return replies[random.nextInt(replies.length)];
  }

  void sendMessage() {
    final text = chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.messages.add(ChatMessage(text: text, isUser: true));
      widget.messages.add(
        ChatMessage(
          text: makeCocoonReply(text),
          isUser: false,
        ),
      );
      chatController.clear();
    });
  }

  String makeCocoonReply(String userText) {
    final text = userText.toLowerCase();

    // 恋愛：返信が遅い
    if (text.contains('返信遅い') ||
        text.contains('返信が遅い') ||
        text.contains('返事遅い') ||
        text.contains('返事が遅い')) {
      return pick([
        '返信が遅いと、不安さんが一気に大きくなりやすいよね。\n今わかっている事実は「まだ返事が来ていない」ことだけかも。',
        '待ってる時間って、実際よりずっと長く感じるよね。\n一番怖い想像は「冷めたかも」ってこと？',
        '返信の遅さって、相手の気持ち全部に見えてしまう時あるよね。\nでもまずは事実と想像を分けよう。',
        '今はスマホを見るたびに心が揺れてる感じかな。\n返事が来たら安心できそう？それとも別の不安もある？',
        '返事を待つ時間って、自分だけ置いていかれた感じになることあるよね。',
      ]);
    }

    // 恋愛：既読無視
    if (text.contains('既読無視') ||
        text.contains('既読スルー') ||
        text.contains('既読ついた')) {
      return pick([
        '既読がついてるのに返事がないと、心がざわざわするよね。\n「見たのに返さない」って感じると傷つきやすい。',
        '既読無視って、相手の気持ちを悪い方に想像しやすいよね。\nでも今はまだ理由までは確定してないよ。',
        '既読がついた瞬間から、返事を待つ時間が重くなるよね。',
        '「読んだなら返してほしい」って思うの自然だよ。\n今は寂しい？不安？イライラ？',
        '既読のまま止まると、自分が大事にされてない気がしてしまうことあるよね。',
      ]);
    }

    // 恋愛：未読無視
    if (text.contains('未読無視') ||
        text.contains('未読スルー') ||
        text.contains('未読')) {
      return pick([
        '未読のままだと、何が起きてるのかわからなくて不安になるよね。',
        '未読って、見えない分だけ想像が広がりやすいよね。\n今一番浮かぶ悪い想像は何？',
        'まだ読んでいないだけかもしれないけど、待ってる側は苦しいよね。',
        '未読の時間が長いと、自分だけ取り残された感じになることあるよね。',
        '未読が続くと「避けられてるのかな」って思いやすいよね。\nでも決めつける前に状況を見よう。',
      ]);
    }

    // 恋愛：冷たい・そっけない
    if (text.contains('冷たい') ||
        text.contains('そっけない') ||
        text.contains('素っ気ない') ||
        text.contains('態度が変')) {
      return pick([
        '相手が冷たく感じると、不安さんがすぐ反応するよね。\nいつからそう感じた？',
        '前と違う態度に見えると、「何かあったのかな」って考えちゃうよね。',
        '冷たくされたように感じると、心がぎゅっとなるよね。',
        'その冷たさは、言葉？返信の雰囲気？会った時の態度？',
        '相手の変化に気づけるくらい、大切に見ているんだと思う。',
        '今は「嫌われたかも」って不安が強い？それとも「大事にされてない」って寂しさ？',
      ]);
    }

    // 恋愛：別れ不安
    if (text.contains('別れたい') ||
        text.contains('別れる') ||
        text.contains('振られる') ||
        text.contains('終わり') ||
        text.contains('終わった')) {
      return pick([
        '別れの不安が出てくると、心が一気に苦しくなるよね。\nでも今はまだ結論を急がなくて大丈夫。',
        '「終わるかも」って思ったきっかけは何だった？',
        '別れが怖い時って、相手の小さな変化が全部サインに見えることあるよね。',
        '今は不安が未来を先取りしてるのかもしれない。\n実際に言われたことと、想像していることを分けよう。',
        '失うかもって思うと、いつもの自分でいられなくなるよね。',
      ]);
    }
    // 恋愛：会えない
    if (text.contains('会えない') ||
        text.contains('会いたい')) {
      return pick([
        '会えない時間って、さみしいさんが大きくなりやすいよね。',
        '今ほしいのは「会うこと」？それとも「安心できる言葉」？',
        '会いたいのに会えない時って、自分だけ我慢してる感じになることあるよね。',
        '距離があると、不安が想像でどんどん育ちやすいよね。',
        '会えない時間に何を考えちゃうことが多い？',
      ]);
    }

    // 恋愛：喧嘩
    if (text.contains('喧嘩') ||
        text.contains('ケンカ') ||
        text.contains('言い合い')) {
      return pick([
        '喧嘩のあとって、言いすぎたことも相手の反応も気になるよね。',
        '本当は何をわかってほしかったのか、一緒に見てみよう。',
        '怒りの奥に、寂しさや傷つきが隠れてることもあるよ。',
        '仲直りしたい気持ちと、まだモヤモヤする気持ち、両方ある？',
        '喧嘩って「大切だからこそ」起きることもあるよね。',
      ]);
    }

    // 恋愛：嫉妬
    if (text.contains('嫉妬') ||
        text.contains('やきもち') ||
        text.contains('他の女') ||
        text.contains('他の男')) {
      return pick([
        '嫉妬って苦しいよね。\nでもそれだけ大切に思ってる気持ちでもあるよ。',
        '不安なのは「取られるかも」って感じ？',
        '嫉妬すると、自分でも嫌になることあるよね。',
        '本当は安心したい気持ちが強いのかもしれないね。',
        '何が引き金になった？',
      ]);
    }

    // 恋愛：依存
    if (text.contains('依存') ||
        text.contains('離れられない') ||
        text.contains('頭から離れない')) {
      return pick([
        'その人のことが頭から離れない感じかな。',
        '安心をその人だけに預けてる感じがあると苦しくなりやすいよね。',
        '依存っていうより、今すごく不安定なだけかもしれないよ。',
        'その人がいないと何が一番苦しい？',
        '「好き」と「安心したい」が混ざってる感じある？',
      ]);
    }

    // 恋愛：好きかわからない
    if (text.contains('好きかわからない') ||
        text.contains('気持ちがわからない')) {
      return pick([
        '好きかわからなくなる時って、心が疲れてることもあるよ。',
        '離れたいのか、ただ疲れてるのか、どっちに近い？',
        '不安で気持ちが見えなくなってる可能性もあるよ。',
        '安心したいのか、自由になりたいのか、一緒に見てみよう。',
      ]);
    }

    // SNS比較
    if (text.contains('sns') ||
        text.contains('インスタ') ||
        text.contains('x') ||
        text.contains('比較')) {
      return pick([
        'SNSって、人のキラキラだけ見えやすい場所だよね。',
        '比べて苦しくなるの自然だよ。',
        '自分に足りないものばかり見えてしまう時あるよね。',
        '本当は何がほしくて苦しくなってるんだろう？',
      ]);
    }

    // 友達
    if (text.contains('友達') ||
        text.contains('親友') ||
        text.contains('人間関係')) {
      return pick([
        '友達とのことって、小さい違和感でも心に残るよね。',
        '悲しかった？それともモヤモヤした？',
        'その関係を続けたい気持ちと、苦しい気持ちどっちが強い？',
        '人間関係って正解がなくて難しいよね。',
      ]);
    }

    // 家族
    if (text.contains('家族') ||
        text.contains('母') ||
        text.contains('父') ||
        text.contains('親')) {
      return pick([
        '家族のことって距離が近いぶん、気持ちが揺れやすいよね。',
        'わかってほしい気持ちが強い感じかな。',
        '怒り？悲しさ？疲れ？どれが近い？',
        '簡単に割り切れないからこそ苦しいよね。',
      ]);
    }

        // 将来・お金
    if (text.contains('将来') ||
        text.contains('未来') ||
        text.contains('お金') ||
        text.contains('生活')) {
      return pick([
        '先が見えない感じって、心が落ち着かなくなるよね。',
        '一番心配なのは生活？仕事？人間関係？',
        '将来の不安って、正体がぼんやりしてると大きくなりやすいよ。',
        '未来を考えるほど苦しくなる時あるよね。',
      ]);
    }

    // 仕事・学校
    if (text.contains('仕事') ||
        text.contains('会社') ||
        text.contains('学校') ||
        text.contains('勉強')) {
      return pick([
        '毎日頑張ってるからこそ、しんどくなる時あるよね。',
        '疲れ？プレッシャー？人間関係？どれが近い？',
        '逃げ場がない感じになる時あるよね。',
        'ちゃんと頑張ってるから苦しいのかも。',
      ]);
    }

    // 不安
    if (text.contains('不安') ||
        text.contains('怖い') ||
        text.contains('心配')) {
      return pick([
        '不安さんがかなり大きくなってる感じかな。',
        '頭の中で何度も考えちゃう？',
        '胸がザワザワする感じある？',
        '不安って、正体が見えないと大きくなりやすいよね。',
      ]);
    }

    // 孤独
    if (text.contains('ひとり') ||
        text.contains('一人') ||
        text.contains('孤独')) {
      return pick([
        'ひとりで抱えると、気持ちってすごく重くなるよね。',
        '今は誰かにいてほしい感じ？',
        'ただ話を聞いてほしい感じかな？',
        '孤独って静かだけど重たいよね。',
      ]);
    }

    // 眠れない
    if (text.contains('眠れない') ||
        text.contains('寝れない') ||
        text.contains('夜')) {
      return pick([
        '夜って気持ちが何倍にも大きく見えやすいよね。',
        '頭が止まらない感じ？',
        '体が落ち着かない感じ？',
        '不安さんが元気になる時間だよね。',
      ]);
    }

    // イライラ
    if (text.contains('イライラ') ||
        text.contains('ムカつく') ||
        text.contains('腹立つ')) {
      return pick([
        'イライラの奥に、本当は悲しさや傷つきがあることもあるよ。',
        '何が一番引っかかった？',
        '怒りって大事なものが傷ついたサインのこともあるよ。',
      ]);
    }

    // 自己否定
    if (text.contains('自分が嫌') ||
        text.contains('自分嫌い') ||
        text.contains('ダメ')) {
      return pick([
        '今、自分にかなり厳しくなってる感じがあるよ。',
        '何がそう思わせてる？',
        'その言葉、自分に強く向けてるね。',
        '本当にそうなのか、一緒に見てみよう。',
      ]);
    }

    return pick([
      '話してくれてありがとう。\nもう少し詳しく聞かせてくれる？',
      'ちゃんと受け取ったよ。\nどんな気持ちが一番近い？',
      'ここでゆっくり整理していこう。\nもう少し聞かせて。',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F3FA),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF1E8F8),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COCOON',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E7BBE),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '気持ちを急がず、やさしく整理しよう。',
                    style: TextStyle(color: Color(0xFF6D6478)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: widget.messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(message: widget.messages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              color: Colors.white.withOpacity(0.92),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: chatController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: '今の気持ちを書いてね',
                        filled: true,
                        fillColor: const Color(0xFFF8F3FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onFieldSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send),
                    color: const Color(0xFF8E7BBE),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF8E7BBE) : Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF5F566B),
          ),
        ),
      ),
    );
  }
}

class KokoroHirobaScreen extends StatefulWidget {
  final MoodRecord? latestMood;
  final Function(EmotionInfo) onListen;
  final VoidCallback onBreathing;

  const KokoroHirobaScreen({
    super.key,
    this.latestMood,
    required this.onListen,
    required this.onBreathing,
  });

  @override
  State<KokoroHirobaScreen> createState() => _KokoroHirobaScreenState();
}

class _KokoroHirobaScreenState extends State<KokoroHirobaScreen> {
  String selectedEmotionId = 'anxiety';
  String guideMessage = 'おかえり。今日はどんな気分？';

  EmotionInfo get selectedEmotion {
    return emotionInfos.firstWhere(
      (emotion) => emotion.id == selectedEmotionId,
      orElse: () => emotionInfos.first,
    );
  }

  EmotionInfo get mainEmotion {
    final mood = widget.latestMood;

    if (mood == null || mood.emotionPercents.isEmpty) {
      return selectedEmotion;
    }

    EmotionInfo strongest = emotionInfos.first;
    double highest = -1;

    for (final emotion in emotionInfos) {
      final percent = mood.emotionPercents[emotion.key] ?? 0;
      if (percent > highest) {
        highest = percent;
        strongest = emotion;
      }
    }

    return strongest;
  }

  double getEmotionSize(String emotionKey, double baseSize) {
    final mood = widget.latestMood;
    if (mood == null) return baseSize;

    final percent = mood.emotionPercents[emotionKey] ?? 0;
    return baseSize + (percent * 0.45);
  }

  Widget gardenEmotion({
    required EmotionInfo emotion,
    required double left,
    required double top,
    required double baseSize,
  }) {
    final selected = selectedEmotionId == emotion.id;
    final size = getEmotionSize(emotion.key, baseSize);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedEmotionId = emotion.id;
            guideMessage = emotion.guideText;
          });
        },
        child: AnimatedScale(
          scale: selected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            children: [
              Image.asset(
                emotion.imagePath,
                height: size,
                width: size,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                emotion.name,
                style: TextStyle(
                  fontSize: selected ? 13 : 12,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? const Color(0xFF5D8A6D)
                      : const Color(0xFF5F566B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
    Widget areaCard(
    String emoji,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final gardenWidth = width - 40;
    final main = mainEmotion;

    final lunaMessage =
        widget.latestMood == null ? guideMessage : main.guideText;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/kokoro_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COCOON',
                  style: TextStyle(
                    fontSize: 34,
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F3A48),
                  ),
                ),
                const Text(
                  '心の広場',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D8A6D),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  height: 530,
                  child: Stack(
                    children: [
                      gardenEmotion(
                        emotion: emotionInfos[0],
                        left: gardenWidth * 0.02,
                        top: 35,
                        baseSize: 90,
                      ),
                      gardenEmotion(
                        emotion: emotionInfos[1],
                        left: gardenWidth * 0.42,
                        top: 80,
                        baseSize: 95,
                      ),
                      gardenEmotion(
                        emotion: emotionInfos[2],
                        left: gardenWidth * 0.04,
                        top: 270,
                        baseSize: 105,
                      ),
                      gardenEmotion(
                        emotion: emotionInfos[3],
                        left: gardenWidth * 0.52,
                        top: 300,
                        baseSize: 100,
                      ),
                      gardenEmotion(
                        emotion: emotionInfos[4],
                        left: gardenWidth * 0.70,
                        top: 135,
                        baseSize: 95,
                      ),
                    ],
                  ),
                ),

                Center(
                  child: Image.asset(
                    'assets/images/luna.png',
                    height: 190,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ルナからの案内',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6F5F8F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lunaMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          actionButton(
                            label: '話を聞く',
                            icon: Icons.chat_bubble_outline,
                            color: const Color(0xFF6F5FBA),
                            onTap: () => widget.onListen(main),
                          ),
                          const SizedBox(width: 10),
                          actionButton(
                            label: 'なでる',
                            icon: Icons.favorite_border,
                            color: const Color(0xFFD7649A),
                            onTap: () {
                              setState(() {
                                guideMessage =
                                    '${selectedEmotion.name}をそっとなでたよ。少し安心したみたい。';
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          actionButton(
                            label: '深呼吸',
                            icon: Icons.spa_outlined,
                            color: const Color(0xFF3C946F),
                            onTap: widget.onBreathing,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    areaCard(
                      '🌲',
                      '深呼吸の森',
                      '3分でリセット',
                      onTap: widget.onBreathing,
                    ),
                    areaCard('☕', 'ひとやすみカフェ', 'やさしい言葉で一息'),
                    areaCard('🌙', '夜の避難所', '眠れない夜の安心'),
                    areaCard('🏠', 'ルナのおうち', 'ルナと過ごす時間'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BreathingGuideScreen extends StatefulWidget {
  const BreathingGuideScreen({super.key});

  @override
  State<BreathingGuideScreen> createState() => _BreathingGuideScreenState();
}

class _BreathingGuideScreenState extends State<BreathingGuideScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool isBreathingIn = true;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 0.7,
      upperBound: 1.2,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isBreathingIn = false;
        });

        controller.animateBack(
          0.7,
          duration: const Duration(seconds: 6),
        );
      }

      if (status == AnimationStatus.dismissed) {
        setState(() {
          isBreathingIn = true;
        });

        controller.animateTo(
          1.2,
          duration: const Duration(seconds: 4),
        );
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void goBackToCocoon() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const CocoonApp(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8EF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Text(
                '深呼吸の森',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C946F),
                ),
              ),
              const SizedBox(height: 20),
              ScaleTransition(
                scale: controller,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isBreathingIn ? '吸って…' : '吐いて…',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/luna.png',
                height: 140,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: goBackToCocoon,
                child: const Text('心の広場に戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class MyPageScreen extends StatelessWidget {
  final String? petImagePath;
  final Function(String) onPetImageChanged;

  const MyPageScreen({
    super.key,
    required this.petImagePath,
    required this.onPetImageChanged,
  });

  Future<void> pickPetImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      onPetImageChanged(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                'マイページ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E7BBE),
                ),
              ),
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 90,
                backgroundColor: Colors.white,
                backgroundImage: petImagePath != null
                    ? FileImage(File(petImagePath!))
                    : const AssetImage('assets/images/luna.png')
                        as ImageProvider,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => pickPetImage(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E7BBE),
                  foregroundColor: Colors.white,
                ),
                child: const Text('ペット写真を変更'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class SimplePage extends StatelessWidget {
  final String title;
  final String icon;

  const SimplePage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$icon $title'),
    );
  }
}
