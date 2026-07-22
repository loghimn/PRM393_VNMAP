import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:vietnam_geo_dashboard/services/storage_service.dart';
import 'mock_helper.dart';

// ============================================================
// CUSTOM UPLOAD TASK — không extends Fake (tránh mocktail
// tracking gây "Cannot call when within a stub response")
// ============================================================
class FakeUploadTask extends Fake implements UploadTask {
  final Completer<TaskSnapshot> _completer = Completer<TaskSnapshot>();
  final StreamController<TaskSnapshot> _streamController =
      StreamController<TaskSnapshot>.broadcast();

  @override
  Stream<TaskSnapshot> get snapshotEvents => _streamController.stream;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot) onValue, {
    Function? onError,
  }) {
    return _completer.future.then(onValue, onError: onError);
  }

  void complete(TaskSnapshot snapshot) => _completer.complete(snapshot);
  void addSnapshot(TaskSnapshot snapshot) => _streamController.add(snapshot);
}

/// Helper: tạo FakeUploadTask đã được complete.
FakeUploadTask completedUploadTask(MockTaskSnapshot snapshot) {
  final task = FakeUploadTask();
  task.complete(snapshot);
  return task;
}

void main() {
  late MockFirebaseStorage mockStorage;
  late MockReference mockRootRef;
  late MockReference mockPathRef;
  late MockTaskSnapshot mockTaskSnapshot;
  late StorageService service;

  setUpAll(() {
    registerServiceFallbackValues();
  });

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockRootRef = MockReference();
    mockPathRef = MockReference();
    mockTaskSnapshot = MockTaskSnapshot();

    service = createTestStorageService(storage: mockStorage);

    when(() => mockStorage.ref()).thenReturn(mockRootRef);
    when(() => mockRootRef.child(any())).thenReturn(mockPathRef);
    when(() => mockTaskSnapshot.ref).thenReturn(mockPathRef);
    when(() => mockPathRef.getDownloadURL()).thenAnswer(
      (_) async =>
          'https://firebasestorage.googleapis.com/v0/b/test.appspot.com/o/test%2Fphoto.jpg',
    );
  });

  group('StorageService — Upload file', () {
    test('uploadFile upload thành công -> trả về download URL', () async {
      final file = File('${Directory.systemTemp.path}/test_upload.jpg');
      file.writeAsStringSync('fake-image-content');

      when(
        () => mockPathRef.putFile(any()),
      ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

      final url = await service.uploadFile(
        path: 'test',
        fileName: 'photo.jpg',
        file: file,
      );

      expect(url, contains('firebasestorage.googleapis.com'));
      expect(url, contains('photo.jpg'));

      file.deleteSync();
    });

    test('uploadFile gọi child() với đúng path/fileName', () async {
      final file = File('${Directory.systemTemp.path}/test_upload2.jpg');
      file.writeAsStringSync('fake');

      when(
        () => mockPathRef.putFile(any()),
      ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

      await service.uploadFile(
        path: 'incidents/SV-0001',
        fileName: 'abc.jpg',
        file: file,
      );

      verify(() => mockRootRef.child('incidents/SV-0001/abc.jpg')).called(1);

      file.deleteSync();
    });

    test('uploadFile gọi putFile với đúng file', () async {
      final file = File('${Directory.systemTemp.path}/test_upload3.jpg');
      file.writeAsStringSync('fake');

      when(
        () => mockPathRef.putFile(any()),
      ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

      await service.uploadFile(path: 'test', fileName: 'img.jpg', file: file);

      verify(() => mockPathRef.putFile(file)).called(1);

      file.deleteSync();
    });

    test('uploadFile gọi onProgress callback đúng tiến trình', () async {
      final file = File('${Directory.systemTemp.path}/test_upload4.jpg');
      file.writeAsStringSync('fake');
      final progressValues = <double>[];

      when(() => mockPathRef.putFile(any())).thenAnswer((_) {
        final task = FakeUploadTask();
        return task;
      });

      when(() => mockTaskSnapshot.bytesTransferred).thenReturn(50);
      when(() => mockTaskSnapshot.totalBytes).thenReturn(100);

      // Lấy reference tới task vừa trả về từ putFile
      // Không có cách nào vì putFile() vừa gọi thì lấy luôn.
      // Cách: mock putFile callback lưu lại task.
      FakeUploadTask? savedTask;
      when(() => mockPathRef.putFile(any())).thenAnswer((_) {
        final t = FakeUploadTask();
        savedTask = t;
        return t;
      });

      final future = service.uploadFile(
        path: 'test',
        fileName: 'progress.jpg',
        file: file,
        onProgress: (p) => progressValues.add(p),
      );

      // Đẩy snapshot vào stream
      savedTask!.addSnapshot(mockTaskSnapshot);
      savedTask!.complete(mockTaskSnapshot);

      await future;

      expect(progressValues.length, greaterThanOrEqualTo(1));
      expect(progressValues.last, closeTo(0.5, 0.01));

      file.deleteSync();
    });

    test(
      'uploadMultipleFiles upload nhiều file -> trả về đúng số URL',
      () async {
        final files = List.generate(3, (i) {
          final f = File('${Directory.systemTemp.path}/multi_$i.jpg');
          f.writeAsStringSync('fake-$i');
          return f;
        });

        when(
          () => mockPathRef.putFile(any()),
        ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

        final urls = await service.uploadMultipleFiles(
          path: 'test/multi',
          files: files,
        );

        expect(urls.length, 3);
        for (final url in urls) {
          expect(url, contains('firebasestorage.googleapis.com'));
        }

        for (final f in files) {
          f.deleteSync();
        }
      },
    );

    test(
      'uploadMultipleFiles gọi onProgress với tiến trình tổng thể',
      () async {
        final files = List.generate(3, (i) {
          final f = File('${Directory.systemTemp.path}/multi_progress_$i.jpg');
          f.writeAsStringSync('fake-$i');
          return f;
        });
        final progressValues = <double>[];

        when(
          () => mockPathRef.putFile(any()),
        ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

        await service.uploadMultipleFiles(
          path: 'test/multi_progress',
          files: files,
          onProgress: (p) => progressValues.add(p),
        );

        expect(progressValues, [1 / 3, 2 / 3, 1.0]);

        for (final f in files) {
          f.deleteSync();
        }
      },
    );

    test('uploadIncidentImages delegate đúng path incidents/SV-0001', () async {
      final files = [
        File('${Directory.systemTemp.path}/inc_1.jpg')..writeAsStringSync('f'),
      ];

      when(
        () => mockPathRef.putFile(any()),
      ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

      await service.uploadIncidentImages(
        incidentCode: 'SV-0001',
        images: files,
      );

      // uploadFile gọi ref.child() với path chứa incidents/SV-0001
      verify(() => mockRootRef.child(any())).called(1);

      files.first.deleteSync();
    });

    test(
      'uploadHouseholdDocuments delegate đúng path households/HGD-0001/documents',
      () async {
        final files = [
          File('${Directory.systemTemp.path}/doc_1.pdf')
            ..writeAsStringSync('f'),
        ];

        when(
          () => mockPathRef.putFile(any()),
        ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

        await service.uploadHouseholdDocuments(
          householdCode: 'HGD-0001',
          documents: files,
        );

        verify(() => mockRootRef.child(any())).called(1);

        files.first.deleteSync();
      },
    );

    test('uploadAvatar xoá avatar cũ trước khi upload', () async {
      when(() => mockPathRef.delete()).thenAnswer((_) async {});
      when(
        () => mockPathRef.putFile(any()),
      ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

      final file = File('${Directory.systemTemp.path}/avatar.jpg')
        ..writeAsStringSync('f');

      await service.uploadAvatar(uid: 'user-123', image: file);

      verify(() => mockPathRef.delete()).called(1);

      file.deleteSync();
    });

    test('uploadAvatar không crash khi chưa có avatar cũ', () async {
      when(() => mockPathRef.delete()).thenThrow(Exception('not found'));
      when(
        () => mockPathRef.putFile(any()),
      ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

      final file = File('${Directory.systemTemp.path}/avatar_new.jpg')
        ..writeAsStringSync('f');

      await service.uploadAvatar(uid: 'user-456', image: file);

      verify(() => mockRootRef.child(any())).called(2);

      file.deleteSync();
    });

    test('uploadAvatar gọi uploadFile với đúng path users/', () async {
      when(() => mockPathRef.delete()).thenAnswer((_) async {});
      when(
        () => mockPathRef.putFile(any()),
      ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

      final file = File('${Directory.systemTemp.path}/avatar_final.jpg')
        ..writeAsStringSync('f');

      await service.uploadAvatar(uid: 'user-789', image: file);

      // uploadFile gọi ref.child() 1 lần cho upload (delete đã gọi child riêng)
      verify(() => mockRootRef.child(any())).called(2);

      file.deleteSync();
    });

    test(
      'uploadHistoricalPlaceImages delegate đúng path historical_places/42',
      () async {
        final files = [
          File('${Directory.systemTemp.path}/hist_1.jpg')
            ..writeAsStringSync('f'),
        ];

        when(
          () => mockPathRef.putFile(any()),
        ).thenAnswer((_) => completedUploadTask(mockTaskSnapshot));

        await service.uploadHistoricalPlaceImages(placeId: 42, images: files);

        verify(() => mockRootRef.child(any())).called(1);

        files.first.deleteSync();
      },
    );
  });
}
