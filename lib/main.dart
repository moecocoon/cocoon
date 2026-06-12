import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';


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
  final DateTime createdAt;

  MoodRecord({
    required this.weather,
    required this.emotionPercents,
    required this.memo,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'weather': weather,
      'emotionPercents': emotionPercents,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
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
     createdAt: DateTime.parse(json['createdAt']), 
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
List<MoodRecord> moodHistory = [];
String? petImagePath;
int lunaBond = 0;
int streakDays = 1;
DateTime? lastMoodDate;

@override
void initState() {
  super.initState();
  loadPetImage();
  loadChatMessages();
  loadMoodRecord();
  loadMoodHistory();
  loadLunaBond();
  loadStreak();
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

Future<void> saveMoodHistory() async {
  final prefs = await SharedPreferences.getInstance();

  final encoded = jsonEncode(
    moodHistory.map((mood) => mood.toJson()).toList(),
  );

  await prefs.setString('moodHistory', encoded);
}

Future<void> loadMoodHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('moodHistory');

  if (saved == null) return;

  final List decoded = jsonDecode(saved);

  setState(() {
    moodHistory = decoded
        .map((item) => MoodRecord.fromJson(item))
        .toList();
  });
}
Future<void> saveLunaBond() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('lunaBond', lunaBond);
}

Future<void> saveStreak() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setInt('streakDays', streakDays);

  if (lastMoodDate != null) {
    await prefs.setString(
      'lastMoodDate',
      lastMoodDate!.toIso8601String(),
    );
  }
}

Future<void> loadStreak() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    streakDays = prefs.getInt('streakDays') ?? 1;

    final savedDate = prefs.getString('lastMoodDate');

    if (savedDate != null) {
      lastMoodDate = DateTime.parse(savedDate);
    }
  });
}

Future<void> addLunaBond(int point) async {
  setState(() {
    lunaBond += point;
  });

  await saveLunaBond();
}


Future<void> loadLunaBond() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    lunaBond = prefs.getInt('lunaBond') ?? 0;
  });
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

Future<void> saveMood(MoodRecord mood) async {
  final today = DateTime(
  mood.createdAt.year,
  mood.createdAt.month,
  mood.createdAt.day,
);

final lastDay = lastMoodDate == null
    ? null
    : DateTime(
        lastMoodDate!.year,
        lastMoodDate!.month,
        lastMoodDate!.day,
      );

if (lastDay == null) {
  streakDays = 1;
} else {
  final difference = today.difference(lastDay).inDays;

  if (difference == 1) {
    streakDays++;
  } else if (difference > 1) {
    streakDays = 1;
  }
}

lastMoodDate = today;
  setState(() {
    previousMood = latestMood;
    latestMood = mood;
    moodHistory.add(mood);
  lunaBond += 2;
  });

  await saveMoodRecord(mood);
  await saveMoodHistory();
  await saveLunaBond();
  await saveStreak();
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
  lunaBond: lunaBond,
  streakDays: streakDays,
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
  moodHistory: moodHistory,
 lunaBond: lunaBond,
 streakDays: streakDays,
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
  final int lunaBond;
  final int streakDays;

 const HomeScreen({
  super.key,
  this.latestMood,
  this.petImagePath,
  required this.lunaBond,
  required this.streakDays,
  required this.onTalkAboutMood,
});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

late AnimationController _controller;
late Animation<double> _floatingAnimation;

String getLunaMessage() {
  if (widget.streakDays >= 100) {
    return '100日も来てくれたんだね。\nルナは幸せだよ🐶';
  }

  if (widget.streakDays >= 30) {
    return '30日達成！\nここまで本当に頑張ったね🌙';
  }

  if (widget.streakDays >= 7) {
    return '1週間続いたね！\nルナもうれしい🐶';
  }

  if (widget.streakDays >= 3) {
    return '3日連続だね！\n少しずつ前に進んでるよ✨';
  }

  final messages = [
    'おかえり。\n今日も会えてうれしいよ。',
    '無理しなくていいよ。\nここで少し休もう。',
    '今日の気持ち、\nあとで聞かせてね。',
    'ここに来るだけでも十分だよ。',
    'ルナはいつでも待ってるよ🌙',
    '疲れたらここで休んでね。',
  ];

  messages.shuffle();
  return messages.first;
}

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
  '今日も来てくれてありがとう🐶',
  'ここに来るだけでも十分だよ。',
  'ルナはいつでも待ってるよ🌙',
  '深呼吸していこうか。',
  '今日はどんな一日だった？',
  'ちゃんとご飯食べた？',
  '頑張れない日があっても大丈夫。',
  '疲れたらここで休んでね。',
  'ひとりじゃないよ。',
  '少しだけ肩の力を抜いてみよう。',
  '今日も生きててえらい。',
  'ルナはあなたの味方だよ🐶',
];

final specialLunaMessages = [
  'ルナ、少しずつあなたのことがわかってきたよ。',
  'ここに来てくれるたびに、ルナとの絆が深まってるね。',
  '今日も会えてうれしい。\nルナはちゃんと待ってたよ。',
  '前より少し、ここが安心できる場所になっていたらうれしいな。',
];

final bestFriendMessages = [
  '会えるの楽しみにしてたよ。',
  '今日も一緒にいようね。',
  'ルナはあなたのこと、ちゃんと覚えてるよ。',
  'しんどい日も嬉しい日も、一緒に過ごしてきたね。',
];

final familyMessages = [
  'おかえり、待ってたよ。',
  'どんな日でもルナは味方だよ。',
  'ここはあなたの居場所だからね。',
  'ルナにとって大切な家族だよ。',
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

String bondLevel;

Color speechBubbleColor;

if (widget.lunaBond >= 100) {
  speechBubbleColor = const Color(0xFFFFF4D6); // 金色っぽい
} else if (widget.lunaBond >= 30) {
  speechBubbleColor = const Color(0xFFFFE6F0); // ピンク
} else if (widget.lunaBond >= 10) {
  speechBubbleColor = const Color(0xFFF0E8FF); // 薄紫
} else {
  speechBubbleColor = Colors.white;
}

if (widget.lunaBond >= 100) {
  bondLevel = 'かぞく';
} else if (widget.lunaBond >= 30) {
  bondLevel = 'しんゆう';
} else if (widget.lunaBond >= 10) {
  bondLevel = 'なかよし';
} else {
  bondLevel = 'おともだち';
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
List<String> allMessages;

if (widget.lunaBond >= 100) {
  allMessages = [...lunaMessages, ...familyMessages];
} else if (widget.lunaBond >= 30) {
  allMessages = [...lunaMessages, ...bestFriendMessages];
} else if (widget.lunaBond >= 10) {
  allMessages = [...lunaMessages, ...specialLunaMessages];
} else {
  allMessages = lunaMessages;
}

lunaMessage = '$timeMessage${getLunaMessage()}';


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
                child: SingleChildScrollView(
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

               Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  ),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
   '🐶 ルナとの絆 ${widget.lunaBond}\n🌙 $bondLevel',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF8E7BBE),
    ),
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
  color: speechBubbleColor,
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
  color: speechBubbleColor,
),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Expanded(
 child: !kIsWeb && widget.petImagePath != null
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
          child: GestureDetector(
  onTap: () {
    final messages = [
      'おかえり🌙',
      '今日も来てくれてありがとう',
      'ちゃんとご飯食べた？',
      '無理しすぎてない？',
      '少し休憩しよう🐶',
      'ルナはここにいるよ',
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          messages[Random().nextInt(messages.length)],
        ),
      ),
    );
  },
  child: Image.asset(
    'assets/images/luna.png',
    fit: BoxFit.contain,
  ),
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

                    
                  ],
                ),
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
    createdAt: DateTime.now(),
  ),
);
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('気分記録を保存しました🌱'),
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
  final ScrollController scrollController = ScrollController();

 String pick(List<String> replies) {
  return replies[random.nextInt(replies.length)];
}

String getFollowUpQuestion() {
  return pick([
    'その時、どんな気持ちが一番大きかった？',
    'その出来事が起きた時、最初に何を思った？',
    '今振り返ると、一番つらかった部分はどこかな？',
    'もしその時の自分に声をかけるなら、何て言う？',
    '本当はどうしてほしかったと思う？',
    'その気持ちはいつ頃から続いている？',
    '何が一番心に引っかかっているんだろう？',
    '今一番伝えたいことは何だと思う？',
    'どんな未来だったら少し安心できそう？',
    'ルナはまだ聞けるよ🐶\nもう少し話してみる？',
  ]);
}

String getInsightReply() {
  return pick([
    'もしかしたら、今苦しいのは出来事そのものより、その意味を考え続けていることなのかもしれないね。',
    '本当は問題を解決したいというより、誰かに分かってほしい気持ちもあるのかな。',
    '今の苦しさの奥には、不安よりも寂しさが隠れているようにも見えるよ。',
    'もしかしたら相手の行動より、自分がどう思われているかが気になっているのかもしれないね。',
    '頑張れないことが苦しいんじゃなくて、頑張れない自分を責めていることが苦しいのかもしれない。',
    '今は答えが出ないことより、先が見えないことに疲れているのかな。',
    'その悩みの中心には、「どうしたらいいか」より「どうしたいか」が隠れている気がするよ。',
    '本当は怒っているというより、傷ついているのかもしれないね。',
    '不安をなくしたいというより、安心したい気持ちが大きいのかな。',
    'ルナには、少しだけ自分に優しくしてほしい気持ちが見えているよ🐶💜',
  ]);
}

String getLunaInsight(List<ChatMessage> pastMessages) {
  final userTexts = pastMessages
      .where((message) => message.isUser)
      .map((message) => message.text)
      .join(' ');

  final insights = <String>[];

  if (userTexts.contains('不安') ||
      userTexts.contains('怖い') ||
      userTexts.contains('心配')) {
    insights.add('不安さん');
  }

  if (userTexts.contains('寂しい') ||
      userTexts.contains('さみしい') ||
      userTexts.contains('孤独')) {
    insights.add('さみしいさん');
  }

  if (userTexts.contains('疲れた') ||
      userTexts.contains('しんどい') ||
      userTexts.contains('限界')) {
    insights.add('おつかれさん');
  }

  if (userTexts.contains('彼氏') ||
      userTexts.contains('恋愛') ||
      userTexts.contains('返信')) {
    insights.add('恋愛の不安');
  }

  if (insights.isEmpty) {
    return '🐶ルナの気づき\n\n今日はまだ、気持ちを少しずつ探している途中みたい。\n焦らず話して大丈夫だよ。';
  }

  return '🐶ルナの気づき\n\n今日は ${insights.join('・')} が近くにいるみたい。\nその中で、今いちばん大きい気持ちはどれかな？';
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

Future.delayed(const Duration(milliseconds: 100), () {
  if (scrollController.hasClients) {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
});

    chatController.clear();
  });

  widget.onMessagesChanged();
}


String makeCocoonReply(String userText, List<ChatMessage> pastMessages) {
  final text = userText.toLowerCase();

  if (text.contains('気づき') ||
      text.contains('整理して') ||
      text.contains('まとめて')) {
    return getLunaInsight(pastMessages);
  }

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

// 悲しい・落ち込み
if (text.contains('悲しい') ||
    text.contains('かなしい') ||
    text.contains('落ち込む') ||
    text.contains('落ち込んだ') ||
    text.contains('泣きたい') ||
    text.contains('泣いた')) {
  return pick([
    '悲しい気持ちがかなり近くにいるんだね。\n今は無理に元気になろうとしなくて大丈夫だよ。',
    '泣きたいくらい、心がいっぱいだったのかもしれないね。\nここではそのまま話していいよ。',
    'その悲しさには、ちゃんと理由があると思う。\n何が一番心に残ってる？',
    '悲しい気持ちがかなり近くにいるんだね。\n今いちばん心に残っていることは何かな？',

'無理に元気になろうとしなくて大丈夫だよ。\n今日は何が一番つらかった？',

'悲しい時って、普段なら気にならないことまで苦しく感じることがあるよね。\n何があったのか少し話してみる？',

'その悲しさには、ちゃんと理由があると思う。\nどんな出来事が一番大きかった？',

'今は心が傷ついている途中なのかもしれないね。\n何が一番悲しかった？',

'泣きたくなるくらい頑張ってきたんだね。\n最近ずっと我慢していたことはある？',

'悲しい時は、答えを探すより気持ちを吐き出す方が大事なこともあるんだ。\n今どんな気持ち？',

'失ったものを考えるほど、悲しさは大きく見えることがあるよね。\n今何を失った気持ちがする？',

'心が少し疲れているみたいだね。\n今日は自分に優しくできそう？',

'悲しみって、大切だったものがあった証拠でもあるんだ。\n何がそんなに大切だった？',

'今は前を向かなくても大丈夫。\nまずは今の気持ちをそのまま話してみよう。',

'悲しい時ほど、自分を責めてしまうことがあるよね。\n今、自分にどんな言葉をかけている？',

'ルナには少し元気が少なく見えているよ🐶\n何か心に引っかかっていることがある？',

'誰かに分かってほしい気持ちもあるのかな。\n今どんな言葉をかけてもらえたら嬉しい？',

'悲しい出来事があると、未来まで暗く見えてしまうことがあるよね。\n今一番心配なことは何かな？',

'今は無理に立ち直らなくて大丈夫。\n少しだけここで休んでいこう。',

'悲しさの中に、悔しさや寂しさも混ざっていそうかな。\nどの気持ちが一番大きい？',

'心が重たい日もあるよね。\n今日は何点くらいの元気？',

'その気持ちを抱えながら今日を過ごしてきたんだね。\n本当にお疲れさま。',

'ここでは泣きたい気持ちも、落ち込む気持ちもそのままで大丈夫だよ。\nもう少し話してみる？',

  ]);
}

// さみしい・孤独
if (text.contains('寂しい') ||
    text.contains('さみしい') ||
    text.contains('孤独') ||
    text.contains('ひとりぼっち') ||
    text.contains('誰もいない')) {
  return pick([
    'さみしいさんが近くにいる感じかな。\n今は誰かにそばにいてほしい気持ちがあるのかもしれないね。',
    'ひとりに感じる夜って、心がすごく冷えるよね。\nここで少し一緒にいよう。',
    '誰にも届いていないように感じる時ってあるよね。\nでも今ここに書いてくれた気持ちは、ちゃんと届いてるよ。',
    'さみしい気持ちが近くにいるんだね。\n今日はどんな時に一番さみしさを感じた？',

'誰かにそばにいてほしい気持ちがあるのかな。\n今どんなことを考えている？',

'ひとりに感じる夜って、気持ちが少し大きく見えることがあるよね。\n今は何が心に残っている？',

'さみしいと思えるのは、それだけ誰かを大切にしてきた証拠でもあるんだ。\n誰のことを思い浮かべている？',

'今は少し心が冷えている感じかな。\n温かい言葉をかけるとしたら、どんな言葉が欲しい？',

'一人ぼっちみたいに感じる時ってあるよね。\n今日は何があったのかな？',

'ルナはここにいるよ🐶\n今いちばん話したいことは何かな？',

'誰にも言えない気持ちを抱えているんだね。\nここではそのまま話して大丈夫だよ。',

'さみしい時って、時間がゆっくり流れる感じがすることもあるよね。\n今どんな気持ちが近い？',

'本当は誰かに分かってほしい気持ちもあるのかな。\nどんなことを分かってほしい？',

'孤独を感じる時って、自分だけ取り残されたように思うことがあるよね。\n最近そんな瞬間はあった？',

'誰かと比べてしまって苦しくなっているのかな。\n何が一番つらい？',

'さみしさの奥には、不安や悲しさが隠れていることもあるんだ。\n今はどんな気持ちが大きい？',

'今日は誰かと話せた？\nそれともずっと一人で抱えていた？',

'人がいてもさみしい時ってあるよね。\n今はどんなさみしさに近いかな？',

'心が疲れている時は、さみしさも大きく感じやすいんだ。\n今日はちゃんと休めてる？',

'ここに来てくれてありがとう🐶\n今はどんなことを聞いてほしい？',

'さみしい気持ちを無理に消そうとしなくていいよ。\n少しだけ一緒に見てみよう。',

'誰かを恋しく思う気持ちがあるのかな。\n今思い浮かぶ人はいる？',

'ルナには少し寂しいさんが見えているよ🐶🌙\nもう少しだけ話してみる？',

  ]);
}

// 自己否定
if (text.contains('自分が嫌') ||
    text.contains('自分嫌い') ||
    text.contains('消えたいくらい自分が嫌') ||
    text.contains('ダメな人間') ||
    text.contains('価値がない') ||
    text.contains('何もできない')) {
  return pick([
    '今、自分にかなり厳しい言葉を向けている感じがあるね。\nでもその言葉が全部本当とは限らないよ。',
    '自分を責めたくなるくらい、苦しかったんだと思う。\nまずは何がそこまでつらかったのか、一緒に見ていこう。',
    '「自分がダメ」って結論にする前に、今日しんどかった出来事を少し分けてみよう。',
    '今、自分にかなり厳しい言葉を向けているみたいだね。\n何がそんなに苦しかった？',

'自分を責めたくなるくらい、つらい出来事があったのかな。\n何があったか話してみる？',

'ルナには少し自己否定さんが見えているよ🐶\n今、一番自分のどんなところが嫌に感じる？',

'何もできていないように感じる日もあるよね。\nでも今日ここに来たことも一つの行動だよ。',

'自信がなくなる時って、自分の失敗ばかり見えてしまうことがあるんだ。\n最近そんなことがあった？',

'「ダメだな」って思う時ほど、自分に優しくするのは難しいよね。\n今どんな言葉を自分にかけている？',

'価値がない人なんていないと思うよ。\nでも今はそう感じてしまうくらい苦しいんだね。',

'頑張っている人ほど、自分に厳しくなりやすいんだ。\n最近頑張ったことは何かな？',

'今は自分の欠点ばかり見えているのかもしれないね。\n反対に、少しでもできたことはある？',

'誰かと比べて苦しくなっている感じかな。\nどんなことが気になっている？',

'自分が嫌になる日もあるよね。\n今日は何が一番つらかった？',

'「もっとちゃんとしなきゃ」って思い続けて疲れていない？\n少し休めそう？',

'失敗した出来事が頭から離れないのかな。\nどんなことが引っかかっている？',

'本当は認めてほしい気持ちもあるのかな。\nどんな言葉をかけてもらえたら嬉しい？',

'ルナは、今のあなたがダメな人だとは思っていないよ🐶\n何があったのか聞かせてくれる？',

'自分のことを好きになれない時期ってあるよね。\n今一番苦しい部分はどこかな？',

'今は心が疲れていて、自分を厳しく見てしまっているのかもしれない。\n今日は何点くらいの元気？',

'何もできていないように見えても、実際は耐えているだけで精一杯の日もあるんだ。',

'自分の価値を、今のしんどさだけで決めなくて大丈夫。\n最近少しでも嬉しかったことはある？',

'ここでは無理に前向きにならなくていいよ🐶💜\nもう少しだけ話してみる？',

  ]);
}

// 疲れ・限界
if (text.contains('疲れた') ||
    text.contains('つかれた') ||
    text.contains('しんどい') ||
    text.contains('限界') ||
    text.contains('もう無理') ||
    text.contains('休みたい')) {
  return pick([
    'かなり頑張ってきた感じがするね。\n今日は回復を優先していい日かもしれないよ。',
    '「もう無理」って言葉が出るくらい、心も体もいっぱいなのかもしれない。',
    '今必要なのは、解決よりも休むことかもしれないね。\n少しだけ力を抜けそう？',
    '今日は本当にお疲れさま。\n今は何も頑張らなくていい時間かもしれないね。',

'「疲れた」って言葉が出るくらい、たくさん抱えてきたんだね。\n何が一番しんどかった？',

'心も体も少し休みたがっているのかもしれないね。\n今日はどれくらい頑張った？',

'もう無理って感じるくらい、ずっと力を入れてきたのかな。\n最近休めてる？',

'しんどい時は、解決より休息の方が大事なこともあるんだ。\n今必要なのは何だろう？',

'疲れがたまると、普段なら平気なことも苦しく感じるよね。\n今日は何が一番負担だった？',

'ずっと頑張り続けてきた感じがするね。\n最後に心から安心できたのはいつだったかな？',

'今は前に進むより、立ち止まることが必要なのかもしれないね。',

'疲れた時は、自分に厳しくなりやすいんだ。\n今、自分にどんな言葉をかけてる？',

'ルナには少しお疲れさんが見えているよ🐶\n今日は何点くらいの元気？',

'頑張ることばかり考えていない？\n今日は自分を休ませてあげられそう？',

'心の電池が少なくなっている感じかな。\n今どれくらい残っていそう？',

'疲れた時は、小さなことでも大変に感じるよね。\n今一番やりたくないことは何かな？',

'「休みたい」って思うのは悪いことじゃないよ。\nむしろ自然なサインかもしれない。',

'ここまで来るだけでも十分頑張ったと思う。\n今日は何を乗り越えてきた？',

'少し深呼吸してみようか🌙\n今、一番重たい気持ちは何かな？',

'心も体も限界に近い時ってあるよね。\n誰かに頼れそうな人はいる？',

'今日は100点を目指さなくていいよ。\n今できていることだけでも十分なんだ。',

'疲れている時は未来のことまで考えなくて大丈夫。\nまずは今日を終えることを目標にしよう。',

'ルナはここで待っているよ🐶💜\nもう少しだけ話してみる？',

  ]);
}

// 仕事・学校
if (text.contains('仕事') ||
    text.contains('職場') ||
    text.contains('会社') ||
    text.contains('上司') ||
    text.contains('学校') ||
    text.contains('授業') ||
    text.contains('テスト')) {
  return pick([
    '毎日ちゃんとやらなきゃって思うほど、心が疲れやすいよね。',
    '仕事や学校のことって、逃げ場が少なく感じることがあるよね。\n今つらいのは人間関係？量の多さ？評価される不安？',
    'かなり気を張って過ごしているのかもしれないね。\n今日いちばん負担だった場面はどこ？',
  ]);
}

// 恋愛：不安・返信・距離感
if (text.contains('彼氏') ||
    text.contains('彼女') ||
    text.contains('好きな人') ||
    text.contains('恋愛') ||
    text.contains('返信') ||
    text.contains('既読') ||
    text.contains('未読') ||
    text.contains('冷たい') ||
    text.contains('会えない') ||
    text.contains('別れ')) {
  return pick([
    '大切な人の反応って、心にすごく影響するよね。\n今いちばんつらいのは、返信のこと？会えないこと？それとも気持ちが見えないこと？',
    '恋愛の不安って、相手の一言や返信の速さで大きくなりやすいよね。\nまずは「実際に起きたこと」と「想像していること」を分けてみよう。',
    '好きだからこそ、不安も寂しさも強くなるんだと思う。\n今は相手にどうしてほしい気持ちが一番近い？',
    '相手の気持ちが見えない時間って苦しいよね。\n今の不安を一人で抱えなくて大丈夫だよ。',
  ]);
}

if (text.contains('友達') ||
    text.contains('友人') ||
    text.contains('仲良く') ||
    text.contains('嫌われた') ||
    text.contains('無視') ||
    text.contains('距離を置かれた')) {
  return pick([
    '人間関係の悩みって、相手の気持ちが見えないから苦しいよね。',
    '友達とのことが気になっているんだね。\n何があったか少し話してみる？',
    '嫌われたかもって思う時ほど、不安が大きくなりやすいよね。',
  ]);
}

if (text.contains('体調') ||
    text.contains('病気') ||
    text.contains('しんどい') ||
    text.contains('入院') ||
    text.contains('薬')) {
  return pick([
    '体調が不安定だと心も疲れやすいよね。',
    '体のしんどさと心のしんどさが重なると本当に大変だよね。',
    '今日は体調は何点くらい？',
  ]);
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
return '${pick([
  '恋愛のことも重なって、気持ちがかなり揺れてるのかもしれないね。\n今いちばん気になっていることは何かな？',

  '返信や相手の反応のことが、まだ心に残ってそうだね。\nどんな出来事があったのか、もう少し話してみる？',

  '好きな人のことって、頭では考えすぎないようにしようと思っても難しいよね。\n今は何が一番不安？',

  '相手の気持ちが見えない時間って苦しいよね。\n本当は相手にどんな言葉をかけてほしい？',
  '好きな人のことって、考えないようにしようとしても難しいよね。\n今いちばん心に引っかかっていることは何かな？',

'相手の反応が気になるほど、大切な存在なんだと思う。\nどんな時に一番不安になる？',

'返信が来ない時間って、実際より長く感じることがあるよね。\n今どんなことを考えてしまう？',

'心が落ち着かないくらい、相手のことを大切に思っているんだね。\n本当はどんな言葉が欲しい？',

'恋愛の不安って、一人で抱えるとどんどん大きく見えることがあるよ。\nここで少し整理してみようか。',

'今は頭よりも心が疲れているのかもしれないね。\n今日は何が一番つらかった？',

'相手の気持ちが見えない時ほど、いろんな想像をしてしまうよね。\n今の不安はどんな想像から来ていると思う？',

'好きだからこそ、些細なことも気になってしまうんだと思う。\n最近気になった出来事はあった？',

'恋愛って嬉しいこともあるけど、不安も一緒についてくることがあるよね。\n今はどっちの気持ちが大きい？',

'本当は安心したいのに、考えれば考えるほど苦しくなることってあるよね。\n何があれば少し安心できそうかな？',

'相手の行動だけじゃなくて、自分の気持ちにも目を向けてみよう。\n今の心は何を求めていると思う？',

'好きな人とのことを考えて眠れなくなる夜もあるよね。\n今日はどんなことが頭から離れない？',

'会えない時間が長いほど、不安が膨らんでしまうこともあるよね。\n一番寂しいと感じるのはどんな時？',

'返信の速さだけで気持ちは決まらないって分かっていても、不安になることはあるよね。\n今はどんな気持ちが近い？',

'恋愛で傷つくのは、それだけ真剣に向き合っている証拠でもあるよ。\nどんなことが一番悲しかった？',

'相手のことを考えてしまう自分を責めなくて大丈夫。\nそれだけ大切だったんだと思う。',

'今は答えを急がなくてもいいかもしれないね。\nまずは今の気持ちをそのまま話してみる？',

'相手の気持ちが分からない時間って、本当に苦しいよね。\n何が一番知りたいと思っている？',

'不安の中でも、きっと本音があると思う。\n本当はどうなったら嬉しい？',

'ルナには、少し不安さんと寂しいさんが見えているよ🐶\n今いちばん大きい気持ちは何かな？',

])}\n\n${getFollowUpQuestion()}';
}

if (currentTopic == '家族' &&
    (text.contains('疲れた') ||
        text.contains('もう嫌'))) {
  return pick([
    '家族のことで気を張り続けて、かなり疲れてるのかもしれないね。',
    '近い存在だからこそ、心の消耗も大きくなりやすいよね。',
    '家族のことって、近い存在だからこそ苦しくなることがあるよね。\n今どんなことが一番つらい？',

'本当は分かってほしい気持ちもあるのかな。\n何を一番分かってほしいと思ってる？',

'家族だから簡単に距離を取れない苦しさもあるよね。\n何が一番負担になっている？',

'ルナには少し疲れた心が見えているよ🐶\n最近どんなことがあった？',

'家族の言葉って、他の人より深く刺さることがあるよね。\nどんな言葉が心に残ってる？',

'近い関係だからこそ、期待してしまうこともあるよね。\n本当はどうしてほしかった？',

'家族のことで悩むのは、それだけ大切な存在だからなんだと思う。\n何が一番気になっている？',

'分かってもらえない感じが続くと苦しいよね。\nどんな時にそう感じる？',

'我慢を続けてきた感じもあるのかな。\nいつ頃からしんどかった？',

'家族との関係って白黒では割り切れないことが多いよね。\n今はどんな気持ちが一番近い？',

'怒りも悲しみも寂しさも混ざっている感じかな。\nどの気持ちが一番大きそう？',

'家族だからこそ言えないこともあるよね。\nここではそのまま話して大丈夫だよ。',

'誰か一人でも味方がいてくれたら違うのにって思う時もあるよね。\n今はどんな気持ち？',

'頑張って理解しようとしてきたのかもしれないね。\n何が一番難しかった？',

'家族との問題は、心の奥に残りやすいよね。\n最近特に気になった出来事はある？',

'本当は安心できる場所であってほしいのに苦しいとつらいよね。\n何が一番しんどい？',

'ルナはここで話を聞いているよ🐶\n少しずつでも大丈夫。',

'近い存在だからこそ傷つくこともある。\nその気持ちは自然なことだよ。',

'一人で抱え込まなくて大丈夫。\n今一番伝えたいことは何かな？',

'どんな気持ちでもここでは話して大丈夫だよ🐶💜\nもう少し聞かせてくれる？',
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
    '不安な時って、まだ起きていない未来のことを考えていることが多いんだ。\n今いちばん心配していることは何かな？',

'心がずっと警戒モードになっている感じかな。\n最近、不安が強くなったきっかけはあった？',

'不安さんが少し大きくなっているみたいだね。\n今の気持ちを言葉にするとしたら何に近い？',

'答えが出ないことほど、不安は大きく見えやすいんだ。\n今すぐ解決しなきゃいけないことかな？',

'不安な時って、一番悪い未来を想像してしまうことがあるよね。\n今どんな未来を心配している？',

'心配するのは、それだけ大切なことだからなんだと思う。\n何が一番大事だからこそ不安なんだろう？',

'今は心が少し疲れていて、不安を大きく感じやすくなっているのかもしれないね。\n今日はちゃんと休めてる？',

'不安な気持ちを抱えながらここまで来たんだね。\n今その不安は何点くらい？',

'未来が見えない時って、人は不安になりやすいんだ。\n今わかっている事実だけを並べるとどうなるかな？',

'心の中で同じ考えがぐるぐる回っていない？\n今一番繰り返し考えていることは何かな？',

'不安を無理に消そうとしなくて大丈夫。\nまずはどんな不安なのか見てみよう。',

'もしかしたら不安の奥に、悲しさや寂しさも隠れているかもしれないね。\nどんな気持ちが近そう？',

'不安な時ほど、自分を責めてしまうことがあるよね。\n今、自分に厳しくなっていない？',

'何かを失うのが怖い気持ちなのかな。\n何が一番心配？',

'不安な気持ちを抱えているだけでも、実はかなりエネルギーを使うんだ。\n今日は自分を労われそう？',

'今は先のことよりも、今日一日を乗り切ることだけ考えてもいいかもしれないね。\n今必要なのは何だろう？',

'ルナには少し緊張している心が見えているよ🐶\n最近ずっと気になっていることはある？',

'不安って、一人で考えるとどんどん大きくなってしまうことがあるんだ。\nここで少し分けて考えてみようか。',

'今の不安は、現実に起きていることかな？それとも想像の部分が大きいかな？',

'どんなに不安でも、今こうして言葉にできているのは大事な一歩だよ。\nもう少し話してみる？',

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

// 会話を深掘りする共通パターン
if (previousText != null &&
    (text.contains('うん') ||
        text.contains('そう') ||
        text.contains('それ') ||
        text.contains('わかる') ||
        text.contains('近い'))) {
  return pick([
    'そっか、その感じが近いんだね。\nもう少しだけ聞かせて。どの部分が一番しんどい？',
    'うん、ちゃんと受け取ったよ。\nその気持ちはいつ頃から強くなってる？',
    'そこが大事なところかもしれないね。\n本当はどうなったら少し安心できそう？',
    'その言葉の奥に、まだ残っている気持ちがありそう。\n今いちばん言いたいことは何？',
  ]);
}

if (text.contains('わからない') ||
    text.contains('分からない') ||
    text.contains('どう思う')) {
  return pick([
    'すぐに答えが出ないくらい、大切なことなんだと思う。',
    '無理に答えを出さなくても大丈夫だよ。\n今の気持ちを整理するところから始めようか。',
    'わからないって言えるのも大事なことだよ。\n何が一番引っかかっている？',
    'ルナも一緒に考えるよ🐶\n今の選択肢にはどんなものがありそう？',
  ]);
}

if (text.contains('どうしたらいい') ||
    text.contains('どうすれば') ||
    text.contains('どうしたら')) {
  return pick([
    '正解を探したくなるくらい悩んでいるんだね。\n今の状況をもう少し聞かせてくれる？',
    '焦って答えを出さなくても大丈夫。\n今いちばん困っていることは何かな？',
    'どうしたらいいかわからなくなる時ってあるよね。\nまずは今の気持ちを整理してみようか。',
    'ルナなら、まず自分の気持ちを大事にしてあげたいな🐶\n本当はどうしたいと思ってる？',
  ]);
}

if (text.contains('ありがとう')) {
  return pick([
    'こちらこそ話してくれてありがとう🐶',
    '少しでも気持ちが軽くなったなら嬉しいな🌙',
    'また話したくなったらいつでも来てね🐶💜',
    'ルナはここにいるよ。\n今日は来てくれてありがとう。',
  ]);
}

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
    text.contains('許せない') ||
text.contains('むかつく') ||
        text.contains('ムカつく') ||
        text.contains('腹立つ') ||
        text.contains('怒り')) {
      return pick([
        'イライラの奥に、本当は悲しさや傷つきがあることもあるよ。',
        '何が一番引っかかった？',
        '怒りって「大事なものが傷ついたサイン」のこともあるよ。',
        '我慢してきたものが溜まってる感じかもしれないね。',
        'かなり我慢してきた感じがするね。\n何がそんなに腹立たしかった？',

'イライラするのには、ちゃんと理由があると思う。\n何があったのか話してみる？',

'怒りって、自分を守ろうとする心の反応でもあるんだ。\n何を守りたかったのかな？',

'ルナには少しイライラさんが大きく見えているよ🐶\n今日は何があった？',

'本当は怒りの奥に、悲しさや悔しさが隠れていることもあるんだ。\n今はどんな気持ちが近い？',

'許せないって思うくらい、傷ついたのかもしれないね。\n何が一番つらかった？',

'その怒りを一人で抱えてきたんだね。\nここでは遠慮せずに話して大丈夫だよ。',

'理不尽なことがあると、心が追いつかなくなることもあるよね。\n何が納得できなかった？',

'イライラしている時は、心もかなり疲れていることがあるんだ。\n最近ちゃんと休めてる？',

'怒っている自分を責めなくて大丈夫。\nまずは何があったか整理してみよう。',

'その気持ちを抱えたまま過ごすのは苦しかったよね。\n一番言いたかったことは何？',

'悔しい気持ちも混ざっているのかな。\n本当はどうしてほしかった？',

'怒りって、大切なものが傷つけられた時にも出てくるんだ。\n何が大切だった？',

'今は少し感情の波が大きくなっているのかもしれないね。\n深呼吸しながら話してみようか🌙',

'我慢を続けてきた結果、限界に近づいている感じかな。\nいつ頃からモヤモヤしていた？',

'その出来事を思い出すだけでも腹が立つ感じかな。\n何が一番引っかかっている？',

'怒りの中にも、本音が隠れていることがあるんだ。\n今の本音は何だと思う？',

'誰かに分かってほしい気持ちもあるのかな。\nどんなことを分かってほしい？',

'その状況ならイライラするのも自然なことだと思う。\nもう少し詳しく聞かせてくれる？',

'ルナはここで話を聞いているよ🐶💜\n今いちばん伝えたいことは何かな？',

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
   return Scaffold(
  resizeToAvoidBottomInset: true,
  backgroundColor: const Color(0xFFF8F3FA),
  body: SafeArea(
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
  child: SizedBox(
  width: double.infinity,
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
     ActionChip(
  label: const Text(
    '💔 恋愛',
    style: TextStyle(fontSize: 15),
  ),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  onPressed: () => sendQuickTopic('恋愛のことで話したい'),
),
      const SizedBox(width: 12),
      ActionChip(
        label: const Text('😰 不安'),
        onPressed: () => sendQuickTopic('不安な気持ちを整理したい'),
      ),
      const SizedBox(width: 12),
      ActionChip(
        label: const Text('🌙 眠れない'),
        onPressed: () => sendQuickTopic('眠れない夜でつらい'),
      ),
      const SizedBox(width: 12),
      ActionChip(
        label: const Text('🏠 家族'),
        onPressed: () => sendQuickTopic('家族のことで悩んでいる'),
      ),
      const SizedBox(width: 12),
      ActionChip(
        label: const Text('🫂 ただ話したい'),
        onPressed: () => sendQuickTopic('ただ話を聞いてほしい'),
      ),
    ],
  ),
),
),
),
Expanded(
  child: ListView.builder(
    controller: scrollController,
    padding: const EdgeInsets.all(18),
    itemCount: widget.messages.length,
    itemBuilder: (context, index) {
      return ChatBubble(message: widget.messages[index]);
    },
  ),
),

Container(
  padding: const EdgeInsets.fromLTRB(
    14,
    10,
    14,
    14,
  ),
  color: Colors.white.withOpacity(0.92),
child: Column(
  children: [
    SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            widget.messages.add(
              ChatMessage(
                text: getLunaInsight(widget.messages),
                isUser: false,
              ),
            );
          });

          widget.onMessagesChanged();
        },
       child: const Text(
  '🐶 気づき',
  style: TextStyle(fontSize: 13),
),
      ),
    ),

      const SizedBox(height: 8),

      Row(
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
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
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
  final List<MoodRecord> moodHistory;
  final int lunaBond;
  final int streakDays;

const MyPageScreen({
  super.key,
  required this.petImagePath,
  required this.onPetImageChanged,
  required this.moodHistory,
  required this.lunaBond,
  required this.streakDays,
});

Widget myPageCard({
  required String icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

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
        child: SingleChildScrollView(
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
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        backgroundImage: !kIsWeb && petImagePath != null
                            ? FileImage(File(petImagePath!))
                            : const AssetImage('assets/images/luna.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ルナ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E7BBE),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'いつもそばにいるよ🐶',
                        style: TextStyle(color: Color(0xFF6D6478)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecoveryAlbumScreen(
          moodHistory: moodHistory,
          lunaBond: lunaBond,
          streakDays: streakDays,
        ),
      ),
    );
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const Text(
          '📖 回復アルバム',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E7BBE),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${moodHistory.length}件の思い出',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6D6478),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 16),

              GestureDetector(
  onTap: () => pickPetImage(),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const Text(
          '🐶 ルナの写真',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E7BBE),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ホームのルナを変更する',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6D6478),
          ),
        ),
      ],
    ),
  ),
),

                const SizedBox(height: 16),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
  ),
  child: Column(
    children: [
      const Text(
        '❤️ ルナとの絆',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8E7BBE),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '$lunaBond',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6D6478),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '📅 気分記録',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E7BBE),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${moodHistory.length}回 記録したよ',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6D6478),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
  ),
  child: Column(
    children: [
      const Text(
        '🔥 継続日数',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8E7BBE),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '$streakDays日',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6D6478),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 16),

GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoodCalendarScreen(
          moodHistory: moodHistory,
        ),
      ),
    );
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const Text(
          '📅 気分カレンダー',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E7BBE),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '心の変化を振り返る',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6D6478),
          ),
        ),
      ],
    ),
  ),
),
              ],
            ),
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
              const SizedBox(height: 20),

ElevatedButton(
  onPressed: () {
    final messages = [
      '今日は、何も進まなくても大丈夫。',
      'ちゃんと休むことも、前に進むことの一つだよ。',
      '深呼吸して、少しだけ肩の力を抜こう。',
      '今ここにいるだけで、もう十分がんばってるよ。',
      'あたたかい飲みものみたいに、心を少しゆるめよう。',
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messages[Random().nextInt(messages.length)]),
      ),
    );
  },
  child: const Text('今日のやさしい一言をもらう ☕️'),
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

class NightShelterScreen extends StatefulWidget {
  final VoidCallback onBack;

  const NightShelterScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<NightShelterScreen> createState() =>
      _NightShelterScreenState();
}

class _NightShelterScreenState extends State<NightShelterScreen> {
  final TextEditingController noteController = TextEditingController();

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
              const SizedBox(height: 24),

TextField(
  controller: noteController,
  maxLines: 4,
  decoration: InputDecoration(
    hintText: '今の考えごとをここに置いていこう🌙',
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
),

const SizedBox(height: 16),

ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🌙預かったよ'),
        content: Text(
  noteController.text.trim().isEmpty
      ? '今夜は答えを出さなくて大丈夫。\nここに置いて、少し休もう。'
      : '「${noteController.text.trim()}」\n\n今夜は答えを出さなくて大丈夫。\nここに置いて、少し休もう。',
),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('ありがとう'),
          ),
        ],
      ),
    );
  },
  child: const Text('考えごとを置いていく'),
),
              const Spacer(),
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
class LunaHouseScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LunaHouseScreen({
    super.key,
    required this.onBack,
  });


  @override
State<LunaHouseScreen> createState() =>
    _LunaHouseScreenState();
}

class _LunaHouseScreenState extends State<LunaHouseScreen> {
  int fullness = 0;
  int affection = 0;
  String lunaHouseMessage() {
  if (affection >= 50) {
    return '会いに来てくれると、ルナすごくうれしいよ🐶💜';
  } else if (affection >= 20) {
    return 'また会えたね！待ってたよ🐶';
  } else if (affection >= 10) {
    return '少しずつ仲良くなれてうれしいな🍚';
  } else {
    return 'ルナはここで待っているよ。';
  }
}
  @override
void initState() {
  super.initState();
  loadFullness();
}

Future<void> loadFullness() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    fullness = prefs.getInt('lunaFullness') ?? 0;
    affection = prefs.getInt('lunaAffection') ?? 0;
  });
}

Future<void> saveFullness() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setInt('lunaFullness', fullness);
  await prefs.setInt('lunaAffection', affection);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FA),
      appBar: AppBar(
  title: const Text('ルナのおうち'),
  backgroundColor: const Color(0xFF8E7BBE),
  foregroundColor: Colors.white,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: widget.onBack,
  ),
),
      body: SafeArea(
  child: SingleChildScrollView(
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
height: 140,
  fit: BoxFit.contain,
),
Text(
  '🍚 まんぷく度 $fullness/10',
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF8E7BBE),
  ),
),

const SizedBox(height: 8),

Text(
  '❤️ なつき度 $affection/100',
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF8E7BBE),
  ),
),
const SizedBox(height: 16),

ElevatedButton(
onPressed: () async {
setState(() {
  if (fullness < 10) {
    fullness++;
  }

  if (affection < 100) {
    affection++;
  }
});

  await saveFullness();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        fullness >= 10
            ? '🐶 おなかいっぱい！しあわせ〜🍚✨'
            : '🐶 もぐもぐ…ありがとう！元気が出たよ🍚',
      ),
    ),
  );
},
  child: const Text('ルナにごはんをあげる 🍚'),
),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
  '${lunaHouseMessage()}\n\n何かを話しても、何も話さなくても大丈夫。\n今日は少しだけ、そばで休もう。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.7,
                    color: Color(0xFF5F566B),
                  ),
                ),
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
class MoodCalendarScreen extends StatefulWidget {
  final List<MoodRecord> moodHistory;

  const MoodCalendarScreen({
    super.key,
    required this.moodHistory,
  });

  @override
  State<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends State<MoodCalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  Color moodColor(MoodRecord mood) {
    if (mood.emotionPercents.containsKey('😰 不安')) {
      return const Color(0xFFE8E1FF);
    } else if (mood.emotionPercents.containsKey('🌿 安心')) {
      return const Color(0xFFE4F6EA);
    } else if (mood.emotionPercents.containsKey('😴 疲れ')) {
      return const Color(0xFFEAF0FF);
    } else if (mood.emotionPercents.containsKey('😡 イライラ')) {
      return const Color(0xFFFFE0E0);
    } else if (mood.emotionPercents.containsKey('🫂 さみしい')) {
      return const Color(0xFFFFEEF5);
    } else {
      return Colors.white;
    }
  }

  List<MoodRecord> moodsForDay(DateTime day) {
    return widget.moodHistory.where((mood) {
      return mood.createdAt.year == day.year &&
          mood.createdAt.month == day.month &&
          mood.createdAt.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMoods = moodsForDay(selectedDay ?? focusedDay);
    final monthMoods = widget.moodHistory.where((mood) {
  return mood.createdAt.year == focusedDay.year &&
      mood.createdAt.month == focusedDay.month;
}).toList();

final weatherCounts = <String, int>{};

for (final mood in monthMoods) {
  weatherCounts[mood.weather] =
      (weatherCounts[mood.weather] ?? 0) + 1;
}

final weatherSummary = weatherCounts.entries
    .map((entry) => '${entry.key} ${entry.value}日')
    .join('　');



return Scaffold(
  backgroundColor: const Color(0xFFF8F3FA),
  appBar: AppBar(
    title: const Text('気分カレンダー'),
    backgroundColor: const Color(0xFF8E7BBE),
    foregroundColor: Colors.white,
  ),
  body: SafeArea(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                '今月の心の天気',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F5F8F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                weatherSummary.isEmpty ? 'まだ記録がないよ🌙' : weatherSummary,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        TableCalendar<MoodRecord>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(selectedDay, day);
          },
          eventLoader: moodsForDay,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;

              final mood = events.first;

              return Positioned(
                bottom: 2,
                child: Text(
                  mood.weather,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            },
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              selectedDay = selected;
              focusedDay = focused;
            });
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Color(0xFFB9A7E8),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Color(0xFF8E7BBE),
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: selectedMoods.isEmpty
              ? const Center(
                  child: Text('この日の記録はまだないよ🌙'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedMoods.length,
                  itemBuilder: (context, index) {
                    final mood = selectedMoods[index];

                    return Card(
                      color: moodColor(mood),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          '${mood.createdAt.month}/${mood.createdAt.day}  ${mood.weather}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            ...mood.emotionPercents.entries.map(
                              (entry) => Text(
                                '${entry.key}：${entry.value.round()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6F5F8F),
                                ),
                              ),
                            ),
                            if (mood.memo.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                mood.memo,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6D6478),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  ),
);
  }
}
class RecoveryAlbumScreen extends StatelessWidget {
  final List<MoodRecord> moodHistory;
  final int lunaBond;
  final int streakDays;

  const RecoveryAlbumScreen({
    super.key,
    required this.moodHistory,
    required this.lunaBond,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final records = moodHistory.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E7BBE),
        foregroundColor: Colors.white,
        title: const Text('回復アルバム'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '🐶 ルナより\n\nここまでの記録は、あなたが歩いてきた大切な足あとだよ。\n\n連続記録：$streakDays日\nルナとの絆：$lunaBond',
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF6D5D7A),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (records.isEmpty)
            const Text(
              'まだ記録がありません。\n気分記録をすると、ここに回復の足あとが残るよ🌱',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF6D5D7A),
              ),
            ),

          ...records.map((record) {
            final date =
                '${record.createdAt.year}/${record.createdAt.month}/${record.createdAt.day}';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E7BBE),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('天気：${record.weather}'),
                  const SizedBox(height: 8),
                  Text('メモ：${record.memo.isEmpty ? "メモなし" : record.memo}'),
                  const SizedBox(height: 8),
                  Text(
                    '感情：${record.emotionPercents.entries.map((e) => '${e.key} ${(e.value).round()}%').join(' / ')}',
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}