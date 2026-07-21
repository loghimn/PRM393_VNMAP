import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification_model.dart';
import '../services/firestore_service.dart';

/// Provider quản lý In-App Notification center
///
/// - Lấy danh sách notification theo userId từ Firestore
/// - Real-time listener để cập nhật badge
/// - Mark as read
class NotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;
  int? _currentUserId;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  /// Số notification chưa đọc
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// 5 notification mới nhất (chưa đọc ưu tiên)
  List<AppNotification> get recentNotifications {
    final sorted = List<AppNotification>.from(_notifications);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  /// Khởi tạo listener khi có userId
  void initialize(int userId) {
    if (_currentUserId == userId) return; // Tránh restart nếu cùng user
    _currentUserId = userId;
    _startListening(userId);
  }

  /// Dọn dẹp khi không cần listener nữa (ví dụ: đăng xuất).
  /// Xóa toàn bộ dữ liệu thông báo để tránh lộ thông tin giữa các tài khoản.
  void disposeListener() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
    _notifications = [];
    _isLoading = false;
    notifyListeners();
  }

  /// Lắng nghe real-time các notification dành cho user này.
  /// Không dùng orderBy để tránh yêu cầu Composite Index trên Firestore.
  /// Sắp xếp và giới hạn được thực hiện in-memory.
  void _startListening(int userId) {
    // Cancel subscription cũ nếu có
    _subscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('target_user_id', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) {
            final all = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = int.tryParse(doc.id) ?? 0;
              return AppNotification.fromJson(data);
            }).toList();

            // Sắp xếp in-memory: mới nhất lên đầu, lấy tối đa 50
            all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _notifications = all.take(50).toList();

            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('NotificationProvider listener error: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Đánh dấu một notification là đã đọc
  Future<void> markAsRead(int notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId.toString())
          .update({'is_read': true});
      // Listener sẽ tự cập nhật lại danh sách
    } catch (e) {
      debugPrint('NotificationProvider.markAsRead error: $e');
    }
  }

  /// Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final notification in _notifications.where((n) => !n.isRead)) {
        final docRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id.toString());
        batch.update(docRef, {'is_read': true});
      }
      await batch.commit();
      // Listener sẽ tự cập nhật
    } catch (e) {
      debugPrint('NotificationProvider.markAllAsRead error: $e');
    }
  }

  /// Xoá một notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId.toString())
          .delete();
      // Listener sẽ tự cập nhật
    } catch (e) {
      debugPrint('NotificationProvider.deleteNotification error: $e');
    }
  }
}
