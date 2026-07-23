import 'dart:ui' show Offset, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/utils/map_hit_test.dart';

void main() {
  final sampleProvinces = [
    ProvinceModel(
      name: 'Tỉnh Hà Nội',
      geometry: {
        'type': 'Polygon',
        'coordinates': [
          [
            [105.0, 21.0],
            [106.0, 21.0],
            [106.0, 22.0],
            [105.0, 22.0],
            [105.0, 21.0],
          ],
        ],
      },
      properties: {'type': 'province'},
    ),
  ];

  final multiPolygonProvinces = [
    ProvinceModel(
      name: 'Tỉnh Đồng Nai',
      geometry: {
        'type': 'MultiPolygon',
        'coordinates': [
          [
            [
              [107.0, 10.5],
              [107.5, 10.5],
              [107.5, 11.0],
              [107.0, 11.0],
              [107.0, 10.5],
            ],
          ],
        ],
      },
      properties: {'type': 'province'},
    ),
  ];

  final specialZones = [
    ProvinceModel(
      name: 'Quần đảo Hoàng Sa',
      geometry: {
        'type': 'Polygon',
        'coordinates': [
          [
            [111.0, 16.0],
            [112.0, 16.0],
            [112.0, 17.0],
            [111.0, 17.0],
            [111.0, 16.0],
          ],
        ],
      },
      properties: {'type': 'special_zone'},
    ),
    ProvinceModel(
      name: 'Quần đảo Trường Sa',
      geometry: {
        'type': 'Polygon',
        'coordinates': [
          [
            [113.0, 8.0],
            [114.0, 8.0],
            [114.0, 9.0],
            [113.0, 9.0],
            [113.0, 8.0],
          ],
        ],
      },
      properties: {'type': 'special_zone'},
    ),
    ProvinceModel(
      name: 'Vùng biển đặc biệt',
      geometry: {
        'type': 'Polygon',
        'coordinates': [
          [
            [108.0, 14.0],
            [109.0, 14.0],
            [109.0, 15.0],
            [108.0, 15.0],
            [108.0, 14.0],
          ],
        ],
      },
      properties: {'type': 'special_zone'},
    ),
  ];

  const canvasSize = Size(800, 600);

  group('getProvinceFromPosition', () {
    test('should return null when position is outside any province', () {
      final result = getProvinceFromPosition(
        const Offset(-100, -100),
        sampleProvinces,
        [],
        canvasSize,
      );
      expect(result, isNull);
    });

    test('should return province when position is inside a polygon', () {
      final result = getProvinceFromPosition(
        const Offset(400, 300),
        sampleProvinces,
        [],
        canvasSize,
      );
      // (400, 300) falls within the canvas area mapped to the province
      expect(result, isNotNull);
      expect(result!.name, 'Tỉnh Hà Nội');
    });

    test('should return province for MultiPolygon geometry', () {
      final result = getProvinceFromPosition(
        const Offset(400, 300),
        multiPolygonProvinces,
        [],
        canvasSize,
      );
      expect(result, isNotNull);
      expect(result!.name, 'Tỉnh Đồng Nai');
    });

    test('should return null for empty provinces list', () {
      final result = getProvinceFromPosition(
        const Offset(400, 300),
        [],
        [],
        canvasSize,
      );
      expect(result, isNull);
    });

    test('should return onlyProvince when specified', () {
      final target = sampleProvinces.first;
      final result = getProvinceFromPosition(
        const Offset(400, 300),
        sampleProvinces,
        [],
        canvasSize,
        onlyProvince: target,
      );
      expect(result, isNotNull);
      expect(result!.name, 'Tỉnh Hà Nội');
    });

    test('should return null when position is not in onlyProvince', () {
      final target = sampleProvinces.first;
      final result = getProvinceFromPosition(
        const Offset(-100, -100),
        sampleProvinces,
        [],
        canvasSize,
        onlyProvince: target,
      );
      expect(result, isNull);
    });

    test('should return special zone when position is inside it', () {
      final result = getProvinceFromPosition(
        const Offset(400, 300),
        sampleProvinces,
        specialZones,
        canvasSize,
      );
      expect(result, isNotNull);
    });

    test('should handle zero size canvas gracefully', () {
      // Should not throw with zero size canvas
      expect(
        () => getProvinceFromPosition(
          const Offset(400, 300),
          sampleProvinces,
          [],
          const Size(0, 0),
        ),
        returnsNormally,
      );
    });

    test(
      'should return null for unknown position with onlyHoangSa special zone',
      () {
        // A position far outside won't hit any special zone or province
        final result = getProvinceFromPosition(
          const Offset(-1000, -1000),
          sampleProvinces,
          specialZones,
          canvasSize,
        );
        expect(result, isNull);
      },
    );
  });
}
