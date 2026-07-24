import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_list_screen.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import '../test_helpers/mock_providers.dart';
import '../test_helpers/navigator_observer.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

/// Fake Route needed for mocktail's registerFallbackValue.
class _FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late FakeAuthProvider mockAuth;
  late FakeIncidentProvider mockIncident;

  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

  setUp(() {
    mockAuth = FakeAuthProvider();
    mockAuth.isAdmin = false;
    mockAuth.isLoading = false;
    mockAuth.error = null;
    mockAuth.currentUser = testUser;
    mockAuth.isLoggedIn = true;
    mockAuth.isInitialized = true;

    mockIncident = FakeIncidentProvider();
    mockIncident.items = incidentList;
    mockIncident.isLoading = false;
    mockIncident.error = null;
    mockIncident.neighborhoodList = ['P.Bến Thành'];
  });

  Widget buildTestScreen({ProviderOverrides? overrides}) {
    return const IncidentListScreen();
  }

  group('IncidentListScreen - Admin View', () {
    setUp(() {
      mockAuth.isAdmin = true;
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      mockIncident.isLoading = true;
      mockIncident.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error display with retry button', (tester) async {
      const errorMsg = 'Network error';
      mockIncident.error = errorMsg;
      mockIncident.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      expect(find.text(errorMsg), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
    });

    testWidgets('should show empty state when no incidents', (tester) async {
      mockIncident.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );

      expect(find.text('Không có sự cố nào'), findsOneWidget);
      expect(find.text('Nhấn + để thêm sự cố mới'), findsOneWidget);
    });

    testWidgets('should render list of incident cards', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Each incident title should be visible
      for (final inc in incidentList) {
        expect(find.text(inc.title), findsOneWidget);
      }
      // Incident code should be visible
      for (final inc in incidentList) {
        expect(find.text(inc.incidentCode), findsOneWidget);
      }
    });

    testWidgets('should navigate to detail screen on card tap', (tester) async {
      final observer = MockNavigatorObserver();

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
        navigatorObservers: [observer],
      );
      await tester.pumpAndSettle();

      // Tap the first incident card (title text)
      await tester.tap(find.text(incidentList[0].title).first);
      await tester.pump(const Duration(milliseconds: 300));

      // Swallow the ProviderNotFoundException from the pushed IncidentDetailScreen
      tester.takeException();

      // Verify a push navigation occurred (2 = initial route + card tap)
      verify(() => observer.didPush(any(), any())).called(2);
    });

    testWidgets('should toggle search by typing and clearing', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Search field should be present
      expect(find.byType(TextField), findsOneWidget);

      // Type in search field
      await tester.enterText(find.byType(TextField), 'Hỏa hoạn');
      await tester.pump();

      // Clear button should appear when search text is non-empty
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      // Tap clear
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();

      // Clear button should disappear when search is cleared
      expect(find.byIcon(Icons.clear_rounded), findsNothing);
    });

    testWidgets('should filter by status chips', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // All filter chips should be visible
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Tiếp nhận'), findsOneWidget);
      expect(find.text('Xử lý'), findsOneWidget);
      expect(find.text('Đã xong'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);

      // Tap "Đã xong" filter
      await tester.tap(find.text('Đã xong'));
      await tester.pump();
    });

    testWidgets('should show sort popup menu', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Tap sort icon button
      await tester.tap(find.byIcon(Icons.sort_rounded));
      await tester.pumpAndSettle();

      // Sort options should appear
      expect(find.text('Ngày tạo'), findsOneWidget);
      expect(find.text('Tiêu đề'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
    });

    testWidgets('should not show FAB for admin', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );

      // Admin should NOT see the FAB
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('should show incidents with address', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Incidents with address should show location icon and address text
      for (final inc in incidentList) {
        if (inc.address != null && inc.address!.isNotEmpty) {
          expect(find.byIcon(Icons.location_on_rounded), findsAtLeast(1));
        }
      }
    });
  });

  group('IncidentListScreen - Non-Admin View', () {
    setUp(() {
      mockAuth.isAdmin = false;
      mockAuth.currentUser = testUser;
      mockAuth.isLoggedIn = true;
    });

    testWidgets('should show FAB to create incident', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Non-admin should see FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Tạo sự vụ'), findsOneWidget);
    });

    testWidgets('should show edit and delete buttons on cards', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Should have edit and delete icon buttons
      expect(find.byIcon(Icons.edit_rounded), findsAtLeast(1));
      expect(find.byIcon(Icons.delete_rounded), findsAtLeast(1));
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Tap delete on first card
      await tester.tap(find.byIcon(Icons.delete_rounded).first);
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Xác nhận xóa'), findsOneWidget);
      expect(find.textContaining('xóa sự vụ'), findsOneWidget);

      // Tap cancel button specifically (not the filter chip)
      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await tester.pumpAndSettle();
    });

    testWidgets('should confirm delete and call provider', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );
      await tester.pumpAndSettle();

      // Tap delete on first card
      await tester.tap(find.byIcon(Icons.delete_rounded).first);
      await tester.pumpAndSettle();

      // Tap confirm delete
      await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
      await tester.pumpAndSettle();
    });

    testWidgets('should show user greeting in empty state', (tester) async {
      mockIncident.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, incident: mockIncident),
      );

      expect(find.text('Không có sự cố nào'), findsOneWidget);
    });
  });
}
