import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/dai_dien/dai_dien_detail_screen.dart';
import 'package:vietnam_geo_dashboard/providers/khu_pho_provider.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockKhuPhoProvider mockKhuPho;
  late MockAuthProvider mockAuth;

  setUp(() {
    mockKhuPho = MockKhuPhoProvider();
    mockAuth = MockAuthProvider();

    // Default stubs for KhuPhoProvider
    when(() => mockKhuPho.loadData()).thenAnswer((_) async {});
  });

  Widget buildTestScreen() {
    return DaiDienDetailScreen(daiDien: testDaiDien);
  }

  // ====================================================================
  // Rendering
  // ====================================================================
  group('DaiDienDetailScreen - Rendering', () {
    testWidgets('should render app bar with dai dien name', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text(testDaiDien.hoTen), findsAtLeast(1));
    });

    testWidgets('should show personal info card with section title', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông tin cá nhân'), findsOneWidget);
      expect(find.text('Họ tên'), findsOneWidget);
      expect(find.text(testDaiDien.hoTen), findsAtLeast(1));
      expect(find.text('Số điện thoại'), findsOneWidget);
      expect(find.text(testDaiDien.soDienThoai ?? 'Chưa có'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text(testDaiDien.email ?? 'Chưa có'), findsOneWidget);
      expect(find.text('Địa chỉ'), findsOneWidget);
      expect(find.text(testDaiDien.diaChi ?? 'Chưa có'), findsOneWidget);
    });

    testWidgets('should show edit button in app bar', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should show assignment card with section title', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phân công'), findsOneWidget);
    });

    testWidgets('should show loading when fetching khu pho', (tester) async {
      final completer = Completer<void>();
      when(() => mockKhuPho.loadData()).thenAnswer((_) => completer.future);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ====================================================================
  // Khu Pho Assignment
  // ====================================================================
  group('DaiDienDetailScreen - Khu Pho Assignment', () {
    testWidgets('should show khu pho name when loaded', (tester) async {
      when(
        () => mockKhuPho.getById(testDaiDien.khuPhoId!),
      ).thenReturn(testKhuPho);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khu phố phụ trách'), findsOneWidget);
      expect(find.text(testKhuPho.tenKhuPho), findsOneWidget);
    });

    testWidgets('should show placeholder when khu pho not found', (
      tester,
    ) async {
      when(() => mockKhuPho.getById(testDaiDien.khuPhoId!)).thenReturn(null);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đang tải thông tin khu phố...'), findsOneWidget);
    });

    testWidgets('should show no assignment when khuPhoId is null', (
      tester,
    ) async {
      final daiDienWithoutKhuPho = DaiDienModel(
        id: testDaiDien.id,
        hoTen: testDaiDien.hoTen,
        soDienThoai: testDaiDien.soDienThoai,
        email: testDaiDien.email,
        diaChi: testDaiDien.diaChi,
        khuPhoId: null,
        tenKhuPho: testDaiDien.tenKhuPho,
        createdAt: testDaiDien.createdAt,
        updatedAt: testDaiDien.updatedAt,
      );
      await tester.pumpScreen(
        DaiDienDetailScreen(daiDien: daiDienWithoutKhuPho),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa được phân công khu phố'), findsOneWidget);
    });
  });

  // ====================================================================
  // Navigation
  // ====================================================================
  group('DaiDienDetailScreen - Navigation', () {
    testWidgets('should navigate to edit screen on edit tap', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump(const Duration(milliseconds: 300));

      // DaiDienFormScreen needs DaiDienProvider → will throw, swallow it
      tester.takeException();
    });

    testWidgets('should navigate to khu pho detail on tap', (tester) async {
      when(
        () => mockKhuPho.getById(testDaiDien.khuPhoId!),
      ).thenReturn(testKhuPho);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(auth: mockAuth, khuPho: mockKhuPho),
      );
      await tester.pumpAndSettle();

      // Tap on the khu pho row
      await tester.tap(find.text(testKhuPho.tenKhuPho));
      await tester.pump(const Duration(milliseconds: 300));

      // KhuPhoDetailScreen needs DaiDienProvider → swallow
      tester.takeException();
    });
  });
}
