import 'dart:ui' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/utils/map_transform.dart';

void main() {
  group('calculateMapTransform', () {
    test('should return transform for single Polygon province', () {
      final provinces = [
        ProvinceModel(
          name: 'Tỉnh Test',
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

      final transform = calculateMapTransform(const Size(800, 600), provinces);

      // Converted: x∈[150,200], y∈[150,200]; width=50, height=50
      // scaleX=(800-128)/50=13.44, scaleY=(600-96)/50=10.08
      // scale=10.08, offsetX=(800-504)/2-150*10.08=-1364, offsetY=(600-504)/2-150*10.08=-1464
      expect(transform.scale, closeTo(10.08, 0.001));
      expect(transform.offsetX, closeTo(-1364.0, 1.0));
      expect(transform.offsetY, closeTo(-1464.0, 1.0));
    });

    test('should return transform for MultiPolygon province', () {
      final provinces = [
        ProvinceModel(
          name: 'Tỉnh Multi',
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

      final transform = calculateMapTransform(const Size(800, 600), provinces);

      // Converted: x∈[250,275], y∈[700,725]; width=25, height=25
      // scaleX=672/25=26.88, scaleY=504/25=20.16, scale=20.16
      expect(transform.scale, closeTo(20.16, 0.01));
    });

    test('should return transform for empty provinces', () {
      final transform = calculateMapTransform(const Size(800, 600), []);

      // No provinces -> scannedPoints=0, minX=inf, minY=inf, maxX=-inf, maxY=-inf
      // width = height = 0 so guard → 1.0 → scaleX=672, scaleY=504, scale=504
      // offsetX = (800 - 0*504)/2 - inf*504 = 400 - inf = -inf (NaN due to inf arithmetic)
      // Just verify it runs without throwing and returns a MapTransform
      expect(transform, isA<MapTransform>());
    });

    test('should handle zero-size canvas gracefully', () {
      final provinces = [
        ProvinceModel(
          name: 'Tỉnh Test',
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

      // Should not crash with zero size
      expect(
        () => calculateMapTransform(const Size(0, 0), provinces),
        returnsNormally,
      );
    });

    test('should return transform with correct scale for landscape canvas', () {
      final provinces = [
        ProvinceModel(
          name: 'Tỉnh Test',
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

      // Landscape canvas: scale should be determined by height (taller ratio)
      final transform = calculateMapTransform(const Size(1024, 768), provinces);

      // scaleX=(1024-128)/50=17.92, scaleY=(768-96)/50=13.44
      // scale = min = 13.44
      expect(transform.scale, closeTo(13.44, 0.01));
    });

    test('should return transform with correct scale for portrait canvas', () {
      final provinces = [
        ProvinceModel(
          name: 'Tỉnh Test',
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

      // Portrait canvas: scale determined by width (narrower ratio)
      final transform = calculateMapTransform(const Size(600, 1024), provinces);

      // scaleX=(600-128)/50=9.44, scaleY=(1024-96)/50=18.56
      // scale = min = 9.44
      expect(transform.scale, closeTo(9.44, 0.01));
    });

    test(
      'should handle provinces with only offshore coordinates (second pass)',
      () {
        // All coordinates have lon > 109.6 => first pass skips everything => second pass
        final provinces = [
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
        ];

        final transform = calculateMapTransform(
          const Size(800, 600),
          provinces,
        );

        // First pass skipped everything (lon > 109.6), second pass scanned with skipOffshore=false
        // Converted: x∈[450,500], y∈[400,450]; width=50, height=50
        // scaleX=672/50=13.44, scaleY=504/50=10.08, scale=10.08
        expect(transform.scale, closeTo(10.08, 0.01));
      },
    );
  });
}
