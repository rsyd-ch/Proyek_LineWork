import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:linework_app/screens/login_screen.dart';
import 'package:linework_app/screens/main_shell.dart';
import 'package:linework_app/screens/profile_setup_screen.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/models/user_profile.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _needsProfileSetup(UserProfile? profile) {
    if (profile == null) return true;
    return profile.name == null || profile.nik == null || profile.ktpUrl == null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;
        return FutureBuilder<UserProfile?>(
          future: FirestoreService.getUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (_needsProfileSetup(profileSnapshot.data)) {
              return ProfileSetupScreen(
                uid: user.uid,
                email: user.email ?? '',
              );
            }

            return const MainShell();
          },
        );
      },
    );
  }
}
