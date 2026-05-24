import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/weather/weather_icon.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';

import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map_painter.dart';
import '../../utils/map_hit_test.dart';
import '../../utils/commune_hit_test.dart';
import '../../utils/map_transform.dart';
import '../../utils/geo_utils.dart';

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
              onHover: (event) async {
                setState(() {
                  mousePosition = event.localPosition;
                });

                final provider = context.read<ProvinceProvider>();
                final canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                final province = getProvinceFromPosition(
                  event.localPosition,
                  provider.provinces,
                  provider.specialZones,
                  canvasSize,
                );

                if (province != provider.hoveredProvince) {
                  provider.setHoveredProvince(province);

                  if (province != null) {
                    // prefetch weather for hovered province
                    final weatherProv = context.read<WeatherProvider>();
                    weatherProv.fetchWeatherForProvince(province);
                  }
                }
              },
              child: GestureDetector(
                onTapDown: (details) async {
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

                      // fetch weather for selected commune
                      final weatherProv = context.read<WeatherProvider>();
                      weatherProv.fetchWeatherForProvince(commune);

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

                    // fetch weather for selected province to show in info panel
                    final weatherProv = context.read<WeatherProvider>();
                    weatherProv.fetchWeatherForProvince(province);
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
                    try {
                      await provider.focusProvince(province);
                    } catch (e) {
                      print('Error focusing province: $e');
                    }
                  }
                },
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: VietnamMapPainter(
                        provinces: provider.provinces,
                        specialZones: provider.specialZones,
                        mousePosition: mousePosition,
                        communes: provider.focusedCommunes,
                        focusedProvince: provider.focusedProvince,
                      ),
                    ),

                    // Hovered province weather icon overlay
                    Consumer2<ProvinceProvider, WeatherProvider>(
                      builder: (context, prov, weatherProv, child) {
                        final hovered = prov.hoveredProvince;

                        if (hovered == null) return const SizedBox();

                        // compute anchor and map transform to position icon
                        final allRegions = [
                          ...prov.provinces,
                          ...prov.specialZones,
                        ];
                        final transform = calculateMapTransform(
                          Size(constraints.maxWidth, constraints.maxHeight),
                          allRegions,
                        );

                        // get anchor ring like painter
                        final geometry = hovered.geometry;
                        final type = geometry['type'];
                        final coords = geometry['coordinates'];

                        List ring = [];
                        if (type == 'Polygon') {
                          ring = coords[0];
                        } else if (type == 'MultiPolygon') {
                          ring = GeoUtils.findLargestRing(coords)[0];
                        }

                        if (ring.isEmpty) return const SizedBox();

                        final anchor = GeoUtils.getAnchorPoint(ring);

                        final screen = Offset(
                          transform.offsetX + anchor.dx * transform.scale,
                          transform.offsetY + anchor.dy * transform.scale,
                        );

                        final weather = weatherProv.getCachedWeatherForProvince(
                          hovered,
                        );

                        // fallback: try fetch by province key
                        // find weather by fetching if not present
                        // we already prefetch on hover so it should be available

                        return Positioned(
                          left: screen.dx - 16,
                          top: screen.dy - 16,
                          child: WeatherIcon(weather: weather),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
