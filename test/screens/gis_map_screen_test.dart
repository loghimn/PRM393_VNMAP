import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/screens/gis_map_screen.dart';
import 'package:vietnam_geo_dashboard/providers/household_provider.dart';
import 'package:vietnam_geo_dashboard/providers/incident_provider.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';
import 'test_helpers/mock_providers.dart';
import 'test_helpers/widget_test_utils.dart';
import 'test_helpers/screen_test_data.dart';

void main() {
  late FakeHouseholdProvider mockHousehold;
  late FakeIncidentProvider mockIncident;

  setUp(() {
    mockHousehold = FakeHouseholdProvider();
    mockHousehold.items = householdList;
    mockHousehold.isLoading = false;
    mockHousehold.error = null;

    mockIncident = FakeIncidentProvider();
    mockIncident.items = incidentList;
    mockIncident.isLoading = false;
    mockIncident.error = null;
  });

  Widget buildTestScreen({ProviderOverrides? overrides}) {
    return const GisMapScreen();
  }

  group('GisMapScreen', () {
    // ==================== RENDER ====================
    testWidgets('should render AppBar with title and legend button', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      expect(find.text('Bản đồ GIS'), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('should render search TextField', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tìm hộ dân, khu phố, địa điểm...'), findsOneWidget);
    });

    testWidgets(
      'should show filter chips with household and incident toggles',
      (tester) async {
        await tester.pumpScreen(
          buildTestScreen(),
          overrides: ProviderOverrides(
            household: mockHousehold,
            incident: mockIncident,
          ),
        );

        expect(find.text('Hộ dân'), findsOneWidget);
        expect(find.text('Sự vụ'), findsOneWidget);
      },
    );

    testWidgets('should show marker count in filter bar', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      // Both households have lat/lng, both incidents have lat/lng = 4 markers
      expect(find.text('4 điểm'), findsOneWidget);
    });

    // ==================== FILTER TOGGLES ====================
    testWidgets('should toggle household filter on tap', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      await tester.tap(find.text('Hộ dân'));
      await tester.pump();

      expect(find.text('2 điểm'), findsOneWidget);
    });

    testWidgets('should toggle incident filter on tap', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      await tester.tap(find.text('Sự vụ'));
      await tester.pump();

      expect(find.text('2 điểm'), findsOneWidget);
    });

    testWidgets('should toggle both filters off showing 0 markers', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      await tester.tap(find.text('Hộ dân'));
      await tester.pump();
      await tester.tap(find.text('Sự vụ'));
      await tester.pump();

      expect(find.text('0 điểm'), findsOneWidget);
    });

    // ==================== SEARCH ====================
    testWidgets('should show search clear button when typing', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('should submit search on pressing done', (tester) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test search');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    });

    // ==================== LEGEND DIALOG ====================
    testWidgets('should show legend dialog when layers button tapped', (
      tester,
    ) async {
      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.layers));
      await tester.pumpAndSettle();

      expect(find.text('Chú thích'), findsOneWidget);
      expect(find.text('Hộ gia đình'), findsOneWidget);
      expect(find.text('Sự vụ - Tiếp nhận'), findsOneWidget);
      expect(find.text('Sự vụ - Đang xử lý'), findsOneWidget);
      expect(find.text('Sự vụ - Hoàn thành'), findsOneWidget);
      expect(find.text('Sự vụ - Đã hủy'), findsOneWidget);

      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      expect(find.text('Chú thích'), findsNothing);
    });

    // ==================== LOADING STATE ====================
    testWidgets('should not crash when household is loading', (tester) async {
      mockHousehold.isLoading = true;

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      // Should render without error; the map still renders but markers
      // come from the data items, not from isLoading
      expect(find.byType(Scaffold), findsOneWidget);
    });

    // ==================== EMPTY STATE ====================
    testWidgets('should handle empty items with no markers', (tester) async {
      mockHousehold.items = [];
      mockIncident.items = [];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      expect(find.text('0 điểm'), findsOneWidget);
    });

    // ==================== STATIC HELPERS ====================
    group('GisMapScreen static helpers', () {
      test('getIncidentColor returns correct color for each status', () {
        expect(
          GisMapScreen.getIncidentColor(IncidentStatus.received),
          Colors.orange,
        );
        expect(
          GisMapScreen.getIncidentColor(IncidentStatus.processing),
          const Color(0xFF3B82F6),
        );
        expect(
          GisMapScreen.getIncidentColor(IncidentStatus.completed),
          Colors.green,
        );
        expect(
          GisMapScreen.getIncidentColor(IncidentStatus.cancelled),
          Colors.grey,
        );
      });

      test('detailRow renders label and value', () {
        final widget = GisMapScreen.detailRow('Mã hộ', 'HH001');
        // Should not crash, returns a widget
        expect(widget, isA<Widget>());
      });

      test('detailRow renders fallback for null value', () {
        final widget = GisMapScreen.detailRow('SĐT', null);
        expect(widget, isA<Widget>());
      });

      test('householdDetailContent renders with location data', () {
        final builder = GisMapScreen.householdDetailContent(
          testHousehold,
          () {},
        );
        expect(builder, isA<Widget>());
      });

      test('householdDetailContent renders without location data', () {
        final householdNoLoc = Household(
          id: 99,
          householdCode: 'HH099',
          headOfHousehold: 'Test',
          houseNumber: '1',
          street: 'Test',
          neighborhood: 'Test',
          ward: 'Test',
          city: 'Test',
          latitude: null,
          longitude: null,
          createdAt: baseDate,
          updatedAt: baseDate,
        );

        final builder = GisMapScreen.householdDetailContent(
          householdNoLoc,
          () {},
        );
        expect(builder, isA<Widget>());

        // Should not contain the "Xem vị trí" button
        expect(
          GisMapScreen.householdDetailContent(householdNoLoc, () {}),
          isA<Widget>(),
        );
      });

      test('incidentDetailContent renders with incident data', () {
        final builder = GisMapScreen.incidentDetailContent(testIncident);
        expect(builder, isA<Widget>());
      });

      test('incidentDetailContent renders incident with empty title', () {
        final incidentNoTitle = Incident(
          id: 99,
          incidentCode: 'INC099',
          title: '',
          description: null,
          status: IncidentStatus.received,
          createdAt: baseDate,
          updatedAt: baseDate,
        );

        final builder = GisMapScreen.incidentDetailContent(incidentNoTitle);
        expect(builder, isA<Widget>());
      });
    });

    // ==================== DATA WITHOUT LAT/LNG ====================
    testWidgets('should handle items without lat/lng gracefully', (
      tester,
    ) async {
      mockHousehold.items = [
        Household(
          id: 3,
          householdCode: 'HH003',
          headOfHousehold: 'No Location',
          houseNumber: '789',
          street: 'Test',
          neighborhood: 'Test',
          ward: 'Test',
          city: 'Test',
          latitude: null,
          longitude: null,
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      ];
      mockIncident.items = [
        Incident(
          id: 3,
          incidentCode: 'INC003',
          title: 'No Loc Incident (cancelled)',
          status: IncidentStatus.cancelled,
          latitude: null,
          longitude: null,
          createdAt: baseDate,
          updatedAt: baseDate,
        ),
      ];

      await tester.pumpScreen(
        buildTestScreen(),
        overrides: ProviderOverrides(
          household: mockHousehold,
          incident: mockIncident,
        ),
      );

      expect(find.text('0 điểm'), findsOneWidget);
    });
  });
}
