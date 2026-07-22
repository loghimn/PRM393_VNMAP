import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnam_geo_dashboard/models/household_request_model.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = createTestFirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService — HouseholdRequest', () {
    group('createHouseholdRequest', () {
      test('creates a household request with given data', () async {
        final request = HouseholdRequest(
          userId: 1,
          headOfHousehold: 'Nguyễn Văn A',
          phone: '0909123456',
          houseNumber: '123',
          street: 'Đường ABC',
          neighborhood: 'Khu phố 1',
          ward: 'Phường 1',
          district: 'Quận 1',
          city: 'TP. Hồ Chí Minh',
          status: 'pending',
        );

        final created = await service.createHouseholdRequest(request);

        expect(created.id, greaterThan(0));
        expect(created.headOfHousehold, 'Nguyễn Văn A');
        expect(created.status, 'pending');
      });
    });

    group('fetchHouseholdRequests', () {
      test('returns all requests when no filter', () async {
        await fakeFirestore.collection('household_requests').doc('1').set({
          'id': 1,
          'user_id': 1,
          'head_of_household': 'A',
          'status': 'pending',
          'created_at': '2024-01-02T00:00:00.000',
          'updated_at': '2024-01-02T00:00:00.000',
        });
        await fakeFirestore.collection('household_requests').doc('2').set({
          'id': 2,
          'user_id': 2,
          'head_of_household': 'B',
          'status': 'approved',
          'created_at': '2024-01-03T00:00:00.000',
          'updated_at': '2024-01-03T00:00:00.000',
        });

        final result = await service.fetchHouseholdRequests();

        expect(result.length, 2);
        // Sorted by created_at descending
        expect(result.first.headOfHousehold, 'B');
        expect(result.last.headOfHousehold, 'A');
      });

      test('filters by status', () async {
        await fakeFirestore.collection('household_requests').doc('1').set({
          'id': 1,
          'user_id': 1,
          'head_of_household': 'A',
          'status': 'pending',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('household_requests').doc('2').set({
          'id': 2,
          'user_id': 2,
          'head_of_household': 'B',
          'status': 'approved',
          'created_at': '2024-01-02T00:00:00.000',
          'updated_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchHouseholdRequests(status: 'pending');

        expect(result.length, 1);
        expect(result.first.headOfHousehold, 'A');
      });

      test('filters by userId', () async {
        await fakeFirestore.collection('household_requests').doc('1').set({
          'id': 1,
          'user_id': 5,
          'head_of_household': 'User5 Req',
          'status': 'pending',
          'created_at': '2024-02-01T00:00:00.000',
          'updated_at': '2024-02-01T00:00:00.000',
        });
        await fakeFirestore.collection('household_requests').doc('2').set({
          'id': 2,
          'user_id': 5,
          'head_of_household': 'User5 Req 2',
          'status': 'approved',
          'created_at': '2024-02-10T00:00:00.000',
          'updated_at': '2024-02-10T00:00:00.000',
        });
        await fakeFirestore.collection('household_requests').doc('3').set({
          'id': 3,
          'user_id': 6,
          'head_of_household': 'User6 Req',
          'status': 'pending',
          'created_at': '2024-03-01T00:00:00.000',
          'updated_at': '2024-03-01T00:00:00.000',
        });

        final result = await service.fetchHouseholdRequests(userId: 5);

        expect(result.length, 2);
      });

      test('returns empty list when nothing matches', () async {
        final result = await service.fetchHouseholdRequests(status: 'pending');

        expect(result, isEmpty);
      });
    });

    group('fetchHouseholdRequestById', () {
      test('returns request when found', () async {
        await fakeFirestore.collection('household_requests').doc('10').set({
          'id': 10,
          'user_id': 1,
          'head_of_household': 'Specific Request',
          'status': 'pending',
          'created_at': '2024-01-10T00:00:00.000',
          'updated_at': '2024-01-10T00:00:00.000',
        });

        final result = await service.fetchHouseholdRequestById(10);

        expect(result, isNotNull);
        expect(result!.headOfHousehold, 'Specific Request');
      });

      test('returns null when not found', () async {
        final result = await service.fetchHouseholdRequestById(999);

        expect(result, isNull);
      });
    });

    group('updateHouseholdRequestStatus', () {
      test('updates status and sets updated_at', () async {
        await fakeFirestore.collection('household_requests').doc('1').set({
          'id': 1,
          'user_id': 1,
          'head_of_household': 'Original',
          'status': 'pending',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });

        final updated = await service.updateHouseholdRequestStatus(
          1,
          'approved',
        );

        expect(updated.status, 'approved');
        expect(updated.updatedAt, isNotNull);
      });
    });
  });
}
