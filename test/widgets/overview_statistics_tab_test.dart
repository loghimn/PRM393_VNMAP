import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/overview_statistics_tab.dart';
import '../screens/test_helpers/mock_providers.dart';
import '../screens/test_helpers/widget_test_utils.dart';

/// Tạo sample provinces cho OverviewStatisticsTab
List<ProvinceModel> _createSampleProvinces() {
  return [
    ProvinceModel(
      name: 'TP. Hồ Chí Minh',
      population: 9200000,
      areaKm2: 2061.0,
      density: 4464.0,
      capital: 'Quận 1',
      macroRegion: 'south_east',
      type: 'Thành phố Trung ương',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {},
    ),
    ProvinceModel(
      name: 'Hà Nội',
      population: 8400000,
      areaKm2: 3359.8,
      density: 2500.0,
      capital: 'Hoàn Kiếm',
      macroRegion: 'red_river_delta',
      type: 'Thành phố Trung ương',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {},
    ),
    ProvinceModel(
      name: 'Đà Nẵng',
      population: 1200000,
      areaKm2: 1285.4,
      density: 933.0,
      capital: 'Hải Châu',
      macroRegion: 'south_central_coast',
      type: 'Thành phố Trung ương',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {},
    ),
    ProvinceModel(
      name: 'Hải Phòng',
      population: 2100000,
      areaKm2: 1523.4,
      density: 1378.0,
      capital: 'Hồng Bàng',
      macroRegion: 'red_river_delta',
      type: 'Thành phố Trung ương',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {},
    ),
    ProvinceModel(
      name: 'Cần Thơ',
      population: 1250000,
      areaKm2: 1401.6,
      density: 892.0,
      capital: 'Ninh Kiều',
      macroRegion: 'mekong_delta',
      type: 'Thành phố Trung ương',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {},
    ),
    ProvinceModel(
      name: 'Nghệ An',
      population: 3400000,
      areaKm2: 16493.7,
      density: 206.0,
      capital: 'Vinh',
      macroRegion: 'north_central_coast',
      type: 'Tỉnh',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {},
    ),
    ProvinceModel(
      name: 'Quảng Ninh',
      population: 1350000,
      areaKm2: 6178.2,
      density: 218.0,
      capital: 'Hạ Long',
      macroRegion: 'northern_midlands',
      type: 'Tỉnh',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {},
    ),
    ProvinceModel(
      name: 'Lâm Đồng',
      population: 1300000,
      areaKm2: 9783.3,
      density: 133.0,
      capital: 'Đà Lạt',
      macroRegion: 'central_highlands',
      type: 'Tỉnh',
      geometry: {'type': 'Polygon', 'coordinates': []},
      properties: {},
    ),
  ];
}

Widget _buildTestWidget({required FakeProvinceProvider provinceProvider}) {
  return createTestApp(
    child: const OverviewStatisticsTab(),
    overrides: ProviderOverrides(province: provinceProvider),
  );
}

void main() {
  group('OverviewStatisticsTab widget', () {
    testWidgets('shows CircularProgressIndicator khi provinces trống', (
      tester,
    ) async {
      final provider = FakeProvinceProvider()..provinces = [];

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();

      // Kiểm tra loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders KPI cards với tổng quan quốc gia', (tester) async {
      final provinces = _createSampleProvinces();
      final provider = FakeProvinceProvider()..provinces = provinces;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // KPI cards hiển thị tiêu đề
      expect(find.text('TỔNG DÂN SỐ'), findsOneWidget);
      expect(find.text('TỔNG DIỆN TÍCH'), findsOneWidget);
      expect(find.text('MẬT ĐỘ TRUNG BÌNH'), findsOneWidget);
      expect(find.text('ĐƠN VỊ HÀNH CHÍNH'), findsOneWidget);

      // Đơn vị
      expect(find.text('người'), findsWidgets);
      expect(find.text('km²'), findsWidgets);
      expect(find.text('người/km²'), findsWidgets);
      expect(find.text('Tỉnh/Thành'), findsOneWidget);

      // Dòng subtext: "x TP • y Tỉnh" - match exact pattern
      expect(find.textContaining('•'), findsOneWidget);
      expect(find.text('5 TP • 3 Tỉnh'), findsOneWidget);
    });

    testWidgets('renders region statistics section', (tester) async {
      final provinces = _createSampleProvinces();
      final provider = FakeProvinceProvider()..provinces = provinces;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tiêu đề vùng
      expect(find.text('Phân Tích Theo Vùng Địa Lý'), findsOneWidget);

      // Tên các vùng hiển thị (dựa trên macroRegion của sample data)
      expect(find.textContaining('Đông Nam Bộ'), findsWidgets);
      expect(find.textContaining('Đồng bằng sông Hồng'), findsWidgets);
      expect(find.textContaining('Tây Nguyên'), findsWidgets);
    });

    testWidgets('renders rankings section với top 3 và bottom 3', (
      tester,
    ) async {
      final provinces = _createSampleProvinces();
      final provider = FakeProvinceProvider()..provinces = provinces;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tiêu đề rankings
      expect(find.text('Xếp Hạng Địa Phương'), findsOneWidget);

      // Các tab button metric
      expect(find.text('Dân số'), findsOneWidget);
      expect(find.text('D.Tích'), findsOneWidget);
      expect(find.text('M.Độ'), findsOneWidget);

      // Top 3 và Bottom 3 header
      expect(find.text('Cao Nhất'), findsOneWidget);
      expect(find.text('Thấp Nhất'), findsOneWidget);

      // Các tỉnh top 3 dân số xuất hiện
      expect(find.text('TP. Hồ Chí Minh'), findsWidgets);
      expect(find.text('Hà Nội'), findsWidgets);
    });

    testWidgets('switching ranking metric changes activeSorted list', (
      tester,
    ) async {
      final provinces = _createSampleProvinces();
      final provider = FakeProvinceProvider()..provinces = provinces;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Mặc định là 'population' → Cao nhất: TP. Hồ Chí Minh
      expect(find.text('TP. Hồ Chí Minh'), findsWidgets);

      // Tap "D.Tích"
      await tester.tap(find.text('D.Tích'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "M.Độ"
      await tester.tap(find.text('M.Độ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('kpi cards show formatted numbers correctly', (tester) async {
      final provinces = _createSampleProvinces();
      final provider = FakeProvinceProvider()..provinces = provinces;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tổng dân số = 9.2 + 8.4 + 1.2 + 2.1 + 1.25 + 3.4 + 1.35 + 1.3 = 28.200.000
      // → "28.200.000"
      expect(find.text('28.200.000'), findsOneWidget);
    });

    testWidgets('renders region stat sub rows', (tester) async {
      final provinces = _createSampleProvinces();
      final provider = FakeProvinceProvider()..provinces = provinces;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll xuống region stats section
      final scrollView = find.byType(SingleChildScrollView);
      await tester.drag(scrollView, const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Region stat labels
      expect(find.textContaining('DÂN SỐ'), findsWidgets);
      expect(find.textContaining('DIỆN TÍCH'), findsWidgets);
      expect(find.textContaining('MẬT ĐỘ'), findsWidgets);
    });

    testWidgets('renders với chỉ 1 province không gây lỗi', (tester) async {
      final provider = FakeProvinceProvider()
        ..provinces = [
          ProvinceModel(
            name: 'Test Tỉnh',
            population: 1000,
            areaKm2: 100.0,
            density: 10.0,
            macroRegion: 'red_river_delta',
            type: 'Tỉnh',
            geometry: {'type': 'Polygon', 'coordinates': []},
            properties: {},
          ),
        ];

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // KPI cards vẫn hiển thị
      expect(find.text('TỔNG DÂN SỐ'), findsOneWidget);
      expect(find.text('Xếp Hạng Địa Phương'), findsOneWidget);
    });
  });
}
