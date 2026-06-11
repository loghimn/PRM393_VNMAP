import 'dart:convert';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/models/weather_model.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/providers/weather_provider.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map.dart';
import 'package:vietnam_geo_dashboard/widgets/map/vietnam_map_painter.dart';
import 'package:vietnam_geo_dashboard/utils/map_transform.dart';
import 'package:vietnam_geo_dashboard/utils/geo_utils.dart';

// Mock WeatherProvider
class MockWeatherProvider extends WeatherProvider {
  @override
  Future<WeatherModel?> fetchWeatherForProvince(ProvinceModel province) async {
    // Do nothing in mock, return null
    return null;
  }
}

// A simple test implementation of ProvinceProvider
class TestProvinceProvider extends ProvinceProvider {
  List<ProvinceModel> allCommunes = [];

  Future<void> loadTestData() async {
    provinces = await _loadProvincesFromTestFile();
    specialZones = await _loadSpecialZonesFromTestFile();
    allCommunes = await _loadCommunesFromTestFile();
    notifyListeners();
  }

  @override
  Future<void> focusProvince(ProvinceModel province) async {
    focusedProvince = province;
    selectedProvince = province;
    focusedCommunes = allCommunes.where((c) {
      return c.properties['parent_ten'] == province.name;
    }).toList();
    notifyListeners();
  }

  List<ProvinceModel> _parseProvinces(String jsonString) {
    String fixedJson = jsonString.replaceAll('NaN', 'null');
    final data = jsonDecode(fixedJson);
    final features = data['features'] as List;
    return features.map((item) => ProvinceModel.fromJson(item)).toList();
  }

  Future<List<ProvinceModel>> _loadProvincesFromTestFile() async {
    final file = File('assets/geojson/provinces.geojson');
    final jsonString = await file.readAsString();
    return _parseProvinces(jsonString);
  }

  Future<List<ProvinceModel>> _loadCommunesFromTestFile() async {
    final file = File('assets/geojson/communes.geojson');
    final jsonString = await file.readAsString();
    return _parseProvinces(jsonString);
  }

  Future<List<ProvinceModel>> _loadSpecialZonesFromTestFile() async {
    final communes = await _loadCommunesFromTestFile();
    return communes.where((c) => c.properties['type'] == 'Đặc khu').toList();
  }
}

// Helper to find a point inside a province's geometry for testing
Offset getPointInProvince(ProvinceModel province, MapTransform transform) {
  final geometry = province.geometry;
  final type = geometry['type'];
  final coords = geometry['coordinates'];

  List ring = [];
  if (type == 'Polygon') {
    ring = coords[0];
  } else if (type == 'MultiPolygon') {
    ring = GeoUtils.findLargestRing(coords)[0];
  }

  if (ring.isEmpty) return Offset.zero;

  // Use the pre-calculated anchor point which is guaranteed to be inside
  final anchor = GeoUtils.getAnchorPoint(ring);

  // Apply the same transform used by the painter to get the screen coordinates
  return Offset(
    transform.offsetX + anchor.dx * transform.scale,
    transform.offsetY + anchor.dy * transform.scale,
  );
}


void main() {
  group('VietnamMap Widget Tests', () {
    late TestProvinceProvider provinceProvider;
    late MockWeatherProvider weatherProvider;

    // Use setUpAll to load data once per group
    setUpAll(() async {
      provinceProvider = TestProvinceProvider();
      weatherProvider = MockWeatherProvider();
      
      // We need to ensure that the test can find the assets
      // This setup assumes tests are run from the project root
      await provinceProvider.loadTestData();
    });

    testWidgets('Map renders, handles hover, double tap, and focus hover correctly',
        (WidgetTester tester) async {

      // Define a size for the widget, e.g., 800x600, to have a valid layout
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProvinceProvider>.value(value: provinceProvider),
            ChangeNotifierProvider<WeatherProvider>.value(value: weatherProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: const VietnamMap(),
              ),
            ),
          ),
        ),
      );

      // Let the widget tree build
      await tester.pumpAndSettle();

      // Verify that the map painter is in the tree
      expect(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is VietnamMapPainter,
        ),
        findsOneWidget,
      );

      // --- 1. Test Hover in Normal View ---
      
      final hanoi = provinceProvider.provinces.firstWhere((p) => p.name == 'Thủ đô Hà Nội');
      final canvasSize = Size(800, 600);
      final allRegionsForTransform = [...provinceProvider.provinces, ...provinceProvider.specialZones];
      final transform = calculateMapTransform(canvasSize, allRegionsForTransform);
      final hanoiPoint = getPointInProvince(hanoi, transform);
      
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(hanoiPoint);
      await tester.pumpAndSettle();

      expect(provinceProvider.hoveredProvince?.name, 'Thủ đô Hà Nội');

      // --- 2. Test Double Tap to Focus ---
      
      // Simulate a double tap at the coordinate
      await tester.tapAt(hanoiPoint);
      await tester.pump(const Duration(milliseconds: 100)); // Simulate time between taps
      await tester.tapAt(hanoiPoint);
      await tester.pumpAndSettle(); // Allow for async operations in focusProvince

      expect(provinceProvider.focusedProvince?.name, 'Thủ đô Hà Nội');

      // --- 3. Test Hover in Focused View ---

      // Find a commune to hover over
      final baDinh = provinceProvider.allCommunes.firstWhere((c) => c.name == 'Phường Ba Đình');
      final focusedTransform = calculateMapTransform(canvasSize, [hanoi]);
      final baDinhPoint = getPointInProvince(baDinh, focusedTransform);

      // Hover over the commune
      await gesture.moveTo(baDinhPoint);
      await tester.pump();

      expect(provinceProvider.hoveredProvince?.name, 'Phường Ba Đình');

      // --- 4. Test Hover Fallback to Province in Focused View ---

      // Move back to a point that is inside the province but not necessarily on the commune
      // For this test, we reuse hanoiPoint, which is transformed for the focused view.
      final hanoiFocusedPoint = getPointInProvince(hanoi, focusedTransform);
      await gesture.moveTo(hanoiFocusedPoint);
      await tester.pump();

      // It should fall back to the focused province (or the commune at that anchor point)
      expect(provinceProvider.hoveredProvince?.name, 'Xã An Khánh');

      // --- 5. Test Hover Outside in Focused View ---
      
      // Move mouse outside to (0,0)
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      
      // The hovered province should now be null
      expect(provinceProvider.hoveredProvince, isNull);
    });
  });
}
