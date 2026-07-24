import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/screens/khu_pho/khu_pho_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/khu_pho/khu_pho_detail_screen.dart';
import 'package:vietnam_geo_dashboard/screens/khu_pho/khu_pho_form_screen.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/dai_dien_provider.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockKhuPhoProvider mockKhuPho;
  late MockAuthProvider mockAuth;
  late MockProvinceProvider mockProvince;
  late MockDaiDienProvider mockDaiDien;

  setUp(() {
    mockKhuPho = MockKhuPhoProvider();
    mockAuth = MockAuthProvider();
    mockProvince = MockProvinceProvider();
    mockDaiDien = MockDaiDienProvider();

    // Default stubs
    when(() => mockKhuPho.isLoading).thenReturn(false);
    when(() => mockKhuPho.danhSach).thenReturn([]);
    when(() => mockKhuPho.error).thenReturn(null);
    when(() => mockKhuPho.loadData()).thenAnswer((_) async {});

    when(() => mockAuth.isAdmin).thenReturn(false);

    when(() => mockProvince.provinces).thenReturn([]);
    when(() => mockProvince.loadData()).thenAnswer((_) async {});

    when(() => mockDaiDien.danhSach).thenReturn([]);
    when(() => mockDaiDien.loadData()).thenAnswer((_) async {});
  });

  Widget buildTestScreen() {
    return const KhuPhoListScreen();
  }

  // ====================================================================
  // Rendering
  // ====================================================================
  group('KhuPhoListScreen - Rendering', () {
    testWidgets('should render app bar with correct title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Danh sách Khu phố'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      when(() => mockKhuPho.isLoading).thenReturn(true);
      when(() => mockKhuPho.danhSach).thenReturn([]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show empty state when no data', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có khu phố nào'), findsOneWidget);
    });

    testWidgets('should show add button for admin in empty state', (
      tester,
    ) async {
      when(() => mockAuth.isAdmin).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có khu phố nào'), findsOneWidget);
      expect(find.text('Thêm khu phố đầu tiên'), findsOneWidget);
    });

    testWidgets('should show error state with retry button', (tester) async {
      when(() => mockKhuPho.error).thenReturn('Lỗi kết nối');
      when(() => mockKhuPho.danhSach).thenReturn([]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lỗi kết nối'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('should show list of khu pho items', (tester) async {
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khu phố 1'), findsOneWidget);
      expect(find.text('Khu phố 2'), findsOneWidget);
      expect(find.text('Q.1'), findsAtLeast(1));
      expect(find.text('Q.2'), findsAtLeast(1));
    });

    testWidgets('should show add icon for admin in appbar when list not empty', (
      tester,
    ) async {
      when(() => mockAuth.isAdmin).thenReturn(true);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      // When list is not empty, only the AppBar add icon is shown (not the empty state button)
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should hide add icon for non-admin', (tester) async {
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('should show popup menu for admin on item', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsAtLeast(1));
    });

    testWidgets('should hide popup menu for non-admin', (tester) async {
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  // ====================================================================
  // Navigation
  // ====================================================================
  group('KhuPhoListScreen - Navigation', () {
    /// Helper to build full overrides including providers needed by destination screens
    ProviderOverrides _navOverrides() => ProviderOverrides(
      auth: mockAuth,
      khuPho: mockKhuPho,
      province: mockProvince,
      daiDien: mockDaiDien,
    );

    testWidgets('should navigate to form screen on add icon tap', (
      tester,
    ) async {
      when(() => mockAuth.isAdmin).thenReturn(true);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(buildTestScreen(), overrides: _navOverrides());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should navigate away from list screen (list no longer shown)
      expect(find.byType(KhuPhoListScreen), findsNothing);
    });

    testWidgets('should navigate to detail screen on item tap', (tester) async {
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(buildTestScreen(), overrides: _navOverrides());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Khu phố 1'));
      await tester.pumpAndSettle();

      // Should navigate away from list screen
      expect(find.byType(KhuPhoListScreen), findsNothing);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);
      when(() => mockKhuPho.deleteKhuPho(any())).thenAnswer((_) async => true);

      await tester.pumpScreen(buildTestScreen(), overrides: _navOverrides());
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Tap delete option
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Xác nhận xóa'), findsOneWidget);
      expect(find.text('Bạn có chắc muốn xóa "Khu phố 1"?'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Xóa'), findsWidgets);
    });

    testWidgets('should confirm delete and call provider', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);
      when(() => mockKhuPho.deleteKhuPho(any())).thenAnswer((_) async => true);

      await tester.pumpScreen(buildTestScreen(), overrides: _navOverrides());
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Confirm delete in dialog
      await tester.tap(find.text('Xóa').last);
      await tester.pumpAndSettle();

      verify(() => mockKhuPho.deleteKhuPho(1)).called(1);
    });

    testWidgets('should cancel delete and not call provider', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);
      when(() => mockKhuPho.deleteKhuPho(any())).thenAnswer((_) async => true);

      await tester.pumpScreen(buildTestScreen(), overrides: _navOverrides());
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Cancel in dialog
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      verifyNever(() => mockKhuPho.deleteKhuPho(any()));
    });

    testWidgets('should navigate to form screen on edit from popup menu', (
      tester,
    ) async {
      when(() => mockAuth.isAdmin).thenReturn(true);
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(buildTestScreen(), overrides: _navOverrides());
      await tester.pumpAndSettle();

      // Open popup menu on first item
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Tap edit
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();

      // Should navigate away from list screen
      expect(find.byType(KhuPhoListScreen), findsNothing);
    });
  });

  // ====================================================================
  // Parent label display
  // ====================================================================
  group('KhuPhoListScreen - Parent label', () {
    testWidgets('should show parent location label when parentTen exists', (
      tester,
    ) async {
      final itemsWithParent = [
        KhuPhoModel(
          id: 1,
          tenKhuPho: 'Khu phố 1',
          moTa: 'Khu vực trung tâm',
          diaChi: 'Q.1',
          parentTen: 'Quận 1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];
      when(() => mockKhuPho.danhSach).thenReturn(itemsWithParent);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('📍 Quận 1'), findsOneWidget);
    });
  });

  // ====================================================================
  // Refresh
  // ====================================================================
  group('KhuPhoListScreen - Refresh', () {
    testWidgets('should call loadData on pull-to-refresh', (tester) async {
      when(() => mockKhuPho.danhSach).thenReturn(khuPhoList);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      // Trigger refresh by dragging down
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // loadData was called initially in initState, and again on refresh
      verify(() => mockKhuPho.loadData()).called(2);
    });
  });
}
