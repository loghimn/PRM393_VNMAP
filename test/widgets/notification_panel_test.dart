import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/app_notification_model.dart';
import 'package:vietnam_geo_dashboard/widgets/notification/notification_panel.dart';
import '../screens/test_helpers/widget_test_utils.dart';
import '../screens/test_helpers/mock_providers.dart';

void main() {
  group('NotificationPanel', () {
    testWidgets('hiển thị header với title "Thông báo"', (tester) async {
      await tester.pumpScreen(const Scaffold(body: NotificationPanel()));

      // Header
      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('hiển thị badge unread count trong header', (tester) async {
      final provider = FakeNotificationProvider();
      provider.addNotification(_createNotification(id: 1, isRead: false));
      provider.addNotification(_createNotification(id: 2, isRead: false));

      await tester.pumpScreen(
        const Scaffold(body: NotificationPanel()),
        overrides: ProviderOverrides(notification: provider),
      );

      // Badge hiển thị số unread
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('bấm "Đã đọc tất cả" gọi markAllAsRead', (tester) async {
      final provider = FakeNotificationProvider();
      provider.addNotification(_createNotification(id: 1, isRead: false));
      provider.addNotification(_createNotification(id: 2, isRead: false));

      await tester.pumpScreen(
        const Scaffold(body: NotificationPanel()),
        overrides: ProviderOverrides(notification: provider),
      );

      // Bấm "Đã đọc tất cả"
      await tester.tap(find.text('Đã đọc tất cả'));
      await tester.pumpAndSettle();

      // Tất cả đã đọc → badge biến mất
      expect(find.text('2'), findsNothing);
    });

    testWidgets('không hiển thị nút "Đã đọc tất cả" khi unread = 0', (
      tester,
    ) async {
      await tester.pumpScreen(const Scaffold(body: NotificationPanel()));

      expect(find.text('Đã đọc tất cả'), findsNothing);
    });

    group('empty state', () {
      testWidgets('hiển thị khi danh sách rỗng', (tester) async {
        await tester.pumpScreen(const Scaffold(body: NotificationPanel()));

        expect(find.text('Chưa có thông báo nào'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      });
    });

    group('loading state', () {
      testWidgets('hiển thị CircularProgressIndicator khi isLoading', (
        tester,
      ) async {
        final provider = FakeNotificationProvider();
        provider.isLoading = true;

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Không hiển thị empty state
        expect(find.text('Chưa có thông báo nào'), findsNothing);
      });
    });

    group('danh sách notifications', () {
      testWidgets('hiển thị title, body, icon emoji', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(
          _createNotification(
            id: 1,
            title: 'Sự cố mới',
            body: 'Đã có báo cáo sự cố tại khu phố 3',
            type: 'incident_created',
            isRead: true,
          ),
        );

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        expect(find.text('Sự cố mới'), findsOneWidget);
        expect(find.text('Đã có báo cáo sự cố tại khu phố 3'), findsOneWidget);
        // Icon emoji 🆕
        expect(find.text('🆕'), findsOneWidget);
      });

      testWidgets('hiển thị thời gian "5 phút trước"', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(
          _createNotification(
            id: 1,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: true,
          ),
        );

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        expect(find.text('5 phút trước'), findsOneWidget);
      });

      testWidgets('hiển thị thời gian "Vừa xong"', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(
          _createNotification(id: 1, createdAt: DateTime.now(), isRead: true),
        );

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        expect(find.text('Vừa xong'), findsOneWidget);
      });

      testWidgets('hiển thị thời gian "1 giờ trước"', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(
          _createNotification(
            id: 1,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            isRead: true,
          ),
        );

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        expect(find.text('1 giờ trước'), findsOneWidget);
      });

      testWidgets('hiển thị thời gian "2 ngày trước"', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(
          _createNotification(
            id: 1,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            isRead: true,
          ),
        );

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        expect(find.text('2 ngày trước'), findsOneWidget);
      });

      testWidgets('có dấu chấm xanh cho item chưa đọc', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(_createNotification(id: 1, isRead: false));

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        // Dấu chấm xanh là Container có decoration màu xanh
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == Colors.blue,
          ),
          findsOneWidget,
        );
      });

      testWidgets('không có dấu chấm xanh cho item đã đọc', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(_createNotification(id: 1, isRead: true));

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        // Không tìm thấy Container màu xanh nào
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == Colors.blue,
          ),
          findsNothing,
        );
      });

      testWidgets('tap item gọi markAsRead', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(_createNotification(id: 42, isRead: false));

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        // Tap vào notification item
        await tester.tap(find.text('Thông báo mới'));
        await tester.pumpAndSettle();

        // Notification id 42 đã đọc
        final notif = provider.notifications.firstWhere((n) => n.id == 42);
        expect(notif.isRead, isTrue);
      });

      testWidgets('không gọi markAsRead nếu item đã đọc', (tester) async {
        final provider = FakeNotificationProvider();
        provider.addNotification(_createNotification(id: 1, isRead: true));

        await tester.pumpScreen(
          const Scaffold(body: NotificationPanel()),
          overrides: ProviderOverrides(notification: provider),
        );

        await tester.tap(find.text('Thông báo mới'));
        await tester.pumpAndSettle();

        // Vẫn đọc
        final notif = provider.notifications.firstWhere((n) => n.id == 1);
        expect(notif.isRead, isTrue);
      });
    });
  });
}

/// Helper tạo AppNotification mẫu cho test
AppNotification _createNotification({
  required int id,
  bool isRead = false,
  String type = 'incident_created',
  String title = 'Thông báo mới',
  String body = 'Nội dung thông báo',
  DateTime? createdAt,
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
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(minutes: 5)),
    updatedAt: DateTime.now(),
  );
}
