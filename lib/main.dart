import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/theme_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/screens/dashboard/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProvinceProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
