import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();
  int currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      'image': 'assets/images/luna.png',
      'title': 'COCOONへようこそ',
      'description': 'ここは、誰にも言えない気持ちを\n自分のペースで話せる場所です。',
    },
    {
      'image': 'assets/images/luna.png',
      'title': 'ルナと話そう',
      'description':
          'うれしいことも、しんどいことも。\nルナがあなたの気持ちを聞いて、一緒に整理します。',
    },
    {
      'image': 'assets/images/emotion_peace.png',
      'title': '今日の気分を記録',
      'description':
          '心の天気や感情の大きさを記録できます。\n振り返ることで、自分の変化に気づけます。',
    },
    {
      'image': 'assets/images/kokoro_bg.png',
      'title': '心の広場でひと休み',
      'description':
          '深呼吸の森、ひとやすみカフェ、夜の避難所など、\n今の心に合う場所でゆっくり休めます。',
    },
    {
      'image': 'assets/images/luna.png',
      'title': 'わたし年表をつくろう',
      'description':
          'これまでの出来事や、生きてきた時代を記録します。\nルナがあなたの歩みを知り、会話にも活かします。',
    },
    {
      'image': 'assets/images/luna.png',
      'title': 'ひとりで抱え込まなくて大丈夫',
      'description': 'COCOONは、あなたを急がせません。\nここから少しずつ始めよう。',
    },
  ];

  void goNext() {
    if (currentPage == pages.length - 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LunaFirstMeetingScreen(
            onStart: widget.onComplete,
          ),
        ),
      );
      return;
    }

    pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: const Text(
                  'スキップ',
                  style: TextStyle(
                    color: Color(0xFF8E7BBE),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Image.asset(
                              item['image']!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: item['image'] ==
                                      'assets/images/kokoro_bg.png'
                                  ? BoxFit.cover
                                  : BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 38),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6F5B8E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['description']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: Color(0xFF6D6478),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? const Color(0xFF8E7BBE)
                        : const Color(0xFFDCD3E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E7BBE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    isLastPage ? 'COCOONをはじめる' : '次へ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LunaFirstMeetingScreen extends StatefulWidget {
  final VoidCallback onStart;

  const LunaFirstMeetingScreen({
    super.key,
    required this.onStart,
  });

  @override
  State<LunaFirstMeetingScreen> createState() =>
      _LunaFirstMeetingScreenState();
}

class _LunaFirstMeetingScreenState extends State<LunaFirstMeetingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> fadeAnimation;
  late final Animation<double> scaleAnimation;

  int messageStep = 0;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );

    scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutBack,
      ),
    );

    animationController.forward();
    showMessages();
  }

  Future<void> showMessages() async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() {
      messageStep = 1;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() {
      messageStep = 2;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      messageStep = 3;
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 70,
              left: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9D5FF).withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4EE).withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: fadeAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: Container(
                        width: 240,
                        height: 240,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8E7BBE)
                                  .withOpacity(0.16),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/luna.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  AnimatedOpacity(
                    opacity: messageStep >= 1 ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: const Text(
                      'はじめまして。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F5B8E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: messageStep >= 2 ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: const Text(
                      'ぼくは、ルナ。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7D7087),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedOpacity(
                    opacity: messageStep >= 3 ? 1 : 0,
                    duration: const Duration(milliseconds: 650),
                    child: const Text(
                      'うれしい日も、しんどい日も。\n'
                      'これから、あなたのそばで\n'
                      '一緒に歩いていくよ🌱',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: Color(0xFF6D6478),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: messageStep >= 3 ? 1 : 0,
                    duration: const Duration(milliseconds: 700),
                    child: IgnorePointer(
                      ignoring: messageStep < 3,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: widget.onStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E7BBE),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            '🐾 ルナと歩きはじめる',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }
}