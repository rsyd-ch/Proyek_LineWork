import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linework_app/services/firestore_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static String normalizePhoneNumber(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    if (trimmed.startsWith('+')) {
      return '+${trimmed.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      return '+62${digits.substring(1)}';
    }
    if (digits.startsWith('62')) {
      return '+$digits';
    }
    return '+62$digits';
  }

  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException error) verificationFailed,
    void Function()? autoVerified,
    void Function(String verificationId)? timeout,
    int? forceResendingToken,
  }) async {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);

    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) async {
        final result = await _auth.signInWithCredential(credential);
        await _ensurePhoneUserProfile(result.user, normalizedPhone);
        autoVerified?.call();
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (verificationId) {
        timeout?.call(verificationId);
      },
    );
  }

  static Future<UserCredential> signInWithPhoneCode({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    final result = await _auth.signInWithCredential(credential);
    await _ensurePhoneUserProfile(
      result.user,
      normalizePhoneNumber(phoneNumber),
    );
    return result;
  }

  static Future<void> _ensurePhoneUserProfile(
    User? user,
    String phoneNumber,
  ) async {
    if (user == null) return;

    final existingProfile = await FirestoreService.getUserProfile(user.uid);
    await FirestoreService.createUserProfile(user.uid, {
      'uid': user.uid,
      'email': user.email ?? '',
      'phone': phoneNumber,
      'contactMethod': 'phone',
      'createdAt': existingProfile?.createdAt != null
          ? Timestamp.fromDate(existingProfile!.createdAt)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isVerified': existingProfile?.isVerified ?? false,
      'role': existingProfile?.role ?? 'user',
    });
  }

  static Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  static Future<UserCredential> signInWithPhonePassword(
    String phoneNumber,
    String password,
  ) async {
    final normalizedEmail = _phoneLoginEmail(phoneNumber);
    return await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  static String _phoneLoginEmail(String phoneNumber) {
    final digits = phoneNumber.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final localNumber = digits.startsWith('62')
        ? '0${digits.substring(2)}'
        : digits;
    return '$localNumber@linework.local';
  }

  static Future<UserCredential> register(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      try {
        await FirestoreService.createUserProfile(user.uid, {
          'uid': user.uid,
          'email': normalizedEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isVerified': false,
          'role': 'user',
        }).timeout(const Duration(seconds: 8));
      } on FirebaseException {
        // Auth account is already created. The profile setup screen can retry
        // writing the user document, so do not keep the user stuck here.
      } on TimeoutException {
        // Same as above: continue to profile setup and let the next step retry.
      }
    }

    return credential;
  }

  static Future<UserCredential> registerWithContact({
    required String contact,
    required bool isEmail,
    required String password,
    required String name,
    required String phone,
    required String nik,
    required String publicBio,
  }) async {
    final normalizedContact = contact.trim().toLowerCase();
    final normalizedEmail = isEmail
        ? normalizedContact
        : _phoneLoginEmail(normalizedContact);
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      try {
        await FirestoreService.createUserProfile(user.uid, {
          'uid': user.uid,
          'email': isEmail ? normalizedEmail : '',
          'phone': phone.trim(),
          'name': name.trim(),
          'nik': nik.trim(),
          'publicBio': publicBio.trim(),
          'contactMethod': isEmail ? 'email' : 'whatsapp',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isVerified': false,
        }).timeout(const Duration(seconds: 8));
      } on FirebaseException {
        // Continue to profile setup; the next step can retry profile writing.
      } on TimeoutException {
        // Same as above.
      }
    }

    return credential;
  }

  static String errorMessage(Object error, {required bool isRegistering}) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Format email belum benar.';
        case 'email-already-in-use':
          return 'Email ini sudah terdaftar. Coba masuk dengan email tersebut.';
        case 'weak-password':
          return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
        case 'operation-not-allowed':
          return 'Metode login ini belum aktif di Firebase Authentication.';
        case 'invalid-phone-number':
          return 'Format nomor HP belum benar. Gunakan contoh 081234567890.';
        case 'invalid-verification-code':
        case 'invalid-verification-id':
          return 'Kode OTP salah atau sudah kedaluwarsa.';
        case 'session-expired':
          return 'Sesi OTP sudah kedaluwarsa. Kirim ulang kode.';
        case 'quota-exceeded':
          return 'Kuota SMS Firebase sedang habis. Coba lagi nanti.';
        case 'captcha-check-failed':
        case 'app-not-authorized':
          return 'Aplikasi belum diizinkan untuk Phone Auth. Periksa SHA-1/SHA-256 di Firebase.';
        case 'user-disabled':
          return 'Akun ini dinonaktifkan.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email atau password salah.';
        case 'network-request-failed':
          return 'Tidak bisa terhubung ke Firebase. Periksa koneksi internet.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
      }
    }

    return isRegistering
        ? 'Registrasi gagal. Coba lagi beberapa saat.'
        : 'Login gagal. Periksa email dan password.';
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }
}
