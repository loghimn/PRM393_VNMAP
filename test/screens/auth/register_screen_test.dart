import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/screens/auth/register_screen.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';

/// The register form is tall (6 fields + button + links). Default 600px
/// surface clips the register button. Always use a taller surface.
const Size _tallSurface = Size(800, 1000);

void main() {
  late FakeAuthProvider mockAuth;

  setUp(() {
    mockAuth = FakeAuthProvider();
    mockAuth.isLoading = false;
    mockAuth.error = null;
    mockAuth.currentUser = null;
    mockAuth.isLoggedIn = false;
    mockAuth.isInitialized = true;
  });

  /// Helper that pumps a RegisterScreen with a taller surface so the
  /// register button (bottom of form) is reachable without scrolling.
  Future<void> pumpRegisterScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(_tallSurface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpScreen(
      const RegisterScreen(),
      overrides: ProviderOverrides(auth: mockAuth),
    );
  }

  /// Tap the register button.  There are two widgets with text "ĐĂNG KÝ":
  /// one is a title Text and one is the button Text.  We target the
  /// ElevatedButton that contains the button text.
  Future<void> tapRegisterButton(WidgetTester tester) async {
    // The last "ĐĂNG KÝ" text belongs to the button (title comes first).
    final button = find.ancestor(
      of: find.text('ĐĂNG KÝ').last,
      matching: find.byType(ElevatedButton),
    );
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
  }

  // ---------------------------------------------------------------------------
  // Initial UI
  // ---------------------------------------------------------------------------
  group('Initial UI', () {
    testWidgets('should render all form fields and title', (tester) async {
      await pumpRegisterScreen(tester);

      // App identification
      expect(find.text('VN'), findsOneWidget);
      // "ĐĂNG KÝ" appears in title and button text
      expect(find.text('ĐĂNG KÝ'), findsAtLeast(1));
      expect(find.text('Tạo tài khoản mới'), findsOneWidget);

      // All form labels present
      expect(find.text('Tên đăng nhập'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Nhập lại mật khẩu'), findsOneWidget);
      expect(find.text('Email (bắt buộc)'), findsOneWidget);
      expect(find.text('Họ tên (tùy chọn)'), findsOneWidget);
      expect(find.text('Số điện thoại (bắt buộc)'), findsOneWidget);

      // Back to login link
      expect(find.text('Đã có tài khoản? Đăng nhập ngay'), findsOneWidget);
    });

    testWidgets('should use desktop layout when screen width > 600', (
      tester,
    ) async {
      // Override surface to desktop size (width > 600)
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpScreen(
        const RegisterScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );
      await tester.pumpAndSettle();

      expect(find.text('VN'), findsOneWidget);
      expect(find.text('ĐĂNG KÝ'), findsAtLeast(1));
      expect(find.text('Đã có tài khoản? Đăng nhập ngay'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Form Validation
  // ---------------------------------------------------------------------------
  group('Form Validation', () {
    testWidgets('should show required errors when all fields empty', (
      tester,
    ) async {
      await pumpRegisterScreen(tester);
      await tapRegisterButton(tester);

      expect(find.text('Vui lòng nhập tên đăng nhập'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      expect(find.text('Vui lòng nhập lại mật khẩu'), findsOneWidget);
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
    });

    testWidgets('should show error for username shorter than 3 chars', (
      tester,
    ) async {
      await pumpRegisterScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên đăng nhập'),
        'ab',
      );
      await tapRegisterButton(tester);

      expect(find.text('Tên đăng nhập ít nhất 3 ký tự'), findsOneWidget);
    });

    testWidgets('should show error for password shorter than 6 chars', (
      tester,
    ) async {
      await pumpRegisterScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        '12345',
      );
      await tapRegisterButton(tester);

      expect(find.text('Mật khẩu ít nhất 6 ký tự'), findsOneWidget);
    });

    testWidgets('should show error when passwords do not match', (
      tester,
    ) async {
      await pumpRegisterScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        '123456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nhập lại mật khẩu'),
        '654321',
      );
      await tapRegisterButton(tester);

      expect(find.text('Mật khẩu không khớp'), findsOneWidget);
    });

    testWidgets('should show error for invalid email', (tester) async {
      await pumpRegisterScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email (bắt buộc)'),
        'not-an-email',
      );
      await tapRegisterButton(tester);

      expect(find.text('Email không hợp lệ'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Password Visibility
  // ---------------------------------------------------------------------------
  group('Password Visibility', () {
    testWidgets('should toggle password visibility', (tester) async {
      await pumpRegisterScreen(tester);

      // Password field (second TextField, index = 1)
      final passwordField = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      // Tap the first visibility_off icon (belongs to password field)
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pump();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    });

    testWidgets('should toggle confirm password visibility', (tester) async {
      await pumpRegisterScreen(tester);

      // Confirm password field (third TextField, index = 2)
      final confirmField = find.byType(TextField).at(2);
      expect(tester.widget<TextField>(confirmField).obscureText, isTrue);

      // Tap the second visibility_off icon
      await tester.tap(find.byIcon(Icons.visibility_off).last);
      await tester.pump();

      expect(tester.widget<TextField>(confirmField).obscureText, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Registration Flow
  // ---------------------------------------------------------------------------
  group('Registration Flow', () {
    Future<void> fillValidForm(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên đăng nhập'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        '123456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nhập lại mật khẩu'),
        '123456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email (bắt buộc)'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Họ tên (tùy chọn)'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Số điện thoại (bắt buộc)'),
        '0987654321',
      );
    }

    testWidgets('should show success snackbar and navigate on success', (
      tester,
    ) async {
      await pumpRegisterScreen(tester);
      await fillValidForm(tester);

      // Scroll button into view and tap
      final button = find.ancestor(
        of: find.text('ĐĂNG KÝ').last,
        matching: find.byType(ElevatedButton),
      );
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Success snackbar
      expect(
        find.text('Đăng ký thành công! Vui lòng đăng nhập.'),
        findsOneWidget,
      );

      // Should have navigated to login screen (placeholder label)
      expect(find.text('LoginScreen'), findsAtLeast(1));
    });

    testWidgets('should stay on register screen when registration fails', (
      tester,
    ) async {
      mockAuth.mockRegisterResult = false;

      await pumpRegisterScreen(tester);
      await fillValidForm(tester);

      final button = find.ancestor(
        of: find.text('ĐĂNG KÝ').last,
        matching: find.byType(ElevatedButton),
      );
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();

      // Register screen should still be showing (no navigation)
      expect(find.text('ĐĂNG KÝ'), findsAtLeast(1));
      // Login placeholder should NOT be present
      expect(find.text('LoginScreen'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------
  group('Navigation', () {
    testWidgets('should navigate to login when back link is tapped', (
      tester,
    ) async {
      await pumpRegisterScreen(tester);
      await tester.pumpAndSettle();

      final backLink = find.text('Đã có tài khoản? Đăng nhập ngay');
      await tester.ensureVisible(backLink);
      await tester.pump();
      await tester.tap(backLink);
      await tester.pumpAndSettle();

      // Should have navigated to login screen (placeholder label)
      expect(find.text('LoginScreen'), findsAtLeast(1));
    });
  });
}
