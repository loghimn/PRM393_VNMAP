import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnam_geo_dashboard/models/app_notification_model.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = createTestFirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService — Notification', () {
    group('addNotification', () {
      test('creates a notification document in Firestore', () async {
        await service.addNotification(
          type: 'incident_created',
          title: 'Sự cố mới',
          body: 'Có sự cố mới vừa được tạo.',
          targetUserId: 2,
          actorUserId: 1,
          relatedId: 42,
          relatedCode: 'SV-0042',
        );

        final snap = await fakeFirestore
            .collection('notifications')
            .orderBy('id')
            .get();
        expect(snap.docs.length, 1);

        final data = snap.docs.first.data();
        expect(data['type'], 'incident_created');
        expect(data['title'], 'Sự cố mới');
        expect(data['body'], 'Có sự cố mới vừa được tạo.');
        expect(data['target_user_id'], 2);
        expect(data['actor_user_id'], 1);
        expect(data['related_id'], 42);
        expect(data['related_code'], 'SV-0042');
        expect(data['is_read'], false);
        expect(data['id'], greaterThan(0));
      });

      test('creates multiple notifications with different types', () async {
        await service.addNotification(
          type: 'incident_created',
          title: 'Sự cố mới',
          body: 'Có sự cố mới.',
          targetUserId: 1,
        );
        await service.addNotification(
          type: 'request_approved',
          title: 'Yêu cầu được duyệt',
          body: 'Yêu cầu hộ khẩu của bạn đã được duyệt.',
          targetUserId: 2,
        );

        final snap = await fakeFirestore
            .collection('notifications')
            .orderBy('id')
            .get();
        expect(snap.docs.length, 2);
        expect(snap.docs[0].data()['type'], 'incident_created');
        expect(snap.docs[1].data()['type'], 'request_approved');
      });
    });

    group('fetchAdminUserIds', () {
      test('returns list of admin user IDs', () async {
        await fakeFirestore.collection('users').doc('1').set({
          'id': 1,
          'role': 'admin',
          'username': 'admin1',
        });
        await fakeFirestore.collection('users').doc('2').set({
          'id': 2,
          'role': 'user',
          'username': 'user1',
        });
        await fakeFirestore.collection('users').doc('3').set({
          'id': 3,
          'role': 'admin',
          'username': 'admin2',
        });

        final adminIds = await service.fetchAdminUserIds();

        expect(adminIds, hasLength(2));
        expect(adminIds, containsAll([1, 3]));
        expect(adminIds, isNot(contains(2)));
      });

      test('returns empty list when no admins', () async {
        await fakeFirestore.collection('users').doc('1').set({
          'id': 1,
          'role': 'user',
          'username': 'user1',
        });

        final adminIds = await service.fetchAdminUserIds();

        expect(adminIds, isEmpty);
      });
    });
  });
}
