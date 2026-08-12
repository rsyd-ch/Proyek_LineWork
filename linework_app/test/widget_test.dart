// Blackbox-style widget tests for the login flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linework_app/screens/login_screen.dart';

void main() {
  group('LoginScreen blackbox tests', () {
    testWidgets('shows login UI and toggles to registration step',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Masuk ke LineWork'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar Akun Baru'), findsOneWidget);

      await tester.tap(find.text('Daftar Akun Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Daftar akun baru'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);

      final phoneField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);

      await tester.enterText(phoneField, '081234567890');
      await tester.enterText(passwordField, 'strongPass1');
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap'), findsOneWidget);
      expect(find.text('NIK'), findsOneWidget);
      expect(find.text('Bio publik'), findsOneWidget);
    });

    testWidgets('validates required login inputs before submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Nomor HP wajib diisi.'), findsOneWidget);
      expect(find.text('Password wajib diisi.'), findsOneWidget);
    });

    testWidgets('toggles password visibility icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
