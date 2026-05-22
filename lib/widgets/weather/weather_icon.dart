import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';

IconData _iconForCode(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code == 1 || code == 2 || code == 3) return Icons.cloud;
  if (code >= 45 && code <= 48) return Icons.blur_on;
  if (code >= 51 && code <= 67) return Icons.grain;
  if (code >= 71 && code <= 77) return Icons.ac_unit;
  if (code >= 80 && code <= 82) return Icons.grain;
  if (code >= 95) return Icons.flash_on;
  return Icons.cloud_queue;
}

Color _colorForCode(int code) {
  if (code == 0) return Colors.orangeAccent;
  if (code >= 1 && code <= 3) return Colors.blueGrey;
  if (code >= 45 && code <= 48) return Colors.blue.shade200;
  if (code >= 51 && code <= 67) return Colors.indigoAccent;
  if (code >= 71 && code <= 77) return Colors.cyan;
  if (code >= 80 && code <= 82) return Colors.lightBlue;
  if (code >= 95) return Colors.deepPurpleAccent;
  return Colors.grey;
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
          colors: [color.withOpacity(0.95), color.withOpacity(0.6)],
          center: Alignment(-0.2, -0.2),
          focal: Alignment.center,
          focalRadius: 0.8,
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(_iconForCode(code), color: Colors.white, size: 20),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${weather!.temperature?.toStringAsFixed(0) ?? '-'}°',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}
