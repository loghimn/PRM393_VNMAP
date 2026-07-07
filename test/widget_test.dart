import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/main.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with required providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProvinceProvider()),
          ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that our app renders the main dashboard title.
    expect(find.text('Vietnam Analytics Dashboard'), findsOneWidget);
  });
}
