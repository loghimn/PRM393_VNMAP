import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/utils/province_special_handler.dart';

void main() {
  group('ProvinceSpecialHandler', () {
    group('shouldSkipCommuneRender', () {
      test('should return false for unknown province', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {'type': 'Polygon', 'coordinates': []},
          properties: {'type': 'province'},
        );
        expect(
          ProvinceSpecialHandler.shouldSkipCommuneRender(province),
          isFalse,
        );
      });
    });

    group('shouldUseAlternativeRender', () {
      test('should return false for unknown province', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {'type': 'Polygon', 'coordinates': []},
          properties: {'type': 'province'},
        );
        expect(
          ProvinceSpecialHandler.shouldUseAlternativeRender(province),
          isFalse,
        );
      });
    });

    group('isValidGeometry', () {
      test('should return true for valid Polygon geometry', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {
            'type': 'Polygon',
            'coordinates': [
              [
                [105.0, 21.0],
                [106.0, 21.0],
                [106.0, 22.0],
                [105.0, 21.0],
              ],
            ],
          },
          properties: {'type': 'province'},
        );
        expect(ProvinceSpecialHandler.isValidGeometry(province), isTrue);
      });

      test('should return true for valid MultiPolygon geometry with data', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {
            'type': 'MultiPolygon',
            'coordinates': [
              [
                [
                  [105.0, 21.0],
                  [106.0, 21.0],
                  [106.0, 22.0],
                  [105.0, 21.0],
                ],
              ],
            ],
          },
          properties: {'type': 'province'},
        );
        expect(ProvinceSpecialHandler.isValidGeometry(province), isTrue);
      });

      test('should return false for invalid geometry type', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {
            'type': 'Point',
            'coordinates': [105.0, 21.0],
          },
          properties: {'type': 'province'},
        );
        expect(ProvinceSpecialHandler.isValidGeometry(province), isFalse);
      });

      test('should return false for null coordinates', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {'type': 'Polygon', 'coordinates': null},
          properties: {'type': 'province'},
        );
        expect(ProvinceSpecialHandler.isValidGeometry(province), isFalse);
      });

      test('should return false for empty coordinates', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {'type': 'Polygon', 'coordinates': []},
          properties: {'type': 'province'},
        );
        expect(ProvinceSpecialHandler.isValidGeometry(province), isFalse);
      });
    });

    group('getSafeCoordinates', () {
      test('should return coordinates from geometry', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {
            'type': 'Polygon',
            'coordinates': [
              [
                [105.0, 21.0],
              ],
            ],
          },
          properties: {'type': 'province'},
        );
        final coords = ProvinceSpecialHandler.getSafeCoordinates(province);
        expect(coords, isA<List>());
        expect(coords.length, 1);
      });

      test('should return empty list for non-list coordinates', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {'type': 'Polygon', 'coordinates': 'invalid'},
          properties: {'type': 'province'},
        );
        final coords = ProvinceSpecialHandler.getSafeCoordinates(province);
        expect(coords, []);
      });

      test('should return empty list on empty geometry', () {
        final province = ProvinceModel(
          name: 'Hà Nội',
          geometry: {},
          properties: {'type': 'province'},
        );
        final coords = ProvinceSpecialHandler.getSafeCoordinates(province);
        expect(coords, []);
      });
    });
  });
}
