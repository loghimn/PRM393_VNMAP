import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/app_notification_model.dart';

/// Panel danh sách thông báo dạng Bottom Sheet
///
/// Hiển thị khi bấm vào icon chuông 🔔
class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),
          // Divider
          const Divider(height: 1, thickness: 1),
          // Danh sách notification
          Expanded(child: _buildNotificationList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.notifications, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Thông báo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (provider.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Nút "Đã đọc tất cả"
              if (provider.unreadCount > 0)
                TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text(
                    'Đã đọc tất cả',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationList(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có thông báo nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Sắp xếp: mới nhất lên trên
        final sorted = List<AppNotification>.from(provider.notifications);
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sorted.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72, endIndent: 16),
          itemBuilder: (context, index) {
            final notification = sorted[index];
            return _buildNotificationItem(context, notification, provider);
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) {
    return InkWell(
      onTap: () {
        // Đánh dấu đã đọc
        if (!notification.isRead) {
          provider.markAsRead(notification.id!);
        }
        // TODO: Điều hướng đến màn hình chi tiết
        // Nếu là notification về incident → mở IncidentDetailScreen
        // Nếu là notification về household request → mở RequestDetailScreen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.isRead
            ? Colors.white
            : Colors.blue.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getIconBgColor(notification.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  notification.iconEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Body
                  Text(
                    notification.body,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Thời gian
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            // Dấu chấm chưa đọc
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'incident_created':
      case 'incident_updated':
      case 'incident_deleted':
      case 'incident_status_changed':
        return Colors.orange.withOpacity(0.1);
      case 'request_created':
      case 'request_approved':
      case 'request_rejected':
        return Colors.blue.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
