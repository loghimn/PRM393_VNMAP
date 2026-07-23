import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/utils/geo_utils.dart';

void main() {
  group('GeoUtils.convert', () {
    test('should convert lon/lat to Offset correctly', () {
      final offset = GeoUtils.convert(105.0, 21.0);
      // x = (105 - 102) * 50 = 150
      // y = (25 - 21) * 50 = 200
      expect(offset.dx, 150.0);
      expect(offset.dy, 200.0);
    });

    test('should return origin for reference point (102, 25)', () {
      final offset = GeoUtils.convert(102, 25);
      expect(offset.dx, 0);
      expect(offset.dy, 0);
    });

    test('should handle negative longitude difference', () {
      final offset = GeoUtils.convert(100.0, 20.0);
      // x = (100 - 102) * 50 = -100
      // y = (25 - 20) * 50 = 250
      expect(offset.dx, -100.0);
      expect(offset.dy, 250.0);
    });

    test('should return Offset(0,0) for NaN values', () {
      final offset = GeoUtils.convert(double.nan, 21.0);
      expect(offset.dx, 0);
      expect(offset.dy, 0);
    });
  });

  group('GeoUtils.calculateArea', () {
    test('should calculate area of a simple square', () {
      final ring = [
        [0.0, 0.0],
        [1.0, 0.0],
        [1.0, 1.0],
        [0.0, 1.0],
        [0.0, 0.0],
      ];
      final area = GeoUtils.calculateArea(ring);
      expect(area, greaterThan(0));
    });

    test('should return 0 for empty ring', () {
      final area = GeoUtils.calculateArea([]);
      expect(area, 0);
    });

    test('should handle ring with only one point', () {
      final ring = [
        [0.0, 0.0],
      ];
      final area = GeoUtils.calculateArea(ring);
      expect(area, 0);
    });

    test('should skip non-list elements', () {
      final ring = [
        [0.0, 0.0],
        [1.0, 0.0],
        'invalid',
        [0.0, 0.0],
      ];
      final area = GeoUtils.calculateArea(ring);
      expect(area, greaterThanOrEqualTo(0));
    });
  });

  group('GeoUtils.findLargestRing', () {
    test('should return the largest polygon ring', () {
      final coordinates = [
        [
          [
            [0.0, 0.0],
            [2.0, 0.0],
            [2.0, 2.0],
            [0.0, 2.0],
            [0.0, 0.0],
          ],
        ],
        [
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 1.0],
            [0.0, 0.0],
          ],
        ],
      ];
      final largest = GeoUtils.findLargestRing(coordinates);
      expect(largest, isA<List>());
      expect(largest.length, greaterThanOrEqualTo(1));
    });

    test('should return empty list for empty input', () {
      final largest = GeoUtils.findLargestRing([]);
      expect(largest, []);
    });

    test('should skip invalid polygons', () {
      final coordinates = ['invalid', 123, null];
      final largest = GeoUtils.findLargestRing(coordinates);
      expect(largest, []);
    });

    test('should skip empty polygons', () {
      final coordinates = [[], []];
      final largest = GeoUtils.findLargestRing(coordinates);
      expect(largest, []);
    });
  });

  group('GeoUtils.getAnchorPoint', () {
    test('should return center of a ring', () {
      final ring = [
        [105.0, 21.0],
        [106.0, 21.0],
        [106.0, 22.0],
        [105.0, 22.0],
        [105.0, 21.0],
      ];
      final anchor = GeoUtils.getAnchorPoint(ring);
      expect(anchor.dx, greaterThan(0));
      expect(anchor.dy, greaterThan(0));
    });

    test('should return Offset(0,0) for empty ring', () {
      final anchor = GeoUtils.getAnchorPoint([]);
      expect(anchor, const Offset(0, 0));
    });

    test('should handle ring with non-list points', () {
      final ring = ['invalid', null, 123];
      final anchor = GeoUtils.getAnchorPoint(ring);
      expect(anchor, const Offset(0, 0));
    });

    test('should skip NaN coordinates', () {
      final ring = [
        [double.nan, double.nan],
        [105.0, 21.0],
      ];
      final anchor = GeoUtils.getAnchorPoint(ring);
      expect(anchor.dx, greaterThan(0));
      expect(anchor.dy, greaterThan(0));
    });
  });
}
