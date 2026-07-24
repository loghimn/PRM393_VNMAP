import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/providers/statistics_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late StatisticsProvider provider;
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    provider = StatisticsProvider(databaseService: mockDb);
  });

  group('StatisticsProvider — construction & initial state', () {
    test('should have correct initial state', () {
      expect(provider.incidentsByMonth, isEmpty);
      expect(provider.incidentsByNeighborhood, isEmpty);
      expect(provider.incidentsByStatus, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.selectedYear, DateTime.now().year);
    });
  });

  group('setSelectedYear', () {
    test('should update selected year', () {
      provider.setSelectedYear(2025);
      expect(provider.selectedYear, 2025);
    });
  });

  group('loadAll', () {
    test('should load all statistics successfully', () async {
      final byMonth = {'1': 5, '2': 3, '3': 7};
      final byNeighborhood = {'Khu phố 1': 10, 'Khu phố 2': 8};
      final byStatus = {'received': 15, 'processing': 5, 'resolved': 3};

      when(
        () => mockDb.statisticsIncidentsByMonth(any()),
      ).thenAnswer((_) async => byMonth);
      when(
        () => mockDb.statisticsIncidentsByNeighborhood(),
      ).thenAnswer((_) async => byNeighborhood);
      when(
        () => mockDb.statisticsIncidentsByStatus(),
      ).thenAnswer((_) async => byStatus);

      await provider.loadAll();

      expect(provider.incidentsByMonth, byMonth);
      expect(provider.incidentsByNeighborhood, byNeighborhood);
      expect(provider.incidentsByStatus, byStatus);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('should handle errors gracefully', () async {
      when(
        () => mockDb.statisticsIncidentsByMonth(any()),
      ).thenThrow(Exception('Firestore error'));

      await provider.loadAll();

      expect(provider.incidentsByMonth, isEmpty);
      expect(provider.incidentsByNeighborhood, isEmpty);
      expect(provider.incidentsByStatus, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, contains('Firestore error'));
    });
  });

  group('loadByMonth', () {
    test('should load monthly statistics', () async {
      final byMonth = {'1': 5, '2': 3, '7': 10};

      when(
        () => mockDb.statisticsIncidentsByMonth(2025),
      ).thenAnswer((_) async => byMonth);

      provider.setSelectedYear(2025);
      await provider.loadByMonth();

      expect(provider.incidentsByMonth, byMonth);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      verify(() => mockDb.statisticsIncidentsByMonth(2025)).called(1);
    });

    test('should handle error', () async {
      when(
        () => mockDb.statisticsIncidentsByMonth(any()),
      ).thenThrow(Exception('DB error'));

      await provider.loadByMonth();

      expect(provider.incidentsByMonth, isEmpty);
      expect(provider.error, contains('DB error'));
    });
  });

  group('loadByNeighborhood', () {
    test('should load neighborhood statistics', () async {
      final byNeighborhood = {'Khu phố 1': 10, 'Khu phố 2': 8, 'Khu phố 3': 12};

      when(
        () => mockDb.statisticsIncidentsByNeighborhood(),
      ).thenAnswer((_) async => byNeighborhood);

      await provider.loadByNeighborhood();

      expect(provider.incidentsByNeighborhood, byNeighborhood);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('should handle error', () async {
      when(
        () => mockDb.statisticsIncidentsByNeighborhood(),
      ).thenThrow(Exception('Network error'));

      await provider.loadByNeighborhood();

      expect(provider.incidentsByNeighborhood, isEmpty);
      expect(provider.error, contains('Network error'));
    });
  });

  group('loadByStatus', () {
    test('should load status statistics', () async {
      final byStatus = {'received': 15, 'processing': 5, 'resolved': 3};

      when(
        () => mockDb.statisticsIncidentsByStatus(),
      ).thenAnswer((_) async => byStatus);

      await provider.loadByStatus();

      expect(provider.incidentsByStatus, byStatus);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('should handle error', () async {
      when(
        () => mockDb.statisticsIncidentsByStatus(),
      ).thenThrow(Exception('Timeout'));

      await provider.loadByStatus();

      expect(provider.incidentsByStatus, isEmpty);
      expect(provider.error, contains('Timeout'));
    });
  });
}
