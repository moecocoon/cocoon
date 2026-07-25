import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/mood_record.dart';

class MoodCalendarScreen extends StatefulWidget {
  final List<MoodRecord> moodHistory;

  const MoodCalendarScreen({
    super.key,
    required this.moodHistory,
  });

  @override
  State<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends State<MoodCalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  Color moodColor(MoodRecord mood) {
    if (mood.emotionPercents.containsKey('😰 不安')) {
      return const Color(0xFFE8E1FF);
    } else if (mood.emotionPercents.containsKey('🌿 安心')) {
      return const Color(0xFFE4F6EA);
    } else if (mood.emotionPercents.containsKey('😴 疲れ')) {
      return const Color(0xFFEAF0FF);
    } else if (mood.emotionPercents.containsKey('😡 イライラ')) {
      return const Color(0xFFFFE0E0);
    } else if (mood.emotionPercents.containsKey('🫂 さみしい')) {
      return const Color(0xFFFFEEF5);
    } else {
      return Colors.white;
    }
  }

  List<MoodRecord> moodsForDay(DateTime day) {
    return widget.moodHistory.where((mood) {
      return mood.createdAt.year == day.year &&
          mood.createdAt.month == day.month &&
          mood.createdAt.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMoods = moodsForDay(selectedDay ?? focusedDay);

    final monthMoods = widget.moodHistory.where((mood) {
      return mood.createdAt.year == focusedDay.year &&
          mood.createdAt.month == focusedDay.month;
    }).toList();

    final weatherCounts = <String, int>{};

    for (final mood in monthMoods) {
      weatherCounts[mood.weather] =
          (weatherCounts[mood.weather] ?? 0) + 1;
    }

    final weatherSummary = weatherCounts.entries
        .map((entry) => '${entry.key} ${entry.value}日')
        .join('  ');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      appBar: AppBar(
        title: const Text('気分カレンダー'),
        backgroundColor: const Color(0xFF8E7BBE),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    '今月の心の天気',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F5F8F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weatherSummary.isEmpty
                        ? 'まだ記録がないよ🌙'
                        : weatherSummary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            TableCalendar<MoodRecord>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              eventLoader: moodsForDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;

                  final mood = events.first;

                  return Positioned(
                    bottom: 2,
                    child: Text(
                      mood.weather,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                },
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  selectedDay = selected;
                  focusedDay = focused;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFFB9A7E8),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF8E7BBE),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectedMoods.isEmpty
                  ? const Center(
                      child: Text('この日の記録はまだないよ🌙'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: selectedMoods.length,
                      itemBuilder: (context, index) {
                        final mood = selectedMoods[index];

                        return Card(
                          color: moodColor(mood),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              '${mood.createdAt.month}/${mood.createdAt.day}  ${mood.weather}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                ...mood.emotionPercents.entries.map(
                                  (entry) => Text(
                                    '${entry.key}：${entry.value.round()}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6F5F8F),
                                    ),
                                  ),
                                ),
                                if (mood.memo.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    mood.memo,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6D6478),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}