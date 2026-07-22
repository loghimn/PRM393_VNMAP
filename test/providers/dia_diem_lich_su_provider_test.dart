import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';
import 'package:vietnam_geo_dashboard/providers/dia_diem_lich_su_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

// ============================================================
// HELPERS
// ============================================================

DiaDiemLichSu createMockItem({
  int? id,
  String ten = 'Văn Miếu',
  String? loaiDiTich = 'Di tích',
  String? diaChi = 'Hà Nội',
  double? kinhDo = 105.0,
  double? viDo = 21.0,
  String? moTa = 'Mô tả',
  String? thoiKy = 'Lý',
  String? imageUrl,
  String? ghiChu,
}) {
  return DiaDiemLichSu(
    id: id,
    ten: ten,
    loaiDiTich: loaiDiTich,
    diaChi: diaChi,
    kinhDo: kinhDo,
    viDo: viDo,
    moTa: moTa,
    thoiKy: thoiKy,
    imageUrl: imageUrl,
    ghiChu: ghiChu,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(createMockItem(id: 0));
  });

  late DiaDiemLichSuProvider provider;
  late MockDatabaseService mockDb;

  final mockItem1 = createMockItem(id: 1, ten: 'Văn Miếu');
  final mockItem2 = createMockItem(id: 2, ten: 'Hoàng Thành');
  final mockItems = [mockItem1, mockItem2];

  setUp(() {
    mockDb = MockDatabaseService();
    provider = DiaDiemLichSuProvider(db: mockDb);
  });

  group('DiaDiemLichSuProvider — construction & initial state', () {
    test('should have correct initial state', () {
      expect(provider.items, isEmpty);
      expect(provider.selected, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.searchQuery, isEmpty);
    });
  });

  group('DiaDiemLichSuProvider — loadItems()', () {
    test('should load items successfully', () async {
      when(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer((_) async => mockItems);

      await provider.loadItems();

      expect(provider.items, equals(mockItems));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('should load items with search query', () async {
      when(
        () => mockDb.fetchDiaDiemLichSuList(searchQuery: 'Văn'),
      ).thenAnswer((_) async => [mockItem1]);

      await provider.loadItems(searchQuery: 'Văn');

      expect(provider.items, equals([mockItem1]));
      expect(provider.searchQuery, equals('Văn'));
      verify(() => mockDb.fetchDiaDiemLichSuList(searchQuery: 'Văn')).called(1);
    });

    test('should handle exception during load', () async {
      when(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenThrow(Exception('Load failed'));

      await provider.loadItems();

      expect(provider.items, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('Lỗi tải danh sách'));
    });

    test('should set loading state correctly', () async {
      late StreamController<List<DiaDiemLichSu>> controller;
      controller = StreamController<List<DiaDiemLichSu>>();

      when(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer((_) => controller.stream.first);

      final future = provider.loadItems();

      expect(provider.isLoading, isTrue);

      controller.add(mockItems);
      await controller.close();
      await future;

      expect(provider.isLoading, isFalse);
    });
  });

  group('DiaDiemLichSuProvider — loadById()', () {
    test('should load item by id successfully', () async {
      when(
        () => mockDb.fetchDiaDiemLichSuById(1),
      ).thenAnswer((_) async => mockItem1);

      final result = await provider.loadById(1);

      expect(result, equals(mockItem1));
      expect(provider.selected, equals(mockItem1));
      expect(provider.isLoading, isFalse);
    });

    test('should return null when item not found', () async {
      when(
        () => mockDb.fetchDiaDiemLichSuById(999),
      ).thenAnswer((_) async => null);

      final result = await provider.loadById(999);

      expect(result, isNull);
      expect(provider.selected, isNull);
    });

    test('should handle exception during loadById', () async {
      when(
        () => mockDb.fetchDiaDiemLichSuById(1),
      ).thenThrow(Exception('Not found'));

      final result = await provider.loadById(1);

      expect(result, isNull);
      expect(provider.error, contains('Lỗi tải chi tiết'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('DiaDiemLichSuProvider — create()', () {
    test('should create successfully', () async {
      when(
        () => mockDb.createDiaDiemLichSu(any()),
      ).thenAnswer((_) async => mockItem1);
      when(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer((_) async => mockItems);

      final result = await provider.create(mockItem1);

      expect(result, isTrue);
      expect(provider.isLoading, isFalse);
      verify(() => mockDb.createDiaDiemLichSu(mockItem1)).called(1);
      // Should reload items after create
      verify(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).called(1);
    });

    test('should handle exception on create', () async {
      when(
        () => mockDb.createDiaDiemLichSu(any()),
      ).thenThrow(Exception('Create failed'));

      final result = await provider.create(mockItem1);

      expect(result, isFalse);
      expect(provider.error, contains('Lỗi tạo'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('DiaDiemLichSuProvider — update()', () {
    test('should update successfully', () async {
      when(
        () => mockDb.updateDiaDiemLichSu(any()),
      ).thenAnswer((_) async => mockItem1);
      when(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer((_) async => mockItems);

      final result = await provider.update(mockItem1);

      expect(result, isTrue);
      verify(() => mockDb.updateDiaDiemLichSu(mockItem1)).called(1);
      verify(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).called(1);
    });

    test('should update selected item if it matches id', () async {
      provider = DiaDiemLichSuProvider(db: mockDb);

      when(
        () => mockDb.fetchDiaDiemLichSuById(1),
      ).thenAnswer((_) async => mockItem1);
      await provider.loadById(1);
      expect(provider.selected, equals(mockItem1));

      final updatedItem = createMockItem(id: 1, ten: 'Văn Miếu (Updated)');

      when(
        () => mockDb.updateDiaDiemLichSu(any()),
      ).thenAnswer((_) async => updatedItem);
      when(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer((_) async => [updatedItem, mockItem2]);

      final result = await provider.update(updatedItem);

      expect(result, isTrue);
      expect(provider.selected?.ten, equals('Văn Miếu (Updated)'));
    });

    test('should handle exception on update', () async {
      when(
        () => mockDb.updateDiaDiemLichSu(any()),
      ).thenThrow(Exception('Update failed'));

      final result = await provider.update(mockItem1);

      expect(result, isFalse);
      expect(provider.error, contains('Lỗi cập nhật'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('DiaDiemLichSuProvider — delete()', () {
    test('should delete successfully', () async {
      when(
        () => mockDb.deleteDiaDiemLichSu(1),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer((_) async => [mockItem2]);

      final result = await provider.delete(1);

      expect(result, isTrue);
      verify(() => mockDb.deleteDiaDiemLichSu(1)).called(1);
      verify(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).called(1);
    });

    test('should clear selected item if deleted matches', () async {
      when(
        () => mockDb.fetchDiaDiemLichSuById(1),
      ).thenAnswer((_) async => mockItem1);
      await provider.loadById(1);
      expect(provider.selected, equals(mockItem1));

      when(
        () => mockDb.deleteDiaDiemLichSu(1),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockDb.fetchDiaDiemLichSuList(
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer((_) async => [mockItem2]);

      await provider.delete(1);

      expect(provider.selected, isNull);
    });

    test('should handle exception on delete', () async {
      when(
        () => mockDb.deleteDiaDiemLichSu(1),
      ).thenThrow(Exception('Delete failed'));

      final result = await provider.delete(1);

      expect(result, isFalse);
      expect(provider.error, contains('Lỗi xóa'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('DiaDiemLichSuProvider — clearSelected()', () {
    test('should clear selected item', () async {
      when(
        () => mockDb.fetchDiaDiemLichSuById(1),
      ).thenAnswer((_) async => mockItem1);
      await provider.loadById(1);
      expect(provider.selected, isNotNull);

      provider.clearSelected();

      expect(provider.selected, isNull);
    });

    test('should be safe to call when selected is already null', () {
      expect(provider.selected, isNull);

      provider.clearSelected();

      expect(provider.selected, isNull);
    });
  });
}
