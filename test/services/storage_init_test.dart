import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:vietnam_geo_dashboard/services/storage_service.dart';
import 'mock_helper.dart';

void main() {
  setUpAll(() {
    registerServiceFallbackValues();
  });

  group('StorageService — Khởi tạo', () {
    test('StorageService.instance trả về singleton', () {
      final instance1 = StorageService.instance;
      final instance2 = StorageService.instance;

      expect(instance1, same(instance2));
    });

    test('createTestInstance() tạo instance với storage mock', () {
      final mockStorage = MockFirebaseStorage();
      final service = createTestStorageService(storage: mockStorage);

      expect(service, isA<StorageService>());
      // Không throw khi khởi tạo
    });

    test('createTestInstance() dùng MockFirebaseStorage mặc định', () {
      final service = createTestStorageService();

      expect(service, isA<StorageService>());
    });

    test('instance và createTestInstance là khác nhau', () {
      final singleton = StorageService.instance;
      final testService = createTestStorageService(
        storage: MockFirebaseStorage(),
      );

      expect(singleton, isNot(same(testService)));
    });
  });
}
