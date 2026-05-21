import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/utils/geo_utils.dart';

class PathUtils {
  static Path createPolygonPath(dynamic coordinates) {
    Path path = Path();

    final firstRing = coordinates[0];

    for (int i = 0; i < firstRing.length; i++) {
      final point = firstRing[i];

      if (point is! List || point.length < 2) continue;

      double lon = point[0].toDouble();
      double lat = point[1].toDouble();

      final p = GeoUtils.convert(lon, lat);

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    path.close();

    return path;
  }
}
