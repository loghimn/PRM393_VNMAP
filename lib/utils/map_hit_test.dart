import 'package:flutter/material.dart';

import '../models/province_model.dart';
import 'map_transform.dart';
import 'path_utils.dart';
import 'island_insets.dart';

ProvinceModel? getProvinceFromPosition(
  Offset position,
  List<ProvinceModel> provinces,
  List<ProvinceModel> specialZones,
  Size canvasSize, {
  ProvinceModel? onlyProvince,
}) {
  if (onlyProvince == null) {
    // Check Hoàng Sa
    final hoangSaRect = getHoangSaInsetRect(canvasSize);
    if (hoangSaRect.contains(position)) {
      try {
        return specialZones.firstWhere((z) => z.name.contains('Hoàng Sa'));
      } catch (_) {}
    }

    // Check Trường Sa
    final truongSaRect = getTruongSaInsetRect(canvasSize);
    if (truongSaRect.contains(position)) {
      try {
        return specialZones.firstWhere((z) => z.name.contains('Trường Sa'));
      } catch (_) {}
    }
  }

  final provinceList = onlyProvince != null ? [onlyProvince] : provinces;

  final transform = calculateMapTransform(canvasSize, provinceList);

  final adjusted = Offset(
    (position.dx - transform.offsetX) / transform.scale,
    (position.dy - transform.offsetY) / transform.scale,
  );

  for (var province in provinceList) {
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
    // Skip Hoàng Sa & Trường Sa since they are handled via inset boxes
    if (zone.name.contains('Hoàng Sa') || zone.name.contains('Trường Sa')) {
      continue;
    }

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

