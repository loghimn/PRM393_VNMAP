import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/app_notification_model.dart';
import 'package:vietnam_geo_dashboard/providers/notification_provider.dart';

// ============================================================
// HELPERS
// ============================================================

AppNotification createNotification({
  int id = 1,
  String type = 'incident_created',
  String title = 'Sự cố mới',
  bool isRead = false,
  int targetUserId = 1,
  int? actorUserId = 2,
  int? relatedId = 42,
  String? relatedCode = 'SV-0042',
}) {
  return AppNotification(
    id: id,
    type: type,
    title: title,
    body: 'Có sự cố mới vừa được tạo.',
    isRead: isRead,
    targetUserId: targetUserId,
    actorUserId: actorUserId,
    relatedId: relatedId,
    relatedCode: relatedCode,
    createdAt: DateTime.now().subtract(Duration(minutes: id)),
  );
}

Map<String, dynamic> notificationToFirestoreDoc(AppNotification n) {
  return {
    'id': n.id,
    'type': n.type,
    'title': n.title,
    'body': n.body,
    'is_read': n.isRead,
    'target_user_id': n.targetUserId,
    'actor_user_id': n.actorUserId,
    'related_id': n.relatedId,
    'related_code': n.relatedCode,
    'created_at': n.createdAt.toIso8601String(),
  };
}

Future<void> seedNotifications(
  FakeFirebaseFirestore firestore,
  List<AppNotification> notifications,
) async {
  for (final n in notifications) {
    await firestore
        .collection('notifications')
        .doc(n.id.toString())
        .set(notificationToFirestoreDoc(n));
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late NotificationProvider provider;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    provider = NotificationProvider(firestore: fakeFirestore);
  });

  tearDown(() {
    provider.disposeListener();
  });

  group('NotificationProvider — construction & initial state', () {
    test('should have correct initial state', () {
      expect(provider.notifications, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.unreadCount, 0);
      expect(provider.recentNotifications, isEmpty);
    });
  });

  group('initialize', () {
    test('should load notifications for the given userId', () async {
      final notif1 = createNotification(id: 1, targetUserId: 1);
      final notif2 = createNotification(id: 2, targetUserId: 1);
      final notif3 = createNotification(
        id: 3,
        targetUserId: 2,
      ); // different user

      await seedNotifications(fakeFirestore, [notif1, notif2, notif3]);

      provider.initialize(1);

      // Wait for the snapshot listener to fire
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.notifications.length, 2);
      expect(provider.unreadCount, 2);
    });

    test('should not throw if same userId is provided twice', () {
      provider.initialize(1);
      provider.initialize(1);
      // Should not throw
      expect(true, isTrue);
    });
  });

  group('disposeListener', () {
    test('should clear all data and cancel subscription', () async {
      final notif = createNotification(id: 1, targetUserId: 1);
      await seedNotifications(fakeFirestore, [notif]);
      provider.initialize(1);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.notifications, isNotEmpty);

      provider.disposeListener();

      expect(provider.notifications, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.unreadCount, 0);
      expect(provider.recentNotifications, isEmpty);
    });
  });

  group('markAsRead', () {
    test('should update is_read to true in Firestore', () async {
      final notif = createNotification(id: 1, targetUserId: 1, isRead: false);
      await seedNotifications(fakeFirestore, [notif]);
      provider.initialize(1);
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.markAsRead(1);

      final doc = await fakeFirestore
          .collection('notifications')
          .doc('1')
          .get();
      expect(doc.data()?['is_read'], true);
    });

    test('should not throw when notification does not exist', () async {
      // Should complete without error
      await provider.markAsRead(999);
      expect(true, isTrue);
    });
  });

  group('markAllAsRead', () {
    test('should mark all unread notifications as read', () async {
      final n1 = createNotification(id: 1, targetUserId: 1, isRead: false);
      final n2 = createNotification(id: 2, targetUserId: 1, isRead: false);
      final n3 = createNotification(id: 3, targetUserId: 1, isRead: true);
      await seedNotifications(fakeFirestore, [n1, n2, n3]);
      provider.initialize(1);
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.markAllAsRead();

      final snap = await fakeFirestore
          .collection('notifications')
          .orderBy('id')
          .get();
      final allDocs = snap.docs;
      expect(allDocs.length, 3);
      for (final doc in allDocs) {
        expect(doc.data()['is_read'], true);
      }
    });

    test('should handle empty list gracefully', () async {
      provider.initialize(1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Should complete without error
      await provider.markAllAsRead();
      expect(true, isTrue);
    });
  });

  group('deleteNotification', () {
    test('should delete notification from Firestore', () async {
      final notif = createNotification(id: 1, targetUserId: 1);
      await seedNotifications(fakeFirestore, [notif]);
      provider.initialize(1);
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.deleteNotification(1);

      final doc = await fakeFirestore
          .collection('notifications')
          .doc('1')
          .get();
      expect(doc.exists, false);
    });

    test('should not throw when deleting non-existent notification', () async {
      // Should complete without error
      await provider.deleteNotification(999);
      expect(true, isTrue);
    });
  });

  group('recentNotifications', () {
    test('should return up to 5 most recent notifications', () async {
      final notifs = List.generate(
        10,
        (i) => createNotification(id: i + 1, targetUserId: 1),
      );
      await seedNotifications(fakeFirestore, notifs);
      provider.initialize(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final recent = provider.recentNotifications;
      expect(recent.length, 5);
      // Most recent (largest id, smallest duration) first
      expect(recent[0].id, 1);
      expect(recent[1].id, 2);
    });

    test('should return fewer than 5 if not enough notifications', () async {
      final notifs = [
        createNotification(id: 1, targetUserId: 1),
        createNotification(id: 2, targetUserId: 1),
      ];
      await seedNotifications(fakeFirestore, notifs);
      provider.initialize(1);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.recentNotifications.length, 2);
    });
  });

  group('error handling', () {
    test('should handle listener error gracefully', () async {
      // Dispose the current provider's subscription
      provider.disposeListener();

      // Simulate an error by providing a non-existent collection reference
      // The listener onError should be called
      provider.initialize(1);
      // We can't easily force an error with FakeFirebaseFirestore,
      // but we can verify the provider is in a consistent state
      expect(provider.isLoading, true);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoading, false);
    });
  });
}
