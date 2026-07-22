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
  static CollectionReference<Map<String, dynamic>> get publicProfilesRef =>
      _db.collection('publicProfiles');
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
    final publicData = _publicProfileData(uid, data);
    final batch = _db.batch();

    batch.set(usersRef.doc(uid), data, SetOptions(merge: true));
    batch.set(publicProfilesRef.doc(uid), publicData, SetOptions(merge: true));

    await batch.commit();
  }

  static Map<String, dynamic> _publicProfileData(
    String uid,
    Map<String, dynamic> data,
  ) {
    return {
      'uid': uid,
      if (data.containsKey('name')) 'name': data['name'],
      if (data.containsKey('photoUrl')) 'photoUrl': data['photoUrl'],
      if (data.containsKey('cvUrl')) 'cvUrl': data['cvUrl'],
      if (data.containsKey('publicBio')) 'publicBio': data['publicBio'],
      if (data.containsKey('isVerified')) 'isVerified': data['isVerified'],
      'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
    };
  }

  static Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await usersRef.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserProfile.fromJson(snapshot.data()!);
  }

  static Future<UserProfile?> getPublicUserProfile(String uid) async {
    final snapshot = await publicProfilesRef.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserProfile.fromJson({...snapshot.data()!, 'uid': snapshot.id});
  }

  static Stream<UserProfile?> streamPublicUserProfile(String uid) {
    return publicProfilesRef.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return UserProfile.fromJson({...data, 'uid': data['uid'] ?? snapshot.id});
    });
  }

  static Stream<UserProfile?> streamUserProfile(String uid) {
    return usersRef.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return UserProfile.fromJson({...data, 'uid': data['uid'] ?? snapshot.id});
    });
  }

  static Future<void> createTask(TaskModel task) async {
    await tasksRef.doc(task.id).set(task.toJson());
  }

  static Future<void> createBid(BidModel bid) async {
    await bidsRef.doc(bid.id).set(bid.toJson());
  }

  static Future<void> acceptBid({
    required String taskId,
    required String bidId,
  }) async {
    await _db.runTransaction((transaction) async {
      final taskDoc = tasksRef.doc(taskId);
      final selectedBidDoc = bidsRef.doc(bidId);
      final taskSnapshot = await transaction.get(taskDoc);
      final selectedBidSnapshot = await transaction.get(selectedBidDoc);

      if (!taskSnapshot.exists || !selectedBidSnapshot.exists) {
        throw StateError('Task or bid not found');
      }

      final task = TaskModel.fromJson({
        ...taskSnapshot.data()!,
        'id': taskSnapshot.id,
      });
      final selectedBid = BidModel.fromJson({
        ...selectedBidSnapshot.data()!,
        'id': selectedBidSnapshot.id,
      });

      if (task.status != 'open' || selectedBid.taskId != taskId) {
        throw StateError('Bid cannot be accepted');
      }

      final now = Timestamp.now();
      transaction.update(taskDoc, {
        'status': 'in_progress',
        'acceptedBidId': selectedBid.id,
        'acceptedProviderId': selectedBid.providerId,
        'acceptedAt': now,
      });
      transaction.update(selectedBidDoc, {'status': 'accepted'});
    });

    final otherBids = await bidsRef.where('taskId', isEqualTo: taskId).get();
    final batch = _db.batch();

    for (final bidDoc in otherBids.docs) {
      if (bidDoc.id == bidId) continue;
      final bid = BidModel.fromJson({...bidDoc.data(), 'id': bidDoc.id});
      if (bid.status == 'pending') {
        batch.update(bidDoc.reference, {'status': 'rejected'});
      }
    }

    await batch.commit();
  }

  static Future<void> completeTask(String taskId) async {
    await tasksRef.doc(taskId).update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
    });
  }

  static Future<void> createRating(RatingModel rating) async {
    await ratingsRef.doc(rating.id).set(rating.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamTasks() {
    return tasksRef.snapshots();
  }

  static Stream<TaskModel?> streamTask(String taskId) {
    return tasksRef.doc(taskId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return TaskModel.fromJson({...data, 'id': data['id'] ?? snapshot.id});
    });
  }

  static Stream<List<TaskModel>> streamTasksForUser(String uid) {
    return tasksRef
        .where(
          Filter.or(
            Filter('requesterId', isEqualTo: uid),
            Filter('acceptedProviderId', isEqualTo: uid),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return TaskModel.fromJson({...data, 'id': data['id'] ?? doc.id});
          }).toList();
        });
  }

  static Stream<List<TaskModel>> streamTasksFiltered({
    String? category,
    String? status,
  }) {
    Query<Map<String, dynamic>> query = tasksRef.where(
      'status',
      isEqualTo: status ?? 'open',
    );

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return TaskModel.fromJson({...data, 'id': data['id'] ?? doc.id});
          }).toList();
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
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return BidModel.fromJson({...data, 'id': data['id'] ?? doc.id});
          }).toList();
        });
  }
}
