import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadKtp({
    required String uid,
    required File file,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('ktp').child(uid).child(fileName);
    final task = ref.putFile(file);
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  static Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage
        .ref()
        .child('profile_photos')
        .child(uid)
        .child(fileName);
    final task = ref.putFile(file);
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  static Future<String> uploadCv({
    required String uid,
    required File file,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('cv').child(uid).child(fileName);
    final task = ref.putFile(file);
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }
}
