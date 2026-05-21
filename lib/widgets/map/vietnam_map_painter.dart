import 'package:flutter/material.dart';

import '../../models/province_model.dart';
import '../../models/provinceLabel.dart';

import '../../utils/geo_utils.dart';
import '../../utils/map_transform.dart';
import '../../utils/path_utils.dart';
import 'package:vietnam_geo_dashboard/utils/province_anchor_overrides.dart';

class VietnamMapPainter extends CustomPainter {
  final List<ProvinceModel> provinces;
  final List<ProvinceModel> specialZones;
  final ProvinceModel? hoveredProvince;
  final Offset mousePosition;

  VietnamMapPainter({
    required this.provinces,
    required this.specialZones,
    this.hoveredProvince,
    required this.mousePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final allRegions = [...provinces, ...specialZones];

    final transform = calculateMapTransform(size, allRegions);

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
      final geometry = zone.geometry;

      final type = geometry['type'];
      final coordinates = geometry['coordinates'];

      final islandPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.fill;

      if (type == 'Polygon') {
        final path = PathUtils.createPolygonPath(coordinates);

        canvas.drawPath(path, islandPaint);

        canvas.drawPath(path, borderPaint);
      } else if (type == 'MultiPolygon') {
        for (final polygon in coordinates) {
          final path = PathUtils.createPolygonPath(polygon);

          canvas.drawPath(path, islandPaint);

          canvas.drawPath(path, borderPaint);
        }
      }
    }

    // =========================
    // DRAW DOTS
    // =========================

    for (var label in labels) {
      _drawDot(canvas, label.position);
    }

    // =========================
    // DRAW LABELS
    // =========================

    for (var label in labels) {
      drawCalloutLabel(canvas, label.position, label.name);
    }

    canvas.restore();
    // _drawSpecialZoneInset(canvas, size);
  }

  // ====================================================
  // DRAW DOT
  // ====================================================

  void _drawDot(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 3, paint);
  }

  // ====================================================
  // DRAW LABEL
  // ====================================================

  void drawCalloutLabel(Canvas canvas, Offset anchor, String name) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 1.2;

    final bool isLeftSide = anchor.dx < 180;

    const lineLength = 45.0;

    late Offset lineEnd;
    late Offset textOffset;

    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    if (isLeftSide) {
      lineEnd = Offset(anchor.dx - lineLength, anchor.dy);

      textOffset = Offset(
        lineEnd.dx - textPainter.width - 6,
        lineEnd.dy - textPainter.height / 2,
      );
    } else {
      lineEnd = Offset(anchor.dx + lineLength, anchor.dy);

      textOffset = Offset(lineEnd.dx + 6, lineEnd.dy - textPainter.height / 2);
    }

    canvas.drawLine(anchor, lineEnd, linePaint);

    textPainter.paint(canvas, textOffset);
  }

  void _drawSpecialZoneInset(Canvas canvas, Size size) {
    final insetRect = Rect.fromLTWH(
      size.width - 220,
      size.height - 220,
      180,
      180,
    );

    // background box
    final bgPaint = Paint()..color = Colors.black26;

    // border
    final borderPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(insetRect, bgPaint);

    canvas.drawRect(insetRect, borderPaint);

    // ===== SAVE =====

    canvas.save();

    // move island vào box
    canvas.translate(insetRect.left + 20, insetRect.top + 20);

    // scale nhỏ lại
    canvas.scale(0.15);

    for (final zone in specialZones) {
      final geometry = zone.geometry;

      final type = geometry['type'];
      final coordinates = geometry['coordinates'];

      final fillPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;

      // =========================
      // POLYGON
      // =========================

      if (type == 'Polygon') {
        final path = PathUtils.createPolygonPath(coordinates);

        canvas.drawPath(path, fillPaint);

        canvas.drawPath(path, borderPaint);
      }
      // =========================
      // MULTIPOLYGON
      // =========================
      else if (type == 'MultiPolygon') {
        for (final polygon in coordinates) {
          final path = PathUtils.createPolygonPath(polygon);

          canvas.drawPath(path, fillPaint);

          canvas.drawPath(path, borderPaint);
        }
      }
    }

    canvas.restore();

    // ===== TITLE =====

    final textPainter = TextPainter(
      text: const TextSpan(
        text: "Hoàng Sa - Trường Sa",
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(canvas, Offset(insetRect.left + 8, insetRect.top - 22));
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
}
