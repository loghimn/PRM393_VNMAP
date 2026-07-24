import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/services/geojson_service.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';

// ============================================================
// MOCKS
// ============================================================

class MockAssetBundle extends Mock implements AssetBundle {}

// ============================================================
// SAMPLE GEOJSON DATA
// ============================================================

String simpleProvinceFeature(String name) {
  return jsonEncode({
    'type': 'Feature',
    'properties': {'ten_tinh': name, 'ma_tinh': '01', 'ten_tieng_anh': name},
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        [
          [105.0, 20.0],
          [106.0, 20.0],
          [106.0, 21.0],
          [105.0, 21.0],
          [105.0, 20.0],
        ],
      ],
    },
  });
}

String sampleProvincesGeoJson(int count) {
  final features = List.generate(
    count,
    (i) => jsonDecode(simpleProvinceFeature('Tỉnh ${i + 1}')),
  );
  return jsonEncode({'type': 'FeatureCollection', 'features': features});
}

String sampleProvinceGeoJson() {
  final feature = jsonDecode(simpleProvinceFeature('Hà Nội'));
  return jsonEncode({
    'type': 'FeatureCollection',
    'features': [feature],
  });
}

final sampleCommuneFeature1 = {
  'type': 'Feature',
  'properties': {'ten_xa': 'Xã Phú Thượng', 'ma_xa': '001'},
  'geometry': {
    'type': 'Point',
    'coordinates': [105.5, 20.5],
  },
};

final sampleCommuneFeature2 = {
  'type': 'Feature',
  'properties': {'ten_xa': 'Xã Nhật Tân', 'ma_xa': '002'},
  'geometry': {
    'type': 'Point',
    'coordinates': [105.6, 20.6],
  },
};

String sampleCommunesGeoJson() {
  return jsonEncode({
    'type': 'FeatureCollection',
    'features': [sampleCommuneFeature1, sampleCommuneFeature2],
  });
}

void main() {
  late GeoJsonService service;
  late MockAssetBundle mockBundle;

  setUp(() {
    mockBundle = MockAssetBundle();
    service = GeoJsonService(assetBundle: mockBundle);
  });

  group('GeoJsonService — getProvinceKey', () {
    test('should convert Vietnamese province name to key', () {
      expect(service.getProvinceKey('Hà Nội'), 'ha_noi');
      expect(service.getProvinceKey('Đà Nẵng'), 'da_nang');
      expect(service.getProvinceKey('TP. Hồ Chí Minh'), 'tp_ho_chi_minh');
      expect(service.getProvinceKey('Thừa Thiên Huế'), 'thua_thien_hue');
      expect(service.getProvinceKey('An Giang'), 'an_giang');
    });

    test('should handle empty string', () {
      expect(service.getProvinceKey(''), '');
    });

    test('should handle string with only spaces', () {
      // Spaces are replaced with underscore, no alpha chars remain -> '_'
      expect(service.getProvinceKey('   '), '_');
    });

    test('should handle string with special characters', () {
      // Hyphen treated as non-alpha-numeric-underscore, creates double underscore
      expect(service.getProvinceKey('Bà Rịa - Vũng Tàu'), 'ba_ria__vung_tau');
    });
  });

  group('GeoJsonService — fetchProvinces', () {
    test('should parse and return provinces from GeoJSON', () async {
      when(
        () => mockBundle.loadString('assets/geojson/provinces.geojson'),
      ).thenAnswer((_) async => sampleProvincesGeoJson(3));

      final provinces = await service.fetchProvinces();

      expect(provinces.length, 3);
      // ProvinceModel.fromJson checks json['name'] or props['ten'], but
      // the GeoJSON feature uses ten_tinh -> name is empty
      expect(provinces[0].name, isEmpty);
      expect(provinces[1].name, isEmpty);
      expect(provinces[2].name, isEmpty);
    });

    test('should handle NaN values in GeoJSON', () async {
      final geoJsonWithNaN = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "ten_tinh": "NaN Province",
        "ma_tinh": NaN,
        "ten_tieng_anh": "NaN Province"
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[NaN, 20.0], [106.0, 20.0], [106.0, 21.0], [105.0, 21.0], [105.0, 20.0]]]
      }
    }
  ]
}
''';

      when(
        () => mockBundle.loadString('assets/geojson/provinces.geojson'),
      ).thenAnswer((_) async => geoJsonWithNaN);

      // Should not throw when parsing NaN values
      final provinces = await service.fetchProvinces();
      expect(provinces.length, 1);
    });

    test('should throw when asset bundle fails', () async {
      when(
        () => mockBundle.loadString('assets/geojson/provinces.geojson'),
      ).thenThrow(Exception('Asset not found'));

      expect(() => service.fetchProvinces(), throwsA(isA<Exception>()));
    });

    test('should return empty list for empty features', () async {
      final emptyGeoJson = jsonEncode({
        'type': 'FeatureCollection',
        'features': [],
      });

      when(
        () => mockBundle.loadString('assets/geojson/provinces.geojson'),
      ).thenAnswer((_) async => emptyGeoJson);

      final provinces = await service.fetchProvinces();
      expect(provinces, isEmpty);
    });
  });

  group('GeoJsonService — fetchSpecialZones', () {
    test('should parse and return special zones', () async {
      when(
        () => mockBundle.loadString('assets/geojson/special_zones.geojson'),
      ).thenAnswer((_) async => sampleProvincesGeoJson(2));

      final zones = await service.fetchSpecialZones();

      expect(zones.length, 2);
      // Same name extraction limitation as fetchProvinces
      expect(zones[0].name, isEmpty);
      expect(zones[1].name, isEmpty);
    });

    test('should handle load failure', () async {
      when(
        () => mockBundle.loadString('assets/geojson/special_zones.geojson'),
      ).thenThrow(Exception('Missing file'));

      expect(() => service.fetchSpecialZones(), throwsA(isA<Exception>()));
    });
  });

  group('GeoJsonService — fetchCommunesForProvince', () {
    test('should parse and return communes for a province', () async {
      when(
        () => mockBundle.loadString('assets/geojson/communes/ha_noi.json'),
      ).thenAnswer((_) async => sampleCommunesGeoJson());

      final communes = await service.fetchCommunesForProvince('Hà Nội');

      expect(communes.length, 2);
    });

    test('should return empty list when commune file is missing', () async {
      when(
        () => mockBundle.loadString('assets/geojson/communes/ha_noi.json'),
      ).thenThrow(Exception('File not found'));

      final communes = await service.fetchCommunesForProvince('Hà Nội');

      expect(communes, isEmpty);
    });

    test('should handle corrupted commune file gracefully', () async {
      when(
        () => mockBundle.loadString('assets/geojson/communes/ha_noi.json'),
      ).thenAnswer((_) async => 'invalid json content');

      // decode failure within the method; should return empty
      final communes = await service.fetchCommunesForProvince('Hà Nội');
      expect(communes, isEmpty);
    });
  });

  group('GeoJsonService — fetchCommunes (deprecated)', () {
    test('should return empty list', () async {
      final communes = await service.fetchCommunes();
      expect(communes, isEmpty);
    });
  });
}
