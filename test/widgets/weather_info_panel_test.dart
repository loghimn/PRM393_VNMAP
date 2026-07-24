import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import 'package:vietnam_geo_dashboard/widgets/weather/weather_info_panel.dart';

/// Helper tạo WeatherModel đầy đủ thông tin
WeatherModel _makeWeather({
  required int weathercode,
  double? temperature,
  double? windspeed,
  double? winddirection,
  double? humidity,
  double? pressure,
  double? precipitation,
  String? time,
}) {
  return WeatherModel(
    temperature: temperature ?? 30.0,
    windspeed: windspeed ?? 5.0,
    winddirection: winddirection ?? 180.0,
    weathercode: weathercode,
    time: time ?? '2024-01-15 12:00',
    humidity: humidity ?? 65.0,
    pressure: pressure ?? 1013.0,
    precipitation: precipitation ?? 0.0,
  );
}

void main() {
  group('WeatherInfoPanel', () {
    testWidgets('returns SizedBox when weather is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: null)),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(WeatherInfoPanel), findsOneWidget);
    });

    testWidgets('displays temperature, windspeed and wind direction', (
      tester,
    ) async {
      final weather = _makeWeather(
        weathercode: 0,
        temperature: 28.5,
        windspeed: 3.2,
        winddirection: 135.0,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: weather)),
        ),
      );

      expect(find.textContaining('28.5'), findsOneWidget);
      expect(find.textContaining('3.2'), findsOneWidget);
      expect(find.textContaining('135°'), findsOneWidget);
    });

    testWidgets('displays humidity, pressure and precipitation', (
      tester,
    ) async {
      final weather = _makeWeather(
        weathercode: 1,
        humidity: 70.0,
        pressure: 1015.0,
        precipitation: 2.5,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: weather)),
        ),
      );

      expect(find.textContaining('70'), findsOneWidget);
      expect(find.textContaining('1015'), findsOneWidget);
      expect(find.textContaining('2.5'), findsOneWidget);
    });

    testWidgets('shows dash for null fields', (tester) async {
      final weather = WeatherModel(
        temperature: null,
        windspeed: null,
        winddirection: null,
        weathercode: 0,
        time: null,
        humidity: null,
        pressure: null,
        precipitation: null,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: weather)),
        ),
      );

      // Nhiệt độ null -> hiển thị dấu '-'
      expect(find.textContaining('- °C'), findsOneWidget);
      // Gió null -> dấu '-'
      expect(find.textContaining('- m/s'), findsOneWidget);
    });

    testWidgets('shows weather description for clear code 0', (tester) async {
      final weather = _makeWeather(weathercode: 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: weather)),
        ),
      );

      expect(find.text('Trời quang / Nắng'), findsOneWidget);
    });

    testWidgets('shows weather description for rain (code 61)', (tester) async {
      final weather = _makeWeather(weathercode: 61);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: weather)),
        ),
      );

      expect(find.textContaining('Mưa phùn'), findsOneWidget);
    });

    testWidgets('shows weather description for thunderstorm (code 95)', (
      tester,
    ) async {
      final weather = _makeWeather(weathercode: 96);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: weather)),
        ),
      );

      expect(find.textContaining('Mưa giông'), findsOneWidget);
    });

    testWidgets('displays time when available', (tester) async {
      final weather = _makeWeather(weathercode: 0, time: '2024-06-01 08:00');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: weather)),
        ),
      );

      expect(find.text('2024-06-01 08:00'), findsOneWidget);
    });

    testWidgets('shows header title "Thời tiết"', (tester) async {
      final weather = _makeWeather(weathercode: 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherInfoPanel(weather: weather)),
        ),
      );

      expect(find.text('Thời tiết'), findsOneWidget);
    });
  });
}
