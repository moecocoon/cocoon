import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
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

  Map<String, dynamic> toJson() {
    return {
      'weather': weather,
      'emotionPercents': emotionPercents,
      'memo': memo,
    };
  }

  factory MoodRecord.fromJson(Map<String, dynamic> json) {
    return MoodRecord(
      weather: json['weather'],
      emotionPercents: Map<String, double>.from(
        (json['emotionPercents'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as num).toDouble(),
          ),
        ),
      ),
      memo: json['memo'] ?? '',
    );
  }
}


class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
    );
  }
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
MoodRecord? previousMood;
String? petImagePath;
@override
void initState() {
  super.initState();
  loadPetImage();
  loadChatMessages();
  loadMoodRecord();
}



Future<void> loadPetImage() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    petImagePath = prefs.getString('petImagePath');
  });
}

Future<void> loadMoodRecord() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('latestMood');

  if (saved == null) return;

  setState(() {
    latestMood = MoodRecord.fromJson(jsonDecode(saved));
  });
}

Future<void> saveMoodRecord(MoodRecord mood) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'latestMood',
    jsonEncode(mood.toJson()),
  );
}



Future<void> updatePetImage(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('petImagePath', path);

  setState(() {
    petImagePath = path;
  });
}

// ここに追加
Future<void> loadChatMessages() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('chatMessages');

  if (saved == null) return;

  final List decoded = jsonDecode(saved);

  setState(() {
    chatMessages
      ..clear()
      ..addAll(
        decoded.map(
          (item) => ChatMessage.fromJson(item),
        ),
      );
  });
}

Future<void> saveChatMessages() async {
  final prefs = await SharedPreferences.getInstance();

  final encoded = jsonEncode(
    chatMessages.map((message) => message.toJson()).toList(),
  );

  await prefs.setString('chatMessages', encoded);
}


  final List<ChatMessage> chatMessages = [
    ChatMessage(
      text: 'ここでは、ゆっくり気持ちを整理できるよ。',
      isUser: false,
    ),
  ];

 void saveMood(MoodRecord mood) {
  setState(() {
    previousMood = latestMood;
    latestMood = mood;
  });

  saveMoodRecord(mood);
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

void goToKokoroHiroba() {
  setState(() {
    selectedIndex = 3;
  });
}


void goToCafe() {
  setState(() {
    selectedIndex = 6;
  });
}

void goToNightShelter() {
  setState(() {
    selectedIndex = 7;
  });
}

void goToLunaHouse() {
  setState(() {
    selectedIndex = 8;
  });
}



  @override
  Widget build(BuildContext context) {
    final pages = [
   HomeScreen(
  latestMood: latestMood,
  petImagePath: petImagePath,
  onTalkAboutMood: () {
    setState(() {
      selectedIndex = 2;
      chatMessages.add(
        ChatMessage(
          text: '今日の気分記録について話したい',
          isUser: true,
        ),
      );
      chatMessages.add(
        ChatMessage(
          text: '今日の記録をもとに、一緒に気持ちを整理していこう。',
          isUser: false,
        ),
      );
    });
    saveChatMessages();
  },
),


      MoodRecordScreen(onSave: saveMood),
 ChatScreen(
  messages: chatMessages,
  onMessagesChanged: saveChatMessages,
  latestMood: latestMood,
),


KokoroHirobaScreen(
  latestMood: latestMood,
  onListen: goToChatWithEmotion,
  onBreathing: goToBreathingGuide,
  onCafe: goToCafe,
  onNightShelter: goToNightShelter,
  onLunaHouse: goToLunaHouse,

),


      MyPageScreen(
  petImagePath: petImagePath,
  onPetImageChanged: updatePetImage,
),

BreathingGuideScreen(onBack: goToKokoroHiroba),
HitoyasumiCafeScreen(onBack: goToKokoroHiroba),
NightShelterScreen(onBack: goToKokoroHiroba),
LunaHouseScreen(onBack: goToKokoroHiroba),
];






    return Scaffold(
      body: pages[selectedIndex],
     bottomNavigationBar: selectedIndex >= 5

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
class HomeScreen extends StatefulWidget {
  final MoodRecord? latestMood;
  final String? petImagePath;
  final VoidCallback onTalkAboutMood;

 const HomeScreen({
  super.key,
  this.latestMood,
  this.petImagePath,
  required this.onTalkAboutMood,
});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

late AnimationController _controller;
late Animation<double> _floatingAnimation;

@override
void initState() {
  super.initState();

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  _floatingAnimation = Tween<double>(
    begin: -6,
    end: 6,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ),
  );
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final lunaHeight = (size.height * 0.42).clamp(250.0, 460.0);

    final lunaMessages = [
  'おかえり。\n今日も会えてうれしいよ。',
  '無理しなくていいよ。\nここで少し休もう。',
  '今日の気持ち、\nあとで聞かせてね。',
  'ここに来てくれてありがとう。\nゆっくりで大丈夫。',
  'がんばれない日も、\nここにいていいよ。',
];
final hour = DateTime.now().hour;
String timeMessage;

Color overlayColor;

if (hour >= 5 && hour < 11) {
  overlayColor = Colors.orange.withOpacity(0.12);
} else if (hour >= 11 && hour < 17) {
  overlayColor = Colors.white.withOpacity(0.05);
} else if (hour >= 17 && hour < 22) {
  overlayColor = Colors.deepPurple.withOpacity(0.18);
} else {
  overlayColor = Colors.indigo.withOpacity(0.30);
}

if (hour >= 5 && hour < 11) {
  timeMessage = 'おはよう。\n';
} else if (hour >= 11 && hour < 17) {
  timeMessage = '今日も来てくれてありがとう。\n';
} else if (hour >= 17 && hour < 22) {
  timeMessage = '今日も一日おつかれさま。\n';
} else {
  timeMessage = 'まだ起きてたんだね。\n';
}


String lunaMessage = '';

if (widget.latestMood != null &&
    widget.latestMood!.emotionPercents.isNotEmpty) {
  final strongestEmotion = widget.latestMood!.emotionPercents.entries
      .reduce((a, b) => a.value >= b.value ? a : b);

  if (strongestEmotion.key.contains('不安')) {
    lunaMessage = '${timeMessage}今日は不安さんが少し大きいみたい。\nここで一緒にゆっくりしよう。';
  } else if (strongestEmotion.key.contains('疲れ')) {
    lunaMessage = '${timeMessage}今日はおつかれさんが近くにいるね。\n無理しない時間にしよう。';
  } else if (strongestEmotion.key.contains('さみしい')) {
    lunaMessage = '${timeMessage}今日はさみしいさんが顔を出してるね。\nルナがそばにいるよ。';
  } else if (strongestEmotion.key.contains('イライラ')) {
    lunaMessage = '${timeMessage}今日はイライラさんが強めかも。\nここで少しほどいていこう。';
  } else if (strongestEmotion.key.contains('安心')) {
    lunaMessage = '${timeMessage}今日は安心さんもいるね。\nそのやわらかい気持ち、大事にしよう。';
  } else {
    lunaMessage = '${timeMessage}今日の気持ち、ちゃんと届いてるよ。\n少し一緒に整理しよう。';
  }
} else {
  lunaMessage =
      '$timeMessage${lunaMessages[Random().nextInt(lunaMessages.length)]}';
}



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
              color:overlayColor,
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

               

                  const SizedBox(height: 18),


                    SizedBox(
                      height: lunaHeight,
                      width: double.infinity,
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
  lunaMessage,
  
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Color(0xFF6D6478),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              Positioned(
                                bottom: -10,
                                child: Transform.rotate(
                                  angle: 0.785398,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Expanded(
  child: widget.petImagePath != null
      ? Image.file(
          File(widget.petImagePath!),
          fit: BoxFit.contain,
        )
      : AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation.value),
              child: child,
            );
          },
          child: Image.asset(
            'assets/images/luna.png',
            fit: BoxFit.contain,
          ),
        ),
),
                        ],
                      ),
                    ),


                    const SizedBox(height: 16),

                    if (widget.latestMood != null)
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
                             widget.latestMood!.weather,
                              style: const TextStyle(fontSize: 34),
                            ),
                            const SizedBox(height: 8),
                            ...widget.latestMood!.emotionPercents.entries.map(
                              (entry) => Text(
                                '${entry.key}：${entry.value.round()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6F5F8F),
                                ),
                              ),
                            ),
                            if (widget.latestMood!.memo.isNotEmpty)
                             ...[
                              const SizedBox(height: 10),
                              Text(
                                widget.latestMood!.memo,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6D6478),
                                ),
                              ),
                              const SizedBox(height: 14),

ElevatedButton(
  onPressed: widget.onTalkAboutMood,
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF8E7BBE),
    foregroundColor: Colors.white,
  ),
  child: const Text('この気持ちをCOCOONに話す'),
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
  final VoidCallback onMessagesChanged;
  final MoodRecord? latestMood;


const ChatScreen({
  super.key,
  required this.messages,
  required this.onMessagesChanged,
  this.latestMood,
});



  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? currentTopic;
  @override
void initState() {
  super.initState();
  loadCurrentTopic();
}

Future<void> loadCurrentTopic() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    currentTopic = prefs.getString('currentTopic');
  });
}

Future<void> saveCurrentTopic(String topic) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('currentTopic', topic);
}
  final TextEditingController chatController = TextEditingController();
  final Random random = Random();

  String pick(List<String> replies) {
    return replies[random.nextInt(replies.length)];
  }

  void sendQuickTopic(String topic) {
  chatController.text = topic;
  sendMessage();
}

void sendMessage() {
  final text = chatController.text.trim();
  if (text.isEmpty) return;

  setState(() {
    widget.messages.add(ChatMessage(text: text, isUser: true));
  widget.messages.add(
  ChatMessage(
    text: makeCocoonReply(text, widget.messages),
    isUser: false,
  ),
);

    chatController.clear();
  });

  widget.onMessagesChanged();
}


 String makeCocoonReply(String userText, List<ChatMessage> pastMessages) {
  final text = userText.toLowerCase();
  if (text.contains('彼氏') ||
    text.contains('恋愛') ||
    text.contains('返信') ||
    text.contains('既読')) {
 currentTopic = '恋愛';
saveCurrentTopic('恋愛');

}

if (text.contains('家族') ||
    text.contains('親')) {
  currentTopic = '家族';
saveCurrentTopic('家族');
}

if (text.contains('不安') ||
    text.contains('怖い')) {
  currentTopic = '不安';
saveCurrentTopic('不安');
}

if (text.contains('眠れない') ||
    text.contains('寝れない')) {
  currentTopic = '睡眠';
saveCurrentTopic('睡眠');
}
  final recentUserTexts = pastMessages
    .where((message) => message.isUser)
    .map((message) => message.text)
    .toList();
    final mood = widget.latestMood;

if (mood != null &&
    (text.contains('今日') ||
        text.contains('今の気持ち') ||
        text.contains('気分') ||
        text.contains('話したい'))) {
  final strongestEmotion = mood.emotionPercents.entries
      .reduce((a, b) => a.value >= b.value ? a : b);

  return '今日の記録を見ると、${mood.weather}で、'
      '${strongestEmotion.key}が${strongestEmotion.value.round()}%くらいあるんだね。\n'
      'その気持ちが少し強めに出ている日なのかもしれない。\n'
      '今日は何が一番その気持ちにつながっていそう？';
}

    if (text.contains('死にたい') ||
    text.contains('消えたい') ||
    text.contains('自殺') ||
    text.contains('自傷') ||
    text.contains('リスカ') ||
    text.contains('傷つけたい') ||
    text.contains('殺したい')) {
  return '今、とても危ないくらい苦しい状態かもしれないね。\n'
      'ここでひとりで抱えなくて大丈夫。\n'
      '今すぐ近くの人、家族、先生、友達、または地域の緊急窓口に連絡してね。\n'
      'もし今すぐ自分や誰かを傷つけそうなら、ためらわずに119や110に連絡してね。';
}

if (currentTopic != null &&
    (text.contains('話したい') ||
        text.contains('相談したい') ||
        text.contains('聞いて'))) {
  return '前回は$currentTopicのことで話してたね。\n'
      '今日はその続き？それとも別のこと？';
}

if (currentTopic == '恋愛' &&
    (text.contains('つらい') ||
        text.contains('しんどい') ||
        text.contains('不安'))) {
  return pick([
    '恋愛のことも重なって、気持ちがかなり揺れてるのかもしれないね。',
    '返信や相手の反応のことが、まだ心に残ってそうだね。',
  ]);
}

if (currentTopic == '家族' &&
    (text.contains('疲れた') ||
        text.contains('もう嫌'))) {
  return pick([
    '家族のことで気を張り続けて、かなり疲れてるのかもしれないね。',
    '近い存在だからこそ、心の消耗も大きくなりやすいよね。',
  ]);
}
// 相談タイプボタン：恋愛
if (text.contains('恋愛のことで話したい')) {
  return pick([
    '恋愛のことだね。\n大切な相手だからこそ、不安や寂しさも大きくなりやすいよね。\n今いちばん近いのは「返信」「会えない」「冷たい」「喧嘩」のどれ？',
    '恋愛の話、ここでゆっくり聞くよ。\n今は不安が強い？寂しさが強い？それともモヤモヤ？',
  ]);
}

// 相談タイプボタン：不安
if (text.contains('不安な気持ちを整理したい')) {
  return pick([
    '不安を整理したいんだね。\nまずは「今起きていること」と「想像していること」を分けてみよう。\n今いちばん怖いのは何？',
    '不安って、頭の中で大きくなりやすいよね。\n一緒に小さく分けていこう。\n体もザワザワしてる？それとも考えが止まらない感じ？',
  ]);
}

// 相談タイプボタン：眠れない
if (text.contains('眠れない夜でつらい')) {
  return pick([
    '眠れない夜って、考えごとが何倍にも大きく見えるよね。\n今は頭がぐるぐるしてる？それとも体が落ち着かない？',
    '寝ようとしてるのに眠れないの、しんどいよね。\n今は無理に寝ようとしなくて大丈夫。\nまず何が浮かんでくる？',
  ]);
}

// 相談タイプボタン：家族
if (text.contains('家族のことで悩んでいる')) {
  return pick([
    '家族のことだね。\n近い存在だからこそ、簡単に割り切れなくて苦しくなるよね。\n今つらいのは「理解されない」「責められる」「距離感」のどれに近い？',
    '家族の悩みって、心の深いところに残りやすいよね。\n今日はどんなことが一番引っかかってる？',
  ]);
}

// 相談タイプボタン：ただ話したい
if (text.contains('ただ話を聞いてほしい')) {
  return pick([
    'うん、ここでは無理に整理しなくて大丈夫。\n話せるところからでいいよ。\n今、心の中に一番ある言葉は何？',
    'ただ聞いてほしい時ってあるよね。\nアドバイスより、まず受け止めてほしい感じかな。\n何があった？',
  ]);
}

String? previousUserText() {
  final users = pastMessages.where((message) => message.isUser).toList();
  if (users.length < 2) return null;
  return users[users.length - 2].text;
}

final previousText = previousUserText();

// 会話の続き：冷たいと言われた後
if (previousText != null &&
    (previousText.contains('冷たい') ||
        previousText.contains('そっけない')) &&
    (text.contains('昨日') ||
        text.contains('今日') ||
        text.contains('最近') ||
        text.contains('急に'))) {
  return pick([
    '急に態度が変わったように見えると、不安になるよね。\n前と比べて一番変わったと感じるのは、返信の速さ？言葉の感じ？会う頻度？',
    '最近そう感じるんだね。\nそれは「嫌われたかも」って考えが出てきやすい状況だと思う。',
  ]);
}

// 会話の続き：眠れない理由
if (previousText != null &&
    (previousText.contains('眠れない') ||
        previousText.contains('寝れない')) &&
    (text.contains('考え') ||
        text.contains('不安') ||
        text.contains('スマホ') ||
        text.contains('彼氏') ||
        text.contains('家族'))) {
  return pick([
    'それが頭に残って眠れないんだね。\n今は解決しようとするより、まず心を少し落ち着かせる方がよさそう。',
    '眠れない理由が少し見えてきたね。\nその中で一番大きいのは、不安？寂しさ？モヤモヤ？',
  ]);
}

// 会話の続き：家族の悩み
if (previousText != null &&
    (previousText.contains('家族') ||
        previousText.contains('親') ||
        previousText.contains('母') ||
        previousText.contains('父')) &&
    (text.contains('責め') ||
        text.contains('わかってくれない') ||
        text.contains('しんどい') ||
        text.contains('疲れた'))) {
  return pick([
    '家族にわかってもらえない感じって、かなり心にくるよね。\n近い相手だからこそ、言葉が深く刺さることもあると思う。',
    '責められているように感じると、自分の居場所まで不安になるよね。\n今ほしいのは、理解？距離？安心できる言葉？',
  ]);
}

// 会話の続き：返信待ちの時間
if (previousText != null &&
    (previousText.contains('既読') ||
        previousText.contains('未読') ||
        previousText.contains('返信') ||
        previousText.contains('返事')) &&
    (text.contains('1日') ||
        text.contains('一日') ||
        text.contains('半日') ||
        text.contains('数時間') ||
        text.contains('昨日から'))) {
  return pick([
    'それは長く感じるよね。\n待ってる間って、スマホを見るたびに心が揺れやすいと思う。\n今一番怖い想像は何？',
    'そのくらい返ってこないと、不安さんが大きくなりやすいよね。\n相手に送りたい言葉はある？それとも今は待つ方が近い？',
  ]);
}
bool talkedAbout(List<String> keywords) {
  return recentUserTexts.any(
    (pastText) => keywords.any((keyword) => pastText.contains(keyword)),
  );
}
// 前にも恋愛の不安を話していた
if ((text.contains('また不安') ||
        text.contains('また怖い') ||
        text.contains('またつらい') ||
        text.contains('またしんどい')) &&
    talkedAbout([
      '返信遅い',
      '返信が遅い',
      '既読',
      '未読',
      '冷たい',
      '会えない',
      '恋愛',
      '好きな人',
      '彼氏',
      '彼女',
    ])) {
  return pick([
    '前にも相手のことで不安になっていたよね。\n今回も同じ人のことかな？',
    'この前も恋愛の不安を話してくれていたね。\nまた心が揺れることがあったのかな。',
    '前に話してくれた不安と少しつながっている感じがするよ。\n今日は何が一番引っかかってる？',
  ]);
}

// 前にも眠れない話をしていた
if ((text.contains('また眠れない') ||
        text.contains('今日も眠れない') ||
        text.contains('また寝れない') ||
        text.contains('今日も寝れない')) &&
    talkedAbout([
      '眠れない',
      '寝れない',
      '寝つけない',
      '夜',
    ])) {
  return pick([
    '前にも眠れない夜のことを話してくれていたね。\n今日も頭が休まらない感じかな。',
    'また眠れないんだね。前の夜もつらかったよね。\n今は考えごとが多い？それとも体が落ち着かない？',
    '眠れない夜が続くと、心も体もしんどくなるよね。\n今夜はまず、休むことだけを目標にしてもいいよ。',
  ]);
}

// 前にも疲れの話をしていた
if ((text.contains('また疲れた') ||
        text.contains('今日もしんどい') ||
        text.contains('またしんどい') ||
        text.contains('まだしんどい')) &&
    talkedAbout([
      '疲れた',
      'しんどい',
      '限界',
      'もう無理',
    ])) {
  return pick([
    '前にも疲れがたまっている感じを話してくれていたね。\nまだ回復しきれていないのかもしれない。',
    '今日もかなり重いんだね。\n前から続いている疲れなら、少し本気で休む時間が必要かも。',
    'またしんどいって言えるくらい、ずっと頑張ってきたんだと思う。',
  ]);
}

// 前にも人間関係の話をしていた
if ((text.contains('またモヤモヤ') ||
        text.contains('また嫌') ||
        text.contains('またつらい') ||
        text.contains('今日もつらい')) &&
    talkedAbout([
      '友達',
      '親友',
      '人間関係',
      '悪口',
      '無視',
      '家族',
      '親',
      '母',
      '父',
    ])) {
  return pick([
    '前にも人との関係で揺れていたよね。\n今回も同じ相手のことかな？',
    'また人間関係で心が疲れている感じかな。\n何が一番残ってる？',
    '前に話してくれたことと少しつながっていそうだね。\n今日はどんな場面がつらかった？',
  ]);
}


    // 恋愛：返信が遅い
    if (text.contains('返信遅い') ||
        text.contains('返信が遅い') ||
        text.contains('返事遅い') ||
        text.contains('返事が遅い')) {
      return pick([
        '返信が遅いと、不安さんが一気に大きくなりやすいよね。\n今わかっている事実は「まだ返事が来ていない」ことだけかも。',
        '待ってる時間って、実際よりずっと長く感じるよね。\n一番怖い想像は「冷めたかも」ってこと？',
        '返信の遅さって、相手の気持ち全部に見えてしまう時あるよね。\nでもまずは事実と想像を分けよう。',
        '今はスマホを見るたびに心が揺れてる感じかな。\n返事が来たら安心できそう？',
      ]);
    }

    // 恋愛：既読・未読
    if (text.contains('既読無視') ||
        text.contains('既読スルー') ||
        text.contains('未読無視') ||
        text.contains('未読スルー') ||
        text.contains('未読') ||
        text.contains('既読')) {
      return pick([
        '既読や未読のまま止まると、不安がどんどん膨らみやすいよね。',
        '返事がない理由が見えないと、心が悪い方に想像しちゃうことあるよね。',
        '今は「返事がない」という事実と、「嫌われたかも」という想像を分けてみよう。',
        '待っている側はすごく苦しいよね。今一番強いのは不安？寂しさ？',
      ]);
    }

    // 恋愛：冷たい・別れ不安
    if (text.contains('冷たい') ||
        text.contains('そっけない') ||
        text.contains('別れ') ||
        text.contains('振られ') ||
        text.contains('終わり')) {
      return pick([
        '相手の変化を感じると、別れの不安まで一気に飛んでしまうことあるよね。',
        '今は結論を急がず、「実際にあったこと」と「想像していること」を分けてみよう。',
        '失うかもって思うと、いつもの自分でいられなくなるよね。',
        '一番怖いのは、相手の気持ちが離れること？それとも関係が変わること？',
      ]);
    }

    // 恋愛：会えない・喧嘩・嫉妬・依存
    if (text.contains('会えない') ||
        text.contains('会いたい') ||
        text.contains('喧嘩') ||
        text.contains('ケンカ') ||
        text.contains('嫉妬') ||
        text.contains('やきもち') ||
        text.contains('依存') ||
        text.contains('離れられない')) {
      return pick([
        '恋愛って、大切だからこそ不安や寂しさも大きくなりやすいよね。',
        '今ほしいのは、安心する言葉？それとも相手とちゃんと話す時間？',
        'その気持ちの奥にあるのは「寂しい」「不安」「怒り」のどれが近い？',
        '相手のことで心がいっぱいになってる感じかな。少しずつ整理しよう。',
      ]);
    }

    // 不安：漠然とした不安
    if (text.contains('不安') ||
        text.contains('怖い') ||
        text.contains('心配') ||
        text.contains('どうしよう')) {
      return pick([
        '不安さんがかなり大きくなってる感じかな。\n今は「何が怖いのか」を一緒に小さく分けてみよう。',
        '不安って、正体がぼんやりしてる時ほど大きく見えやすいよね。',
        '頭の中で何度も同じことを考えちゃう感じ？それとも胸がザワザワする感じ？',
        '今すぐ答えを出さなくて大丈夫。\nまずは「今起きてること」と「想像してること」を分けよう。',
        '不安がある時は、未来を一気に見すぎていることもあるよ。\n今この瞬間に戻ってみよう。',
      ]);
    }

    // 不安：考えすぎ
    if (text.contains('考えすぎ') ||
        text.contains('考えちゃう') ||
        text.contains('頭から離れない') ||
        text.contains('ぐるぐる')) {
      return pick([
        '頭の中がぐるぐるしてるんだね。\n考えを止めようとするより、まず外に出してみよう。',
        '同じことを何度も考える時って、安心材料を探してることが多いよ。',
        '考えすぎてる時は、心が「ちゃんと守りたい」って頑張ってるのかも。',
        '今の考えは、事実？予想？不安さんの声？一緒に分けよう。',
      ]);
    }

    // 不安：体の反応
    if (text.contains('ドキドキ') ||
        text.contains('息苦しい') ||
        text.contains('苦しい') ||
        text.contains('落ち着かない') ||
        text.contains('震える')) {
      return pick([
        '体にも不安が出てる感じがあるね。\nまずはゆっくり息を吐くことから始めよう。',
        'ドキドキや息苦しさがある時は、体が警戒モードになってるのかも。',
        '今は考えるより、体を少し安心させるのが先でもいいよ。',
        '足の裏を床につけて、「今ここ」に戻ってみよう。',
      ]);
    }

    // 眠れない：夜の不安
    if (text.contains('眠れない') ||
        text.contains('寝れない') ||
        text.contains('寝つけない') ||
        text.contains('夜')) {
      return pick([
        '夜って、不安さんが何倍にも大きく見えやすい時間だよね。',
        '眠れない時って、頭も心も止まらなくなる感じがあるよね。',
        '今は無理に寝ようとしなくて大丈夫。\nまず体を休ませるだけでもいいよ。',
        '夜の考えごとは、朝より重く見えやすいよ。\n今は結論を出さなくていい時間にしよう。',
        '頭がぐるぐるしてる？それとも体が落ち着かない？',
      ]);
    }

    // 眠れない：スマホ・SNS
    if (text.contains('スマホ') ||
        text.contains('sns') ||
        text.contains('インスタ') ||
        text.contains('見ちゃう')) {
      return pick([
        '眠れない時のスマホって、安心したくて見ちゃうことあるよね。',
        'SNSを見るほど心がざわつくなら、少しだけ画面から離れてもいいかも。',
        '今スマホを見てるのは、安心したいから？それとも気を紛らわせたいから？',
        '心が疲れてる時ほど、人の投稿がまぶしく見えることあるよ。',
      ]);
    }

        // 孤独
    if (text.contains('孤独') ||
        text.contains('ひとり') ||
        text.contains('一人') ||
        text.contains('ひとりぼっち') ||
        text.contains('寂しい') ||
        text.contains('さみしい')) {
      return pick([
        'ひとりで抱えると、気持ちってすごく重くなるよね。',
        '今は誰かにいてほしい感じ？それともただ吐き出したい感じ？',
        'さみしいさんが近くにいる感じかな。ここで少し一緒にいよう。',
        '孤独って、静かだけど心にはかなり重くのしかかるよね。',
      ]);
    }

    // イライラ
    if (text.contains('イライラ') ||
        text.contains('ムカつく') ||
        text.contains('腹立つ') ||
        text.contains('怒り')) {
      return pick([
        'イライラの奥に、本当は悲しさや傷つきがあることもあるよ。',
        '何が一番引っかかった？',
        '怒りって「大事なものが傷ついたサイン」のこともあるよ。',
        '我慢してきたものが溜まってる感じかもしれないね。',
      ]);
    }

    // 疲れ
    if (text.contains('疲れた') ||
        text.contains('しんどい') ||
        text.contains('限界') ||
        text.contains('もう無理')) {
      return pick([
        'かなり頑張ってきた感じが伝わるよ。',
        '今必要なのは休むこと？話すこと？',
        '限界まで頑張ってきたのかもしれないね。',
        '今日は回復を優先していい日かもしれないよ。',
      ]);
    }

    // 自己否定
    if (text.contains('自分が嫌') ||
        text.contains('自分嫌い') ||
        text.contains('ダメ') ||
        text.contains('価値がない')) {
      return pick([
        '今、自分にかなり厳しくなってる感じがあるよ。',
        'その言葉、自分に強く向けてるね。',
        '本当にそうなのか、不安さんや疲れさんの声なのか、一緒に見てみよう。',
        '自分を責める前に、何がそこまで苦しかったのか見ていいよ。',
      ]);
    }

    // 友達・人間関係
    if (text.contains('友達') ||
        text.contains('親友') ||
        text.contains('人間関係') ||
        text.contains('悪口') ||
        text.contains('無視')) {
      return pick([
        '人間関係って、小さい違和感でも心に残りやすいよね。',
        '悲しかった？それともモヤモヤした？',
        '大事にされてない感じがしたのかな。',
        '相手との関係を続けたい気持ちと、苦しい気持ち、どっちが今強い？',
      ]);
    }

    // 家族
    if (text.contains('家族') ||
        text.contains('母') ||
        text.contains('父') ||
        text.contains('親') ||
        text.contains('兄') ||
        text.contains('姉') ||
        text.contains('弟') ||
        text.contains('妹')) {
      return pick([
        '家族のことって、距離が近いぶん心が揺れやすいよね。',
        'わかってほしい気持ちと、離れたい気持ちが両方ある感じかな。',
        '責められた感じ？それとも理解されない感じ？',
        '簡単に割り切れないからこそ苦しいよね。',
      ]);
    }

      // 将来
    if (text.contains('将来') ||
        text.contains('未来') ||
        text.contains('お金') ||
        text.contains('生活')) {
      return pick([
        '先が見えない時って、不安さんが大きくなりやすいよね。',
        '一番心配なのは生活？仕事？人間関係？',
        '未来を一気に考えると苦しくなるから、まず今日できる一歩に分けよう。',
        'お金の不安って、現実的だからこそ重く感じるよね。',
      ]);
    }

    // 学校
    if (text.contains('学校') ||
        text.contains('勉強') ||
        text.contains('テスト') ||
        text.contains('大学')) {
      return pick([
        '学校のプレッシャーってしんどいよね。',
        '人間関係？成績？プレッシャー？どれが近い？',
        '頑張ってるからこそ苦しくなる時あるよね。',
        'ちゃんとやらなきゃって気持ちで疲れてない？',
      ]);
    }

    // 泣きたい・涙
if (text.contains('泣きたい') ||
    text.contains('涙') ||
    text.contains('泣いた') ||
    text.contains('泣きそう')) {
  return pick([
    '泣きたいくらい、ずっと我慢してきたのかもしれないね。',
    '涙が出そうな時は、心が「もう少しやさしくして」って言ってるのかも。',
    '泣くことは弱いことじゃないよ。ちゃんと感じている証拠だよ。',
    '今は理由をきれいに説明できなくても大丈夫。ここで少し休もう。',
  ]);
}

// 朝がつらい
if (text.contains('朝つらい') ||
    text.contains('朝がつらい') ||
    text.contains('起きれない') ||
    text.contains('起きられない') ||
    text.contains('布団から出られない')) {
  return pick([
    '朝が重い日は、心も体もまだ休みたがっているのかもしれないね。',
    '起きられない自分を責めるより、まず「今日は重い日なんだ」って受け止めていいよ。',
    '今日を全部頑張ろうとしなくて大丈夫。まずは水を飲む、顔を洗う、くらいでいいよ。',
    '朝からつらいと、一日が長く感じるよね。今できそうな一番小さいことは何かな。',
  ]);
}

// 仕事・バイト
if (text.contains('仕事') ||
    text.contains('バイト') ||
    text.contains('職場') ||
    text.contains('上司') ||
    text.contains('会社')) {
  return pick([
    '仕事のしんどさって、逃げ場が少なく感じることがあるよね。',
    '職場で気を張り続けて、かなり疲れているのかもしれないね。',
    '今つらいのは、人間関係？量の多さ？それとも評価される不安？',
    'ちゃんとやらなきゃって思うほど、自分を追い込みやすいよね。',
  ]);
}

// 自信がない
if (text.contains('自信ない') ||
    text.contains('自信がない') ||
    text.contains('できない') ||
    text.contains('向いてない') ||
    text.contains('比べちゃう')) {
  return pick([
    '自信がない時って、できていることまで見えにくくなるよね。',
    '誰かと比べて苦しくなってる感じかな。',
    '「できない」って思うくらい、ちゃんと向き合っているのかもしれないよ。',
    '今は大きな自信じゃなくて、小さく「ここまではできた」を探してみよう。',
  ]);
}

// 生理前・ホルモン
if (text.contains('生理前') ||
    text.contains('生理') ||
    text.contains('pms') ||
    text.contains('PMS') ||
    text.contains('ホルモン')) {
  return pick([
    '生理前は、いつもより不安や悲しさが強く見えることがあるよね。',
    'それは気合い不足じゃなくて、体の波の影響もあるかもしれないよ。',
    '今日は自分に厳しく判断しすぎない日にしてもいいかも。',
    '心も体も敏感になっている時期かもしれないね。少し守るモードでいこう。',
  ]);
}

// 誰にも言えない
if (text.contains('誰にも言えない') ||
    text.contains('言えない') ||
    text.contains('相談できない') ||
    text.contains('隠してる')) {
  return pick([
    '誰にも言えずに抱えてきたんだね。それだけでかなり重かったと思う。',
    'ここでは、きれいに話せなくても大丈夫だよ。',
    '言えない気持ちには、言えないだけの理由があるよね。',
    '少しずつでいいよ。今いちばん外に出したい言葉は何かな。',
  ]);
}



    return pick([
      '話してくれてありがとう。\nもう少し詳しく聞かせてくれる？',
      'ちゃんと受け取ったよ。\n今一番近い感情はどれ？',
      'ここでゆっくり整理していこう。\n急がなくて大丈夫。',
    ]);
  }

  // 相談タイプボタン：恋愛


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
            const Padding(
  padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
  child: Text(
    'COCOONは医療・専門相談の代わりではありません。危険を感じる時は、すぐに身近な人や緊急窓口に連絡してください。',
    style: TextStyle(
      fontSize: 12,
      color: Color(0xFF8A7D96),
    ),
    textAlign: TextAlign.center,
  ),
),
Padding(
  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
  child: Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ActionChip(
        label: const Text('💔 恋愛'),
        onPressed: () => sendQuickTopic('恋愛のことで話したい'),
      ),
      ActionChip(
        label: const Text('😰 不安'),
        onPressed: () => sendQuickTopic('不安な気持ちを整理したい'),
      ),
      ActionChip(
        label: const Text('🌙 眠れない'),
        onPressed: () => sendQuickTopic('眠れない夜でつらい'),
      ),
      ActionChip(
        label: const Text('🏠 家族'),
        onPressed: () => sendQuickTopic('家族のことで悩んでいる'),
      ),
      ActionChip(
        label: const Text('🫂 ただ話したい'),
        onPressed: () => sendQuickTopic('ただ話を聞いてほしい'),
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
  final VoidCallback onCafe;
  final VoidCallback onNightShelter;
  final VoidCallback onLunaHouse;

  const KokoroHirobaScreen({
    super.key,
    this.latestMood,
    required this.onListen,
    required this.onBreathing,
    required this.onCafe,
    required this.onNightShelter,
    required this.onLunaHouse,
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

                    areaCard(
  '☕',
  'ひとやすみカフェ',
  'やさしい言葉で一息',
  onTap: widget.onCafe,
),

areaCard(
  '🌙',
  '夜の避難所',
  '眠れない夜の安心',
  onTap: () {
    setState(() {
      guideMessage = '夜の避難所が押されたよ';
    });
    widget.onNightShelter();
  },
),

areaCard(
  '🏠',
  'ルナのおうち',
  'ルナと過ごす時間',
  onTap: widget.onLunaHouse,
),



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
  final VoidCallback onBack;

  const BreathingGuideScreen({
    super.key,
    required this.onBack,
  });

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
  onPressed: widget.onBack,
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


class HitoyasumiCafeScreen extends StatelessWidget {
  final VoidCallback onBack;

  const HitoyasumiCafeScreen({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Text(
                'ひとやすみカフェ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9A6B4F),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'あたたかい飲みものみたいに、少しだけ心をゆるめよう。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF6D5A4E),
                ),
              ),
              const SizedBox(height: 36),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Text(
                  '今日は、ちゃんと頑張った日。\n何もできなかったように見えても、ここまで来たことがもう十分だよ。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.7,
                    color: Color(0xFF5F4D43),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onBack,
                child: const Text('心の広場に戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NightShelterScreen extends StatelessWidget {
  final VoidCallback onBack;

  const NightShelterScreen({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Text(
                '夜の避難所',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D5F92),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '眠れない夜も、ここでは急がなくて大丈夫。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF55566F),
                ),
              ),
              const SizedBox(height: 36),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Text(
                  '夜は、考えごとが少し大きく見える時間。\n今は答えを出さなくていいよ。\nただ、体を横にして休ませてあげよう。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.7,
                    color: Color(0xFF4F5068),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
  onPressed: onBack,
  child: const Text('心の広場に戻る'),
),

            ],
          ),
        ),
      ),
    );
  }
}
class LunaHouseScreen extends StatelessWidget {
  final VoidCallback onBack;

  const LunaHouseScreen({
    super.key,
    required this.onBack,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Text(
                'ルナのおうち',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E7BBE),
                ),
              ),
              const SizedBox(height: 24),
              Image.asset(
                'assets/images/luna.png',
                height: 180,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Text(
                  'ルナはここで待っているよ。\n何かを話しても、何も話さなくても大丈夫。\n今日は少しだけ、そばで休もう。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.7,
                    color: Color(0xFF5F566B),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
  onPressed: onBack,
  child: const Text('心の広場に戻る'),
),

            ],
          ),
        ),
      ),
    );
  }
}

class SpeechBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

