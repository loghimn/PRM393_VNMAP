import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import 'package:vietnam_geo_dashboard/services/open_meteo_service.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/utils/geo_utils.dart';

class WeatherProvider extends ChangeNotifier {
  final OpenMeteoService _service = const OpenMeteoService();

  final Map<String, WeatherModel?> _cache = {};

  WeatherModel? getWeatherForKey(String key) => _cache[key];

  Future<WeatherModel?> fetchWeatherForCoords(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';

    if (_cache.containsKey(key)) return _cache[key];

    final w = await _service.fetchCurrentWeather(lat, lon);

    _cache[key] = w;

    notifyListeners();

    return w;
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
