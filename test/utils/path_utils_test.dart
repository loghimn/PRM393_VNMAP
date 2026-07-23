import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/utils/path_utils.dart';
import 'dart:ui' as ui;

void main() {
  group('PathUtils.createPolygonPath', () {
    test('should create path from simple coordinates', () {
      final coordinates = [
        [
          [105.0, 21.0],
          [106.0, 21.0],
          [106.0, 22.0],
          [105.0, 22.0],
          [105.0, 21.0],
        ],
      ];
      final path = PathUtils.createPolygonPath(coordinates);
      expect(path, isA<ui.Path>());
      expect(path.getBounds().width, greaterThan(0));
      expect(path.getBounds().height, greaterThan(0));
    });

    test('should return empty path for empty coordinates', () {
      final path = PathUtils.createPolygonPath([]);
      expect(path, isA<ui.Path>());
      expect(path.getBounds().isEmpty, isTrue);
    });

    test('should handle null coordinates via safe method', () {
      final path = PathUtils.createPolygonPathSafe(null, provinceName: 'Test');
      expect(path, isA<ui.Path>());
    });

    test('should handle coordinates with holes', () {
      final coordinates = [
        [
          [105.0, 21.0],
          [107.0, 21.0],
          [107.0, 23.0],
          [105.0, 23.0],
          [105.0, 21.0],
        ],
        [
          [106.0, 21.5],
          [106.5, 21.5],
          [106.5, 22.0],
          [106.0, 22.0],
          [106.0, 21.5],
        ],
      ];
      final path = PathUtils.createPolygonPath(coordinates);
      expect(path, isA<ui.Path>());
    });

    test('should skip invalid points', () {
      final coordinates = [
        [
          [105.0, 21.0],
          'invalid',
          [106.0, 22.0],
          [105.0, 21.0],
        ],
      ];
      final path = PathUtils.createPolygonPath(coordinates);
      expect(path, isA<ui.Path>());
    });

    test('should skip points with NaN coordinates', () {
      final coordinates = [
        [
          [105.0, 21.0],
          [double.nan, double.nan],
          [106.0, 22.0],
          [105.0, 21.0],
        ],
      ];
      final path = PathUtils.createPolygonPath(coordinates);
      expect(path, isA<ui.Path>());
    });

    test('should handle ring with only one valid point', () {
      final coordinates = [
        [
          [105.0, 21.0],
        ],
      ];
      final path = PathUtils.createPolygonPath(coordinates);
      expect(path, isA<ui.Path>());
    });
  });

  group('PathUtils.createPolygonPathSafe', () {
    test('should create path for valid coordinates', () {
      final coordinates = [
        [
          [105.0, 21.0],
          [106.0, 21.0],
          [106.0, 22.0],
          [105.0, 22.0],
          [105.0, 21.0],
        ],
      ];
      final path = PathUtils.createPolygonPathSafe(
        coordinates,
        provinceName: 'Test',
      );
      expect(path, isA<ui.Path>());
    });

    test('should return empty path on error', () {
      // Passing null should trigger catch block
      final path = PathUtils.createPolygonPathSafe(null, provinceName: 'Error');
      expect(path, isA<ui.Path>());
    });

    test('should work without province name', () {
      final coordinates = [
        [
          [105.0, 21.0],
          [106.0, 21.0],
          [106.0, 22.0],
          [105.0, 22.0],
          [105.0, 21.0],
        ],
      ];
      final path = PathUtils.createPolygonPathSafe(coordinates);
      expect(path, isA<ui.Path>());
    });
  });
}
