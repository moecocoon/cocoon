import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/support_contact.dart';

class SupportContactScreen extends StatefulWidget {
  const SupportContactScreen({super.key});

  @override
  State<SupportContactScreen> createState() =>
      _SupportContactScreenState();
}

class _SupportContactScreenState
    extends State<SupportContactScreen> {
  static const String storageKey = 'supportContacts';

  final List<SupportContact> contacts = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);

      if (saved != null && saved.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(saved);

        final loadedContacts = decoded.map((item) {
          return SupportContact.fromJson(
            Map<String, dynamic>.from(item as Map),
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
      debugPrint('相談先の読み込みエラー: $error');
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

    final encoded = jsonEncode(
      contacts.map((contact) => contact.toJson()).toList(),
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
      alignLabelWithHint: true,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6A9B8D),
      ),
      filled: true,
      fillColor: const Color(0xFFF2F7F5),
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
          color: Color(0xFF6A9B8D),
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> openContactForm({
    SupportContact? existingContact,
    int? editIndex,
  }) async {
    final nameController = TextEditingController(
      text: existingContact?.name ?? '',
    );

    final categoryController = TextEditingController(
      text: existingContact?.category ?? '',
    );

    final phoneController = TextEditingController(
      text: existingContact?.phoneNumber ?? '',
    );

    final urlController = TextEditingController(
      text: existingContact?.url ?? '',
    );

    final memoController = TextEditingController(
      text: existingContact?.memo ?? '',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8CDDE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    isEditing ? '相談先を編集' : '相談先を追加',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF655472),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    '病院や学校、職場など、頼れる相談先を登録できます。',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF817387),
                    ),
                  ),

                  const SizedBox(height: 22),

                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      label: '相談先の名前',
                      hint: '例：〇〇メンタルクリニック',
                      icon: Icons.business_rounded,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: categoryController,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      label: '種類',
                      hint: '例：病院、学校、職場、公的窓口',
                      icon: Icons.category_rounded,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      label: '電話番号',
                      hint: '例：0312345678',
                      icon: Icons.phone_rounded,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration(
                      label: 'Webサイト',
                      hint: '例：https://example.com',
                      icon: Icons.language_rounded,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: memoController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: fieldDecoration(
                      label: 'メモ',
                      hint: '受付時間や担当者など',
                      icon: Icons.notes_rounded,
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
                                const Color(0xFF6A9B8D),
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

                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '相談先の名前を入力してね',
                                  ),
                                ),
                              );
                              return;
                            }

                            final newContact = SupportContact(
                              name: name,
                              category:
                                  categoryController.text.trim(),
                              phoneNumber:
                                  phoneController.text.trim(),
                              url: urlController.text.trim(),
                              memo: memoController.text.trim(),
                            );

                            setState(() {
                              if (isEditing) {
                                contacts[editIndex] = newContact;
                              } else {
                                contacts.add(newContact);
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
    categoryController.dispose();
    phoneController.dispose();
    urlController.dispose();
    memoController.dispose();
  }

  Future<void> callContact(String phoneNumber) async {
    final cleanedPhoneNumber = phoneNumber.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (cleanedPhoneNumber.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('電話番号が登録されていません'),
        ),
      );
      return;
    }

    final phoneUri = Uri(
      scheme: 'tel',
      path: cleanedPhoneNumber,
    );

    try {
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('電話アプリを開けませんでした'),
          ),
        );
      }
    } catch (error) {
      debugPrint('電話アプリの起動エラー: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('電話アプリを開けませんでした'),
        ),
      );
    }
  }

  Future<void> openWebsite(String url) async {
    final trimmedUrl = url.trim();

    if (trimmedUrl.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Webサイトが登録されていません'),
        ),
      );
      return;
    }

    final normalizedUrl =
        trimmedUrl.startsWith('http://') ||
                trimmedUrl.startsWith('https://')
            ? trimmedUrl
            : 'https://$trimmedUrl';

    final uri = Uri.tryParse(normalizedUrl);

    if (uri == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Webサイトの形式を確認してね'),
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Webサイトを開けませんでした'),
          ),
        );
      }
    } catch (error) {
      debugPrint('Webサイトの起動エラー: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Webサイトを開けませんでした'),
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
            '相談先を削除しますか？',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF655472),
            ),
          ),
          content: Text(
            '「${contact.name}」を削除します。',
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
      contacts.removeAt(index);
    });

    await saveContacts();
  }

  Widget contactCard({
    required SupportContact contact,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFECF5F2),
            Color(0xFFF5EEF8),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A9B8D).withOpacity(0.09),
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
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Color(0xFF6A9B8D),
                  size: 28,
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
                    if (contact.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        contact.category,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6A9B8D),
                        ),
                      ),
                    ],
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
                  } else if (value == 'delete') {
                    deleteContact(index);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded),
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

          if (contact.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              contact.phoneNumber,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6D6478),
              ),
            ),
          ],

          if (contact.memo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              contact.memo,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF817387),
              ),
            ),
          ],

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF6A9B8D),
                    side: const BorderSide(
                      color: Color(0xFFB8D4CC),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  onPressed: () {
                    callContact(contact.phoneNumber);
                  },
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('電話する'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6A9B8D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  onPressed: () {
                    openWebsite(contact.url);
                  },
                  icon: const Icon(Icons.language_rounded),
                  label: const Text('サイト'),
                ),
              ),
            ],
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
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F0EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                size: 43,
                color: Color(0xFF6A9B8D),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'まだ相談先が登録されていません',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF655472),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '病院や学校、職場などの\n相談先を登録しておこう',
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
          'サポート・相談先',
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
                  color: const Color(0xFFECF5F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  '普段利用している病院や学校、職場、'
                  '支援機関などを登録できます。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF667A74),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6A9B8D),
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
                        const Color(0xFF6A9B8D),
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
                    '相談先を追加',
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