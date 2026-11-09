import 'admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();


bool isLoading = false;

Future<void> login() async {
  if (isLoading) return;

  final email = emailController.text.trim();
  final password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('メールアドレスとパスワードを入力してください。'),
      ),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
   
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Firebaseから最新の管理者権限を取得
final token = await credential.user!.getIdTokenResult(true);
final isAdmin = token.claims?['admin'] == true;

// 管理者でない場合はログアウト
if (!isAdmin) {
  await FirebaseAuth.instance.signOut();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('管理者権限がありません。'),
    ),
  );
  return;
}


if (!mounted) return;

Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => const AdminDashboardScreen(),
  ),
);


  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    final message = switch (e.code) {
      'invalid-email' => 'メールアドレスの形式を確認してください。',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'メールアドレスまたはパスワードを確認してください。',
      'too-many-requests' => '時間をおいてから再度お試しください。',
      _ => 'ログインできませんでした。もう一度お試しください。',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('通信エラーが発生しました。'),
      ),
    );
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 64,
                      color: Color(0xFF9C7BB5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'COCOON',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF49365D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('企業管理者ログイン'),
                    const SizedBox(height: 28),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'メールアドレス',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'パスワード',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => login(),
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('ログイン'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '※ 現在は画面デザインの確認用です。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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

