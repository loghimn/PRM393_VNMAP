import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/providers/province_provider.dart';
import 'package:vietnam_geo_dashboard/services/database_service.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart'
    show SearchResult;

// ============================================================
// MOCKS
// ============================================================

class MockDatabaseService extends Mock implements DatabaseService {}

// ============================================================
// HELPERS
// ============================================================

ProvinceModel createProvince({
  String name = 'Hà Nội',
  String? ma = '01',
  String? type,
  String? parentTen,
}) {
  return ProvinceModel(
    name: name,
    ma: ma,
    type: type,
    parentTen: parentTen,
    geometry: {'type': 'Polygon', 'coordinates': []},
    properties: {'type': type ?? 'province'},
  );
}

void main() {
  late ProvinceProvider provider;
  late MockDatabaseService mockService;

  final provinceHaNoi = createProvince(name: 'Hà Nội', ma: '01');
  final provinceHCM = createProvince(name: 'TP. Hồ Chí Minh', ma: '02');
  final zone1 = createProvince(
    name: 'Đặc khu A',
    ma: '99',
    type: 'special_zone',
  );
  final commune1 = createProvince(
    name: 'Phường Tràng Tiền',
    parentTen: 'Hà Nội',
  );
  final commune2 = createProvince(name: 'Phường Láng Hạ', parentTen: 'Hà Nội');

  setUp(() {
    mockService = MockDatabaseService();
    provider = ProvinceProvider.withService(mockService);
  });

  group('ProvinceProvider — initial state', () {
    test('should have correct initial state', () {
      expect(provider.provinces, isEmpty);
      expect(provider.specialZones, isEmpty);
      expect(provider.selectedProvince, isNull);
      expect(provider.selectedCommune, isNull);
      expect(provider.hoveredProvince, isNull);
      expect(provider.focusedProvince, isNull);
      expect(provider.focusedCommunes, isEmpty);
      expect(provider.communes, isEmpty);
      expect(provider.calculatedDensities, isEmpty);
      expect(provider.isCalculatingDensity, isFalse);
      expect(provider.isLoadingHighSchools, isFalse);
      expect(provider.isLoadingHouseholds, isFalse);
    });
  });

  group('ProvinceProvider — loadData()', () {
    test('should load provinces and special zones', () async {
      when(
        () => mockService.fetchProvinces(),
      ).thenAnswer((_) async => [provinceHaNoi, provinceHCM]);
      when(
        () => mockService.fetchSpecialZones(),
      ).thenAnswer((_) async => [zone1]);

      await provider.loadData();

      expect(provider.provinces, hasLength(2));
      expect(provider.provinces.first.name, 'Hà Nội');
      expect(provider.specialZones, hasLength(1));
      expect(provider.specialZones.first.name, 'Đặc khu A');
    });

    test('should handle empty data', () async {
      when(() => mockService.fetchProvinces()).thenAnswer((_) async => []);
      when(() => mockService.fetchSpecialZones()).thenAnswer((_) async => []);

      await provider.loadData();

      expect(provider.provinces, isEmpty);
      expect(provider.specialZones, isEmpty);
    });
  });

  group('ProvinceProvider — selectProvince()', () {
    test('should set selected province and clear commune', () async {
      provider.selectProvince(provinceHaNoi);

      expect(provider.selectedProvince, equals(provinceHaNoi));
      expect(provider.selectedCommune, isNull);
    });

    test('should notify listeners', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.selectProvince(provinceHaNoi);

      expect(notified, isTrue);
    });
  });

  group('ProvinceProvider — setHoveredProvince()', () {
    test('should set hovered province', () {
      provider.setHoveredProvince(provinceHaNoi);

      expect(provider.hoveredProvince, equals(provinceHaNoi));
    });

    test('should clear hovered province when null', () {
      provider.setHoveredProvince(provinceHaNoi);
      provider.setHoveredProvince(null);

      expect(provider.hoveredProvince, isNull);
    });

    test('should notify listeners', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.setHoveredProvince(provinceHaNoi);

      expect(notified, isTrue);
    });
  });

  group('ProvinceProvider — focusProvince()', () {
    test('should fetch communes and set focused province', () async {
      when(
        () => mockService.fetchCommunesForProvince('Hà Nội'),
      ).thenAnswer((_) async => [commune1, commune2]);

      await provider.focusProvince(provinceHaNoi);

      expect(provider.focusedProvince, equals(provinceHaNoi));
      expect(provider.focusedCommunes, hasLength(2));
      expect(provider.selectedProvince, equals(provinceHaNoi));
      verify(() => mockService.fetchCommunesForProvince('Hà Nội')).called(1);
    });

    test('should use cached communes on second focus', () async {
      when(
        () => mockService.fetchCommunesForProvince('Hà Nội'),
      ).thenAnswer((_) async => [commune1]);

      await provider.focusProvince(provinceHaNoi);
      await provider.focusProvince(provinceHaNoi);

      // Service should only be called once (cached)
      verify(() => mockService.fetchCommunesForProvince('Hà Nội')).called(1);
    });

    test('should handle fetch error gracefully', () async {
      when(
        () => mockService.fetchCommunesForProvince('Hà Nội'),
      ).thenThrow(Exception('Network error'));

      await provider.focusProvince(provinceHaNoi);

      expect(provider.focusedProvince, equals(provinceHaNoi));
      expect(provider.focusedCommunes, isEmpty);
    });
  });

  group('ProvinceProvider — clearFocus()', () {
    test('should clear focused province and communes', () {
      provider.clearFocus();

      expect(provider.focusedProvince, isNull);
      expect(provider.focusedCommunes, isEmpty);
    });

    test('should notify listeners', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.clearFocus();

      expect(notified, isTrue);
    });
  });

  group('ProvinceProvider — selectCommune()', () {
    test('should set selected commune and clear selected province', () async {
      when(
        () => mockService.fetchHighSchoolsByCommuneName(
          any(),
          provinceName: any(named: 'provinceName'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockService.fetchHouseholdsByCommuneName(any()),
      ).thenAnswer((_) async => []);

      provider.selectCommune(commune1);
      // Give async operations time to complete
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedCommune, equals(commune1));
      expect(provider.selectedProvince, isNull);
    });

    test('should trigger high schools and households loading', () async {
      when(
        () => mockService.fetchHighSchoolsByCommuneName(
          any(),
          provinceName: any(named: 'provinceName'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockService.fetchHouseholdsByCommuneName(any()),
      ).thenAnswer((_) async => []);

      provider.selectCommune(commune1);
      // Give async operations time to complete
      await Future<void>.delayed(Duration.zero);

      verify(
        () => mockService.fetchHighSchoolsByCommuneName(
          'Phường Tràng Tiền',
          provinceName: any(named: 'provinceName'),
        ),
      ).called(1);
      verify(() => mockService.fetchHouseholdsByCommuneName(any())).called(1);
    });
  });

  group('ProvinceProvider — clearSelection()', () {
    test('should clear selected province and commune', () {
      provider.clearSelection();

      expect(provider.selectedProvince, isNull);
      expect(provider.selectedCommune, isNull);
    });

    test('should notify listeners', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.clearSelection();

      expect(notified, isTrue);
    });
  });

  group('ProvinceProvider — calculateCommuneDensities()', () {
    test('should fetch and cache densities', () async {
      when(() => mockService.fetchCalculatedDensities()).thenAnswer(
        (_) async => [
          {'commune': 'Phường A', 'density': 5000},
        ],
      );

      await provider.calculateCommuneDensities();

      expect(provider.calculatedDensities, hasLength(1));
      expect(provider.isCalculatingDensity, isFalse);
    });

    test('should not fetch again if already loaded', () async {
      when(() => mockService.fetchCalculatedDensities()).thenAnswer(
        (_) async => [
          {'commune': 'Phường A', 'density': 5000},
        ],
      );

      await provider.calculateCommuneDensities(); // first call
      await provider.calculateCommuneDensities(); // second call (cached)

      // Should only call service once
      verify(() => mockService.fetchCalculatedDensities()).called(1);
    });

    test('should not fetch if already calculating', () async {
      // Mock to return a future that never completes to keep isCalculating = true
      when(() => mockService.fetchCalculatedDensities()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return [
          {'commune': 'Phường A'},
        ];
      });

      // Start first call but don't await it
      provider.calculateCommuneDensities();
      // Second call should return immediately because isCalculating is true
      await provider.calculateCommuneDensities();

      // Should only call service once
      verify(() => mockService.fetchCalculatedDensities()).called(1);
    });

    test('should handle error gracefully', () async {
      when(
        () => mockService.fetchCalculatedDensities(),
      ).thenThrow(Exception('Fetch error'));

      await provider.calculateCommuneDensities();

      expect(provider.calculatedDensities, isEmpty);
      expect(provider.isCalculatingDensity, isFalse);
    });
  });

  group('ProvinceProvider — loadHighSchoolsForCommune()', () {
    test('should skip if commune name is empty', () async {
      final emptyCommune = createProvince(name: '');

      await provider.loadHighSchoolsForCommune(emptyCommune);

      verifyNever(
        () => mockService.fetchHighSchoolsByCommuneName(
          any(),
          provinceName: any(named: 'provinceName'),
        ),
      );
    });

    test('should load high schools successfully', () async {
      when(
        () => mockService.fetchHighSchoolsByCommuneName(
          'Phường Tràng Tiền',
          provinceName: any(named: 'provinceName'),
        ),
      ).thenAnswer((_) async => []);

      await provider.loadHighSchoolsForCommune(commune1);

      expect(provider.isLoadingHighSchools, isFalse);
    });
  });

  group('ProvinceProvider — loadHouseholdsForCommune()', () {
    test('should skip if commune name is empty', () async {
      final emptyCommune = createProvince(name: '');

      await provider.loadHouseholdsForCommune(emptyCommune);

      verifyNever(() => mockService.fetchHouseholdsByCommuneName(any()));
    });

    test('should load households successfully', () async {
      when(
        () => mockService.fetchHouseholdsByCommuneName('Phường Tràng Tiền'),
      ).thenAnswer((_) async => []);

      await provider.loadHouseholdsForCommune(commune1);

      expect(provider.isLoadingHouseholds, isFalse);
    });
  });

  group('ProvinceProvider — searchLocations()', () {
    test('should delegate to service', () async {
      final results = [
        SearchResult(name: 'Hà Nội', type: 'province', model: provinceHaNoi),
      ];
      when(
        () => mockService.searchLocations('Hà'),
      ).thenAnswer((_) async => results);

      final result = await provider.searchLocations('Hà');

      expect(result, hasLength(1));
      expect(result.first.name, 'Hà Nội');
      verify(() => mockService.searchLocations('Hà')).called(1);
    });
  });

  group('ProvinceProvider — selectSearchResult()', () {
    test('should select province when result type is province', () async {
      final result = SearchResult(
        name: 'Hà Nội',
        type: 'province',
        model: provinceHaNoi,
      );

      await provider.selectSearchResult(result);

      expect(provider.selectedProvince, equals(provinceHaNoi));
      expect(provider.focusedProvince, isNull);
    });

    test('should select commune when result type is commune', () async {
      when(
        () => mockService.fetchCommunesForProvince('Hà Nội'),
      ).thenAnswer((_) async => [commune1]);
      when(
        () => mockService.fetchProvinces(),
      ).thenAnswer((_) async => [provinceHaNoi]);
      when(() => mockService.fetchSpecialZones()).thenAnswer((_) async => []);
      when(
        () => mockService.fetchHighSchoolsByCommuneName(
          any(),
          provinceName: any(named: 'provinceName'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockService.fetchHouseholdsByCommuneName(any()),
      ).thenAnswer((_) async => []);

      // Need to have provinces loaded for the search lookup
      await provider.loadData();
      final result = SearchResult(
        name: 'Phường Tràng Tiền',
        type: 'commune',
        model: commune1,
      );

      await provider.selectSearchResult(result);

      expect(provider.selectedCommune, equals(commune1));
      expect(provider.selectedProvince, isNull);
      expect(provider.focusedProvince, isNotNull);
    });
  });
}
