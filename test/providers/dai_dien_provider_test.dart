import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';
import 'package:vietnam_geo_dashboard/providers/dai_dien_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

// ============================================================
// HELPERS
// ============================================================

DaiDienModel createMockDaiDien({
  int? id,
  String hoTen = 'Nguyễn Văn A',
  String? soDienThoai = '0123456789',
  String? email = 'a@example.com',
  String? diaChi = 'Số 1, Đường ABC',
  int? khuPhoId = 1,
  String? tenKhuPho = 'Khu phố 1',
}) {
  return DaiDienModel(
    id: id,
    hoTen: hoTen,
    soDienThoai: soDienThoai,
    email: email,
    diaChi: diaChi,
    khuPhoId: khuPhoId,
    tenKhuPho: tenKhuPho,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(createMockDaiDien(id: 0));
  });

  late DaiDienProvider provider;
  late MockDatabaseService mockService;

  final mockItem1 = createMockDaiDien(id: 1, hoTen: 'Nguyễn Văn A');
  final mockItem2 = createMockDaiDien(id: 2, hoTen: 'Trần Thị B');
  final mockItems = [mockItem1, mockItem2];

  setUp(() {
    mockService = MockDatabaseService();
    provider = DaiDienProvider(service: mockService);
  });

  group('DaiDienProvider — construction & initial state', () {
    test('should have correct initial state', () {
      expect(provider.danhSach, isEmpty);
      expect(provider.ketQuaTimKiem, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.isSearching, isFalse);
      expect(provider.error, isNull);
    });
  });

  group('DaiDienProvider — loadData()', () {
    test('should load data successfully', () async {
      when(
        () => mockService.fetchDaiDiens(),
      ).thenAnswer((_) async => mockItems);

      await provider.loadData();

      expect(provider.danhSach, equals(mockItems));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('should handle exception during load', () async {
      when(
        () => mockService.fetchDaiDiens(),
      ).thenThrow(Exception('Connection failed'));

      await provider.loadData();

      expect(provider.danhSach, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('Lỗi tải dữ liệu'));
    });

    test('should set loading state correctly', () async {
      late StreamController<List<DaiDienModel>> controller;
      controller = StreamController<List<DaiDienModel>>();

      when(
        () => mockService.fetchDaiDiens(),
      ).thenAnswer((_) => controller.stream.first);

      final future = provider.loadData();

      expect(provider.isLoading, isTrue);

      controller.add(mockItems);
      await controller.close();
      await future;

      expect(provider.isLoading, isFalse);
    });
  });

  group('DaiDienProvider — addDaiDien()', () {
    test('should add successfully', () async {
      when(
        () => mockService.createDaiDien(any()),
      ).thenAnswer((_) async => mockItem1);

      final result = await provider.addDaiDien(mockItem1);

      expect(result, isTrue);
      expect(provider.danhSach, contains(mockItem1));
      verify(() => mockService.createDaiDien(mockItem1)).called(1);
    });

    test('should handle exception on add', () async {
      when(
        () => mockService.createDaiDien(any()),
      ).thenThrow(Exception('Create failed'));

      final result = await provider.addDaiDien(mockItem1);

      expect(result, isFalse);
      expect(provider.error, contains('Lỗi thêm đại diện'));
      expect(provider.danhSach, isEmpty);
    });
  });

  group('DaiDienProvider — updateDaiDien()', () {
    test('should update existing item successfully', () async {
      // First add an item
      provider.setDanhSachForTesting([mockItem1]);

      final updatedItem = createMockDaiDien(
        id: 1,
        hoTen: 'Nguyễn Văn A (Updated)',
      );

      when(
        () => mockService.updateDaiDien(any()),
      ).thenAnswer((_) async => updatedItem);

      final result = await provider.updateDaiDien(updatedItem);

      expect(result, isTrue);
      expect(provider.danhSach.first.hoTen, equals('Nguyễn Văn A (Updated)'));
      verify(() => mockService.updateDaiDien(updatedItem)).called(1);
    });

    test('should work even if item not in list', () async {
      when(
        () => mockService.updateDaiDien(any()),
      ).thenAnswer((_) async => mockItem1);

      final result = await provider.updateDaiDien(mockItem1);

      expect(result, isTrue);
    });

    test('should handle exception on update', () async {
      when(
        () => mockService.updateDaiDien(any()),
      ).thenThrow(Exception('Update failed'));

      final result = await provider.updateDaiDien(mockItem1);

      expect(result, isFalse);
      expect(provider.error, contains('Lỗi cập nhật đại diện'));
    });
  });

  group('DaiDienProvider — deleteDaiDien()', () {
    test('should delete existing item successfully', () async {
      provider.setDanhSachForTesting([mockItem1, mockItem2]);

      when(
        () => mockService.deleteDaiDien(1),
      ).thenAnswer((_) async => Future.value());

      final result = await provider.deleteDaiDien(1);

      expect(result, isTrue);
      expect(provider.danhSach, equals([mockItem2]));
      verify(() => mockService.deleteDaiDien(1)).called(1);
    });

    test('should handle exception on delete', () async {
      when(
        () => mockService.deleteDaiDien(any()),
      ).thenThrow(Exception('Delete failed'));

      final result = await provider.deleteDaiDien(1);

      expect(result, isFalse);
      expect(provider.error, contains('Lỗi xóa đại diện'));
    });
  });

  group('DaiDienProvider — search()', () {
    test('should return empty results for empty query', () async {
      await provider.search('   ');

      expect(provider.ketQuaTimKiem, isEmpty);
      expect(provider.isSearching, isFalse);
    });

    test('should search with non-empty query', () async {
      when(
        () => mockService.searchDaiDiens('Nguyễn'),
      ).thenAnswer((_) async => [mockItem1]);

      await provider.search('Nguyễn');

      expect(provider.ketQuaTimKiem, equals([mockItem1]));
      expect(provider.isSearching, isFalse);
      verify(() => mockService.searchDaiDiens('Nguyễn')).called(1);
    });

    test('should handle exception on search', () async {
      when(
        () => mockService.searchDaiDiens(any()),
      ).thenThrow(Exception('Search error'));

      await provider.search('something');

      expect(provider.ketQuaTimKiem, isEmpty);
      expect(provider.isSearching, isFalse);
      expect(provider.error, contains('Lỗi tìm kiếm đại diện'));
    });

    test('should set searching state correctly', () async {
      late StreamController<List<DaiDienModel>> controller;
      controller = StreamController<List<DaiDienModel>>();

      when(
        () => mockService.searchDaiDiens('test'),
      ).thenAnswer((_) => controller.stream.first);

      final future = provider.search('test');

      expect(provider.isSearching, isTrue);

      controller.add([mockItem1]);
      await controller.close();
      await future;

      expect(provider.isSearching, isFalse);
    });
  });

  group('DaiDienProvider — clearSearch()', () {
    test('should clear search results and searching state', () async {
      when(
        () => mockService.searchDaiDiens('test'),
      ).thenAnswer((_) async => [mockItem1]);

      await provider.search('test');
      expect(provider.ketQuaTimKiem, isNotEmpty);

      provider.clearSearch();

      expect(provider.ketQuaTimKiem, isEmpty);
      expect(provider.isSearching, isFalse);
    });
  });

  group('DaiDienProvider — getById()', () {
    test('should return item by id', () {
      provider.setDanhSachForTesting(mockItems);

      final result = provider.getById(1);

      expect(result, equals(mockItem1));
    });

    test('should return null if id not found', () {
      provider.setDanhSachForTesting(mockItems);

      final result = provider.getById(999);

      expect(result, isNull);
    });

    test('should return null if list is empty', () {
      final result = provider.getById(1);

      expect(result, isNull);
    });
  });
}
