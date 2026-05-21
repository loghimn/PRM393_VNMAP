import 'package:flutter/material.dart';

import '../models/province_model.dart';
import 'map_transform.dart';
import 'path_utils.dart';

ProvinceModel? getProvinceFromPosition(
  Offset position,
  List<ProvinceModel> provinces,
  List<ProvinceModel> specialZones,
  Size canvasSize,
) {
  final allRegions = [...provinces, ...specialZones];

  final transform = calculateMapTransform(canvasSize, allRegions);

  final adjusted = Offset(
    (position.dx - transform.offsetX) / transform.scale,
    (position.dy - transform.offsetY) / transform.scale,
  );

  for (var province in provinces) {
    final geometry = province.geometry;

    final type = geometry['type'];
    final coordinates = geometry['coordinates'];

    if (type == 'Polygon') {
      final path = PathUtils.createPolygonPath(coordinates);

      if (path.contains(adjusted)) {
        return province;
      }
    }

    if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        final path = PathUtils.createPolygonPath(polygon);

        if (path.contains(adjusted)) {
          return province;
        }
      }
    }
  }

  for (var zone in specialZones) {
    final geometry = zone.geometry;

    final type = geometry['type'];
    final coordinates = geometry['coordinates'];

    if (type == 'Polygon') {
      final path = PathUtils.createPolygonPath(coordinates);

      if (path.contains(adjusted)) {
        return zone;
      }
    }

    if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        final path = PathUtils.createPolygonPath(polygon);

        if (path.contains(adjusted)) {
          return zone;
        }
      }
    }
  }

  return null;
}
