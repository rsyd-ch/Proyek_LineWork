import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linework_app/models/bid_model.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/models/user_profile.dart';

void main() {
  group('TaskModel', () {
    test('serializes Firestore values and keeps optional due date', () {
      final createdAt = DateTime.utc(2026, 5, 25, 10);
      final dueAt = DateTime.utc(2026, 5, 26, 12);
      final task = TaskModel(
        id: 'task-1',
        title: 'Antar paket',
        description: 'Ambil paket dan antar ke tujuan',
        requesterId: 'user-1',
        location: const GeoPoint(-6.2, 106.8),
        price: 50000,
        isCod: false,
        category: 'Angkut Barang',
        status: 'open',
        acceptedBidId: 'bid-1',
        acceptedProviderId: 'provider-1',
        createdAt: createdAt,
        dueAt: dueAt,
        acceptedAt: createdAt.add(const Duration(minutes: 10)),
        completedAt: dueAt,
      );

      final json = task.toJson();
      final parsed = TaskModel.fromJson(json);

      expect(parsed.id, 'task-1');
      expect(parsed.location.latitude, -6.2);
      expect(parsed.price, 50000);
      expect(parsed.isCod, isFalse);
      expect(parsed.acceptedBidId, 'bid-1');
      expect(parsed.acceptedProviderId, 'provider-1');
      expect(parsed.createdAt.isAtSameMomentAs(createdAt), isTrue);
      expect(parsed.dueAt?.isAtSameMomentAs(dueAt), isTrue);
      expect(
        parsed.acceptedAt?.isAtSameMomentAs(
          createdAt.add(const Duration(minutes: 10)),
        ),
        isTrue,
      );
      expect(parsed.completedAt?.isAtSameMomentAs(dueAt), isTrue);
    });

    test('uses safe defaults for incomplete data', () {
      final task = TaskModel.fromJson(<String, dynamic>{});

      expect(task.title, 'Pekerjaan tanpa judul');
      expect(task.category, 'Lainnya');
      expect(task.status, 'open');
      expect(task.isCod, isTrue);
      expect(task.location.latitude, 0);
      expect(task.location.longitude, 0);
    });
  });

  group('BidModel', () {
    test('serializes amount and defaults status to pending', () {
      final createdAt = DateTime.utc(2026, 5, 25, 11);
      final bid = BidModel(
        id: 'bid-1',
        taskId: 'task-1',
        providerId: 'provider-1',
        amount: 75000,
        message: 'Saya bisa bantu sore ini',
        createdAt: createdAt,
      );

      final parsed = BidModel.fromJson(bid.toJson());

      expect(parsed.amount, 75000);
      expect(parsed.status, 'pending');
      expect(parsed.createdAt.isAtSameMomentAs(createdAt), isTrue);
    });
  });

  group('UserProfile', () {
    test('defaults verification state and reads string dates', () {
      final profile = UserProfile.fromJson({
        'uid': 'user-1',
        'email': 'user@example.com',
        'createdAt': '2026-05-25T10:00:00.000Z',
        'updatedAt': '2026-05-25T11:00:00.000Z',
      });

      expect(profile.uid, 'user-1');
      expect(profile.email, 'user@example.com');
      expect(profile.isVerified, isFalse);
      expect(profile.createdAt, DateTime.utc(2026, 5, 25, 10));
      expect(profile.updatedAt, DateTime.utc(2026, 5, 25, 11));
    });
  });
}
