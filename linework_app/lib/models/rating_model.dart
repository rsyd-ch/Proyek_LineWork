import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String taskId;
  final int stars;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.taskId,
    required this.stars,
    required this.comment,
    required this.tags,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      taskId: json['taskId'] as String,
      stars: json['stars'] as int,
      comment: json['comment'] as String,
      tags: List<String>.from(json['tags'] as List<dynamic>),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'taskId': taskId,
      'stars': stars,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
