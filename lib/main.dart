import 'package:flutter/material.dart';

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
    guideText: '安心さんが今日はそばでふわっと見守ってくれてるみたい。',
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

  final List<ChatMessage> chatMessages = [
    ChatMessage(
      text: 'ここでは、恋愛・友情・人間関係・孤独感や不安を、ゆっくり整理できるよ。',
      isUser: false,
    ),
    ChatMessage(
      text: 'うまく話せなくても大丈夫。今いちばん近い気持ちを、そのまま書いてみてね。',
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
          text: '${emotion.name}のこと、一緒にゆっくり見ていこう。${emotion.guideText} 何が一番近い気持ち？',
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
      HomeScreen(latestMood: latestMood),
      MoodRecordScreen(onSave: saveMood),
      ChatScreen(messages: chatMessages),
      KokoroHirobaScreen(
        latestMood: latestMood,
        onListen: goToChatWithEmotion,
        onBreathing: goToBreathingGuide,
      ),
      const SimplePage(title: 'マイページ', icon: '🐾'),
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
              unselectedItemColor: const Color(0xFFB8AEC8),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'ホーム',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.spa_rounded),
                  label: '気分記録',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_rounded),
                  label: 'COCOON',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.park_rounded),
                  label: '心の広場',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'マイページ',
                ),
              ],
            ),
    );
  }
}
class HomeScreen extends StatelessWidget {
  final MoodRecord? latestMood;

  const HomeScreen({super.key, this.latestMood});

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
                      child: Image.asset(
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

  final List<String> weathers = ['☀️', '🌤️', '☁️', '🌧️', '🌪️', '🌙'];

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: memoController,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '例：今日は少し疲れた。でも記録できた。',
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
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

  void sendMessage() {
    final text = chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.messages.add(ChatMessage(text: text, isUser: true));
      widget.messages.add(ChatMessage(text: makeCocoonReply(text), isUser: false));
      chatController.clear();
    });
  }

  String makeCocoonReply(String userText) {
    final text = userText.toLowerCase();

    if (text.contains('不安') || text.contains('怖い') || text.contains('心配')) {
      return '不安が大きいんだね。まずは今起きていることを一緒に整理してみよう。';
    }

    if (text.contains('彼氏') || text.contains('恋愛') || text.contains('返信')) {
      return '恋愛の不安って、相手の反応ひとつで大きくなるよね。';
    }

    if (text.contains('友達')) {
      return '友達とのことで何が一番引っかかってる？';
    }

    return '話してくれてありがとう。もう少し詳しく聞かせてくれる？';
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
                      maxLines: 4,
                      minLines: 1,
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

  const ChatBubble({super.key, required this.message});

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

  Widget areaCard(String emoji, String title, String subtitle) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final gardenWidth = width - 40;
    final main = mainEmotion;

    final lunaMessage = widget.latestMood == null
        ? guideMessage
        : main.guideText;

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
                    fit: BoxFit.contain,
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
                        style: const TextStyle(fontSize: 18, height: 1.5),
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
                                selectedEmotionId = selectedEmotion.id;
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
                    areaCard('🌲', '深呼吸の森', '3分でリセット'),
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

class BreathingGuideScreen extends StatelessWidget {
  const BreathingGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '深呼吸の森',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C946F),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '吸って\n吐いて',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.6,
                      color: Color(0xFF3C946F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'ゆっくり吸って、ゆっくり吐こう。\n今はそれだけで大丈夫。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                  color: Color(0xFF5F566B),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const CocoonApp(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C946F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('心の広場に戻る'),
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
