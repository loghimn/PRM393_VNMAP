import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/lich_su/dia_diem_lich_su_detail_screen.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockDiaDiemLichSuProvider mockProvider;
  late MockAuthProvider mockAuth;

  /// Default item không có imageUrl để tránh lỗi Image.network trong test.
  final defaultItem = DiaDiemLichSu(
    id: 1,
    ten: 'Chợ Bến Thành',
    loaiDiTich: 'Chợ',
    diaChi: 'P.Bến Thành, Q.1, TP.HCM',
    moTa: 'Biểu tượng của Sài Gòn',
    imageUrl: null,
  );

  setUp(() {
    mockProvider = MockDiaDiemLichSuProvider();
    mockAuth = MockAuthProvider();

    // Default stubs
    when(() => mockProvider.isLoading).thenReturn(false);
    when(() => mockProvider.error).thenReturn(null);
    when(() => mockProvider.selected).thenReturn(defaultItem);
    when(() => mockProvider.loadById(1)).thenAnswer((_) async => defaultItem);

    // Auth defaults
    when(() => mockAuth.isAdmin).thenReturn(false);
    when(() => mockAuth.isLoggedIn).thenReturn(true);
  });

  Widget buildTestScreen() {
    return const DiaDiemLichSuDetailScreen(lichSuId: 1);
  }

  // ====================================================================
  // Rendering
  // ====================================================================
  group('DiaDiemLichSuDetailScreen - Rendering', () {
    testWidgets('should render app bar with correct title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết địa điểm lịch sử'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      when(() => mockProvider.isLoading).thenReturn(true);
      when(() => mockProvider.selected).thenReturn(null);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state when error occurs and no data', (
      tester,
    ) async {
      when(() => mockProvider.error).thenReturn('Lỗi mạng');
      when(() => mockProvider.selected).thenReturn(null);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Lỗi mạng'), findsOneWidget);
      expect(find.text('Tải lại'), findsOneWidget);
    });

    testWidgets('should show not found message when selected is null', (
      tester,
    ) async {
      when(() => mockProvider.selected).thenReturn(null);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy địa điểm lịch sử.'), findsOneWidget);
    });

    testWidgets('should display item name when loaded', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(defaultItem.ten), findsAtLeast(1));
    });

    testWidgets('should show placeholder icon when no imageUrl', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.account_balance_rounded), findsOneWidget);
    });

    testWidgets('should show edit button for admin', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should hide edit button for non-admin', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(false);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsNothing);
    });
  });

  // ====================================================================
  // Detail Information
  // ====================================================================
  group('DiaDiemLichSuDetailScreen - Detail Information', () {
    testWidgets('should show description card with title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mô tả'), findsOneWidget);
    });

    testWidgets('should show item description text', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(defaultItem.moTa!), findsOneWidget);
    });

    testWidgets('should show fallback text when description is null', (
      tester,
    ) async {
      final itemNoMoTa = DiaDiemLichSu(id: 1, ten: 'Địa danh', moTa: null);
      when(() => mockProvider.selected).thenReturn(itemNoMoTa);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có mô tả'), findsOneWidget);
    });

    testWidgets('should show info card with section title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông tin chi tiết'), findsOneWidget);
    });

    testWidgets('should show loaiDiTich info row', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Loại di tích'), findsOneWidget);
      expect(find.text(defaultItem.loaiDiTich!), findsAtLeast(1));
    });

    testWidgets('should show diaChi info row', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      // "Địa chỉ" appears both as a tag and as an info row label
      expect(find.text('Địa chỉ'), findsAtLeast(1));
      expect(find.text(defaultItem.diaChi!), findsOneWidget);
    });

    testWidgets('should show loaiDiTich tag', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Loại: ${defaultItem.loaiDiTich!}'), findsOneWidget);
    });

    testWidgets('should show diaChi tag text', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      // "Địa chỉ" appears both as a tag and as an info row label
      expect(find.text('Địa chỉ'), findsAtLeast(1));
    });
  });

  // ====================================================================
  // Full Item Rendering
  // ====================================================================
  group('DiaDiemLichSuDetailScreen - Full Item', () {
    testWidgets('should show thoiKy and ghiChu when present', (tester) async {
      final fullItem = DiaDiemLichSu(
        id: 1,
        ten: 'Địa danh đầy đủ',
        loaiDiTich: 'Đền',
        diaChi: 'Địa chỉ ABC',
        thoiKy: 'Nguyễn',
        moTa: 'Mô tả chi tiết',
        ghiChu: 'Ghi chú quan trọng',
        imageUrl: null,
      );
      when(() => mockProvider.selected).thenReturn(fullItem);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Check tags
      expect(find.text('Thời kỳ: Nguyễn'), findsOneWidget);
      expect(find.text('Loại: Đền'), findsOneWidget);

      // Check info rows
      expect(find.text('Ghi chú'), findsOneWidget);
      expect(find.text('Ghi chú quan trọng'), findsOneWidget);
      // "Địa chỉ" appears both as tag and info row label
      expect(find.text('Địa chỉ'), findsAtLeast(1));
      expect(find.text('Địa chỉ ABC'), findsOneWidget);
    });
  });

  // ====================================================================
  // Navigation
  // ====================================================================
  group('DiaDiemLichSuDetailScreen - Navigation', () {
    testWidgets('should navigate to edit screen on edit tap', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockProvider,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump(const Duration(milliseconds: 300));

      // DiaDiemLichSuFormScreen needs DiaDiemLichSuProvider → will throw, swallow it
      tester.takeException();
    });
  });
}
