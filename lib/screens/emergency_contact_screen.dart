import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_contact.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() =>
      _EmergencyContactScreenState();
}

class _EmergencyContactScreenState
    extends State<EmergencyContactScreen> {
  final List<EmergencyContact> contacts = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedContacts = prefs.getString('emergencyContacts');

      if (savedContacts != null && savedContacts.isNotEmpty) {
        final List<dynamic> decodedContacts =
            jsonDecode(savedContacts);

        final loadedContacts = decodedContacts.map((item) {
          return EmergencyContact.fromJson(
            Map<String, dynamic>.from(item),
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          contacts
            ..clear()
            ..addAll(loadedContacts);
        });
      }
    } catch (error) {
      debugPrint('緊急連絡先の読み込みエラー: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveContacts() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedContacts = jsonEncode(
      contacts.map((contact) => contact.toJson()).toList(),
    );

    await prefs.setString(
      'emergencyContacts',
      encodedContacts,
    );
  }

  InputDecoration inputDecoration({
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
      fillColor: const Color(0xFFF7F1FA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF8E7BBE),
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> openContactForm({
    EmergencyContact? existingContact,
    int? editIndex,
  }) async {
    final nameController = TextEditingController(
      text: existingContact?.name ?? '',
    );

    final relationshipController = TextEditingController(
      text: existingContact?.relationship ?? '',
    );

    final phoneController = TextEditingController(
      text: existingContact?.phoneNumber ?? '',
    );

    final isEditing =
        existingContact != null && editIndex != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              22,
              14,
              22,
              26,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBFF),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9CFDE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECE6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.contact_phone_rounded,
                          color: Color(0xFFC98265),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          isEditing
                              ? '緊急連絡先を編集'
                              : '緊急連絡先を追加',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF655472),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: inputDecoration(
                      label: '名前',
                      hint: '例：お母さん',
                      icon: Icons.person_rounded,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: relationshipController,
                    textInputAction: TextInputAction.next,
                    decoration: inputDecoration(
                      label: 'あなたとの関係',
                      hint: '例：家族、友人、恋人',
                      icon: Icons.people_alt_rounded,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: inputDecoration(
                      label: '電話番号',
                      hint: '例：09012345678',
                      icon: Icons.phone_rounded,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                const Color(0xFF817387),
                            side: const BorderSide(
                              color: Color(0xFFD8CDDE),
                            ),
                            padding: const EdgeInsets.symmetric(
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            final name =
                                nameController.text.trim();
                            final relationship =
                                relationshipController.text.trim();
                            final phoneNumber =
                                phoneController.text.trim();

                            if (name.isEmpty ||
                                phoneNumber.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '名前と電話番号を入力してね',
                                  ),
                                ),
                              );
                              return;
                            }

                            final contact = EmergencyContact(
                              name: name,
                              relationship:
                                  relationship.isEmpty
                                      ? '関係未登録'
                                      : relationship,
                              phoneNumber: phoneNumber,
                            );

                            setState(() {
                              if (isEditing) {
                                contacts[editIndex] = contact;
                              } else {
                                contacts.add(contact);
                              }
                            });

                            await saveContacts();

                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                          },
                          child: Text(
                            isEditing ? '保存する' : '追加する',
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

    nameController.dispose();
    relationshipController.dispose();
    phoneController.dispose();
  }

Future<void> callContact(EmergencyContact contact) async {
  final phoneUri = Uri(
    scheme: 'tel',
    path: contact.phoneNumber,
  );

  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('電話をかけられませんでした'),
      ),
    );
  }
}

  Future<void> deleteContact(int index) async {
    final contact = contacts[index];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFBFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            '連絡先を削除しますか？',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF655472),
            ),
          ),
          content: Text(
            '${contact.name}さんの連絡先を削除します。',
            style: const TextStyle(
              color: Color(0xFF817387),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'キャンセル',
                style: TextStyle(
                  color: Color(0xFF817387),
                ),
              ),
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
      contacts.removeAt(index);
    });

    await saveContacts();
  }

  Widget contactCard({
    required EmergencyContact contact,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3ED),
            Color(0xFFF7ECF9),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E7BBE).withOpacity(0.09),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFC98265),
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F526D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.relationship,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A7D92),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.phoneNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6D6478),
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
                    openContactForm(
                      existingContact: contact,
                      editIndex: index,
                    );
                  }

                  if (value == 'delete') {
                    deleteContact(index);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: Color(0xFF8E7BBE),
                          ),
                          SizedBox(width: 10),
                          Text('編集'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
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

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC98265),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
             onPressed: () {
  callContact(contact);
},
              icon: const Icon(Icons.phone_rounded),
              label: const Text(
                '電話する',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyContacts() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFF0E7F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contact_phone_rounded,
                size: 42,
                color: Color(0xFF9A82B1),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'まだ連絡先が登録されていません',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF655472),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '困ったときに頼れる人を\n登録しておこう',
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
          '緊急連絡先',
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
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.health_and_safety_rounded,
                      color: Color(0xFFC98265),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '困ったときに連絡できる人を登録できます。'
                        '本人の操作なしに電話や情報送信が行われることはありません。',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF746678),
                        ),
                      ),
                    ),
                  ],
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
                    : contacts.isEmpty
                        ? emptyContacts()
                        : ListView.builder(
                            physics:
                                const BouncingScrollPhysics(),
                            itemCount: contacts.length,
                            itemBuilder: (context, index) {
                              return contactCard(
                                contact: contacts[index],
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
                    openContactForm();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    '緊急連絡先を追加',
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