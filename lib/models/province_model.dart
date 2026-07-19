import 'dart:convert';

class ProvinceModel {
  final String name;

  final String? ma;
  final double? areaKm2;
  final int? population;
  final double? density;
  final String? capital;
  final String? decree;
  final String? macroRegion;

  final String? type;
  final String? predecessors;
  final String? parentMa;
  final String? parentTen;

  final Map<String, dynamic> geometry;
  final Map<String, dynamic> properties;

  ProvinceModel({
    required this.name,
    required this.geometry,
    required this.properties,

    this.ma,
    this.areaKm2,
    this.population,
    this.density,
    this.capital,
    this.decree,
    this.macroRegion,
    this.type,
    this.predecessors,
    this.parentMa,
    this.parentTen,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    final props = Map<String, dynamic>.from(
      json['properties'] ?? <String, dynamic>{},
    );

    final geometryData = json['geometry'] ?? json['geometry_json'];
    final geometry = geometryData is Map<String, dynamic>
        ? Map<String, dynamic>.from(geometryData)
        : geometryData is String
        ? Map<String, dynamic>.from(jsonDecode(geometryData))
        : <String, dynamic>{};

    return ProvinceModel(
      name: json['name'] ?? props['ten'] ?? '',
      ma: json['code']?.toString() ?? props['ma']?.toString(),
      areaKm2: (json['area_km2'] as num?)?.toDouble(),
      population: (json['population'] as num?)?.toInt(),
      density: (json['density'] as num?)?.toDouble(),
      capital: json['capital'] ?? props['capital'],
      decree: json['decree'] ?? props['decree'],
      macroRegion: json['macro_region'] ?? props['macro_region'],
      type: json['type'] ?? props['type'],
      predecessors: json['predecessors'] ?? props['predecessors'],
      parentMa: json['parent_ma'] ?? props['parent_ma'],
      parentTen: json['parent_ten'] ?? props['parent_ten'],
      geometry: geometry,
      properties: props,
    );
  }

  String get macroRegionVietnamese {
    final region = macroRegion;
    if (region == null) return '-';
    switch (region.trim().toLowerCase()) {
      case 'red_river_delta':
        return 'Đồng bằng sông Hồng';
      case 'northern_midlands':
        return 'Trung du và miền núi phía Bắc';
      case 'north_central_coast':
        return 'Bắc Trung Bộ';
      case 'central_coast':
        return 'Trung Bộ';
      case 'south_central_coast':
        return 'Nam Trung Bộ';
      case 'central_highlands':
        return 'Tây Nguyên';
      case 'south_east':
      case 'southeast':
        return 'Đông Nam Bộ';
      case 'mekong_delta':
        return 'Đồng bằng sông Cửu Long';
      default:
        return region
            .replaceAll('_', ' ')
            .split(' ')
            .map((part) {
              if (part.isEmpty) return part;
              return part[0].toUpperCase() + part.substring(1);
            })
            .join(' ');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProvinceModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          ma == other.ma;

  @override
  int get hashCode => name.hashCode ^ ma.hashCode;
}
