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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  MoodRecord? latestMood;

  void saveMood(MoodRecord mood) {
    setState(() {
      latestMood = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(latestMood: latestMood),
      MoodRecordScreen(onSave: saveMood),
      const ChatScreen(),
      const KokoroHirobaScreen(),
      const SimplePage(title: 'マイページ', icon: '🐾'),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('記録できたよ🌿'),
        content: const Text('ここに来て、気持ちを置けたね。今日はそれだけで十分だよ。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ありがとう'),
          ),
        ],
      ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController chatController = TextEditingController();

  final List<ChatMessage> messages = [
    ChatMessage(
      text: 'ここでは、恋愛・友情・人間関係・孤独感や不安を、ゆっくり整理できるよ。',
      isUser: false,
    ),
    ChatMessage(
      text: 'うまく話せなくても大丈夫。今いちばん近い気持ちを、そのまま書いてみてね。',
      isUser: false,
    ),
  ];

  void sendMessage() {
    final text = chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      messages.add(ChatMessage(text: makeCocoonReply(text), isUser: false));
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
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(message: messages[index]);
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
  const KokoroHirobaScreen({super.key});

  @override
  State<KokoroHirobaScreen> createState() => _KokoroHirobaScreenState();
}

class _KokoroHirobaScreenState extends State<KokoroHirobaScreen> {
  String message = 'おかえり。今日はどんな気分？';
  String selectedEmotion = 'anxiety';

  void updateMessage(String emotion, String text) {
    setState(() {
      selectedEmotion = emotion;
      message = text;
    });
  }

  Widget emotionCharacter({
    required String imagePath,
    required String emotionId,
    required String name,
    required String status,
    required Color color,
    required String text,
  }) {
    final selected = selectedEmotion == emotionId;

    return GestureDetector(
      onTap: () => updateMessage(emotionId, text),
      child: Container(
        width: 135,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.28)
              : Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              height: 90,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(status, style: const TextStyle(fontSize: 12)),
          ],
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
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/kokoro_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.10),
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
                const SizedBox(height: 24),

                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    emotionCharacter(
                      imagePath: 'assets/images/emotion_anxiety.png',
                      emotionId: 'anxiety',
                      name: '不安さん',
                      status: 'そわそわ…',
                      color: Colors.blue,
                      text: '不安さんが今日は少し落ち着かないみたい。',
                    ),
                    emotionCharacter(
                      imagePath: 'assets/images/emotion_peace.png',
                      emotionId: 'peace',
                      name: '安心さん',
                      status: 'ふわふわ',
                      color: Colors.amber,
                      text: '安心さんが近くにいるよ。',
                    ),
                    emotionCharacter(
                      imagePath: 'assets/images/emotion_lonely.png',
                      emotionId: 'lonely',
                      name: 'さみしいさん',
                      status: 'ひとやすみ中',
                      color: Colors.pink,
                      text: 'さみしいさんが少し寂しそう。',
                    ),
                    emotionCharacter(
                      imagePath: 'assets/images/emotion_tired.png',
                      emotionId: 'tired',
                      name: 'おつかれさん',
                      status: 'すやすや',
                      color: Colors.purple,
                      text: '今日はゆっくり休もう。',
                    ),
                    emotionCharacter(
                      imagePath: 'assets/images/emotion_angry.png',
                      emotionId: 'angry',
                      name: 'イライラさん',
                      status: 'もやもや',
                      color: Colors.orange,
                      text: 'イライラさんも大切な感情だよ。',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Center(
                  child: Image.asset(
                    'assets/images/luna.png',
                    height: 190,
                  ),
                ),

                const SizedBox(height: 12),

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
                        '今日のこころ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
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
