import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadKtp({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('ktp').child('$uid-${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task = ref.putFile(file);
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }
}
