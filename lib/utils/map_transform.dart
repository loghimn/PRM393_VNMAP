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

  void scanRing(List ring) {
    for (final point in ring) {
      if (point is! List || point.length < 2) continue;

      final p = GeoUtils.convert(point[0].toDouble(), point[1].toDouble());

      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }
  }

  for (final province in provinces) {
    final geometry = province.geometry;

    final type = geometry['type'];
    final coords = geometry['coordinates'];

    if (type == 'Polygon') {
      scanRing(coords[0]);
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        scanRing(poly[0]);
      }
    }
  }

  final width = maxX - minX;
  final height = maxY - minY;

  const padding = 80.0;

  final scaleX = (size.width - padding * 2) / width;
  final scaleY = (size.height - padding * 2) / height;

  final scale = scaleX < scaleY ? scaleX : scaleY;

  final offsetX = (size.width - width * scale) / 2 - minX * scale;

  final offsetY = (size.height - height * scale) / 2 - minY * scale - 20;

  return MapTransform(scale: scale, offsetX: offsetX, offsetY: offsetY);
}
