

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
    final props = json['properties'];

    return ProvinceModel(
      name: props['ten'] ?? '',

      ma: props['ma'],

      areaKm2: (props['area_km2'] as num?)?.toDouble(),

      population: (props['population'] as num?)?.toInt(),

      density: (props['density'] as num?)?.toDouble(),

      capital: props['capital'],

      decree: props['decree'],

      macroRegion: props['macro_region'],

      type: props['type'],

      predecessors: props['predecessors'],

      parentMa: props['parent_ma'],

      parentTen: props['parent_ten'],

      geometry: json['geometry'],

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
