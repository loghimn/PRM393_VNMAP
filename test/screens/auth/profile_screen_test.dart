import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/screens/auth/profile_screen.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/navigator_observer.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

/// Fake Route needed for mocktail's registerFallbackValue.
class _FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late FakeAuthProvider mockAuth;

  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

  setUp(() {
    mockAuth = FakeAuthProvider();
    mockAuth.isLoading = false;
    mockAuth.error = null;
    mockAuth.currentUser = testUser;
    mockAuth.isLoggedIn = true;
    mockAuth.isInitialized = true;
  });

  Widget buildTestScreen({ProviderOverrides? overrides}) {
    return const ProfileScreen();
  }

  group('Initial State', () {
    testWidgets('should show user information when logged in', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Thông tin tài khoản'), findsOneWidget);

      // User name appears in both avatar section and detail row → 2 widgets
      expect(find.text(testUser.fullName!), findsNWidgets(2));
      expect(find.textContaining('@${testUser.username}'), findsOneWidget);

      // Personal info section header
      expect(find.text('Thông tin cá nhân'), findsOneWidget);
    });

    testWidgets('should show login prompt when user is null', (tester) async {
      mockAuth.currentUser = null;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      expect(find.text('Vui lòng đăng nhập'), findsOneWidget);
    });

    testWidgets('should show role badge for admin', (tester) async {
      mockAuth.currentUser = UserModel(
        id: testUser.id,
        uid: testUser.uid,
        username: testUser.username,
        email: testUser.email,
        fullName: testUser.fullName,
        phone: testUser.phone,
        role: 'admin', // ← admin role triggers "Quản trị viên"
        avatarUrl: testUser.avatarUrl,
        isActive: testUser.isActive,
      );

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // "Quản trị viên" appears in the account info section
      expect(find.text('Quản trị viên'), findsOneWidget);
    });

    testWidgets('should show role badge for regular user', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // testUser has role 'user' → shows "Người dùng"
      expect(find.text('Người dùng'), findsOneWidget);
    });

    testWidgets('should show account metadata section', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vai trò'), findsOneWidget);
      expect(find.text('Ngày tạo'), findsOneWidget);
      expect(find.text('Lần cuối đăng nhập'), findsOneWidget);
    });
  });

  group('Edit Mode', () {
    testWidgets('should toggle edit mode when edit icon is tapped', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Initially not editing → edit icon
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Now edit mode → close icon + text fields + save button
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byType(TextField), findsAtLeast(1));
      expect(find.text('Lưu thay đổi'), findsOneWidget);

      // Tap X to exit edit mode
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Back to non-editing
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should show validation snackbar when saving with empty name', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Clear name field (first TextField)
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();

      // Tap save
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pump();

      expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    });

    testWidgets('should call updateProfile and show success snackbar', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Modify name field
      const newName = 'Nguyễn Văn Test';
      await tester.enterText(find.byType(TextField).first, newName);
      await tester.pump();

      // Tap save
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      // Success snackbar
      expect(find.text('Cập nhật thông tin thành công'), findsOneWidget);
    });

    testWidgets('should show error snackbar when updateProfile fails', (
      tester,
    ) async {
      mockAuth
        ..error = 'Server error'
        ..mockUpdateProfile =
            ({
              String? fullName,
              String? email,
              String? phone,
              File? avatarFile,
              void Function(double)? onUploadProgress,
            }) async => false;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Tap save
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      // Snackbar shows auth.error
      expect(find.text('Server error'), findsOneWidget);
    });
  });

  group('Change Password', () {
    testWidgets('should expand and collapse password section', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.text('Mật khẩu cũ'), findsNothing);

      // Tap the section header (first match of "Đổi mật khẩu")
      await tester.tap(find.text('Đổi mật khẩu').first);
      await tester.pump();

      // Password fields visible
      expect(find.text('Mật khẩu cũ'), findsOneWidget);
      expect(find.text('Mật khẩu mới'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);
      // "Đổi mật khẩu" appears both as title and button text
      expect(find.text('Đổi mật khẩu'), findsNWidgets(2));

      // Tap section header again to collapse
      await tester.tap(find.text('Đổi mật khẩu').first);
      await tester.pump();

      // Collapsed again
      expect(find.text('Mật khẩu cũ'), findsNothing);
    });

    testWidgets('should show error for password shorter than 6 chars', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Expand password section
      await tester.tap(find.text('Đổi mật khẩu').first);
      await tester.pump();

      // Enter short new password
      await tester.enterText(find.byType(TextField).at(1), 'abc12');
      await tester.pump();

      // Tap the change password button (scroll down if needed)
      final changePwBtn = find.widgetWithText(ElevatedButton, 'Đổi mật khẩu');
      await tester.ensureVisible(changePwBtn);
      await tester.pump();
      await tester.tap(changePwBtn);
      await tester.pump();

      expect(find.text('Mật khẩu mới phải có ít nhất 6 ký tự'), findsOneWidget);
    });

    testWidgets('should show error when passwords do not match', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Expand password section
      await tester.tap(find.text('Đổi mật khẩu').first);
      await tester.pump();

      // Enter new password
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.pump();

      // Enter different confirmation
      await tester.enterText(find.byType(TextField).at(2), '654321');
      await tester.pump();

      // Tap change password button
      final changePwBtn = find.widgetWithText(ElevatedButton, 'Đổi mật khẩu');
      await tester.ensureVisible(changePwBtn);
      await tester.pump();
      await tester.tap(changePwBtn);
      await tester.pump();

      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
    });

    testWidgets('should show success message on password change', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.text('Đổi mật khẩu').first);
      await tester.pump();

      // Fill all 3 password fields
      await tester.enterText(find.byType(TextField).at(0), 'old123');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(2), '123456');
      await tester.pump();

      // Tap change password button
      final changePwBtn = find.widgetWithText(ElevatedButton, 'Đổi mật khẩu');
      await tester.ensureVisible(changePwBtn);
      await tester.pump();
      await tester.tap(changePwBtn);
      await tester.pumpAndSettle();

      // Success indicator in the password section (setState inline message)
      expect(find.text('Đổi mật khẩu thành công'), findsAtLeast(1));
    });

    testWidgets(
      'should show failure snackbar when changePassword returns false',
      (tester) async {
        // Override changePassword to fail
        mockAuth.mockChangePasswordResult = false;

        await tester.pumpScreen(
          buildTestScreen(),
          overrides: ProviderOverrides(auth: mockAuth),
        );
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.text('Đổi mật khẩu').first);
        await tester.pump();

        // Fill valid passwords
        await tester.enterText(find.byType(TextField).at(0), 'old123');
        await tester.pump();
        await tester.enterText(find.byType(TextField).at(1), '123456');
        await tester.pump();
        await tester.enterText(find.byType(TextField).at(2), '123456');
        await tester.pump();

        // Tap change password button
        final changePwBtn = find.widgetWithText(ElevatedButton, 'Đổi mật khẩu');
        await tester.ensureVisible(changePwBtn);
        await tester.pump();
        await tester.tap(changePwBtn);
        await tester.pumpAndSettle();

        // Fail snackbar
        expect(find.text('Đổi mật khẩu thất bại'), findsOneWidget);
      },
    );
  });

  group('Logout', () {
    testWidgets('should show confirmation dialog when logout tapped', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Scroll down to logout button
      final logoutBtn = find.text('ĐĂNG XUẤT');
      await tester.ensureVisible(logoutBtn);
      await tester.pump();
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Dialog content
      expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
      expect(find.text('Bạn có chắc muốn đăng xuất?'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    });

    testWidgets('should stay on profile when logout is cancelled', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Scroll to logout and tap
      final logoutBtn = find.text('ĐĂNG XUẤT');
      await tester.ensureVisible(logoutBtn);
      await tester.pump();
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Still on profile → fullName appears twice (avatar + detail row)
      expect(find.text(testUser.fullName!), findsNWidgets(2));
      expect(find.text('Thông tin tài khoản'), findsOneWidget);
    });

    testWidgets('should logout and navigate to login on confirm', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Scroll to logout and tap
      final logoutBtn = find.text('ĐĂNG XUẤT');
      await tester.ensureVisible(logoutBtn);
      await tester.pump();
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Tap confirm logout
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pumpAndSettle();

      // Auth state cleared
      expect(mockAuth.currentUser, isNull);

      // Should navigate to login screen (title + Center text = 2 widgets)
      expect(find.text('LoginScreen'), findsAtLeast(1));
    });
  });

  group('Avatar Section', () {
    testWidgets('should show avatar with initials when no avatar URL', (
      tester,
    ) async {
      // Ensure no avatarUrl
      mockAuth.currentUser = UserModel(
        id: testUser.id,
        uid: testUser.uid,
        username: testUser.username,
        email: testUser.email,
        fullName: testUser.fullName,
        phone: testUser.phone,
        role: testUser.role,
        avatarUrl: '', // empty → shows initials
        isActive: testUser.isActive,
      );

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // First letter of full name displayed in avatar
      expect(find.text(testUser.fullName![0].toUpperCase()), findsOneWidget);
    });

    testWidgets('should show camera badge in edit mode on avatar', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // No camera badge initially
      expect(find.byIcon(Icons.camera_alt), findsNothing);

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Camera badge should appear
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });

  group('Password Visibility Toggle', () {
    testWidgets('should toggle old password visibility', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      // Expand password section
      await tester.tap(find.text('Đổi mật khẩu').first);
      await tester.pump();

      // Old password field starts with obscure = true
      final oldPassField = tester.widget<TextField>(
        find.byType(TextField).at(0),
      );
      expect(oldPassField.obscureText, isTrue);

      // Tap visibility toggle for old password
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pump();

      // Now visible
      final updatedField = tester.widget<TextField>(
        find.byType(TextField).at(0),
      );
      expect(updatedField.obscureText, isFalse);
    });
  });
}
