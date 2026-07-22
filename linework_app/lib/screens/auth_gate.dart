import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:linework_app/screens/login_screen.dart';
import 'package:linework_app/screens/loading_screen.dart';
import 'package:linework_app/screens/main_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen(message: 'Membuka akun...');
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return const MainShell();
      },
    );
  }
}
