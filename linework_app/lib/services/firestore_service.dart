import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linework_app/models/bid_model.dart';
import 'package:linework_app/models/rating_model.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/models/user_profile.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get usersRef =>
      _db.collection('users');
  static CollectionReference<Map<String, dynamic>> get tasksRef =>
      _db.collection('tasks');
  static CollectionReference<Map<String, dynamic>> get bidsRef =>
      _db.collection('bids');
  static CollectionReference<Map<String, dynamic>> get ratingsRef =>
      _db.collection('ratings');

  static Future<void> createUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await usersRef.doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await usersRef.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserProfile.fromJson(snapshot.data()!);
  }

  static Future<void> createTask(TaskModel task) async {
    await tasksRef.doc(task.id).set(task.toJson());
  }

  static Future<void> createBid(BidModel bid) async {
    await bidsRef.doc(bid.id).set(bid.toJson());
  }

  static Future<void> createRating(RatingModel rating) async {
    await ratingsRef.doc(rating.id).set(rating.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamTasks() {
    return tasksRef.snapshots();
  }

  static Stream<List<TaskModel>> streamTasksFiltered({
    String? category,
    String? status,
  }) {
    Query query = tasksRef.where('status', isEqualTo: status ?? 'open');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return (query as Query<Map<String, dynamic>>)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
    });
  }

  static Future<TaskModel?> getTask(String taskId) async {
    final snapshot = await tasksRef.doc(taskId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return TaskModel.fromJson(snapshot.data()!);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamBids(String taskId) {
    return bidsRef.where('taskId', isEqualTo: taskId).snapshots();
  }

  static Stream<List<BidModel>> streamBidsForTask(String taskId) {
    return bidsRef
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BidModel.fromJson(doc.data())).toList();
    });
  }
}
