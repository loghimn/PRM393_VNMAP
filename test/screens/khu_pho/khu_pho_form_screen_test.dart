import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/khu_pho/khu_pho_form_screen.dart';
import 'package:vietnam_geo_dashboard/providers/khu_pho_provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockKhuPhoProvider mockKhuPho;
  late MockProvinceProvider mockProvince;

  setUpAll(() {
    registerFallbackValue(KhuPhoModel(id: 1, tenKhuPho: 'Fallback'));
  });

  setUp(() {
    mockKhuPho = MockKhuPhoProvider();
    mockProvince = MockProvinceProvider();

    // Default stubs for KhuPhoProvider
    when(() => mockKhuPho.isLoading).thenReturn(false);
    when(() => mockKhuPho.error).thenReturn(null);
    when(() => mockKhuPho.addKhuPho(any())).thenAnswer((_) async => true);
    when(() => mockKhuPho.updateKhuPho(any())).thenAnswer((_) async => true);

    // Default stubs for ProvinceProvider
    when(() => mockProvince.provinces).thenReturn([]);
    when(() => mockProvince.loadData()).thenAnswer((_) async {});
  });

  group('KhuPhoFormScreen - Rendering', () {
    testWidgets('should show create mode title when no khu pho provided', (
      tester,
    ) async {
      await tester.pumpScreen(
        const KhuPhoFormScreen(),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thêm khu phố'), findsOneWidget);
    });

    testWidgets('should show edit mode title when khu pho provided', (
      tester,
    ) async {
      await tester.pumpScreen(
        KhuPhoFormScreen(khuPho: testKhuPho),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sửa khu phố'), findsOneWidget);
    });

    testWidgets('should pre-fill fields in edit mode', (tester) async {
      await tester.pumpScreen(
        KhuPhoFormScreen(khuPho: testKhuPho),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Find text fields with pre-filled values
      final tenField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect((tenField.controller?.text), equals(testKhuPho.tenKhuPho));
    });

    testWidgets(
      'should render submit button with correct label in create mode',
      (tester) async {
        await tester.pumpScreen(
          const KhuPhoFormScreen(),
          overrides: ProviderOverrides(
            khuPho: mockKhuPho,
            province: mockProvince,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Thêm mới'), findsOneWidget);
      },
    );

    testWidgets('should render submit button with correct label in edit mode', (
      tester,
    ) async {
      await tester.pumpScreen(
        KhuPhoFormScreen(khuPho: testKhuPho),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cập nhật'), findsOneWidget);
    });
  });

  group('KhuPhoFormScreen - Validation', () {
    testWidgets('should show error when name is empty on submit', (
      tester,
    ) async {
      await tester.pumpScreen(
        const KhuPhoFormScreen(),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit with empty fields
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tên khu phố'), findsOneWidget);
      // Verify provider was NOT called (validation failed)
      verifyNever(() => mockKhuPho.addKhuPho(any()));
    });

    testWidgets('should not show error when name is filled', (tester) async {
      await tester.pumpScreen(
        const KhuPhoFormScreen(),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextFormField).first, 'Khu phố test');
      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tên khu phố'), findsNothing);
    });
  });

  group('KhuPhoFormScreen - Create', () {
    testWidgets('should call addKhuPho when submitting in create mode', (
      tester,
    ) async {
      when(() => mockKhuPho.addKhuPho(any())).thenAnswer((_) async => true);

      // Add spy to capture addKhuPho calls
      when(() => mockKhuPho.addKhuPho(any())).thenAnswer((_) async => true);

      await tester.pumpScreen(
        const KhuPhoFormScreen(),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Khu phố mới');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      verify(() => mockKhuPho.addKhuPho(any())).called(1);
    });

    testWidgets('should show snackbar when create fails', (tester) async {
      when(() => mockKhuPho.addKhuPho(any())).thenAnswer((_) async => false);
      when(() => mockKhuPho.error).thenReturn('Lỗi tạo mới');

      await tester.pumpScreen(
        const KhuPhoFormScreen(),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Khu phố lỗi');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Lỗi tạo mới'), findsOneWidget);
    });

    testWidgets('should show loading indicator while submitting', (
      tester,
    ) async {
      // Use a completer that never completes to simulate loading
      final completer = Completer<bool>();
      when(
        () => mockKhuPho.addKhuPho(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpScreen(
        const KhuPhoFormScreen(),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Khu phố mới');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Thêm mới'));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Button text should be hidden
      expect(find.text('Thêm mới'), findsNothing);
    });
  });

  group('KhuPhoFormScreen - Edit', () {
    testWidgets('should call updateKhuPho when submitting in edit mode', (
      tester,
    ) async {
      when(() => mockKhuPho.updateKhuPho(any())).thenAnswer((_) async => true);

      await tester.pumpScreen(
        KhuPhoFormScreen(khuPho: testKhuPho),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Change name
      await tester.enterText(find.byType(TextFormField).first, 'Khu phố sửa');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Cập nhật'));
      await tester.pumpAndSettle();

      verify(() => mockKhuPho.updateKhuPho(any())).called(1);
    });

    testWidgets('should show snackbar when update fails', (tester) async {
      when(() => mockKhuPho.updateKhuPho(any())).thenAnswer((_) async => false);
      when(() => mockKhuPho.error).thenReturn('Lỗi cập nhật');

      await tester.pumpScreen(
        KhuPhoFormScreen(khuPho: testKhuPho),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Change name
      await tester.enterText(
        find.byType(TextFormField).first,
        'Khu phố sửa lỗi',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Cập nhật'));
      await tester.pumpAndSettle();

      expect(find.text('Lỗi cập nhật'), findsOneWidget);
    });
  });

  group('KhuPhoFormScreen - Province Dropdown', () {
    testWidgets('should populate province dropdown from provider', (
      tester,
    ) async {
      final provinces = [
        ProvinceModel(
          name: 'TP.HCM',
          geometry: <String, dynamic>{},
          properties: const {'type': 'province'},
        ),
        ProvinceModel(
          name: 'Hà Nội',
          geometry: <String, dynamic>{},
          properties: const {'type': 'province'},
        ),
      ];
      when(() => mockProvince.provinces).thenReturn(provinces);

      await tester.pumpScreen(
        const KhuPhoFormScreen(),
        overrides: ProviderOverrides(
          khuPho: mockKhuPho,
          province: mockProvince,
        ),
      );
      await tester.pumpAndSettle();

      // Tap dropdown to open it and see the items
      await tester.tap(find.text('-- Chọn tỉnh/thành --'));
      await tester.pumpAndSettle();

      expect(find.text('TP.HCM'), findsOneWidget);
      expect(find.text('Hà Nội'), findsOneWidget);
    });
  });
}
