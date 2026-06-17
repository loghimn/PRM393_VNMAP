import 'package:flutter/material.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';

String _describeWeatherCode(int code) {
  if (code == 0) return 'Trời quang / Nắng';
  if (code == 1) return 'Ít mây';
  if (code == 2) return 'Mây rải rác';
  if (code == 3) return 'Nhiều mây / U ám';
  if (code >= 45 && code <= 48) return 'Sương mù';
  if (code >= 51 && code <= 67) return 'Mưa phùn / Mưa';
  if (code >= 71 && code <= 77) return 'Tuyết / Băng';
  if (code >= 80 && code <= 82) return 'Mưa rào';
  if (code >= 95) return 'Mưa giông';
  return 'Không xác định';
}

class WeatherInfoPanel extends StatelessWidget {
  final WeatherModel? weather;

  const WeatherInfoPanel({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff0b1220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thời tiết', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              if (weather!.time != null)
                Text(weather!.time!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${weather!.temperature?.toStringAsFixed(1) ?? '-'} °C', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_describeWeatherCode(weather!.weathercode), style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Gió: ${weather!.windspeed?.toStringAsFixed(1) ?? '-'} m/s', style: const TextStyle(color: Colors.white70)),
                  Text('Hướng: ${weather!.winddirection?.toStringAsFixed(0) ?? '-'}°', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _smallInfo('Độ ẩm', weather!.humidity != null ? '${weather!.humidity!.toStringAsFixed(0)} %' : '-')),
              Expanded(child: _smallInfo('Áp suất', weather!.pressure != null ? '${weather!.pressure!.toStringAsFixed(0)} hPa' : '-')),
              Expanded(child: _smallInfo('Lượng mưa', weather!.precipitation != null ? '${weather!.precipitation!.toStringAsFixed(1)} mm' : '-')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
