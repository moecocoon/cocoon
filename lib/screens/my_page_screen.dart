import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'chat_background_shop_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'emergency_contact_screen.dart';
import '../models/mood_record.dart';
import 'mood_calendar_screen.dart';
import 'my_timeline_screen.dart';
import 'profile_setup_screen.dart';
import 'recovery_album_screen.dart';
import 'package:cocoon/screens/support_contact_screen.dart';


class MyPageScreen extends StatelessWidget {
  final List<MoodRecord> moodHistory;
  final int lunaBond;
  final int streakDays;
  final Function(String) onChatBackgroundChanged;
  final String currentChatBackgroundPath;

  const MyPageScreen({
    super.key,
    required this.moodHistory,
    required this.lunaBond,
    required this.streakDays,
    required this.onChatBackgroundChanged,
    required this.currentChatBackgroundPath,
  });


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

  Widget statItem({
    required String icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF665675),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF897C94),
            ),
          ),
        ],
      ),
    );
  }

  Widget menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 17,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.85),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E7BBE).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F526D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xFF83768D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8E7BBE),
                    size: 23,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget smallMenuTile({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 132,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E7BBE).withOpacity(0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5F526D),
                  ),
                ),
              ],
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
          child: Column(
            children: [
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'マイページ',
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF655472),
                        ),
                      ),
                    ),
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Color(0xFF8E7BBE),
                        size: 23,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // プロフィールエリア
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.fromLTRB(
                  22,
                  25,
                  22,
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
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E7BBE).withOpacity(0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8E7BBE)
                                    .withOpacity(0.16),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
  radius: 61,
  backgroundColor: Color(0xFFF8F3FA),
  backgroundImage: AssetImage(
    'assets/images/luna.png',
  ),
),
                        ),
                        
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'ルナ',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF665675),
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      '今日も、あなたのそばにいるよ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF817387),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.67),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Row(
                        children: [
                          statItem(
                            icon: '❤️',
                            value: '$lunaBond',
                            label: 'ルナとの絆',
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: const Color(0xFFE4D9E9),
                          ),
                          statItem(
                            icon: '🔥',
                            value: '$streakDays日',
                            label: '継続日数',
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: const Color(0xFFE4D9E9),
                          ),
                          statItem(
                            icon: '🌷',
                            value: '${moodHistory.length}回',
                            label: '気分記録',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 33),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    sectionTitle(
                      title: 'わたしの記録',
                      subtitle: 'これまでの歩みや心の変化',
                    ),

                    menuTile(
                      icon: Icons.auto_stories_rounded,
                      title: '回復アルバム',
                      subtitle: '${moodHistory.length}件の思い出を振り返る',
                      backgroundColor: const Color(0xFFF4EAFB),
                      iconColor: const Color(0xFF9B72B9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecoveryAlbumScreen(
                              moodHistory: moodHistory,
                              lunaBond: lunaBond,
                              streakDays: streakDays,
                            ),
                          ),
                        );
                      },
                    ),

                    menuTile(
                      icon: Icons.calendar_month_rounded,
                      title: '気分カレンダー',
                      subtitle: '毎日の心の変化を見つめる',
                      backgroundColor: const Color(0xFFEAF4FA),
                      iconColor: const Color(0xFF6C9DB7),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MoodCalendarScreen(
                              moodHistory: moodHistory,
                            ),
                          ),
                        );
                      },
                    ),

                    menuTile(
                      icon: Icons.timeline_rounded,
                      title: 'わたし年表',
                      subtitle: '人生の出来事を少しずつ残す',
                      backgroundColor: const Color(0xFFFFF0F3),
                      iconColor: const Color(0xFFC77B91),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyTimelineScreen(),
                          ),
                        );
                      },
                    ),

                                        menuTile(
                      icon: Icons.wallpaper_rounded,
                      title: '背景ショップ',
                      subtitle: 'お気に入りの景色に着せ替える',
                      backgroundColor: const Color(0xFFFFF3E8),
                      iconColor: const Color(0xFFB88762),
                      onTap: () {
                        Navigator.push(
                          context,
                         MaterialPageRoute(
  builder: (_) => ChatBackgroundShopScreen(
    onBackgroundSelected: onChatBackgroundChanged,
    currentBackgroundPath: currentChatBackgroundPath,
  ),
),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

               

                    sectionTitle(
                      title: 'わたしとルナ',
                      subtitle: 'COCOONを自分らしい場所に',
                    ),

                   Row(
  children: [
    smallMenuTile(
      icon: Icons.person_rounded,
      title: 'あなたのこと',
      backgroundColor: const Color(0xFFF4EEFA),
      iconColor: const Color(0xFF9273AF),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(),
          ),
        );
      },
    ),
  ],
),

                    const SizedBox(height: 32),

                    sectionTitle(
                      title: '安心のために',
                      subtitle: '困ったときに頼れる場所を準備する',
                    ),

                    menuTile(
                      icon: Icons.contact_phone_rounded,
                      title: '緊急連絡先',
                      subtitle: '困ったときに連絡できる人を登録する',
                      backgroundColor: const Color(0xFFFFF0EA),
                      iconColor: const Color(0xFFC98265),
                     onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const EmergencyContactScreen(),
    ),
  );
},
),

                    menuTile(
                      icon: Icons.health_and_safety_rounded,
                      title: 'サポート・相談先',
                      subtitle: '相談できる場所や支援情報を確認する',
                      backgroundColor: const Color(0xFFECF5F2),
                      iconColor: const Color(0xFF6A9B8D),
                      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SupportContactScreen(),
    ),
  );
},
),
                    const SizedBox(height: 25),
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