import 'package:flutter/material.dart';

import '../models/mood_record.dart';

class RecoveryAlbumScreen extends StatelessWidget {
  final List<MoodRecord> moodHistory;
  final int lunaBond;
  final int streakDays;

  const RecoveryAlbumScreen({
    super.key,
    required this.moodHistory,
    required this.lunaBond,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final records = moodHistory.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E7BBE),
        foregroundColor: Colors.white,
        title: const Text('回復アルバム'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '🐶 ルナより\n\n'
              'ここまでの記録は、あなたが歩いてきた大切な足あとだよ。\n\n'
              '連続記録：$streakDays日\n'
              'ルナとの絆：$lunaBond',
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF6D5D7A),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (records.isEmpty)
            const Text(
              'まだ記録がありません。\n'
              '気分記録をすると、ここに回復の足あとが残るよ🌱',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF6D5D7A),
              ),
            ),
          ...records.map((record) {
            final date =
                '${record.createdAt.year}/'
                '${record.createdAt.month}/'
                '${record.createdAt.day}';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E7BBE),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('天気：${record.weather}'),
                  const SizedBox(height: 8),
                  Text(
                    'メモ：'
                    '${record.memo.isEmpty ? "メモなし" : record.memo}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '感情：'
                    '${record.emotionPercents.entries.map((entry) {
                      return '${entry.key} '
                          '${entry.value.round()}%';
                    }).join(' / ')}',
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}