import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_request_detail_screen.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';
import '../test_helpers/fake_database_service.dart';

class _FakeRoute extends Fake implements Route<dynamic> {}

/// Một user có role='user' dùng trong non-admin tests.
final _testUser = UserModel(
  id: 999,
  uid: 'non-admin-uid',
  username: 'nonadmin',
  email: 'user@example.com',
  fullName: 'Normal User',
  phone: '0900000000',
  role: 'user',
  avatarUrl: null,
  isActive: true,
);

void main() {
  late FakeAuthProvider mockAuth;
  late FakeHouseholdRequestProvider mockHouseholdRequest;
  late FakeDatabaseService fakeDb;

  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

  setUp(() {
    mockAuth = FakeAuthProvider();
    mockAuth.isLoading = false;
    mockAuth.error = null;
    mockAuth.isLoggedIn = true;
    mockAuth.isInitialized = true;

    // Mặc định là user (không admin)
    mockAuth.currentUser = _testUser;

    mockHouseholdRequest = FakeHouseholdRequestProvider();
    mockHouseholdRequest.requests = [];

    fakeDb = FakeDatabaseService();
    fakeDb.asyncDelay = Duration.zero;
  });

  group('HouseholdRequestDetailScreen - Loading & Error States', () {
    testWidgets('should show loading indicator while loading', (tester) async {
      // Giả lập database chậm hơn
      fakeDb.asyncDelay = const Duration(milliseconds: 200);

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Chỉ pump 50ms, chưa đủ 200ms nên UI vẫn đang loading
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cho timer 200ms chạy hết để tránh lỗi pending timer
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    });

    testWidgets('should show not found when request is null', (tester) async {
      fakeDb.mockHouseholdRequestById = null;

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 999, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy yêu cầu'), findsOneWidget);
    });
  });

  group('HouseholdRequestDetailScreen - Basic Info', () {
    testWidgets('should show correct title in AppBar', (tester) async {
      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết yêu cầu'), findsOneWidget);
    });

    testWidgets('should display request info when loaded', (tester) async {
      fakeDb.mockHouseholdRequestById = testRequest;

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      // headOfHousehold luôn có giá trị (non-null)
      expect(find.textContaining(testRequest.headOfHousehold!), findsOneWidget);
      expect(find.textContaining(testRequest.phone!), findsOneWidget);
    });

    testWidgets('should display address info', (tester) async {
      fakeDb.mockHouseholdRequestById = testRequest;

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testRequest.houseNumber!), findsOneWidget);
      expect(find.text(testRequest.street!), findsOneWidget);
      expect(find.text(testRequest.neighborhood!), findsOneWidget);
    });

    testWidgets('should show status banner for pending request', (
      tester,
    ) async {
      fakeDb.mockHouseholdRequestById = testRequest;

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chờ phê duyệt'), findsOneWidget);
    });

    testWidgets('should show status banner for approved request', (
      tester,
    ) async {
      fakeDb.mockHouseholdRequestById = HouseholdRequest(
        id: 1,
        userId: 1,
        headOfHousehold: 'Nguyễn Văn A',
        phone: '0909123456',
        houseNumber: '123',
        street: 'Đường Lê Lợi',
        neighborhood: 'P.Bến Thành',
        ward: 'Q.1',
        city: 'TP.HCM',
        status: 'approved',
        email: 'test@example.com',
        population: 4,
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã phê duyệt'), findsOneWidget);
    });

    testWidgets('should show status banner for rejected request', (
      tester,
    ) async {
      fakeDb.mockHouseholdRequestById = HouseholdRequest(
        id: 1,
        userId: 1,
        headOfHousehold: 'Nguyễn Văn A',
        phone: '0909123456',
        houseNumber: '123',
        street: 'Đường Lê Lợi',
        neighborhood: 'P.Bến Thành',
        ward: 'Q.1',
        city: 'TP.HCM',
        status: 'rejected',
        email: 'test@example.com',
        population: 4,
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã từ chối'), findsOneWidget);
    });
  });

  group('HouseholdRequestDetailScreen - Admin Actions', () {
    testWidgets('should show admin action buttons for pending + admin', (
      tester,
    ) async {
      mockAuth.currentUser = adminUser; // role == 'admin'
      fakeDb.mockHouseholdRequestById = testRequest;

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phê duyệt'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);
    });

    testWidgets('should not show admin actions for non-admin user', (
      tester,
    ) async {
      // currentUser đã là testUser (role='user') trong setUp
      fakeDb.mockHouseholdRequestById = testRequest;

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phê duyệt'), findsNothing);
      expect(find.text('Từ chối'), findsNothing);
    });

    testWidgets('should not show admin actions for already processed request', (
      tester,
    ) async {
      mockAuth.currentUser = adminUser;
      fakeDb.mockHouseholdRequestById = HouseholdRequest(
        id: 1,
        userId: 1,
        headOfHousehold: 'Nguyễn Văn A',
        phone: '0909123456',
        houseNumber: '123',
        street: 'Đường Lê Lợi',
        neighborhood: 'P.Bến Thành',
        ward: 'Q.1',
        city: 'TP.HCM',
        status: 'approved',
        email: 'test@example.com',
        population: 4,
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phê duyệt'), findsNothing);
      expect(find.text('Từ chối'), findsNothing);
    });

    testWidgets('should show admin note text field for pending request', (
      tester,
    ) async {
      mockAuth.currentUser = adminUser;
      fakeDb.mockHouseholdRequestById = testRequest;

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phản hồi của admin'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should show admin note if request has one', (tester) async {
      fakeDb.mockHouseholdRequestById = HouseholdRequest(
        id: 1,
        userId: 1,
        headOfHousehold: 'Nguyễn Văn A',
        phone: '0909123456',
        houseNumber: '123',
        street: 'Đường Lê Lợi',
        neighborhood: 'P.Bến Thành',
        ward: 'Q.1',
        city: 'TP.HCM',
        status: 'rejected',
        adminNote: 'Thiếu thông tin',
        email: 'test@example.com',
        population: 4,
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      await tester.pumpScreen(
        HouseholdRequestDetailScreen(requestId: 1, databaseService: fakeDb),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ghi chú của admin'), findsOneWidget);
      expect(find.text('Thiếu thông tin'), findsOneWidget);
    });
  });
}
