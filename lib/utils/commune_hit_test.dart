import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/utils/path_utils.dart';
import '../models/province_model.dart';

ProvinceModel? getCommuneFromPositionRaw(
  Offset position,
  List<ProvinceModel> communes,
  ProvinceModel focusedProvince,
) {
  for (final commune in communes) {
    if (commune.parentTen != focusedProvince.name) continue;

    final geometry = commune.geometry;
    final type = geometry['type'];
    final coords = geometry['coordinates'];

    if (type == 'Polygon') {
      final path = PathUtils.createPolygonPath(coords);
      if (path.contains(position)) {
        return commune;
      }
    } else if (type == 'MultiPolygon') {
      for (var polygon in coords) {
        final path = PathUtils.createPolygonPath(polygon);
        if (path.contains(position)) {
          return commune;
        }
      }
    }
  }

  return null;
}
