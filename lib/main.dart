import 'firebase_web_registration_stub.dart'
    if (dart.library.js_interop)
        'firebase_web_registration_web.dart';
import 'screens/kokoro_hiroba_screen_v5.dart';
import 'services/weather_service.dart';
import 'screens/chat_screen.dart';
import 'screens/mood_record_screen.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_contact_screen.dart';
import 'models/emergency_contact.dart';
import 'screens/my_page_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/mood_calendar_screen.dart';
import 'screens/recovery_album_screen.dart';
import 'models/chat_message_model.dart';
import 'models/luna_memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cocoon/theme/app_colors.dart';
import 'package:cocoon/theme/app_text_styles.dart';
import 'package:cocoon/widgets/cocoon_card.dart';
import 'package:cocoon/models/mood_record.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

const String openWeatherApiKey = String.fromEnvironment(
  'OPENWEATHER_API_KEY',
);


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFirebaseWebPlugins();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CocoonApp());
}

class CocoonApp extends StatefulWidget {
  const CocoonApp({super.key});

  @override
  State<CocoonApp> createState() => _CocoonAppState();
}

class _CocoonAppState extends State<CocoonApp> {
  bool isLoading = true;
  bool hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    loadOnboardingStatus();
  }

  Future<void> loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      hasSeenOnboarding =
          prefs.getBool('hasSeenOnboarding') ?? false;
      isLoading = false;
    });
  }

Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool('hasSeenOnboarding', true);

  // 👇初回ホームで歓迎メッセージを表示
  await prefs.setBool('showFirstHomeWelcome', true);

  if (!mounted) return;

  setState(() {
    hasSeenOnboarding = true;
  });
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COCOON',
      theme: ThemeData(useMaterial3: true),
      home: isLoading
          ? const Scaffold(
              backgroundColor: Color(0xFFF8F3FA),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8E7BBE),
                ),
              ),
            )
          : hasSeenOnboarding
              ? const MainScreen()
              : OnboardingScreen(
                  onComplete: completeOnboarding,
                ),
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
    id: 'happy',
    key: '😊 うれしい',
    name: 'うれしいさん',
    imagePath: 'assets/images/emotion_happy.png',
    guideText:
        'うれしいさんが来ているね。うれしい気持ちを、一緒に味わおう。',
  ),
  EmotionInfo(
    id: 'effort',
    key: '🥹 がんばった',
    name: 'がんばったさん',
    imagePath: 'assets/images/emotion_effort.png',
    guideText:
        'がんばったさんが来ているね。今日の頑張りを聞かせてね。',
  ),

    EmotionInfo(
    id: 'sad',
    key: '😢 悲しい',
    name: '悲しいさん',
    imagePath: 'assets/images/emotion_sad.png',
    guideText:
        '悲しいさんが来ているね。話したくなったら、ゆっくり聞かせてね。',
  ),
  EmotionInfo(
    id: 'anxiety',
    key: '😰 不安',
    name: '不安さん',
    imagePath: 'assets/images/emotion_anxiety.png',
    guideText: '不安さんが今日は少し落ち着かないみたい。',
  ),
  EmotionInfo(
    id: 'peace',
    key: '😌 安心',
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
String chatBackgroundPath =
    'assets/images/chat_bg_default.png';
MoodRecord? latestMood;
MoodRecord? previousMood;
List<MoodRecord> moodHistory = [];
List<LunaMemory> lunaMemories = [];
String? petImagePath;
int lunaBond = 0;

// 🐶 ルナの成長レベル
int get lunaLevel {
  if (lunaBond >= 100) return 4;
  if (lunaBond >= 50) return 3;
  if (lunaBond >= 20) return 2;
  return 1;
}

// 🌷 レベルごとの名前
String get lunaLevelName {
  switch (lunaLevel) {
    case 4:
      return 'ずっと一緒';
    case 3:
      return 'たいせつな友達';
    case 2:
      return 'なかよし';
    default:
      return 'はじめまして';
  }
}

int streakDays = 1;
DateTime? lastMoodDate;
bool showFirstHomeWelcome = false;
/*  */
Future<void> loadChatBackground() async {
  final prefs = await SharedPreferences.getInstance();

  final savedPath = prefs.getString('chatBackgroundPath');

  if (!mounted) return;

  setState(() {
    chatBackgroundPath =
        savedPath ?? 'assets/images/chat_bg_default.png';
  });
}

Future<void> saveChatBackground(String newPath) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'chatBackgroundPath',
    newPath,
  );

  if (!mounted) return;

  setState(() {
    chatBackgroundPath = newPath;
  });
}

@override
void initState() {
  super.initState();
  loadPetImage();
  loadChatBackground();
  loadChatMessages();
  loadMoodRecord();
  loadMoodHistory();
  loadLunaBond();
  loadStreak();
  loadLunaMemories();
  loadFirstHomeWelcome();
}

Future<void> loadFirstHomeWelcome() async {
  final prefs = await SharedPreferences.getInstance();
  final shouldShow =
      prefs.getBool('showFirstHomeWelcome') ?? false;

  if (!mounted) return;

  setState(() {
    showFirstHomeWelcome = shouldShow;
  });
}

Future<void> closeFirstHomeWelcome() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool(
    'showFirstHomeWelcome',
    false,
  );

  if (!mounted) return;

  setState(() {
    showFirstHomeWelcome = false;
  });
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

// 🐶 ポイント追加前のレベルを記録
final oldLevel = lunaLevel;

setState(() {
  previousMood = latestMood;
  latestMood = mood;
  moodHistory.add(mood);
  lunaBond += 2;
});

// 🌷 レベルアップしたか確認
final newLevel = lunaLevel;

if (newLevel > oldLevel && mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF8E7BBE),
      duration: const Duration(seconds: 4),
      content: Text(
        '🐶 おめでとう！ルナがLv.$newLevel「$lunaLevelName」になったよ🌸',
      ),
    ),
  );
}

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

onOpenMood: () {
  setState(() => selectedIndex = 1);
},
onOpenMyPage: () {
  setState(() => selectedIndex = 4);
},
onOpenLunaHouse: goToLunaHouse,
onOpenChat: () {
  setState(() => selectedIndex = 2);
},

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
  chatBackgroundPath: chatBackgroundPath,
),


KokoroHirobaScreenV5(
  latestMood: latestMood,
  onListenEmotion: (emotionId) {
    final emotion = emotionInfos.firstWhere(
      (item) => item.id == emotionId,
      orElse: () => emotionInfos.first,
    );

    goToChatWithEmotion(emotion);
  },
  onBreathing: goToBreathingGuide,
  onCafe: goToCafe,
  onNightShelter: goToNightShelter,
  onLunaHouse: goToLunaHouse,
),


MyPageScreen(
  moodHistory: moodHistory,
  lunaBond: lunaBond,
  streakDays: streakDays,
  currentChatBackgroundPath: chatBackgroundPath,
  onChatBackgroundChanged: (newPath) {
  saveChatBackground(newPath);
},
),

BreathingGuideScreen(onBack: goToKokoroHiroba),
HitoyasumiCafeScreen(onBack: goToKokoroHiroba),
NightShelterScreen(onBack: goToKokoroHiroba),
LunaHouseScreen(onBack: goToKokoroHiroba),
];






return Scaffold(
  backgroundColor: const Color(0xFFF8F3FA),
  body: Stack(
    children: [
      pages[selectedIndex],

      if (showFirstHomeWelcome && selectedIndex == 0)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.35),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                    ),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFBFF),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/luna.png',
                          height: 150,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'おかえり。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6F5B8E),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          '今日からここが、\n'
                          'あなたの帰ってこられる場所に\n'
                          'なれたらうれしいな🌱\n\n'
                          '無理をしなくても大丈夫。\n'
                          'ぼくはいつでもここにいるよ。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.65,
                            color: Color(0xFF6D6478),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: closeFirstHomeWelcome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF8E7BBE),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              '🌱 はじめよう',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  ),

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
  State<KokoroHirobaScreen> createState() =>
      _KokoroHirobaScreenState();
}

class _KokoroHirobaScreenState
    extends State<KokoroHirobaScreen> {
  WeatherData? weatherData;
  bool isWeatherLoading = true;
  String? weatherError;
  bool lunaEnteredGarden = false;
  String selectedEmotionId = 'anxiety';
  String? customMessage;

  EmotionInfo get selectedEmotion {
    return emotionInfos.firstWhere(
      (emotion) => emotion.id == selectedEmotionId,
      orElse: () => emotionInfos.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectEmotionFromLatestMood();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
  if (openWeatherApiKey.isEmpty) {
    setState(() {
      isWeatherLoading = false;
      weatherError = 'APIキーが設定されていません';
    });
    return;
  }

  try {
    final service = WeatherService(
      apiKey: openWeatherApiKey,
    );

    final result = await service.getCurrentWeather();

    if (!mounted) return;

    setState(() {
      weatherData = result;
      isWeatherLoading = false;
      weatherError = null;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isWeatherLoading = false;
      weatherError = e.toString();
    });
  }
}

  void _selectEmotionFromLatestMood() {
    final mood = widget.latestMood;

    if (mood == null || mood.emotionPercents.isEmpty) {
      return;
    }

    EmotionInfo strongestEmotion = emotionInfos.first;
    double highestPercent = -1;

    for (final emotion in emotionInfos) {
      final percent = mood.emotionPercents[emotion.key] ?? 0;

      if (percent > highestPercent) {
        highestPercent = percent;
        strongestEmotion = emotion;
      }
    }

    selectedEmotionId = strongestEmotion.id;
  }

  String get greeting {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return 'おはよう。\n今日もあなたのペースで大丈夫だよ。';
    }

    if (hour >= 11 && hour < 17) {
      return 'おかえり。\nここで少し、ほっとしよう。';
    }

    if (hour >= 17 && hour < 22) {
      return '今日もここまで、よく頑張ったね。\nゆっくりしていこう。';
    }

    return '眠れない夜も、ルナがそばにいるよ。\nここで一緒に休もう。';
  }

  String get lunaMessage {
    if (customMessage != null) {
      return customMessage!;
    }

    switch (selectedEmotion.id) {
      case 'anxiety':
        return '今日は不安さんが少し近くにいるみたい。\n'
            '無理に追い払わなくても大丈夫だよ。';

      case 'peace':
        return '今日は安心さんがそばにいるね。\n'
            'この穏やかな気持ちを大切にしよう。';

      case 'tired':
        return 'おつかれさんが、ひと休みしたそうだよ。\n'
            '今日はゆっくり進もうね。';

      case 'angry':
        return 'イライラさんが何かを伝えたそうにしているね。\n'
            'まずは、ゆっくり息を吐いてみよう。';

      case 'lonely':
        return 'さみしいさんが、誰かのそばにいたいみたい。\n'
            'ここでは一人で頑張らなくていいよ。';

      default:
        return selectedEmotion.guideText;
    }
  }

  String get recommendedTitle {
    switch (selectedEmotion.id) {
      case 'tired':
        return 'ひとやすみカフェ';

      case 'lonely':
      case 'peace':
        return 'ルナのおうち';

      case 'anxiety':
      case 'angry':
      default:
        return '深呼吸の森';
    }
  }

  String get recommendedSubtitle {
    switch (selectedEmotion.id) {
      case 'anxiety':
        return '3分だけ呼吸に集中して、心の波を整えよう';

      case 'angry':
        return 'ゆっくり息を吐いて、気持ちをほどこう';

      case 'tired':
        return 'やさしい言葉と一緒に、ひと休みしよう';

      case 'lonely':
        return 'ルナのそばで、安心できる時間を過ごそう';

      case 'peace':
        return '穏やかな気持ちを、ルナと味わおう';

      default:
        return '今の心に合う場所で、ゆっくり休もう';
    }
  }

  String get recommendedImagePath {
    switch (selectedEmotion.id) {
      case 'tired':
        return 'assets/images/cafe_card.png';

      case 'lonely':
      case 'peace':
        return 'assets/images/luna_house_card.png';

      case 'anxiety':
      case 'angry':
      default:
        return 'assets/images/forest_card.png';
    }
  }

  VoidCallback get recommendedOnTap {
    switch (selectedEmotion.id) {
      case 'tired':
        return widget.onCafe;

      case 'lonely':
      case 'peace':
        return widget.onLunaHouse;

      case 'anxiety':
      case 'angry':
      default:
        return widget.onBreathing;
    }
  }

  void selectEmotion(EmotionInfo emotion) {
    setState(() {
      selectedEmotionId = emotion.id;
      customMessage = null;
    });
  }

  Widget emotionButton(EmotionInfo emotion) {
    final selected = selectedEmotionId == emotion.id;

    return GestureDetector(
      onTap: () => selectEmotion(emotion),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOut,
        width: 82,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF0E8FA)
              : Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? const Color(0xFFAE8ED8)
                : const Color(0xFFE8DFEE),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFF8A6CAF).withOpacity(0.20)
                  : Colors.black.withOpacity(0.04),
              blurRadius: selected ? 15 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1,
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutBack,
              child: Image.asset(
                emotion.imagePath,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              emotion.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected
                    ? const Color(0xFF6F538E)
                    : const Color(0xFF706779),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget smallActionButton({
    required String label,
    required IconData icon,
    required Color foregroundColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: foregroundColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget placeCard({
    required String imagePath,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.93),
            borderRadius: BorderRadius.circular(25),
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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      imagePath,
                      width: 104,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 7,
                    bottom: 7,
                    child: Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.93),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 17,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
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
                        color: Color(0xFF655572),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Color(0xFF786F7F),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: accentColor,
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
            color: const Color(0xFFF8F3FA).withOpacity(0.18),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ルナのお出迎え
                // ルナのお出迎え
Container(
  width: double.infinity,
  height: 230,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    border: Border.all(
      color: Colors.white.withOpacity(0.75),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(29),
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/kokoro_bg.png',
            fit: BoxFit.cover,
          ),
        ),

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.88),
                  Colors.white.withOpacity(0.55),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.86),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '☀️',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(width: 6),
                Text(
  isWeatherLoading
      ? '取得中...'
      : weatherData == null
          ? '天気なし'
          : '${weatherData!.weatherEmoji} ${weatherData!.weatherLabel} ${weatherData!.temperatureText}',

                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF665A70),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 17,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(18),
            ),
            child:Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF8B73A5),
                ),
                SizedBox(width: 4),
                Text(
  weatherData?.cityName ?? '現在地',

                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF756682),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          left: 18,
          top: 65,
          right: 135,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '心の広場',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F5B8E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  15,
                  12,
                  15,
                  12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.80),
                  ),
                ),
                child: Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF62566F),
                  ),
                ),
              ),
            ],
          ),
        ),

       Positioned(
  right: 10,
  bottom: -2,
  child: Image.asset(
    'assets/images/luna.png',
    width: 140,
    height: 175,
    fit: BoxFit.contain,
  ),
),

        Positioned(
          right: 105,
          bottom: 22,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF1E8F8),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Center(
              child: Text(
                '🐾',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

                const SizedBox(height: 16),

                // 感情選択
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 17, 16, 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFE8DFEE),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '今の気持ちは？',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6F5B8E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'いちばん近い気持ちを、そっと選んでね',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF91869A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 108,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: emotionInfos.length,
                          itemBuilder: (context, index) {
                            return emotionButton(
                              emotionInfos[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ルナのひとこと
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Container(
                    key: ValueKey(
                      '$selectedEmotionId-$customMessage',
                    ),
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFF8FC),
                          Color(0xFFF2EAF9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFE4D6ED),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF72598E)
                              .withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1E8F8),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/images/luna.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ルナのひとこと',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8A72A3),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    lunaMessage,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.6,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5F536A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            smallActionButton(
                              label: '話を聞く',
                              icon: Icons
                                  .chat_bubble_outline_rounded,
                              foregroundColor:
                                  const Color(0xFF725DB0),
                              backgroundColor:
                                  const Color(0xFFEDE6FA),
                              onTap: () => widget.onListen(
                                selectedEmotion,
                              ),
                            ),
                            const SizedBox(width: 10),
                            smallActionButton(
                              label: 'なでる',
                              icon: Icons.favorite_border_rounded,
                              foregroundColor:
                                  const Color(0xFFD15F92),
                              backgroundColor:
                                  const Color(0xFFFCE8F1),
                              onTap: () {
                                setState(() {
                                  customMessage =
                                      '${selectedEmotion.name}をそっとなでたよ。\n'
                                      '少し安心したみたい。';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  '今日のおすすめ',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F5B8E),
                  ),
                ),
                const SizedBox(height: 10),

                // おすすめ
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: recommendedOnTap,
                    borderRadius: BorderRadius.circular(29),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(29),
                        border: Border.all(
                          color: const Color(0xFFE2D6EB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6F5B8E)
                                .withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            child: Image.asset(
                              recommendedImagePath,
                              width: double.infinity,
                              height: 170,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(17),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recommendedTitle,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              Color(0xFF635176),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        recommendedSubtitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.5,
                                          color:
                                              Color(0xFF766D7D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEDE6FA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Color(0xFF745AA5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                const Text(
                  '好きな場所へ',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F5B8E),
                  ),
                ),
                const SizedBox(height: 10),

                placeCard(
                  imagePath: 'assets/images/forest_card.png',
                  title: '深呼吸の森',
                  subtitle: '呼吸を整えて、気持ちをゆるめる場所',
                  icon: Icons.spa_outlined,
                  accentColor: const Color(0xFF5E9B79),
                  onTap: widget.onBreathing,
                ),
                const SizedBox(height: 12),

                placeCard(
                  imagePath: 'assets/images/cafe_card.png',
                  title: 'ひとやすみカフェ',
                  subtitle: 'やさしい言葉と一緒に、ひと休み',
                  icon: Icons.local_cafe_outlined,
                  accentColor: const Color(0xFFC58B67),
                  onTap: widget.onCafe,
                ),
                const SizedBox(height: 12),

                placeCard(
                  imagePath: 'assets/images/night_card.png',
                  title: '夜の避難所',
                  subtitle: '眠れない夜に、安心できる場所',
                  icon: Icons.nights_stay_outlined,
                  accentColor: const Color(0xFF6B72A7),
                  onTap: widget.onNightShelter,
                ),
                const SizedBox(height: 12),

                placeCard(
                  imagePath:
                      'assets/images/luna_house_card.png',
                  title: 'ルナのおうち',
                  subtitle: 'ルナとゆっくり過ごす場所',
                  icon: Icons.home_outlined,
                  accentColor: const Color(0xFFD27A9E),
                  onTap: widget.onLunaHouse,
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
    child: Stack(
      children: [
        // =========================
        // 背景
        // =========================
        Positioned.fill(
          child: Image.asset(
            'assets/images/breath_forest_bg.png',
            fit: BoxFit.cover,
          ),
        ),

        // 森を少し落ち着かせるフィルター
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF8FFF9).withOpacity(0.20),
                  const Color(0xFFEFF8F2).withOpacity(0.24),
                  const Color(0xFFE6F0EA).withOpacity(0.34),
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  34,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 58,
                  ),
                  child: SizedBox(
  width: double.infinity,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
                      // =========================
                      // タイトル
                      // =========================
                      const Icon(
                        Icons.air_rounded,
                        size: 22,
                        color: Color(0xFF4F765F),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        '深呼吸の森',
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: Color(0xFF3F5949),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'ここでは、少しだけ呼吸に戻ってこよう。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF66736B),
                        ),
                      ),

                      const SizedBox(height: 34),

                      // =========================
                      // 呼吸の円
                      // =========================
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.42),
                              ),
                            ),
                          ),

                          ScaleTransition(
                            scale: controller,
                            child: Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF8FFF9)
                                    .withOpacity(0.78),
                                border: Border.all(
                                  color: const Color(0xFFBFD4C6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF799686)
                                        .withOpacity(0.10),
                                    blurRadius: 26,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isBreathingIn
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      size: 20,
                                      color: const Color(0xFF5E816B),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      isBreathingIn
                                          ? 'すって…'
                                          : 'はいて…',
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF445C4C),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      isBreathingIn
                                          ? 'ゆっくり、息を入れよう'
                                          : '力を抜いて、ゆっくり外へ',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF78847B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // =========================
                      // ルナ
                      // =========================
                      Image.asset(
                        'assets/images/luna.png',
                        height: 115,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 10),

                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: 330,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.74),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.80),
                          ),
                        ),
                        child: const Text(
                          'うまくやらなくて大丈夫。\n'
                          'ただ、呼吸を感じるだけでいいよ。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            color: Color(0xFF5C665F),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // =========================
                      // 戻る
                      // =========================
                      TextButton.icon(
                        onPressed: widget.onBack,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 17,
                        ),
                        label: const Text(
                          '心の広場へ戻る',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F6658),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
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


class HitoyasumiCafeScreen extends StatefulWidget {
  final VoidCallback onBack;

  const HitoyasumiCafeScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<HitoyasumiCafeScreen> createState() =>
      _HitoyasumiCafeScreenState();
}

class _HitoyasumiCafeScreenState
    extends State<HitoyasumiCafeScreen> {
  String? selectedCafeMood;
  String? selectedDrink;
  String? lastDrink;

  String drinkEmoji = '';
  String cafeMessage = '';
  String drinkMessage = '';
  String gentleMessage = '';

  int drinkCount = 0;

  // ==================================================
  // 気分 × 飲みもの
  // ==================================================

  String getCafeMessage(
    String drink,
    String? mood,
  ) {
    if (drink == 'ココア') {
      switch (mood) {
        case '疲れた':
          return '今日はちょっと疲れてるんだね。\n'
              '甘いココアと一緒に、少しだけ力を抜こう。';

        case '不安':
          return '不安が少し大きくなってるのかな。\n'
              '今は全部考えなくて大丈夫。';

        case '落ち込んでる':
          return '今日は少し心が沈んでるんだね。\n'
              '自分にも、やさしい時間をあげよう。';

        case '眠れない':
          return 'まだ眠れないんだね。\n'
              'ここでは時間を気にせず、のんびりしていこう。';

        case 'なんとなく休みたい':
          return '理由がなくても、休みたいときは休んでいいよ。\n'
              '少しだけ、ぼーっとしよう。';

        default:
          return 'あったかいココアにしよう。\n'
              '今日は少しだけ、力を抜いていこう。';
      }
    }

    if (drink == 'お茶') {
      switch (mood) {
        case '疲れた':
          return '今日は少し疲れがたまってるんだね。\n'
              'あたたかいお茶を飲みながら、ひと息つこう。';

        case '不安':
          return '頭の中がぐるぐるしてるのかな。\n'
              '今は答えを出さずに、ゆっくりしよう。';

        case '落ち込んでる':
          return '今日は少し元気が出ない日なんだね。\n'
              '無理に元気にならなくていいよ。';

        case '眠れない':
          return 'まだ眠れないんだね。\n'
              '静かにお茶を飲みながら、ゆっくりしていこう。';

        case 'なんとなく休みたい':
          return 'なんとなく休みたい日もあるよね。\n'
              '今日はのんびりしよう。';

        default:
          return 'あたたかいお茶にしよう。\n'
              '気持ちも急がなくて大丈夫だよ。';
      }
    }

    if (drink == 'ホットミルク') {
      switch (mood) {
        case '疲れた':
          return '今日はたくさん頑張ったんだね。\n'
              'あたたかいミルクと一緒に、ゆっくり休もう。';

        case '不安':
          return '不安なことが頭から離れないのかな。\n'
              '今は答えを出さなくても大丈夫。';

        case '落ち込んでる':
          return '今日は心が少し疲れてるんだね。\n'
              'ここでは、そのままの気持ちでいていいよ。';

        case '眠れない':
          return '眠れない夜なんだね。\n'
              'あたたかいミルクと一緒に、ゆっくりしよう。';

        case 'なんとなく休みたい':
          return '今日はちょっと休憩したい気分なんだね。\n'
              '何かを頑張らなくてもいい時間にしよう。';

        default:
          return 'ホットミルクにしよう。\n'
              '今は頑張るより、休む時間にしよう。';
      }
    }

    return '';
  }

  // ==================================================
  // 気分
  // ==================================================

  void selectMood(String mood) {
    setState(() {
      selectedCafeMood = mood;

      if (selectedDrink != null) {
        cafeMessage = getCafeMessage(
          selectedDrink!,
          mood,
        );
      }
    });
  }

  // ==================================================
  // 飲みもの
  // ==================================================

  void selectDrink(String drink) {
    setState(() {
      selectedDrink = drink;
      lastDrink = drink;

      drinkCount = 0;
      drinkMessage = '';
      gentleMessage = '';

      if (drink == 'ココア') {
        drinkEmoji = '☕';
      } else if (drink == 'お茶') {
        drinkEmoji = '🍵';
      } else {
        drinkEmoji = '🥛';
      }

      cafeMessage = getCafeMessage(
        drink,
        selectedCafeMood,
      );
    });
  }

  // ==================================================
  // ひとくち飲む
  // ==================================================

  Future<void> takeSip() async {
    if (selectedDrink == null) return;

    setState(() {
      drinkCount++;

      if (drinkCount == 1) {
        drinkMessage = 'ふぅ…あったかいね。';
      } else if (drinkCount == 2) {
        drinkMessage = 'もうひとくち。急がなくて大丈夫。';
      } else if (drinkCount == 3) {
        drinkMessage = '少しずつ、心もゆるんできたかな。';
      } else {
        drinkMessage = 'ごちそうさま。ひと息つけたね。';
      }
    });

    if (drinkCount >= 4) {
      await Future.delayed(
        const Duration(milliseconds: 1200),
      );

      if (!mounted) return;

      setState(() {
        selectedDrink = null;
        drinkEmoji = '';
        cafeMessage = '';
        drinkMessage = '';
        drinkCount = 0;
      });
    }
  }

  // ==================================================
  // 今日のやさしい一言
  // ==================================================

  void showGentleMessage() {
    List<String> messages;

    if (lastDrink == 'ココア') {
      messages = [
        '今日は少しくらい、自分を甘やかしてもいい日だよ。',
        '頑張ったぶんだけ、やさしい時間ももらっていいんだよ。',
        '「ちゃんとしなきゃ」を、今日は少し置いておこう。',
        '自分にも、やさしい言葉を向けてあげよう。',
        '甘いひと休みも、大切な時間だよ。',
      ];
    } else if (lastDrink == 'お茶') {
      messages = [
        '急いで答えを出さなくても大丈夫。',
        '今は少しだけ、考えることをお休みしよう。',
        'ひと息つくだけでも、心の景色は少し変わるよ。',
        '今日のことは、今日の自分のペースで大丈夫。',
        'ゆっくり、ひとつずつでいいよ。',
      ];
    } else if (lastDrink == 'ホットミルク') {
      messages = [
        '今日はもう、頑張ることをお休みしてもいいよ。',
        '何もしない時間も、ちゃんと大切な時間だよ。',
        '疲れた日は、休むことを一番にしていいよ。',
        '今日は自分に「おつかれさま」って言ってあげよう。',
        '今は安心できる場所で、ゆっくりしよう。',
      ];
    } else {
      messages = [
        '今日は、何も進まなくても大丈夫。',
        'ちゃんと休むことも、大切な時間だよ。',
        '少しだけ肩の力を抜こう。',
        'ここでは急がなくて大丈夫。',
        '今日は自分のペースで過ごしていいよ。',
      ];
    }

    setState(() {
      gentleMessage =
          messages[Random().nextInt(messages.length)];
    });
  }

  // ==================================================
  // 気分アイコン
  // ==================================================

  Widget moodItem({
    required String emoji,
    required String label,
    required String value,
  }) {
    final selected = selectedCafeMood == value;

    return GestureDetector(
      onTap: () => selectMood(value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF8).withOpacity(0.78),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF8E7BBE)
                      : const Color(0xFFE7DED6),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 27,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: const Color(0xFF554B47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // 飲みものアイコン
  // ==================================================

  Widget drinkItem({
    required String emoji,
    required String label,
    required String value,
  }) {
    final selected = selectedDrink == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => selectDrink(value),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF8).withOpacity(0.82),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF8E7BBE)
                      : const Color(0xFFE7DED6),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: const Color(0xFF554B47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1EC),
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Image.asset(
              'assets/images/cafe_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 全体を少し落ち着かせる
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFFF9F4).withOpacity(0.16),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    22,
                    22,
                    34,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // -----------------------------
                        // タイトル
                        // -----------------------------
                        const Icon(
                          Icons.local_cafe_outlined,
                          size: 19,
                          color: Color(0xFF6B5B53),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'ひとやすみカフェ',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: Color(0xFF55463F),
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          '今日は少し、ここで休もう。',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF756D68),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // -----------------------------
                        // 気分
                        // -----------------------------
                        const Text(
                          '今日はどうしたの？',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF55463F),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              moodItem(
                                emoji: '😮‍💨',
                                label: '疲れた',
                                value: '疲れた',
                              ),
                              moodItem(
                                emoji: '😰',
                                label: '不安',
                                value: '不安',
                              ),
                              moodItem(
                                emoji: '😢',
                                label: '落ち込み',
                                value: '落ち込んでる',
                              ),
                              moodItem(
                                emoji: '🌙',
                                label: '眠れない',
                                value: '眠れない',
                              ),
                              moodItem(
                                emoji: '☁️',
                                label: '休みたい',
                                value: 'なんとなく休みたい',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // -----------------------------
                        // 飲みもの
                        // -----------------------------
                        const Text(
                          '何を飲む？',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF55463F),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            drinkItem(
                              emoji: '☕',
                              label: 'ココア',
                              value: 'ココア',
                            ),
                            drinkItem(
                              emoji: '🍵',
                              label: 'お茶',
                              value: 'お茶',
                            ),
                            drinkItem(
                              emoji: '🥛',
                              label: 'ミルク',
                              value: 'ホットミルク',
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // -----------------------------
                        // 飲みものカード
                        // -----------------------------
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: selectedDrink == null
                              ? const SizedBox.shrink()
                              : Center(
                                  child: Container(
                                    key: ValueKey(selectedDrink),
                                    width: 340,
                                    padding: const EdgeInsets.fromLTRB(
                                      22,
                                      18,
                                      22,
                                      16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFCF8)
                                          .withOpacity(0.76),
                                      borderRadius:
                                          BorderRadius.circular(26),
                                      border: Border.all(
                                        color: const Color(0xFFE7DED6),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        AnimatedScale(
                                          scale: drinkCount == 0
                                              ? 1
                                              : drinkCount == 1
                                                  ? 0.95
                                                  : drinkCount == 2
                                                      ? 0.90
                                                      : drinkCount == 3
                                                          ? 0.84
                                                          : 0.78,
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          child: Text(
                                            drinkEmoji,
                                            style: const TextStyle(
                                              fontSize: 40,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          '$selectedDrinkを用意したよ',
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF55463F),
                                          ),
                                        ),

                                        const SizedBox(height: 9),

                                        Text(
                                          cafeMessage,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            height: 1.6,
                                            color: Color(0xFF5E5652),
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        Container(
                                          width: double.infinity,
                                          height: 1,
                                          color: const Color(0xFFE7DED6),
                                        ),

                                        const SizedBox(height: 14),

                                        SizedBox(
                                          height: 44,
                                          child: ElevatedButton.icon(
                                            onPressed: takeSip,
                                            icon: const Icon(
                                              Icons.local_cafe_outlined,
                                              size: 17,
                                            ),
                                            label: const Text(
                                              'ひとくち飲む',
                                            ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFF4ECE6),
                                              foregroundColor:
                                                  const Color(0xFF55463F),
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 24,
                                              ),
                                              shape:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  22,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFFE0D5CE),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 9),

                                        Text(
                                          drinkCount == 0
                                              ? 'ゆっくり飲んでね'
                                              : '$drinkCount / 4 ひとくち目',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF8A817C),
                                          ),
                                        ),

                                        if (drinkMessage.isNotEmpty) ...[
                                          const SizedBox(height: 7),
                                          Text(
                                            drinkMessage,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFF756D68),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 22),

                        // -----------------------------
                        // 今日のやさしい一言
                        // -----------------------------
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: gentleMessage.isEmpty
                              ? OutlinedButton.icon(
                                  key: const ValueKey('gentleButton'),
                                  onPressed: showGentleMessage,
                                  icon: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    '今日のやさしい一言',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF55463F),
                                    backgroundColor:
                                        const Color(0xFFFFFCF8)
                                            .withOpacity(0.72),
                                    side: const BorderSide(
                                      color: Color(0xFFE0D5CE),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(22),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Container(
                                    key: ValueKey(gentleMessage),
                                    width: 340,
                                    padding: const EdgeInsets.fromLTRB(
                                      22,
                                      17,
                                      22,
                                      18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFCF8)
                                          .withOpacity(0.80),
                                      borderRadius:
                                          BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFFE7DED6),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 18,
                                          color: Color(0xFF8E7BBE),
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          gentleMessage,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            height: 1.65,
                                            color: Color(0xFF554B47),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 28),

                        // -----------------------------
                        // 戻る
                        // -----------------------------
                        TextButton.icon(
                          onPressed: widget.onBack,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 17,
                          ),
                          label: const Text(
                            '心の広場へ戻る',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                const Color(0xFF55463F),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 11,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

class _NightShelterScreenState
    extends State<NightShelterScreen> {
  final TextEditingController noteController =
      TextEditingController();

  bool hasPlacedThought = false;
  String placedMessage = '';

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void placeThought() {
    final text = noteController.text.trim();

    setState(() {
      hasPlacedThought = true;

      if (text.isEmpty) {
        placedMessage =
            '今夜は答えを出さなくて大丈夫。\n'
            'ここでは、少しだけ心を休ませよう。';
      } else {
        placedMessage =
            '考えごと、ここで預かっておくね。\n'
            '今夜はもう、少し休んでいいよ。';
      }

      noteController.clear();
    });
  }

  void resetThought() {
    setState(() {
      hasPlacedThought = false;
      placedMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17172A),
      body: Stack(
        children: [
          // =============================
          // 背景
          // =============================
          Positioned.fill(
            child: Image.asset(
              'assets/images/night_shelter_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 真っ黒ではなく、紺紫を重ねる
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF17172A)
                        .withOpacity(0.45),
                    const Color(0xFF25233E)
                        .withOpacity(0.62),
                    const Color(0xFF17172A)
                        .withOpacity(0.78),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    22,
                    24,
                    22,
                    34,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - 58,
                    ),
                    child: Column(
                      children: [
                        // =============================
                        // タイトル
                        // =============================
                        const Icon(
                          Icons.nights_stay_rounded,
                          color: Color(0xFFCBC4F2),
                          size: 24,
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          '夜の避難所',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Color(0xFFF0ECFF),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          '眠れない夜は、ここで少し休もう。',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFFD2CDE3),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // =============================
                        // 最初の言葉
                        // =============================
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.fromLTRB(
                            22,
                            20,
                            22,
                            20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                                    0xFF2F2C49)
                                .withOpacity(0.72),
                            borderRadius:
                                BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.12),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons
                                    .bedtime_outlined,
                                size: 20,
                                color:
                                    Color(0xFFBEB5E9),
                              ),

                              const SizedBox(
                                  height: 10),

                              const Text(
                                '夜は、考えごとが\n'
                                '少し大きく見える時間。',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  height: 1.6,
                                  fontWeight:
                                      FontWeight.w600,
                                  color:
                                      Color(0xFFF0ECFA),
                                ),
                              ),

                              const SizedBox(
                                  height: 10),

                              const Text(
                                '今は答えを出さなくて大丈夫。\n'
                                '考えることを、ここに置いていこう。',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.6,
                                  color:
                                      Color(0xFFD2CCDF),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // =============================
                        // 入力エリア
                        // =============================
                        AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 280,
                          ),
                          child: !hasPlacedThought
                              ? Container(
                                  key: const ValueKey(
                                    'inputArea',
                                  ),
                                  width:
                                      double.infinity,
                                  padding:
                                      const EdgeInsets
                                          .fromLTRB(
                                    18,
                                    18,
                                    18,
                                    18,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white
                                        .withOpacity(
                                            0.10),
                                    borderRadius:
                                        BorderRadius
                                            .circular(28),
                                    border:
                                        Border.all(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                              0.14),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        '今の考えごと',
                                        style:
                                            TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                          color: Color(
                                              0xFFD8D2EB),
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 10),

                                      TextField(
                                        controller:
                                            noteController,
                                        minLines: 3,
                                        maxLines: 5,
                                        style:
                                            const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color:
                                              Colors.white,
                                        ),
                                        cursorColor:
                                            const Color(
                                                0xFFC8BFF0),
                                        decoration:
                                            InputDecoration(
                                          hintText:
                                              'ここに置いていこう…',
                                          hintStyle:
                                              TextStyle(
                                            color: Colors
                                                .white
                                                .withOpacity(
                                                    0.42),
                                          ),
                                          filled: true,
                                          fillColor:
                                              Colors.white
                                                  .withOpacity(
                                                      0.08),
                                          contentPadding:
                                              const EdgeInsets
                                                  .all(16),
                                          enabledBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                                        20),
                                            borderSide:
                                                BorderSide(
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                      0.10),
                                            ),
                                          ),
                                          focusedBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                                        20),
                                            borderSide:
                                                const BorderSide(
                                              color: Color(
                                                  0xFFAAA0D8),
                                              width: 1.3,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 14),

                                      SizedBox(
                                        width:
                                            double.infinity,
                                        height: 46,
                                        child:
                                            ElevatedButton.icon(
                                          onPressed:
                                              placeThought,
                                          icon:
                                              const Icon(
                                            Icons
                                                .dark_mode_outlined,
                                            size: 17,
                                          ),
                                          label:
                                              const Text(
                                            'ここに置いていく',
                                          ),
                                          style:
                                              ElevatedButton
                                                  .styleFrom(
                                            backgroundColor:
                                                const Color(
                                                    0xFF9186C8),
                                            foregroundColor:
                                                Colors.white,
                                            elevation: 0,
                                            shape:
                                                RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          23),
                                            ),
                                            textStyle:
                                                const TextStyle(
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )

                              // =============================
                              // 置いていった後
                              // =============================
                              : Container(
                                  key: const ValueKey(
                                    'placedArea',
                                  ),
                                  width:
                                      double.infinity,
                                  padding:
                                      const EdgeInsets
                                          .fromLTRB(
                                    22,
                                    24,
                                    22,
                                    22,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: const Color(
                                            0xFF35314E)
                                        .withOpacity(
                                            0.78),
                                    borderRadius:
                                        BorderRadius
                                            .circular(28),
                                    border:
                                        Border.all(
                                      color: const Color(
                                              0xFFB8AFE1)
                                          .withOpacity(
                                              0.25),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration:
                                            BoxDecoration(
                                          color: const Color(
                                                  0xFF8C82C0)
                                              .withOpacity(
                                                  0.22),
                                          shape:
                                              BoxShape.circle,
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .nights_stay_rounded,
                                          color: Color(
                                              0xFFD5CFF5),
                                          size: 26,
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 15),

                                      const Text(
                                        'ここに置いていけたよ',
                                        style:
                                            TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          color: Color(
                                              0xFFF0ECFF),
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 10),

                                      Text(
                                        placedMessage,
                                        textAlign:
                                            TextAlign
                                                .center,
                                        style:
                                            const TextStyle(
                                          fontSize: 14,
                                          height: 1.65,
                                          color: Color(
                                              0xFFD6D0E4),
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 18),

                                      TextButton(
                                        onPressed:
                                            resetThought,
                                        style: TextButton
                                            .styleFrom(
                                          foregroundColor:
                                              const Color(
                                                  0xFFBFB6E8),
                                        ),
                                        child:
                                            const Text(
                                          'もうひとつ置いていく',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),

                        const SizedBox(height: 26),

                        // =============================
                        // 小さな夜の一言
                        // =============================
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.07),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🌙 今夜は、少し休めればそれで十分。',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color:
                                  Color(0xFFCFC9DE),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // =============================
                        // 戻る
                        // =============================
                        TextButton.icon(
                          onPressed:
                              widget.onBack,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 17,
                          ),
                          label: const Text(
                            '心の広場へ戻る',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                const Color(
                                    0xFFC8C0EB),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            textStyle:
                                const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LunaHouseScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LunaHouseScreen({super.key, required this.onBack});

  @override
  State<LunaHouseScreen> createState() => _LunaHouseScreenState();
}

class _LunaHouseScreenState extends State<LunaHouseScreen>
    with TickerProviderStateMixin {
  int fullness = 0;
  int affection = 0;
  int todayPetCount = 0;
  DateTime? lastPetDate;
  bool _loading = true;
  bool _loadFailed = false;
  bool _preloaded = false;
  String _activity = 'idle';
  String _message = '';
  SharedPreferences? _prefs;
  late final AnimationController _idle;
  late final AnimationController _action;

  bool get _busy => _loading || _loadFailed || _activity != 'idle';

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _action = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _loadHouse();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preloaded) {
      _preloaded = true;
      for (final path in ['assets/images/luna_3d.png', 'assets/images/luna_3d_blink.png']) {
        precacheImage(AssetImage(path), context, onError: (error, stackTrace) {});
      }
    }
  }

  bool _sameDay(DateTime? a, DateTime b) => a != null &&
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _loadHouse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      var savedFullness = (prefs.getInt('lunaFullness') ?? 0).clamp(0, 10).toInt();
      final savedAffection = (prefs.getInt('lunaAffection') ?? 0).clamp(0, 100).toInt();
      final updated = DateTime.tryParse(prefs.getString('lunaFullnessLastUpdated') ?? '');
      final previousVisit = DateTime.tryParse(prefs.getString('lunaHouseLastVisit') ?? '');
      final petDate = DateTime.tryParse(prefs.getString('lunaLastPetDate') ?? '');
      var savedPetCount = _sameDay(petDate, now) ? (prefs.getInt('lunaTodayPetCount') ?? 0) : 0;
      if (savedPetCount < 0) savedPetCount = 0;
      // Preserve the unused part of each six-hour interval when visiting.
      if (updated == null || updated.isAfter(now)) {
        await prefs.setString('lunaFullnessLastUpdated', now.toIso8601String());
      } else {
        final intervals = now.difference(updated).inHours ~/ 6;
        if (intervals > 0) {
          savedFullness = (savedFullness - intervals).clamp(0, 10).toInt();
          await prefs.setInt('lunaFullness', savedFullness);
          await prefs.setString('lunaFullnessLastUpdated',
            updated.add(Duration(hours: intervals * 6)).toIso8601String());
        }
      }
      await prefs.setString('lunaHouseLastVisit', now.toIso8601String());
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        fullness = savedFullness;
        affection = savedAffection;
        todayPetCount = savedPetCount;
        lastPetDate = petDate;
        _loading = false;
        _loadFailed = false;
        _message = previousVisit != null && now.difference(previousVisit).inHours >= 24
          ? 'また会えてうれしいな。\n今日は一緒にのんびりしよう。' : '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _loadFailed = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お世話の記録を読み込めませんでした。もう一度試してね。')));
    }
  }

  String get _houseMessage {
    if (_loading) return 'おへやを準備しているよ。';
    if (_loadFailed) return '記録を読み込めなかったよ。\n右上のボタンでもう一度試してね。';
    if (_message.isNotEmpty) return _message;
    if (fullness >= 9) return 'おなかいっぱい。\nきみのそばで、ひと休み。';
    if (fullness <= 2) return 'よかったら、ごはんにしよう。\nなでてくれるのもうれしいな。';
    if (affection >= 50) return 'きみと過ごすこの時間が、\nルナのたからものだよ。';
    return 'ここでは、きみのペースで。\n一緒にゆっくりしよう。';
  }

  Future<void> _care(String kind) async {
    if (_busy || _prefs == null) return;
    if (kind == 'feed' && fullness >= 10) {
      setState(() => _message = 'いまはおなかいっぱい。\n一緒に遊ぼう！');
      return;
    }
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    setState(() {
      _activity = kind;
      _message = kind == 'feed' ? 'ごはんだ！\nもぐもぐ、おいしいな。'
        : kind == 'pet' ? 'えへへ、気持ちいいな。\nなでてくれてありがとう。'
        : 'きみと遊ぶの、だいすき！';
    });
    if (!reduceMotion) _action.repeat(reverse: true);
    await Future<void>.delayed(Duration(milliseconds: kind == 'feed' ? 2100 : kind == 'play' ? 1400 : 750));
    if (!mounted) return;
    _action.stop();
    _action.reset();
    final now = DateTime.now();
    setState(() {
      if (kind == 'feed') fullness = (fullness + 1).clamp(0, 10).toInt();
      affection = (affection + 1).clamp(0, 100).toInt();
      if (kind == 'pet') {
        todayPetCount = (_sameDay(lastPetDate, now) ? todayPetCount : 0) + 1;
        lastPetDate = now;
      }
      _message = kind == 'feed' ? 'ごちそうさま。\nごはんをくれてありがとう！'
        : kind == 'pet' ? 'なでなで、うれしかった。\nもう少しそばにいてね。'
        : '楽しかったね！\n今度は一緒にひと休みしよう。';
    });
    try {
      final prefs = _prefs!;
      var saved = await prefs.setInt('lunaFullness', fullness);
      saved = await prefs.setInt('lunaAffection', affection) && saved;
      // Petting and playing do not restart the hunger countdown.
      if (kind == 'feed') {
        saved = await prefs.setString('lunaFullnessLastUpdated', now.toIso8601String()) && saved;
      }
      if (kind == 'pet') {
        saved = await prefs.setInt('lunaTodayPetCount', todayPetCount) && saved;
        saved = await prefs.setString('lunaLastPetDate', now.toIso8601String()) && saved;
      }
      if (!saved) throw StateError('Could not save care data');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('今回のお世話を保存できませんでした。')));
      }
    } finally {
      if (mounted) setState(() => _activity = 'idle');
    }
  }

  Widget _status(String label, String value, double progress, IconData icon, Color color) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: color), const SizedBox(width: 5),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6E607C)))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF584568))),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(10), child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress), duration: const Duration(milliseconds: 350),
        builder: (_, value, child) => LinearProgressIndicator(value: value, minHeight: 7,
          backgroundColor: const Color(0xFFECE5F0), valueColor: AlwaysStoppedAnimation<Color>(color)),
      )),
    ]));
  }

  Widget _careButton(String label, IconData icon, Color color, String kind) {
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Material(color: color, shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
        clipBehavior: Clip.antiAlias,
        child: IconButton(tooltip: label, onPressed: _busy ? null : () => _care(kind),
          icon: Icon(icon), iconSize: 28, padding: const EdgeInsets.all(16),
          color: Colors.white, disabledColor: Colors.white60)),
      const SizedBox(height: 7),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5E4A6E)))),
    ]));
  }

  Widget _lunaStage() {
    return LayoutBuilder(builder: (context, bounds) {
      return Semantics(label: 'ルナ。タップしてなでる', button: true,
        child: GestureDetector(onTap: _busy ? null : () => _care('pet'),
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(animation: Listenable.merge([_idle, _action]), builder: (context, child) {
            final reduceMotion = MediaQuery.of(context).disableAnimations;
            final blinking = !reduceMotion && _idle.value > 0.95;
            final closed = _activity == 'pet' || blinking;
            final bounce = reduceMotion ? 0.0 : _activity == 'play' ? -_action.value * 14
              : _activity == 'feed' ? _action.value * 4 : (_idle.value - 0.5) * 3;
            return Stack(alignment: Alignment.center, children: [
              Positioned(bottom: bounds.maxHeight * 0.06, child: Container(
                width: bounds.maxWidth * 0.42, height: 16,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(100),
                  boxShadow: [BoxShadow(color: const Color(0xFF796286).withValues(alpha: 0.18), blurRadius: 22, spreadRadius: 5)]))),
              Positioned.fill(child: Transform.translate(offset: Offset(0, bounce),
                child: ClipRect(child: Transform.scale(scale: 1.25,
                  child: Image.asset(closed ? 'assets/images/luna_3d_blink.png' : 'assets/images/luna_3d.png',
                    fit: BoxFit.contain, gaplessPlayback: true,
                    errorBuilder: (_, error, stack) => Image.asset('assets/images/luna.png', fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) => const Icon(Icons.pets_rounded, size: 100, color: Color(0xFF9C87B6))),
                  ),
                )),
              )),
              if (_activity == 'pet') Positioned(top: bounds.maxHeight * 0.12, right: bounds.maxWidth * 0.14,
                child: const Icon(Icons.favorite_rounded, color: Color(0xFFE5A0B5), size: 38)),
              if (_activity == 'play') Positioned(top: bounds.maxHeight * 0.25, right: bounds.maxWidth * 0.15,
                child: Transform.translate(offset: Offset(0, reduceMotion ? 0 : -_action.value * 12),
                  child: const Text('🎾', style: TextStyle(fontSize: 35)))),
              if (_activity == 'feed') Positioned(bottom: 3,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(30)),
                  child: const Text('🍚', style: TextStyle(fontSize: 32)))),
            ]);
          }),
        ),
      );
    });
  }

  Widget _roomScene() {
    return Column(children: [
      Row(children: [
        Material(color: Colors.white.withValues(alpha: 0.94), shape: const CircleBorder(),
          child: IconButton(tooltip: '心の広場へ戻る', onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF77608A)))),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ルナのおうち', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF5E4A6E))),
          Text('きみと、のんびり過ごす場所', style: TextStyle(fontSize: 11, color: Color(0xFF766780))),
        ])),
        if (_loadFailed) IconButton(tooltip: '記録を読み直す', onPressed: () {
          setState(() { _loading = true; _loadFailed = false; }); _loadHouse();
        }, icon: const Icon(Icons.refresh_rounded)),
      ]),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(24)),
        child: _loading ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))
          : Row(children: [
            _status('まんぷく', '$fullness / 10', fullness / 10, Icons.restaurant_rounded, const Color(0xFFD5A273)),
            const SizedBox(width: 24),
            _status('なつき度', '$affection / 100', affection / 100, Icons.favorite_rounded, const Color(0xFFBC94BB)),
          ]),
      ),
      const SizedBox(height: 14),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 1.5)),
        child: Text(_houseMessage, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600, color: Color(0xFF5E4A6E)))),
      const SizedBox(height: 6),
      Expanded(child: _lunaStage()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF5EDF4), body: Stack(children: [
      Positioned.fill(child: Image.asset('assets/images/luna_home_bg.png', fit: BoxFit.cover,
        errorBuilder: (_, error, stack) => const DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFF1E5F2), Color(0xFFF4E5D9)]))))),
      Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.12))),
      SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(children: [
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final minimum = 450.0 + (scale > 1 ? (scale - 1) * 200 : 0);
              if (constraints.maxHeight < minimum) {
                return SingleChildScrollView(child: SizedBox(height: minimum, child: _roomScene()));
              }
              return _roomScene();
            })),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _careButton('ごはん', Icons.restaurant_rounded, const Color(0xFFD5A273), 'feed'),
              _careButton('なでる', Icons.favorite_rounded, const Color(0xFFBC94BB), 'pet'),
              _careButton('遊ぶ', Icons.sports_tennis_rounded, const Color(0xFF8DA69F), 'play'),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.90), borderRadius: BorderRadius.circular(18)),
              child: Text(_loading ? '少しだけ待ってね' : 'ルナをタップしても、なでられるよ',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF766780)))),
          ]),
        ),
      ))),
    ]));
  }

  @override
  void dispose() {
    _idle.dispose();
    _action.dispose();
    super.dispose();
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

  DateTime? birthday;
  List<JapanEvent> japanEvents = [];

  @override
  void initState() {
    super.initState();

    loadTimelineEvents();
    loadBirthdayForTimeline();
    loadJapanEventsForTimeline();
  }

  Future<void> loadBirthdayForTimeline() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBirthday = prefs.getString('birthday');

    if (savedBirthday == null) return;

    setState(() {
      birthday = DateTime.parse(savedBirthday);
    });
  }

  Future<void> loadJapanEventsForTimeline() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/japan_timeline.json',
    );

    final List decoded = jsonDecode(jsonString);

    setState(() {
      japanEvents = decoded
          .map((item) => JapanEvent.fromJson(item))
          .toList();
    });
  }

  List<JapanEvent> get relevantJapanEvents {
  if (birthday == null || japanEvents.isEmpty) {
    return [];
  }

  final filtered = japanEvents.where((event) {
    return event.year >= birthday!.year &&
        event.year <= DateTime.now().year;
  }).toList();

  filtered.sort(
    (a, b) => a.year.compareTo(b.year),
  );

  return filtered;
}

String getTimelineInsight() {
  if (events.length < 2) {
    return 'まだ出来事は少ないけれど、ここから少しずつ歩みが見えてきそうだね🐶';
  }

  final sortedEvents = [...events]
    ..sort((a, b) => a.year.compareTo(b.year));

  final categoryCounts = <String, int>{};

  for (final event in sortedEvents) {
    categoryCounts[event.category] =
        (categoryCounts[event.category] ?? 0) + 1;
  }

  final mostCommonCategory = categoryCounts.entries.reduce(
    (a, b) => a.value >= b.value ? a : b,
  );

  final recentEvents =
      sortedEvents.reversed.take(3).toList().reversed.toList();

  final recentText = recentEvents
      .map((event) => '${event.year}年「${event.title}」')
      .join('、');

  if (mostCommonCategory.value >= 2) {
    return '年表を見ていると、「${mostCommonCategory.key}」に関する出来事が何度か出てきているね。\n'
        '$recentTextなど、いくつもの経験を重ねてきたんだね🐶';
  }

  return '最近の年表を見ると、$recentTextという流れがあるね。\n'
      'それぞれは別の出来事でも、今のあなたにつながる大切な足あとだと思うよ🐶';
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

  CocoonCard(
  padding: const EdgeInsets.all(20),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Image.asset(
        'assets/images/luna.png',
        width: 58,
        height: 58,
      ),

      const SizedBox(width: 14),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🐶 ルナの気づき',
              style: AppTextStyles.heading.copyWith(
                fontSize: 18,
                color: AppColors.accent,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              getTimelineInsight(),
              style: AppTextStyles.body.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),

const SizedBox(height: 24),          

if (birthday != null && relevantJapanEvents.isNotEmpty) ...[
  CocoonCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🌏 あなたが生きてきた時代',
         style: AppTextStyles.heading.copyWith(
  color: AppColors.accent,
  fontSize: 20,
),
        ),

        const SizedBox(height: 16),

        ...relevantJapanEvents.take(8).map((event) {
          final age = event.year - birthday!.year;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E8F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$age歳',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${event.year}年  ${event.title}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6D6478),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  ),

  const SizedBox(height: 24),
],            

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

class ChatBackgroundShopScreen extends StatelessWidget {
  const ChatBackgroundShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F3FA),
        elevation: 0,
        title: const Text(
          '背景ショップ',
          style: TextStyle(
            color: Color(0xFF655472),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COCOONを、もっとあなたらしい場所に。',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF746A7D),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/chat_bg_default.png',
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            '夢見るルナのお部屋',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF655472),
                            ),
                          ),
                        ),

                        Text(
                          '無料',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E7BBE),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '使用中',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF725D8D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}