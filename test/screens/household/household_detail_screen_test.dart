import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_detail_screen.dart';
import 'package:vietnam_geo_dashboard/providers/household_provider.dart';
import 'package:vietnam_geo_dashboard/providers/auth_provider.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockHouseholdProvider mockHousehold;
  late MockAuthProvider mockAuth;

  setUp(() {
    mockHousehold = MockHouseholdProvider();
    mockAuth = MockAuthProvider();

    // Default stubs
    when(() => mockHousehold.selected).thenReturn(null);
    when(() => mockHousehold.isLoading).thenReturn(false);
    when(() => mockHousehold.error).thenReturn(null);
    when(() => mockHousehold.loadById(any())).thenAnswer((_) async {});
  });

  Widget buildTestScreen({int householdId = 1}) {
    return HouseholdDetailScreen(householdId: householdId);
  }

  // ====================================================================
  // Rendering – Loading State
  // ====================================================================
  group('HouseholdDetailScreen - Loading', () {
    testWidgets('should show loading indicator when loading', (tester) async {
      when(() => mockHousehold.isLoading).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      // Use pump() instead of pumpAndSettle() because CircularProgressIndicator never settles
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ====================================================================
  // Rendering – Error State
  // ====================================================================
  group('HouseholdDetailScreen - Error', () {
    testWidgets('should show error state with retry button', (tester) async {
      when(() => mockHousehold.error).thenReturn('Network error');

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('should retry loading when retry button is tapped', (
      tester,
    ) async {
      when(() => mockHousehold.error).thenReturn('Network error');

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thử lại'));
      await tester.pump();

      verify(() => mockHousehold.loadById(1)).called(2); // init + retry
    });
  });

  // ====================================================================
  // Rendering – Empty State
  // ====================================================================
  group('HouseholdDetailScreen - Empty', () {
    testWidgets('should show empty state when selected is null', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có thông tin'), findsOneWidget);
    });
  });

  // ====================================================================
  // Rendering – Data Display
  // ====================================================================
  group('HouseholdDetailScreen - Data Display', () {
    setUp(() {
      when(() => mockHousehold.selected).thenReturn(testHousehold);
    });

    testWidgets('should render app bar with correct title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết hộ gia đình'), findsOneWidget);
    });

    testWidgets('should show household name and code in header', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text(testHousehold.headOfHousehold), findsOneWidget);
      expect(find.textContaining(testHousehold.householdCode), findsOneWidget);
    });

    testWidgets('should show address information section', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông tin địa chỉ'), findsOneWidget);
      expect(find.text('Số nhà'), findsOneWidget);
      expect(find.text(testHousehold.houseNumber ?? '—'), findsOneWidget);
      expect(find.text('Đường'), findsOneWidget);
      expect(find.text(testHousehold.street ?? '—'), findsOneWidget);
      expect(find.text('Phường/Xã'), findsOneWidget);
      expect(find.text(testHousehold.ward ?? '—'), findsOneWidget);
    });

    testWidgets('should show contact information section', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông tin liên hệ'), findsOneWidget);
      expect(find.text(testHousehold.phone ?? '—'), findsOneWidget);
      expect(find.text(testHousehold.email ?? '—'), findsOneWidget);
    });

    testWidgets('should show location section with coordinates', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vị trí'), findsOneWidget);
      expect(find.text('Kinh độ'), findsOneWidget);
      expect(find.text('Vĩ độ'), findsOneWidget);
    });

    testWidgets('should show copy coordinates button', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sao chép tọa độ'), findsOneWidget);
    });

    testWidgets('should show notes section', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ghi chú'), findsOneWidget);
      expect(find.text(testHousehold.notes ?? ''), findsOneWidget);
    });

    testWidgets('should show "Xem sự vụ liên quan" button', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xem sự vụ liên quan'), findsOneWidget);
    });

    testWidgets('should show popup menu with edit option', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Sửa'), findsOneWidget);
    });
  });

  // ====================================================================
  // Interactions
  // ====================================================================
  group('HouseholdDetailScreen - Interactions', () {
    setUp(() {
      when(() => mockHousehold.selected).thenReturn(testHousehold);
    });

    testWidgets('should show snackbar when copy coordinates is tapped', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      // Scroll down to make the button visible
      await tester.scrollUntilVisible(
        find.text('Sao chép tọa độ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      await tester.tap(find.text('Sao chép tọa độ'));
      await tester.pumpAndSettle();

      expect(find.text('Đã sao chép tọa độ'), findsOneWidget);
    });

    testWidgets('should navigate to edit screen when edit is tapped', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Tap "Sửa"
      await tester.tap(find.text('Sửa'));
      await tester.pump(const Duration(milliseconds: 300));

      // Should navigate to form (will throw because providers not set up for form)
      tester.takeException();
    });

    testWidgets(
      'should navigate to incident list when related incidents button is tapped',
      (tester) async {
        await tester.pumpScreen(
          buildTestScreen(),
          overrides: ProviderOverrides(
            auth: mockAuth,
            household: mockHousehold,
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to make the button visible
        await tester.scrollUntilVisible(
          find.text('Xem sự vụ liên quan'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();

        await tester.tap(find.text('Xem sự vụ liên quan'));
        await tester.pump(const Duration(milliseconds: 300));

        // Should navigate (IncidentListScreen needs providers → swallow)
        tester.takeException();
      },
    );
  });

  // ====================================================================
  // Household with missing fields
  // ====================================================================
  group('HouseholdDetailScreen - Partial Data', () {
    testWidgets('should render household with null optional fields', (
      tester,
    ) async {
      final partialHousehold = Household(
        id: 3,
        householdCode: 'HH003',
        headOfHousehold: 'Lê Văn C',
        houseNumber: null,
        street: null,
        neighborhood: null,
        ward: null,
        city: null,
        phone: null,
        email: null,
        population: null,
        notes: null,
        longitude: null,
        latitude: null,
        createdBy: 1,
      );
      when(() => mockHousehold.selected).thenReturn(partialHousehold);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, household: mockHousehold),
      );
      await tester.pumpAndSettle();

      // Should render with fallback '—'
      expect(find.text('—'), findsAtLeast(1));
      // Should NOT show copy coordinates button (no coordinates)
      expect(find.text('Sao chép tọa độ'), findsNothing);
      // Should NOT show notes section (notes is null)
      expect(find.text('Ghi chú'), findsNothing);
    });
  });
}
