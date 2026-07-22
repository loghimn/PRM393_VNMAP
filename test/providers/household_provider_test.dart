import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/providers/household_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

// ============================================================
// HELPERS
// ============================================================

Household createHousehold({
  int? id = 1,
  String householdCode = 'HH-001',
  String headOfHousehold = 'Nguyễn Văn A',
  String? neighborhood,
  String? ward,
  int? createdBy = 1,
}) {
  return Household(
    id: id,
    householdCode: householdCode,
    headOfHousehold: headOfHousehold,
    phone: '0909123456',
    houseNumber: '123',
    street: 'Đường Lê Lợi',
    neighborhood: neighborhood ?? 'Khu phố 1',
    ward: ward ?? 'Phường Bến Nghé',
    district: 'Quận 1',
    city: 'Hồ Chí Minh',
    createdBy: createdBy,
  );
}

void main() {
  late HouseholdProvider provider;
  late MockDatabaseService mockDb;

  final household1 = createHousehold(id: 1);
  final household2 = createHousehold(id: 2, householdCode: 'HH-002');
  final allHouseholds = [household1, household2];

  setUpAll(() {
    registerFallbackValue(createHousehold());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    provider = HouseholdProvider(databaseService: mockDb);
  });

  group('HouseholdProvider — construction & initial state', () {
    test('should have correct initial state', () {
      expect(provider.items, isEmpty);
      expect(provider.selected, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.totalCount, equals(0));
      expect(provider.searchQuery, isEmpty);
      expect(provider.filterNeighborhood, isNull);
    });
  });

  group('HouseholdProvider — loadItems()', () {
    test('should load items and count successfully', () async {
      when(
        () => mockDb.fetchHouseholdList(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allHouseholds);
      when(
        () => mockDb.countHouseholds(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);

      await provider.loadItems();

      expect(provider.items, equals(allHouseholds));
      expect(provider.totalCount, equals(2));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('should handle exception during loadItems', () async {
      when(
        () => mockDb.fetchHouseholdList(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
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

    test('should persist search query and neighborhood filters', () async {
      when(
        () => mockDb.fetchHouseholdList(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [household1]);
      when(
        () => mockDb.countHouseholds(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 1);

      await provider.loadItems(
        searchQuery: 'Nguyễn',
        neighborhood: 'Khu phố 1',
        createdBy: 1,
      );

      expect(provider.searchQuery, equals('Nguyễn'));
      expect(provider.filterNeighborhood, equals('Khu phố 1'));
    });

    test('should set loading state correctly', () async {
      final completer = Completer<List<Household>>();
      when(
        () => mockDb.fetchHouseholdList(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) => completer.future);
      when(
        () => mockDb.countHouseholds(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
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

  group('HouseholdProvider — loadById()', () {
    test('should load household by id successfully', () async {
      when(
        () => mockDb.fetchHouseholdById(1),
      ).thenAnswer((_) async => household1);

      final result = await provider.loadById(1);

      expect(result, equals(household1));
      expect(provider.selected, equals(household1));
      expect(provider.isLoading, isFalse);
    });

    test('should handle exception during loadById', () async {
      when(
        () => mockDb.fetchHouseholdById(1),
      ).thenThrow(Exception('Not found'));

      final result = await provider.loadById(1);

      expect(result, isNull);
      expect(provider.error, contains('Not found'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('HouseholdProvider — create()', () {
    test('should create household and reload items', () async {
      when(
        () => mockDb.fetchHouseholdList(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allHouseholds);
      when(
        () => mockDb.countHouseholds(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);
      when(
        () => mockDb.createHousehold(any()),
      ).thenAnswer((_) async => household1);

      final result = await provider.create(household1);

      expect(result, isTrue);
      expect(provider.items, equals(allHouseholds));
      verify(() => mockDb.createHousehold(household1)).called(1);
    });

    test('should handle exception during create', () async {
      when(
        () => mockDb.createHousehold(any()),
      ).thenThrow(Exception('Create failed'));

      final result = await provider.create(household1);

      expect(result, isFalse);
      expect(provider.error, contains('Create failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('HouseholdProvider — update()', () {
    test('should update household and reload items', () async {
      when(
        () => mockDb.fetchHouseholdList(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => allHouseholds);
      when(
        () => mockDb.countHouseholds(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 2);
      when(
        () => mockDb.updateHousehold(any()),
      ).thenAnswer((_) async => household1);

      final result = await provider.update(household1);

      expect(result, isTrue);
      expect(provider.selected, equals(household1));
      verify(() => mockDb.updateHousehold(household1)).called(1);
    });

    test('should handle exception during update', () async {
      when(
        () => mockDb.updateHousehold(any()),
      ).thenThrow(Exception('Update failed'));

      final result = await provider.update(household1);

      expect(result, isFalse);
      expect(provider.error, contains('Update failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('HouseholdProvider — delete()', () {
    test('should delete household and reload items', () async {
      // First load an item so selected is set
      when(
        () => mockDb.fetchHouseholdById(1),
      ).thenAnswer((_) async => household1);
      await provider.loadById(1);
      expect(provider.selected, isNotNull);

      when(
        () => mockDb.fetchHouseholdList(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [household2]);
      when(
        () => mockDb.countHouseholds(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDb.deleteHousehold(1),
      ).thenAnswer((_) async => Future.value());

      final result = await provider.delete(1);

      expect(result, isTrue);
      expect(
        provider.selected,
        isNull,
      ); // cleared because selected.id == deleted id
      verify(() => mockDb.deleteHousehold(1)).called(1);
    });

    test('should not clear selected if deleting different id', () async {
      provider.clearSelected();
      // Set selected to household1
      when(
        () => mockDb.fetchHouseholdById(1),
      ).thenAnswer((_) async => household1);
      await provider.loadById(1);
      expect(provider.selected?.id, equals(1));

      when(
        () => mockDb.fetchHouseholdList(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [household2]);
      when(
        () => mockDb.countHouseholds(
          searchQuery: any(named: 'searchQuery'),
          neighborhood: any(named: 'neighborhood'),
          ward: any(named: 'ward'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDb.deleteHousehold(2),
      ).thenAnswer((_) async => Future.value());

      final result = await provider.delete(2);

      expect(result, isTrue);
      expect(provider.selected, isNotNull); // still has household1
    });

    test('should handle exception during delete', () async {
      when(
        () => mockDb.deleteHousehold(1),
      ).thenThrow(Exception('Delete failed'));

      final result = await provider.delete(1);

      expect(result, isFalse);
      expect(provider.error, contains('Delete failed'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('HouseholdProvider — setSearchQuery / setFilterNeighborhood', () {
    test('setSearchQuery should update search query', () {
      provider.setSearchQuery('test query');
      expect(provider.searchQuery, equals('test query'));
    });

    test('setFilterNeighborhood should update neighborhood filter', () {
      provider.setFilterNeighborhood('Khu phố 2');
      expect(provider.filterNeighborhood, equals('Khu phố 2'));
    });

    test('setFilterNeighborhood should accept null', () {
      provider.setFilterNeighborhood('Khu phố 1');
      expect(provider.filterNeighborhood, isNotNull);

      provider.setFilterNeighborhood(null);
      expect(provider.filterNeighborhood, isNull);
    });
  });

  group('HouseholdProvider — clearSelected()', () {
    test('should clear selected household', () async {
      when(
        () => mockDb.fetchHouseholdById(1),
      ).thenAnswer((_) async => household1);
      await provider.loadById(1);
      expect(provider.selected, isNotNull);

      provider.clearSelected();

      expect(provider.selected, isNull);
    });
  });

  group('HouseholdProvider — searchByPhone()', () {
    test('should return household when found by phone', () async {
      when(
        () => mockDb.fetchHouseholdByPhone('0909123456'),
      ).thenAnswer((_) async => household1);

      final result = await provider.searchByPhone('0909123456');

      expect(result, equals(household1));
    });

    test('should return null on exception', () async {
      when(
        () => mockDb.fetchHouseholdByPhone(any()),
      ).thenThrow(Exception('Not found'));

      final result = await provider.searchByPhone('0909000000');

      expect(result, isNull);
    });

    test('should return null when not found', () async {
      when(
        () => mockDb.fetchHouseholdByPhone('0909000000'),
      ).thenAnswer((_) async => null);

      final result = await provider.searchByPhone('0909000000');

      expect(result, isNull);
    });
  });
}
