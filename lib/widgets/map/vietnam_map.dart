import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/weather/weather_icon.dart';

import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map_painter.dart';
import '../../services/database_service.dart';
import '../../utils/map_hit_test.dart';
import '../../utils/commune_hit_test.dart';
import '../../utils/map_transform.dart';
import '../../utils/geo_utils.dart';
import '../../utils/island_insets.dart';
import '../../utils/app_theme.dart';

class VietnamMap extends StatefulWidget {
  const VietnamMap({super.key});

  @override
  State<VietnamMap> createState() => _VietnamMapState();
}

class _VietnamMapState extends State<VietnamMap> {
  Offset mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
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

                var province = getProvinceFromPosition(
                  event.localPosition,
                  provider.provinces,
                  provider.specialZones,
                  canvasSize,
                );
                if (provider.focusedProvince != null) {
                  // Check if the mouse is inside the focused province's bounds first
                  final provinceHit = getProvinceFromPosition(
                    event.localPosition,
                    [provider.focusedProvince!],
                    [],
                    canvasSize,
                  );

                  if (provinceHit == null) {
                    province = null;
                  } else {
                    // If inside, then check for communes
                    // IMPORTANT: Include communes in transform calculation to match painter
                    final regionsForTransform = [
                      provider.focusedProvince!,
                      ...provider.focusedCommunes,
                    ];
                    final transform = calculateMapTransform(
                      canvasSize,
                      regionsForTransform,
                    );
                    final adjustedPos = Offset(
                      (event.localPosition.dx - transform.offsetX) /
                          transform.scale,
                      (event.localPosition.dy - transform.offsetY) /
                          transform.scale,
                    );
                    province =
                        getCommuneFromPositionRaw(
                          adjustedPos,
                          provider.focusedCommunes,
                          provider.focusedProvince!,
                        ) ??
                        provider.focusedProvince;
                  }
                } else {
                  province = getProvinceFromPosition(
                    event.localPosition,
                    provider.provinces,
                    provider.specialZones,
                    canvasSize,
                  );
                }

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

                  final canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  if (provider.focusedProvince != null) {
                    // IMPORTANT: Include communes in transform calculation to match painter
                    final regionsForTransform = [
                      provider.focusedProvince!,
                      ...provider.focusedCommunes,
                    ];
                    final transform = calculateMapTransform(
                      canvasSize,
                      regionsForTransform,
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

                  final province = getProvinceFromPosition(
                    details.localPosition,
                    provider.provinces,
                    provider.specialZones,
                    canvasSize,
                    onlyProvince: provider.focusedProvince,
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
                      size: Size(
                        constraints.maxWidth * 1.6,
                        constraints.maxHeight,
                      ),
                      painter: VietnamMapPainter(
                        provinces: provider.provinces,
                        specialZones: provider.specialZones,
                        mousePosition: mousePosition,
                        communes: provider.focusedCommunes,
                        focusedProvince: provider.focusedProvince,
                        selectedProvince: provider.selectedProvince,
                        selectedCommune: provider.selectedCommune,
                        viewportSize: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                      ),
                    ),

                    // Hovered province or commune weather icon overlay
                    Consumer2<ProvinceProvider, WeatherProvider>(
                      builder: (context, prov, weatherProv, child) {
                        final hovered = prov.hoveredProvince;

                        if (hovered == null) return const SizedBox();

                        // compute anchor and map transform to position icon
                        final canvasSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );

                        // compute anchor and map transform to position icon
                        // Must use same regions as painter (provinces only, not specialZones)
                        // to keep weather icon aligned with the drawn province
                        final mapRegions = prov.focusedProvince != null
                            ? [prov.focusedProvince!]
                            : prov.provinces;

                        final transform = calculateMapTransform(
                          canvasSize,
                          mapRegions,
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

                        final Offset screen;
                        if (hovered.name.contains('Hoàng Sa') &&
                            prov.focusedProvince == null) {
                          final rect = getHoangSaInsetRect(canvasSize);
                          screen = Offset(
                            rect.left - 20,
                            rect.top + rect.height / 2,
                          );
                        } else if (hovered.name.contains('Trường Sa') &&
                            prov.focusedProvince == null) {
                          final rect = getTruongSaInsetRect(canvasSize);
                          screen = Offset(
                            rect.left - 20,
                            rect.top + rect.height / 2,
                          );
                        } else {
                          screen = Offset(
                            transform.offsetX + anchor.dx * transform.scale,
                            transform.offsetY + anchor.dy * transform.scale,
                          );
                        }

                        final weather = weatherProv.getCachedWeatherForProvince(
                          hovered,
                        );

                        return Positioned(
                          left: screen.dx - 16,
                          top: screen.dy - 16,
                          child: WeatherIcon(weather: weather),
                        );
                      },
                    ),

                    // Beautiful responsive search bar overlay
                    Positioned(
                      top: 16,
                      right: 16,
                      left: isMobile
                          ? (provider.focusedProvince != null ? 150 : 16)
                          : null,
                      width: isMobile ? null : 320,
                      child: Autocomplete<SearchResult>(
                        optionsBuilder:
                            (TextEditingValue textEditingValue) async {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<SearchResult>.empty();
                              }
                              return await provider.searchLocations(
                                textEditingValue.text,
                              );
                            },
                        displayStringForOption: (SearchResult option) =>
                            option.name,
                        onSelected: (SearchResult selection) {
                          provider.selectSearchResult(selection);
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 8.0,
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.searchBg,
                              child: Container(
                                width: isMobile
                                    ? MediaQuery.of(context).size.width -
                                          (provider.focusedProvince != null
                                              ? 166
                                              : 32)
                                    : 320,
                                constraints: const BoxConstraints(
                                  maxHeight: 250,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final SearchResult option = options
                                            .elementAt(index);
                                        return ListTile(
                                          hoverColor: AppColors.hoverBg,
                                          dense: true,
                                          title: Text(
                                            option.name,
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  option.type == 'province' ||
                                                      option.type ==
                                                          'special_zone'
                                                  ? AppColors.primary
                                                        .withOpacity(0.15)
                                                  : AppColors.warning
                                                        .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                    option.type == 'province' ||
                                                        option.type ==
                                                            'special_zone'
                                                    ? AppColors.primary
                                                    : AppColors.warning,
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              option.type == 'province' ||
                                                      option.type ==
                                                          'special_zone'
                                                  ? 'Tỉnh'
                                                  : 'Xã',
                                              style: TextStyle(
                                                color:
                                                    option.type == 'province' ||
                                                        option.type ==
                                                            'special_zone'
                                                    ? AppColors.primary
                                                    : AppColors.warning,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.searchBg.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Tìm kiếm tỉnh thành, xã phường...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: AppColors.textMuted,
                                      size: 18,
                                    ),
                                    suffixIcon:
                                        ValueListenableBuilder<
                                          TextEditingValue
                                        >(
                                          valueListenable:
                                              textEditingController,
                                          builder: (context, value, child) {
                                            if (value.text.isEmpty)
                                              return const SizedBox.shrink();
                                            return GestureDetector(
                                              onTap: () {
                                                textEditingController.clear();
                                                provider.clearSelection();
                                              },
                                              child: Icon(
                                                Icons.clear,
                                                color: AppColors.textMuted,
                                                size: 16,
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                  onSubmitted: (_) => onFieldSubmitted(),
                                ),
                              );
                            },
                      ),
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
