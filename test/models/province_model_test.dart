import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';

void main() {
  group('ProvinceModel.fromJson', () {
    test('should parse province with full JSON data', () {
      final json = {
        'name': 'Hà Nội',
        'code': '01',
        'area_km2': 3358.9,
        'population': 8053663,
        'density': 2399.0,
        'capital': 'Hoàn Kiếm',
        'decree': 'Nghị định...',
        'macro_region': 'red_river_delta',
        'type': 'Thanh pho',
        'predecessors': 'Hà Tây',
        'parent_ma': '00',
        'parent_ten': 'Việt Nam',
        'geometry': {'type': 'Polygon', 'coordinates': []},
        'properties': {'ten': 'Hà Nội', 'ma': '01'},
      };

      final province = ProvinceModel.fromJson(json);

      expect(province.name, 'Hà Nội');
      expect(province.ma, '01');
      expect(province.areaKm2, 3358.9);
      expect(province.population, 8053663);
      expect(province.density, 2399.0);
      expect(province.capital, 'Hoàn Kiếm');
      expect(province.decree, 'Nghị định...');
      expect(province.macroRegion, 'red_river_delta');
      expect(province.type, 'Thanh pho');
      expect(province.predecessors, 'Hà Tây');
      expect(province.parentMa, '00');
      expect(province.parentTen, 'Việt Nam');
      expect(province.geometry['type'], 'Polygon');
      expect(province.properties['ten'], 'Hà Nội');
    });

    test('should handle geometry as JSON string', () {
      final json = {
        'name': 'Hà Nội',
        'geometry_json': '{"type":"Point","coordinates":[105,21]}',
        'properties': {},
      };

      final province = ProvinceModel.fromJson(json);

      expect(province.geometry['type'], 'Point');
      expect(province.geometry['coordinates'], [105, 21]);
    });

    test('should handle missing geometry gracefully', () {
      final json = {'name': 'Hà Nội', 'properties': {}};

      final province = ProvinceModel.fromJson(json);

      expect(province.geometry, isEmpty);
    });

    test('should fallback to properties for missing fields', () {
      final json = {
        'properties': {
          'ten': 'Hồ Chí Minh',
          'ma': '79',
          'capital': 'Quận 1',
          'decree': 'Nghị định 1',
          'macro_region': 'south_east',
          'type': 'Thanh pho',
          'predecessors': '',
          'parent_ma': '00',
          'parent_ten': 'Việt Nam',
        },
        'geometry': {},
      };

      final province = ProvinceModel.fromJson(json);

      expect(province.name, 'Hồ Chí Minh');
      expect(province.ma, '79');
      expect(province.capital, 'Quận 1');
      expect(province.macroRegion, 'south_east');
    });

    test('should use empty string for missing name', () {
      final json = {'properties': {}, 'geometry': {}};

      final province = ProvinceModel.fromJson(json);

      expect(province.name, '');
    });

    test('should use toString for code when it is not a String', () {
      final json = {
        'code': 1,
        'name': 'Test',
        'properties': {},
        'geometry': {},
      };

      final province = ProvinceModel.fromJson(json);

      expect(province.ma, '1');
    });
  });

  group('ProvinceModel.macroRegionVietnamese', () {
    test('should return Vietnamese for Red River Delta', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'red_river_delta',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Đồng bằng sông Hồng');
    });

    test('should return Vietnamese for Northern Midlands', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'northern_midlands',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Trung du và miền núi phía Bắc');
    });

    test('should return Vietnamese for North Central Coast', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'north_central_coast',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Bắc Trung Bộ');
    });

    test('should return Vietnamese for Central Coast', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'central_coast',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Trung Bộ');
    });

    test('should return Vietnamese for South Central Coast', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'south_central_coast',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Nam Trung Bộ');
    });

    test('should return Vietnamese for Central Highlands', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'central_highlands',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Tây Nguyên');
    });

    test('should return Vietnamese for South East (south_east)', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'south_east',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Đông Nam Bộ');
    });

    test('should return Vietnamese for South East (southeast)', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'southeast',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Đông Nam Bộ');
    });

    test('should return Vietnamese for Mekong Delta', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'mekong_delta',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Đồng bằng sông Cửu Long');
    });

    test('should handle unknown region with title case', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: 'unknown_region_test',
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, 'Unknown Region Test');
    });

    test('should return dash for null macroRegion', () {
      final province = ProvinceModel(
        name: 'Test',
        macroRegion: null,
        geometry: {},
        properties: {},
      );

      expect(province.macroRegionVietnamese, '-');
    });
  });

  group('ProvinceModel equality', () {
    test('should be equal when name and ma are the same', () {
      final province1 = ProvinceModel(
        name: 'Hà Nội',
        ma: '01',
        geometry: {},
        properties: {},
      );
      final province2 = ProvinceModel(
        name: 'Hà Nội',
        ma: '01',
        geometry: {},
        properties: {},
      );

      expect(province1 == province2, isTrue);
      expect(province1.hashCode == province2.hashCode, isTrue);
    });

    test('should not be equal when names differ', () {
      final province1 = ProvinceModel(
        name: 'Hà Nội',
        ma: '01',
        geometry: {},
        properties: {},
      );
      final province2 = ProvinceModel(
        name: 'Hồ Chí Minh',
        ma: '01',
        geometry: {},
        properties: {},
      );

      expect(province1 == province2, isFalse);
    });

    test('should not be equal when ma differs', () {
      final province1 = ProvinceModel(
        name: 'Hà Nội',
        ma: '01',
        geometry: {},
        properties: {},
      );
      final province2 = ProvinceModel(
        name: 'Hà Nội',
        ma: '02',
        geometry: {},
        properties: {},
      );

      expect(province1 == province2, isFalse);
    });
  });
}
