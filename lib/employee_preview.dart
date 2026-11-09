import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/employee_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseを初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EmployeePreviewApp());
}

class EmployeePreviewApp extends StatelessWidget {
  const EmployeePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COCOON 会社連携プレビュー',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF9C7BB5),
      ),
      home: const EmployeeLoginScreen(),
    );
  }
}