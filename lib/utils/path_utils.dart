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
        final point = ring[i];

        if (point is! List || point.length < 2) continue;

        double lon = point[0].toDouble();
        double lat = point[1].toDouble();

        final p = GeoUtils.convert(lon, lat);

        if (isFirstPoint) {
          path.moveTo(p.dx, p.dy);
          isFirstPoint = false;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }

      path.close();
    }

    return path;
  }
}
