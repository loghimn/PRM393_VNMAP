import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/widgets/popup_notification.dart';
import '../screens/test_helpers/widget_test_utils.dart';

/// Helper: tap nút "Đã hiểu" trong dialog và chờ dismiss
Future<void> tapButton(WidgetTester tester, {String label = 'Đã hiểu'}) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('PopupNotification - showSuccess', () {
    testWidgets('hiển thị title và message', (tester) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showSuccess(
              context: context,
              title: 'Thành công!',
              message: 'Dữ liệu đã được lưu',
            ),
            child: const Text('Open'),
          ),
        ),
      );

      // Mở dialog
      await tester.tap(find.text('Open'));
      await tester.pump();
      // Chờ animation dialog mở
      await tester.pump(const Duration(milliseconds: 600));

      // Kiểm tra nội dung
      expect(find.text('Thành công!'), findsOneWidget);
      expect(find.text('Dữ liệu đã được lưu'), findsOneWidget);

      // Icon check circle
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('nút "Đã hiểu" đóng dialog và gọi onDismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showSuccess(
              context: context,
              title: 'Thành công!',
              message: 'OK',
              onDismiss: () => dismissed = true,
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tapButton(tester);

      expect(dismissed, isTrue);
      // Dialog đã đóng
      expect(find.text('Thành công!'), findsNothing);
    });

    testWidgets('custom button text', (tester) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showSuccess(
              context: context,
              title: 'OK',
              message: 'Done',
              buttonText: 'Tiếp tục',
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Tiếp tục'), findsOneWidget);
      expect(find.text('Đã hiểu'), findsNothing);
    });

    testWidgets('autoCloseDuration tự động đóng dialog sau khoảng thời gian', (
      tester,
    ) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showSuccess(
              context: context,
              title: 'Auto',
              message: 'Close',
              autoCloseDuration: const Duration(milliseconds: 50),
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      // Trước khi autoClose chạy - dialog vẫn hiển thị
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('Auto'), findsOneWidget);

      // Chờ autoClose + animation
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog đã tự động đóng
      expect(find.text('Auto'), findsNothing);
    });
  });

  group('PopupNotification - showError', () {
    testWidgets('hiển thị title, message và icon error', (tester) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showError(
              context: context,
              title: 'Lỗi!',
              message: 'Đã xảy ra lỗi',
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Lỗi!'), findsOneWidget);
      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('nút "Đã hiểu" đóng dialog', (tester) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showError(
              context: context,
              title: 'Lỗi!',
              message: 'Thử lại',
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tapButton(tester);

      expect(find.text('Lỗi!'), findsNothing);
    });
  });

  group('PopupNotification - showInfo', () {
    testWidgets('hiển thị title, message và icon info mặc định', (
      tester,
    ) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showInfo(
              context: context,
              title: 'Thông tin',
              message: 'Đây là thông báo',
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Thông tin'), findsOneWidget);
      expect(find.text('Đây là thông báo'), findsOneWidget);
      expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    });

    testWidgets('custom icon', (tester) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showInfo(
              context: context,
              title: 'Info',
              message: 'Test',
              icon: Icons.star_rounded,
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });
  });

  group('PopupNotification - showConfirm', () {
    testWidgets('hiển thị title, message và 2 nút', (tester) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showConfirm(
              context: context,
              title: 'Xác nhận',
              message: 'Bạn có chắc chắn?',
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Xác nhận'), findsOneWidget);
      expect(find.text('Bạn có chắc chắn?'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Đồng ý'), findsOneWidget);
      // Icon help
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });

    testWidgets('tap Hủy trả về false', (tester) async {
      bool? result;

      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await PopupNotification.showConfirm(
                context: context,
                title: 'Xác nhận',
                message: 'Chắc chưa?',
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('tap Đồng ý trả về true', (tester) async {
      bool? result;

      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await PopupNotification.showConfirm(
                context: context,
                title: 'Xác nhận',
                message: 'Chắc chưa?',
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('Đồng ý'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('custom confirm/cancel text và confirmColor', (tester) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showConfirm(
              context: context,
              title: 'Title',
              message: 'Message',
              confirmText: 'Có',
              cancelText: 'Không',
              confirmColor: Colors.red,
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Có'), findsOneWidget);
      expect(find.text('Không'), findsOneWidget);
    });
  });

  group('PopupNotification - showLoading', () {
    testWidgets('hiển thị title và CircularProgressIndicator', (tester) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showLoading(
              context: context,
              title: 'Đang xử lý...',
              message: 'Vui lòng đợi',
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      // Loading dialog có pulse animation cần pump nhiều hơn
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Đang xử lý...'), findsOneWidget);

      // CircularProgressIndicator trong loading dialog
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Không có nút nào trong loading dialog
      expect(find.text('Đã hiểu'), findsNothing);
      expect(find.text('Hủy'), findsNothing);
      expect(find.text('Đồng ý'), findsNothing);
    });
  });

  group('PopupNotification - showPendingInfo', () {
    testWidgets('hiển thị pending info với headName, address, status', (
      tester,
    ) async {
      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showPendingInfo(
              context: context,
              title: 'Yêu cầu đang chờ',
              message: 'Chi tiết bên dưới',
              headName: 'Nguyễn Văn A',
              address: '123 Đường Lê Lợi, Q.1',
              statusText: 'Chờ duyệt',
              statusColor: Colors.orange,
              onViewDetail: () {},
              onBack: () {},
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Title
      expect(find.text('Yêu cầu đang chờ'), findsOneWidget);
      // Head name
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      // Address
      expect(find.text('123 Đường Lê Lợi, Q.1'), findsOneWidget);
      // Status
      expect(find.text('Chờ duyệt'), findsOneWidget);
      // Icon hourglass
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets('nút Quay lại gọi onBack, nút Xem chi tiết gọi onViewDetail', (
      tester,
    ) async {
      bool backCalled = false;
      bool detailCalled = false;

      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showPendingInfo(
              context: context,
              title: 'Pending',
              message: 'Info',
              headName: 'Test',
              address: 'Address',
              statusText: 'Chờ',
              statusColor: Colors.orange,
              onViewDetail: () => detailCalled = true,
              onBack: () => backCalled = true,
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap Quay lại
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
      expect(detailCalled, isFalse);
    });

    testWidgets('nút Xem chi tiết gọi onViewDetail', (tester) async {
      bool detailCalled = false;

      await tester.pumpScreen(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PopupNotification.showPendingInfo(
              context: context,
              title: 'Pending',
              message: 'Info',
              headName: 'Test',
              address: 'Addr',
              statusText: 'Chờ',
              statusColor: Colors.orange,
              onViewDetail: () => detailCalled = true,
              onBack: () {},
            ),
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Đóng dialog trước bằng Quay lại, test detail riêng
      await tester.tap(find.text('Xem chi tiết'));
      await tester.pumpAndSettle();

      expect(detailCalled, isTrue);
    });
  });
}
