class WeatherModel {
  final double? temperature;
  final double? windspeed;
  final double? winddirection;
  final int weathercode;
  final String? time;

  // extra
  final double? humidity; // %
  final double? pressure; // hPa
  final double? precipitation; // mm

  WeatherModel({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
    required this.time,
    this.winddirection,
    this.humidity,
    this.pressure,
    this.precipitation,
  });
}
