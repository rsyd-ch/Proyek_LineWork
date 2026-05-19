import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linework_app/services/firestore_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await FirestoreService.createUserProfile(user.uid, {
        'uid': user.uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'role': 'user',
      });
    }

    return credential;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
