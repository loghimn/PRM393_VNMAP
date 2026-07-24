import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/providers/auth_provider.dart';
import 'package:vietnam_geo_dashboard/models/user_model.dart';
import 'package:vietnam_geo_dashboard/providers/household_provider.dart';
import 'package:vietnam_geo_dashboard/providers/incident_provider.dart';
import 'package:vietnam_geo_dashboard/providers/household_request_provider.dart';
import 'package:vietnam_geo_dashboard/providers/notification_provider.dart';
import 'package:vietnam_geo_dashboard/providers/statistics_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/providers/theme_provider.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/khu_pho_provider.dart';
import 'package:vietnam_geo_dashboard/providers/dai_dien_provider.dart';
import 'package:vietnam_geo_dashboard/providers/dia_diem_lich_su_provider.dart';

import 'mock_providers.dart';

/// Overrides cho các mock providers trong test.
class ProviderOverrides {
  final AuthProvider? auth;
  final ThemeProvider? theme;
  final HouseholdProvider? household;
  final IncidentProvider? incident;
  final KhuPhoProvider? khuPho;
  final DaiDienProvider? daiDien;
  final DiaDiemLichSuProvider? diaDiemLichSu;
  final ProvinceProvider? province;
  final StatisticsProvider? statistics;
  final NotificationProvider? notification;
  final WeatherProvider? weather;
  final HouseholdRequestProvider? householdRequest;

  const ProviderOverrides({
    this.auth,
    this.theme,
    this.household,
    this.incident,
    this.khuPho,
    this.daiDien,
    this.diaDiemLichSu,
    this.province,
    this.statistics,
    this.notification,
    this.weather,
    this.householdRequest,
  });
}

/// Tạo [MaterialApp] wrap với các mock providers cho testing.
///
/// [child] là screen/widget cần test.
/// [overrides] chứa các mock provider sẽ override provider mặc định.
/// [routes] là các named routes cho navigation testing.
Widget createTestApp({
  required Widget child,
  ProviderOverrides? overrides,
  Map<String, WidgetBuilder>? routes,
  List<NavigatorObserver>? navigatorObservers,
}) {
  // Các provider mặc định (mock)
  final defaultProviders = [
    ChangeNotifierProvider<AuthProvider>.value(
      value: overrides?.auth ?? FakeAuthProvider(),
    ),
    ChangeNotifierProvider<ThemeProvider>.value(
      value: overrides?.theme ?? FakeThemeProvider(),
    ),
    ChangeNotifierProvider<HouseholdProvider>.value(
      value: overrides?.household ?? FakeHouseholdProvider(),
    ),
    ChangeNotifierProvider<IncidentProvider>.value(
      value: overrides?.incident ?? FakeIncidentProvider(),
    ),
    ChangeNotifierProvider<KhuPhoProvider>.value(
      value: overrides?.khuPho ?? FakeKhuPhoProvider(),
    ),
    ChangeNotifierProvider<DaiDienProvider>.value(
      value: overrides?.daiDien ?? FakeDaiDienProvider(),
    ),
    ChangeNotifierProvider<DiaDiemLichSuProvider>.value(
      value: overrides?.diaDiemLichSu ?? FakeDiaDiemLichSuProvider(),
    ),
    ChangeNotifierProvider<ProvinceProvider>.value(
      value: overrides?.province ?? FakeProvinceProvider(),
    ),
    ChangeNotifierProvider<StatisticsProvider>.value(
      value: overrides?.statistics ?? FakeStatisticsProvider(),
    ),
    ChangeNotifierProvider<NotificationProvider>.value(
      value: overrides?.notification ?? FakeNotificationProvider(),
    ),
    ChangeNotifierProvider<WeatherProvider>.value(
      value: overrides?.weather ?? FakeWeatherProvider(),
    ),
    ChangeNotifierProvider<HouseholdRequestProvider>.value(
      value: overrides?.householdRequest ?? FakeHouseholdRequestProvider(),
    ),
  ];

  return MultiProvider(
    providers: defaultProviders,
    child: MaterialApp(
      navigatorObservers: navigatorObservers ?? [],
      routes: {
        '/': (_) => child,
        '/login': (_) => const _PlaceholderScreen(label: 'LoginScreen'),
        '/register': (_) => const _PlaceholderScreen(label: 'RegisterScreen'),
        '/profile': (_) => const _PlaceholderScreen(label: 'ProfileScreen'),
        if (routes != null) ...routes,
      },
    ),
  );
}

/// Widget placeholder cho navigation testing
class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label)),
    );
  }
}

/// Helper để pumpWidget với test app
extension PumpTestApp on WidgetTester {
  Future<void> pumpScreen(
    Widget screen, {
    ProviderOverrides? overrides,
    Map<String, WidgetBuilder>? routes,
    List<NavigatorObserver>? navigatorObservers,
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    await pumpWidget(
      createTestApp(
        child: screen,
        overrides: overrides,
        routes: routes,
        navigatorObservers: navigatorObservers,
      ),
    );
    await pump(duration);
  }
}
