import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String requesterId;
  final GeoPoint location;
  final double price;
  final bool isCod;
  final String category;
  final String status;
  final String? acceptedBidId;
  final String? acceptedProviderId;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.requesterId,
    required this.location,
    required this.price,
    this.isCod = true,
    required this.category,
    this.status = 'open',
    this.acceptedBidId,
    this.acceptedProviderId,
    required this.createdAt,
    this.dueAt,
    this.acceptedAt,
    this.completedAt,
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

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    return TaskModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Pekerjaan tanpa judul',
      description: json['description'] as String? ?? '',
      requesterId: json['requesterId'] as String? ?? '',
      location: json['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isCod: json['isCod'] as bool? ?? true,
      category: json['category'] as String? ?? 'Lainnya',
      status: json['status'] as String? ?? 'open',
      acceptedBidId: json['acceptedBidId'] as String?,
      acceptedProviderId: json['acceptedProviderId'] as String?,
      createdAt: _readDate(json['createdAt']) ?? now,
      dueAt: _readDate(json['dueAt']),
      acceptedAt: _readDate(json['acceptedAt']),
      completedAt: _readDate(json['completedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requesterId': requesterId,
      'location': location,
      'price': price,
      'isCod': isCod,
      'category': category,
      'status': status,
      'acceptedBidId': acceptedBidId,
      'acceptedProviderId': acceptedProviderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }
}
