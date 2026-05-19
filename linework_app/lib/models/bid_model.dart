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

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      providerId: json['providerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      message: json['message'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
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
