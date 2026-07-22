import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/providers/khu_pho_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

// ============================================================
// HELPERS
// ============================================================

KhuPhoModel createKhuPho({
  int? id = 1,
  String tenKhuPho = 'Khu phố 1',
  String? moTa,
  String? diaChi,
  String? parentTen,
}) {
  return KhuPhoModel(
    id: id,
    tenKhuPho: tenKhuPho,
    moTa: moTa,
    diaChi: diaChi,
    parentTen: parentTen,
  );
}

void main() {
  late KhuPhoProvider provider;
  late MockDatabaseService mockDb;

  final kp1 = createKhuPho(id: 1, tenKhuPho: 'Khu phố 1');
  final kp2 = createKhuPho(id: 2, tenKhuPho: 'Khu phố 2');

  List<KhuPhoModel> allKhuPhos() => [kp1, kp2];

  setUpAll(() {
    registerFallbackValue(createKhuPho());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    provider = KhuPhoProvider(databaseService: mockDb);
    reset(mockDb);
  });

  group('initial state', () {
    test('should have correct initial state', () {
      expect(provider.danhSach, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });
  });

  group('loadData()', () {
    test('should load data successfully', () async {
      final data = allKhuPhos();
      when(() => mockDb.fetchKhuPhos()).thenAnswer((_) async => data);

      await provider.loadData();

      expect(provider.danhSach, equals(data));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });
  });

  group('addKhuPho()', () {
    test('should add khu pho successfully', () async {
      when(() => mockDb.createKhuPho(kp1)).thenAnswer((_) async => kp1);

      final result = await provider.addKhuPho(kp1);

      expect(result, isTrue);
      expect(provider.danhSach, contains(kp1));
      verify(() => mockDb.createKhuPho(kp1)).called(1);
    });

    test('should handle exception during addKhuPho', () async {
      when(
        () => mockDb.createKhuPho(any()),
      ).thenThrow(Exception('Create failed'));

      final result = await provider.addKhuPho(kp1);

      expect(result, isFalse);
      expect(provider.error, contains('Create failed'));
    });
  });

  group('updateKhuPho()', () {
    test('should update existing khu pho successfully', () async {
      final data = allKhuPhos();
      when(() => mockDb.fetchKhuPhos()).thenAnswer((_) async => data);
      await provider.loadData();
      expect(provider.danhSach.length, equals(2));

      final updated = createKhuPho(id: 1, tenKhuPho: 'Khu phố 1 (updated)');
      when(() => mockDb.updateKhuPho(updated)).thenAnswer((_) async => updated);

      final result = await provider.updateKhuPho(updated);

      expect(result, isTrue);
      expect(provider.danhSach[0].tenKhuPho, equals('Khu phố 1 (updated)'));
    });

    test('should handle exception during updateKhuPho', () async {
      when(
        () => mockDb.updateKhuPho(any()),
      ).thenThrow(Exception('Update failed'));

      final result = await provider.updateKhuPho(kp1);

      expect(result, isFalse);
      expect(provider.error, contains('Update failed'));
    });
  });

  group('deleteKhuPho()', () {
    test('should delete existing khu pho successfully', () async {
      final data = allKhuPhos();
      when(() => mockDb.fetchKhuPhos()).thenAnswer((_) async => data);
      await provider.loadData();
      expect(provider.danhSach.length, equals(2));

      when(
        () => mockDb.deleteKhuPho(1),
      ).thenAnswer((_) async => Future.value());

      final result = await provider.deleteKhuPho(1);

      expect(result, isTrue);
      expect(provider.danhSach, equals([kp2]));
    });

    test('should handle exception during deleteKhuPho', () async {
      when(() => mockDb.deleteKhuPho(1)).thenThrow(Exception('Delete failed'));

      final result = await provider.deleteKhuPho(1);

      expect(result, isFalse);
      expect(provider.error, contains('Delete failed'));
    });
  });

  group('getById()', () {
    test('should return item by id', () async {
      final data = allKhuPhos();
      when(() => mockDb.fetchKhuPhos()).thenAnswer((_) async => data);
      await provider.loadData();

      expect(provider.danhSach.length, equals(2));

      final result = provider.getById(1);

      expect(result, isNotNull);
      expect(result!.id, equals(1));
    });

    test('should return null if id not found', () async {
      final data = allKhuPhos();
      when(() => mockDb.fetchKhuPhos()).thenAnswer((_) async => data);
      await provider.loadData();

      final result = provider.getById(99);

      expect(result, isNull);
    });

    test('should return null if list is empty', () async {
      final result = provider.getById(1);

      expect(result, isNull);
    });
  });
}
