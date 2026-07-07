import 'package:flutter/material.dart';

import '../models/province_model.dart';
import 'geo_utils.dart';

class MapTransform {
  final double scale;
  final double offsetX;
  final double offsetY;

  MapTransform({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

MapTransform calculateMapTransform(Size size, List<ProvinceModel> provinces) {
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = -double.infinity;
  double maxY = -double.infinity;

  int scannedPoints = 0;

  void scanRing(List ring, {bool skipOffshore = true}) {
    for (final point in ring) {
      if (point is! List || point.length < 2) continue;

      final double lon = point[0].toDouble();
      final double lat = point[1].toDouble();

      // Skip offshore islands (Hoàng Sa & Trường Sa) that distort the bounding box width in overview
      if (skipOffshore && lon > 109.6) continue;

      final p = GeoUtils.convert(lon, lat);

      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
      scannedPoints++;
    }
  }

  // First pass: try with skipping offshore islands
  for (final province in provinces) {
    final geometry = province.geometry;
    final type = geometry['type'];
    final coords = geometry['coordinates'];

    if (type == 'Polygon') {
      scanRing(coords[0], skipOffshore: true);
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        scanRing(poly[0], skipOffshore: true);
      }
    }
  }

  // Second pass: if no points were scanned (e.g. focusing solely on Hoàng Sa/Trường Sa)
  if (scannedPoints == 0) {
    minX = double.infinity;
    minY = double.infinity;
    maxX = -double.infinity;
    maxY = -double.infinity;

    for (final province in provinces) {
      final geometry = province.geometry;
      final type = geometry['type'];
      final coords = geometry['coordinates'];

      if (type == 'Polygon') {
        scanRing(coords[0], skipOffshore: false);
      } else if (type == 'MultiPolygon') {
        for (final poly in coords) {
          scanRing(poly[0], skipOffshore: false);
        }
      }
    }
  }

  final width = maxX - minX;
  final height = maxY - minY;

  const paddingX = 64.0;
  const paddingY = 48.0;

  final scaleX = (size.width - paddingX * 2) / (width > 0 ? width : 1.0);
  final scaleY = (size.height - paddingY * 2) / (height > 0 ? height : 1.0);

  final scale = scaleX < scaleY ? scaleX : scaleY;

  final offsetX = (size.width - width * scale) / 2 - minX * scale;

  final offsetY = (size.height - height * scale) / 2 - minY * scale;

  return MapTransform(scale: scale, offsetX: offsetX, offsetY: offsetY);
}
