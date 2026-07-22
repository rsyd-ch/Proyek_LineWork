# LineWork

LineWork adalah aplikasi Flutter untuk mempertemukan pengguna yang membutuhkan bantuan pekerjaan ringan dengan penyedia bantuan di area sekitar. MVP saat ini berfokus pada alur posting pekerjaan, penawaran, penerimaan bid, status pekerjaan, profil pengguna, rating, lokasi, dan integrasi Firebase.

## Status Saat Ini

- Flutter analyze: lulus tanpa issue.
- Flutter test: semua test model lulus.
- Android debug build: berhasil membuat `build/app/outputs/flutter-apk/app-debug.apk`.
- Firebase project default: `linework-a7dbc`.

## Fitur MVP

- Autentikasi email/password dengan Firebase Authentication.
- Registrasi menggunakan email atau kontak WhatsApp yang dipetakan ke akun lokal.
- Setup profil pengguna dan unggah berkas KTP ke Firebase Storage.
- Listing pekerjaan berdasarkan kategori dan status.
- Posting pekerjaan dengan lokasi, harga, kategori, metode pembayaran, dan batas waktu.
- Detail pekerjaan, pengajuan bid, penerimaan bid, dan penolakan bid lain.
- Status pekerjaan untuk requester/provider.
- Rating setelah pekerjaan selesai.
- Mode terang/gelap melalui pengaturan aplikasi.

## Struktur Penting

- `lib/main.dart`: entry point aplikasi dan inisialisasi Firebase.
- `lib/models/`: model data Firestore.
- `lib/screens/`: layar utama aplikasi.
- `lib/services/`: service untuk auth, Firestore, storage, lokasi, dan pengaturan.
- `firestore.rules`: rules Cloud Firestore.
- `storage.rules`: rules Firebase Storage.
- `test/models_test.dart`: test serialisasi model.

## Prasyarat

- Flutter SDK 3.35.x atau kompatibel dengan Dart SDK `^3.9.2`.
- Android Studio/JDK untuk build Android.
- Firebase project dengan Authentication, Cloud Firestore, dan Storage aktif.
- File `android/app/google-services.json` sudah tersedia untuk project Firebase.

## Menjalankan Proyek

```bash
flutter pub get
flutter run
```

Untuk menjalankan di emulator/perangkat tertentu:

```bash
flutter devices
flutter run -d <device-id>
```

## Pemeriksaan Kualitas

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Firebase Rules

Deploy rules dari folder `linework_app`:

```bash
firebase deploy --only firestore:rules,storage
```

Ringkasan rules saat ini:

- `users`: hanya pemilik akun yang bisa membuat, membaca, dan memperbarui profilnya.
- `publicProfiles`: publik bisa membaca nama, foto, bio, CV, dan status verifikasi tanpa data sensitif.
- `tasks`: publik bisa membaca; user login bisa membuat task untuk dirinya; requester bisa update/delete task.
- `bids`: user login bisa membaca; provider membuat bid miliknya; pemilik task bisa update bid; provider bisa delete bid miliknya.
- `ratings`: publik bisa membaca; user login bisa membuat rating atas nama dirinya.
- `storage/ktp/{userId}`: hanya user terkait yang bisa membaca, menulis, dan menghapus file KTP miliknya.
- `storage/profile_photos/{userId}` dan `storage/cv/{userId}`: publik bisa membaca, user terkait bisa mengunggah dan menghapus file miliknya.

## Langkah Lanjut yang Disarankan

1. Commit baseline yang sudah lulus analyze, test, dan build.
2. Uji manual alur lengkap: register/login, setup profil, posting task, bid, accept bid, complete, rating.
3. Tambah test untuk transisi status task/bid dan validasi data profil.
4. Pertimbangkan indeks Firestore jika query production mulai memakai kombinasi filter/order.
5. Siapkan dokumentasi demo dan screenshot untuk presentasi MVP.
