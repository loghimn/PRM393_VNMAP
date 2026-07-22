import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = createTestFirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService — Statistics', () {
    group('statisticsIncidentsByMonth', () {
      test('returns zero counts for empty data', () async {
        final result = await service.statisticsIncidentsByMonth(2024);

        for (int i = 1; i <= 12; i++) {
          expect(result['Month $i'], 0);
        }
      });

      test('counts incidents grouped by month', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'Jan incident',
          'status': 'received',
          'created_at': '2024-01-15T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('2').set({
          'id': 2,
          'incident_code': 'IC-0002',
          'title': 'Feb incident',
          'status': 'received',
          'created_at': '2024-02-10T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('3').set({
          'id': 3,
          'incident_code': 'IC-0003',
          'title': 'Jan incident 2',
          'status': 'completed',
          'created_at': '2024-01-20T00:00:00.000',
        });

        final result = await service.statisticsIncidentsByMonth(2024);

        expect(result['Month 1'], 2);
        expect(result['Month 2'], 1);
        expect(result['Month 3'], 0);
      });

      test('ignores incidents from different year', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'Old incident',
          'status': 'received',
          'created_at': '2023-12-31T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('2').set({
          'id': 2,
          'incident_code': 'IC-0002',
          'title': 'New incident',
          'status': 'received',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.statisticsIncidentsByMonth(2024);

        expect(result['Month 1'], 1);
        expect(result['Month 12'], 0);
      });
    });

    group('statisticsIncidentsByNeighborhood', () {
      test('returns empty map when no incidents', () async {
        final result = await service.statisticsIncidentsByNeighborhood();

        expect(result, isEmpty);
      });

      test('groups incidents by neighborhood', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'A',
          'status': 'received',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('2').set({
          'id': 2,
          'incident_code': 'IC-0002',
          'title': 'B',
          'status': 'received',
          'neighborhood': 'Khu phố 2',
          'created_at': '2024-01-02T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('3').set({
          'id': 3,
          'incident_code': 'IC-0003',
          'title': 'C',
          'status': 'received',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-03T00:00:00.000',
        });

        final result = await service.statisticsIncidentsByNeighborhood();

        expect(result['Khu phố 1'], 2);
        expect(result['Khu phố 2'], 1);
      });
    });

    group('statisticsIncidentsByStatus', () {
      test('returns empty map when no incidents', () async {
        final result = await service.statisticsIncidentsByStatus();

        expect(result, isEmpty);
      });

      test('groups incidents by status display name', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'A',
          'status': 'received',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('2').set({
          'id': 2,
          'incident_code': 'IC-0002',
          'title': 'B',
          'status': 'processing',
          'created_at': '2024-01-02T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('3').set({
          'id': 3,
          'incident_code': 'IC-0003',
          'title': 'C',
          'status': 'received',
          'created_at': '2024-01-03T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('4').set({
          'id': 4,
          'incident_code': 'IC-0004',
          'title': 'D',
          'status': 'completed',
          'created_at': '2024-01-04T00:00:00.000',
        });

        final result = await service.statisticsIncidentsByStatus();

        expect(result['Received'], 2);
        expect(result['Processing'], 1);
        expect(result['Completed'], 1);
      });
    });
  });
}
