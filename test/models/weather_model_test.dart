import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';

void main() {
  group('WeatherModel', () {
    test('should create WeatherModel with all required fields', () {
      final weather = WeatherModel(
        temperature: 30.5,
        windspeed: 15.2,
        weathercode: 0,
        time: '2025-07-23T12:00:00',
      );

      expect(weather.temperature, 30.5);
      expect(weather.windspeed, 15.2);
      expect(weather.weathercode, 0);
      expect(weather.time, '2025-07-23T12:00:00');
    });

    test('should create WeatherModel with optional fields', () {
      final weather = WeatherModel(
        temperature: 28.0,
        windspeed: 10.0,
        weathercode: 3,
        time: '2025-07-23T06:00:00',
        winddirection: 180.0,
        humidity: 75.0,
        pressure: 1013.25,
        precipitation: 0.5,
      );

      expect(weather.winddirection, 180.0);
      expect(weather.humidity, 75.0);
      expect(weather.pressure, 1013.25);
      expect(weather.precipitation, 0.5);
    });

    test('should allow null optional fields', () {
      final weather = WeatherModel(
        temperature: 25.0,
        windspeed: 5.0,
        weathercode: 1,
        time: '2025-07-23T00:00:00',
      );

      expect(weather.winddirection, isNull);
      expect(weather.humidity, isNull);
      expect(weather.pressure, isNull);
      expect(weather.precipitation, isNull);
    });

    test('should allow null temperature and windspeed', () {
      final weather = WeatherModel(
        temperature: null,
        windspeed: null,
        weathercode: 2,
        time: null,
      );

      expect(weather.temperature, isNull);
      expect(weather.windspeed, isNull);
      expect(weather.time, isNull);
    });

    test('should handle weathercode for clear sky', () {
      final weather = WeatherModel(
        temperature: 35.0,
        windspeed: 0.0,
        weathercode: 0,
        time: '2025-07-23T12:00:00',
      );

      expect(weather.weathercode, 0);
    });

    test('should handle weathercode for rain', () {
      final weather = WeatherModel(
        temperature: 20.0,
        windspeed: 12.0,
        weathercode: 61,
        time: '2025-07-23T12:00:00',
      );

      expect(weather.weathercode, 61);
    });

    test('should handle extreme values', () {
      final weather = WeatherModel(
        temperature: -10.0,
        windspeed: 100.0,
        weathercode: 95,
        time: '2025-07-23T12:00:00',
        winddirection: 360.0,
        humidity: 100.0,
        pressure: 1100.0,
        precipitation: 50.0,
      );

      expect(weather.temperature, -10.0);
      expect(weather.windspeed, 100.0);
      expect(weather.weathercode, 95);
    });
  });
}
