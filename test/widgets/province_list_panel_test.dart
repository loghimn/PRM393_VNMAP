import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_list_panel.dart';
import '../screens/test_helpers/mock_providers.dart';
import '../screens/test_helpers/widget_test_utils.dart';

/// Tạo provider với [provinces] được set sẵn.
FakeProvinceProvider createProvider(List<ProvinceModel> provinces) {
  final provider = FakeProvinceProvider();
  provider.provinces = provinces;
  return provider;
}

/// Tạo sample test data
final List<ProvinceModel> sampleProvinces = [
  ProvinceModel(
    name: 'TP. Hồ Chí Minh',
    density: 4500.0,
    population: 9000000,
    areaKm2: 2061.0,
    geometry: {'type': 'Polygon', 'coordinates': []},
    properties: {},
  ),
  ProvinceModel(
    name: 'Hà Nội',
    density: 2500.0,
    population: 8000000,
    areaKm2: 3359.0,
    geometry: {'type': 'Polygon', 'coordinates': []},
    properties: {},
  ),
  ProvinceModel(
    name: 'Đà Nẵng',
    density: 1200.0,
    population: 1200000,
    areaKm2: 1285.0,
    geometry: {'type': 'Polygon', 'coordinates': []},
    properties: {},
  ),
  ProvinceModel(
    name: 'Hải Phòng',
    density: 800.0,
    population: 2000000,
    areaKm2: 1523.0,
    geometry: {'type': 'Polygon', 'coordinates': []},
    properties: {},
  ),
];

void main() {
  group('ProvinceListPanel', () {
    testWidgets('hiển thị CircularProgressIndicator khi provinces trống', (
      tester,
    ) async {
      final provider = createProvider([]);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      // Vì không có provinces, widget hiển thị CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hiển thị tiêu đề và số lượng tỉnh khi có dữ liệu', (
      tester,
    ) async {
      final provider = createProvider(sampleProvinces);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      // Tiêu đề
      expect(find.text('Xếp Hạng Mật Độ Dân Số'), findsOneWidget);

      // Số lượng tỉnh: "4 tỉnh"
      expect(find.text('4 tỉnh'), findsOneWidget);
    });

    testWidgets('hiển thị đúng tên tất cả tỉnh', (tester) async {
      final provider = createProvider(sampleProvinces);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      for (final p in sampleProvinces) {
        expect(find.text(p.name), findsOneWidget);
      }
    });

    testWidgets('sắp xếp tỉnh theo density descending', (tester) async {
      final provider = createProvider(sampleProvinces);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      // Scroll xuống cuối để render tất cả items
      await tester.scrollUntilVisible(
        find.text('Hải Phòng'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );

      // Lấy các Text widget chứa density value (số >= 3 chữ số)
      // Filter: text nằm trong container có decoration (density badge)
      // Cách chính xác: tìm Text có font size 12 và fontWeight w700 (density value style)
      final densityTexts = tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  w.data != null &&
                  w.data!.isNotEmpty &&
                  w.style?.fontSize == 12 &&
                  w.style?.fontWeight == FontWeight.w700,
            ),
          )
          .toList();

      // Phải có đúng 4 density values
      expect(densityTexts.length, 4);

      // Thứ tự phải là 4500 > 2500 > 1200 > 800
      expect(densityTexts[0].data, '4500');
      expect(densityTexts[1].data, '2500');
      expect(densityTexts[2].data, '1200');
      expect(densityTexts[3].data, '800');
    });

    testWidgets('top 1 có medal icon màu vàng (Icons.emoji_events)', (
      tester,
    ) async {
      final provider = createProvider(sampleProvinces);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      // Kiểm tra có icon emoji_events (trophy) xuất hiện
      expect(find.byIcon(Icons.emoji_events), findsAtLeastNWidgets(1));
    });

    testWidgets('hiển thị density value cho mỗi tỉnh', (tester) async {
      final provider = createProvider(sampleProvinces);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      // Kiểm tra density value xuất hiện
      // TP.HCM: 4500, Hà Nội: 2500, Đà Nẵng: 1200, Hải Phòng: 800
      expect(find.text('4500'), findsOneWidget);
      expect(find.text('2500'), findsOneWidget);
      expect(find.text('1200'), findsOneWidget);
      expect(find.text('800'), findsOneWidget);
    });

    testWidgets('tap vào một tỉnh gọi selectProvince', (tester) async {
      final provider = createProvider(sampleProvinces);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      // Tap vào tỉnh đầu tiên (TP. Hồ Chí Minh)
      await tester.tap(find.text('TP. Hồ Chí Minh'));
      await tester.pumpAndSettle();

      // Kiểm tra provider đã select đúng tỉnh
      expect(provider.selectedProvince?.name, 'TP. Hồ Chí Minh');
      expect(provider.selectedProvince?.density, 4500.0);
    });

    testWidgets('số 4 (không top 3) không có rankIcon', (tester) async {
      final threeProvinces = sampleProvinces.take(3).toList();
      final provider = createProvider(threeProvinces);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      // Cả 3 đều có medal → 3 icons
      expect(find.byIcon(Icons.emoji_events), findsNWidgets(3));

      // Thêm tỉnh thứ 4
      provider.provinces = sampleProvinces;
      provider.notifyListeners();
      await tester.pumpAndSettle();

      // Tỉnh thứ 4 (rank 4) không có medal → vẫn còn 3 icons (top 3)
      // Nhưng tổng số tỉnh = 4
      expect(find.byIcon(Icons.emoji_events), findsNWidgets(3));
    });

    testWidgets('các medal top 1-3 có màu riêng', (tester) async {
      final threeProvinces = sampleProvinces.take(3).toList();
      final provider = createProvider(threeProvinces);

      await tester.pumpScreen(
        const ProvinceListPanel(),
        overrides: ProviderOverrides(province: provider),
      );

      // Lấy tất cả Icon widgets cho emoji_events
      final iconWidgets = tester.widgetList<Icon>(
        find.byIcon(Icons.emoji_events),
      );

      // Màu: vàng → bạc → đồng
      expect(iconWidgets.length, 3);
      expect(iconWidgets.elementAt(0).color, const Color(0xFFF59E0B)); // Vàng
      expect(iconWidgets.elementAt(1).color, const Color(0xFF94A3B8)); // Bạc
      expect(iconWidgets.elementAt(2).color, const Color(0xFFCD7F32)); // Đồng
    });
  });
}
