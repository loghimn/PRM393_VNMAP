import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import 'package:vietnam_geo_dashboard/widgets/weather/weather_icon.dart';

/// Helper tạo WeatherModel với weather code và temperature
WeatherModel _makeWeather({required int weathercode, double? temperature}) {
  return WeatherModel(
    temperature: temperature ?? 30.0,
    windspeed: null,
    weathercode: weathercode,
    time: null,
  );
}

void main() {
  group('WeatherIcon', () {
    testWidgets('returns SizedBox when weather is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WeatherIcon(weather: null))),
      );

      // WeatherIcon when null returns SizedBox => không có icon nào
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(WeatherIcon), findsOneWidget);
    });

    testWidgets('shows wb_sunny icon for clear weather (code 0)', (
      tester,
    ) async {
      final weather = _makeWeather(weathercode: 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('shows wb_cloudy icon for cloudy weather (codes 1-3)', (
      tester,
    ) async {
      // code 2 (mây rải rác)
      final weather = _makeWeather(weathercode: 2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.wb_cloudy), findsOneWidget);
    });

    testWidgets('shows water_drop icon for drizzle (codes 51-55)', (
      tester,
    ) async {
      final weather = _makeWeather(weathercode: 53);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('shows thunderstorm icon for rain showers (codes 80-82)', (
      tester,
    ) async {
      final weather = _makeWeather(weathercode: 80);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.thunderstorm), findsOneWidget);
    });

    testWidgets('shows flash_on icon for thunderstorm (code 95+)', (
      tester,
    ) async {
      final weather = _makeWeather(weathercode: 96);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('shows temperature badge', (tester) async {
      final weather = _makeWeather(weathercode: 0, temperature: 35.5);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      // Kiểm tra nhiệt độ hiển thị (làm tròn)
      expect(find.textContaining('36°'), findsOneWidget);
    });

    testWidgets('renders with null temperature without crashing', (
      tester,
    ) async {
      final weather = _makeWeather(weathercode: 0, temperature: null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      // Vẫn render icon sunny dù temperature null
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('shows umbrella icon for rain (codes 61-67)', (tester) async {
      final weather = _makeWeather(weathercode: 63);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.umbrella), findsOneWidget);
    });

    testWidgets('shows ac_unit icon for snow (codes 71-77)', (tester) async {
      final weather = _makeWeather(weathercode: 73);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    });

    testWidgets('shows foggy icon for fog (codes 45-48)', (tester) async {
      final weather = _makeWeather(weathercode: 45);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.foggy), findsOneWidget);
    });

    testWidgets('shows default cloud icon for unknown code', (tester) async {
      // code = 10 không match bất kỳ condition nào (nằm giữa 3 và 45)
      final weather = _makeWeather(weathercode: 10);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeatherIcon(weather: weather)),
        ),
      );

      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });
  });
}
