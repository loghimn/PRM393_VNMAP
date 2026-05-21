import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map_painter.dart';
import '../../utils/map_hit_test.dart';

class VietnamMap extends StatefulWidget {
  const VietnamMap({super.key});

  @override
  State<VietnamMap> createState() => _VietnamMapState();
}

class _VietnamMapState extends State<VietnamMap> {
  final TransformationController _controller = TransformationController();

  Offset mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProvinceProvider>(
      builder: (context, provider, child) {
        if (provider.provinces.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return MouseRegion(
          onHover: (event) {
            // matrix hiện tại của InteractiveViewer
            final matrix = _controller.value;

            // đảo ngược matrix
            final inverseMatrix = Matrix4.inverted(matrix);

            // convert tọa độ chuột về tọa độ thật của canvas
            final transformed = MatrixUtils.transformPoint(
              inverseMatrix,
              event.localPosition,
            );

            setState(() {
              mousePosition = transformed;
            });
          },

          child: InteractiveViewer(
            transformationController: _controller,

            boundaryMargin: const EdgeInsets.all(500),

            minScale: 0.5,
            maxScale: 5,

            child: GestureDetector(
              onTapDown: (details) {
                final provider = context.read<ProvinceProvider>();

                final province = getProvinceFromPosition(
                  details.localPosition,
                  provider.provinces,
                );

                if (province != null) {
                  provider.selectProvince(province);
                }
              },

              child: MouseRegion(
                onHover: (event) {
                  setState(() {
                    mousePosition = event.localPosition;
                  });
                },

                child: CustomPaint(
                  size: const Size(1200, 2000),

                  painter: VietnamMapPainter(
                    provinces: provider.provinces,
                    mousePosition: mousePosition,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
