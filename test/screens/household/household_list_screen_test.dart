import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_list_screen.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/navigator_observer.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

/// Fake Route needed for mocktail's registerFallbackValue.
class _FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late FakeAuthProvider mockAuth;
  late FakeHouseholdProvider mockHousehold;
  late FakeHouseholdRequestProvider mockHouseholdRequest;

  late List<Household> sampleHouseholds;

  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

  setUp(() {
    mockAuth = FakeAuthProvider();
    mockAuth.isAdmin = false;
    mockAuth.isLoading = false;
    mockAuth.error = null;
    mockAuth.currentUser = testUser;

    mockHousehold = FakeHouseholdProvider();
    mockHousehold.items = sampleHouseholds = householdList;
    mockHousehold.isLoading = false;
    mockHousehold.error = null;

    mockHouseholdRequest = FakeHouseholdRequestProvider();
  });

  Widget buildTestScreen({ProviderOverrides? overrides}) {
    return const HouseholdListScreen();
  }

  group('HouseholdListScreen - Admin View', () {
    setUp(() {
      mockAuth.isAdmin = true;
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      mockHousehold.isLoading = true;
      mockHousehold.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error display with refresh button', (
      tester,
    ) async {
      const errorMsg = 'Network error';
      mockHousehold.error = errorMsg;
      mockHousehold.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      expect(find.text(errorMsg), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
    });

    testWidgets('should show empty state when no households', (tester) async {
      mockHousehold.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      expect(find.text('Chưa có hộ gia đình nào'), findsOneWidget);
    });

    testWidgets('should render list of household cards', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Title
      expect(find.text('Danh sách hộ gia đình'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Each household name should be visible
      for (final h in sampleHouseholds) {
        expect(find.text(h.headOfHousehold), findsOneWidget);
      }
    });

    testWidgets('should toggle search mode', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Initially not searching
      expect(find.text('Danh sách hộ gia đình'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Tap search icon to enter search mode
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pump();

      // Now search field should appear
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap close icon to exit search
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('Danh sách hộ gia đình'), findsOneWidget);
    });

    testWidgets('should call loadItems with search query on submit', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Enter search mode
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pump();

      // Type query and submit
      await tester.enterText(find.byType(TextField), 'Nguyen');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Verify the searchQuery was set on the provider
      expect(mockHousehold.searchQuery, 'Nguyen');
    });

    testWidgets('should navigate to detail screen on card tap', (tester) async {
      final observer = MockNavigatorObserver();

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
        navigatorObservers: [observer],
      );
      await tester.pumpAndSettle();

      // Tap the first household card
      await tester.tap(find.text(sampleHouseholds[0].headOfHousehold).first);
      await tester.pump(const Duration(milliseconds: 300));

      // Swallow the ProviderNotFoundException from the pushed
      // HouseholdDetailScreen; it's expected because the pushed
      // route isn't wrapped with test providers.
      tester.takeException();

      // Verify a push navigation occurred (2 = initial route + card tap)
      verify(() => observer.didPush(any(), any())).called(2);
    });

    testWidgets('should show popup menu with edit/delete options', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Tap popup menu button (more_vert)
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Sửa'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
    });

    testWidgets('should delete household after confirmation', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Xác nhận xóa'), findsOneWidget);
      expect(find.textContaining('xóa hộ gia đình'), findsOneWidget);

      // Tap confirm
      await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
      await tester.pumpAndSettle();
    });

    testWidgets('should cancel delete dialog', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
    });

    testWidgets('should show linear progress when loading more items', (
      tester,
    ) async {
      mockHousehold.isLoading = true;
      mockHousehold.items = sampleHouseholds;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );

      // Should have items and a linear progress indicator (for refresh loading)
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(sampleHouseholds[0].headOfHousehold), findsOneWidget);
    });
  });

  group('HouseholdListScreen - Non-Admin View', () {
    setUp(() {
      mockAuth.isAdmin = false;
      mockAuth.currentUser = testUser;
    });

    testWidgets('should show user household when found by phone', (
      tester,
    ) async {
      final userHousehold = sampleHouseholds[0];
      mockHousehold.mockSearchByPhone = (_) async => userHousehold;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      // Should show the user's household info
      expect(find.text(userHousehold.headOfHousehold), findsOneWidget);
    });

    testWidgets('should show request button when no household found', (
      tester,
    ) async {
      // No household found by phone
      mockHousehold.mockSearchByPhone = (_) async => null;
      mockHousehold.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      // Should show request button
      expect(find.text('Chưa có thông tin hộ gia đình'), findsOneWidget);
      expect(find.text('Gửi yêu cầu tạo hộ gia đình'), findsOneWidget);
    });

    testWidgets('should show pending request info when request exists', (
      tester,
    ) async {
      mockHousehold.mockSearchByPhone = (_) async => null;
      mockHousehold.items = [];

      // Return a mock pending request
      mockHouseholdRequest.mockGetUserPendingRequest = (_) async => testRequest;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          household: mockHousehold,
          householdRequest: mockHouseholdRequest,
        ),
      );
      await tester.pumpAndSettle();

      // Should show pending request status
      expect(find.text('Đã gửi yêu cầu tạo hộ gia đình'), findsOneWidget);
    });
  });
}
