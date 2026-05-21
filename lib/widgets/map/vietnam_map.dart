import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map_painter.dart';
import '../../utils/map_hit_test.dart';

class VietnamMap extends StatefulWidget {
  const VietnamMap({super.key});

  @override
  State<VietnamMap> createState() => _VietnamMapState();
}

class _VietnamMapState extends State<VietnamMap> {
  Offset mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProvinceProvider>(
      builder: (context, provider, child) {
        if (provider.provinces.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return MouseRegion(
              onHover: (event) {
                setState(() {
                  mousePosition = event.localPosition;
                });
              },
              child: GestureDetector(
                onTapDown: (details) {
                  final provider = context.read<ProvinceProvider>();

                  final canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  final province = getProvinceFromPosition(
                    details.localPosition,
                    provider.provinces,
                    provider.specialZones,
                    canvasSize,
                  );

                  if (province != null) {
                    provider.selectProvince(province);
                  }
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: VietnamMapPainter(
                    provinces: provider.provinces,
                    specialZones: provider.specialZones,
                    mousePosition: mousePosition,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
