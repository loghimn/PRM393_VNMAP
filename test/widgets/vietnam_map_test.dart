import 'dart:ui' show Size;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';

import '../screens/test_helpers/mock_providers.dart';
import '../screens/test_helpers/widget_test_utils.dart';

/// Tạo ProvinceModel với 1 polygon ring
ProvinceModel createPolygonProvince({
  required String name,
  required String type,
  List<List<double>>? ring,
}) {
  final r =
      ring ??
      [
        [105.0, 21.0],
        [106.0, 21.0],
        [106.0, 22.0],
        [105.0, 22.0],
        [105.0, 21.0],
      ];
  return ProvinceModel(
    name: name,
    geometry: {
      'type': 'Polygon',
      'coordinates': [r],
    },
    properties: {'type': type},
  );
}

/// Fake ProvinceProvider có thể inject provinces
class TestProvinceProvider extends FakeProvinceProvider {
  @override
  List<ProvinceModel> provinces;

  @override
  List<ProvinceModel> specialZones;

  @override
  ProvinceModel? focusedProvince;

  @override
  ProvinceModel? selectedProvince;

  @override
  ProvinceModel? selectedCommune;

  @override
  List<ProvinceModel> focusedCommunes;

  @override
  ProvinceModel? hoveredProvince;

  TestProvinceProvider({
    List<ProvinceModel>? provinces,
    List<ProvinceModel>? specialZones,
    this.focusedProvince,
    this.selectedProvince,
    this.selectedCommune,
    this.hoveredProvince,
  }) : provinces = provinces ?? [],
       specialZones = specialZones ?? [],
       focusedCommunes = [];

  @override
  void setHoveredProvince(ProvinceModel? province) {
    hoveredProvince = province;
    notifyListeners();
  }

  @override
  void selectProvince(ProvinceModel province) {
    selectedProvince = province;
    notifyListeners();
  }

  @override
  void selectCommune(ProvinceModel commune) {
    selectedCommune = commune;
    notifyListeners();
  }

  @override
  Future<void> focusProvince(ProvinceModel province) async {
    focusedProvince = province;
    notifyListeners();
  }
}

/// Fake WeatherProvider không gọi API thật
class TestWeatherProvider extends FakeWeatherProvider {
  @override
  Future<WeatherModel?> fetchWeatherForProvince(ProvinceModel province) async {
    return null; // Không gọi API
  }
}

void main() {
  final sampleProvince = createPolygonProvince(
    name: 'Hà Nội',
    type: 'Thành phố',
  );

  group('VietnamMap widget - rendering', () {
    testWidgets('shows CircularProgressIndicator khi provinces trống', (
      tester,
    ) async {
      final provinceProv = TestProvinceProvider(provinces: []);

      await tester.pumpScreen(
        const Material(child: VietnamMap()),
        overrides: ProviderOverrides(
          province: provinceProv,
          weather: TestWeatherProvider(),
        ),
      );

      // Mặc định provinces.isEmpty => CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders CustomPaint khi có provinces', (tester) async {
      final provinceProv = TestProvinceProvider(provinces: [sampleProvince]);

      await tester.pumpScreen(
        const Material(child: VietnamMap()),
        overrides: ProviderOverrides(
          province: provinceProv,
          weather: TestWeatherProvider(),
        ),
      );

      // Khi có data => CustomPaint xuất hiện (có thể có nhiều hơn 1 do overlay)
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

      // Stack (chứa autocomplete + painter + overlay)
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('renders Autocomplete cho search', (tester) async {
      final provinceProv = TestProvinceProvider(provinces: [sampleProvince]);

      await tester.pumpScreen(
        const Material(child: VietnamMap()),
        overrides: ProviderOverrides(
          province: provinceProv,
          weather: TestWeatherProvider(),
        ),
      );

      // Autocomplete với hint 'Tìm kiếm tỉnh thành, xã phường...'
      expect(find.byType(Autocomplete<SearchResult>), findsOneWidget);
    });
  });

  group('VietnamMap widget - interactions', () {
    testWidgets('tapping does not throw', (tester) async {
      final provinceProv = TestProvinceProvider(provinces: [sampleProvince]);

      // Chưa có selectedProvince
      expect(provinceProv.selectedProvince, isNull);

      await tester.pumpScreen(
        const Material(child: VietnamMap()),
        overrides: ProviderOverrides(
          province: provinceProv,
          weather: TestWeatherProvider(),
        ),
      );

      // Tap tại vị trí trung tâm màn hình — không throw
      await tester.tapAt(const Offset(400, 300));
      await tester.pumpAndSettle();
    });

    testWidgets('double tap does not throw', (tester) async {
      final provinceProv = TestProvinceProvider(provinces: [sampleProvince]);

      expect(provinceProv.focusedProvince, isNull);

      await tester.pumpScreen(
        const Material(child: VietnamMap()),
        overrides: ProviderOverrides(
          province: provinceProv,
          weather: TestWeatherProvider(),
        ),
      );

      // Double tap không chính xác gọi focusProvince nhưng không throw
      await tester.tapAt(const Offset(400, 300));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(400, 300));
      await tester.pumpAndSettle();
    });
  });
}
