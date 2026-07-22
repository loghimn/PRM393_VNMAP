import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = createTestFirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService — Incidents', () {
    group('fetchIncidentList', () {
      test('returns list of incidents', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'Hỏng đèn đường',
          'description': 'Đèn đường số 10 bị hỏng',
          'status': 'received',
          'neighborhood': 'Khu phố 1',
          'ward': 'Phường 1',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchIncidentList();

        expect(result.length, 1);
        expect(result.first.title, 'Hỏng đèn đường');
        expect(result.first.status, IncidentStatus.received);
      });

      test('filters by status', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'Incident A',
          'status': 'received',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('2').set({
          'id': 2,
          'incident_code': 'IC-0002',
          'title': 'Incident B',
          'status': 'completed',
          'created_at': '2024-01-02T00:00:00.000',
          'updated_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchIncidentList(status: 'completed');

        expect(result.length, 1);
        expect(result.first.title, 'Incident B');
      });

      test('filters by neighborhood', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'A',
          'status': 'received',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('2').set({
          'id': 2,
          'incident_code': 'IC-0002',
          'title': 'B',
          'status': 'received',
          'neighborhood': 'Khu phố 2',
          'created_at': '2024-01-02T00:00:00.000',
          'updated_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchIncidentList(
          neighborhood: 'Khu phố 1',
        );

        expect(result.length, 1);
        expect(result.first.title, 'A');
      });

      test('filters by search query', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'Hỏng đèn đường',
          'status': 'received',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchIncidentList(searchQuery: 'đèn');

        expect(result.length, 1);
      });

      test('applies pagination with limit and offset', () async {
        for (int i = 0; i < 5; i++) {
          await fakeFirestore.collection('incidents').doc('$i').set({
            'id': i,
            'incident_code': 'IC-${(i + 1).toString().padLeft(4, '0')}',
            'title': 'Incident $i',
            'status': 'received',
            'created_at': '2024-01-0${i + 1}T00:00:00.000',
            'updated_at': '2024-01-0${i + 1}T00:00:00.000',
          });
        }

        final result = await service.fetchIncidentList(limit: 2, offset: 1);

        expect(result.length, 2);
      });
    });

    group('fetchIncidentById', () {
      test('returns incident when found', () async {
        await fakeFirestore.collection('incidents').doc('5').set({
          'id': 5,
          'incident_code': 'IC-0005',
          'title': 'Test Incident',
          'status': 'processing',
          'created_at': '2024-01-05T00:00:00.000',
          'updated_at': '2024-01-05T00:00:00.000',
        });

        final result = await service.fetchIncidentById(5);

        expect(result, isNotNull);
        expect(result!.title, 'Test Incident');
        expect(result.status, IncidentStatus.processing);
      });

      test('returns null when not found', () async {
        final result = await service.fetchIncidentById(999);

        expect(result, isNull);
      });
    });

    group('createIncident', () {
      test('creates an incident and returns it', () async {
        final incident = Incident(
          incidentCode: 'IC-TEMP',
          title: 'New Incident',
          description: 'Test description',
          status: IncidentStatus.received,
          neighborhood: 'Khu phố 1',
          ward: 'Phường 1',
        );

        final created = await service.createIncident(incident);

        expect(created.id, greaterThan(0));
        expect(created.title, 'New Incident');
        expect(created.status, IncidentStatus.received);

        // Verify it was persisted
        final snap = await fakeFirestore.collection('incidents').get();
        expect(snap.docs.length, 1);
      });
    });

    group('updateIncident', () {
      test('updates an existing incident', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'Original Title',
          'status': 'received',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });

        final updated = await service.updateIncident(
          Incident(
            id: 1,
            incidentCode: 'IC-0001',
            title: 'Updated Title',
            description: 'Updated desc',
            status: IncidentStatus.processing,
          ),
        );

        expect(updated.title, 'Updated Title');
        expect(updated.status, IncidentStatus.processing);
      });

      test('updates and sends notification on status change', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'Status Change Test',
          'status': 'received',
          'created_by': 42,
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });

        await service.updateIncident(
          Incident(
            id: 1,
            incidentCode: 'IC-0001',
            title: 'Status Change Test',
            status: IncidentStatus.completed,
          ),
          updatedBy: 1,
        );

        // Notification should have been created for created_by (42)
        final notifSnap = await fakeFirestore.collection('notifications').get();
        expect(notifSnap.docs.length, 1);
        expect(notifSnap.docs.first.data()['type'], 'incident_status_changed');
      });
    });

    group('deleteIncident', () {
      test('deletes an incident', () async {
        await fakeFirestore.collection('incidents').doc('7').set({
          'id': 7,
          'incident_code': 'IC-0007',
          'title': 'To Delete',
          'status': 'received',
          'created_at': '2024-01-07T00:00:00.000',
          'updated_at': '2024-01-07T00:00:00.000',
        });

        await service.deleteIncident(7);

        final snap = await fakeFirestore.collection('incidents').get();
        expect(snap.docs.length, 0);
      });

      test('sends notification when deletedBy is provided', () async {
        await fakeFirestore.collection('incidents').doc('8').set({
          'id': 8,
          'incident_code': 'IC-0008',
          'title': 'Delete With Note',
          'status': 'received',
          'created_at': '2024-01-08T00:00:00.000',
          'updated_at': '2024-01-08T00:00:00.000',
        });

        await service.deleteIncident(8, deletedBy: 99);

        final notifSnap = await fakeFirestore.collection('notifications').get();
        expect(notifSnap.docs.length, 1);
        expect(notifSnap.docs.first.data()['type'], 'incident_deleted');
      });
    });

    group('countIncidents', () {
      test('returns total count', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'IC-0001',
          'title': 'A',
          'status': 'received',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('incidents').doc('2').set({
          'id': 2,
          'incident_code': 'IC-0002',
          'title': 'B',
          'status': 'completed',
          'created_at': '2024-01-02T00:00:00.000',
          'updated_at': '2024-01-02T00:00:00.000',
        });

        final count = await service.countIncidents();

        expect(count, 2);
      });
    });

    group('generateIncidentCode', () {
      test('generates SV-0001 when no incidents exist', () async {
        final code = await service.generateIncidentCode();

        expect(code, 'SV-0001');
      });

      test('generates incremented code', () async {
        await fakeFirestore.collection('incidents').doc('1').set({
          'id': 1,
          'incident_code': 'SV-0005',
          'title': 'Existing',
          'status': 'received',
          'created_at': '2024-01-01T00:00:00.000',
          'updated_at': '2024-01-01T00:00:00.000',
        });

        final code = await service.generateIncidentCode();

        expect(code, 'SV-0006');
      });
    });
  });
}
