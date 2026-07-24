import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/app_notification_model.dart';
import 'package:vietnam_geo_dashboard/widgets/notification/notification_bell.dart';
import '../screens/test_helpers/widget_test_utils.dart';
import '../screens/test_helpers/mock_providers.dart';

void main() {
  group('NotificationBell', () {
    testWidgets('hiển thị icon chuông', (tester) async {
      await tester.pumpScreen(const Scaffold(body: NotificationBell()));

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('hiển thị badge khi có unread', (tester) async {
      final provider = FakeNotificationProvider();
      provider.addNotification(_createNotification(id: 1, isRead: false));

      await tester.pumpScreen(
        const Scaffold(body: NotificationBell()),
        overrides: ProviderOverrides(notification: provider),
      );

      // Badge hiển thị
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('không hiển thị badge khi unreadCount = 0', (tester) async {
      await tester.pumpScreen(const Scaffold(body: NotificationBell()));

      // Text '0' không xuất hiện (badge không render)
      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('badge hiển thị "99+" khi unread > 99', (tester) async {
      final provider = FakeNotificationProvider();
      // Thêm 100 notifications chưa đọc
      for (int i = 1; i <= 100; i++) {
        provider.addNotification(_createNotification(id: i, isRead: false));
      }

      await tester.pumpScreen(
        const Scaffold(body: NotificationBell()),
        overrides: ProviderOverrides(notification: provider),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('bấm chuông mở NotificationPanel dạng bottom sheet', (
      tester,
    ) async {
      await tester.pumpScreen(const Scaffold(body: NotificationBell()));

      // Bấm icon chuông
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Bottom sheet hiển thị với header "Thông báo"
      expect(find.text('Thông báo'), findsOneWidget);
    });
  });
}

/// Helper tạo AppNotification mẫu
AppNotification _createNotification({
  required int id,
  bool isRead = false,
  String type = 'incident_created',
  String title = 'Thông báo mới',
  String body = 'Nội dung thông báo',
}) {
  return AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead,
    targetUserId: 1,
    actorUserId: 2,
    relatedId: 100,
    relatedCode: 'SV-001',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    updatedAt: DateTime.now(),
  );
}
