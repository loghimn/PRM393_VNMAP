import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vietnam_geo_dashboard/models/weather_model.dart';

class OpenMeteoService {
  const OpenMeteoService();

  /// Fetch current weather plus some hourly fields (humidity, pressure, precipitation)
  Future<WeatherModel?> fetchCurrentWeather(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=relativehumidity_2m,surface_pressure,precipitation&timezone=auto',
    );

    final resp = await http.get(uri);

    if (resp.statusCode != 200) return null;

    final map = json.decode(resp.body) as Map<String, dynamic>;

    final current = map['current_weather'] as Map<String, dynamic>?;

    if (current == null) return null;

    double? humidity;
    double? pressure;
    double? precipitation;

    try {
      final hourly = map['hourly'] as Map<String, dynamic>?;
      if (hourly != null) {
        final times = (hourly['time'] as List<dynamic>?)?.map((e) => e?.toString()).toList() ?? [];
        final currentTime = current['time'] as String?;
        final idx = currentTime != null ? times.indexOf(currentTime) : -1;

        if (idx != -1) {
          final rh = (hourly['relativehumidity_2m'] as List<dynamic>?);
          final sp = (hourly['surface_pressure'] as List<dynamic>?);
          final pp = (hourly['precipitation'] as List<dynamic>?);

          if (rh != null && idx < rh.length) humidity = (rh[idx] as num?)?.toDouble();
          if (sp != null && idx < sp.length) pressure = (sp[idx] as num?)?.toDouble();
          if (pp != null && idx < pp.length) precipitation = (pp[idx] as num?)?.toDouble();
        }
      }
    } catch (_) {
      // ignore parsing extras
    }

    return WeatherModel(
      temperature: (current['temperature'] as num?)?.toDouble(),
      windspeed: (current['windspeed'] as num?)?.toDouble(),
      winddirection: (current['winddirection'] as num?)?.toDouble(),
      weathercode: (current['weathercode'] as int?) ?? (current['weather_code'] as int?) ?? 0,
      time: current['time'] as String?,
      humidity: humidity,
      pressure: pressure,
      precipitation: precipitation,
    );
  }
}
