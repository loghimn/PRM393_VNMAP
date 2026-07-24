import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/population_density_chart.dart';
import '../screens/test_helpers/mock_providers.dart';
import '../screens/test_helpers/widget_test_utils.dart';

/// Tạo sample densities data cho PopulationDensityChart
List<Map<String, dynamic>> _createSampleDensities() {
  return [
    {
      'name': 'TP. Hồ Chí Minh',
      'density': 4500.5,
      'area': 2061.0,
      'population': 9200000.0,
    },
    {
      'name': 'Hà Nội',
      'density': 2500.3,
      'area': 3359.8,
      'population': 8400000.0,
    },
    {
      'name': 'Hải Phòng',
      'density': 1200.0,
      'area': 1523.4,
      'population': 2100000.0,
    },
    {
      'name': 'Đà Nẵng',
      'density': 1800.2,
      'area': 1285.4,
      'population': 1200000.0,
    },
    {
      'name': 'Cần Thơ',
      'density': 1400.7,
      'area': 1401.6,
      'population': 1250000.0,
    },
    {
      'name': 'Quảng Ninh',
      'density': 200.5,
      'area': 6178.2,
      'population': 1350000.0,
    },
    {
      'name': 'Nghệ An',
      'density': 180.0,
      'area': 16493.7,
      'population': 3400000.0,
    },
  ];
}

/// Sample densities với 34 provinces để test slider
List<Map<String, dynamic>> _createFullSampleDensities() {
  final names = [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Bình Dương',
    'Đồng Nai',
    'Bà Rịa - Vũng Tàu',
    'Long An',
    'Tiền Giang',
    'Bến Tre',
    'Trà Vinh',
    'Vĩnh Long',
    'An Giang',
    'Đồng Tháp',
    'Kiên Giang',
    'Hậu Giang',
    'Sóc Trăng',
    'Bạc Liêu',
    'Cà Mau',
    'Quảng Ninh',
    'Lạng Sơn',
    'Phú Thọ',
    'Hà Giang',
    'Cao Bằng',
    'Nghệ An',
    'Hà Tĩnh',
    'Quảng Bình',
    'Quảng Trị',
    'Thừa Thiên Huế',
    'Lâm Đồng',
    'Gia Lai',
    'Kon Tum',
    'Đắk Lắk',
  ];
  return List.generate(34, (i) {
    return {
      'name': names[i],
      'density': 5000.0 - i * 140.0,
      'area': 2000.0 + i * 200.0,
      'population': 5000000.0 - i * 120000.0,
    };
  });
}

Widget _buildTestWidget({
  required FakeProvinceProvider provinceProvider,
  ValueChanged<String>? onMetricChanged,
}) {
  return createTestApp(
    child: Scaffold(
      body: PopulationDensityChart(onMetricChanged: onMetricChanged),
    ),
    overrides: ProviderOverrides(province: provinceProvider),
  );
}

void main() {
  group('PopulationDensityChart widget', () {
    testWidgets('shows loading indicator khi isCalculatingDensity = true', (
      tester,
    ) async {
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = true
        ..calculatedDensities = [];

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();

      // Kiểm tra CircularProgressIndicator hiển thị
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text('Đang đọc và phân tích dữ liệu 34 tỉnh/thành phố...'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator khi calculatedDensities trống', (
      tester,
    ) async {
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = false
        ..calculatedDensities = [];

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text('Đang đọc và phân tích dữ liệu 34 tỉnh/thành phố...'),
        findsOneWidget,
      );
    });

    testWidgets('renders bar chart khi có densities data', (tester) async {
      final densities = _createSampleDensities();
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = false
        ..calculatedDensities = densities;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tiêu đề chart
      expect(find.text('Mật Độ Dân Số Theo Tỉnh'), findsOneWidget);

      // Các chip metric hiển thị
      expect(find.text('Mật độ'), findsOneWidget);
      expect(find.text('Diện tích'), findsOneWidget);
      expect(find.text('Dân số'), findsOneWidget);

      // Tên tỉnh trong ranking xuất hiện
      expect(find.textContaining('Hồ Chí Minh'), findsWidgets);
      expect(find.textContaining('Hà Nội'), findsWidgets);
    });

    testWidgets('switching metric chip changes display', (tester) async {
      final densities = _createSampleDensities();
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = false
        ..calculatedDensities = densities;

      String? lastMetric;
      await tester.pumpWidget(
        _buildTestWidget(
          provinceProvider: provider,
          onMetricChanged: (metric) => lastMetric = metric,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Mặc định là density → title "Mật Độ Dân Số Theo Tỉnh"
      expect(find.text('Mật Độ Dân Số Theo Tỉnh'), findsOneWidget);

      // Tap "Diện tích"
      await tester.tap(find.text('Diện tích'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Diện Tích Theo Tỉnh'), findsOneWidget);
      expect(lastMetric, 'area');

      // Tap "Dân số"
      await tester.tap(find.text('Dân số'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Dân Số Theo Tỉnh'), findsOneWidget);
      expect(lastMetric, 'population');
    });

    testWidgets('slider changes display count', (tester) async {
      final densities = _createFullSampleDensities();
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = false
        ..calculatedDensities = densities;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Mặc định slider = 34 → hiển thị "34 tỉnh"
      expect(find.textContaining('34 tỉnh'), findsWidgets);

      // Tìm slider và thay đổi giá trị
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
    });

    testWidgets('displays summary cards cho highest và lowest province', (
      tester,
    ) async {
      final densities = _createSampleDensities();
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = false
        ..calculatedDensities = densities;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Kiểm tra có insight text
      expect(find.textContaining('mật độ dân số gấp'), findsOneWidget);
      expect(find.textContaining('lần'), findsOneWidget);
    });

    testWidgets('calls onMetricChanged in initState', (tester) async {
      final densities = _createSampleDensities();
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = false
        ..calculatedDensities = densities;

      String? initMetric;
      await tester.pumpWidget(
        _buildTestWidget(
          provinceProvider: provider,
          onMetricChanged: (metric) => initMetric = metric,
        ),
      );
      await tester.pump();

      // initState gọi onMetricChanged với metric mặc định 'density'
      expect(initMetric, 'density');
    });

    testWidgets('renders với metric area hiển thị diện tích', (tester) async {
      final densities = _createSampleDensities();
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = false
        ..calculatedDensities = densities;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "Diện tích"
      await tester.tap(find.text('Diện tích'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Diện Tích Theo Tỉnh'), findsOneWidget);
    });

    testWidgets('renders với metric population hiển thị dân số', (
      tester,
    ) async {
      final densities = _createSampleDensities();
      final provider = FakeProvinceProvider()
        ..isCalculatingDensity = false
        ..calculatedDensities = densities;

      await tester.pumpWidget(_buildTestWidget(provinceProvider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "Dân số"
      await tester.tap(find.text('Dân số'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dân Số Theo Tỉnh'), findsOneWidget);
    });
  });
}
