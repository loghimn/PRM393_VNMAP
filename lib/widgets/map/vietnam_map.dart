import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map_painter.dart';
import '../../utils/map_hit_test.dart';
import '../../utils/commune_hit_test.dart';
import '../../utils/map_transform.dart';

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
                  print("CLICK MAP");
                  print("focusedProvince = ${provider.focusedProvince?.name}");

                  final canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  if (provider.focusedProvince != null) {
                    final transform = calculateMapTransform(
                      canvasSize,
                      provider.focusedProvince == null
                          ? provider.provinces
                          : [provider.focusedProvince!],
                    );

                    final adjustedClick = Offset(
                      (details.localPosition.dx - transform.offsetX) /
                          transform.scale,
                      (details.localPosition.dy - transform.offsetY) /
                          transform.scale,
                    );

                    final commune = getCommuneFromPositionRaw(
                      adjustedClick,
                      provider.focusedCommunes,
                      provider.focusedProvince!,
                    );

                    if (commune != null) {
                      provider.selectCommune(commune);
                      return;
                    }
                  }

                  // fallback: click tỉnh
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
                onDoubleTapDown: (details) async {
                  final provider = context.read<ProvinceProvider>();

                  // 🚫 CHẶN: nếu đang focus thì không cho đổi tỉnh
                  if (provider.focusedProvince != null) return;

                  final canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  final province = getProvinceFromPosition(
                    details.localPosition,
                    provider.provinces,
                    provider.specialZones,
                    canvasSize,
                    onlyProvince: provider.focusedProvince,
                  );

                  if (province != null) {
                    await provider.focusProvince(province);
                  }
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: VietnamMapPainter(
                    provinces: provider.provinces,
                    specialZones: provider.specialZones,
                    mousePosition: mousePosition,
                    communes: provider.focusedCommunes,
                    focusedProvince: provider.focusedProvince,
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
