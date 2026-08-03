import 'package:flutter/material.dart';

import '../models/mood_record.dart';

class MoodRecordScreen extends StatefulWidget {
  final Function(MoodRecord) onSave;

  const MoodRecordScreen({
    super.key,
    required this.onSave,
  });

  @override
  State<MoodRecordScreen> createState() =>
      _MoodRecordScreenState();
}

class _MoodRecordScreenState extends State<MoodRecordScreen> {
  String? selectedWeather;

  final Map<String, double> emotionPercents = {};

  final TextEditingController memoController =
      TextEditingController();

  final List<String> weathers = [
    '☀️',
    '🌤️',
    '☁️',
    '🌧️',
    '🌙',
  ];

  final List<String> emotions = [
    '😊',
    '😌',
    '🥹',
    '😰',
    '😢',
    '😴',
    '😡',
    '🫂',
  ];

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

  final Map<String, String> weatherNames = {
    '☀️': '晴れ',
    '🌤️': '少し晴れ',
    '☁️': 'くもり',
    '🌧️': '雨',
    '🌙': '夜',
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
        const SnackBar(
          content: Text('今日の心の天気を選んでね'),
        ),
      );
      return;
    }

    if (emotionPercents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('近い感情を1つ以上選んでね'),
        ),
      );
      return;
    }

    widget.onSave(
      MoodRecord(
        weather: selectedWeather!,
        emotionPercents:
            Map<String, double>.from(emotionPercents),
        memo: memoController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('今日の気分を記録できたよ🌿'),
      ),
    );

    setState(() {
      selectedWeather = null;
      emotionPercents.clear();
      memoController.clear();
    });
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
              color: Color(0xFF9A8FA5),
            ),
          ),
        ],
      ),
    );
  }

  Widget moodCard({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF8E7BBE).withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget weatherItem(String weather) {
    final selected = selectedWeather == weather;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedWeather = weather;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 82,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE8DAF2)
                : const Color(0xFFF8F3FA),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? const Color(0xFF8E7BBE)
                  : Colors.transparent,
              width: 1.7,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: selected ? 1.15 : 1,
                child: Text(
                  weather,
                  style: const TextStyle(fontSize: 29),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                weatherNames[weather] ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: selected
                      ? const Color(0xFF765D8D)
                      : const Color(0xFF8A7D92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget emotionItem(String emoji) {
    final key = '$emoji ${emotionNames[emoji]}';
    final selected = emotionPercents.containsKey(key);

    return GestureDetector(
      onTap: () {
        toggleEmotion(emoji);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE9DCF3)
              : const Color(0xFFF8F3FA),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: selected
                ? const Color(0xFF8E7BBE)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 23),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                emotionNames[emoji] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: selected
                      ? const Color(0xFF6E567F)
                      : const Color(0xFF706578),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF8E7BBE),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget emotionSlider(
    MapEntry<String, double> entry,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(
        17,
        16,
        17,
        12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF4EAFB),
            Color(0xFFFFF1F5),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF655472),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${entry.value.round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E7BBE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Slider(
            value: entry.value,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: const Color(0xFF8E7BBE),
            inactiveColor: const Color(0xFFE0D5E6),
            onChanged: (value) {
              setState(() {
                emotionPercents[entry.key] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            35,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今日のこころ',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF655472),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  21,
                  22,
                  21,
                  22,
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
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E7BBE)
                          .withOpacity(0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child:  Row(
                  children: [
                    Container(
                      width: 59,
                      height: 59,
                      decoration: BoxDecoration(
                        color: Color(0xCCFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFB888A4),
                        size: 29,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '今日はどんな一日だった？',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF655472),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'うまく言葉にできなくても大丈夫。'
                            '今の気持ちに近いものを選んでね。',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Color(0xFF817387),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 31),

              sectionTitle(
                title: '心の天気',
                subtitle: '今の心に近い空模様を選んでね',
              ),

              moodCard(
                child: Row(
                  children: weathers
                      .map(weatherItem)
                      .toList(),
                ),
              ),

              const SizedBox(height: 29),

              sectionTitle(
                title: '今近い感情',
                subtitle: 'いくつ選んでも大丈夫だよ',
              ),

              moodCard(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: emotions.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.45,
                  ),
                  itemBuilder: (context, index) {
                    return emotionItem(
                      emotions[index],
                    );
                  },
                ),
              ),

              if (emotionPercents.isNotEmpty) ...[
                const SizedBox(height: 29),

                sectionTitle(
                  title: '気持ちの大きさ',
                  subtitle: 'それぞれの強さを調整してね',
                ),

                moodCard(
                  child: Column(
                    children: emotionPercents.entries
                        .map(emotionSlider)
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: 29),

              sectionTitle(
                title: '今日のこと',
                subtitle: '書ける範囲で、少しだけ残してみよう',
              ),

              moodCard(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  8,
                ),
                child: TextFormField(
                  controller: memoController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    hintText:
                        '今日あったことや、今思っていることを書いてね',
                    hintStyle: TextStyle(
                      color: Color(0xFFA69BAA),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF8E7BBE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(23),
                    ),
                    elevation: 0,
                  ),
                  onPressed: saveRecord,
                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                  ),
                  label: const Text(
                    '今日の気分を記録する',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'ここに残した気持ちは、あなたの大切な記録です。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A8FA5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum LunaEmotion {
  happy,
  anxious,
  sad,
  angry,
  tired,
  neutral,
}

enum LunaIntent {
  wish,
  success,
  positiveReport,
  problem,
  question,
  neutral,
}

enum LunaTopic {
  love,
  work,
  school,
  family,
  friend,
  health,
  general,
}
