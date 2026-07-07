import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/theme_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
<<<<<<< HEAD
import 'package:vietnam_geo_dashboard/providers/household_provider.dart';
import 'package:vietnam_geo_dashboard/providers/incident_provider.dart';
import 'package:vietnam_geo_dashboard/providers/statistics_provider.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
=======
import 'package:vietnam_geo_dashboard/providers/khu_pho_provider.dart';
import 'package:vietnam_geo_dashboard/providers/dai_dien_provider.dart';
>>>>>>> 1af02c0 (feat: Ward, Quarter)
import 'package:vietnam_geo_dashboard/screens/dashboard/dashboard_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_detail_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_form_screen.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_detail_screen.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_form_screen.dart';
import 'package:vietnam_geo_dashboard/screens/statistics/statistics_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProvinceProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
<<<<<<< HEAD
        ChangeNotifierProvider(create: (_) => HouseholdProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
=======
        ChangeNotifierProvider(create: (_) => KhuPhoProvider()),
        ChangeNotifierProvider(create: (_) => DaiDienProvider()),
>>>>>>> 1af02c0 (feat: Ward, Quarter)
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
          initialRoute: '/',
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case '/household-list':
        return MaterialPageRoute(
          builder: (_) => const HouseholdListScreen(),
          settings: settings,
        );
      case '/household-detail':
        final householdId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => HouseholdDetailScreen(householdId: householdId),
          settings: settings,
        );
      case '/household-create':
        return MaterialPageRoute(
          builder: (_) => const HouseholdFormScreen(),
          settings: settings,
        );
      case '/household-edit':
        // Pass the Household object via arguments
        final household = settings.arguments as Household;
        return MaterialPageRoute(
          builder: (_) => HouseholdFormScreen(household: household),
          settings: settings,
        );
      case '/incident-list':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) =>
              IncidentListScreen(householdId: args?['householdId'] as int?),
          settings: settings,
        );
      case '/incident-detail':
        final incidentId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => IncidentDetailScreen(incidentId: incidentId),
          settings: settings,
        );
      case '/incident-create':
        final householdId = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => IncidentFormScreen(householdId: householdId),
          settings: settings,
        );
      case '/incident-edit':
        // Pass the Incident object via arguments
        final incident = settings.arguments as Incident;
        return MaterialPageRoute(
          builder: (_) => IncidentFormScreen(incident: incident),
          settings: settings,
        );
      case '/statistics':
        return MaterialPageRoute(
          builder: (_) => const StatisticsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
    }
  }
}
