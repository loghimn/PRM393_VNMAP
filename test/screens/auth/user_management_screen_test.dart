import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/screens/auth/user_management_screen.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/fake_database_service.dart';

void main() {
  late FakeAuthProvider mockAuth;

  setUp(() {
    mockAuth = FakeAuthProvider();
    mockAuth.isAdmin = false;
    mockAuth.isLoading = false;
    mockAuth.error = null;
    mockAuth.currentUser = null;
    mockAuth.isLoggedIn = true;
    mockAuth.isInitialized = true;
  });

  // ---------------------------------------------------------------------------
  // Access Control
  // ---------------------------------------------------------------------------
  group('Access Control', () {
    testWidgets('should show access denied for non-admin user', (tester) async {
      mockAuth.isAdmin = false;

      await tester.pumpScreen(
        const UserManagementScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn không có quyền truy cập trang này'),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Admin View - UI Elements
  // ---------------------------------------------------------------------------
  group('Admin View', () {
    setUp(() {
      mockAuth.isAdmin = true;
    });

    testWidgets('should render app bar with correct title', (tester) async {
      await tester.pumpScreen(
        const UserManagementScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // AppBar title is rendered synchronously
      expect(find.text('Quản lý người dùng'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      // Sử dụng FakeDatabaseService với asyncDelay để quan sát trạng thái loading
      // trước khi _loadUsers hoàn thành.
      final fakeDb = FakeDatabaseService();
      fakeDb.asyncDelay = const Duration(milliseconds: 100);

      await tester.pumpWidget(
        createTestApp(
          child: UserManagementScreen(databaseService: fakeDb),
          overrides: ProviderOverrides(auth: mockAuth),
        ),
      );

      // _loadUsers calls setState (synchronous before await) which marks
      // the widget dirty; pump one frame to render the CircularProgressIndicator.
      await tester.pump();

      // CircularProgressIndicator shows while _loadUsers is in-flight
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump to completion so resources are cleaned up
      await tester.pumpAndSettle();
    });

    testWidgets('should show error message after DatabaseService failure', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockGetAllUsersError = Exception('Network error');

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // After pumpScreen, the async _loadUsers has completed and set _error.
      // Pump one more frame to reflect the setState call.
      await tester.pump();

      // Should show error with "Lỗi:" prefix
      expect(find.textContaining('Lỗi:'), findsOneWidget);
    });
  });
}
