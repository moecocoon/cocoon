
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/admin_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminLoginScreen(),
    ),
  );
}

