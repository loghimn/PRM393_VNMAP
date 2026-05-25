import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/utils/geo_utils.dart';

class PathUtils {
  static Path createPolygonPath(dynamic coordinates) {
    Path path = Path();

    // Handle all rings: coordinates[0] is outer boundary, coordinates[1...n] are holes
    for (var ringIndex = 0; ringIndex < coordinates.length; ringIndex++) {
      final ring = coordinates[ringIndex];

      if (ring is! List || ring.isEmpty) continue;

      bool isFirstPoint = true;

      for (int i = 0; i < ring.length; i++) {
        try {
          final point = ring[i];

          if (point is! List || point.length < 2) continue;

          double lon = point[0].toDouble();
          double lat = point[1].toDouble();

          // Skip if coordinates are NaN or infinite
          if (lon.isNaN || lon.isInfinite || lat.isNaN || lat.isInfinite) {
            continue;
          }

          final p = GeoUtils.convert(lon, lat);

          // Skip if converted position is invalid
          if (p.dx.isNaN || p.dx.isInfinite || p.dy.isNaN || p.dy.isInfinite) {
            continue;
          }

          if (isFirstPoint) {
            path.moveTo(p.dx, p.dy);
            isFirstPoint = false;
          } else {
            path.lineTo(p.dx, p.dy);
          }
        } catch (e) {
          // Skip problematic points
          continue;
        }
      }

      if (!isFirstPoint) {
        path.close();
      }
    }

    return path;
  }

  /// Safe polygon path creation with fallback for problematic provinces like An Giang
  static Path createPolygonPathSafe(
    dynamic coordinates, {
    String? provinceName,
  }) {
    try {
      return createPolygonPath(coordinates);
    } catch (e) {
      print('Error creating path for $provinceName: $e');
      // Return empty path if something goes wrong
      return Path();
    }
  }
}
