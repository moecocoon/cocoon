import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/luna_memory.dart';
import '../models/mood_record.dart';

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
  late final AnimationController _controller;
  late final Animation<double> _floatingAnimation;

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
      return 'この前話してくれた\n'
          '「${widget.latestMemory!.summary}」\n'
          'その後どうだった？🐶';
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

    final strongest = strongestEmotion(widget.latestMood);

    if (strongest != null) {
      if (strongest.key.contains('不安')) {
        return '今日は不安さんが少し大きいみたい。\n'
            'ここで一緒にゆっくりしよう。';
      }

      if (strongest.key.contains('疲れ')) {
        return '今日はおつかれさんが近くにいるね。\n'
            '無理しない時間にしよう。';
      }

      if (strongest.key.contains('さみしい')) {
        return '今日はさみしいさんが顔を出してるね。\n'
            'ルナがそばにいるよ。';
      }

      if (strongest.key.contains('イライラ')) {
        return '今日はイライラさんが強めかも。\n'
            'ここで少しほどいていこう。';
      }

      if (strongest.key.contains('安心')) {
        return '今日は安心さんもいるね。\n'
            'そのやわらかい気持ち、大事にしよう。';
      }

      if (strongest.key.contains('うれしい')) {
        return 'うれしい気持ちを残してくれたんだね。\n'
            'ルナもうれしいよ🌸';
      }
    }

    if (hour >= 5 && hour < 11) {
      return 'おはよう☀️\n今日も無理せずいこうね。';
    }

    if (hour >= 11 && hour < 17) {
      return 'こんにちは🌼\n少し休憩するのも大事だよ。';
    }

    if (hour >= 17 && hour < 23) {
      return '今日もお疲れさま🌙\nここまで頑張ったね。';
    }

    return 'まだ起きてたんだね🌙\nルナはここにいるよ🐶';
  }

  MapEntry<String, double>? strongestEmotion(
    MoodRecord? mood,
  ) {
    if (mood == null || mood.emotionPercents.isEmpty) {
      return null;
    }

    return mood.emotionPercents.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
  }

  Color getEmotionColor(String emotionKey) {
    if (emotionKey.contains('うれしい')) {
      return const Color(0xFFFFD966);
    }

    if (emotionKey.contains('安心')) {
      return const Color(0xFF9AD7B5);
    }

    if (emotionKey.contains('がんばった')) {
      return const Color(0xFFFFB6C1);
    }

    if (emotionKey.contains('不安')) {
      return const Color(0xFF8FAADC);
    }

    if (emotionKey.contains('悲しい')) {
      return const Color(0xFF9DC3E6);
    }

    if (emotionKey.contains('疲れ')) {
      return const Color(0xFFBFBFBF);
    }

    if (emotionKey.contains('イライラ')) {
      return const Color(0xFFD99694);
    }

    if (emotionKey.contains('さみしい')) {
      return const Color(0xFFC5A3FF);
    }

    return const Color(0xFF8E7BBE);
  }

  String getWeekday(DateTime date) {
    const weekdays = [
      '月',
      '火',
      '水',
      '木',
      '金',
      '土',
      '日',
    ];

    return weekdays[date.weekday - 1];
  }

  Widget sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5F526D),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8294),
            ),
          ),
        ],
      ),
    );
  }

  Widget homeCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(19),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E7BBE).withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget statusItem({
    required String emoji,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF655472),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A7D92),
            ),
          ),
        ],
      ),
    );
  }

  Widget lunaHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        17,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3E8FA),
            Color(0xFFFFEEF4),
            Color(0xFFEEEAFB),
          ],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E7BBE).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF8E7BBE),
                      size: 20,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'ルナからのメッセージ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF765D8D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  getLunaMessage(),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF62566B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 190,
            child: !kIsWeb && widget.petImagePath != null
                ? Image.file(
                    File(widget.petImagePath!),
                    fit: BoxFit.contain,
                  )
                : AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          _floatingAnimation.value,
                        ),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/images/luna.png',
                      height: 190,
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.pets_rounded,
                          size: 90,
                          color: Color(0xFF9A82B1),
                        );
                      },
                    ),
                  ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Row(
              children: [
                statusItem(
                  emoji: '❤️',
                  value: '${widget.lunaBond}',
                  label: 'ルナとの絆',
                ),
                Container(
                  width: 1,
                  height: 47,
                  color: const Color(0xFFE3D8E8),
                ),
                statusItem(
                  emoji: '🔥',
                  value: '${widget.streakDays}日',
                  label: '継続日数',
                ),
                Container(
                  width: 1,
                  height: 47,
                  color: const Color(0xFFE3D8E8),
                ),
                statusItem(
                  emoji: '🐶',
                  value: getBondLevel(),
                  label: '今の関係',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget todayMoodCard() {
    final mood = widget.latestMood;
    final strongest = strongestEmotion(mood);

    if (mood == null) {
      return homeCard(
        child: const Row(
          children: [
            Icon(
              Icons.cloud_outlined,
              color: Color(0xFF9A82B1),
              size: 36,
            ),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                'まだ今日の気分は記録されていません。\n'
                '気分記録から、今の心を残してみよう。',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF746678),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return homeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF2E7FA),
                      Color(0xFFFFEEF4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Text(
                  mood.weather,
                  style: const TextStyle(fontSize: 32),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'いちばん大きい気持ち',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF998DA1),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strongest?.key ?? '記録した気持ち',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F526D),
                      ),
                    ),
                  ],
                ),
              ),

              if (strongest != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E7F6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${strongest.value.round()}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E7BBE),
                    ),
                  ),
                ),
            ],
          ),

          if (mood.emotionPercents.isNotEmpty) ...[
            const SizedBox(height: 17),

            ...mood.emotionPercents.entries.map(
              (entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6D6478),
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E7BBE),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          if (mood.memo.isNotEmpty) ...[
            const SizedBox(height: 9),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                mood.memo,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF6D6478),
                ),
              ),
            ),
          ],

          const SizedBox(height: 17),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8E7BBE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
              onPressed: widget.onTalkAboutMood,
              icon: const Icon(Icons.chat_rounded),
              label: const Text(
                'この気持ちをCOCOONに話す',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  MoodRecord? moodForDay(DateTime targetDay) {
    final records = widget.moodHistory.where((mood) {
      return mood.createdAt.year == targetDay.year &&
          mood.createdAt.month == targetDay.month &&
          mood.createdAt.day == targetDay.day;
    }).toList();

    if (records.isEmpty) return null;

    return records.last;
  }

  Future<void> showMoodDetails(
    MoodRecord mood,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFBFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            '${getWeekday(mood.createdAt)}曜日の記録',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF655472),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    mood.weather,
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
                const SizedBox(height: 16),
                ...mood.emotionPercents.entries.map(
                  (entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${entry.key}：${entry.value.round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6D6478),
                        ),
                      ),
                    );
                  },
                ),
                if (mood.memo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'メモ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF655472),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mood.memo,
                    style: const TextStyle(
                      height: 1.5,
                      color: Color(0xFF6D6478),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Widget sevenDayChart() {
    final today = DateTime.now();

    return homeCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final targetDay = today.subtract(
            Duration(days: 6 - index),
          );

          final mood = moodForDay(targetDay);
          final strongest = strongestEmotion(mood);

          final value = strongest?.value ?? 0;

          final barColor = strongest == null
              ? const Color(0xFFD8CDE0)
              : getEmotionColor(strongest.key);

          final isToday =
              targetDay.year == today.year &&
              targetDay.month == today.month &&
              targetDay.day == today.day;

          return Expanded(
            child: GestureDetector(
              onTap: mood == null
                  ? null
                  : () {
                      showMoodDetails(mood);
                    },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    strongest == null
                        ? ''
                        : '${value.round()}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF746678),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    width: 24,
                    height: 105,
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 300),
                      width: 24,
                      height: mood == null
                          ? 0
                          : (value / 100) * 105,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius:
                            BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    getWeekday(targetDay),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? const Color(0xFF8E7BBE)
                          : const Color(0xFF817387),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    mood?.weather ?? '・',
                    style: const TextStyle(fontSize: 17),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalPadding =
        screenWidth < 500 ? 20.0 : screenWidth * 0.18;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const ColoredBox(
                  color: Color(0xFFF8F3FA),
                );
              },
            ),
          ),

          Positioned.fill(
  child: Container(
    color: const Color(0xFFF8F3FA)
        .withOpacity(0.10),
  ),
),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                45,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COCOON',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Color(0xFF655472),
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    '今日も、ここでひと休みしよう',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF817387),
                    ),
                  ),

                  const SizedBox(height: 20),

                  lunaHeroCard(),

                  const SizedBox(height: 31),

                  sectionTitle(
                    title: '今日の気分',
                    subtitle: widget.latestMood == null
                        ? '今の心を記録してみよう'
                        : '今の心をやさしく振り返ろう',
                  ),

                  todayMoodCard(),

                  const SizedBox(height: 31),

                  sectionTitle(
                    title: '最近7日間',
                    subtitle: '毎日の心の変化を見てみよう',
                  ),

                  sevenDayChart(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
