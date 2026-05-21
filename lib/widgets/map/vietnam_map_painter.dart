import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/provinceLabel.dart';
import 'package:vietnam_geo_dashboard/utils/geo_utils.dart';
import 'package:vietnam_geo_dashboard/utils/path_utils.dart';
import '../../models/province_model.dart';

class VietnamMapPainter extends CustomPainter {
  final double scale = 50;
  final List<ProvinceModel> provinces;
  final ProvinceModel? hoveredProvince;
  final Offset mousePosition;

  VietnamMapPainter({
    required this.provinces,
    this.hoveredProvince,
    required this.mousePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.translate(120, 20);

    List<ProvinceLabel> labels = [];

    for (var province in provinces) {
      final geometry = province.geometry;
      final type = geometry['type'];
      final coordinates = geometry['coordinates'];

      if (coordinates == null || coordinates.isEmpty) {
        continue;
      }

      // =========================
      // HOVER COLOR
      // =========================

      final fillPaint = Paint()
        ..color = hoveredProvince?.name == province.name
            ? Colors.orange
            : Colors.green
        ..style = PaintingStyle.fill;

      // =========================
      // POLYGON
      // =========================

      if (type == 'Polygon') {
        final path = PathUtils.createPolygonPath(coordinates);

        final adjustedMouse = Offset(
          mousePosition.dx - 120,
          mousePosition.dy - 20,
        );

        final isHovered = path.contains(adjustedMouse);

        final provincePaint = Paint()
          ..color = isHovered ? Colors.orange : Colors.green
          ..style = PaintingStyle.fill;

        canvas.drawPath(path, provincePaint);
        canvas.drawPath(path, borderPaint);

        final ring = coordinates[0];

        if (ring.isEmpty) continue;

        final anchor = GeoUtils.getAnchorPoint(ring);

        if (anchor.dx == 0 && anchor.dy == 0) {
          continue;
        }

        labels.add(ProvinceLabel(position: anchor, name: province.name));
      }
      // =========================
      // MULTIPOLYGON
      // =========================
      else if (type == 'MultiPolygon') {
        for (var polygon in coordinates) {
          if (polygon.isEmpty) continue;
          if (polygon[0].isEmpty) continue;

          final path = PathUtils.createPolygonPath(polygon);

          final adjustedMouse = Offset(
            mousePosition.dx - 120,
            mousePosition.dy - 20,
          );

          final isHovered = path.contains(adjustedMouse);

          final provincePaint = Paint()
            ..color = isHovered ? Colors.orange : Colors.green
            ..style = PaintingStyle.fill;

          canvas.drawPath(path, provincePaint);
          canvas.drawPath(path, borderPaint);
        }

        final biggest = GeoUtils.findLargestRing(coordinates);

        if (biggest.isEmpty || biggest[0].isEmpty) {
          continue;
        }

        final anchor = GeoUtils.getAnchorPoint(biggest[0]);

        if (anchor.dx == 0 && anchor.dy == 0) {
          continue;
        }

        labels.add(ProvinceLabel(position: anchor, name: province.name));
      }
    }

    // =========================
    // DRAW DOTS
    // =========================

    for (var label in labels) {
      _drawDot(canvas, label.position);
    }

    if (hoveredProvince != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: hoveredProvince!.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final tooltipPosition = Offset(
        mousePosition.dx + 12,
        mousePosition.dy + 12,
      );

      final rect = Rect.fromLTWH(
        tooltipPosition.dx - 6,
        tooltipPosition.dy - 4,
        textPainter.width + 12,
        textPainter.height + 8,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = Colors.black87,
      );

      textPainter.paint(canvas, tooltipPosition);
    }

    // =========================
    // DRAW LABELS
    // =========================

    for (var label in labels) {
      _drawCalloutLabel(canvas, label.position, label.name, size);
    }
  }

  // ====================================================
  // DRAW POLYGON
  // ====================================================
  void drawPolygon(
    Canvas canvas,
    dynamic coordinates,
    Paint fillPaint,
    Paint borderPaint,
  ) {
    Path path = Path();

    final firstRing = coordinates[0];

    for (int i = 0; i < firstRing.length; i++) {
      final point = firstRing[i];

      // skip point lỗi
      if (point is! List || point.length < 2) continue;

      double lon = point[0].toDouble();
      double lat = point[1].toDouble();

      final p = GeoUtils.convert(lon, lat);

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  // ====================================================
  // DRAW DOT
  // ====================================================
  void _drawDot(Canvas canvas, Offset position) {
    if (position.dx.isNaN ||
        position.dy.isNaN ||
        position.dx.isInfinite ||
        position.dy.isInfinite) {
      return;
    }

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 3, paint);
  }

  // ====================================================
  // DRAW CALLOUT LABLE
  // ====================================================
  void _drawCalloutLabel(Canvas canvas, Offset anchor, String name, Size size) {
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
      // ===== LEFT =====

      lineEnd = Offset(anchor.dx - lineLength, anchor.dy);

      textOffset = Offset(
        lineEnd.dx - textPainter.width - 6,
        lineEnd.dy - textPainter.height / 2,
      );
    } else {
      // ===== RIGHT =====

      lineEnd = Offset(anchor.dx + lineLength, anchor.dy);

      textOffset = Offset(lineEnd.dx + 6, lineEnd.dy - textPainter.height / 2);
    }

    // ===== LINE =====

    canvas.drawLine(anchor, lineEnd, linePaint);

    // ===== TEXT =====

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
