import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cocoon/theme/app_colors.dart';
import 'package:cocoon/theme/app_text_styles.dart';
import 'package:cocoon/widgets/cocoon_card.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';



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

class LunaMemory {
  final String topic;
  final String summary;
  final DateTime createdAt;

  LunaMemory({
    required this.topic,
    required this.summary,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LunaMemory.fromJson(Map<String, dynamic> json) {
    return LunaMemory(
      topic: json['topic'],
      summary: json['summary'],
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
List<LunaMemory> lunaMemories = [];
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
  loadLunaMemories();
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

String getLunaMessage() {
  final hour = DateTime.now().hour;

  if (streakDays >= 30) {
    return 'もう1か月も会いに来てくれてるんだね。ルナ、すごくうれしいよ。';
  }

  if (streakDays >= 7) {
    return '1週間も続いてるね。ちゃんと自分の気持ちを見ててえらいよ。';
  }

  if (streakDays >= 3) {
    return '3日連続だね。今日も会えてうれしいな。';
  }

  if (lunaBond >= 100) {
    return '君が来てくれると、ルナも安心するんだ。';
  }

  if (lunaBond >= 50) {
    return 'また来てくれたね。ルナ、ちゃんと覚えてるよ。';
  }

  if (hour >= 5 && hour < 11) {
    return 'おはよう。今日も無理しすぎないでね。';
  } else if (hour >= 11 && hour < 17) {
    return '少し休憩できてる？ルナはここにいるよ。';
  } else if (hour >= 17 && hour < 22) {
    return '今日もおつかれさま。ここでは力を抜いていいよ。';
  } else {
    return '眠れない夜かな。ルナはここにいるよ。';
  }
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

Future<void> saveLunaMemories() async {
  final prefs = await SharedPreferences.getInstance();

  final encoded = jsonEncode(
    lunaMemories.map((memory) => memory.toJson()).toList(),
  );

  await prefs.setString('lunaMemories', encoded);
}



Future<void> loadLunaMemories() async {
  final prefs = await SharedPreferences.getInstance();

  final saved = prefs.getString('lunaMemories');

  if (saved == null) return;

  final List decoded = jsonDecode(saved);

  setState(() {
    lunaMemories = decoded
        .map((item) => LunaMemory.fromJson(item))
        .toList();
  });
}
Future<void> addLunaMemoryFromText(String text) async {
  final trimmedText = text.trim();

  if (trimmedText.isEmpty) return;

  String? topic;

  if (trimmedText.contains('彼氏') ||
      trimmedText.contains('彼女') ||
      trimmedText.contains('好きな人') ||
      trimmedText.contains('恋愛')) {
    topic = '恋愛';
  } else if (trimmedText.contains('仕事') ||
      trimmedText.contains('職場') ||
      trimmedText.contains('会社')) {
    topic = '仕事';
  } else if (trimmedText.contains('就職') ||
      trimmedText.contains('転職') ||
      trimmedText.contains('面接') ||
      trimmedText.contains('将来') ||
      trimmedText.contains('一人暮らし') ||
      trimmedText.contains('お金')) {
    topic = '将来';
  } else if (trimmedText.contains('家族') ||
      trimmedText.contains('母') ||
      trimmedText.contains('父') ||
      trimmedText.contains('親')) {
    topic = '家族';
  } else if (trimmedText.contains('友達') ||
      trimmedText.contains('親友') ||
      trimmedText.contains('旅行')) {
    topic = '友達';
  } else if (trimmedText.contains('学校') ||
      trimmedText.contains('勉強') ||
      trimmedText.contains('授業')) {
    topic = '学校';
  } else if (trimmedText.contains('体調') ||
      trimmedText.contains('病気') ||
      trimmedText.contains('通院') ||
      trimmedText.contains('入院')) {
    topic = '健康';
  }

  // 記憶するテーマが見つからなければ保存しない
  if (topic == null) return;

  // 長すぎる文章は短くする
  final summary = trimmedText.length > 60
      ? '${trimmedText.substring(0, 60)}…'
      : trimmedText;

  // 同じ内容を重複して保存しない
  final alreadySaved = lunaMemories.any(
    (memory) =>
        memory.topic == topic &&
        memory.summary == summary,
  );

  if (alreadySaved) return;

  setState(() {
    lunaMemories.add(
      LunaMemory(
        topic: topic!,
        summary: summary,
        createdAt: DateTime.now(),
      ),
    );

    // 古い記憶から削除し、最大20件にする
    while (lunaMemories.length > 20) {
      lunaMemories.removeAt(0);
    }
  });

  await saveLunaMemories();
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
    final LunaMemory? latestMemory =
    lunaMemories.isNotEmpty ? lunaMemories.last : null;
    final pages = [
  HomeScreen(
  latestMood: latestMood,
  petImagePath: petImagePath,
  lunaBond: lunaBond,
  streakDays: streakDays,
 moodHistory: moodHistory, 
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
  onMemorySave: addLunaMemoryFromText,
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
  final LunaMemory? latestMemory;
  final List<MoodRecord> moodHistory;

  const HomeScreen({
    super.key,
    this.latestMood,
    this.petImagePath,
    this.latestMemory,
    required this.lunaBond,
    required this.streakDays,
    required this.onTalkAboutMood,
    required this.moodHistory,
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

  String getBondLevel() {
    if (widget.lunaBond >= 100) return 'かぞく';
    if (widget.lunaBond >= 30) return 'しんゆう';
    if (widget.lunaBond >= 10) return 'なかよし';
    return 'おともだち';
  }

  String getLunaMessage() {
    final hour = DateTime.now().hour;

    if (widget.latestMemory != null) {
      return 'この前話してくれた\n「${widget.latestMemory!.summary}」\nその後どうだった？🐶';
    }

    if (widget.streakDays >= 100) {
      return '100日も来てくれたんだね。\nルナは幸せだよ🐶';
    }

    if (widget.streakDays >= 30) {
      return '30日達成！\nここまで本当に頑張ったね🌙';
    }

    if (widget.streakDays >= 7) {
      return '1週間続いたね！\nルナもうれしい🐶';
    }

    if (widget.latestMood != null &&
        widget.latestMood!.emotionPercents.isNotEmpty) {
      final strongestEmotion = widget.latestMood!.emotionPercents.entries
          .reduce((a, b) => a.value >= b.value ? a : b);

      if (strongestEmotion.key.contains('不安')) {
        return '今日は不安さんが少し大きいみたい。\nここで一緒にゆっくりしよう。';
      } else if (strongestEmotion.key.contains('疲れ')) {
        return '今日はおつかれさんが近くにいるね。\n無理しない時間にしよう。';
      } else if (strongestEmotion.key.contains('さみしい')) {
        return '今日はさみしいさんが顔を出してるね。\nルナがそばにいるよ。';
      } else if (strongestEmotion.key.contains('イライラ')) {
        return '今日はイライラさんが強めかも。\nここで少しほどいていこう。';
      } else if (strongestEmotion.key.contains('安心')) {
        return '今日は安心さんもいるね。\nそのやわらかい気持ち、大事にしよう。';
      }
    }

    if (hour >= 5 && hour < 11) {
      return 'おはよう☀️\n今日も無理せずいこうね。';
    } else if (hour >= 11 && hour < 17) {
      return 'こんにちは🌼\n少し休憩するのも大事だよ。';
    } else if (hour >= 17 && hour < 23) {
      return '今日もお疲れさま🌙\nここまで頑張ったね。';
    } else {
      return 'まだ起きてたんだね🌙\nルナはここにいるよ🐶';
    }
  }

  Color getOverlayColor() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return Colors.orange.withOpacity(0.12);
    } else if (hour >= 11 && hour < 17) {
      return Colors.white.withOpacity(0.05);
    } else if (hour >= 17 && hour < 22) {
      return Colors.deepPurple.withOpacity(0.18);
    } else {
      return Colors.indigo.withOpacity(0.30);
    }
  }

  Color getEmotionColor(String emotionKey) {
  if (emotionKey.contains('うれしい')) {
    return const Color(0xFFFFD966);
  } else if (emotionKey.contains('安心')) {
    return const Color(0xFF9AD7B5);
  } else if (emotionKey.contains('がんばった')) {
    return const Color(0xFFFFB6C1);
  } else if (emotionKey.contains('不安')) {
    return const Color(0xFF8FAADC);
  } else if (emotionKey.contains('悲しい')) {
    return const Color(0xFF9DC3E6);
  } else if (emotionKey.contains('疲れ')) {
    return const Color(0xFFBFBFBF);
  } else if (emotionKey.contains('イライラ')) {
    return const Color(0xFFD99694);
  } else if (emotionKey.contains('さみしい')) {
    return const Color(0xFFC5A3FF);
  }
  return AppColors.accent;
}

String getWeekday(DateTime date) {
  const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  return weekdays[date.weekday - 1];
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bondLevel = getBondLevel();
    final lunaMessage = getLunaMessage();

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
              color: getOverlayColor(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width < 500 ? 24 : size.width * 0.18,
                vertical: 24,
              ),
              child: Column(
                children: [
                  Text(
                    'COCOON',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 40,
                      letterSpacing: 5,
                      color: AppColors.accent,
                    ),
                  ),

                  const SizedBox(height: 14),

                  CocoonCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFE9D5FF),
                          child: Text(
                            '🐶',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ルナとの絆 ${widget.lunaBond}',
                                style: AppTextStyles.title,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bondLevel,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  CocoonCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💌 ルナからのメッセージ',
                          style: AppTextStyles.title.copyWith(
                            fontSize: 17,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lunaMessage,
                          style: AppTextStyles.body.copyWith(
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6D6478),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 170,
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
                            child: Image.asset(
                              'assets/images/luna.png',
                              height: 170,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  if (widget.latestMood != null)
                    CocoonCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '😊 今日の気分',
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Center(
                            child: Text(
                              widget.latestMood!.weather,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),

                          const SizedBox(height: 14),

                          ...widget.latestMood!.emotionPercents.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: AppTextStyles.body,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value.round()}%',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (widget.latestMood!.memo.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              widget.latestMood!.memo,
                              style: AppTextStyles.caption.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onTalkAboutMood,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('この気持ちをCOCOONに話す'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

if (widget.moodHistory.isNotEmpty)
  CocoonCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 最近7日間の気分',
          style: AppTextStyles.title.copyWith(
            color: AppColors.accent,
          ),
        ),

        const SizedBox(height: 18),
Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: List.generate(7, (index) {
    final today = DateTime.now();
    final targetDay = today.subtract(Duration(days: 6 - index));

    final moodsOfDay = widget.moodHistory.where((mood) {
      return mood.createdAt.year == targetDay.year &&
          mood.createdAt.month == targetDay.month &&
          mood.createdAt.day == targetDay.day;
    }).toList();

    final mood = moodsOfDay.isNotEmpty ? moodsOfDay.last : null;

    if (mood == null) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(''),
            const SizedBox(height: 6),
            Container(
              width: 24,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
           Builder(
  builder: (context) {
    final isToday =
        targetDay.year == DateTime.now().year &&
        targetDay.month == DateTime.now().month &&
        targetDay.day == DateTime.now().day;

    return Text(
      getWeekday(targetDay),
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.bold,
        color: isToday
            ? AppColors.accent
            : AppColors.textPrimary,
      ),
    );
  },
),
            const SizedBox(height: 4),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final strongest = mood.emotionPercents.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    final emotionColor = getEmotionColor(strongest.key);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                title: Text(
                  '${getWeekday(mood.createdAt)}曜日の記録',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        mood.weather,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...mood.emotionPercents.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${entry.key}：${entry.value.round()}%',
                          style: AppTextStyles.body,
                        ),
                      ),
                    ),
                    if (mood.memo.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'メモ',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(mood.memo, style: AppTextStyles.body),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる'),
                  ),
                ],
              );
            },
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${strongest.value.round()}%',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 24,
              height: 110,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: emotionColor.withOpacity(0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: (strongest.value / 100) * 110,
                decoration: BoxDecoration(
                  color: emotionColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 8),
           Builder(
  builder: (context) {
    final isToday =
        mood.createdAt.year == DateTime.now().year &&
        mood.createdAt.month == DateTime.now().month &&
        mood.createdAt.day == DateTime.now().day;

    return Text(
      getWeekday(mood.createdAt),
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.bold,
        color: isToday
            ? AppColors.accent
            : AppColors.textPrimary,
      ),
    );
  },
),
            const SizedBox(height: 4),
            Text(mood.weather, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }),
),
      ],
    ),
  ),

                  const SizedBox(height: 180),
                ],
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

  final List<String> weathers = ['☀️', '🌤️', '☁️', '🌧️', '🌙'];

  final List<String> emotions = ['😊', '😌', '🥹', '😰', '😢', '😴', '😡', '🫂'];

  final Map<String, String> emotionNames = {
    '😊': 'うれしい',
    '😌': '安心',
    '🥹': 'がんばった',
    '😰': '不安',
    '😢': '悲しい',
    '😴': '疲れ',
    '😡': 'イライラ',
    '🫂': 'さみしい',
  };

  void toggleEmotion(String emoji) {
    setState(() {
      final key = '$emoji ${emotionNames[emoji]}';

      if (emotionPercents.containsKey(key)) {
        emotionPercents.remove(key);
      } else {
        emotionPercents[key] = 50;
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
      const SnackBar(content: Text('記録できたよ🌿')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('今日の気分'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日の心の天気は？',
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 20),

              CocoonCard(
                child: Wrap(
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.secondary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.accent
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            weather,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                '今近い感情は？',
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 20),

              CocoonCard(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: emotions.map((emoji) {
                    final key = '$emoji ${emotionNames[emoji]}';
                    final selected = emotionPercents.containsKey(key);

                    return ChoiceChip(
                      label: Text(key),
                      selected: selected,
                      onSelected: (_) => toggleEmotion(emoji),
                      selectedColor: AppColors.secondary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              ...emotionPercents.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CocoonCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}：${entry.value.round()}%',
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                       const SizedBox(height: 12),

ClipRRect(
  borderRadius: BorderRadius.circular(999),
  child: LinearProgressIndicator(
    value: entry.value / 100,
    minHeight: 14,
    backgroundColor: AppColors.secondary.withOpacity(0.45),
    valueColor: const AlwaysStoppedAnimation<Color>(
      AppColors.accent,
    ),
  ),
),

const SizedBox(height: 10),

Slider(
  value: entry.value,
  min: 0,
  max: 100,
  divisions: 20,
  activeColor: AppColors.accent,
  inactiveColor: AppColors.secondary,
  onChanged: (value) {
    setState(() {
      emotionPercents[entry.key] = value;
    });
  },
),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'ひとことメモ',
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 14),

              CocoonCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: TextFormField(
                  controller: memoController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '今日のことを少しだけ書いてみる',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '記録する',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 40),
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
  final Function(String) onMemorySave;


const ChatScreen({
  super.key,
  required this.messages,
  required this.onMessagesChanged,
  required this.onMemorySave,
  this.latestMood,
});



  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isLunaCardCollapsed = false;

  DateTime? birthday;
String birthOrder = '';
String siblings = '';
String familyStyle = '';
String currentStatus = '';
  List<JapanEvent> japanEvents = [];
  bool isThinking = false;
  List<TimelineEvent> timelineEvents = [];
  String? currentTopic;
@override
void initState() {
  super.initState();

  loadCurrentTopic();
  loadTimelineEventsForChat();
  loadJapanEvents();
  loadProfileForChat();

  scrollController.addListener(() {
    if (scrollController.offset > 10 &&
        !isLunaCardCollapsed &&
        mounted) {
      setState(() {
        isLunaCardCollapsed = true;
      });
    }
  });
}

@override
void dispose() {
  scrollController.dispose();
  chatController.dispose();
  super.dispose();
}

Future<void> loadCurrentTopic() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    currentTopic = prefs.getString('currentTopic');
  });
}

Future<void> loadTimelineEventsForChat() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('timelineEvents');

  if (saved == null) return;

  final List decoded = jsonDecode(saved);

  setState(() {
    timelineEvents = decoded
        .map((item) => TimelineEvent.fromJson(item))
        .toList();
  });
}

Future<void> loadJapanEvents() async {
  final jsonString =
      await rootBundle.loadString('assets/data/japan_timeline.json');

  final List decoded = jsonDecode(jsonString);

  setState(() {
    japanEvents = decoded
        .map((item) => JapanEvent.fromJson(item))
        .toList();
  });

  debugPrint('日本年表の件数：${japanEvents.length}');


for (final event in japanEvents) {
  if (event.year == 2020 || event.year == 2022) {
    debugPrint(
      '確認：${event.year} ${event.title} keywords=${event.keywords}',
    );
  }
}
}

Future<void> loadProfileForChat() async {
  final prefs = await SharedPreferences.getInstance();
  final savedBirthday = prefs.getString('birthday');

  setState(() {
    if (savedBirthday != null) {
      birthday = DateTime.parse(savedBirthday);
    }

    birthOrder = prefs.getString('birthOrder') ?? '';
    siblings = prefs.getString('siblings') ?? '';
    familyStyle = prefs.getString('familyStyle') ?? '';
    currentStatus = prefs.getString('currentStatus') ?? '';
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

Future<void> sendMessage() async {
  final text = chatController.text.trim();
  if (text.isEmpty) return;

  widget.onMemorySave(text);

  setState(() {
    widget.messages.add(ChatMessage(text: text, isUser: true));
    chatController.clear();
    isThinking = true;
  });

  widget.onMessagesChanged();

  await Future.delayed(const Duration(milliseconds: 900));

  setState(() {
    isThinking = false;
    widget.messages.add(
      ChatMessage(
        text: makeCocoonReply(text, widget.messages),
        isUser: false,
      ),
    );
  });

  widget.onMessagesChanged();

  Future.delayed(const Duration(milliseconds: 100), () {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}


String makeCocoonReply(String userText, List<ChatMessage> pastMessages) {
  final text = userText.toLowerCase();

  int? age;

if (birthday != null) {
  final now = DateTime.now();

  age = now.year - birthday!.year;

  if (now.month < birthday!.month ||
      (now.month == birthday!.month &&
          now.day < birthday!.day)) {
    age--;
  }
}

  if (text.contains('自己紹介') ||
    text.contains('私のこと') ||
    text.contains('プロフィール')) {

  return '🐶\n\n'
      '今わかっていることだよ✨\n\n'
      '🎂 生年月日：${birthday != null ? '${birthday!.year}/${birthday!.month}/${birthday!.day}' : '未設定'}\n'
      '👶 出生順位：${birthOrder.isEmpty ? '未設定' : birthOrder}\n'
      '👨‍👩‍👧‍👦 兄弟姉妹：${siblings.isEmpty ? '未設定' : siblings}\n'
      '🏠 家族との距離感：${familyStyle.isEmpty ? '未設定' : familyStyle}\n'
      '💼 現在の状況：${currentStatus.isEmpty ? '未設定' : currentStatus}';
}

if ((text.contains('家族') ||
          text.contains('親') ||
          text.contains('母') ||
          text.contains('父')) &&
      familyStyle.isNotEmpty) {
    return '🐶\n\n'
        '家族との距離感を「$familyStyle」と教えてくれていたね。\n\n'
        'その中で今の悩みを抱えるのは、きっと気を使うことも多かったと思うよ。\n'
        '今いちばんしんどいのは、どんなところ？';
  }

  if ((text.contains('仕事') ||
        text.contains('会社') ||
        text.contains('学校') ||
        text.contains('勉強') ||
        text.contains('疲れた') ||
        text.contains('つらい')) &&
    currentStatus.isNotEmpty) {
  return '🐶\n\n'
      '今は「$currentStatus」と教えてくれていたね。\n\n'
      'その環境の中で毎日頑張っているからこそ、今の気持ちが大きくなっているのかもしれないね。\n\n'
      '最近、一番負担に感じていることは何かな？';
}

if ((text.contains('全部私が') ||
        text.contains('全部自分が') ||
        text.contains('頼られる') ||
        text.contains('責任') ||
        text.contains('我慢') ||
        text.contains('しっかりしなきゃ')) &&
    birthOrder.isNotEmpty) {
  return '🐶\n\n'
      '出生順位は「$birthOrder」と教えてくれていたね。\n\n'
      'それだけで性格が決まるわけではないけれど、'
      '家族の中で役割や責任を感じる場面があったのかな。\n\n'
      'いつ頃から「自分が頑張らなきゃ」と感じるようになった？';
}

if (birthday != null && japanEvents.isNotEmpty) {
  final matchedJapanEvents = japanEvents.where((event) {
    final isBornAlready =
        event.year >= birthday!.year &&
        event.year <= DateTime.now().year;

    final hasMatchingKeyword = event.keywords.any(
      (keyword) => text.contains(keyword.toLowerCase()),
    );

    return isBornAlready && hasMatchingKeyword;
  }).toList()
    ..sort((a, b) => b.year.compareTo(a.year));

    debugPrint('入力文：$text / 一致件数：${matchedJapanEvents.length}');

  if (matchedJapanEvents.isNotEmpty) {
    final event = matchedJapanEvents.first;
    final ageAtEvent = event.year - birthday!.year;

    return '🐶\n\n'
        '今は${age ?? ''}歳なんだね。\n\n'
        '日本年表を見ると、だいたい${ageAtEvent}歳頃の'
        '${event.year}年に「${event.title}」という出来事があったよ。\n\n'
        '${event.description}\n\n'
        'その頃の社会の変化が、今の気持ちに少し影響している部分もあるのかな？';
  }
}

if (timelineEvents.isNotEmpty) {
  String? targetCategory;

  if (text.contains('仕事') ||
      text.contains('職場') ||
      text.contains('自信') ||
      text.contains('将来')) {
    targetCategory = '仕事';
  } else if (text.contains('恋愛') ||
      text.contains('彼氏') ||
      text.contains('彼女') ||
      text.contains('好きな人')) {
    targetCategory = '恋愛';
  } else if (text.contains('家族') ||
      text.contains('親') ||
      text.contains('母') ||
      text.contains('父')) {
    targetCategory = '家族';
  } else if (text.contains('体調') ||
      text.contains('病気') ||
      text.contains('健康') ||
      text.contains('疲れた')) {
    targetCategory = '健康';
  }

  if (targetCategory != null) {
    final matchedEvents = timelineEvents
        .where((event) => event.category == targetCategory)
        .toList();


 if (matchedEvents.isNotEmpty) {
  final recentEvents = matchedEvents.reversed.take(3).toList();

  final eventText = recentEvents
      .map((event) => '・${event.year}年「${event.title}」')
      .join('\n');

  return '🐶\n\n'
      '今の話を聞いていて、'
      'わたし年表の出来事をいくつか思い出したよ。\n\n'
      '$eventText\n\n'
      'こうして振り返ると、'
      'あなたはこのテーマと何度も向き合ってきたんだね。\n\n'
      '今の気持ちは、この中のどの出来事と一番つながっていると思う？';
}
  }
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

if (text.contains('将来') ||
    text.contains('人生') ||
    text.contains('夢') ||
    text.contains('目標') ||
    text.contains('就職') ||
    text.contains('転職') ||
    text.contains('一人暮らし') ||
    text.contains('お金') ||
    text.contains('貯金')) {
  currentTopic = '将来';
  saveCurrentTopic('将来');
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

// 仕事：上司
if (currentTopic == '仕事' &&
    (text.contains('上司') ||
     text.contains('店長') ||
     text.contains('部長') ||
     text.contains('課長'))) {

  return '${pick([

'上司との関係って、一日の気分にも影響しやすいよね。\n今日はどんなことがあったの？',

'上司に言われたことが心に残っているのかな。\nどんな言葉だった？',

'仕事そのものより、人間関係がつらい日もあるよね。\n何が一番負担になっている？',

'頑張っているのに認めてもらえないと苦しいよね。\n最近特につらかった出来事はある？',

'上司との距離感って難しいよね。\n本当はどう接したいと思ってる？',

'ルナには少し気を張っている心が見えているよ🐶\nもう少し聞かせてくれる？',

'仕事へ行く前から憂うつになるくらいかな。\n朝はどんな気持ちになる？',

'我慢を続けるだけだと心も疲れてしまうよね。\n今一番話したいことは何？',

])}\n\n${getFollowUpQuestion()}';
}

// 仕事：同僚
if (currentTopic == '仕事' &&
    (text.contains('同僚') ||
     text.contains('先輩') ||
     text.contains('後輩') ||
     text.contains('同期'))) {

  return '${pick([

'同僚との関係って、一日の過ごしやすさにも影響するよね。\n今日はどんなことがあったの？',

'仕事そのものより、人間関係がつらい日もあるよね。\n何が一番気になっている？',

'職場で気を遣い続けると、それだけで疲れてしまうこともあるよね。\n最近どんなことがあった？',

'同僚との距離感って難しいよね。\nどんな時に一番しんどいと感じる？',

'ルナには少し疲れた心が見えているよ🐶\nもう少し話してみる？',

'誰かに気を遣い続ける毎日だと、自分の心も休まりにくいよね。\n今日は何が一番負担だった？',

'職場の人間関係って簡単には変えられないから苦しいよね。\n今、一番伝えたいことは何かな？',

'無理して笑顔で過ごしている日もあるのかな。\n本当の気持ちを聞かせてくれる？',

  ])}\n\n${getFollowUpQuestion()}';
}

// 仕事：ミスした
if (currentTopic == '仕事' &&
    (text.contains('ミス') ||
     text.contains('失敗') ||
     text.contains('怒られた') ||
     text.contains('間違えた') ||
     text.contains('やらかした'))) {

  return '${pick([

'ミスをすると、必要以上に自分を責めてしまうことってあるよね。\n今日あったことを聞かせてくれる？',

'怒られた後って、頭の中で何度も思い返してしまうことがあるよね。\n一番心に残っていることは何かな？',

'失敗したことより、「次も失敗するかも」って不安になるのがつらいこともあるよね。\n今どんな気持ち？',

'誰でも失敗することはあるけど、自分のことだとすごく大きく感じてしまうよね。\n今日は何があったの？',

'ルナには少し落ち込んでいる心が見えているよ🐶\nここでは無理に元気にならなくて大丈夫。',

'頑張っていたからこそ、失敗が悔しいんだと思う。\n何が一番引っかかっている？',

'ミスをした後って、自分のいいところまで見えなくなることがあるよね。\n今は少し休みながら話そう。',

'今日の失敗だけで、あなたの価値が決まるわけじゃないよ。\nルナはそう思ってる🐶',

  ])}\n\n${getFollowUpQuestion()}';
}

// 仕事：評価されない・認められない
if (currentTopic == '仕事' &&
    (text.contains('評価') ||
     text.contains('認められない') ||
     text.contains('褒められない') ||
     text.contains('頑張ってるのに') ||
     text.contains('報われない'))) {

  return '${pick([

'頑張っているのに認めてもらえないと、心が折れそうになることもあるよね。\n最近どんなことがあったの？',

'努力が伝わらないと、「頑張る意味って何だろう」って思ってしまうこともあるよね。\n何が一番つらい？',

'結果だけじゃなくて、頑張りも見てもらえたら嬉しいよね。\n最近頑張ったことを教えてくれる？',

'周りと比べられると、自分だけ置いていかれたような気持ちになることもあるよね。\nどんな場面でそう感じた？',

'ルナは、頑張っていること自体にも価値があると思うよ🐶\n今日は何を頑張ったの？',

'評価されない日が続くと、自信までなくなってしまうこともあるよね。\n今一番引っかかっていることは何かな？',

'誰かに「よく頑張ったね」って言ってもらいたい日もあるよね。\n今日はルナが話を聞くよ🐶',

'頑張りが報われないように感じる日は、本当に苦しいよね。\nその気持ちを一人で抱えなくて大丈夫だよ。',

])}\n\n${getFollowUpQuestion()}';
}

// 仕事：仕事量・残業・忙しすぎる
if (currentTopic == '仕事' &&
    (text.contains('残業') ||
     text.contains('忙しい') ||
     text.contains('仕事量') ||
     text.contains('終わらない') ||
     text.contains('やること多い') ||
     text.contains('タスク') ||
     text.contains('休めない'))) {

  return '${pick([

'やることが多すぎると、心も体もずっと追われている感じになるよね。\n今一番重たい仕事は何かな？',

'仕事が終わらない日が続くと、休んでいても気持ちが休まらないよね。\n最近ちゃんと休めてる？',

'忙しすぎると、自分のペースがどんどんなくなってしまうことがあるよね。\n今日は何が一番大変だった？',

'残業が続くと、体だけじゃなくて心も疲れてしまうよね。\n今の疲れは何点くらい？',

'「まだやらなきゃ」って気持ちがずっと続いているのかな。\n今すぐ手放せそうなことはある？',

'ルナには、かなり頑張りすぎている心が見えているよ🐶\n今日は少し休めそう？',

'仕事量が多い時って、自分が足りないんじゃなくて、抱えている量が多すぎることもあるよ。',

'全部を完璧にやろうとしなくても大丈夫。\n今いちばん優先しなきゃいけないことは何かな？',

])}\n\n${getFollowUpQuestion()}';
}

// 仕事：辞めたい・出勤したくない
if (currentTopic == '仕事' &&
    (text.contains('辞めたい') ||
     text.contains('やめたい') ||
     text.contains('仕事行きたくない') ||
     text.contains('会社行きたくない') ||
     text.contains('出勤したくない') ||
     text.contains('仕事したくない'))) {

  return '${pick([

'仕事に行きたくないくらい、心も体も疲れているのかもしれないね。\n最近一番つらかったことは何かな？',

'「辞めたい」って思うほど頑張ってきたんだね。\n何が一番負担になっている？',

'朝起きた時から仕事のことを考えてしまう感じかな。\nどんな気持ちになる？',

'辞めたい気持ちの中には、疲れや悲しさ、怒りが混ざっていることもあるよね。\n今一番大きい気持ちは何かな？',

'本当は辞めたいわけじゃなくて、「今の状況から楽になりたい」気持ちなのかもしれないね。\nどう思う？',

'ルナには少し限界まで頑張ってきた心が見えているよ🐶\nここでは無理に元気にならなくて大丈夫。',

'「もう無理かもしれない」って感じる日もあるよね。\n今日は何が一番苦しかった？',

'今すぐ答えを出さなくても大丈夫。\nまずは今の気持ちを整理するところから始めよう🐶',

])}\n\n${getFollowUpQuestion()}';
}

// 仕事：転職
if (currentTopic == '仕事' &&
    (text.contains('転職') ||
     text.contains('会社変えたい') ||
     text.contains('職場変えたい') ||
     text.contains('別の仕事') ||
     text.contains('仕事変えたい'))) {

  return '${pick([

'転職を考えるくらい、今の環境で頑張ってきたんだね。\n何が一番変わったら楽になりそう？',

'今の仕事を続けるか、環境を変えるかってすごく迷うよね。\n転職したいと思ったきっかけは何だった？',

'転職って希望もあるけど、不安も大きいよね。\n今一番心配なのは何かな？',

'「逃げなのかな」って思ってしまうこともあるかもしれないけど、自分を守るための選択肢でもあるよ🐶',

'次の場所では、どんな働き方ができたら安心できそう？',

'今の職場で我慢していることが多いのかな。\n一番つらい部分を教えてくれる？',

'転職を考える時って、自分のこれからを真剣に考えている時でもあるよね。\nどんな未来に近づきたい？',

'焦って決めなくて大丈夫。\nまずは「変えたいこと」と「守りたいこと」を分けてみよう。',

])}\n\n${getFollowUpQuestion()}';
}

// 仕事：面接
if (currentTopic == '仕事' &&
    (text.contains('面接') ||
     text.contains('就活') ||
     text.contains('面談') ||
     text.contains('面接官') ||
     text.contains('面接結果'))) {

  return '${pick([

'面接って、始まる前も終わった後も緊張が続くよね。\n今はどんな気持ち？',

'「うまく話せたかな」って何度も思い返してしまうこともあるよね。\n一番気になっていることは何かな？',

'面接は自分を評価されるように感じて、不安になりやすいよね。\n今日はどんなことがあった？',

'結果を待っている時間って、本当に長く感じるよね。\n今一番心配していることは何？',

'ルナは、面接に挑戦したこと自体が大きな一歩だと思うよ🐶\nお疲れさま。',

'緊張しながらも頑張ったんだね。\n自分ではどんなところがうまくできたと思う？',

'結果がどうなるか分からない時間って落ち着かないよね。\n今は何を考えている？',

'どんな結果でも、今日頑張った経験はちゃんと次につながるよ🐶\nもう少し話してみる？',

])}\n\n${getFollowUpQuestion()}';
}

// 仕事：面接
if (currentTopic == '仕事' &&
    (text.contains('面接') ||
     text.contains('就活') ||
     text.contains('面談') ||
     text.contains('面接官') ||
     text.contains('面接結果'))) {

  return '${pick([

'面接って、始まる前も終わった後も緊張が続くよね。\n今はどんな気持ち？',

'「うまく話せたかな」って何度も思い返してしまうこともあるよね。\n一番気になっていることは何かな？',

'面接は自分を評価されるように感じて、不安になりやすいよね。\n今日はどんなことがあった？',

'結果を待っている時間って、本当に長く感じるよね。\n今一番心配していることは何？',

'ルナは、面接に挑戦したこと自体が大きな一歩だと思うよ🐶\nお疲れさま。',

'緊張しながらも頑張ったんだね。\n自分ではどんなところがうまくできたと思う？',

'結果がどうなるか分からない時間って落ち着かないよね。\n今は何を考えている？',

'どんな結果でも、今日頑張った経験はちゃんと次につながるよ🐶\nもう少し話してみる？',

])}\n\n${getFollowUpQuestion()}';
}

// 仕事：新人・新しい職場
if (currentTopic == '仕事' &&
    (text.contains('新人') ||
     text.contains('入社') ||
     text.contains('新しい職場') ||
     text.contains('初出勤') ||
     text.contains('慣れない') ||
     text.contains('覚えられない'))) {

  return '${pick([

'新しい環境って、それだけでたくさんエネルギーを使うよね。\n今日はどんなことがあった？',

'仕事を覚えるだけでも大変なのに、人間関係も一緒に始まるから疲れやすいよね。\n今一番不安なことは何かな？',

'周りと比べて焦ってしまうこともあるよね。\nでも最初から完璧な人はいないよ🐶',

'覚えることが多い時期は、自分が成長している途中でもあるんだ。\n最近できるようになったことはある？',

'新しい職場に慣れるまでは、不安になるのが自然だよ。\n今日は何が一番大変だった？',

'ルナには少し緊張している心が見えているよ🐶\n無理に強くならなくて大丈夫。',

'失敗しないように頑張りすぎて、心が疲れてしまうこともあるよね。\n今日はちゃんと休めそう？',

'「ちゃんとできるかな」って思う日もあるよね。\nでもここまで頑張ってきた自分も忘れないでね🐶',

])}\n\n${getFollowUpQuestion()}';
}

// 仕事：ハラスメント・理不尽
if (currentTopic == '仕事' &&
    (text.contains('パワハラ') ||
     text.contains('セクハラ') ||
     text.contains('モラハラ') ||
     text.contains('理不尽') ||
     text.contains('嫌がらせ') ||
     text.contains('八つ当たり') ||
     text.contains('怒鳴られた'))) {

  return '${pick([

'理不尽なことが続くと、「自分が悪いのかな」って考えてしまうこともあるよね。\n今日は何があったの？',

'傷つく言葉を受けると、その場だけじゃなくて後からも苦しくなるよね。\n一番心に残っていることは何かな？',

'毎日気を張り続ける環境だと、心も体も疲れてしまうよね。\n最近ちゃんと休めてる？',

'理不尽な対応を受けると、自信までなくなってしまうことがあるよね。\n今一番つらいことは何かな？',

'ルナは、あなたが悪いと決めつける前に、どんなことがあったのか聞きたいな🐶',

'誰かに傷つけられた気持ちは、簡単には消えないよね。\nここでは安心して話して大丈夫。',

'一人で耐え続けるのは本当に大変だったと思う。\n今どんな気持ちが一番大きい？',

'無理に強くいようとしなくても大丈夫。\nルナと一緒に少しずつ整理していこう🐶',

  ])}\n\n${getFollowUpQuestion()}';
}

// 仕事：仕事とプライベートの両立
if (currentTopic == '仕事' &&
    (text.contains('両立') ||
     text.contains('プライベート') ||
     text.contains('休みの日') ||
     text.contains('休日') ||
     text.contains('仕事のこと考える') ||
     text.contains('気が休まらない'))) {

  return '${pick([

'休みの日まで仕事のことを考えてしまうと、心が休まらないよね。\n最近いつ一番そう感じた？',

'仕事と自分の時間の境目がなくなると、ずっと疲れが残る感じがするよね。\n今いちばん休めていない部分はどこかな？',

'プライベートの時間も大切にしたいのに、仕事が頭から離れないのはつらいよね。\nどんな時に思い出してしまう？',

'休んでいるはずなのに、心だけ仕事場にいる感じかな。\n今日はどんなことが気になっている？',

'ルナには、ずっと気を張っている心が見えているよ🐶\n少しだけ力を抜けそう？',

'仕事を頑張ることと、自分を大切にすることは両方あっていいと思うよ。\n今はどっちが足りていない感じ？',

'休日まで不安が続くと、次の一週間が怖くなることもあるよね。\n何が一番重たく感じる？',

'まずは今日、仕事から少し離れるためにできそうな小さいことはあるかな？',

  ])}\n\n${getFollowUpQuestion()}';
}
// 仕事
if (text.contains('仕事') ||
    text.contains('職場') ||
    text.contains('会社') ||
    text.contains('上司')) {

  // ポジティブ判定
  final isPositive =
      text.contains('嬉しい') ||
      text.contains('うれしい') ||
      text.contains('楽しい') ||
      text.contains('好き') ||
      text.contains('できた') ||
      text.contains('頑張れた') ||
      text.contains('がんばつた') ||
      text.contains('褒められた') ||
      text.contains('ほめられた') ||
      text.contains('任された') ||
      text.contains('評価された') ||
      text.contains('合格') ||
      text.contains('成功') ||
      text.contains('昇進') ||
      text.contains('達成');

  if (isPositive) {
    return pick([
      'それはうれしいね🐶✨\n頑張ったことがちゃんと実を結んだんだね！',
      'いい一日だったんだね🌙\nルナまでうれしい気持ちになったよ。',
      'その出来事、大切にしてほしいな。\n今日は自分をたくさん褒めてあげよう！',
    ]);
  }

  // ネガティブ・その他
  return pick([
    '毎日ちゃんとやらなきゃって思うほど、心が疲れやすいよね。',
    '仕事や学校のことって、逃げ場が少なく感じることがあるよね。\n今つらいのは人間関係？量の多さ？評価される不安？',
    'かなり気を張って過ごしているのかもしれないね。\n今日いちばん負担だった場面はどこ？',
  ]);
}


// 学校：テスト・受験
if (currentTopic == '学校' &&
    (text.contains('テスト') ||
     text.contains('試験') ||
     text.contains('受験') ||
     text.contains('模試') ||
     text.contains('点数') ||
     text.contains('成績'))) {

  return '${pick([

'テストや受験って、結果が気になって不安になるよね。\n今一番心配なことは何かな？',

'勉強してきたからこそ、「うまくいくかな」って考えてしまうんだよね。\n最近どんな気持ち？',

'結果を待っている時間って、本当に長く感じるよね。\n今はどんなことを考えている？',

'思うような点数が取れないと、自分まで否定された気持ちになることもあるよね。\n何が一番悔しかった？',

'受験やテストは心も体も疲れやすいよね。\n今日はちゃんと休めそう？',

'ルナは、頑張ってきた時間そのものにも価値があると思うよ🐶',

'焦る気持ちがあるのかな。\n今一番プレッシャーを感じていることは何？',

'どんな結果でも、ここまで努力してきた自分を忘れないでね🐶',

  ])}\n\n${getFollowUpQuestion()}';
}

// 学校：勉強についていけない
if (currentTopic == '学校' &&
    (text.contains('勉強') ||
     text.contains('授業についていけない') ||
     text.contains('分からない') ||
     text.contains('理解できない') ||
     text.contains('難しい') ||
     text.contains('覚えられない'))) {

  return '${pick([

'勉強についていけないと感じると、不安になるよね。\n最近どんなことが難しいと感じてる？',

'周りと比べて焦ってしまうこともあるよね。\n今一番苦手なことは何かな？',

'分からないことが増えると、「自分には無理なのかな」って思ってしまう日もあるよね。\nどこでつまずいている感じ？',

'勉強は分からないことが続くと苦しくなりやすいよね。\n今日はどんな授業があったの？',

'覚えられない日があっても大丈夫。\n疲れている時は頭も働きにくくなるからね🐶',

'ルナは、分からないって言葉にできることも大切な一歩だと思うよ。\n何が一番困っている？',

'全部を一度にできるようにならなくても大丈夫。\n今は一番困っているところから話してみよう。',

'勉強で悩むのは、それだけ頑張りたい気持ちがあるからなんだね🐶',

  ])}\n\n${getFollowUpQuestion()}';
}

// 学校：先生との関係
if (currentTopic == '学校' &&
    (text.contains('先生') ||
     text.contains('担任') ||
     text.contains('怒られた') ||
     text.contains('注意された') ||
     text.contains('先生が怖い') ||
     text.contains('相談できない'))) {

  return '${pick([

'先生との関係って、学校で過ごす気持ちに大きく影響するよね。\n今日はどんなことがあったの？',

'先生に言われたことが心に残っているのかな。\nどんな言葉だった？',

'怒られたり注意されたりすると、あとから何度も思い出してしまうことがあるよね。\n今一番引っかかっていることは何？',

'先生が怖いと、学校にいる時間も緊張しやすいよね。\nどんな時に一番そう感じる？',

'相談したいのにできない感じかな。\n本当はどんなことを分かってほしい？',

'ルナには少し気を張っている心が見えているよ🐶\nここではそのまま話して大丈夫。',

'先生との距離感って難しいよね。\n今は近づきたい気持ちと離れたい気持ち、どっちが近い？',

'学校で安心できる大人がいると少し違うよね。\n他に話せそうな人はいる？',

  ])}\n\n${getFollowUpQuestion()}';
}

// 学校：クラスメイト・友達関係
if (currentTopic == '学校' &&
    (text.contains('クラスメイト') ||
     text.contains('友達') ||
     text.contains('友人') ||
     text.contains('同級生') ||
     text.contains('クラス') ||
     text.contains('ぼっち') ||
     text.contains('仲間外れ'))) {

  return '${pick([

'クラスの人間関係って、毎日顔を合わせるから心に残りやすいよね。\n今日はどんなことがあったの？',

'友達とのことでモヤモヤしているのかな。\n今いちばん気になっていることは何？',

'学校でひとりに感じる時間って、すごく長く感じることがあるよね。\nどんな時に一番さみしくなる？',

'仲間外れみたいに感じると、学校にいるだけで疲れてしまうよね。\n何が一番つらかった？',

'クラスの空気を気にしながら過ごすのって、かなりエネルギーを使うよね。\n今日は気を遣う場面があった？',

'ルナには少し心細い気持ちが見えているよ🐶\nここではそのまま話して大丈夫。',

'友達と一緒にいても、安心できない時ってあるよね。\n最近そう感じたことはあった？',

'一人で抱え込まなくて大丈夫。\n今、誰に一番分かってほしい？',

  ])}\n\n${getFollowUpQuestion()}';
}

// 学校：部活
if (currentTopic == '学校' &&
    (text.contains('部活') ||
     text.contains('顧問') ||
     text.contains('先輩') ||
     text.contains('後輩') ||
     text.contains('試合') ||
     text.contains('練習'))) {

  return '${pick([

'部活って、好きでやっていても人間関係や練習で疲れることがあるよね。\n今日はどんなことがあったの？',

'練習や試合のことが心に残っているのかな。\n何が一番引っかかってる？',

'先輩や後輩との関係って、学校生活の中でも気を遣いやすいよね。\nどんな時にしんどいと感じる？',

'顧問の先生とのことが気になっているのかな。\nどんな言葉や態度が心に残ってる？',

'頑張りたい気持ちと、疲れた気持ちが両方あるのかもしれないね。\n今はどっちが大きい？',

'ルナには少し頑張りすぎている心が見えているよ🐶\nここでは力を抜いて話して大丈夫。',

'部活でうまくいかない日って、自分を責めてしまうこともあるよね。\n今日は何が一番悔しかった？',

'続けたい気持ちと、少し休みたい気持ちが混ざっているのかな。\n今の本音を聞かせてくれる？',

  ])}\n\n${getFollowUpQuestion()}';
}
// 学校：学校に行きたくない
if (currentTopic == '学校' &&
    (text.contains('学校行きたくない') ||
     text.contains('学校に行きたくない') ||
     text.contains('休みたい') ||
     text.contains('行きたくない') ||
     text.contains('朝がつらい') ||
     text.contains('学校嫌'))) {

  return '${pick([

'学校へ行かなきゃって思うほど、心も体も重たくなる日ってあるよね。\n今日は何が一番つらい？',

'朝になると気持ちが沈んでしまう感じかな。\nどんなことを考えてしまう？',

'学校に行きたくない気持ちには、ちゃんと理由があることも多いよ。\n最近何かあった？',

'無理に「頑張らなきゃ」って思い続けると、心も疲れてしまうよね。\n今はどんな気持ち？',

'ルナには少し疲れた心が見えているよ🐶\nここでは無理に元気にならなくて大丈夫。',

'学校がつらい日は、自分を責めてしまうこともあるよね。\n何が一番苦しいのかな？',

'「行きたくない」って思うくらい頑張ってきたんだね。\n今日は何が心に引っかかっている？',

'今すぐ答えを出さなくても大丈夫。\nまずはルナと一緒に気持ちを整理してみよう🐶',

  ])}\n\n${getFollowUpQuestion()}';
}

// 学校：いじめ・嫌がらせ
if (currentTopic == '学校' &&
    (text.contains('いじめ') ||
     text.contains('悪口') ||
     text.contains('無視') ||
     text.contains('仲間外れ') ||
     text.contains('嫌がらせ') ||
     text.contains('陰口') ||
     text.contains('SNSで言われた'))) {

  return '${pick([

'それはかなりつらかったね。\n学校でそういうことがあると、安心できる場所がなくなったように感じることもあるよね。',

'悪口や無視って、心にずっと残りやすいよね。\n今いちばん苦しかった場面はどこかな？',

'ひとりで抱えるには重たいことだと思う。\n話せそうな先生や家族、信頼できる人はいる？',

'仲間外れにされると、自分が悪いのかなって思ってしまうこともあるよね。\nでも、傷ついた気持ちは大事にしていいよ。',

'ルナはここで話を聞いているよ🐶\n何があったのか、少しずつで大丈夫。',

'学校に行くのが怖くなるくらいなら、無理に一人で耐え続けなくていいよ。\n誰かに一緒に伝える方法を考えよう。',

'嫌がらせが続いているなら、記録しておくことも自分を守る助けになるよ。\nいつ、どんなことがあった？',

'今の気持ちを話してくれてありがとう。\nここでは責めたりしないから、そのまま聞かせてね。',

  ])}\n\n${getFollowUpQuestion()}';
}

// 学校：いじめ・嫌がらせ
if (currentTopic == '学校' &&
    (text.contains('いじめ') ||
     text.contains('悪口') ||
     text.contains('無視') ||
     text.contains('仲間外れ') ||
     text.contains('嫌がらせ') ||
     text.contains('陰口') ||
     text.contains('SNSで言われた'))) {

  return '${pick([

'それはかなりつらかったね。\n学校でそういうことがあると、安心できる場所がなくなったように感じることもあるよね。',

'悪口や無視って、心にずっと残りやすいよね。\n今いちばん苦しかった場面はどこかな？',

'ひとりで抱えるには重たいことだと思う。\n話せそうな先生や家族、信頼できる人はいる？',

'仲間外れにされると、自分が悪いのかなって思ってしまうこともあるよね。\nでも、傷ついた気持ちは大事にしていいよ。',

'ルナはここで話を聞いているよ🐶\n何があったのか、少しずつで大丈夫。',

'学校に行くのが怖くなるくらいなら、無理に一人で耐え続けなくていいよ。\n誰かに一緒に伝える方法を考えよう。',

'嫌がらせが続いているなら、記録しておくことも自分を守る助けになるよ。\nいつ、どんなことがあった？',

'今の気持ちを話してくれてありがとう。\nここでは責めたりしないから、そのまま聞かせてね。',

  ])}\n\n${getFollowUpQuestion()}';
}

// 学校
if (text.contains('学校') ||
    text.contains('授業') ||
    text.contains('テスト') ||
    text.contains('勉強') ||
    text.contains('受験')) {

  final isPositive =
      text.contains('嬉しい') ||
      text.contains('うれしい') ||
      text.contains('できた') ||
      text.contains('頑張れた') ||
      text.contains('褒められた') ||
      text.contains('合格') ||
      text.contains('受かった') ||
      text.contains('100点');

  if (isPositive) {
    return pick([
      'すごいね🐶✨\n今日の頑張りがちゃんと結果につながったんだね！',
      'ルナまでうれしくなっちゃった🌸\n今日は自分をたくさん褒めてあげよう！',
      '頑張った自分を認めてあげる日だね。\n本当にお疲れさま！',
    ]);
  }

  return pick([
    '学校って勉強だけじゃなくて、人間関係もあって大変だよね。\n今日は何があった？',
    '学校生活って毎日だからこそ疲れやすいよね。\n一番つらかったことは何かな？',
    '今日はどんな一日だった？\nルナがゆっくり話を聞くよ🐶',
  ]);
}

// 恋愛：不安・返信・距離感
// 恋愛
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

  // ポジティブ判定
  final isPositive =
      text.contains('嬉しい') ||
      text.contains('うれしい') ||
      text.contains('幸せ') ||
      text.contains('楽しい') ||
      text.contains('仲直り') ||
      text.contains('付き合えた') ||
      text.contains('デート') ||
      text.contains('旅行') ||
      text.contains('会えた') ||
      text.contains('告白') ||
      text.contains('好きって言われた') ||
      text.contains('記念日') ||
      text.contains('笑った');

  if (isPositive) {
    return pick([
      'よかったね🐶💜 ルナまでうれしくなっちゃった！',
      'その幸せな気持ち、大切にしてね🌙',
      '素敵な時間だったんだね。ルナも心があたたかくなったよ。',
      'そんな話を聞けてうれしいな。また思い出も聞かせてね🐶',
    ]);
  }

  // ネガティブ・不安
  return pick([
    '大切な人の反応って、心にすごく影響するよね。\n今いちばんつらいのは、返信のこと？会えないこと？それとも気持ちが見えないこと？',
    '恋愛の不安って、相手の一言や返信の速さで大きくなりやすいよね。\nまずは「実際に起きたこと」と「想像していること」を分けてみよう。',
    '好きだからこそ、不安も寂しさも強くなるんだと思う。\n今は相手にどうしてほしい気持ちが一番近い？',
    '相手の気持ちが見えない時間って苦しいよね。\n今の不安を一人で抱えなくて大丈夫だよ。',
  ]);
}
// 友達・人間関係
if (text.contains('友達') ||
    text.contains('親友') ||
    text.contains('友人') ||
    text.contains('人間関係') ||
    text.contains('悪口') ||
    text.contains('無視') ||
    text.contains('遊んだ') ||
    text.contains('ご飯') ||
    text.contains('旅行')) {

  final isPositive =
      text.contains('楽しい') ||
      text.contains('楽しかった') ||
      text.contains('嬉しい') ||
      text.contains('うれしい') ||
      text.contains('遊んだ') ||
      text.contains('ご飯') ||
      text.contains('旅行') ||
      text.contains('笑った') ||
      text.contains('仲直り') ||
      text.contains('会えた') ||
      text.contains('話せた') ||
      text.contains('親友');

  if (isPositive) {
    return pick([
      '楽しそうだね🐶✨\n大切な人といい時間を過ごせたんだね。',
      'それはうれしいね🌙\nルナまでにこにこしちゃうよ。',
      'いい思い出がまた一つ増えたね。\nどんなところが一番楽しかった？',
      '友達と安心して過ごせる時間って、心が少し軽くなるよね🐶',
    ]);
  }

  return pick([
    '人間関係って、小さい違和感でも心に残りやすいよね。',
    '悲しかった？それともモヤモヤした？',
    '大事にされてない感じがしたのかな。',
    '相手との関係を続けたい気持ちと、苦しい気持ち、どっちが今強い？',
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
    (text.contains('嬉しい') ||
        text.contains('うれしい') ||
        text.contains('幸せ') ||
        text.contains('楽しい') ||
        text.contains('仲直り') ||
        text.contains('会えた') ||
        text.contains('デート') ||
        text.contains('付き合えた') ||
        text.contains('好きって言われた') ||
        text.contains('記念日'))) {
  return '${pick([
    'よかったね🐶💜\nルナまでうれしくなっちゃった！',
    'その幸せな気持ち、大切にしてね🌙\n今日は少しにこにこして過ごせそうだね。',
    '素敵な時間だったんだね。\n話してくれてありがとう。ルナも心があたたかくなったよ。',
    '大切な人とのうれしい出来事って、心に残るよね。\nどんなところが一番うれしかった？',
    'いいね🐶✨\nその出来事、今日の小さな宝物にしよう。',
  ])}\n\n${getFollowUpQuestion()}';
}

// 返信が来ない専用
if (currentTopic == '恋愛' &&
    (text.contains('返信') ||
     text.contains('既読') ||
     text.contains('未読') ||
     text.contains('LINE'))) {

  return '${pick([

    '返信が来ない時間って、本当に長く感じるよね。\n今どんなことを考えてしまってる？',

    '返信がないだけで、不安がどんどん大きくなることってあるよね。\n今一番心配なのは何かな？',

    '待っている時間って苦しいよね。\n最後に連絡を取ったのはいつ頃？',

    '返信の速さだけで気持ちは決まらないって分かっていても、不安になるよね。\nルナに話してみよう。',

  ])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：会えない
if (currentTopic == '恋愛' &&
    text.contains('会えない')) {
  return '${pick([
    '会いたいのに会えない時間って、心が置いていかれる感じがするよね。\n今いちばん寂しいのはどんな時？',
    '会えない日が続くと、不安も寂しさも大きくなりやすいよね。\n本当はどんな時間を一緒に過ごしたい？',
    '会えないことがつらいんだね。\n次に会える予定は決まっているのかな？',
    '距離があると、相手の気持ちまで遠く感じてしまうことがあるよね。\n今一番確かめたいことは何？',
  ])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：喧嘩
if (currentTopic == '恋愛' &&
    (text.contains('喧嘩') ||
     text.contains('ケンカ'))) {
  return '${pick([
    '喧嘩した後って、怒りだけじゃなくて悲しさや不安も残りやすいよね。\n今いちばん強い気持ちは何かな？',
    '大切な人とぶつかると、心がすごく疲れるよね。\n本当は何を分かってほしかった？',
    '仲直りしたい気持ちと、まだ傷ついている気持ちが両方あるのかな。\nどっちが今大きい？',
    '喧嘩のあとって、相手の言葉を何度も思い出しちゃうことがあるよね。\n一番心に残っている言葉はある？',
  ])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：別れ
if (currentTopic == '恋愛' &&
    (text.contains('別れ') ||
     text.contains('振られ') ||
     text.contains('失恋'))) {
  return '${pick([
    '別れの話って、心が追いつかないくらい苦しいよね。\n今は悲しさ、不安、寂しさのどれが一番近い？',
    '大切だった人とのことだから、すぐに整理できなくて当然だよ。\n今いちばん心に残っていることは何かな？',
    '失った感じがして、胸が重くなることもあるよね。\n今日はここで少し休もう。',
    'まだ好きな気持ちが残っているのかな。\nそれとも、納得できない気持ちが大きい？',
  ])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：片思い
if (currentTopic == '恋愛' &&
    (text.contains('片思い') ||
     text.contains('好きな人') ||
     text.contains('告白'))) {

  return '${pick([

'好きな人のことって、考えないようにしようとしても難しいよね。\n今どんなことが一番気になっている？',

'片思いって、嬉しい気持ちと不安な気持ちが一緒にやってくることがあるよね。\n今日はどんな出来事があったの？',

'相手のちょっとした言葉や態度で、一日中気持ちが揺れてしまうこともあるよね。\n何が一番心に残ってる？',

'「もしかして脈があるのかな？」って期待したり、「違ったのかな」って落ち込んだりすることもあるよね。\n今はどんな気持ちが近い？',

'好きだからこそ、相手の反応が気になってしまうんだと思う。\n最近あった出来事を聞かせてくれる？',

'告白するか迷っているのかな？\n今一番引っかかっていることは何？',

'相手のことを大切に思っているからこそ、不安も大きくなりやすいよね。\n本当はどうなったら嬉しい？',

'片思いって、一人で考えている時間が長くなりがちだよね。\n今どんなことを考えている？',

'ルナには少しドキドキしている心が見えているよ🐶\nその気持ちを話してみて。',

'恋って正解が見えないから迷うことも多いよね。\n今、一番知りたいことは何かな？',

  ])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：復縁
if (currentTopic == '恋愛' &&
    (text.contains('復縁') ||
     text.contains('やり直したい') ||
     text.contains('元彼') ||
     text.contains('元カノ'))) {

  return '${pick([

'やり直したい気持ちがあるんだね。\nどんなところが一番心に残っているのかな？',

'復縁を考えるくらい、大切な相手だったんだね。\n今も連絡は取れているの？',

'別れた後って、「あの時こうしていれば」って考えてしまうこともあるよね。\n今一番後悔していることはある？',

'もう一度やり直したい気持ちと、前に進まなきゃって気持ちが混ざっているのかな。\n今はどっちが近い？',

'相手のことを忘れられない日もあるよね。\n最近思い出したきっかけはあった？',

'復縁したいと思うのは、それだけ大切な時間だったからなんだと思う。\nどんな思い出が一番心に残ってる？',

'今の気持ちを焦って決めなくても大丈夫。\nルナと一緒に少し整理してみよう🐶',

'本当に復縁したいのか、それとも寂しさが大きいのか。\n今の自分はどう感じていると思う？',

])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：遠距離・会えない期間
if (currentTopic == '恋愛' &&
    (text.contains('遠距離') ||
     text.contains('離れてる') ||
     text.contains('距離') ||
     text.contains('会える日がない'))) {

  return '${pick([

'遠距離って、好きな気持ちがあるからこそ寂しさも大きくなるよね。\n最近一番寂しかったのはどんな時？',

'会えない時間が長いと、不安になる日もあるよね。\n今一番心配していることは何かな？',

'会いたい時に会えないのって、本当に苦しいよね。\n次に会える予定は決まっている？',

'距離があると、相手の様子が見えない分、いろんな想像をしてしまうこともあるよね。\n最近どんなことを考えてしまう？',

'離れていても大切に思う気持ちは変わらないこともあるよね。\n今、一番伝えたいことは何かな？',

'遠距離だからこそ、お互いを信じることが難しく感じる日もあるよね。\n今日はどんな気持ち？',

'ルナには少し寂しそうな心が見えているよ🐶\n最近あったことを聞かせてくれる？',

'遠くにいる相手を思う時間って長く感じるよね。\n今は何が一番つらい？',

])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：嫉妬
if (currentTopic == '恋愛' &&
    (text.contains('嫉妬') ||
     text.contains('やきもち') ||
     text.contains('他の女') ||
     text.contains('他の男') ||
     text.contains('異性') ||
     text.contains('不安になる'))) {

  return '${pick([

'嫉妬って、自分でも苦しくなる気持ちだよね。\n今どんな場面が一番引っかかっている？',

'相手を大切に思うほど、他の人との距離が気になってしまうこともあるよね。\n何を見たり聞いたりして不安になった？',

'やきもちを妬く自分を責めなくて大丈夫だよ。\nその奥に、安心したい気持ちがあるのかもしれないね。',

'他の人と比べてしまうと、心がどんどん疲れてしまうよね。\n今一番怖いのは何かな？',

'嫉妬の奥には、「ちゃんと大切にされたい」って気持ちが隠れていることもあるよ。\n本当はどんな言葉がほしい？',

'相手の行動が気になるくらい、不安が大きくなっているんだね。\n最近特に気になった出来事はあった？',

'ルナには、少し不安さんとやきもちさんが見えているよ🐶\n今の気持ちをそのまま聞かせて。',

'嫉妬って、好きな気持ちがあるからこそ出てくることもあるよね。\nでも一人で抱えると苦しくなるから、ここで少し整理しよう。',

])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：浮気・裏切り
if (currentTopic == '恋愛' &&
    (text.contains('浮気') ||
     text.contains('裏切り') ||
     text.contains('裏切られ') ||
     text.contains('嘘つかれ') ||
     text.contains('嘘をつかれ') ||
     text.contains('信じられない'))) {

  return '${pick([

'信じていた相手に傷つけられたように感じると、心がすごく苦しくなるよね。\n今いちばんつらいのは何かな？',

'浮気や裏切りの不安って、頭から離れにくいよね。\n何がきっかけでそう感じたの？',

'相手を信じたい気持ちと、もう信じられない気持ちがぶつかっているのかな。\n今はどっちが大きい？',

'嘘をつかれたように感じると、自分まで責めてしまうことがあるよね。\nでも傷ついた気持ちは大事にしていいよ。',

'本当のことを知りたい気持ちと、知るのが怖い気持ちが混ざっているのかもしれないね。\n今一番確認したいことは何？',

'ルナには、かなり傷ついた心が見えているよ🐶\nここでは無理に平気なふりをしなくて大丈夫。',

'信頼が揺れる出来事があると、安心するのが難しくなるよね。\n何が一番引っかかっている？',

'今すぐ答えを出さなくても大丈夫。\nまずは「事実」と「想像」を一緒に分けてみよう。',

])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：告白
if (currentTopic == '恋愛' &&
    (text.contains('告白') ||
     text.contains('伝えたい') ||
     text.contains('気持ちを伝えたい') ||
     text.contains('好きって言いたい'))) {

  return '${pick([

'告白って、勇気がいるよね。\n今、一番迷っていることは何かな？',

'気持ちを伝えたいけど、結果を考えると怖くなってしまうこともあるよね。\n今どんな不安がある？',

'好きだからこそ、今の関係が変わるのが怖いのかな。\n本当はどうなったら嬉しい？',

'タイミングって難しいよね。\n今「今じゃないかも」って思う理由はある？',

'相手の反応を想像すると、なかなか一歩踏み出せないこともあるよね。\n何が一番心配？',

'ルナにはドキドキしている心が見えているよ🐶\nその気持ちを聞かせてくれる？',

'告白するか迷う時間も、大切な恋の時間なんだと思う。\n相手のどんなところが好きなの？',

'どんな結果になっても、その気持ちは本物なんだと思う。\nルナと一緒に少し整理してみよう。',

])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：倦怠期・マンネリ
if (currentTopic == '恋愛' &&
    (text.contains('倦怠期') ||
     text.contains('マンネリ') ||
     text.contains('前みたいじゃない') ||
     text.contains('冷めた') ||
     text.contains('飽きられた'))) {

  return '${pick([

'前みたいじゃないと感じると、不安になってしまうよね。\n最近そう感じた出来事はあった？',

'関係が落ち着いてきたのか、それとも距離ができたのか、判断が難しいこともあるよね。\n何が一番気になっている？',

'相手の気持ちが変わってしまったんじゃないかって考えると苦しくなるよね。\n最近どんなことがあった？',

'一緒にいる時間が長くなると、関係が少し変わることもあるよね。\n今はどんな関係になれたら嬉しい？',

'以前より連絡や会話が減ると、不安になってしまうこともあるよね。\n一番寂しいと感じるのはどんな時？',

'ルナには少し心配そうな気持ちが見えているよ🐶\n今の気持ちを聞かせてくれる？',

'「嫌われたのかな」って考えてしまう日もあるよね。\nそのきっかけは何だった？',

'焦って答えを出そうとしなくても大丈夫。\nまずは今の気持ちを一緒に整理してみよう。',

  ])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：仲直りしたい
if (currentTopic == '恋愛' &&
    (text.contains('仲直り') ||
     text.contains('謝りたい') ||
     text.contains('仲直りしたい') ||
     text.contains('許してほしい'))) {

  return '${pick([

'仲直りしたいと思うくらい、その人を大切に思っているんだね。\n今一番伝えたいことは何かな？',

'謝りたい気持ちはあるけど、どう伝えたらいいか迷っているのかな。\n何が一番不安？',

'喧嘩のあとって、お互いに声をかけるタイミングが難しいよね。\n今どんな状況なの？',

'仲直りしたい気持ちと、傷ついた気持ちが両方あるのかな。\n今はどっちが大きい？',

'本当は素直になりたいのに、なかなか一歩踏み出せないこともあるよね。\n何が引っかかっている？',

'ルナは仲直りしたいって思える優しさも大切だと思うよ🐶\nその気持ちをもう少し聞かせて。',

'焦って答えを出さなくても大丈夫。\nまずは今の気持ちを整理してみよう。',

'きっと相手との関係を大切にしたいからこそ悩んでいるんだね。\nどうなったら一番嬉しい？',

  ])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：恋愛に自信がない・恋人ができない
if (currentTopic == '恋愛' &&
    (text.contains('恋人ができない') ||
     text.contains('恋愛できない') ||
     text.contains('自信がない') ||
     text.contains('モテない') ||
     text.contains('誰にも好きになってもらえない') ||
     text.contains('恋愛向いてない'))) {

  return '${pick([

'恋愛に自信が持てない日ってあるよね。\n最近そう感じたきっかけは何だったのかな？',

'「自分なんて…」って思ってしまうくらい苦しかったんだね。\nどんなことが一番心に残っている？',

'恋愛って周りと比べてしまうことも多いよね。\n今、一番気になっていることは何かな？',

'恋人ができないと、「自分に魅力がないのかな」って考えてしまうこともあるよね。\n最近そんな風に感じた出来事はあった？',

'焦る気持ちもあるのかな。\nルナは、自分のペースで進んでも大丈夫だと思うよ🐶',

'恋愛がうまくいかない時って、自分を責めてしまうことがあるよね。\n本当はどんな恋愛がしたい？',

'周りが幸せそうに見えると、自分だけ取り残されたように感じることもあるよね。\n今どんな気持ち？',

'ルナは、恋愛だけで人の価値が決まることはないと思ってるよ🐶\nまずは今の気持ちを聞かせて。',

])}\n\n${getFollowUpQuestion()}';
}

// 恋愛：恋愛に自信がない・恋人ができない
if (currentTopic == '恋愛' &&
    (text.contains('恋人ができない') ||
     text.contains('恋愛できない') ||
     text.contains('自信がない') ||
     text.contains('モテない') ||
     text.contains('誰にも好きになってもらえない') ||
     text.contains('恋愛向いてない'))) {

  return '${pick([

'恋愛に自信が持てない日ってあるよね。\n最近そう感じたきっかけは何だったのかな？',

'「自分なんて…」って思ってしまうくらい苦しかったんだね。\nどんなことが一番心に残っている？',

'恋愛って周りと比べてしまうことも多いよね。\n今、一番気になっていることは何かな？',

'恋人ができないと、「自分に魅力がないのかな」って考えてしまうこともあるよね。\n最近そんな風に感じた出来事はあった？',

'焦る気持ちもあるのかな。\nルナは、自分のペースで進んでも大丈夫だと思うよ🐶',

'恋愛がうまくいかない時って、自分を責めてしまうことがあるよね。\n本当はどんな恋愛がしたい？',

'周りが幸せそうに見えると、自分だけ取り残されたように感じることもあるよね。\n今どんな気持ち？',

'ルナは、恋愛だけで人の価値が決まることはないと思ってるよ🐶\nまずは今の気持ちを聞かせて。',

])}\n\n${getFollowUpQuestion()}';
}
// ←今ある恋愛全般

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

'相手のことを大切に思うほど、少しの変化でも気になってしまうよね。\n今いちばん引っかかっているのはどんなこと？',

'不安になるのは、ちゃんと向き合いたい気持ちがあるからかもしれないね。\n本当はどうなったら安心できそう？',

'好きな人のことって、頭では落ち着こうとしても心が先に反応しちゃうことがあるよね。\n今は寂しさと不安、どっちが近い？',

'相手の言葉や態度を何度も思い出してしまう感じかな。\nその中で一番忘れられない場面はある？',

'恋愛って、嬉しい時間がある分だけ不安も大きくなりやすいよね。\n今は何を一番確かめたい気持ち？',


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

if (currentTopic == '将来' &&
    (text.contains('不安') ||
     text.contains('怖い') ||
     text.contains('心配'))) {

  return '${pick([
    '未来のことって、考えれば考えるほど不安になることがあるよね。\n今、一番心配なことは何かな？',
    '将来に正解はないからこそ迷うんだと思う。\nどんな未来を思い描いている？',
    '焦る気持ちもあるのかな。\nルナはゆっくりでも大丈夫だと思うよ🐶',
    '今の不安を少しずつ言葉にしていこう。\n整理すると見えてくるものもあるよ。',
  ])}\n\n${getFollowUpQuestion()}';
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



    // 家族
    // 家族
if (text.contains('家族') ||
    text.contains('母') ||
    text.contains('父') ||
    text.contains('親') ||
    text.contains('兄') ||
    text.contains('姉') ||
    text.contains('弟') ||
    text.contains('妹')) {

  final isPositive =
      text.contains('嬉しい') ||
      text.contains('うれしい') ||
      text.contains('楽しい') ||
      text.contains('仲良く') ||
      text.contains('褒められた') ||
      text.contains('ほめられた') ||
      text.contains('応援してくれた') ||
      text.contains('ご飯') ||
      text.contains('旅行') ||
      text.contains('話せた') ||
      text.contains('安心') ||
      text.contains('ありがとう');

  if (isPositive) {
    return pick([
      'それはあたたかい時間だったんだね🐶🌙\n家族とのうれしい出来事って、心に残るよね。',
      'よかったね。\n少し安心できる時間があったみたいで、ルナもうれしいよ。',
      '家族といい時間を過ごせたんだね🐶\nどんなところが一番うれしかった？',
      'その出来事、大切にしていいと思う。\n心が少しほっとしたのかな。',
    ]);
  }

  return pick([
    '家族のことって、距離が近いぶん心が揺れやすいよね。',
    'わかってほしい気持ちと、離れたい気持ちが両方ある感じかな。',
    '責められた感じ？それとも理解されない感じ？',
    '簡単に割り切れないからこそ苦しいよね。',
    '家族だからこそ言えないこともあるよね。\nここではそのまま話して大丈夫だよ。',
  ]);
}
      // 将来
// 将来・人生・お金
if (text.contains('将来') ||
    text.contains('人生') ||
    text.contains('夢') ||
    text.contains('目標') ||
    text.contains('就職') ||
    text.contains('転職') ||
    text.contains('一人暮らし') ||
    text.contains('お金') ||
    text.contains('貯金')) {

  final isPositive =
      text.contains('楽しみ') ||
      text.contains('嬉しい') ||
      text.contains('うれしい') ||
      text.contains('決まった') ||
      text.contains('受かった') ||
      text.contains('合格') ||
      text.contains('成功') ||
      text.contains('叶った') ||
      text.contains('達成') ||
      text.contains('自信');

  if (isPositive) {
    return pick([
      'それは本当にうれしいね🐶✨\n少しずつ夢に近づいているんだね。',
      '努力してきたことが形になったんだね🌙\nルナもすごくうれしいよ。',
      '未来が楽しみになってきたんだね。\nその気持ちを大切にしていこう。',
      '一歩前に進めたね🐶\nこれからもルナが応援してるよ。',
    ]);
  }

  return pick([
    '将来のことを考えると、不安になる日もあるよね。',
    '答えがまだ見えないからこそ、心配になるのは自然なことだよ。',
    '未来のことを一人で抱え込まなくて大丈夫。\nルナと一緒に少しずつ整理していこう。',
    '今いちばん気になっているのは、仕事？お金？それともこれからの生活かな？',
    '未来はまだ決まっていないからこそ、不安も希望もあるんだと思う。\n今の気持ちを聞かせてくれる？',
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
  child: Column(
  children: [
    Row(
      children: [
        Image.asset(
          'assets/images/luna.png',
        height: 45,
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COCOON',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'おかえり。\n今日はどんなことがあった？',
                style: AppTextStyles.body.copyWith(
                  height: 1.5,
                  color: const Color(0xFF6D6478),
                ),
              ),
            ],
          ),
        ),
      ],
    ),

    const SizedBox(height: 10),

    const Text(
      'COCOONは医療・専門相談の代わりではありません。危険を感じる時は、すぐに身近な人や緊急窓口に連絡してください。',
      style: TextStyle(
        fontSize: 12,
        color: Color(0xFF8A7D96),
      ),
      textAlign: TextAlign.center,
    ),
  ],
),
            ),
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  margin: EdgeInsets.fromLTRB(
    16,
    isLunaCardCollapsed ? 6 : 10,
    16,
    6,
  ),
  padding: EdgeInsets.all(
    isLunaCardCollapsed ? 8 : 12,
  ),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(
      isLunaCardCollapsed ? 18 : 24,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: isLunaCardCollapsed ? 10 : 16,
        offset: const Offset(0, 5),
      ),
    ],
  ),
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    child: isLunaCardCollapsed
        ? Row(
            key: const ValueKey('smallLunaCard'),
            children: [
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4ECFA),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/luna.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ルナはここで聞いてるよ🐶',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F5B8E),
                  ),
                ),
              ),
            ],
          )
        : Row(
            key: const ValueKey('largeLunaCard'),
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4ECFA),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/luna.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🐶 ルナ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F5B8E),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'おかえり🌱\n今日は何を話そうか？',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6574),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
  Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFFFFF2F6),
        Color(0xFFF6EAF4),
      ],
    ),
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
    border: Border.all(
      color: const Color(0xFFE8CFE0),
    ),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => sendQuickTopic('恋愛のことで話したい'),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '💔',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(width: 8),
            Text(
              '恋愛相談',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C536C),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
 Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFFFFF8E8),
        Color(0xFFFFF1CC),
      ],
    ),
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
    border: Border.all(
      color: Color(0xFFEFD89B),
    ),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => sendQuickTopic('不安な気持ちを整理したい'),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('😰', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              '不安を整理',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8C6A00),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFFEAF1FF),
        Color(0xFFDCE8FF),
      ],
    ),
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
    border: Border.all(
      color: Color(0xFFC7D8FF),
    ),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => sendQuickTopic('眠れない夜でつらい'),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌙', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              '眠れない夜',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5066A8),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFFEFFAF0),
        Color(0xFFDDF3E0),
      ],
    ),
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
    border: Border.all(
      color: Color(0xFFC9E5CE),
    ),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => sendQuickTopic('家族のことで悩んでいる'),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏠', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              '家族のこと',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D7A52),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFFF4EEFF),
        Color(0xFFE9DEFF),
      ],
    ),
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
    border: Border.all(
      color: Color(0xFFD9C8FF),
    ),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => sendQuickTopic('ただ話を聞いてほしい'),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🫂', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              '話を聞いて',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6F5B8E),
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
    ),
  ),
),

Expanded(
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF8F4FC),
          Color(0xFFFFFFFF),
        ],
      ),
    ),
    child: Column(
      children: [
      Expanded(
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(18),
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            return ChatBubble(
              message: widget.messages[index],
            );
          },
        ),
      ),

      if (isThinking)
        const ThinkingBubble(),
    ],
  ),
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
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onFieldSubmitted: (_) => sendMessage(),
            ),
          ),
         Container(
  width: 52,
  height: 52,
  decoration: BoxDecoration(
    color: AppColors.accent,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.12),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
 child: IconButton(
  onPressed: sendMessage,
  icon: Image.asset(
    'assets/images/paw.png',
    width: 24,
    height: 24,
  ),
),
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
    final bool isUser = message.isUser;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 14,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EAF8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE0D2EC),
                ),
              ),
              child: Image.asset(
                'assets/images/luna.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 4,
                      bottom: 4,
                    ),
                    child: Text(
                      'ルナ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8A7D96),
                      ),
                    ),
                  ),

                Container(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF8E7BBE)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(
                        isUser ? 20 : 5,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? 5 : 20,
                      ),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: const Color(0xFFE9E1EF),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isUser
                          ? Colors.white
                          : const Color(0xFF514A59),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({super.key});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 18, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final dotCount = ((controller.value * 3).floor() + 1);

            return Text(
              '🐶 ルナが考え中${'.' * dotCount}',
              style: const TextStyle(
                color: Color(0xFF8E7BBE),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            );
          },
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
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE8DFEE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFF4ECFA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F5B8E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF6D6478),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            const Icon(
              Icons.chevron_right_rounded,
              size: 26,
              color: Color(0xFF9A8AAC),
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
               Container(
  width: double.infinity,
  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.90),
    borderRadius: BorderRadius.circular(26),
    border: Border.all(
      color: const Color(0xFFE8DFEE),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFFF1E8F8),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '🌳',
            style: TextStyle(fontSize: 26),
          ),
        ),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '心の広場',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6F5B8E),
              ),
            ),
            SizedBox(height: 5),
            Text(
              '今日はどこで休んでいく？\nルナと一緒に、今の心に合う場所を探そう🐶',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF6D6478),
              ),
            ),
          ],
        ),
      ),
    ],
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

Column(
  children: [
    areaCard(
      '🌲',
      '深呼吸の森',
      '3分でリセット',
      onTap: widget.onBreathing,
    ),

    const SizedBox(height: 12),

    areaCard(
      '☕',
      'ひとやすみカフェ',
      'やさしい言葉で一息',
      onTap: widget.onCafe,
    ),

    const SizedBox(height: 12),

    areaCard(
      '🌙',
      '夜の避難所',
      '眠れない夜の安心',
      onTap: widget.onNightShelter,
    ),

    const SizedBox(height: 12),

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
   body: SizedBox.expand(
  child: Container(
    decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/breath_forest_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.white.withOpacity(0.25),
        child: SafeArea(
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
                      color: Colors.white.withOpacity(0.85),
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
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileSetupScreen(),
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
    child: const Column(
      children: [
        Text(
          '🌱 あなたのこと',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E7BBE),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'ルナにあなたのことを教える',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF6D6478),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 16),

GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTimelineScreen(),
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
      children: const [
        Text(
          '🌱 わたし年表',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E7BBE),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '人生の出来事を記録する',
          style: TextStyle(
            fontSize: 15,
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
  body: SizedBox.expand(
    child: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/images/cafe_bg.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.white.withOpacity(0.20),
        child: SafeArea(
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
  body: SizedBox.expand(
    child: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/images/night_shelter_bg.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black54,
        child: SafeArea(
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
  appBar: AppBar(
  title: const Text('ルナのおうち'),
  backgroundColor: const Color(0xFF8E7BBE),
  foregroundColor: Colors.white,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: widget.onBack,
  ),
),
     body: SizedBox.expand(
  child: Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage(
          'assets/images/luna_home_bg.png',
        ),
        fit: BoxFit.cover,
      ),
    ),
    child: Container(
      color: Colors.white.withOpacity(0.15),
      child: SafeArea(
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
                  color: Colors.white,
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
    color: Colors.white,
  ),
),

const SizedBox(height: 8),

Text(
  '❤️ なつき度 $affection/100',
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
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

class TimelineEvent {
  final int year;
  final String title;
  final String category;

  TimelineEvent({
    required this.year,
    required this.title,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'title': title,
      'category': category,
    };
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      year: json['year'],
      title: json['title'],
      category: json['category'] ?? 'その他',
    );
  }
}

class JapanEvent {
  final int year;
  final String title;
  final String category;
  final String description;
  final List<String> keywords;
  final List<String> emotions;
  final int? affectedAgeMin;
  final int? affectedAgeMax;

  JapanEvent({
    required this.year,
    required this.title,
    required this.category,
    required this.description,
    required this.keywords,
    required this.emotions,
    this.affectedAgeMin,
    this.affectedAgeMax,
  });

  factory JapanEvent.fromJson(Map<String, dynamic> json) {
    final affectedAge = json['affectedAge'];

    return JapanEvent(
      year: json['year'],
      title: json['title'],
      category: json['category'],
      description: json['description'],

      // keywordsがない古いデータでもエラーにならない
      keywords: List<String>.from(
        json['keywords'] ?? [],
      ),

      // emotionsがない古いデータでもエラーにならない
      emotions: List<String>.from(
        json['emotions'] ?? [],
      ),

      // affectedAgeがないデータでもエラーにならない
      affectedAgeMin: affectedAge is Map
          ? affectedAge['min'] as int?
          : null,

      affectedAgeMax: affectedAge is Map
          ? affectedAge['max'] as int?
          : null,
    );
  }
}


class MyTimelineScreen extends StatefulWidget {
  const MyTimelineScreen({super.key});

  @override
  State<MyTimelineScreen> createState() => _MyTimelineScreenState();
}

class _MyTimelineScreenState extends State<MyTimelineScreen> {
final List<TimelineEvent> events = [];


  @override
void initState() {
  super.initState();
  loadTimelineEvents();
}

Future<void> saveTimelineEvents() async {
  final prefs = await SharedPreferences.getInstance();

  final encoded = jsonEncode(
    events.map((event) => event.toJson()).toList(),
  );

  await prefs.setString('timelineEvents', encoded);
}

Future<void> loadTimelineEvents() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('timelineEvents');

  if (saved == null) return;

  final List decoded = jsonDecode(saved);

  setState(() {
    events
      ..clear()
      ..addAll(
        decoded.map(
          (item) => TimelineEvent.fromJson(item),
        ),
      );
  });
}

void addEvent() {
  final yearController = TextEditingController();
  final titleController = TextEditingController();

  String selectedCategory = 'その他';

final categories = [
  '恋愛',
  '家族',
  '仕事',
  '学校',
  '健康',
  '成長',
  '思い出',
  'その他',
];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('出来事を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '年',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '出来事',
              ),
            ),

            const SizedBox(height: 12),

DropdownButtonFormField<String>(
  value: selectedCategory,
  decoration: const InputDecoration(
    labelText: 'カテゴリー',
  ),
  items: categories.map((category) {
    return DropdownMenuItem(
      value: category,
      child: Text(category),
    );
  }).toList(),
  onChanged: (value) {
    if (value == null) return;
    selectedCategory = value;
  },
),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (yearController.text.isEmpty ||
                  titleController.text.isEmpty) {
                return;
              }

              setState(() {
                events.add(
                 TimelineEvent(
  year: int.parse(yearController.text),
  title: titleController.text,
  category: selectedCategory,
),
                );

                events.sort(
                  (a, b) => a.year.compareTo(b.year),
                );
              });

              await saveTimelineEvents();

              Navigator.pop(context);
            },
            child: const Text('追加'),
          ),
        ],
      );
    },
  );
}

void editEvent(TimelineEvent event) {
  final yearController = TextEditingController(
    text: event.year.toString(),
  );

  final titleController = TextEditingController(
    text: event.title,
  );

  String selectedCategory = event.category;

  const categories = [
    '恋愛',
    '家族',
    '仕事',
    '学校',
    '健康',
    '成長',
    '思い出',
    'その他',
  ];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('出来事を編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '年'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '出来事'),
            ),
            const SizedBox(height: 12),

DropdownButtonFormField<String>(
  value: selectedCategory,
  decoration: const InputDecoration(
    labelText: 'カテゴリー',
  ),
  items: categories.map((category) {
    return DropdownMenuItem(
      value: category,
      child: Text(category),
    );
  }).toList(),
  onChanged: (value) {
    if (value == null) return;
    selectedCategory = value;
  },
),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (yearController.text.isEmpty ||
                  titleController.text.isEmpty) {
                return;
              }

              setState(() {
                final index = events.indexOf(event);

               events[index] = TimelineEvent(
  year: int.parse(yearController.text),
  title: titleController.text,
  category: selectedCategory,
);

                events.sort((a, b) => a.year.compareTo(b.year));
              });
            

              await saveTimelineEvents();

              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      );
    },
  );
}

String getCategoryEmoji(String category) {
  switch (category) {
    case '恋愛':
      return '💕';
    case '家族':
      return '👨‍👩‍👧';
    case '仕事':
      return '💼';
    case '学校':
      return '🎓';
    case '健康':
      return '❤️';
    case '成長':
      return '🌱';
    case '思い出':
      return '📸';
    default:
      return '📌';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('わたし年表'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '🌱 わたし年表',
              style: AppTextStyles.heading.copyWith(
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'あなたの歩いてきた時間を、少しずつ残していこう。',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),

            if (events.isEmpty)
  CocoonCard(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Text(
          '🌱',
          style: TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 12),
        Text(
          'まだ年表はありません',
          style: AppTextStyles.title.copyWith(
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'あなたの人生を\n少しずつ残していこう。',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
      ],
    ),
  ),

const SizedBox(height: 20),

if (events.isEmpty)
  CocoonCard(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Image.asset(
          'assets/images/luna.png',
          height: 90,
        ),

        const SizedBox(height: 16),

        Text(
          'ルナより 🐶',
          style: AppTextStyles.title.copyWith(
            color: AppColors.accent,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'ここは、あなたの人生を残していく場所だよ。\n\n'
          'うれしかったことも、\n'
          'つらかったことも、\n'
          '全部あなたの大切な足あと。\n\n'
          '最初の一歩を書いてみよう🌱',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            height: 1.7,
          ),
        ),
      ],
    ),
  ),

const SizedBox(height: 20),

            ...events.map(
              (event) => CocoonCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Text(
                      '${event.year}',
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${getCategoryEmoji(event.category)} ${event.category}',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.accent,
        ),
      ),

      const SizedBox(height: 4),

      Text(
        event.title,
        style: AppTextStyles.body,
      ),
    ],
  ),
),

                    IconButton(
  icon: const Icon(Icons.edit_outlined),
  color: AppColors.accent,
  onPressed: () => editEvent(event),
),

                    IconButton(
  icon: const Icon(Icons.delete_outline),
  color: AppColors.textSecondary,
 onPressed: () async {
  setState(() {
    events.remove(event);
  });

  await saveTimelineEvents();
},
),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: addEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('＋ 出来事を追加'),
            ),
          ],
        ),
      ),
    );
  }
}
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  DateTime? birthday;
  String birthOrder = '';
  String siblings = '';
  String familyStyle = '';
  String currentStatus = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();

    if (birthday != null) {
      await prefs.setString('birthday', birthday!.toIso8601String());
    }

    await prefs.setString('birthOrder', birthOrder);
    await prefs.setString('siblings', siblings);
    await prefs.setString('familyStyle', familyStyle);
    await prefs.setString('currentStatus', currentStatus);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ルナに教えてくれてありがとう🌱')),
    );
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBirthday = prefs.getString('birthday');

    setState(() {
      if (savedBirthday != null) {
        birthday = DateTime.parse(savedBirthday);
      }

      birthOrder = prefs.getString('birthOrder') ?? '';
      siblings = prefs.getString('siblings') ?? '';
      familyStyle = prefs.getString('familyStyle') ?? '';
      currentStatus = prefs.getString('currentStatus') ?? '';
    });
  }

  Widget profileCard({
    required String icon,
    required String title,
    required String value,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return CocoonCard(
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 26)),
        title: Text(title),
        subtitle: Text(value.isEmpty ? 'まだ設定していません' : value),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await showModalBottomSheet<String>(
            context: context,
            builder: (_) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
                    return ListTile(
                      title: Text(option),
                      onTap: () => Navigator.pop(context, option),
                    );
                  }).toList(),
                ),
              );
            },
          );

          if (result != null) {
            onSelected(result);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🌱 あなたのこと'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'ルナは、あなたのことをもっと知りたいな🐶\n正解はないから、今のあなたに近いものを教えてね。',
            style: AppTextStyles.body.copyWith(height: 1.6),
          ),

          const SizedBox(height: 24),

          CocoonCard(
            child: ListTile(
              leading: const Text('🎂', style: TextStyle(fontSize: 26)),
              title: const Text('生年月日'),
              subtitle: Text(
                birthday == null
                    ? 'まだ設定していません'
                    : '${birthday!.year}/${birthday!.month}/${birthday!.day}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: birthday ?? DateTime(2000),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() {
                    birthday = picked;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          profileCard(
            icon: '👶',
            title: '出生順位',
            value: birthOrder,
            options: const ['長女', '長男', '真ん中', '末っ子', '一人っ子', 'その他'],
            onSelected: (value) {
              setState(() {
                birthOrder = value;
              });
            },
          ),

          const SizedBox(height: 16),

          profileCard(
            icon: '👨‍👩‍👧‍👦',
            title: '兄弟姉妹',
            value: siblings,
            options: const ['一人っ子', '2人きょうだい', '3人きょうだい', '4人以上', '答えたくない'],
            onSelected: (value) {
              setState(() {
                siblings = value;
              });
            },
          ),

          const SizedBox(height: 16),

          profileCard(
            icon: '🏠',
            title: '家族との距離感',
            value: familyStyle,
            options: const ['近い', '普通', '少し距離がある', '複雑', '答えたくない'],
            onSelected: (value) {
              setState(() {
                familyStyle = value;
              });
            },
          ),

          const SizedBox(height: 16),

          profileCard(
            icon: '💼',
            title: '現在の状況',
            value: currentStatus,
            options: const ['学生', '社会人', '休職中', '転職活動中', '主婦・主夫', 'その他'],
            onSelected: (value) {
              setState(() {
                currentStatus = value;
              });
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                '保存する',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}