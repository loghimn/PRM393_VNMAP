import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/lich_su/dia_diem_lich_su_form_screen.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockDiaDiemLichSuProvider mockDiaDiemLichSu;
  late MockAuthProvider mockAuth;

  setUpAll(() {
    registerFallbackValue(DiaDiemLichSu(ten: ''));
  });

  setUp(() {
    mockDiaDiemLichSu = MockDiaDiemLichSuProvider();
    mockAuth = MockAuthProvider();

    // Default stubs
    when(() => mockDiaDiemLichSu.isLoading).thenReturn(false);
    when(() => mockDiaDiemLichSu.error).thenReturn(null);
    when(() => mockDiaDiemLichSu.create(any())).thenAnswer((_) async => true);
    when(() => mockDiaDiemLichSu.update(any())).thenAnswer((_) async => true);

    when(() => mockAuth.isAdmin).thenReturn(false);
  });

  Widget buildCreateScreen() {
    return const DiaDiemLichSuFormScreen();
  }

  Widget buildEditScreen() {
    return DiaDiemLichSuFormScreen(lichSu: testDiaDiemLichSu);
  }

  /// Helper: fill all required fields
  Future<void> fillRequiredFields(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên di tích'),
      'Địa điểm test',
    );
  }

  /// Helper: tap the submit button, scrolling to make it visible first.
  Future<void> tapSubmitButton(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu lại'), warnIfMissed: false);
  }

  /// Helper: tap the update button, scrolling to make it visible first.
  Future<void> tapUpdateButton(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cập nhật'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cập nhật'), warnIfMissed: false);
  }

  // ====================================================================
  // Rendering
  // ====================================================================
  group('DiaDiemLichSuFormScreen - Rendering', () {
    testWidgets('should render create mode with correct title', (tester) async {
      await tester.pumpScreen(
        buildCreateScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thêm địa điểm lịch sử'), findsOneWidget);
      expect(find.text('Lưu lại'), findsOneWidget);
    });

    testWidgets('should render edit mode with correct title', (tester) async {
      await tester.pumpScreen(
        buildEditScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sửa địa điểm lịch sử'), findsOneWidget);
      expect(find.text('Cập nhật'), findsOneWidget);
    });

    testWidgets('should pre-fill fields in edit mode', (tester) async {
      await tester.pumpScreen(
        buildEditScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Tên di tích'),
            )
            .controller
            ?.text,
        equals('Chợ Bến Thành'),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Loại di tích'),
            )
            .controller
            ?.text,
        equals('Chợ'),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Địa chỉ'),
            )
            .controller
            ?.text,
        equals('P.Bến Thành, Q.1, TP.HCM'),
      );
    });

    testWidgets('should show all fields', (tester) async {
      await tester.pumpScreen(
        buildCreateScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tên di tích'), findsOneWidget);
      expect(find.text('Loại di tích'), findsOneWidget);
      expect(find.text('Địa chỉ'), findsOneWidget);
      expect(find.text('Thời kỳ'), findsOneWidget);
      expect(find.text('URL ảnh'), findsOneWidget);
      expect(find.text('Mô tả'), findsOneWidget);
      expect(find.text('Ghi chú'), findsOneWidget);
    });
  });

  // ====================================================================
  // Validation
  // ====================================================================
  group('DiaDiemLichSuFormScreen - Validation', () {
    testWidgets('should show error when name is empty on submit', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildCreateScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      // Tap save without filling required fields
      await tapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập Tên di tích'), findsOneWidget);
    });

    testWidgets('should call create on valid form in create mode', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildCreateScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      await fillRequiredFields(tester);
      await tapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockDiaDiemLichSu.create(any())).called(1);
    });

    testWidgets('should call update on valid form in edit mode', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildEditScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      await tapUpdateButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockDiaDiemLichSu.update(any())).called(1);
    });

    testWidgets('should not submit when create fails', (tester) async {
      when(
        () => mockDiaDiemLichSu.create(any()),
      ).thenAnswer((_) async => false);
      when(() => mockDiaDiemLichSu.error).thenReturn('Lỗi tạo địa điểm');

      await tester.pumpScreen(
        buildCreateScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      await fillRequiredFields(tester);
      await tapSubmitButton(tester);
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('Lỗi tạo địa điểm'), findsOneWidget);
    });

    testWidgets('should show loading state while saving', (tester) async {
      when(() => mockDiaDiemLichSu.create(any())).thenAnswer((_) async {
        // Don't complete immediately so we can check loading state
        await Future.delayed(const Duration(seconds: 1));
        return true;
      });

      await tester.pumpScreen(
        buildCreateScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      await fillRequiredFields(tester);
      await tapSubmitButton(tester);
      // Pump a frame to trigger setState (shows loading indicator)
      await tester.pump(const Duration(milliseconds: 50));

      // Should show progress indicator on button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance past the 1-second delay so the pending Future.delayed fires
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });
  });
}
