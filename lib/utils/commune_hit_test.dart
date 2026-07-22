import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/utils/path_utils.dart';
import '../models/province_model.dart';

ProvinceModel? getCommuneFromPositionRaw(
  Offset position,
  List<ProvinceModel> communes,
  ProvinceModel focusedProvince,
) {
  // Debug logging for An Giang
  bool isAnGiang = focusedProvince.name == 'Tỉnh An Giang';
  if (isAnGiang) {
    debugPrint('[An Giang Debug] Checking position: $position');
    debugPrint('[An Giang Debug] Total communes to check: ${communes.length}');
  }

  int checkedCount = 0;
  int pathErrorCount = 0;
  int firstPathLogged = 0;

  for (final commune in communes) {
    try {
      if (commune.parentTen != focusedProvince.name) continue;

      checkedCount++;

      final geometry = commune.geometry;
      // if (geometry == null) continue;

      final type = geometry['type'];
      final coords = geometry['coordinates'];

      if (coords == null || coords.isEmpty) {
        if (isAnGiang) {
          debugPrint('[An Giang Debug] Skipping ${commune.name}: empty coords');
        }
        continue;
      }

      if (type == 'Polygon') {
        final path = PathUtils.createPolygonPathSafe(
          coords,
          provinceName: focusedProvince.name,
        );

        final bounds = path.getBounds();
        if (firstPathLogged < 2 && isAnGiang) {
          debugPrint(
            '[An Giang Debug] ${commune.name} bounds: left=${bounds.left}, top=${bounds.top}, right=${bounds.right}, bottom=${bounds.bottom}',
          );
          firstPathLogged++;
        }

        if (bounds.isEmpty) {
          pathErrorCount++;
          if (isAnGiang) {
            debugPrint('[An Giang Debug] Empty path for ${commune.name}');
          }
          continue;
        }

        if (path.contains(position)) {
          if (isAnGiang) {
            debugPrint('[An Giang Debug] Found match: ${commune.name}');
          }
          return commune;
        }
      } else if (type == 'MultiPolygon') {
        for (var i = 0; i < coords.length; i++) {
          var polygon = coords[i];
          if (polygon == null || polygon.isEmpty) continue;
          final path = PathUtils.createPolygonPathSafe(
            polygon,
            provinceName: focusedProvince.name,
          );

          final bounds = path.getBounds();
          if (firstPathLogged < 2 && isAnGiang && i == 0) {
            debugPrint(
              '[An Giang Debug] ${commune.name}[$i] bounds: left=${bounds.left}, top=${bounds.top}, right=${bounds.right}, bottom=${bounds.bottom}',
            );
            firstPathLogged++;
          }

          if (bounds.isEmpty) {
            pathErrorCount++;
            continue;
          }

          if (path.contains(position)) {
            if (isAnGiang) {
              debugPrint(
                '[An Giang Debug] Found match in MultiPolygon #$i: ${commune.name}',
              );
            }
            return commune;
          }
        }
      }
    } catch (e) {
      // Log and skip problematic communes
      if (isAnGiang) {
        debugPrint('[An Giang Debug] Error checking commune ${commune.name}: $e');
      } else {
        debugPrint('Error checking commune ${commune.name}: $e');
      }
      continue;
    }
  }

  if (isAnGiang) {
    debugPrint(
      '[An Giang Debug] Checked $checkedCount communes, $pathErrorCount had empty paths - NO MATCH FOUND',
    );
  }

  return null;
}
