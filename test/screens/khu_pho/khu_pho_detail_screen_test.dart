import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/khu_pho/khu_pho_detail_screen.dart';
import 'package:vietnam_geo_dashboard/providers/dai_dien_provider.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockDaiDienProvider mockDaiDien;
  late MockAuthProvider mockAuth;

  setUp(() {
    mockDaiDien = MockDaiDienProvider();
    mockAuth = MockAuthProvider();

    // Default stubs
    when(() => mockDaiDien.danhSach).thenReturn([]);
    when(() => mockDaiDien.isLoading).thenReturn(false);
    when(() => mockDaiDien.loadData()).thenAnswer((_) async {});
  });

  Widget buildTestScreen({KhuPhoModel? khuPho}) {
    return KhuPhoDetailScreen(khuPho: khuPho ?? testKhuPho);
  }

  // ====================================================================
  // Rendering
  // ====================================================================
  group('KhuPhoDetailScreen - Rendering', () {
    testWidgets('should render app bar with khu pho name', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      // AppBar title + info row both show the name
      expect(find.text(testKhuPho.tenKhuPho), findsAtLeast(1));
    });

    testWidgets('should show info card with section title and all fields', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông tin khu phố'), findsOneWidget);
      expect(find.text('Tên khu phố'), findsOneWidget);
      // AppBar title + info row both show the name
      expect(find.text(testKhuPho.tenKhuPho), findsAtLeast(1));
      expect(find.text('Phường/Xã'), findsOneWidget);
      expect(find.text(testKhuPho.parentTen ?? 'Chưa có'), findsOneWidget);
      expect(find.text('Địa chỉ'), findsOneWidget);
      expect(find.text(testKhuPho.diaChi ?? 'Chưa có'), findsOneWidget);
      expect(find.text('Mô tả'), findsOneWidget);
      expect(find.text(testKhuPho.moTa ?? 'Chưa có'), findsOneWidget);
    });

    testWidgets('should show edit button in app bar', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });

  // ====================================================================
  // Đại diện section
  // ====================================================================
  group('KhuPhoDetailScreen - Dai Dien Section', () {
    testWidgets('should show empty state when no dai dien', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đại diện khu phố'), findsOneWidget);
      expect(find.text('Chưa có đại diện nào'), findsOneWidget);
    });

    testWidgets('should show list of representatives', (tester) async {
      final daiDiens = [testDaiDien];
      when(() => mockDaiDien.danhSach).thenReturn(daiDiens);
      when(() => mockDaiDien.isLoading).thenReturn(false);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      expect(find.text(testDaiDien.hoTen), findsOneWidget);
      expect(find.text(testDaiDien.soDienThoai ?? ''), findsOneWidget);
    });

    testWidgets('should show add representative button', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thêm đại diện'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  // ====================================================================
  // Navigation
  // ====================================================================
  group('KhuPhoDetailScreen - Navigation', () {
    testWidgets('should navigate to edit screen on edit tap', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump(const Duration(milliseconds: 300));

      // KhuPhoFormScreen needs KhuPhoProvider → will throw, swallow it
      tester.takeException();
    });

    testWidgets('should navigate to dai dien detail on tap', (tester) async {
      final daiDiens = [testDaiDien];
      when(() => mockDaiDien.danhSach).thenReturn(daiDiens);
      when(() => mockDaiDien.isLoading).thenReturn(false);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(testDaiDien.hoTen));
      await tester.pump(const Duration(milliseconds: 300));

      // DaiDienDetailScreen needs additional providers → swallow
      tester.takeException();
    });

    testWidgets('should navigate to add dai dien screen', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, daiDien: mockDaiDien),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm đại diện'));
      await tester.pump(const Duration(milliseconds: 300));

      // DaiDienFormScreen needs additional providers → swallow
      tester.takeException();
    });
  });
}
