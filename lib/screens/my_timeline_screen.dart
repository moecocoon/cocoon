import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimelineEvent {
  final String yearMonth;
  final String title;
  final String pastFeeling;
  final String currentReflection;
  final List<String> tags;
  final String emotion;
  final int impact;

  const TimelineEvent({
    required this.yearMonth,
    required this.title,
    required this.pastFeeling,
    required this.currentReflection,
    required this.tags,
    required this.emotion,
    required this.impact,
  });

  Map<String, dynamic> toJson() {
    return {
      'yearMonth': yearMonth,
      'title': title,
      'pastFeeling': pastFeeling,
      'currentReflection': currentReflection,
      'tags': tags,
      'emotion': emotion,
      'impact': impact,
    };
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      yearMonth: json['yearMonth'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pastFeeling: json['pastFeeling'] as String? ?? '',
      currentReflection:
          json['currentReflection'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      emotion: json['emotion'] as String? ?? '😌',
      impact: json['impact'] as int? ?? 3,
    );
  }
}

class MyTimelineScreen extends StatefulWidget {
  const MyTimelineScreen({super.key});

  @override
  State<MyTimelineScreen> createState() =>
      _MyTimelineScreenState();
}

class _MyTimelineScreenState extends State<MyTimelineScreen> {
  static const String storageKey = 'myTimelineEvents';

  final List<TimelineEvent> events = [];

  final List<String> tagOptions = [
    '🌱 成長',
    '❤️ 人との出会い',
    '💔 別れ',
    '🏠 家族',
    '🎓 学校',
    '💼 仕事',
    '🏥 健康',
    '✨ 挑戦',
    '🌧️ 辛かった',
    '🌸 嬉しかった',
  ];

  final List<String> emotionOptions = [
    '😊',
    '😌',
    '🥹',
    '😰',
    '😢',
    '😡',
    '🫂',
  ];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);

      if (saved != null && saved.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(saved);

        final loadedEvents = decoded.map((item) {
          return TimelineEvent.fromJson(
            Map<String, dynamic>.from(item),
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          events
            ..clear()
            ..addAll(loadedEvents);
        });
      }
    } catch (error) {
      debugPrint('わたし年表の読み込みエラー: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      events.map((event) => event.toJson()).toList(),
    );

    await prefs.setString(storageKey, encoded);
  }

  InputDecoration fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF8E7BBE),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F3FA),
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(
          color: Color(0xFF8E7BBE),
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> openEventForm({
    TimelineEvent? existingEvent,
    int? editIndex,
  }) async {
    final yearMonthController = TextEditingController(
      text: existingEvent?.yearMonth ?? '',
    );

    final titleController = TextEditingController(
      text: existingEvent?.title ?? '',
    );

    final pastFeelingController = TextEditingController(
      text: existingEvent?.pastFeeling ?? '',
    );

    final currentReflectionController = TextEditingController(
      text: existingEvent?.currentReflection ?? '',
    );

    final selectedTags = <String>{
      ...?existingEvent?.tags,
    };

    String selectedEmotion =
        existingEvent?.emotion ?? '😌';

    double impact =
        (existingEvent?.impact ?? 3).toDouble();

    final isEditing =
        existingEvent != null && editIndex != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(sheetContext).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBFF),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8CDDE),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        isEditing
                            ? '出来事を編集'
                            : '出来事を追加',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF655472),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'あなたの歩いてきた時間を、少しずつ残していこう。',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF897C94),
                        ),
                      ),

                      const SizedBox(height: 22),

                      TextField(
                        controller: yearMonthController,
                        textInputAction: TextInputAction.next,
                        decoration: fieldDecoration(
                          label: '年月',
                          hint: '例：2026年7月',
                          icon: Icons.calendar_month_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        decoration: fieldDecoration(
                          label: '出来事',
                          hint: '例：COCOONを作り始めた',
                          icon: Icons.auto_stories_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: pastFeelingController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: fieldDecoration(
                          label: 'その当時、どう思っていた？',
                          hint: 'そのとき感じていたことを書いてね',
                          icon: Icons.history_rounded,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller:
                            currentReflectionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: fieldDecoration(
                          label: '今振り返ると、どう思う？',
                          hint: '今の自分から見た気持ちを書いてね',
                          icon: Icons.lightbulb_rounded,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'この出来事に近いもの',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF655472),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tagOptions.map((tag) {
                          final selected =
                              selectedTags.contains(tag);

                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            selectedColor:
                                const Color(0xFFE6D8F0),
                            backgroundColor:
                                const Color(0xFFF5EFF7),
                            checkmarkColor:
                                const Color(0xFF765D8D),
                            side: BorderSide.none,
                            onSelected: (value) {
                              setModalState(() {
                                if (value) {
                                  selectedTags.add(tag);
                                } else {
                                  selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'そのときの気持ち',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF655472),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children:
                            emotionOptions.map((emotion) {
                          final selected =
                              selectedEmotion == emotion;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedEmotion = emotion;
                              });
                            },
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 180),
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFE7D9F2)
                                    : const Color(0xFFF5EFF7),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: const Color(
                                          0xFF8E7BBE,
                                        ),
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Text(
                                emotion,
                                style:
                                    const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '人生への影響度',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF655472),
                              ),
                            ),
                          ),
                          Text(
                            '${impact.round()} / 5',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8E7BBE),
                            ),
                          ),
                        ],
                      ),

                      Slider(
                        value: impact,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: const Color(0xFF8E7BBE),
                        label: impact.round().toString(),
                        onChanged: (value) {
                          setModalState(() {
                            impact = value;
                          });
                        },
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '小さな出来事',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF998DA1),
                            ),
                          ),
                          Text(
                            '大きな転機',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF998DA1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style:
                                  OutlinedButton.styleFrom(
                                foregroundColor:
                                    const Color(0xFF817387),
                                side: const BorderSide(
                                  color: Color(0xFFD8CDDE),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                              },
                              child: const Text('キャンセル'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF8E7BBE),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () async {
                                final yearMonth =
                                    yearMonthController.text.trim();

                                final title =
                                    titleController.text.trim();

                                if (yearMonth.isEmpty ||
                                    title.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '年月と出来事を入力してね',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final newEvent = TimelineEvent(
                                  yearMonth: yearMonth,
                                  title: title,
                                  pastFeeling:
                                      pastFeelingController.text
                                          .trim(),
                                  currentReflection:
                                      currentReflectionController
                                          .text
                                          .trim(),
                                  tags: selectedTags.toList(),
                                  emotion: selectedEmotion,
                                  impact: impact.round(),
                                );

                                setState(() {
                                  if (isEditing) {
                                    events[editIndex!] =
                                        newEvent;
                                  } else {
                                    events.insert(0, newEvent);
                                  }
                                });

                                await saveEvents();

                                if (!sheetContext.mounted) {
                                  return;
                                }

                                Navigator.pop(sheetContext);
                              },
                              child: Text(
                                isEditing
                                    ? '保存する'
                                    : '追加する',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    yearMonthController.dispose();
    titleController.dispose();
    pastFeelingController.dispose();
    currentReflectionController.dispose();
  }

  Future<void> deleteEvent(int index) async {
    final event = events[index];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFBFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            '出来事を削除しますか？',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF655472),
            ),
          ),
          content: Text(
            '「${event.title}」を年表から削除します。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                '削除する',
                style: TextStyle(
                  color: Color(0xFFC96868),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      events.removeAt(index);
    });

    await saveEvents();
  }

  Widget eventCard({
    required TimelineEvent event,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3E9FA),
            Color(0xFFFFF1F5),
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E7BBE)
                .withOpacity(0.09),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                event.emotion,
                style: const TextStyle(fontSize: 29),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.yearMonth,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF967BA5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F526D),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF8E7BBE),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    openEventForm(
                      existingEvent: event,
                      editIndex: index,
                    );
                  }

                  if (value == 'delete') {
                    deleteEvent(index);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded),
                          SizedBox(width: 10),
                          Text('編集'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFC96868),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '削除',
                            style: TextStyle(
                              color: Color(0xFFC96868),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),

          if (event.pastFeeling.isNotEmpty) ...[
            const SizedBox(height: 17),
            const Text(
              'その当時',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B7FAA),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              event.pastFeeling,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF6D6478),
              ),
            ),
          ],

          if (event.currentReflection.isNotEmpty) ...[
            const SizedBox(height: 15),
            const Text(
              '今振り返ると',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC27E91),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              event.currentReflection,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF6D6478),
              ),
            ),
          ],

          if (event.tags.isNotEmpty) ...[
            const SizedBox(height: 15),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: event.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.68),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF766A7F),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 15),

          Row(
            children: [
              const Text(
                '人生への影響',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A7D92),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '★' * event.impact,
                style: const TextStyle(
                  color: Color(0xFFC38A62),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget emptyTimeline() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE3F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 43,
                color: Color(0xFF9A82B1),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'まだ出来事がありません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF655472),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'あなたの歩いてきた時間を\n少しずつ残してみよう',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF8A7D92),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F3FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'わたし年表',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF655472),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF1E7FA),
                      Color(0xFFFFEEF4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Text(
                  '出来事だけでなく、そのときの気持ちと、'
                  '今の自分から見た思いも残せます。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF746678),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8E7BBE),
                        ),
                      )
                    : events.isEmpty
                        ? emptyTimeline()
                        : ListView.builder(
                            physics:
                                const BouncingScrollPhysics(),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              return eventCard(
                                event: events[index],
                                index: index,
                              );
                            },
                          ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF8E7BBE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: () {
                    openEventForm();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    '出来事を追加',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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