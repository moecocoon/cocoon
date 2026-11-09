import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmployeeOrganizationScreen extends StatefulWidget {
  const EmployeeOrganizationScreen({super.key});

  @override
  State<EmployeeOrganizationScreen> createState() =>
      _EmployeeOrganizationScreenState();
}

class _EmployeeOrganizationScreenState
    extends State<EmployeeOrganizationScreen> {
  final organizationController = TextEditingController();

  // 所属申請に使用する氏名
final nameController = TextEditingController();

  bool isLoading = false;
  bool agreed = false;
  String? message;

  Future<void> requestMembership() async {
    if (isLoading) return;

    final organizationId = organizationController.text.trim();
final employeeName = nameController.text.trim();

    if (organizationId.isEmpty || !agreed) {
      setState(() {
        message = '会社IDの入力と確認事項への同意が必要です。';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('申請にはログインが必要です。');
      }

      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse(
          'https://asia-northeast1-cocoon-688eb.cloudfunctions.net/requestOrganizationMembership',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
  'organizationId': organizationId,
  'employeeName': employeeName,
}),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      setState(() {
        message = response.statusCode == 200
            ? '所属申請を送信しました。現在、承認待ちです。'
            : (data['error']?.toString() ?? '申請に失敗しました。');
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        message = '申請できませんでした。ログイン状態や通信環境を確認してください。';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    organizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FC),
      appBar: AppBar(
        title: const Text('会社との連携'),
        backgroundColor: const Color(0xFFEDE2F6),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.favorite_border,
                        size: 48,
                        color: Color(0xFF9C7BB5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'COCOONと会社をつなぐ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF49365D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '会社への所属を申請できます。\n'
                      '申請だけでは所属は確定しません。',
                    ),
                    const SizedBox(height: 24),
// 申請者の氏名
TextField(
  controller: nameController,
  textCapitalization: TextCapitalization.words,
  maxLength: 50,
  decoration: const InputDecoration(
    labelText: '氏名',
    hintText: '例：山田 太郎',
    prefixIcon: Icon(Icons.person_outline),
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 16),

                    TextField(
                      controller: organizationController,
                      decoration: const InputDecoration(
                        labelText: '会社ID',
                        hintText: '例：company_a',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: agreed,
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                agreed = value ?? false;
                              });
                            },
                      title: const Text(
                        '会社への所属申請に同意します。',
                      ),
                      subtitle: const Text(
  '申請すると、入力した氏名・会社ID・'
  'アカウント識別子・申請日時が保存されます。\n'
  '氏名と申請日時は、申請先企業の管理者に共有されます。\n'
  'ルナとのチャット内容や「わたし年表」は'
  '会社に共有されません。',
),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : requestMembership,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            isLoading ? '送信中...' : '所属を申請する',
                          ),
                        ),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(message!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}