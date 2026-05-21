import 'package:flutter/material.dart';

import '../models/province_model.dart';
import 'path_utils.dart';

ProvinceModel? getProvinceFromPosition(
  Offset position,
  List<ProvinceModel> provinces,
) {
  final adjusted = Offset(position.dx - 120, position.dy - 20);

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

  return null;
}
