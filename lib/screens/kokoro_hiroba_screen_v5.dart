import 'package:flutter/material.dart';

import '../services/weather_service.dart';
import '../widgets/garden_area.dart';
import '../widgets/garden_header.dart';
import '../widgets/luna_widget.dart';

const String openWeatherApiKey = String.fromEnvironment(
  'OPENWEATHER_API_KEY',
);

class KokoroHirobaScreenV5 extends StatefulWidget {
  final ValueChanged<String> onListenEmotion;
  final VoidCallback onBreathing;
  final VoidCallback onCafe;
  final VoidCallback onNightShelter;
  final VoidCallback onLunaHouse;

  const KokoroHirobaScreenV5({
    super.key,
    required this.onListenEmotion,
    required this.onBreathing,
    required this.onCafe,
    required this.onNightShelter,
    required this.onLunaHouse,
  });

  @override
  State<KokoroHirobaScreenV5> createState() =>
      _KokoroHirobaScreenV5State();
}

class _KokoroHirobaScreenV5State
    extends State<KokoroHirobaScreenV5> {
  WeatherData? weatherData;
  bool isWeatherLoading = true;
  String lunaMessage = '今日もゆっくり歩こう。';

  String? selectedEmotion;
bool showTalkButton = false;

  @override
  void initState() {
    super.initState();

    _loadWeather();

  }

  Future<void> _loadWeather() async {
    if (openWeatherApiKey.isEmpty) {
      if (!mounted) return;

      setState(() {
        isWeatherLoading = false;
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
        lunaMessage = _weatherMessage(result.condition);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isWeatherLoading = false;
      });
    }
  }

  String _weatherMessage(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '今日は気持ちのいい空だね。庭を一緒に歩こう。';

      case 'clouds':
        return '今日はやわらかい曇り空だね。ゆっくり過ごそう。';

      case 'rain':
      case 'drizzle':
        return '今日は雨だね。ここで一緒に雨宿りしよう。';

      case 'thunderstorm':
        return '外は少し荒れているね。ここでは安心して休んでね。';

      case 'snow':
        return '雪が降っているね。あたたかくして過ごそう。';

      default:
        return 'おかえり。今日もゆっくり歩こう。';
    }
  }

  String get weatherText {
    if (isWeatherLoading) {
      return '🌤️ 天気を取得中…';
    }

    if (weatherData == null) {
      return '🌿 今日の庭';
    }

    return '${weatherData!.weatherEmoji} '
        '${weatherData!.weatherLabel} '
        '${weatherData!.temperatureText}';
  }

  String get cityName {
    return weatherData?.cityName ?? '現在地';
  }

  void _showDestinationMessage(
    String message,
    VoidCallback destination,
  ) {
    setState(() {
      lunaMessage = message;
    });

    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        if (!mounted) return;
        destination();
      },
    );
  }

Widget destinationImageCard({
  required String imagePath,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.50),
                        Colors.black.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 17,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.90),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF6F5B8E),
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
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '心の広場',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F5B8E),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'ルナと一緒に、心の庭を歩こう',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF82778A),
                ),
              ),
              const SizedBox(height: 16),

              GardenHeader(
                weatherText: weatherText,
                cityName: cityName,
                lunaMessage: lunaMessage,
              ),

              const SizedBox(height: 18),

     GardenArea(
  onEmotionTap: (emotionId) {
    setState(() {
        selectedEmotion = emotionId;
      showTalkButton = true;

      switch (emotionId) {
        case "anxiety":
          lunaMessage =
              "今日は不安さんが遊びに来ているね。何か心配なことがあったのかな？";
          break;

        case "peace":
          lunaMessage =
              "安心さんがいるね。今日は少し心が落ち着いているみたい。";
          break;

        case "lonely":
          lunaMessage =
              "さみしいさんが来ているね。ここでは一人で頑張らなくていいよ。";
          break;

        case "tired":
          lunaMessage =
              "おつかれさんも休みに来たみたい。一緒に少し休憩しよう。";
          break;

        case "angry":
          lunaMessage =
              "イライラさんが何か伝えたいことがあるみたい。ゆっくり話を聞いてみよう。";
          break;
      }
    });
  },

  luna: LunaWidget(
    size: 170,
    isWalking: false,
    onTap: () {
      setState(() {
        lunaMessage = "呼んだ？ルナはここにいるよ🐾";
      });
    },
  ),
),

if (selectedEmotion != null)
  Padding(
    padding: const EdgeInsets.only(
      top: 14,
      bottom: 10,
    ),
    child: Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: selectedEmotion == null
              ? null
              : () {
                  widget.onListenEmotion(
                    selectedEmotion!,
                  );
                },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFFB9A2CA),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF72598E)
                      .withOpacity(0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 19,
                  color: Color(0xFF755D8D),
                ),
                SizedBox(width: 8),
                Text(
                  'この気持ちについて話す',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF604C6E),
                  ),
                ),
                SizedBox(width: 7),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF8F78A0),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),

              const SizedBox(height: 24),

              const Text(
                'どこへ行く？',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F5B8E),
                ),
              ),
              const SizedBox(height: 10),
destinationImageCard(
  imagePath: 'assets/images/forest_card.png',
  title: '深呼吸の森',
  subtitle: '呼吸を整えて、心をゆるめる場所',
  onTap: () {
    _showDestinationMessage(
      '深呼吸の森へ行こう。ゆっくり歩いていこうね。',
      widget.onBreathing,
    );
  },
),

destinationImageCard(
  imagePath: 'assets/images/cafe_card.png',
  title: 'ひとやすみカフェ',
  subtitle: 'やさしい言葉と一緒にひと休み',
  onTap: () {
    _showDestinationMessage(
      'ひとやすみカフェで、少し休んでいこう。',
      widget.onCafe,
    );
  },
),

destinationImageCard(
  imagePath: 'assets/images/night_card.png',
  title: '夜の避難所',
  subtitle: '眠れない夜に安心できる場所',
  onTap: () {
    _showDestinationMessage(
      '夜の避難所へ行こう。ここでは安心していいよ。',
      widget.onNightShelter,
    );
  },
),

destinationImageCard(
  imagePath: 'assets/images/luna_house_card.png',
  title: 'ルナのおうち',
  subtitle: 'ルナとゆっくり過ごす場所',
  onTap: () {
    _showDestinationMessage(
      'ルナのおうちで、一緒にのんびりしよう。',
      widget.onLunaHouse,
    );
  },
),
            ],
          ),
        ),
      ),
    );
  }
}