import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service quản lý upload/download file trên Firebase Storage.
///
/// Singleton pattern, tương tự FirestoreService.
/// Hỗ trợ upload ảnh cho: Incident, Household, User, DiaDiemLichSu.
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ===================================================================
  // PUBLIC METHODS
  // ===================================================================

  /// Upload một file, trả về download URL.
  ///
  /// [path] Đường dẫn thư mục trong bucket (VD: `incidents/SV-0001`)
  /// [fileName] Tên file (VD: `1712345678_photo.jpg`)
  /// [file] File cần upload
  /// [onProgress] Callback báo % tiến trình (0.0 - 1.0)
  Future<String> uploadFile({
    required String path,
    required String fileName,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child('$path/$fileName');
    final task = ref.putFile(file);

    // Theo dõi tiến trình nếu có callback
    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await task;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Upload nhiều file cùng lúc, trả về danh sách download URL.
  ///
  /// Mỗi file được đặt tên theo timestamp + tên gốc để tránh trùng.
  Future<List<String>> uploadMultipleFiles({
    required String path,
    required List<File> files,
    void Function(double progress)? onProgress,
  }) async {
    final urls = <String>[];
    final totalFiles = files.length;
    int completed = 0;

    for (final file in files) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.uri.pathSegments.last}';
      final url = await uploadFile(
        path: path,
        fileName: fileName,
        file: file,
        onProgress: totalFiles == 1 ? onProgress : null,
      );
      urls.add(url);
      completed++;
      if (onProgress != null && totalFiles > 1) {
        onProgress(completed / totalFiles);
      }
    }

    return urls;
  }

  /// Upload ảnh sự vụ (Incident)
  Future<List<String>> uploadIncidentImages({
    required String incidentCode,
    required List<File> images,
    void Function(double progress)? onProgress,
  }) async {
    return uploadMultipleFiles(
      path: 'incidents/$incidentCode',
      files: images,
      onProgress: onProgress,
    );
  }

  /// Upload giấy tờ hộ khẩu (Household)
  Future<List<String>> uploadHouseholdDocuments({
    required String householdCode,
    required List<File> documents,
    void Function(double progress)? onProgress,
  }) async {
    return uploadMultipleFiles(
      path: 'households/$householdCode/documents',
      files: documents,
      onProgress: onProgress,
    );
  }

  /// Upload avatar người dùng (sẽ ghi đè nếu đã có)
  Future<String> uploadAvatar({
    required String uid,
    required File image,
    void Function(double progress)? onProgress,
  }) async {
    // Xoá avatar cũ nếu có
    try {
      final oldRef = _storage.ref().child('users/$uid/avatar');
      await oldRef.delete();
    } catch (_) {
      // Chưa có avatar cũ -> ignore
    }

    return uploadFile(
      path: 'users/$uid',
      fileName: 'avatar.jpg',
      file: image,
      onProgress: onProgress,
    );
  }

  /// Upload ảnh địa điểm lịch sử
  Future<List<String>> uploadHistoricalPlaceImages({
    required int placeId,
    required List<File> images,
    void Function(double progress)? onProgress,
  }) async {
    return uploadMultipleFiles(
      path: 'historical_places/$placeId',
      files: images,
      onProgress: onProgress,
    );
  }

  /// Xoá một file theo download URL.
  /// Dùng [Reference.delete()] để xoá trên Storage.
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('StorageService.deleteFile error: $e');
    }
  }

  /// Xoá nhiều file theo danh sách download URL.
  Future<void> deleteFiles(List<String> urls) async {
    for (final url in urls) {
      await deleteFile(url);
    }
  }

  /// Xoá toàn bộ thư mục (dùng khi xoá incident/household)
  Future<void> deleteFolder(String prefix) async {
    try {
      final ref = _storage.ref().child(prefix);
      final result = await ref.listAll();
      for (final item in result.items) {
        await item.delete();
      }
      for (final subfolder in result.prefixes) {
        await deleteFolder(subfolder.fullPath);
      }
    } catch (e) {
      print('StorageService.deleteFolder error: $e');
    }
  }
}
