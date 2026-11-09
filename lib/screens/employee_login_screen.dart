import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart' show MainScreen;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'employee_organization_screen.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() =>
      _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'メールアドレスとパスワードを入力してください。';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('ログイン情報を確認できませんでした。');
      }

      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse(
          'https://asia-northeast1-cocoon-688eb.cloudfunctions.net/getEmployeeMembershipStatus',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          errorMessage =
              '所属状況を確認できませんでした。時間をおいて再度ログインしてください。';
        });
        return;
      }

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as Map<String, dynamic>;

      final status = data['status'];

      if (status == 'active') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
        );
      } else if (status == 'none') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const EmployeeOrganizationScreen(),
          ),
        );
      } else {
        setState(() {
          errorMessage = status == 'pending'
              ? '現在、会社の承認待ちです。承認後に再度ログインしてください。'
              : '利用可能な所属を確認できませんでした。会社の管理者にお問い合わせください。';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = switch (error.code) {
          'invalid-email' =>
            'メールアドレスの形式を確認してください。',
          'invalid-credential' ||
          'wrong-password' ||
          'user-not-found' =>
            'メールアドレスまたはパスワードを確認してください。',
          _ => 'ログインできませんでした。',
        };
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = '通信エラーが発生しました。';
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FC),
      appBar: AppBar(
        title: const Text('COCOON 従業員ログイン'),
        backgroundColor: const Color(0xFFEDE2F6),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 52,
                      color: Color(0xFF9C7BB5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'COCOONへようこそ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF49365D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '会社との連携に進むため、ログインしてください。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'メールアドレス',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'パスワード',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            isLoading ? 'ログイン中...' : 'ログイン',
                          ),
                        ),
                      ),
                    ),
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