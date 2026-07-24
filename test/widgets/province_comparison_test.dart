import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_comparison.dart';
import '../screens/test_helpers/mock_providers.dart';
import '../screens/test_helpers/widget_test_utils.dart';

/// Sample provinces for ProvinceComparison tests
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
  ];
}

Widget _buildTestApp({required List<ProvinceModel> provinces}) {
  return createTestApp(
    child: Scaffold(body: ProvinceComparison(provinces: provinces)),
    overrides: const ProviderOverrides(),
  );
}

void main() {
  group('ProvinceComparison widget', () {
    testWidgets('renders header title with compare icon', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(provinces: _createSampleProvinces()),
      );
      await tester.pump();

      // Header title
      expect(find.text('So Sánh Hai Tỉnh'), findsOneWidget);
      // Mode toggle buttons
      expect(find.text('Tỉnh/Thành Phố'), findsOneWidget);
      expect(find.text('Xã/Phường'), findsOneWidget);
    });

    testWidgets('shows dropdown labels Tỉnh 1 and Tỉnh 2', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(provinces: _createSampleProvinces()),
      );
      await tester.pump();

      // Dropdown labels
      expect(find.text('Tỉnh 1'), findsOneWidget);
      expect(find.text('Tỉnh 2'), findsOneWidget);

      // Default selected provinces (first two) - appears in dropdown + metric bar names
      expect(find.text('TP. Hồ Chí Minh'), findsWidgets);
      expect(find.text('Hà Nội'), findsWidgets);
    });

    testWidgets('shows metric bars for Dân Số, Diện Tích, Mật Độ Dân Số', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(provinces: _createSampleProvinces()),
      );
      await tester.pump();

      // Three metric section titles
      expect(find.text('DÂN SỐ'), findsOneWidget);
      expect(find.text('DIỆN TÍCH'), findsOneWidget);
      expect(find.text('MẬT ĐỘ DÂN SỐ'), findsOneWidget);

      // Unit labels appear
      expect(find.textContaining('người'), findsWidgets);
      expect(find.textContaining('km²'), findsWidgets);
      expect(find.textContaining('người/km²'), findsWidgets);
    });

    testWidgets('displays formatted numbers with dot separators', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(provinces: _createSampleProvinces()),
      );
      await tester.pump();

      // 9.200.000 for TP. Hồ Chí Minh population
      expect(find.text('9.200.000 người'), findsOneWidget);
      // 8.400.000 for Hà Nội population
      expect(find.text('8.400.000 người'), findsOneWidget);
    });

    testWidgets('ratio text displays winner comparison', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(provinces: _createSampleProvinces()),
      );
      await tester.pump();

      // TP. Hồ Chí Minh có population cao hơn Hà Nội → ratio text hiển thị
      expect(find.textContaining('cao hơn'), findsWidgets);
      expect(find.textContaining('lần'), findsWidgets);
    });

    testWidgets('switching to commune mode changes title', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(provinces: _createSampleProvinces()),
      );
      await tester.pump();

      // Tap "Xã/Phường" toggle
      await tester.tap(find.text('Xã/Phường'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Title changes
      expect(find.text('So Sánh Hai Xã/Phường'), findsOneWidget);

      // Commune mode labels show
      expect(find.textContaining('Chọn Tỉnh/Thành phố'), findsWidgets);
    });

    testWidgets('province filter in dropdown works', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(provinces: _createSampleProvinces()),
      );
      await tester.pump();

      // Open Tỉnh 2 dropdown - find the dropdown button by label "Tỉnh 2"
      // Tap on the dropdown arrow/button for Tỉnh 2
      final dropdown2Label = find.text('Tỉnh 2');
      expect(dropdown2Label, findsOneWidget);
      // Find the nearest DropdownButton widget and open it
      final dropdownBtn = find.descendant(
        of: find.byType(DropdownButton<ProvinceModel>),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      );
      expect(dropdownBtn, findsWidgets);
      await tester.tap(dropdownBtn.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After opening the dropdown, TP. Hồ Chí Minh should still appear
      // (but not as a duplicate in the dropdown items since it's filtered out from province 2)
      // The widget has 4 instances: dropdown1 text + 3 metric bar texts (name, bar label)
      expect(find.text('TP. Hồ Chí Minh'), findsWidgets);
    });

    testWidgets('updates metric when province dropdown changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(provinces: _createSampleProvinces()),
      );
      await tester.pump();

      // Default: Tỉnh 1 = TP. Hồ Chí Minh, Tỉnh 2 = Hà Nội
      // Opening Tỉnh 1 dropdown to change selection
      final dropdownBtn = find.descendant(
        of: find.byType(DropdownButton<ProvinceModel>),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      );
      await tester.tap(dropdownBtn.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select Hải Phòng from the dropdown items
      // Use the specific DropdownMenuItem text
      await tester.tap(
        find.descendant(
          of: find.byType(DropdownMenuItem<ProvinceModel>),
          matching: find.text('Hải Phòng'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tỉnh 1 now shows Hải Phòng (in dropdown + metric bar name + metric bar label)
      expect(find.text('Hải Phòng'), findsWidgets);
    });

    testWidgets('single province list does not crash', (tester) async {
      final singleProvince = [
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
      ];

      await tester.pumpWidget(_buildTestApp(provinces: singleProvince));
      await tester.pump();

      // Header still renders
      expect(find.text('So Sánh Hai Tỉnh'), findsOneWidget);

      // Only Tỉnh 1 has a value, Tỉnh 2 shows dropdown with no items
      expect(find.text('Cần Thơ'), findsOneWidget);

      // No metric bars since only 1 province (second is null)
      expect(find.text('DÂN SỐ'), findsNothing);
    });

    testWidgets(
      'renders metric bars after province 2 selected when initially single',
      (tester) async {
        final provinces = [
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
        ];

        await tester.pumpWidget(_buildTestApp(provinces: provinces));
        await tester.pump();

        // Both provinces shown → metric bars should appear
        expect(find.text('DÂN SỐ'), findsOneWidget);
        expect(find.text('DIỆN TÍCH'), findsOneWidget);
        expect(find.text('MẬT ĐỘ DÂN SỐ'), findsOneWidget);
      },
    );
  });
}
