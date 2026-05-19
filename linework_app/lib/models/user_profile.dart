import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final String? role;
  final String? nik;
  final String? ktpUrl;
  final String? phone;
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
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: json['role'] as String?,
      nik: json['nik'] as String?,
      ktpUrl: json['ktpUrl'] as String?,
      phone: json['phone'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
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
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
