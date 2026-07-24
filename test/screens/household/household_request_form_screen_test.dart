import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_request_form_screen.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';
import '../test_helpers/fake_database_service.dart';

void main() {
  late FakeAuthProvider mockAuth;
  late FakeHouseholdRequestProvider mockHouseholdRequest;
  late FakeDatabaseService fakeDb;

  setUp(() {
    mockAuth = FakeAuthProvider();
    mockAuth.isAdmin = false;
    mockAuth.isLoading = false;
    mockAuth.error = null;
    mockAuth.currentUser = testUser;
    mockAuth.isLoggedIn = true;
    mockAuth.isInitialized = true;

    mockHouseholdRequest = FakeHouseholdRequestProvider();
    mockHouseholdRequest.requests = [];
    // Mặc định không có pending request → form sẽ hiện ra
    mockHouseholdRequest.mockGetUserPendingRequest = (_) async => null;

    fakeDb = FakeDatabaseService();
    fakeDb.mockCities = [];
    fakeDb.mockCommunes = [];
    // Speed up async operations
    fakeDb.asyncDelay = Duration.zero;
  });

  /// Helper: pump screen và đợi check pending + load dropdown hoàn tất
  Future<void> pumpAndWaitForForm(WidgetTester tester) async {
    await tester.pumpScreen(
      HouseholdRequestFormScreen(databaseService: fakeDb),
      overrides: ProviderOverrides(
        auth: mockAuth,
        householdRequest: mockHouseholdRequest,
      ),
    );
    // Đợi _checkPendingRequest + _loadDropdownData hoàn tất và rebuild
    await tester.pumpAndSettle();
  }

  group('HouseholdRequestFormScreen - Loading State', () {
    testWidgets('should show checking indicator initially', (tester) async {
      // Giả lập pending check chậm
      mockHouseholdRequest.mockGetUserPendingRequest = (_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return null;
      };

      await tester.pumpScreen(
        HouseholdRequestFormScreen(databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Chỉ pump 100ms (mặc định của pumpScreen), chưa đủ 1s
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang kiểm tra yêu cầu...'), findsOneWidget);

      // Dọn dẹp pending timer
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });
  });

  group('HouseholdRequestFormScreen - Pending Request', () {
    testWidgets(
      'should show pending request screen when user has pending request',
      (tester) async {
        // Use larger surface to accommodate the popup content
        final originalSize = tester.view.physicalSize;
        addTearDown(() {
          tester.view.resetPhysicalSize();
        });
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        mockHouseholdRequest.mockGetUserPendingRequest = (_) async =>
            testRequest;

        await tester.pumpScreen(
          HouseholdRequestFormScreen(databaseService: fakeDb),
          overrides: ProviderOverrides(
            auth: mockAuth,
            householdRequest: mockHouseholdRequest,
          ),
        );
        await tester.pumpAndSettle();

        // Pending popup shows these texts
        expect(find.text('Yêu cầu đang chờ duyệt'), findsOneWidget);
      },
    );
  });

  group('HouseholdRequestFormScreen - AppBar', () {
    testWidgets('should show correct AppBar title', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Yêu cầu tạo hộ gia đình'), findsOneWidget);
    });

    testWidgets('should show back button', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });

  group('HouseholdRequestFormScreen - Info Notice', () {
    testWidgets('should show info notice about creating household', (
      tester,
    ) async {
      await pumpAndWaitForForm(tester);

      expect(find.textContaining('Bạn chưa có hộ gia đình'), findsOneWidget);
    });
  });

  group('HouseholdRequestFormScreen - Form Sections', () {
    testWidgets('should show personal info section header', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Thông tin chủ hộ'), findsOneWidget);
    });

    testWidgets('should show head of household field', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Họ và tên chủ hộ'), findsOneWidget);
    });

    testWidgets('should show phone field', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Số điện thoại'), findsOneWidget);
    });

    testWidgets('should show population and email fields', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Số nhân khẩu'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('should show address section header', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Địa chỉ'), findsOneWidget);
    });

    testWidgets('should show city/ward dropdown labels', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Tỉnh/Thành phố'), findsOneWidget);
      expect(find.text('Phường/Xã'), findsOneWidget);
    });

    testWidgets(
      'should show house number, street, neighborhood, district fields',
      (tester) async {
        await pumpAndWaitForForm(tester);

        expect(find.text('Số nhà'), findsOneWidget);
        expect(find.text('Đường'), findsOneWidget);
        expect(find.text('Tổ'), findsOneWidget);
        expect(find.text('Quận/Huyện'), findsOneWidget);
      },
    );

    testWidgets('should show notes section', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Ghi chú'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should show image section header', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Hình ảnh hộ gia đình'), findsOneWidget);
    });

    testWidgets('should show image pick button', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Chọn ảnh'), findsOneWidget);
    });
  });

  group('HouseholdRequestFormScreen - Submit Button', () {
    testWidgets('should show submit button', (tester) async {
      await pumpAndWaitForForm(tester);

      expect(find.text('Gửi yêu cầu'), findsOneWidget);
    });
  });
}
