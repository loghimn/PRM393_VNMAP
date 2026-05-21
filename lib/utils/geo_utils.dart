import 'package:flutter/material.dart';

class GeoUtils {
  static const double scale = 50;

  static Offset convert(double lon, double lat) {
    final x = (lon - 102) * scale;
    final y = (25 - lat) * scale;

    if (x.isNaN || y.isNaN) {
      return const Offset(0, 0);
    }

    return Offset(x, y);
  }

  static double calculateArea(List ring) {
    double area = 0;

    for (int i = 0; i < ring.length - 1; i++) {
      final p1 = ring[i];
      final p2 = ring[i + 1];

      if (p1 is! List || p2 is! List) continue;

      double x1 = p1[0].toDouble();
      double y1 = p1[1].toDouble();

      double x2 = p2[0].toDouble();
      double y2 = p2[1].toDouble();

      area += (x1 * y2 - x2 * y1);
    }

    return area.abs();
  }

  static List findLargestRing(List coordinates) {
    List? largest;
    double maxArea = 0;

    for (var polygon in coordinates) {
      // skip polygon lỗi
      if (polygon is! List || polygon.isEmpty) continue;

      final ring = polygon[0];

      // skip ring rỗng
      if (ring is! List || ring.isEmpty) continue;

      final area = calculateArea(ring);

      if (area > maxArea) {
        maxArea = area;
        largest = polygon;
      }
    }

    // fallback chống crash
    return largest ?? [[]];
  }

  static Offset getAnchorPoint(List ring) {
    if (ring.isEmpty) {
      return const Offset(0, 0);
    }

    double sumX = 0;
    double sumY = 0;
    int count = 0;

    for (var point in ring) {
      if (point is! List || point.length < 2) continue;

      final p = convert(point[0].toDouble(), point[1].toDouble());

      if (p.dx.isNaN || p.dy.isNaN) continue;

      sumX += p.dx;
      sumY += p.dy;

      count++;
    }

    if (count == 0) {
      return const Offset(0, 0);
    }

    return Offset(sumX / count, sumY / count);
  }
}
