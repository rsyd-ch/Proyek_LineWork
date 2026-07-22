import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final String? role;
  final String? nik;
  final String? ktpUrl;
  final String? phone;
  final String? photoUrl;
  final String? cvUrl;
  final String? contactMethod;
  final String? publicBio;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.role,
    this.nik,
    this.ktpUrl,
    this.phone,
    this.photoUrl,
    this.cvUrl,
    this.contactMethod,
    this.publicBio,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    return UserProfile(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      role: json['role'] as String?,
      nik: json['nik'] as String?,
      ktpUrl: json['ktpUrl'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      cvUrl: json['cvUrl'] as String?,
      contactMethod: json['contactMethod'] as String?,
      publicBio: json['publicBio'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: _readDate(json['createdAt']) ?? now,
      updatedAt: _readDate(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'nik': nik,
      'ktpUrl': ktpUrl,
      'phone': phone,
      'photoUrl': photoUrl,
      'cvUrl': cvUrl,
      'contactMethod': contactMethod,
      'publicBio': publicBio,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
