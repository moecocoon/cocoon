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
            fontWeight: FontWeight.w700,

            // 背景の上でも読みやすい濃い色
            color: Color(0xFF4F4852),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,

            // 今までより少し濃く
            color: Color(0xFF68616B),
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
  return Column(
    children: [
      // ==============================
      // ルナ
      // ==============================
      SizedBox(
        height: 215,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ルナの後ろのやわらかい光
            Container(
              width: 205,
              height: 205,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.28),
              ),
            ),

            // ルナ
            !kIsWeb && widget.petImagePath != null
                ? Image.file(
                    File(widget.petImagePath!),
                    height: 190,
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
                          color: Color(0xFF8E7BBE),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),

      const SizedBox(height: 4),

      // ==============================
      // ルナの吹き出し
      // ==============================
      Container(
        constraints: const BoxConstraints(
          maxWidth: 340,
        ),
        padding: const EdgeInsets.fromLTRB(
          20,
          15,
          20,
          15,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.90),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: Color(0xFF8E7BBE),
                ),
                SizedBox(width: 6),
                Text(
                  'ルナからのメッセージ',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF817387),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              getLunaMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: Color(0xFF574F5C),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 14),

      // ==============================
      // 絆・継続日数・関係
      // ==============================
      Container(
        constraints: const BoxConstraints(
          maxWidth: 340,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.64),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.76),
          ),
        ),
        child: Row(
          children: [
            statusItem(
              emoji: '♡',
              value: '${widget.lunaBond}',
              label: 'ルナとの絆',
            ),

            Container(
              width: 1,
              height: 38,
              color: const Color(0xFFE4DDE7),
            ),

            statusItem(
              emoji: '🔥',
              value: '${widget.streakDays}日',
              label: '継続日数',
            ),

            Container(
              width: 1,
              height: 38,
              color: const Color(0xFFE4DDE7),
            ),

            statusItem(
              emoji: '🐾',
              value: getBondLevel(),
              label: '今の関係',
            ),
          ],
        ),
      ),
    ],
  );
}
Widget todayMoodCard() {
  final mood = widget.latestMood;

  // ==========================================
  // まだ今日の気分を記録していない
  // ==========================================
  if (mood == null) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF4EEF7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_outlined,
              size: 24,
              color: Color(0xFF8E7BBE),
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'まだ今日の気分は記録されていません',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D5660),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            '今の心を、少しだけ残してみよう。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF817A84),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 一番大きい感情
  // ==========================================
  final strongest = strongestEmotion(mood);

  final emotionName =
      strongest?.key ?? '今の気持ち';

  final emotionValue =
      strongest?.value ?? 0;

  final emotionColor = strongest == null
      ? const Color(0xFF8E7BBE)
      : getEmotionColor(strongest.key);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      20,
      20,
      20,
      18,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.78),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: Colors.white.withOpacity(0.88),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================
        // 天気 ＋ 今日
        // ======================================
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2F8),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text(
                mood.weather,
                style: const TextStyle(
                  fontSize: 25,
                ),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日いちばん近い気持ち',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF817A84),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    emotionName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF554F59),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              '${emotionValue.round()}%',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: emotionColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ======================================
        // 感情バー
        // ======================================
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: (emotionValue / 100)
                .clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor:
                const Color(0xFFEDE8EF),
            valueColor:
                AlwaysStoppedAnimation<Color>(
              emotionColor,
            ),
          ),
        ),

        // ======================================
        // メモ
        // ======================================
        if (mood.memo.trim().isNotEmpty) ...[
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F8)
                  .withOpacity(0.86),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              mood.memo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF6D6670),
              ),
            ),
          ),
        ],

        const SizedBox(height: 17),

        // ======================================
        // COCOONに話す
        // ======================================
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: widget.onTalkAboutMood,
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 17,
            ),
            label: const Text(
              'この気持ちをCOCOONに話す',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF8E7BBE),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(23),
              ),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
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

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      16,
      20,
      16,
      16,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.76),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: Colors.white.withOpacity(0.86),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        // ==============================
        // 上の小さな案内
        // ==============================
        Row(
          children: [
            const Icon(
              Icons.auto_graph_rounded,
              size: 17,
              color: Color(0xFF8E7BBE),
            ),

            const SizedBox(width: 7),

            const Text(
              '7日間のこころ',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF716978),
              ),
            ),

            const Spacer(),

            Text(
              '${today.month}月',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF918994),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ==============================
        // 7日間グラフ
        // ==============================
        SizedBox(
          height: 170,
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
                  ? const Color(0xFFDCD6DF)
                  : getEmotionColor(strongest.key);

              final isToday =
                  targetDay.year == today.year &&
                  targetDay.month == today.month &&
                  targetDay.day == today.day;

              // 記録がある日は最低でも少しバーを見せる
              final barHeight = mood == null
                  ? 8.0
                  : 20.0 + (value / 100 * 65);

              return Expanded(
                child: GestureDetector(
                  onTap: mood == null
                      ? null
                      : () {
                          showMoodDetails(mood);
                        },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      // --------------------------
                      // %
                      // --------------------------
                      SizedBox(
                        height: 20,
                        child: mood == null
                            ? const SizedBox.shrink()
                            : Text(
                                '${value.round()}%',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: barColor,
                                ),
                              ),
                      ),

                      const SizedBox(height: 4),

                      // --------------------------
                      // バー
                      // --------------------------
                      AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 350,
                        ),
                        curve: Curves.easeOutCubic,
                        width: 13,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: mood == null
                              ? const Color(0xFFE8E3EA)
                              : barColor.withOpacity(
                                  isToday ? 0.95 : 0.72,
                                ),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // --------------------------
                      // 天気
                      // --------------------------
                      SizedBox(
                        height: 20,
                        child: Text(
                          mood?.weather ?? '・',
                          style: TextStyle(
                            fontSize:
                                mood == null ? 12 : 15,
                            color: const Color(
                              0xFF918994,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // --------------------------
                      // 曜日
                      // --------------------------
                      Container(
                        width: 27,
                        height: 27,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF8E7BBE)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          getWeekday(targetDay),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? Colors.white
                                : const Color(
                                    0xFF756E78,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 12),

        // ==============================
        // 下の案内
        // ==============================
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.touch_app_outlined,
              size: 13,
              color: Color(0xFF9A929C),
            ),

            const SizedBox(width: 5),

            Text(
              widget.moodHistory.isEmpty
                  ? '気分を記録すると、ここに残っていくよ'
                  : '曜日をタップすると、その日の記録を見られるよ',
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF918994),
              ),
            ),
          ],
        ),
      ],
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
                 Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COCOON',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.2,
            color: Color(0xFF554F59),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '${DateTime.now().month}月${DateTime.now().day}日・'
          '${getWeekday(DateTime.now())}曜日',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF777079),
          ),
        ),
      ],
    ),

    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.72),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 14,
            color: Color(0xFF8E7BBE),
          ),
          SizedBox(width: 5),
          Text(
            'ひと休みしよう',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF655D69),
            ),
          ),
        ],
      ),
    ),
  ],
),

const SizedBox(height: 16),

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
