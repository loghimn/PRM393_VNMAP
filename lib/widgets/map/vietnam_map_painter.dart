import 'package:flutter/material.dart';

import '../../models/province_model.dart';
import '../../models/provinceLabel.dart';

import '../../utils/geo_utils.dart';
import '../../utils/map_transform.dart';
import '../../utils/path_utils.dart';
import '../../utils/province_special_handler.dart';
import 'package:vietnam_geo_dashboard/utils/province_anchor_overrides.dart';
import '../../utils/island_insets.dart';

class VietnamMapPainter extends CustomPainter {
  final List<ProvinceModel> provinces;
  final List<ProvinceModel> specialZones;
  final ProvinceModel? hoveredProvince;
  final Offset mousePosition;
  final List<ProvinceModel> communes;
  final ProvinceModel? focusedProvince;
  final Size viewportSize;

  VietnamMapPainter({
    required this.provinces,
    required this.specialZones,
    this.hoveredProvince,
    required this.mousePosition,
    required this.communes,
    required this.focusedProvince,
    required this.viewportSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final transform = calculateMapTransform(viewportSize, provinces);

    final fitScale = transform.scale;
    final offsetX = transform.offsetX;
    final offsetY = transform.offsetY;

    canvas.save();

    canvas.translate(offsetX, offsetY);

    canvas.scale(fitScale);

    List<ProvinceLabel> labels = [];

    final adjustedMouse = Offset(
      (mousePosition.dx - offsetX) / fitScale,
      (mousePosition.dy - offsetY) / fitScale,
    );

    if (focusedProvince != null) {
      canvas.restore();

      drawFocusedProvinceMode(canvas, viewportSize);

      return;
    }

    for (var province in provinces) {
      final geometry = province.geometry;

      final type = geometry['type'];
      final coordinates = geometry['coordinates'];

      if (coordinates == null || coordinates.isEmpty) {
        continue;
      }

      // =========================
      // POLYGON
      // =========================

      if (type == 'Polygon') {
        final path = PathUtils.createPolygonPath(coordinates);

        final isHovered = path.contains(adjustedMouse);

        final provincePaint = Paint()
          ..color = getProvinceColor(province, isHovered)
          ..style = PaintingStyle.fill;

        canvas.drawPath(path, provincePaint);

        canvas.drawPath(path, borderPaint);

        final ring = coordinates[0];

        if (ring.isEmpty) continue;

        Offset anchor =
            ProvinceAnchorOverrides.overrides[province.name] ??
            GeoUtils.getAnchorPoint(ring);

        labels.add(ProvinceLabel(position: anchor, name: province.name));
      }
      // =========================
      // MULTIPOLYGON
      // =========================
      else if (type == 'MultiPolygon') {
        bool hovered = false;

        for (var polygon in coordinates) {
          if (polygon.isEmpty) continue;
          if (polygon[0].isEmpty) continue;

          final path = PathUtils.createPolygonPath(polygon);

          if (path.contains(adjustedMouse)) {
            hovered = true;
          }

          final provincePaint = Paint()
            ..color = getProvinceColor(province, hovered)
            ..style = PaintingStyle.fill;

          canvas.drawPath(path, provincePaint);

          canvas.drawPath(path, borderPaint);
        }

        final biggest = GeoUtils.findLargestRing(coordinates);

        if (biggest.isEmpty || biggest[0].isEmpty) {
          continue;
        }

        Offset anchor =
            ProvinceAnchorOverrides.overrides[province.name] ??
            GeoUtils.getAnchorPoint(biggest[0]);

        labels.add(ProvinceLabel(position: anchor, name: province.name));
      }
    }

    for (var zone in specialZones) {
      // Skip Hoàng Sa and Trường Sa as they will be drawn in offshore inset boxes
      if (zone.name.contains('Hoàng Sa') || zone.name.contains('Trường Sa')) {
        continue;
      }

      final geometry = zone.geometry;

      final type = geometry['type'];
      final coordinates = geometry['coordinates'];

      final islandPaint = Paint()
        ..color = Colors.orangeAccent
        ..style = PaintingStyle.fill;

      final islandBorderPaint = Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      if (type == 'Polygon') {
        final path = PathUtils.createPolygonPath(coordinates);
        canvas.drawPath(path, islandPaint);
        canvas.drawPath(path, islandBorderPaint);
      } else if (type == 'MultiPolygon') {
        for (final polygon in coordinates) {
          final path = PathUtils.createPolygonPath(polygon);
          canvas.drawPath(path, islandPaint);
          canvas.drawPath(path, islandBorderPaint);
        }
      }

      // Draw a label for each special zone (Hoàng Sa / Trường Sa)
      final ring = type == 'Polygon' ? coordinates[0] : GeoUtils.findLargestRing(coordinates)[0];
      if (ring.isNotEmpty) {
        final anchor = GeoUtils.getAnchorPoint(ring);

        String labelText = zone.name;
        if (labelText.contains('Hoàng Sa')) {
          labelText = 'QĐ. Hoàng Sa';
        } else if (labelText.contains('Trường Sa')) {
          labelText = 'QĐ. Trường Sa';
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(anchor.dx - textPainter.width / 2, anchor.dy - 15));
      }
    }

    // =========================
    // DRAW DOTS
    // =========================



    canvas.restore();

    // Draw inset boxes for Hoàng Sa & Trường Sa in viewport space
    if (focusedProvince == null) {
      _drawOffshoreIslandInsets(canvas, viewportSize);
    }
  }



  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Color getProvinceColor(ProvinceModel province, bool hovered) {
    if (hovered) {
      return Colors.orange;
    }

    switch (province.properties['type']) {
      case 'Đặc khu':
        return Colors.blueAccent;

      case 'Thành phố':
        return Colors.purple;

      case 'Tỉnh':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  void drawFocusedProvinceMode(Canvas canvas, Size viewportSize) {
    final province = focusedProvince!;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    try {
      // Include both province AND communes in transform calculation
      final regionsForTransform = [
        province,
        ...communes.where((c) => c.parentTen == province.name),
      ];
      final transform = calculateMapTransform(viewportSize, regionsForTransform);

      canvas.save();
      canvas.translate(transform.offsetX, transform.offsetY);
      canvas.scale(transform.scale);

      // Determine if the province itself is hovered (and not a specific commune)
      final isProvinceHovered = hoveredProvince?.name == province.name;

      final fillPaint = Paint()
        ..color = isProvinceHovered ? Colors.orange : Colors.green
        ..style = PaintingStyle.fill;

      final geometry = province.geometry;
      // if (geometry == null) {
      //   canvas.restore();
      //   return;
      // }

      final type = geometry['type'];
      final coordinates = geometry['coordinates'];

      if (coordinates == null || coordinates.isEmpty) {
        canvas.restore();
        return;
      }

      // ===== DRAW BIG PROVINCE =====
      try {
        if (type == 'Polygon') {
          final path = PathUtils.createPolygonPathSafe(
            coordinates,
            provinceName: province.name,
          );
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, borderPaint);
        } else if (type == 'MultiPolygon') {
          for (final polygon in coordinates) {
            if (polygon == null || polygon.isEmpty) continue;
            final path = PathUtils.createPolygonPathSafe(
              polygon,
              provinceName: province.name,
            );
            canvas.drawPath(path, fillPaint);
            canvas.drawPath(path, borderPaint);
          }
        }
      } catch (e) {
        print('Error drawing province ${province.name}: $e');
      }

      // ===== DRAW COMMUNES =====
      // Skip commune rendering for provinces with known data issues
      if (!ProvinceSpecialHandler.shouldSkipCommuneRender(province)) {
        final relatedCommunes = communes
            .where((c) => c.parentTen == province.name)
            .toList();

        print(
          'Drawing communes for ${province.name}: ${relatedCommunes.length} communes',
        );

        if (relatedCommunes.isEmpty) {
          print('No communes found for ${province.name}');
        }

        int drawnCount = 0;
        int skippedCount = 0;

        for (final commune in relatedCommunes) {
          try {
            final communeGeometry = commune.geometry;
            // if (communeGeometry == null) {
            //   skippedCount++;
            //   continue;
            // }

            final communeCoords = communeGeometry['coordinates'];
            if (communeCoords == null || communeCoords.isEmpty) {
              skippedCount++;
              continue;
            }

            // Highlight hovered commune
            final isCommuneHovered = hoveredProvince?.name == commune.name;
            final communePaint = Paint()
              ..color = isCommuneHovered
                  ? Colors.yellow.withOpacity(0.7)
                  : Colors.black.withOpacity(0.1)
              ..style = PaintingStyle.fill;

            final communeBorderPaint = Paint()
              ..color = isCommuneHovered
                  ? Colors.white
                  : Colors.white.withOpacity(0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = isCommuneHovered
                  ? 2 / transform.scale
                  : 1 / transform.scale;

            if (communeGeometry['type'] == 'Polygon') {
              final path = PathUtils.createPolygonPathSafe(
                communeCoords,
                provinceName: commune.name,
              );
              canvas.drawPath(path, communePaint);
              canvas.drawPath(path, communeBorderPaint);
              drawnCount++;
            } else if (communeGeometry['type'] == 'MultiPolygon') {
              for (var polygon in communeCoords) {
                if (polygon == null || polygon.isEmpty) continue;
                final path = PathUtils.createPolygonPathSafe(
                  polygon,
                  provinceName: commune.name,
                );
                canvas.drawPath(path, communePaint);
                canvas.drawPath(path, communeBorderPaint);
              }
              drawnCount++;
            }
          } catch (e) {
            print('Error drawing commune ${commune.name}: $e');
            skippedCount++;
            continue;
          }
        }

        print('Communes drawn: $drawnCount, skipped: $skippedCount');
      } else {
        print('Skipping commune rendering for ${province.name} (known issue)');
      }

      canvas.restore();
    } catch (e) {
      print('Error in drawFocusedProvinceMode for ${province.name}: $e');
      canvas.restore();
    }
  }

  void _drawOffshoreIslandInsets(Canvas canvas, Size size) {
    // 1. Draw Hoàng Sa
    try {
      final hoangSaZone = specialZones.firstWhere((z) => z.name.contains('Hoàng Sa'));
      final hoangSaRect = getHoangSaInsetRect(size);
      _drawIslandInset(canvas, hoangSaRect, hoangSaZone, 'QĐ. Hoàng Sa');
    } catch (e) {
      print('Error drawing Hoàng Sa inset: $e');
    }

    // 2. Draw Trường Sa
    try {
      final truongSaZone = specialZones.firstWhere((z) => z.name.contains('Trường Sa'));
      final truongSaRect = getTruongSaInsetRect(size);
      _drawIslandInset(canvas, truongSaRect, truongSaZone, 'QĐ. Trường Sa');
    } catch (e) {
      print('Error drawing Trường Sa inset: $e');
    }
  }

  void _drawIslandInset(Canvas canvas, Rect rect, ProvinceModel zone, String label) {
    final isHovered = hoveredProvince?.name == zone.name;

    // --- DRAW BACKGROUND CARD (Glassmorphic look) ---
    final bgPaint = Paint()
      ..color = isHovered ? const Color(0xEE243447) : const Color(0xDD18222F)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isHovered ? Colors.orangeAccent : Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 1.5 : 1.0;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));
    canvas.drawRRect(rrect, shadowPaint);
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // --- CALCULATE BOUNDS AND LOCAL SCALE ---
    final geometry = zone.geometry;
    final type = geometry['type'];
    final coordinates = geometry['coordinates'];

    if (coordinates == null || coordinates.isEmpty) return;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    void scanRing(List ring) {
      for (var pt in ring) {
        if (pt is List && pt.length >= 2) {
          double x = pt[0].toDouble();
          double y = pt[1].toDouble();
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (type == 'Polygon') {
      scanRing(coordinates[0]);
    } else if (type == 'MultiPolygon') {
      for (var poly in coordinates) {
        scanRing(poly[0]);
      }
    }

    if (minX == double.infinity || maxX == -double.infinity) return;

    final double geoW = maxX - minX;
    final double geoH = maxY - minY;

    // Padding inside the inset card
    const double innerPadding = 8.0;
    const double titleHeight = 16.0;

    final double availW = rect.width - 2 * innerPadding;
    final double availH = rect.height - 2 * innerPadding - titleHeight;

    final double scaleX = availW / (geoW > 0 ? geoW : 1.0);
    final double scaleY = availH / (geoH > 0 ? geoH : 1.0);
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // Center coordinates
    final double insetCenterX = rect.left + rect.width / 2;
    final double insetCenterY = rect.top + innerPadding + availH / 2;
    final double geoCenterX = (minX + maxX) / 2;
    final double geoCenterY = (minY + maxY) / 2;

    // --- DRAW ISLANDS ---
    final islandPaint = Paint()
      ..color = isHovered ? Colors.orange : Colors.orangeAccent
      ..style = PaintingStyle.fill;

    final islandBorderPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    Path createInsetPath(List ring) {
      final path = Path();
      if (ring.isEmpty) return path;
      final first = ring[0];
      final startX = insetCenterX + (first[0].toDouble() - geoCenterX) * scale;
      final startY = insetCenterY - (first[1].toDouble() - geoCenterY) * scale;
      path.moveTo(startX, startY);
      for (int i = 1; i < ring.length; i++) {
        final pt = ring[i];
        final x = insetCenterX + (pt[0].toDouble() - geoCenterX) * scale;
        final y = insetCenterY - (pt[1].toDouble() - geoCenterY) * scale;
        path.lineTo(x, y);
      }
      path.close();
      return path;
    }

    if (type == 'Polygon') {
      final path = createInsetPath(coordinates[0]);
      canvas.drawPath(path, islandPaint);
      canvas.drawPath(path, islandBorderPaint);
    } else if (type == 'MultiPolygon') {
      for (final poly in coordinates) {
        if (poly.isEmpty) continue;
        final path = createInsetPath(poly[0]);
        canvas.drawPath(path, islandPaint);
        canvas.drawPath(path, islandBorderPaint);
      }
    }

    // --- DRAW LABEL ---
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isHovered ? Colors.orangeAccent : Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.bottom - titleHeight - 2.0,
      ),
    );
  }
}
