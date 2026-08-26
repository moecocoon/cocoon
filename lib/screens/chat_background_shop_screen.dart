import 'package:flutter/material.dart';
import '../services/purchase_service.dart';
class ChatBackgroundShopScreen extends StatefulWidget {
  final Function(String) onBackgroundSelected;
  final String currentBackgroundPath;

  const ChatBackgroundShopScreen({
    super.key,
    required this.onBackgroundSelected,
    required this.currentBackgroundPath,
  });

  @override
  State<ChatBackgroundShopScreen> createState() =>
      _ChatBackgroundShopScreenState();
}


class _ChatBackgroundShopScreenState
    extends State<ChatBackgroundShopScreen> {

  final PurchaseService purchaseService =
      PurchaseService.instance;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializePurchase();
  }

  Future<void> initializePurchase() async {
    await purchaseService.initialize();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

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
  child: SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
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

                   SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed:
        widget.currentBackgroundPath ==
                'assets/images/chat_bg_default.png'
            ? null
            : () {
                widget.onBackgroundSelected(
                  'assets/images/chat_bg_default.png',
                );

                setState(() {});
              },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEDE5F5),
      disabledBackgroundColor: const Color(0xFFEDE5F5),
      foregroundColor: const Color(0xFF725D8D),
      disabledForegroundColor: const Color(0xFF725D8D),
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: Text(
      widget.currentBackgroundPath ==
              'assets/images/chat_bg_default.png'
          ? '使用中'
          : 'この背景にする',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
                  ],
                ),
              ),

              const SizedBox(height: 20),
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
                        'assets/images/chat_bg_star_night.png',
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
                            '星降るルナの夜空',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF655472),
                            ),
                          ),
                        ),
                        Text(
                          '¥160',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E7BBE),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      '満天の星に包まれる、静かな夜のお部屋。',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF82778A),
                      ),
                    ),

                    const SizedBox(height: 12),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
 onPressed:
    widget.currentBackgroundPath ==
            'assets/images/chat_bg_star_night.png'
        ? null
        : () {
            widget.onBackgroundSelected(
              'assets/images/chat_bg_star_night.png',
            );

            setState(() {});

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '星降るルナの夜空に変更しました 🌙',
                ),
              ),
            );
          },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF8E7BBE),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),
    child: Text(
  widget.currentBackgroundPath ==
          'assets/images/chat_bg_star_night.png'
      ? '使用中'
      : 'この背景にする',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
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
      ),
    );
  }
}