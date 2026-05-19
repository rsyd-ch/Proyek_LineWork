import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:linework_app/screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LineWork',
      theme: ThemeData(
        primaryColor: const Color(0xFF1B3D6E),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        fontFamily: 'Inter',
      ),
      home: const AuthGate(),
    );
  }
}
