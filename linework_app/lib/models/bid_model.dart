import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String id;
  final String taskId;
  final String providerId;
  final double amount;
  final String message;
  final String status;
  final DateTime createdAt;

  BidModel({
    required this.id,
    required this.taskId,
    required this.providerId,
    required this.amount,
    required this.message,
    this.status = 'pending',
    required this.createdAt,
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

  factory BidModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    return BidModel(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      providerId: json['providerId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: _readDate(json['createdAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'providerId': providerId,
      'amount': amount,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
