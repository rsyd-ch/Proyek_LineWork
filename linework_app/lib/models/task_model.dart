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
  final DateTime createdAt;
  final DateTime? dueAt;

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
    required this.createdAt,
    this.dueAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requesterId: json['requesterId'] as String,
      location: json['location'] as GeoPoint,
      price: (json['price'] as num).toDouble(),
      isCod: json['isCod'] as bool? ?? true,
      category: json['category'] as String,
      status: json['status'] as String? ?? 'open',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      dueAt: json['dueAt'] != null
          ? (json['dueAt'] as Timestamp).toDate()
          : null,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
    };
  }
}
