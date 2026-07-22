import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:linework_app/screens/auth_gate.dart';
import 'package:linework_app/screens/loading_screen.dart';
import 'package:linework_app/services/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(MainApp(firebaseInitialization: Firebase.initializeApp()));
}

class MainApp extends StatelessWidget {
  final Future<FirebaseApp> firebaseInitialization;

  const MainApp({required this.firebaseInitialization, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'LineWork',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            primaryColor: const Color(0xFF1B3D6E),
            scaffoldBackgroundColor: const Color(0xFFF4F7FB),
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B4778),
              primary: const Color(0xFF0B4778),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF38BDF8),
            scaffoldBackgroundColor: const Color(0xFF081421),
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF38BDF8),
              primary: const Color(0xFF38BDF8),
              surface: const Color(0xFF0F2233),
            ),
          ),
          home: FutureBuilder<FirebaseApp>(
            future: firebaseInitialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _StartupErrorScreen(error: snapshot.error);
              }

              if (snapshot.connectionState == ConnectionState.done) {
                return const AuthGate();
              }

              return const LoadingScreen();
            },
          ),
        );
      },
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final Object? error;

  const _StartupErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 108,
                  height: 108,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),
                const Text(
                  'LineWork belum bisa dibuka',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
