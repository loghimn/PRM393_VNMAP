import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:vietnam_geo_dashboard/providers/auth_provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/theme_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/providers/household_provider.dart';
import 'package:vietnam_geo_dashboard/providers/incident_provider.dart';
import 'package:vietnam_geo_dashboard/providers/statistics_provider.dart';
import 'package:vietnam_geo_dashboard/providers/dia_diem_lich_su_provider.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'package:vietnam_geo_dashboard/providers/khu_pho_provider.dart';
import 'package:vietnam_geo_dashboard/providers/dai_dien_provider.dart';
import 'package:vietnam_geo_dashboard/providers/household_request_provider.dart';
import 'package:vietnam_geo_dashboard/providers/notification_provider.dart';
import 'package:vietnam_geo_dashboard/screens/dashboard/dashboard_screen.dart';
import 'package:vietnam_geo_dashboard/screens/auth/login_screen.dart';
import 'package:vietnam_geo_dashboard/screens/auth/profile_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_detail_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_form_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_request_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_request_form_screen.dart';
import 'package:vietnam_geo_dashboard/screens/household/household_request_detail_screen.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_list_screen.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_detail_screen.dart';
import 'package:vietnam_geo_dashboard/screens/incident/incident_form_screen.dart';
import 'package:vietnam_geo_dashboard/screens/statistics/statistics_screen.dart';
import 'package:vietnam_geo_dashboard/screens/gis_map_screen.dart';
import 'package:vietnam_geo_dashboard/screens/auth/register_screen.dart';
import 'package:vietnam_geo_dashboard/screens/auth/user_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProvinceProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => HouseholdProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => DiaDiemLichSuProvider()),
        ChangeNotifierProvider(create: (_) => KhuPhoProvider()),
        ChangeNotifierProvider(create: (_) => DaiDienProvider()),
        ChangeNotifierProvider(create: (_) => HouseholdRequestProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
          initialRoute: '/splash',
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(
          builder: (_) => const _SplashScreen(),
          settings: settings,
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case '/user-management':
        return MaterialPageRoute(
          builder: (_) => const UserManagementScreen(),
          settings: settings,
        );
      case '/':
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
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
      case '/household-request-list':
        return MaterialPageRoute(
          builder: (_) => const HouseholdRequestListScreen(),
          settings: settings,
        );
      case '/household-request-create':
        return MaterialPageRoute(
          builder: (_) => const HouseholdRequestFormScreen(),
          settings: settings,
        );
      case '/household-request-detail':
        final requestId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => HouseholdRequestDetailScreen(requestId: requestId),
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
      case '/gis-map':
        return MaterialPageRoute(
          builder: (_) => const GisMapScreen(),
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

/// Splash screen that checks authentication and redirects accordingly
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Đang tải...'),
          ],
        ),
      ),
    );
  }
}
