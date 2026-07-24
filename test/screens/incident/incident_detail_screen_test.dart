import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_detail_screen.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

class _FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late FakeAuthProvider mockAuth;
  late FakeIncidentProvider mockIncident;

  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

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
  });

  Widget buildTestScreen({ProviderOverrides? overrides}) {
    return const IncidentDetailScreen(incidentId: 1);
  }

  group('IncidentDetailScreen - Loading & Error States', () {
    testWidgets('should show loading indicator when loading', (tester) async {
      mockIncident.isLoading = true;
      mockIncident.selected = null;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message with retry button', (tester) async {
      const errorMsg = 'Lỗi tải dữ liệu';
      mockIncident.error = errorMsg;
      mockIncident.selected = null;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text(errorMsg), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('should show not found when selected is null', (tester) async {
      mockIncident.selected = null;
      mockIncident.error = null;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy thông tin'), findsOneWidget);
    });
  });

  group('IncidentDetailScreen - Incident Info Display', () {
    testWidgets('should display incident title and code', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text(testIncident.title), findsOneWidget);
      expect(find.text(testIncident.incidentCode), findsOneWidget);
    });

    testWidgets('should display incident status', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text(testIncident.status.displayName), findsWidgets);
    });

    testWidgets('should display incident description', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text(testIncident.description!), findsOneWidget);
    });

    testWidgets('should display address information', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text(testIncident.address!), findsOneWidget);
      expect(find.text(testIncident.neighborhood!), findsOneWidget);
      expect(find.text(testIncident.ward!), findsOneWidget);
      expect(find.text(testIncident.city!), findsOneWidget);
    });

    testWidgets('should display handler info', (tester) async {
      final incidentWithHandler = Incident(
        id: testIncident.id,
        incidentCode: testIncident.incidentCode,
        title: testIncident.title,
        description: testIncident.description,
        address: testIncident.address,
        incidentAddress: testIncident.incidentAddress,
        neighborhood: testIncident.neighborhood,
        ward: testIncident.ward,
        district: testIncident.district,
        city: testIncident.city,
        longitude: testIncident.longitude,
        latitude: testIncident.latitude,
        householdId: testIncident.householdId,
        headOfHousehold: testIncident.headOfHousehold,
        phone: testIncident.phone,
        status: testIncident.status,
        handler: 'Nguyễn Văn X',
        notes: testIncident.notes,
        createdBy: testIncident.createdBy,
        imageUrls: testIncident.imageUrls,
        createdAt: testIncident.createdAt,
        updatedAt: testIncident.updatedAt,
        completedDate: testIncident.completedDate,
      );
      mockIncident.selected = incidentWithHandler;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn X'), findsOneWidget);
    });

    testWidgets('should display related household info', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hộ gia đình liên quan'), findsOneWidget);
      expect(find.textContaining('HĐ1'), findsOneWidget);
    });

    testWidgets('should display timeline (createdAt, updatedAt)', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thời gian'), findsOneWidget);
      expect(find.text('Tạo lúc'), findsOneWidget);
      expect(find.text('Cập nhật lúc'), findsOneWidget);
    });
  });

  group('IncidentDetailScreen - Admin Actions', () {
    testWidgets('should show action buttons for admin user', (tester) async {
      mockAuth.isAdmin = true;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cập nhật trạng thái'), findsOneWidget);
      expect(find.text('Phân công'), findsOneWidget);
    });

    testWidgets('should not show action buttons for non-admin user', (
      tester,
    ) async {
      mockAuth.isAdmin = false;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cập nhật trạng thái'), findsNothing);
      expect(find.text('Phân công'), findsNothing);
    });

    testWidgets(
      'should open update status dialog when tapping Cập nhật trạng thái',
      (tester) async {
        mockAuth.isAdmin = true;

        await tester.pumpScreen(
          buildTestScreen(),
          overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cập nhật trạng thái'));
        await tester.pumpAndSettle();

        // Should show dialog with status options
        expect(find.text('Cập nhật trạng thái'), findsWidgets);
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets('should open assign handler dialog when tapping Phân công', (
      tester,
    ) async {
      mockAuth.isAdmin = true;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phân công'));
      await tester.pumpAndSettle();

      expect(find.text('Phân công xử lý'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should show edit and delete in popup menu', (tester) async {
      mockAuth.isAdmin = true;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Tap the more button
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Chỉnh sửa'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
    });
  });
}
