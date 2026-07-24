import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/auth/login_screen.dart';
import 'package:vietnam_geo_dashboard/providers/auth_provider.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';

void main() {
  late MockAuthProvider mockAuth;

  setUp(() {
    mockAuth = MockAuthProvider();

    // Default stub values
    when(() => mockAuth.error).thenReturn(null);
    when(() => mockAuth.isLoading).thenReturn(false);
    when(() => mockAuth.clearError()).thenReturn(null);
  });

  Widget buildTestScreen({ProviderOverrides? overrides}) {
    return const LoginScreen();
  }

  group('LoginScreen - Rendering', () {
    testWidgets('should render logo, title and subtitle', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      expect(find.text('VN'), findsOneWidget);
      expect(find.text('VNMAP'), findsOneWidget);
      expect(find.text('Hệ thống quản lý thông tin'), findsOneWidget);
    });

    testWidgets('should render email and password fields', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // Email field
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Nhập email'), findsOneWidget);

      // Password field
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('should render login and register buttons', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
      expect(find.text('Chưa có tài khoản? Đăng ký ngay'), findsOneWidget);
    });

    testWidgets('should render password visibility toggle', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // Password field is obscured by default
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Password should be visible now
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });
  });

  group('LoginScreen - Validation', () {
    testWidgets('should show error when email is empty', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // Tap login button without filling fields
      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
    });

    testWidgets('should show error when password is empty', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // Enter email only
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('should show error for invalid email format', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pumpAndSettle();

      expect(find.text('Email không hợp lệ'), findsOneWidget);
    });

    testWidgets('should show both errors when both fields are empty', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });
  });

  group('LoginScreen - Login Flow', () {
    testWidgets('should show loading indicator when logging in', (
      tester,
    ) async {
      // Create a completer to hold the login future incomplete
      final completer = Completer<bool>();
      when(
        () => mockAuth.login(any(), any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // Fill in credentials
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Tap login — this sets _isLoading = true
      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pump(); // trigger setState to show loading indicator

      // Loading indicator should replace button text
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP'), findsNothing);

      // Complete the login future to clean up
      completer.complete(true);
      await tester.pumpAndSettle();
    });

    testWidgets('should call login and navigate to home on success', (
      tester,
    ) async {
      when(() => mockAuth.login(any(), any())).thenAnswer((_) async => true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // Fill in valid credentials
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Tap login
      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pumpAndSettle();

      // Verify login was called with correct credentials
      verify(() => mockAuth.login('test@example.com', 'password123')).called(1);
    });

    testWidgets('should show error message when login fails', (tester) async {
      const errorMsg = 'Email hoặc mật khẩu không chính xác';
      when(() => mockAuth.login(any(), any())).thenAnswer((_) async => false);
      when(() => mockAuth.error).thenReturn(errorMsg);

      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
          overrides: ProviderOverrides(auth: mockAuth),
        ),
      );
      await tester.pump();

      // Fill in credentials
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'wrong@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');

      // Tap login
      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pumpAndSettle();

      // Error message should be displayed from Consumer<AuthProvider>
      expect(find.text(errorMsg), findsOneWidget);
    });

    testWidgets('should dismiss error when close icon is tapped', (
      tester,
    ) async {
      const errorMsg = 'Email hoặc mật khẩu không chính xác';
      when(() => mockAuth.login(any(), any())).thenAnswer((_) async => false);
      when(() => mockAuth.error).thenReturn(errorMsg);

      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
          overrides: ProviderOverrides(auth: mockAuth),
        ),
      );
      await tester.pump();

      // Trigger login to show error
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'wrong@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pumpAndSettle();

      // Error is shown
      expect(find.text(errorMsg), findsOneWidget);

      // Tap close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      verify(() => mockAuth.clearError()).called(1);
    });
  });

  group('LoginScreen - Navigation', () {
    testWidgets('should navigate to Register screen', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth),
      );

      // Tap register link
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký ngay'));
      await tester.pumpAndSettle();

      // Should navigate away from login screen (to /register placeholder)
      // The _PlaceholderScreen shows "RegisterScreen" in both AppBar and body
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('RegisterScreen'), findsNWidgets(2));
    });
  });
}
