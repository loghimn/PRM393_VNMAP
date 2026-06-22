import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import '../../utils/app_theme.dart';

// Custom weather icon mapping using Material Icons that don't look like generic AI output
IconData _iconForCode(int code) {
  if (code == 0) return Icons.wb_sunny; // clear / sunny
  if (code == 1 || code == 2 || code == 3) return Icons.wb_cloudy; // cloudy
  if (code >= 45 && code <= 48) return Icons.foggy; // fog
  if (code >= 51 && code <= 55) return Icons.water_drop; // drizzle
  if (code >= 56 && code <= 57) return Icons.ac_unit; // freezing drizzle
  if (code >= 61 && code <= 67) return Icons.umbrella; // rain
  if (code >= 71 && code <= 77) return Icons.ac_unit; // snow
  if (code >= 80 && code <= 82) return Icons.thunderstorm; // rain showers
  if (code >= 85 && code <= 86) return Icons.snowing; // snow showers
  if (code >= 95) return Icons.flash_on; // thunderstorm
  return Icons.cloud; // default
}

Color _colorForCode(int code) {
  if (code == 0) return AppColors.weatherSunny;
  if (code >= 1 && code <= 3) return AppColors.weatherCloud;
  if (code >= 45 && code <= 48) return AppColors.weatherFog;
  if (code >= 51 && code <= 67) return AppColors.weatherRain;
  if (code >= 71 && code <= 77) return AppColors.weatherSnow;
  if (code >= 80 && code <= 82) return AppColors.weatherRain;
  if (code >= 95) return AppColors.weatherStorm;
  return AppColors.weatherCloud;
}

class WeatherIcon extends StatelessWidget {
  final WeatherModel? weather;

  const WeatherIcon({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    if (weather == null) return const SizedBox();

    final code = weather!.weathercode;
    final color = _colorForCode(code);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.85), color.withOpacity(0.4)],
          center: const Alignment(-0.3, -0.3),
          focal: Alignment.center,
          focalRadius: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(_iconForCode(code), color: AppColors.textPrimary, size: 20),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${weather!.temperature?.toStringAsFixed(0) ?? '-'}°',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
