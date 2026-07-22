import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'package:vietnam_geo_dashboard/providers/incident_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

// ============================================================
// HELPERS
// ============================================================

Incident createIncident({
  int? id = 1,
  String incidentCode = 'SV-001',
  String title = 'Sự vụ test',
  IncidentStatus status = IncidentStatus.received,
  String? neighborhood,
  int? createdBy = 1,
}) {
  return Incident(
    id: id,
    incidentCode: incidentCode,
    title: title,
    description: 'Mô tả sự vụ',
    address: '123 Đường Lê Lợi',
    incidentAddress: '123 Đường Lê Lợi',
    neighborhood: neighborhood ?? 'Khu phố 1',
    ward: 'Phường Bến Nghé',
    district: 'Quận 1',
    city: 'Hồ Chí Minh',
    status: status,
    createdBy: createdBy,
  );
}

void main() {
  late IncidentProvider provider;
  late MockDatabaseService mockDb;

  final incident1 = createIncident(id: 1);
  final incident2 = createIncident(id: 2, incidentCode: 'SV-002');
  final allIncidents = [incident1, incident2];

  setUpAll(() {
    registerFallbackValue(createIncident());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    provider = IncidentProvider(databaseService: mockDb);
  });

  group('IncidentProvider — construction & initial state', () {
    test('should have correct initial state', () {
      expect(provider.items, isEmpty);
      expect(provider.selected, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.totalCount, equals(0));
      expect(provider.searchQuery, isEmpty);
      expect(provider.filterStatus, isNull);
      expect(provider.filterNeighborhood, isNull);
      expect(provider.neighborhoodList, isEmpty);
    });
  });

  group('IncidentProvider — loadItems()', () {
    test('should load items and count successfully', () async {
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allIncidents);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);

      await provider.loadItems();

      expect(provider.items, equals(allIncidents));
      expect(provider.totalCount, equals(2));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('should persist filters passed to loadItems', () async {
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [incident1]);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 1);

      await provider.loadItems(
        searchQuery: 'test',
        status: 'processing',
        neighborhood: 'Khu phố 2',
        createdBy: 1,
      );

      expect(provider.searchQuery, equals('test'));
      expect(provider.filterStatus, equals('processing'));
      expect(provider.filterNeighborhood, equals('Khu phố 2'));
    });

    test('should handle exception during loadItems', () async {
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(Exception('Load failed'));

      await provider.loadItems();

      expect(provider.items, isEmpty);
      expect(provider.error, contains('Load failed'));
      expect(provider.isLoading, isFalse);
    });

    test('should set loading state correctly', () async {
      final completer = Completer<List<Incident>>();
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) => completer.future);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 0);

      final future = provider.loadItems();
      expect(provider.isLoading, isTrue);

      completer.complete([]);
      await future;

      expect(provider.isLoading, isFalse);
    });
  });

  group('IncidentProvider — loadNeighborhoodList()', () {
    test('should load neighborhood list successfully', () async {
      when(
        () => mockDb.fetchNeighborhoodList(),
      ).thenAnswer((_) async => ['Khu phố 1', 'Khu phố 2']);

      await provider.loadNeighborhoodList();

      expect(provider.neighborhoodList, equals(['Khu phố 1', 'Khu phố 2']));
    });

    test('should keep previous list on exception', () async {
      when(() => mockDb.fetchNeighborhoodList()).thenThrow(Exception('Error'));

      await provider.loadNeighborhoodList();

      expect(provider.neighborhoodList, isEmpty);
    });
  });

  group('IncidentProvider — loadById()', () {
    test('should load incident by id successfully', () async {
      when(
        () => mockDb.fetchIncidentById(1),
      ).thenAnswer((_) async => incident1);

      final result = await provider.loadById(1);

      expect(result, equals(incident1));
      expect(provider.selected, equals(incident1));
      expect(provider.isLoading, isFalse);
    });

    test('should handle exception during loadById', () async {
      when(() => mockDb.fetchIncidentById(1)).thenThrow(Exception('Not found'));

      final result = await provider.loadById(1);

      expect(result, isNull);
      expect(provider.error, contains('Not found'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('IncidentProvider — create()', () {
    test('should create incident and reload items', () async {
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allIncidents);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);
      when(
        () => mockDb.createIncident(any()),
      ).thenAnswer((_) async => incident1);

      final result = await provider.create(incident1);

      expect(result, isTrue);
      expect(provider.items, equals(allIncidents));
      verify(() => mockDb.createIncident(incident1)).called(1);
    });

    test('should handle exception during create', () async {
      when(
        () => mockDb.createIncident(any()),
      ).thenThrow(Exception('Create failed'));

      final result = await provider.create(incident1);

      expect(result, isFalse);
      expect(provider.error, contains('Create failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('IncidentProvider — update()', () {
    test('should update incident and reload items', () async {
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allIncidents);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);
      when(
        () => mockDb.updateIncident(any(), updatedBy: any(named: 'updatedBy')),
      ).thenAnswer((_) async => incident1);

      final result = await provider.update(incident1, updatedBy: 1);

      expect(result, isTrue);
      expect(provider.selected, equals(incident1));
      verify(() => mockDb.updateIncident(incident1, updatedBy: 1)).called(1);
    });

    test('should handle exception during update', () async {
      when(
        () => mockDb.updateIncident(any(), updatedBy: any(named: 'updatedBy')),
      ).thenThrow(Exception('Update failed'));

      final result = await provider.update(incident1);

      expect(result, isFalse);
      expect(provider.error, contains('Update failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('IncidentProvider — updateStatus()', () {
    test('should change status to completed and set completedDate', () async {
      // Pre-load items so firstWhere works
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allIncidents);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);
      await provider.loadItems();

      when(
        () => mockDb.updateIncident(any(), updatedBy: any(named: 'updatedBy')),
      ).thenAnswer((_) async => incident1);

      final result = await provider.updateStatus(
        1,
        IncidentStatus.completed,
        updatedBy: 1,
      );

      expect(result, isTrue);
      verify(
        () => mockDb.updateIncident(any(that: isA<Incident>()), updatedBy: 1),
      ).called(1);
    });

    test('should change status to processing without completedDate', () async {
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allIncidents);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);
      await provider.loadItems();

      when(
        () => mockDb.updateIncident(any(), updatedBy: any(named: 'updatedBy')),
      ).thenAnswer((_) async => incident1);

      final result = await provider.updateStatus(
        1,
        IncidentStatus.processing,
        updatedBy: 1,
      );

      expect(result, isTrue);
    });
  });

  group('IncidentProvider — assignHandler()', () {
    test('should assign handler and update incident', () async {
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allIncidents);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);
      await provider.loadItems();

      when(
        () => mockDb.updateIncident(any(), updatedBy: any(named: 'updatedBy')),
      ).thenAnswer((_) async => incident1);

      final result = await provider.assignHandler(
        1,
        'Nguyễn Văn B',
        updatedBy: 1,
      );

      expect(result, isTrue);
      verify(
        () => mockDb.updateIncident(any(that: isA<Incident>()), updatedBy: 1),
      ).called(1);
    });
  });

  group('IncidentProvider — delete()', () {
    test('should delete incident and reload items', () async {
      // Load selected first
      when(
        () => mockDb.fetchIncidentById(1),
      ).thenAnswer((_) async => incident1);
      await provider.loadById(1);
      expect(provider.selected, isNotNull);

      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [incident2]);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDb.deleteIncident(1, deletedBy: any(named: 'deletedBy')),
      ).thenAnswer((_) async => Future.value());

      final result = await provider.delete(1, deletedBy: 1);

      expect(result, isTrue);
      expect(provider.selected, isNull); // cleared because matches deleted id
      verify(() => mockDb.deleteIncident(1, deletedBy: 1)).called(1);
    });

    test('should handle exception during delete', () async {
      when(
        () => mockDb.deleteIncident(1, deletedBy: any(named: 'deletedBy')),
      ).thenThrow(Exception('Delete failed'));

      final result = await provider.delete(1);

      expect(result, isFalse);
      expect(provider.error, contains('Delete failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('IncidentProvider — setters', () {
    test('setSearchQuery should update search query', () {
      provider.setSearchQuery('test query');
      expect(provider.searchQuery, equals('test query'));
    });

    test('setFilterStatus should update filter status', () {
      provider.setFilterStatus('completed');
      expect(provider.filterStatus, equals('completed'));
    });

    test('setFilterStatus should accept null', () {
      provider.setFilterStatus('processing');
      expect(provider.filterStatus, isNotNull);

      provider.setFilterStatus(null);
      expect(provider.filterStatus, isNull);
    });

    test('setFilterNeighborhood should update neighborhood filter', () {
      provider.setFilterNeighborhood('Khu phố 2');
      expect(provider.filterNeighborhood, equals('Khu phố 2'));
    });
  });

  group('IncidentProvider — clearSelected()', () {
    test('should clear selected incident', () async {
      when(
        () => mockDb.fetchIncidentById(1),
      ).thenAnswer((_) async => incident1);
      await provider.loadById(1);
      expect(provider.selected, isNotNull);

      provider.clearSelected();

      expect(provider.selected, isNull);
    });
  });

  group('IncidentProvider — reset()', () {
    test('should reset all state to initial values', () async {
      // First set some state
      when(
        () => mockDb.fetchIncidentList(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allIncidents);
      when(
        () => mockDb.countIncidents(
          searchQuery: any(named: 'searchQuery'),
          status: any(named: 'status'),
          neighborhood: any(named: 'neighborhood'),
          householdId: any(named: 'householdId'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);
      await provider.loadItems();
      expect(provider.items, isNotEmpty);

      provider.reset();

      expect(provider.items, isEmpty);
      expect(provider.selected, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.totalCount, equals(0));
      expect(provider.searchQuery, isEmpty);
      expect(provider.filterStatus, isNull);
      expect(provider.filterNeighborhood, isNull);
      expect(provider.neighborhoodList, isEmpty);
    });
  });
}
