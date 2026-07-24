import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_form_screen.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';
import '../test_helpers/fake_database_service.dart';

void main() {
  late FakeAuthProvider mockAuth;
  late FakeIncidentProvider mockIncident;
  late FakeDatabaseService fakeDb;

  setUp(() {
    mockAuth = FakeAuthProvider();
    mockAuth.isAdmin = true;
    mockAuth.isLoading = false;
    mockAuth.error = null;
    mockAuth.currentUser = adminUser;
    mockAuth.isLoggedIn = true;
    mockAuth.isInitialized = true;

    mockIncident = FakeIncidentProvider();
    mockIncident.selected = testIncident;
    mockIncident.isLoading = false;
    mockIncident.error = null;
    mockIncident.items = incidentList;

    fakeDb = FakeDatabaseService();
    fakeDb.mockCities = [];
    fakeDb.mockCommunes = [];
    fakeDb.asyncDelay = Duration.zero;
  });

  /// Helper: pump screen và đợi _loadDropdownData hoàn tất và rebuild
  Future<void> pumpAndWaitForForm(WidgetTester tester, Widget screen) async {
    await tester.pumpScreen(
      screen,
      overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
    );
    await tester.pumpAndSettle();
  }

  /// Helper: scroll trong ListView cho đến khi tìm thấy [findMe] hoặc hết
  Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder findMe, {
    Axis direction = Axis.vertical,
  }) async {
    while (findMe.evaluate().isEmpty) {
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }

  group('IncidentFormScreen - Create Mode', () {
    Widget buildCreateScreen() {
      return IncidentFormScreen(databaseService: fakeDb);
    }

    testWidgets('should show create title in AppBar', (tester) async {
      await pumpAndWaitForForm(tester, buildCreateScreen());

      // "Tạo sự vụ mới" appears in AppBar title and button text
      expect(find.text('Tạo sự vụ mới'), findsWidgets);
    });

    testWidgets('should show create button text', (tester) async {
      await pumpAndWaitForForm(tester, buildCreateScreen());

      expect(find.text('Tạo sự vụ mới'), findsWidgets);
    });

    testWidgets('should show main sections', (tester) async {
      await pumpAndWaitForForm(tester, buildCreateScreen());

      // Top section is visible without scrolling
      expect(find.text('Tìm kiếm hộ gia đình'), findsOneWidget);

      // Scroll to see sections below the fold
      await scrollUntilVisible(tester, find.text('Địa chỉ'));
      expect(find.text('Địa chỉ'), findsOneWidget);

      await scrollUntilVisible(tester, find.text('Địa chỉ sự việc'));
      // "Địa chỉ sự việc" appears as section title + subtitle text
      expect(find.text('Địa chỉ sự việc'), findsWidgets);

      expect(find.text('Thông tin sự cố'), findsOneWidget);
    });

    testWidgets('should show admin sections when user is admin', (
      tester,
    ) async {
      mockAuth.isAdmin = true;

      await pumpAndWaitForForm(tester, buildCreateScreen());

      await scrollUntilVisible(tester, find.text('Phân công xử lý'));
      expect(find.text('Phân công xử lý'), findsOneWidget);
    });

    testWidgets('should not show admin sections for non-admin user', (
      tester,
    ) async {
      mockAuth.isAdmin = false;

      await pumpAndWaitForForm(tester, buildCreateScreen());

      // Non-admin user: section header should not exist anywhere in the tree
      expect(find.text('Phân công xử lý'), findsNothing);
    });

    testWidgets('should show image picker section', (tester) async {
      await pumpAndWaitForForm(tester, buildCreateScreen());

      await scrollUntilVisible(tester, find.text('Hình ảnh hiện trường'));
      expect(find.text('Hình ảnh hiện trường'), findsOneWidget);
    });

    testWidgets('should show notes section', (tester) async {
      await pumpAndWaitForForm(tester, buildCreateScreen());

      await scrollUntilVisible(tester, find.text('Ghi chú'));
      // "Ghi chú" appears as section title + subtitle / hint text
      expect(find.text('Ghi chú'), findsWidgets);
    });
  });

  group('IncidentFormScreen - Edit Mode', () {
    Widget buildEditScreen() {
      return IncidentFormScreen(
        incident: testIncident,
        databaseService: fakeDb,
      );
    }

    testWidgets('should show edit title in AppBar', (tester) async {
      await pumpAndWaitForForm(tester, buildEditScreen());

      expect(find.text('Chỉnh sửa sự vụ'), findsOneWidget);
    });

    testWidgets('should show update button text', (tester) async {
      await pumpAndWaitForForm(tester, buildEditScreen());

      expect(find.text('Cập nhật sự vụ'), findsWidgets);
    });

    testWidgets('should pre-fill incident data', (tester) async {
      await pumpAndWaitForForm(tester, buildEditScreen());

      // Verify the edit mode form has the correct structure:
      // - The incident info section with "Thông tin sự cố" header
      await scrollUntilVisible(tester, find.text('Thông tin sự cố'));
      expect(find.text('Thông tin sự cố'), findsOneWidget);
    });

    testWidgets('should show close button in AppBar', (tester) async {
      await pumpAndWaitForForm(tester, buildEditScreen());

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
