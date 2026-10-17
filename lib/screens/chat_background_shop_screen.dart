import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool starNightPurchased = false;
  late String selectedBackgroundPath;

@override
void initState() {
  super.initState();

  selectedBackgroundPath =
      widget.currentBackgroundPath;

  purchaseService.starNightPurchasedNotifier
      .addListener(_onPurchaseChanged);

  initializePurchase();
}

void _onPurchaseChanged() {
  if (!mounted) return;

  setState(() {
    starNightPurchased =
        purchaseService.starNightPurchasedNotifier.value;
  });
}

@override
void dispose() {
  purchaseService.starNightPurchasedNotifier
      .removeListener(_onPurchaseChanged);

  super.dispose();
}

 Future<void> initializePurchase() async {
  await purchaseService.initialize();

  if (!mounted) return;

  setState(() {
    starNightPurchased =
        purchaseService.starNightPurchased;

    isLoading = false;
  });
}

// ★ コンパクト背景カード ★
Widget backgroundCard({
  required String title,
  required String imagePath,
  required String priceText,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.asset(
            imagePath,
            width: double.infinity,
            height: 110,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF655472),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          priceText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E7BBE),
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSelected ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDE5F5),
              disabledBackgroundColor:
                  const Color(0xFFEDE5F5),
              foregroundColor: const Color(0xFF725D8D),
              disabledForegroundColor:
                  const Color(0xFF725D8D),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSelected ? '使用中' : 'この背景にする',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
// ★ 課金背景用コンパクトカード ★
Widget paidBackgroundCard({
  required String title,
  required String imagePath,
  required String priceText,
  required bool isSelected,
  required bool isPurchased,
  required VoidCallback onUse,
  required VoidCallback onBuy,
}) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.asset(
            imagePath,
            width: double.infinity,
            height: 110,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF655472),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          priceText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E7BBE),
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSelected
                ? null
                : isPurchased
                    ? onUse
                    : onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: isPurchased
                  ? const Color(0xFFEDE5F5)
                  : const Color(0xFF8E7BBE),
              disabledBackgroundColor:
                  const Color(0xFFEDE5F5),
              foregroundColor: isPurchased
                  ? const Color(0xFF725D8D)
                  : Colors.white,
              disabledForegroundColor:
                  const Color(0xFF725D8D),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSelected
                  ? '使用中'
                  : isPurchased
                      ? 'この背景にする'
                      : '🔒 $priceTextで購入',
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
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

Align(
  alignment: Alignment.centerRight,
  child: TextButton.icon(
    onPressed: () async {
      await purchaseService.restorePurchases();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '購入履歴を確認しています',
          ),
        ),
      );
    },
    icon: const Icon(
      Icons.restore_rounded,
      size: 18,
    ),
    label: const Text(
      '購入を復元',
    ),
  ),
),

              const SizedBox(height: 24),

              // ★ 夢見るルナ ＋ 星空：コンパクト2列 ★
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 夢見るルナ
    Expanded(
      child: backgroundCard(
        title: '夢見るルナ',
        imagePath: 'assets/images/chat_bg_default.png',
        priceText: '無料',
        isSelected:
            selectedBackgroundPath ==
                'assets/images/chat_bg_default.png',
        onTap: () {
          widget.onBackgroundSelected(
            'assets/images/chat_bg_default.png',
          );

          setState(() {
            selectedBackgroundPath =
                'assets/images/chat_bg_default.png';
          });
        },
      ),
    ),

    const SizedBox(width: 12),

    // 星空
    Expanded(
      child: paidBackgroundCard(
        title: '星降るルナの夜空',
        imagePath: 'assets/images/chat_bg_star_night.png',
        priceText:
            purchaseService.starNightProduct?.price ?? '¥160',
        isSelected:
            selectedBackgroundPath ==
                'assets/images/chat_bg_star_night.png',
        isPurchased: starNightPurchased,

        // 購入済み → 背景にする
        onUse: () {
          widget.onBackgroundSelected(
            'assets/images/chat_bg_star_night.png',
          );

          setState(() {
            selectedBackgroundPath =
                'assets/images/chat_bg_star_night.png';
          });
        },

        // 未購入 → 購入
        onBuy: () async {
          // Chromeでは開発用の仮購入
          if (kIsWeb) {
            final prefs =
                await SharedPreferences.getInstance();

            await prefs.setBool(
              'purchased_star_night',
              true,
            );

            if (!mounted) return;

            setState(() {
              starNightPurchased = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '開発用：購入テストが完了しました',
                ),
              ),
            );

            return;
          }

          // iPhoneでは本物のストア購入
          try {
            await purchaseService.buyStarNight();
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '購入を開始できませんでした。',
                ),
              ),
            );
          }
        },
      ),
    ),
  ],
),

const SizedBox(height: 20),

              const SizedBox(height: 20),
              
              // ★ 朝焼け ＋ 虹：コンパクト2列 ★
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: backgroundCard(
        title: '朝焼けのルナ',
        imagePath: 'assets/images/chat_bg_sunrise.png',
        priceText: '無料',
        isSelected:
            selectedBackgroundPath ==
                'assets/images/chat_bg_sunrise.png',
        onTap: () {
          widget.onBackgroundSelected(
            'assets/images/chat_bg_sunrise.png',
          );

          setState(() {
            selectedBackgroundPath =
                'assets/images/chat_bg_sunrise.png';
          });
        },
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
      child: backgroundCard(
        title: '虹とルナのお部屋',
        imagePath: 'assets/images/chat_bg_rainbow.png',
        priceText: '無料',
        isSelected:
            selectedBackgroundPath ==
                'assets/images/chat_bg_rainbow.png',
        onTap: () {
          widget.onBackgroundSelected(
            'assets/images/chat_bg_rainbow.png',
          );

          setState(() {
            selectedBackgroundPath =
                'assets/images/chat_bg_rainbow.png';
          });
        },
      ),
    ),
  ],
),

const SizedBox(height: 20),
// ★ 雨音のルナカフェ：コンパクト ★
SizedBox(
  width: (MediaQuery.of(context).size.width - 52) / 2,
  child: backgroundCard(
    title: '雨音のルナカフェ',
    imagePath: 'assets/images/chat_bg_rain_cafe.png',
    priceText: '無料',
    isSelected:
        selectedBackgroundPath ==
            'assets/images/chat_bg_rain_cafe.png',
    onTap: () {
      widget.onBackgroundSelected(
        'assets/images/chat_bg_rain_cafe.png',
      );

      setState(() {
        selectedBackgroundPath =
            'assets/images/chat_bg_rain_cafe.png';
      });
    },
  ),
),

const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }
}