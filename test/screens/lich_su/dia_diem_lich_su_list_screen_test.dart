import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/screens/lich_su/dia_diem_lich_su_list_screen.dart';
import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/widget_test_utils.dart';
import '../test_helpers/screen_test_data.dart';

void main() {
  late MockDiaDiemLichSuProvider mockDiaDiemLichSu;
  late MockAuthProvider mockAuth;

  setUp(() {
    mockDiaDiemLichSu = MockDiaDiemLichSuProvider();
    mockAuth = MockAuthProvider();

    // Default stubs
    when(() => mockDiaDiemLichSu.isLoading).thenReturn(false);
    when(() => mockDiaDiemLichSu.items).thenReturn([]);
    when(() => mockDiaDiemLichSu.error).thenReturn(null);
    when(
      () => mockDiaDiemLichSu.loadItems(searchQuery: any(named: 'searchQuery')),
    ).thenAnswer((_) async {});

    when(() => mockAuth.isAdmin).thenReturn(false);
  });

  Widget buildTestScreen() {
    return const DiaDiemLichSuListScreen();
  }

  // ====================================================================
  // Rendering
  // ====================================================================
  group('DiaDiemLichSuListScreen - Rendering', () {
    testWidgets('should render app bar with correct title', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Địa điểm lịch sử'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading and empty', (
      tester,
    ) async {
      when(() => mockDiaDiemLichSu.isLoading).thenReturn(true);
      when(() => mockDiaDiemLichSu.items).thenReturn([]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
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
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có địa điểm lịch sử nào'), findsOneWidget);
    });

    testWidgets('should show add button for admin in empty state', (
      tester,
    ) async {
      when(() => mockAuth.isAdmin).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có địa điểm lịch sử nào'), findsOneWidget);
      expect(find.text('Thêm địa điểm lịch sử'), findsOneWidget);
    });

    testWidgets('should show error state with retry button', (tester) async {
      when(() => mockDiaDiemLichSu.error).thenReturn('Lỗi kết nối');
      when(() => mockDiaDiemLichSu.items).thenReturn([]);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lỗi kết nối'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('should show list of places', (tester) async {
      final places = [
        testDiaDiemLichSu,
        DiaDiemLichSu(
          id: 2,
          ten: 'Dinh Độc Lập',
          moTa: 'Dinh lịch sử',
          diaChi: 'Q.1, TP.HCM',
          kinhDo: 106.6954,
          viDo: 10.7790,
          loaiDiTich: 'Di tích',
          imageUrl: null,
          ghiChu: null,
          createdAt: DateTime(2024, 1, 1),
        ),
      ];
      when(() => mockDiaDiemLichSu.items).thenReturn(places);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chợ Bến Thành'), findsOneWidget);
      expect(find.text('Dinh Độc Lập'), findsOneWidget);
      expect(find.text('Chợ'), findsAtLeast(1));
      expect(find.text('Di tích'), findsAtLeast(1));
    });

    testWidgets('should show FAB for admin', (tester) async {
      when(() => mockAuth.isAdmin).thenReturn(true);

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should hide FAB for non-admin', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          auth: mockAuth,
          diaDiemLichSu: mockDiaDiemLichSu,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
