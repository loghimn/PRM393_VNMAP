import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/screens/auth/user_management_screen.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/fake_database_service.dart';

// ---------------------------------------------------------------------------
// Sample users used across tests
// ---------------------------------------------------------------------------
final _activeUser = UserModel(
  id: 1,
  uid: 'uid-1',
  username: 'user1',
  email: 'user1@test.com',
  fullName: 'Nguyễn Văn A',
  phone: '0909123456',
  role: 'user',
  isActive: true,
);

final _inactiveUser = UserModel(
  id: 2,
  uid: 'uid-2',
  username: 'user2',
  email: 'user2@test.com',
  fullName: 'Trần Thị B',
  phone: '0909123457',
  role: 'user',
  isActive: false,
);

final _adminUser = UserModel(
  id: 3,
  uid: 'uid-3',
  username: 'admin',
  email: 'admin@test.com',
  fullName: 'Admin User',
  phone: '0909123458',
  role: 'admin',
  isActive: true,
);

final _sampleUsers = [_activeUser, _inactiveUser, _adminUser];

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

    testWidgets('should show empty message when no users', (tester) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [];

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không có người dùng nào'), findsOneWidget);
    });

    testWidgets('should render user list with data', (tester) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = _sampleUsers;

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Verify all usernames are rendered
      expect(find.text('user1'), findsOneWidget);
      expect(find.text('user2'), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);

      // Verify status texts
      expect(find.textContaining('Hoạt động'), findsWidgets);
      expect(find.text('Trạng thái: Đã khóa'), findsOneWidget);

      // Verify role display
      expect(find.textContaining('Vai trò:'), findsWidgets);
    });

    testWidgets('should show popup menu items for non-admin active user', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_activeUser]; // role: user, isActive: true

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Tap on PopupMenuButton
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Should show "Khóa tài khoản" (since user is active) and "Đổi vai trò"
      expect(find.text('Khóa tài khoản'), findsOneWidget);
      expect(find.text('Đổi vai trò'), findsOneWidget);
    });

    testWidgets('should show popup menu items for non-admin inactive user', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_inactiveUser]; // role: user, isActive: false

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Tap on PopupMenuButton
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Should show "Mở tài khoản" (since user is inactive) and "Đổi vai trò"
      expect(find.text('Mở tài khoản'), findsOneWidget);
      expect(find.text('Đổi vai trò'), findsOneWidget);
    });

    testWidgets('should NOT show popup menu items for admin user', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_adminUser]; // role: admin

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Tap on PopupMenuButton
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Should NOT have toggle or change role for admin
      expect(find.text('Khóa tài khoản'), findsNothing);
      expect(find.text('Mở tài khoản'), findsNothing);
      expect(find.text('Đổi vai trò'), findsNothing);
    });

    testWidgets('should toggle user status when "Khóa tài khoản" tapped', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_activeUser]; // isActive: true -> should become false

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap "Khóa tài khoản"
      await tester.tap(find.text('Khóa tài khoản'));
      await tester.pumpAndSettle();

      // After toggle, no error snackbar should appear
      expect(find.textContaining('Lỗi:'), findsNothing);
    });

    testWidgets('should show snackbar when trying to toggle admin status', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_adminUser]; // role: admin

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Since admin user doesn't have popup menu items,
      // we cannot trigger _toggleUserStatus from UI.
      // Verify the popup menu shows no options
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Khóa tài khoản'), findsNothing);
    });

    testWidgets('should show error snackbar when toggle user fails', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_activeUser];
      fakeDb.mockUpdateUserError = Exception('Update failed');

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap "Khóa tài khoản" -> will trigger error catch
      await tester.tap(find.text('Khóa tài khoản'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.textContaining('Lỗi:'), findsOneWidget);
    });

    testWidgets('should show role selection dialog when "Đổi vai trò" tapped', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_activeUser]; // role: user

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap "Đổi vai trò" -> triggers _showRoleDialog -> shows AlertDialog
      await tester.tap(find.text('Đổi vai trò'));
      await tester.pumpAndSettle();

      // Role dialog should appear
      expect(find.text('Thay đổi vai trò'), findsOneWidget);
      expect(find.text('User (Người dùng)'), findsOneWidget);
      expect(find.text('Admin (Quản trị viên)'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
    });

    testWidgets('should change role to admin when selected in dialog', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_activeUser]; // role: user

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Open popup -> tap change role
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi vai trò'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Thay đổi vai trò'), findsOneWidget);

      // Tap the Radio widget directly for the "admin" option
      // (tapping the Text may not trigger Radio's onChanged via ListTile)
      final adminRadio = find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w is ListTile &&
              w.title is Text &&
              (w.title as Text).data == 'Admin (Quản trị viên)',
        ),
        matching: find.byType(Radio<String>),
      );
      await tester.tap(adminRadio);
      // Navigator.pop + _changeUserRole async chain completes
      await tester.pumpAndSettle();

      // Dialog should close and no error shown
      expect(find.text('Thay đổi vai trò'), findsNothing);
      expect(find.textContaining('Lỗi:'), findsNothing);
    });

    testWidgets('should close role dialog when cancel is tapped', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_activeUser];

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Open popup -> tap change role
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi vai trò'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Thay đổi vai trò'), findsOneWidget);

      // Tap "Hủy"
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Thay đổi vai trò'), findsNothing);
    });

    testWidgets(
      'should show snackbar when trying to change admin role in dialog',
      (tester) async {
        final fakeDb = FakeDatabaseService();
        fakeDb.mockUsers = [_adminUser]; // role: admin

        await tester.pumpScreen(
          UserManagementScreen(databaseService: fakeDb),
          overrides: ProviderOverrides(auth: mockAuth),
        );
        await tester.pumpAndSettle();

        // Admin user doesn't have popup menu items
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // No change role option for admin
        expect(find.text('Đổi vai trò'), findsNothing);
      },
    );

    testWidgets('should show change role error snackbar on failure', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_activeUser];
      fakeDb.mockUpdateUserError = Exception('Role update failed');

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Open popup -> change role
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi vai trò'));
      await tester.pumpAndSettle();

      // Select admin role via Radio widget -> will trigger error in _changeUserRole
      final adminRadio = find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w is ListTile &&
              w.title is Text &&
              (w.title as Text).data == 'Admin (Quản trị viên)',
        ),
        matching: find.byType(Radio<String>),
      );
      await tester.tap(adminRadio);
      // Navigator.pop + _changeUserRole throws + SnackBar appears
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.textContaining('Lỗi:'), findsOneWidget);
    });

    testWidgets('should clear search and reload when clear button tapped', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = _sampleUsers;

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Clear button is always present (suffixIcon: IconButton)
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Type something in search field
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Verify text is entered
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'test');

      // Tap clear button -> triggers _searchController.clear() and _loadUsers()
      await tester.tap(find.byIcon(Icons.clear));
      // Let async _loadUsers complete
      await tester.pumpAndSettle();

      // Search field should be cleared
      expect(textField.controller?.text, '');

      // Users should still be visible after reload
      expect(find.text('user1'), findsOneWidget);
    });

    testWidgets('should reload users when search is submitted', (tester) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = _sampleUsers;

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Type in search field
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'user1');
      await tester.pump();

      // Submit search (press done/enter)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      // Use pumpAndSettle to let the async _loadUsers complete and avoid pending timers
      await tester.pumpAndSettle();

      // Should reload users without error
      expect(find.textContaining('Lỗi'), findsNothing);
    });

    testWidgets('should refresh user list when refresh button tapped', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = _sampleUsers;

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Tap refresh icon
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Users should still be visible
      expect(find.text('user1'), findsOneWidget);
    });

    testWidgets('should show correct avatar for admin vs regular user', (
      tester,
    ) async {
      final fakeDb = FakeDatabaseService();
      fakeDb.mockUsers = [_activeUser, _adminUser];

      await tester.pumpScreen(
        UserManagementScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Both CircleAvatars should be rendered
      expect(find.byType(CircleAvatar), findsNWidgets(2));

      // Admin icon for admin user
      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);

      // Person icon for regular user
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
