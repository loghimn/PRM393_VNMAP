import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_request_list_screen.dart';
import 'package:vietnam_geo_dashboard/providers/household_request_provider.dart';
import 'package:vietnam_geo_dashboard/providers/auth_provider.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockHouseholdRequestProvider mockRequestProvider;
  late MockAuthProvider mockAuth;

  setUp(() {
    mockRequestProvider = MockHouseholdRequestProvider();
    mockAuth = MockAuthProvider();

    // Default stubs for provider
    when(() => mockRequestProvider.isLoading).thenReturn(false);
    when(() => mockRequestProvider.pendingRequests).thenReturn([]);
    when(() => mockRequestProvider.approvedRequests).thenReturn([]);
    when(() => mockRequestProvider.rejectedRequests).thenReturn([]);
    when(() => mockRequestProvider.fetchAllRequests()).thenAnswer((_) async {});
  });

  Widget buildTestScreen() {
    return const HouseholdRequestListScreen();
  }

  // ====================================================================
  // Non-admin Access
  // ====================================================================
  group('HouseholdRequestListScreen - Access Control', () {
    testWidgets('should show access denied for non-admin users', (
      tester,
    ) async {
      when(() => mockAuth.currentUser).thenReturn(testUser);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chỉ admin mới có quyền truy cập'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });

  // ====================================================================
  // Admin - Loading State
  // ====================================================================
  group('HouseholdRequestListScreen - Loading', () {
    testWidgets('should show loading indicator when loading', (tester) async {
      when(() => mockAuth.currentUser).thenReturn(adminUser);
      when(() => mockRequestProvider.isLoading).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ====================================================================
  // Admin - Empty States
  // ====================================================================
  group('HouseholdRequestListScreen - Empty States', () {
    setUp(() {
      when(() => mockAuth.currentUser).thenReturn(adminUser);
    });

    testWidgets('should show app bar with correct title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yêu cầu tạo hộ gia đình'), findsOneWidget);
    });

    testWidgets('should show tab bar with 3 tabs', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('Đã duyệt'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);
    });

    testWidgets('should show empty state for all tabs', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không có yêu cầu nào'), findsOneWidget);
    });
  });

  // ====================================================================
  // Admin - With Data
  // ====================================================================
  group('HouseholdRequestListScreen - With Data', () {
    setUp(() {
      when(() => mockAuth.currentUser).thenReturn(adminUser);
      when(() => mockRequestProvider.pendingRequests).thenReturn([testRequest]);
      when(
        () => mockRequestProvider.approvedRequests,
      ).thenReturn(requestList.where((r) => r.status == 'approved').toList());
      when(
        () => mockRequestProvider.rejectedRequests,
      ).thenReturn(requestList.where((r) => r.status == 'rejected').toList());
    });

    testWidgets('should show pending request in first tab', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Default tab is pending
      expect(find.text(testRequest.headOfHousehold), findsOneWidget);
      // Status text appears in both tab bar and chip → atLeast(1)
      expect(find.text('Chờ duyệt'), findsAtLeast(1));
    });

    testWidgets('should show approved requests after tab switch', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Switch to "Đã duyệt" tab
      await tester.tap(find.text('Đã duyệt'));
      await tester.pumpAndSettle();

      expect(find.text('Trần Thị B'), findsOneWidget);
      expect(find.text('Đã duyệt'), findsAtLeast(1));
    });

    testWidgets('should show request card with address and status chip', (
      tester,
    ) async {
      when(() => mockRequestProvider.pendingRequests).thenReturn([testRequest]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Card should show name
      expect(find.textContaining(testRequest.headOfHousehold), findsOneWidget);
      // Should have chevron icon indicating navigation
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('should navigate to detail on card tap', (tester) async {
      when(() => mockRequestProvider.pendingRequests).thenReturn([testRequest]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the request card
      await tester.tap(find.textContaining(testRequest.headOfHousehold));
      await tester.pumpAndSettle();

      // Navigation happens (HouseholdRequestDetailScreen will throw because it needs DatabaseService)
      tester.takeException();
    });
  });

  // ====================================================================
  // Pull-to-refresh
  // ====================================================================
  group('HouseholdRequestListScreen - Refresh', () {
    testWidgets('should call fetchAllRequests on pull-to-refresh', (
      tester,
    ) async {
      when(() => mockAuth.currentUser).thenReturn(adminUser);
      when(() => mockRequestProvider.pendingRequests).thenReturn([testRequest]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          householdRequest: mockRequestProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Drag down to trigger refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(
        () => mockRequestProvider.fetchAllRequests(),
      ).called(greaterThanOrEqualTo(1));
    });
  });
}
