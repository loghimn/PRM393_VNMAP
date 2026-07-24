import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/dai_dien/dai_dien_form_screen.dart';
import 'package:vietnam_geo_dashboard/providers/dai_dien_provider.dart';
import 'package:vietnam_geo_dashboard/providers/khu_pho_provider.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockDaiDienProvider mockDaiDien;
  late MockKhuPhoProvider mockKhuPho;
  late MockAuthProvider mockAuth;

  setUpAll(() {
    registerFallbackValue(DaiDienModel(id: 1, hoTen: 'Fallback'));
    registerFallbackValue(KhuPhoModel(id: 1, tenKhuPho: 'Fallback'));
  });

  setUp(() {
    mockDaiDien = MockDaiDienProvider();
    mockKhuPho = MockKhuPhoProvider();
    mockAuth = MockAuthProvider();

    // Default stubs for DaiDienProvider
    when(() => mockDaiDien.isLoading).thenReturn(false);
    when(() => mockDaiDien.error).thenReturn(null);
    when(() => mockDaiDien.addDaiDien(any())).thenAnswer((_) async => true);
    when(() => mockDaiDien.updateDaiDien(any())).thenAnswer((_) async => true);

    // Default stubs for KhuPhoProvider
    // Include a default khu pho matching testDaiDien.khuPhoId (1)
    when(
      () => mockKhuPho.danhSach,
    ).thenReturn([KhuPhoModel(id: 1, tenKhuPho: 'Khu phố 1')]);
    when(() => mockKhuPho.loadData()).thenAnswer((_) async {});
  });

  group('DaiDienFormScreen - Rendering', () {
    testWidgets('should show create mode title when no dai dien provided', (
      tester,
    ) async {
      await tester.pumpScreen(
        const DaiDienFormScreen(),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thêm đại diện'), findsOneWidget);
    });

    testWidgets('should show edit mode title when dai dien provided', (
      tester,
    ) async {
      await tester.pumpScreen(
        DaiDienFormScreen(daiDien: testDaiDien),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sửa đại diện'), findsOneWidget);
    });

    testWidgets('should pre-fill fields in edit mode', (tester) async {
      // Ensure khu pho list has the matching id for testDaiDien.khuPhoId (1)
      when(
        () => mockKhuPho.danhSach,
      ).thenReturn([KhuPhoModel(id: 1, tenKhuPho: 'Khu phố 1')]);

      await tester.pumpScreen(
        DaiDienFormScreen(daiDien: testDaiDien),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Find all TextFormFields and check their controllers
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));

      final hoTenField = tester.widget<TextFormField>(fields.at(0));
      expect(hoTenField.controller?.text, equals(testDaiDien.hoTen));

      final phoneField = tester.widget<TextFormField>(fields.at(1));
      expect(
        phoneField.controller?.text,
        equals(testDaiDien.soDienThoai ?? ''),
      );

      final emailField = tester.widget<TextFormField>(fields.at(2));
      expect(emailField.controller?.text, equals(testDaiDien.email ?? ''));

      final addressField = tester.widget<TextFormField>(fields.at(3));
      expect(addressField.controller?.text, equals(testDaiDien.diaChi ?? ''));
    });

    testWidgets(
      'should render submit button with correct label in create mode',
      (tester) async {
        await tester.pumpScreen(
          const DaiDienFormScreen(),
          overrides: ProviderOverrides(
            daiDien: mockDaiDien,
            khuPho: mockKhuPho,
            auth: mockAuth,
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
        DaiDienFormScreen(daiDien: testDaiDien),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cập nhật'), findsOneWidget);
    });
  });

  group('DaiDienFormScreen - Validation', () {
    testWidgets('should show error when name is empty on submit', (
      tester,
    ) async {
      await tester.pumpScreen(
        const DaiDienFormScreen(),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thêm mới'));
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
      // Verify provider was NOT called (validation failed)
      verifyNever(() => mockDaiDien.addDaiDien(any()));
    });

    testWidgets('should not show error when name is filled', (tester) async {
      await tester.pumpScreen(
        const DaiDienFormScreen(),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn A');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thêm mới'));
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập họ tên'), findsNothing);
    });
  });

  group('DaiDienFormScreen - Create', () {
    testWidgets('should call addDaiDien when submitting in create mode', (
      tester,
    ) async {
      when(() => mockDaiDien.addDaiDien(any())).thenAnswer((_) async => true);

      await tester.pumpScreen(
        const DaiDienFormScreen(),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn A');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thêm mới'));
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      verify(() => mockDaiDien.addDaiDien(any())).called(1);
    });

    testWidgets('should show snackbar when create fails', (tester) async {
      when(() => mockDaiDien.addDaiDien(any())).thenAnswer((_) async => false);
      when(() => mockDaiDien.error).thenReturn('Lỗi tạo mới');

      await tester.pumpScreen(
        const DaiDienFormScreen(),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn A');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thêm mới'));
      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Lỗi tạo mới'), findsOneWidget);
    });

    testWidgets('should show loading indicator while submitting', (
      tester,
    ) async {
      final completer = Completer<bool>();
      when(
        () => mockDaiDien.addDaiDien(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpScreen(
        const DaiDienFormScreen(),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Fill name
      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn A');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thêm mới'));
      await tester.tap(find.text('Thêm mới'));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Button text should be hidden
      expect(find.text('Thêm mới'), findsNothing);
    });
  });

  group('DaiDienFormScreen - Edit', () {
    testWidgets('should call updateDaiDien when submitting in edit mode', (
      tester,
    ) async {
      when(
        () => mockDaiDien.updateDaiDien(any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockKhuPho.danhSach,
      ).thenReturn([KhuPhoModel(id: 1, tenKhuPho: 'Khu phố 1')]);

      await tester.pumpScreen(
        DaiDienFormScreen(daiDien: testDaiDien),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Change name
      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn B');
      await tester.pumpAndSettle();

      // Scroll to button and tap
      await tester.ensureVisible(find.text('Cập nhật'));
      await tester.tap(find.text('Cập nhật'));
      await tester.pumpAndSettle();

      verify(() => mockDaiDien.updateDaiDien(any())).called(1);
    });

    testWidgets('should show snackbar when update fails', (tester) async {
      when(
        () => mockDaiDien.updateDaiDien(any()),
      ).thenAnswer((_) async => false);
      when(() => mockDaiDien.error).thenReturn('Lỗi cập nhật');
      when(
        () => mockKhuPho.danhSach,
      ).thenReturn([KhuPhoModel(id: 1, tenKhuPho: 'Khu phố 1')]);

      await tester.pumpScreen(
        DaiDienFormScreen(daiDien: testDaiDien),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Change name
      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Văn B');
      await tester.pumpAndSettle();

      // Scroll to button and tap
      await tester.ensureVisible(find.text('Cập nhật'));
      await tester.tap(find.text('Cập nhật'));
      await tester.pumpAndSettle();

      expect(find.text('Lỗi cập nhật'), findsOneWidget);
    });
  });

  group('DaiDienFormScreen - Khu Pho Dropdown', () {
    testWidgets('should populate khu pho dropdown from provider', (
      tester,
    ) async {
      final danhSach = [
        KhuPhoModel(id: 1, tenKhuPho: 'Khu phố 1'),
        KhuPhoModel(id: 2, tenKhuPho: 'Khu phố 2'),
      ];
      when(() => mockKhuPho.danhSach).thenReturn(danhSach);

      await tester.pumpScreen(
        const DaiDienFormScreen(),
        overrides: ProviderOverrides(
          daiDien: mockDaiDien,
          khuPho: mockKhuPho,
          auth: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Tap dropdown to open it and see the items
      final dropdown = find.text('-- Chưa phân công --');
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      expect(find.text('Khu phố 1'), findsOneWidget);
      expect(find.text('Khu phố 2'), findsOneWidget);
    });
  });
}
