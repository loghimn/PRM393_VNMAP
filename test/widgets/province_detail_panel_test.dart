import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import 'package:vietnam_geo_dashboard/widgets/analytics/province_detail_panel.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/models/high_school_model.dart';
import '../screens/test_helpers/mock_providers.dart';
import '../screens/test_helpers/widget_test_utils.dart';

/// FakeWeatherProvider có hỗ trợ cache cho gọi getCachedWeatherForProvince
class _FakeWeatherWithCache extends FakeWeatherProvider {
  final Map<String, WeatherModel> cachedWeather = {};

  @override
  WeatherModel? getCachedWeatherForProvince(ProvinceModel province) {
    return cachedWeather[province.ma ?? ''];
  }

  @override
  Future<WeatherModel?> fetchWeatherForProvince(ProvinceModel province) async {
    return cachedWeather[province.ma ?? ''];
  }
}

/// Tạo province mẫu cho test
ProvinceModel _createProvince({
  String name = 'Hà Nội',
  String? type,
  String? parentTen,
  String? parentMa,
  String? predecessors,
  String? decree,
}) {
  return ProvinceModel(
    name: name,
    ma: '01',
    areaKm2: 3359.8,
    population: 8400000,
    density: 2500.0,
    capital: 'Hoàn Kiếm',
    macroRegion: 'red_river_delta',
    type: type,
    predecessors: predecessors,
    parentTen: parentTen,
    parentMa: parentMa,
    decree: decree,
    geometry: {'type': 'Polygon', 'coordinates': []},
    properties: {},
  );
}

void main() {
  group('ProvinceDetailPanel — province == null (national overview)', () {
    testWidgets('shows loading text when no weather data', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(body: ProvinceDetailPanel(province: null)),
        ),
      );
      await tester.pump();

      expect(
        find.text('Đang tải tổng quan thời tiết quốc gia...'),
        findsOneWidget,
      );
    });

    testWidgets('shows national overview with weather data', (tester) async {
      final weatherProv = FakeWeatherProvider()
        ..nationalWeatherSummary = WeatherModel(
          temperature: 30.5,
          windspeed: 12.0,
          weathercode: 0,
          time: '2026-07-24T12:00',
          humidity: 65,
          pressure: 1013,
          precipitation: 0.0,
        );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(body: ProvinceDetailPanel(province: null)),
          overrides: ProviderOverrides(weather: weatherProv),
        ),
      );
      await tester.pump();

      // National overview title
      expect(find.text('Tổng quan thời tiết Việt Nam'), findsOneWidget);
    });

    testWidgets('shows regional weather summaries', (tester) async {
      final weatherProv = FakeWeatherProvider()
        ..nationalWeatherSummary = WeatherModel(
          temperature: 28.0,
          windspeed: 10.0,
          weathercode: 1,
          time: '2026-07-24T12:00',
          humidity: 70,
        )
        ..regionalSummaries['north'] = RegionWeatherSummary(
          key: 'north',
          label: 'Miền Bắc',
          weather: WeatherModel(
            temperature: 26.0,
            windspeed: 8.0,
            weathercode: 0,
            time: '2026-07-24T12:00',
            humidity: 75,
          ),
        )
        ..regionalSummaries['south'] = RegionWeatherSummary(
          key: 'south',
          label: 'Miền Nam',
          weather: WeatherModel(
            temperature: 32.0,
            windspeed: 15.0,
            weathercode: 0,
            time: '2026-07-24T12:00',
            humidity: 60,
          ),
        );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(body: ProvinceDetailPanel(province: null)),
          overrides: ProviderOverrides(weather: weatherProv),
        ),
      );
      await tester.pump();

      // Regional section title
      expect(find.text('Tổng quan thời tiết vùng'), findsOneWidget);
      // Regional labels
      expect(find.text('Miền Bắc'), findsOneWidget);
      expect(find.text('Miền Nam'), findsOneWidget);
    });

    testWidgets('shows empty regional message when no regions', (tester) async {
      final weatherProv = FakeWeatherProvider()
        ..nationalWeatherSummary = WeatherModel(
          temperature: 28.0,
          windspeed: 10.0,
          weathercode: 1,
          time: '2026-07-24T12:00',
        );

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(body: ProvinceDetailPanel(province: null)),
          overrides: ProviderOverrides(weather: weatherProv),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'Không tìm thấy dữ liệu thời tiết vùng. Vui lòng thử lại sau.',
        ),
        findsOneWidget,
      );
    });
  });

  group('ProvinceDetailPanel — province detail', () {
    testWidgets('shows province name and basic info', (tester) async {
      final province = _createProvince(decree: 'Nghị định 01/2026');

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: province)),
        ),
      );
      await tester.pump();

      // Province name header
      expect(find.text('Hà Nội'), findsOneWidget);
      // Basic info fields
      expect(find.textContaining('Mã hành chính'), findsOneWidget);
      expect(find.textContaining('Diện tích'), findsWidgets);
      expect(find.textContaining('Dân số'), findsWidgets);
      expect(find.textContaining('Mật độ dân số'), findsWidgets);
      expect(find.textContaining('Tỉnh lỵ'), findsOneWidget);
      expect(find.textContaining('Vùng địa lý'), findsOneWidget);
      // Decree section
      expect(find.text('Nghị định / Quyết định'), findsOneWidget);
      expect(find.text('Nghị định 01/2026'), findsOneWidget);
    });

    testWidgets('shows macro region in Vietnamese', (tester) async {
      final province = _createProvince();

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: province)),
        ),
      );
      await tester.pump();

      // Hà Nội thuộc red_river_delta -> Đồng bằng sông Hồng
      expect(find.textContaining('Đồng bằng sông Hồng'), findsWidgets);
    });

    testWidgets('shows weather panel for province', (tester) async {
      final province = _createProvince();
      final weatherProv = _FakeWeatherWithCache()
        ..cachedWeather[province.ma ?? ''] = WeatherModel(
          temperature: 25.0,
          windspeed: 5.0,
          weathercode: 0,
          time: '2026-07-24T12:00',
          humidity: 70,
          pressure: 1013,
        );

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: province)),
          overrides: ProviderOverrides(weather: weatherProv),
        ),
      );
      await tester.pump();

      // Weather widget renders with "Thời tiết" title
      expect(find.text('Thời tiết'), findsOneWidget);
    });

    testWidgets('shows hyphen for missing decree', (tester) async {
      final province = _createProvince(decree: null);

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: province)),
        ),
      );
      await tester.pump();

      expect(find.text('Nghị định / Quyết định'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });
  });

  group('ProvinceDetailPanel — special zone', () {
    testWidgets('shows special zone details', (tester) async {
      final province = _createProvince(
        name: 'Vũng Tàu - Côn Đảo',
        type: 'Đặc khu',
        parentMa: '77',
        parentTen: 'Bà Rịa - Vũng Tàu',
        predecessors: 'Huyện Côn Đảo',
        decree: 'Nghị định 123',
      );

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: province)),
        ),
      );
      await tester.pump();

      // Special zone has different color accent -> name displayed
      expect(find.text('Vũng Tàu - Côn Đảo'), findsOneWidget);
      // Type field
      expect(find.textContaining('Phân loại'), findsOneWidget);
      expect(find.text('Đặc khu'), findsOneWidget);
      // Parent info
      expect(find.textContaining('Mã cấp trên'), findsOneWidget);
      expect(find.textContaining('Đơn vị cấp trên'), findsOneWidget);
      expect(find.textContaining('Bà Rịa - Vũng Tàu'), findsWidgets);
      // Predecessors
      expect(find.text('Đơn vị tiền thân'), findsOneWidget);
      expect(find.text('Huyện Côn Đảo'), findsOneWidget);
      // Decree
      expect(find.text('Nghị định / Quyết định'), findsOneWidget);
      expect(find.text('Nghị định 123'), findsOneWidget);
    });
  });

  group('ProvinceDetailPanel — commune', () {
    testWidgets('shows commune details and parent province', (tester) async {
      final commune = _createProvince(
        name: 'Phường Bến Nghé',
        type: 'Phường',
        parentTen: 'Quận 1',
      );

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: commune)),
        ),
      );
      await tester.pump();

      // Commune name
      expect(find.text('Phường Bến Nghé'), findsOneWidget);
      // Commune info includes parent province
      expect(find.textContaining('Thuộc tỉnh'), findsOneWidget);
      expect(find.textContaining('Quận 1'), findsWidgets);
      // Type
      expect(find.text('Phường'), findsOneWidget);
    });

    testWidgets('shows high schools section for commune', (tester) async {
      final commune = _createProvince(
        name: 'Xã Tân Phong',
        type: 'Xã',
        parentTen: 'Quận 7',
      );

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: commune)),
        ),
      );
      await tester.pump();

      // High schools section title
      expect(find.text('Trường THPT trên địa bàn'), findsOneWidget);
      // No schools loaded -> shows empty message
      expect(
        find.text('Không có dữ liệu trường THPT cho xã/phường này.'),
        findsOneWidget,
      );
    });

    testWidgets('shows high school cards when schools exist', (tester) async {
      final commune = _createProvince(
        name: 'Xã Tân Phong',
        type: 'Xã',
        parentTen: 'Quận 7',
      );
      final provinceProv = FakeProvinceProvider()
        ..selectedCommuneHighSchools = [
          _createHighSchool(
            tenTruong: 'THPT Tân Phong',
            address: '123 đường số 1',
            khuVuc: 'Khu vực 2',
            maTruong: 'TP01',
          ),
          _createHighSchool(
            tenTruong: 'THPT Nguyễn Huệ',
            address: '456 đường số 2',
            khuVuc: 'Khu vực 1',
            maTruong: 'TP02',
          ),
        ];

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: commune)),
          overrides: ProviderOverrides(province: provinceProv),
        ),
      );
      await tester.pump();

      // School names displayed
      expect(find.text('THPT Tân Phong'), findsOneWidget);
      expect(find.text('THPT Nguyễn Huệ'), findsOneWidget);
      // Addresses displayed
      expect(find.text('123 đường số 1'), findsOneWidget);
      expect(find.text('456 đường số 2'), findsOneWidget);
      // Khu vực displayed
      expect(find.textContaining('Khu vực 2'), findsWidgets);
      // Mã trường displayed
      expect(find.textContaining('TP01'), findsWidgets);
      expect(find.textContaining('TP02'), findsWidgets);
    });

    testWidgets('shows loading indicator for high schools', (tester) async {
      final commune = _createProvince(
        name: 'Xã Tân Phong',
        type: 'Xã',
        parentTen: 'Quận 7',
      );
      final provinceProv = FakeProvinceProvider()..isLoadingHighSchools = true;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(body: ProvinceDetailPanel(province: commune)),
          overrides: ProviderOverrides(province: provinceProv),
        ),
      );
      await tester.pump();

      // Loading indicator visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

HighSchool _createHighSchool({
  required String tenTruong,
  String? address,
  String? khuVuc,
  String? maTruong,
}) {
  return HighSchool(
    tenTruong: tenTruong,
    address: address,
    khuVuc: khuVuc,
    maTruong: maTruong,
    maXaPhuong: '001',
    tenXaPhuong: 'Xã Tân Phong',
    maTinhTp: '79',
    tenTinhTp: 'TP. Hồ Chí Minh',
  );
}
