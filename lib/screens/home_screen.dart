import 'dart:async';
import 'dart:ui';
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
  final VoidCallback? onOpenMood;
  final VoidCallback? onOpenMyPage;
  final VoidCallback? onOpenLunaHouse;
  final VoidCallback? onOpenChat;

  const HomeScreen({
    super.key,
    this.latestMood,
    this.petImagePath,
    this.latestMemory,
    required this.lunaBond,
    required this.streakDays,
    required this.onTalkAboutMood,
    required this.moodHistory,
    this.onOpenMood,
    this.onOpenMyPage,
    this.onOpenLunaHouse,
    this.onOpenChat,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatingAnimation;
  Timer? _blinkTimer;
  Timer? _blinkEndTimer;
  bool _isBlinking = false;
  bool _tappedLuna = false;
  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || MediaQuery.of(context).disableAnimations) return;
      setState(() => _isBlinking = true);
      _blinkEndTimer = Timer(const Duration(milliseconds: 160), () {
        if (mounted) setState(() => _isBlinking = false);
      });
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      _imagesPrecached = true;
      for (final path in ['assets/images/luna_3d.png', 'assets/images/luna_3d_blink.png']) {
        precacheImage(AssetImage(path), context, onError: (error, stackTrace) {});
      }
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkEndTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // 🐶 ルナの成長レベル
  int get lunaLevel {
    if (widget.lunaBond >= 100) return 4;
    if (widget.lunaBond >= 50) return 3;
    if (widget.lunaBond >= 20) return 2;
    return 1;
  }

  // 🌷 レベルごとの名前
  String getBondLevel() {
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

  MapEntry<String, double>? strongestEmotion(MoodRecord? mood) {
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
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];

    return weekdays[date.weekday - 1];
  }

  Widget sectionTitle({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8E7BBE).withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ), // Container
      ), // BackdropFilter
    ); // ClipRRect
  }

  Widget statusItem({
    required String emoji,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
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
            style: const TextStyle(fontSize: 10, color: Color(0xFF8A7D92)),
          ),
        ],
      ),
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
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
              style: TextStyle(fontSize: 12.5, color: Color(0xFF817A84)),
            ),
          ],
        ),
      );
    }

    // ==========================================
    // 一番大きい感情
    // ==========================================
    final strongest = strongestEmotion(mood);

    final emotionName = strongest?.key ?? '今の気持ち';

    final emotionValue = strongest?.value ?? 0;

    final emotionColor = strongest == null
        ? const Color(0xFF8E7BBE)
        : getEmotionColor(strongest.key);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                child: Text(mood.weather, style: const TextStyle(fontSize: 25)),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
              value: (emotionValue / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: const Color(0xFFEDE8EF),
              valueColor: AlwaysStoppedAnimation<Color>(emotionColor),
            ),
          ),

          // ======================================
          // メモ
          // ======================================
          if (mood.memo.trim().isNotEmpty) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5F8).withValues(alpha: 0.86),
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
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
              label: const Text('この気持ちをCOCOONに話す'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E7BBE),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
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

  Future<void> showMoodDetails(MoodRecord mood) async {
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
                ...mood.emotionPercents.entries.map((entry) {
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
                }),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                final targetDay = today.subtract(Duration(days: 6 - index));

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
                      mainAxisAlignment: MainAxisAlignment.end,
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
                                    fontWeight: FontWeight.w600,
                                    color: barColor,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 4),

                        // --------------------------
                        // バー
                        // --------------------------
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: 13,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: mood == null
                                ? const Color(0xFFE8E3EA)
                                : barColor.withValues(alpha: isToday ? 0.95 : 0.72),
                            borderRadius: BorderRadius.circular(10),
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
                              fontSize: mood == null ? 12 : 15,
                              color: const Color(0xFF918994),
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
                                  : const Color(0xFF756E78),
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

  // 🐶 ルナの成長カード（リニューアル版）
  Widget lunaGrowthCard() {
    final bond = widget.lunaBond;

    final int levelStart;
    final int nextLevelPoint;
    final String nextLevelName;

    if (bond < 20) {
      levelStart = 0;
      nextLevelPoint = 20;
      nextLevelName = 'なかよし';
    } else if (bond < 50) {
      levelStart = 20;
      nextLevelPoint = 50;
      nextLevelName = 'たいせつな友達';
    } else if (bond < 100) {
      levelStart = 50;
      nextLevelPoint = 100;
      nextLevelName = 'ずっと一緒';
    } else {
      levelStart = 100;
      nextLevelPoint = 100;
      nextLevelName = '';
    }

    final isMaxLevel = lunaLevel == 4;

    final double progress = isMaxLevel
        ? 1.0
        : ((bond - levelStart) / (nextLevelPoint - levelStart))
              .clamp(0.0, 1.0)
              .toDouble();

    final remainingPoints = isMaxLevel ? 0 : nextLevelPoint - bond;

    const mainColor = Color(0xFF665272);
    const accentColor = Color(0xFFB79BCB);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xBFFFFFFF), Color(0x99F4EAF8)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6F5A80).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  const Icon(Icons.pets_outlined, size: 19, color: accentColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "LUNA'S GROWTH",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Color(0xFF8B7897),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E8F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'LEVEL ${lunaLevel.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: mainColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 関係レベル
              const Text(
                'ルナとの関係',
                style: TextStyle(fontSize: 12, color: Color(0xFF96869E)),
              ),

              const SizedBox(height: 5),

              Text(
                getBondLevel(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: mainColor,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                isMaxLevel ? 'これからも、ゆっくり一緒に過ごそう。' : '少しずつ、絆を育てていこう。',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF8A7B91),
                ),
              ),

              const SizedBox(height: 22),

              const Divider(color: Color(0xFFE9E0EC), height: 1),

              const SizedBox(height: 20),

              // ポイント表示
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '絆の成長',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mainColor,
                    ),
                  ),
                  Text(
                    isMaxLevel ? '$bond pt' : '$bond / $nextLevelPoint pt',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF887493),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 成長ゲージ
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 9,
                      backgroundColor: const Color(0xFFEDE5F1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        accentColor,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 13),

              // 次のレベルへの案内
              Text(
                isMaxLevel
                    ? '🌸 ルナとの絆がいっぱいに育ったよ'
                    : 'あと$remainingPointsポイントで「$nextLevelName」に 🌷',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF96869E),
                ),
              ),
            ],
          ), // Column
        ), // Container
      ), // BackdropFilter
    ); // ClipRRect
  }

  void _showHomeDetails() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F3FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
                child: Row(children: [
                  const Expanded(child: Text('こころとルナの記録',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                      color: Color(0xFF554F66)))),
                  IconButton(tooltip: '閉じる', onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded)),
                ]),
              ),
              Expanded(child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  lunaGrowthCard(),
                  const SizedBox(height: 24),
                  sectionTitle(title: '最近の気分', subtitle: '残してくれた気持ちを振り返ろう'),
                  todayMoodCard(),
                  const SizedBox(height: 24),
                  sectionTitle(title: '最近7日間', subtitle: '毎日の心の変化を見てみよう'),
                  sevenDayChart(),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundAction(String label, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 14, offset: const Offset(0, 6)),
        ]),
        child: Material(
          color: color, shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 4)),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            tooltip: label, onPressed: onTap, padding: const EdgeInsets.all(12),
            iconSize: 27, color: Colors.white, disabledColor: Colors.white54,
            icon: Icon(icon),
          ),
        ),
      ),
      const SizedBox(height: 9),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14)),
        child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF514660))),
      ),
    ]));
  }

  Widget _lunaInRoom(double height) {
    final image = !kIsWeb && widget.petImagePath != null
        ? Image.file(File(widget.petImagePath!), fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.pets_rounded, size: 100, color: Color(0xFF8E7BBE)))
        : Image.asset(
            _isBlinking ? 'assets/images/luna_3d_blink.png' : 'assets/images/luna_3d.png',
            fit: BoxFit.contain, gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Image.asset('assets/images/luna.png', fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.pets_rounded, size: 100, color: Color(0xFF8E7BBE))),
          );
    return SizedBox(height: height, child: Stack(alignment: Alignment.center, children: [
      Positioned(bottom: 8, child: Container(width: height * 0.48, height: 24,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), boxShadow: [
          BoxShadow(color: const Color(0xFF625478).withValues(alpha: 0.18), blurRadius: 22, spreadRadius: 4),
        ]))),
      Positioned.fill(child: Semantics(
        label: 'ルナ。タップするとメッセージが変わります', button: true,
        child: GestureDetector(
          onTap: () => setState(() { _tappedLuna = !_tappedLuna; }),
          child: AnimatedBuilder(animation: _floatingAnimation,
            child: ClipRect(child: Transform.scale(
              scale: !kIsWeb && widget.petImagePath != null ? 1.0 : 1.25,
              child: image,
            )),
            builder: (context, child) => Transform.translate(
              offset: Offset(0, MediaQuery.of(context).disableAnimations ? 0 : _floatingAnimation.value * 0.45),
              child: child,
            )),
        ),
      )),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final start = lunaLevel == 1 ? 0 : lunaLevel == 2 ? 20 : lunaLevel == 3 ? 50 : 100;
    final end = lunaLevel == 1 ? 20 : lunaLevel == 2 ? 50 : 100;
    final progress = lunaLevel == 4 ? 1.0 : ((widget.lunaBond - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      backgroundColor: const Color(0xFFF1EAF6),
      body: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/home_bg.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFE2D8EE), Color(0xFFF8EEE6)]))))),
        Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.12))),
        SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(children: [
              // The scene takes remaining height; the controls stay visible below it.
              Expanded(child: LayoutBuilder(builder: (context, sceneConstraints) {
                Widget scene() => Column(children: [
                  Row(children: [
                    Material(color: Colors.white.withValues(alpha: 0.92), shape: const CircleBorder(),
                      child: IconButton(tooltip: '記録と絆を見る', onPressed: _showHomeDetails,
                        icon: const Icon(Icons.menu_rounded, color: Color(0xFF75658B)))),
                    const SizedBox(width: 12),
                    Expanded(child: Material(
                      color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(onTap: _showHomeDetails, child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('ルナとの絆 · Lv.$lunaLevel',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF554866))),
                          const SizedBox(height: 7),
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(
                            value: progress, minHeight: 6, backgroundColor: const Color(0xFFE9E2EF),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA88CC6)))),
                        ]),
                      )),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white, width: 1.5)),
                    child: Column(children: [
                      const Text('LUNA', style: TextStyle(fontSize: 10, letterSpacing: 3,
                        fontWeight: FontWeight.bold, color: Color(0xFF9783AC))),
                      const SizedBox(height: 8),
                      AnimatedSize(duration: const Duration(milliseconds: 200),
                        child: Text(_tappedLuna ? 'なでてくれてありがとう。\nきみのそばにいるよ。' : getLunaMessage(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, height: 1.5,
                            fontWeight: FontWeight.w600, color: Color(0xFF554866)))),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: LayoutBuilder(builder: (context, heroConstraints) =>
                    _lunaInRoom(heroConstraints.maxHeight))),
                ]);
                // Short windows and enlarged text can scroll the scene without hiding chat.
                final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
                final minimumHeight = 380.0 + (textScale > 1 ? (textScale - 1) * 180 : 0);
                if (sceneConstraints.maxHeight < minimumHeight) {
                  return SingleChildScrollView(child: SizedBox(height: minimumHeight, child: scene()));
                }
                return scene();
              })),
              const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _roundAction('ルナのおうち', Icons.pets_rounded, const Color(0xFF8F7AAE), widget.onOpenLunaHouse),
                    _roundAction('気分記録', Icons.favorite_rounded, const Color(0xFFD7A0AC), widget.onOpenMood),
                    _roundAction('マイページ', Icons.person_rounded, const Color(0xFF829B9B), widget.onOpenMyPage),
                  ]),
              const SizedBox(height: 12),
                  Material(
                    color: Colors.white.withValues(alpha: 0.96), borderRadius: BorderRadius.circular(30),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(onTap: widget.onOpenChat ?? widget.onTalkAboutMood,
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                        child: Row(children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF8E7BBE)),
                          SizedBox(width: 12),
                          Expanded(child: Text('ルナに話しかける', style: TextStyle(fontSize: 14, color: Color(0xFF80718F)))),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFF8E7BBE)),
                        ])),
                    ),
                  ),
            ]),
          ),
        ))),
      ]),
    );
  }
}
