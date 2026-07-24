import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/dai_dien/dai_dien_list_screen.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockDaiDienProvider mockDaiDien;
  late MockKhuPhoProvider mockKhuPho;
  late MockAuthProvider mockAuth;

  setUp(() {
    mockDaiDien = MockDaiDienProvider();
    mockKhuPho = MockKhuPhoProvider();
    mockAuth = MockAuthProvider();

    // Default stubs
    when(() => mockDaiDien.isLoading).thenReturn(false);
    when(() => mockDaiDien.danhSach).thenReturn([]);
    when(() => mockDaiDien.ketQuaTimKiem).thenReturn([]);
    when(() => mockDaiDien.isSearching).thenReturn(false);
    when(() => mockDaiDien.loadData()).thenAnswer((_) async {});
    when(() => mockDaiDien.search(any())).thenAnswer((_) async {});
    when(() => mockDaiDien.clearSearch()).thenReturn(null);

    when(() => mockKhuPho.isLoading).thenReturn(false);
    when(() => mockKhuPho.danhSach).thenReturn([]);
    when(() => mockKhuPho.loadData()).thenAnswer((_) async {});

    when(() => mockAuth.isAdmin).thenReturn(false);
  });

  Widget buildTestScreen() {
    return const DaiDienListScreen();
  }

  // ====================================================================
  // Rendering
  // ====================================================================
  group('DaiDienListScreen - Rendering', () {
    testWidgets('should render app bar with correct title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đại diện khu phố'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      when(() => mockDaiDien.isLoading).thenReturn(true);
      when(() => mockKhuPho.isLoading).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show empty state when no data', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có dữ liệu'), findsOneWidget);
      // Non-admin should NOT see the hint
      expect(find.text('Thêm khu phố và đại diện để quản lý'), findsNothing);
    });

    testWidgets('should show empty state with hint for admin', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có dữ liệu'), findsOneWidget);
      expect(find.text('Thêm khu phố và đại diện để quản lý'), findsOneWidget);
    });

    testWidgets('should show grouped list with khu pho sections', (
      tester,
    ) async {
      when(() => mockDaiDien.danhSach).thenReturn([testDaiDien]);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      // Khu pho names should be shown
      expect(find.text('Khu phố 1'), findsOneWidget);
      expect(find.text('Khu phố 2'), findsOneWidget);
      // Subtitle count
      expect(find.text('1 đại diện'), findsOneWidget);

      // Tap to expand the first khu pho group
      await tester.tap(find.text('Khu phố 1'));
      await tester.pumpAndSettle();

      // Dai dien name should now be visible inside expanded tile
      expect(find.text(testDaiDien.hoTen), findsAtLeast(1));
    });

    testWidgets('should show unassigned section when dai dien has no khu pho', (
      tester,
    ) async {
      final unassigned = DaiDienModel(id: 3, hoTen: 'Nguyễn Không KP');
      when(() => mockDaiDien.danhSach).thenReturn([unassigned]);
      when(() => mockKhuPho.danhSach).thenReturn([]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa phân công'), findsOneWidget);
      expect(find.text('Nguyễn Không KP'), findsAtLeast(1));
    });

    testWidgets('should show search bar', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tìm kiếm đại diện...'), findsOneWidget);
    });

    testWidgets('should show FAB for admin', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should hide FAB for non-admin', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(false);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  // ====================================================================
  // Search
  // ====================================================================
  group('DaiDienListScreen - Search', () {
    testWidgets('should trigger search when typing', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Nguyễn');
      await tester.pump();

      verify(() => mockDaiDien.search('Nguyễn')).called(1);
    });

    testWidgets('should display search results', (tester) async {
      final searchResults = [
        DaiDienModel(
          id: 3,
          hoTen: 'Nguyễn Văn D',
          soDienThoai: '0999888777',
          tenKhuPho: 'Khu phố 1',
        ),
      ];
      when(() => mockDaiDien.ketQuaTimKiem).thenReturn(searchResults);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      // Type to switch to search results view
      await tester.enterText(find.byType(TextField), 'Nguyễn');
      await tester.pump();

      // Search result should appear
      expect(find.text('Nguyễn Văn D'), findsOneWidget);
    });

    testWidgets('should show loading in search results', (tester) async {
      when(() => mockDaiDien.isSearching).thenReturn(true);
      when(() => mockDaiDien.ketQuaTimKiem).thenReturn([]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      // Type to enter search mode
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show no results message', (tester) async {
      when(() => mockDaiDien.isSearching).thenReturn(false);
      when(() => mockDaiDien.ketQuaTimKiem).thenReturn([]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump();

      expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
    });

    testWidgets('should clear search and return to grouped view', (
      tester,
    ) async {
      when(() => mockDaiDien.danhSach).thenReturn([testDaiDien]);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
        ),
      );
      await tester.pumpAndSettle();

      // First enter search mode
      await tester.enterText(find.byType(TextField), 'Nguyễn');
      await tester.pump();

      // Find and tap clear button
      expect(find.byIcon(Icons.clear), findsOneWidget);
      await tester.tap(find.byIcon(Icons.clear));
      // Text is cleared, need pump for the setState to trigger
      await tester.pump();
      await tester.pump();

      verify(() => mockDaiDien.clearSearch()).called(1);
      // After clearing, grouped view should show again
      expect(find.text('Khu phố 1'), findsOneWidget);
      expect(find.text('Khu phố 2'), findsOneWidget);
    });
  });
}
