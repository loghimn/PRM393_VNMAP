import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:vietnam_geo_dashboard/services/storage_service.dart';
import 'mock_helper.dart';

void main() {
  late MockFirebaseStorage mockStorage;
  late MockReference mockRootRef;
  late MockReference mockPathRef;
  late MockListResult mockListResult;
  late StorageService service;

  setUpAll(() {
    registerServiceFallbackValues();
  });

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockRootRef = MockReference();
    mockPathRef = MockReference();
    mockListResult = MockListResult();
    service = createTestStorageService(storage: mockStorage);

    when(() => mockStorage.ref()).thenReturn(mockRootRef);
    when(() => mockRootRef.child(any())).thenReturn(mockPathRef);
  });

  group('StorageService — Delete file', () {
    test('deleteFile gọi refFromURL + delete()', () async {
      when(() => mockStorage.refFromURL(any())).thenReturn(mockPathRef);
      when(() => mockPathRef.delete()).thenAnswer((_) async {});

      await service.deleteFile('https://fake.url/photo.jpg');

      verify(
        () => mockStorage.refFromURL('https://fake.url/photo.jpg'),
      ).called(1);
      verify(() => mockPathRef.delete()).called(1);
    });

    test('deleteFile không throw khi delete thất bại', () async {
      when(() => mockStorage.refFromURL(any())).thenReturn(mockPathRef);
      when(() => mockPathRef.delete()).thenThrow(Exception('network error'));

      // Không throw
      await service.deleteFile('https://fake.url/photo.jpg');

      verify(() => mockPathRef.delete()).called(1);
    });

    test('deleteFiles xoá nhiều file', () async {
      when(() => mockStorage.refFromURL(any())).thenReturn(mockPathRef);
      when(() => mockPathRef.delete()).thenAnswer((_) async {});

      final urls = [
        'https://fake.url/1.jpg',
        'https://fake.url/2.jpg',
        'https://fake.url/3.jpg',
      ];

      await service.deleteFiles(urls);

      verify(() => mockStorage.refFromURL(any())).called(urls.length);
      verify(() => mockPathRef.delete()).called(urls.length);
    });

    test('deleteFolder xoá thư mục rỗng', () async {
      // listAll trả về items rỗng, prefixes rỗng
      when(() => mockPathRef.listAll()).thenAnswer((_) async {
        when(() => mockListResult.items).thenReturn([]);
        when(() => mockListResult.prefixes).thenReturn([]);
        return mockListResult;
      });

      await service.deleteFolder('empty-folder');

      verify(() => mockRootRef.child('empty-folder')).called(1);
      verify(() => mockPathRef.listAll()).called(1);
    });

    test('deleteFolder xoá thư mục có nhiều file', () async {
      final mockItem1 = MockReference();
      final mockItem2 = MockReference();
      when(() => mockItem1.delete()).thenAnswer((_) async {});
      when(() => mockItem2.delete()).thenAnswer((_) async {});

      when(() => mockPathRef.listAll()).thenAnswer((_) async {
        when(() => mockListResult.items).thenReturn([mockItem1, mockItem2]);
        when(() => mockListResult.prefixes).thenReturn([]);
        return mockListResult;
      });

      await service.deleteFolder('folder-with-files');

      verify(() => mockItem1.delete()).called(1);
      verify(() => mockItem2.delete()).called(1);
    });

    test('deleteFolder xoá thư mục có subfolder (đệ quy)', () async {
      final mockSubfolderRef = MockReference();
      final mockSubItem = MockReference();
      when(() => mockSubfolderRef.child(any())).thenReturn(mockSubfolderRef);
      when(() => mockSubfolderRef.listAll()).thenAnswer((_) async {
        when(() => mockListResult.items).thenReturn([mockSubItem]);
        when(() => mockListResult.prefixes).thenReturn([]);
        return mockListResult;
      });
      when(() => mockSubItem.delete()).thenAnswer((_) async {});

      // Lần 1: folder gốc có 1 subfolder
      final mockSubfolderPrefix = MockReference();
      when(() => mockSubfolderPrefix.fullPath).thenReturn('folder/sub');

      // Mock listAll cho root folder
      when(() => mockPathRef.listAll()).thenAnswer((_) async {
        final subListResult = MockListResult();
        when(() => subListResult.items).thenReturn([]);
        when(() => subListResult.prefixes).thenReturn([mockSubfolderPrefix]);
        return subListResult;
      });

      // Mock child('folder/sub') trả về subfolderRef
      when(() => mockRootRef.child('folder/sub')).thenReturn(mockSubfolderRef);
      // Mock listAll cho subfolder trả về mockSubItem
      when(() => mockSubfolderRef.listAll()).thenAnswer((_) async {
        final subListResult = MockListResult();
        when(() => subListResult.items).thenReturn([mockSubItem]);
        when(() => subListResult.prefixes).thenReturn([]);
        return subListResult;
      });

      await service.deleteFolder('folder');

      verify(() => mockSubItem.delete()).called(1);
    });

    test('deleteFolder không throw khi listAll thất bại', () async {
      when(
        () => mockPathRef.listAll(),
      ).thenThrow(Exception('permission denied'));

      // Không throw
      await service.deleteFolder('restricted-folder');

      verify(() => mockPathRef.listAll()).called(1);
    });
  });
}
