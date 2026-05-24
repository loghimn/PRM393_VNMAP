import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import 'package:vietnam_geo_dashboard/services/open_meteo_service.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/utils/geo_utils.dart';

class RegionWeatherSummary {
  final String key;
  final String label;
  final WeatherModel? weather;

  RegionWeatherSummary({
    required this.key,
    required this.label,
    required this.weather,
  });

  String get temperatureLabel {
    if (weather?.temperature == null) return '-';
    return '${weather!.temperature!.toStringAsFixed(1)}°C';
  }

  String get status {
    if (weather == null) return 'Không có dữ liệu';
    if (weather!.precipitation != null && weather!.precipitation! > 0.1) {
      return 'Mưa';
    }
    final code = weather!.weathercode;
    if (code == 0) return 'Nắng';
    if (code == 1 || code == 2 || code == 3) return 'Trời nhiều mây';
    if (code >= 45 && code <= 67) return 'Sương/mưa nhẹ';
    if (code >= 71 && code <= 77) return 'Tuyết/đông lạnh';
    if (code >= 80 && code <= 82) return 'Mưa rào';
    if (code >= 95) return 'Giông tố';
    return 'Ám mây';
  }

  String get description {
    return '$label: $status, ${temperatureLabel.toLowerCase()}';
  }
}

class WeatherProvider extends ChangeNotifier {
  final OpenMeteoService _service = const OpenMeteoService();

  final Map<String, WeatherModel?> _cache = {};
  WeatherModel? nationalWeatherSummary;
  String nationalTextSummary = '';
  final Map<String, RegionWeatherSummary> regionalSummaries = {};

  WeatherModel? getWeatherForKey(String key) => _cache[key];

  Future<WeatherModel?> fetchWeatherForCoords(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';

    if (_cache.containsKey(key)) return _cache[key];

    final w = await _service.fetchCurrentWeather(lat, lon);

    _cache[key] = w;
    notifyListeners();
    return w;
  }

  Future<void> loadRegionalSummaries(List<ProvinceModel> provinces) async {
    final groups = <String, List<ProvinceModel>>{};

    for (final province in provinces) {
      final regionKey = province.macroRegion?.toString().trim();
      if (regionKey == null || regionKey.isEmpty) continue;
      groups.putIfAbsent(regionKey, () => []).add(province);
    }

    if (groups.isEmpty) {
      await loadNationalWeatherSummary(provinces);
      return;
    }

    regionalSummaries.clear();

    for (final entry in groups.entries) {
      final center = _calculateRegionCenter(entry.value);
      if (center == null) continue;
      final weather = await fetchWeatherForCoords(center.dy, center.dx);
      regionalSummaries[entry.key] = RegionWeatherSummary(
        key: entry.key,
        label: _regionLabel(entry.key),
        weather: weather,
      );
    }

    nationalTextSummary = _buildNationalTextSummary(
      regionalSummaries.values.toList(),
    );
    nationalWeatherSummary = await _loadNationalCenterWeather(provinces);
    notifyListeners();
  }

  Future<void> loadNationalWeatherSummary(List<ProvinceModel> provinces) async {
    nationalWeatherSummary = await _loadNationalCenterWeather(provinces);
    nationalTextSummary = _buildNationalTextSummary(
      regionalSummaries.values.toList(),
    );
    notifyListeners();
  }

  Future<WeatherModel?> _loadNationalCenterWeather(
    List<ProvinceModel> provinces,
  ) async {
    final center = _calculateRegionCenter(provinces);
    if (center == null) return null;
    return fetchWeatherForCoords(center.dy, center.dx);
  }

  Offset? _calculateRegionCenter(List<ProvinceModel> provinces) {
    final centers = <Offset>[];

    for (final province in provinces) {
      final centroid = _provinceCentroid(province);
      if (centroid != null) centers.add(centroid);
    }

    if (centers.isEmpty) return null;

    double sumLon = 0;
    double sumLat = 0;

    for (final center in centers) {
      sumLon += center.dx;
      sumLat += center.dy;
    }

    return Offset(sumLon / centers.length, sumLat / centers.length);
  }

  Offset? _provinceCentroid(ProvinceModel province) {
    final geometry = province.geometry;
    final type = geometry['type'];
    final coords = geometry['coordinates'];

    List ring = [];
    if (type == 'Polygon') {
      ring = coords[0];
    } else if (type == 'MultiPolygon') {
      ring = GeoUtils.findLargestRing(coords)[0];
    }

    if (ring.isEmpty) return null;

    double sumLon = 0;
    double sumLat = 0;
    int count = 0;

    for (final pt in ring) {
      if (pt is! List || pt.length < 2) continue;
      sumLon += (pt[0] as num).toDouble();
      sumLat += (pt[1] as num).toDouble();
      count++;
    }
    if (count == 0) return null;
    return Offset(sumLon / count, sumLat / count);
  }

  String _buildNationalTextSummary(List<RegionWeatherSummary> regions) {
    if (regions.isEmpty) return 'Đang tải thông tin thời tiết vùng...';

    final sorted = regions.toList()..sort((a, b) => a.label.compareTo(b.label));

    final parts = sorted.map((region) {
      final status = region.status.toLowerCase();
      return '${region.label}: $status, ${region.temperatureLabel}';
    }).toList();

    return parts.join(' · ');
  }

  String _regionLabel(String key) {
    switch (key) {
      case 'red_river_delta':
        return 'Đồng bằng sông Hồng';
      case 'northern_midlands':
        return 'Bắc Trung Bộ & Tây Bắc';
      case 'north_central_coast':
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
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((part) {
              if (part.isEmpty) return part;
              return part[0].toUpperCase() + part.substring(1);
            })
            .join(' ');
    }
  }

  WeatherModel? getCachedWeatherForProvince(ProvinceModel province) {
    try {
      final geometry = province.geometry;
      final type = geometry['type'];
      final coords = geometry['coordinates'];

      List ring = [];

      if (type == 'Polygon') {
        ring = coords[0];
      } else if (type == 'MultiPolygon') {
        ring = GeoUtils.findLargestRing(coords)[0];
      }

      if (ring.isEmpty) return null;

      double sumLon = 0;
      double sumLat = 0;
      int count = 0;

      for (final pt in ring) {
        if (pt is! List || pt.length < 2) continue;
        final lon = (pt[0] as num).toDouble();
        final lat = (pt[1] as num).toDouble();
        sumLon += lon;
        sumLat += lat;
        count++;
      }

      if (count == 0) return null;

      final avgLat = sumLat / count;
      final avgLon = sumLon / count;

      final key = '${avgLat.toStringAsFixed(4)},${avgLon.toStringAsFixed(4)}';

      return _cache[key];
    } catch (e) {
      return null;
    }
  }

  Future<WeatherModel?> fetchWeatherForProvince(ProvinceModel province) async {
    try {
      final geometry = province.geometry;
      final type = geometry['type'];
      final coords = geometry['coordinates'];

      List ring = [];

      if (type == 'Polygon') {
        ring = coords[0];
      } else if (type == 'MultiPolygon') {
        ring = GeoUtils.findLargestRing(coords)[0];
      }

      if (ring.isEmpty) return null;

      double sumLon = 0;
      double sumLat = 0;
      int count = 0;

      for (final pt in ring) {
        if (pt is! List || pt.length < 2) continue;
        final lon = (pt[0] as num).toDouble();
        final lat = (pt[1] as num).toDouble();
        sumLon += lon;
        sumLat += lat;
        count++;
      }

      if (count == 0) return null;

      final avgLat = sumLat / count;
      final avgLon = sumLon / count;

      return fetchWeatherForCoords(avgLat, avgLon);
    } catch (e) {
      return null;
    }
  }
}
