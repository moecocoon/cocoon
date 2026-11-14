import 'package:flutter/material.dart';

import 'luna_widget.dart';

class GardenArea extends StatelessWidget {
  final Widget? luna;
  final Function(String)? onEmotionTap;
  final Map<String, double> emotionPercents;

  const GardenArea({
    super.key,
    this.luna,
    this.onEmotionTap,
    this.emotionPercents = const {},
  });

  double emotionSize(String key, double defaultSize) {
    // 記録がないときは、今までの大きさ
    if (emotionPercents.isEmpty) return defaultSize;

    final value = emotionPercents[key] ?? 0;
    final percent = value.isFinite
        ? value.clamp(0.0, 100.0).toDouble()
        : 0.0;

    // 0％で44、100％で84
    return 44.0 + 40.0 * percent / 100.0;
  }

  Widget emotionImage({
    required String id,
    required String label,
    required String imagePath,
    required String moodKey,
    required double defaultSize,
  }) {
    final size = emotionSize(moodKey, defaultSize);

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () => onEmotionTap?.call(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: size,
          height: size,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sadSize = emotionSize('😢 悲しい', 55);

    return Container(
      height: 540,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: const DecorationImage(
          image: AssetImage(
            'assets/images/garden/garden_bg.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [

            // うれしいさん
Positioned(
  right: 25,
  top: 280,
  child: emotionImage(
    id: 'happy',
    label: 'うれしいさん',
    imagePath: 'assets/images/emotion_happy.png',
    moodKey: '😊 うれしい',
    defaultSize: 55,
  ),
),

// がんばったさん
Positioned(
  left: 0,
  right: 0,
  top: 210,
  child: Center(
    child: emotionImage(
      id: 'effort',
      label: 'がんばったさん',
      imagePath: 'assets/images/emotion_effort.png',
      moodKey: '🥹 がんばった',
      defaultSize: 55,
    ),
  ),
),
            Positioned(
              left: 25,
              top: 170,
              child: emotionImage(
                id: 'anxiety',
                label: '不安さん',
                imagePath: 'assets/images/emotion_anxiety.png',
                moodKey: '😰 不安',
                defaultSize: 55,
              ),
            ),
            Positioned(
              right: 25,
              top: 170,
              child: emotionImage(
                id: 'peace',
                label: '安心さん',
                imagePath: 'assets/images/emotion_peace.png',
                moodKey: '😌 安心',
                defaultSize: 55,
              ),
            ),

            // 悲しいさんは、いったん絵文字で表示
            Positioned(
              left: 0,
              right: 0,
              top: 110,
              child: Center(
                child: Tooltip(
                  message: '悲しいさん',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    width: sadSize,
                    height: sadSize,
                    alignment: Alignment.center,
                    child: GestureDetector(
  onTap: () => onEmotionTap?.call('sad'),
  child: Image.asset(
    'assets/images/emotion_sad.png',
    fit: BoxFit.contain,
  ),
),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 35,
              bottom: 25,
              child: emotionImage(
                id: 'lonely',
                label: 'さみしいさん',
                imagePath: 'assets/images/emotion_lonely.png',
                moodKey: '🫂 さみしい',
                defaultSize: 58,
              ),
            ),
            Positioned(
              right: 30,
              bottom: 25,
              child: emotionImage(
                id: 'tired',
                label: 'おつかれさん',
                imagePath: 'assets/images/emotion_tired.png',
                moodKey: '😴 疲れ',
                defaultSize: 58,
              ),
            ),
            Positioned(
  left: 25,
  top: 280,
              child: emotionImage(
                id: 'angry',
                label: 'イライラさん',
                imagePath: 'assets/images/emotion_angry.png',
                moodKey: '😡 イライラ',
                defaultSize: 55,
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.58),
              child: luna ?? const LunaWidget(size: 170),
            ),
          ],
        ),
      ),
    );
  }
}
