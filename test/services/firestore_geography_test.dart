import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = createTestFirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService — Geography', () {
    group('fetchProvinces', () {
      test('returns list of provinces', () async {
        await fakeFirestore.collection('provinces').doc('79').set({
          'name': 'TP. Hồ Chí Minh',
          'code': '79',
          'type': 'Thành phố',
          'area_km2': 2061,
          'population': 8993000,
          'density': 4363,
          'capital': 'Quận 1',
          'macro_region': 'Đông Nam Bộ',
        });
        await fakeFirestore.collection('provinces').doc('01').set({
          'name': 'Hà Nội',
          'code': '01',
          'type': 'Thành phố',
          'area_km2': 3359,
          'population': 8054000,
          'density': 2398,
          'capital': 'Hoàn Kiếm',
          'macro_region': 'Đồng bằng sông Hồng',
        });

        final result = await service.fetchProvinces();

        expect(result.length, 2);
        expect(result.map((p) => p.name), contains('TP. Hồ Chí Minh'));
        expect(result.map((p) => p.name), contains('Hà Nội'));
      });

      test('returns empty list when no provinces', () async {
        final result = await service.fetchProvinces();

        expect(result, isEmpty);
      });
    });

    group('fetchSpecialZones', () {
      test('returns list of special zones', () async {
        await fakeFirestore.collection('special_zones').doc('sz-1').set({
          'name': 'Khu kinh tế Dung Quất',
          'code': 'SZ01',
          'type': 'Khu kinh tế',
        });

        final result = await service.fetchSpecialZones();

        expect(result.length, 1);
        expect(result.first.name, 'Khu kinh tế Dung Quất');
      });

      test('returns empty list when no special zones', () async {
        final result = await service.fetchSpecialZones();

        expect(result, isEmpty);
      });
    });

    group('fetchCommunesForProvince', () {
      test('returns communes for a province name', () async {
        // Note: service queries parent_name, not parent_code
        await fakeFirestore.collection('communes').doc('c-1').set({
          'name': 'Phường 1',
          'code': 'C01',
          'parent_name': 'TP. Hồ Chí Minh',
          'parent_ten': 'TP. Hồ Chí Minh',
          'type': 'Phường',
        });
        await fakeFirestore.collection('communes').doc('c-2').set({
          'name': 'Phường 2',
          'code': 'C02',
          'parent_name': 'TP. Hồ Chí Minh',
          'parent_ten': 'TP. Hồ Chí Minh',
          'type': 'Phường',
        });

        final result = await service.fetchCommunesForProvince(
          'TP. Hồ Chí Minh',
        );

        expect(result.length, 2);
        expect(result.map((c) => c.name), contains('Phường 1'));
      });

      test('returns empty list for unknown province name', () async {
        final result = await service.fetchCommunesForProvince('NonExistent');

        expect(result, isEmpty);
      });
    });

    group('fetchCalculatedDensities', () {
      test('returns sorted density list', () async {
        await fakeFirestore.collection('provinces').doc('01').set({
          'name': 'Hà Nội',
          'code': '01',
          'area_km2': 3359,
          'population': 8054000,
        });
        await fakeFirestore.collection('provinces').doc('79').set({
          'name': 'TP. Hồ Chí Minh',
          'code': '79',
          'area_km2': 2061,
          'population': 8993000,
        });

        final result = await service.fetchCalculatedDensities();

        // Sorted descending: HCMC has higher density
        expect(result.length, 2);
        expect(result.first['name'], 'TP. Hồ Chí Minh');
        expect(
          (result.first['density'] as double) >
              (result.last['density'] as double),
          isTrue,
        );
      });

      test('excludes provinces without population/area', () async {
        await fakeFirestore.collection('provinces').doc('no-data').set({
          'name': 'No Data',
          'code': '00',
        });

        final result = await service.fetchCalculatedDensities();

        expect(result, isEmpty);
      });
    });

    group('fetchHighSchoolsByCommuneName', () {
      test('returns high schools by commune name', () async {
        await fakeFirestore.collection('high_schools').doc('hs-1').set({
          'ten_truong': 'THPT Chuyên Lê Hồng Phong',
          'ten_xa_phuong': 'Phường 1',
          'ten_tinh_tp': 'TP. Hồ Chí Minh',
          'dia_chi': '123 ABC',
          'loai_hinh': 'Công lập',
        });
        await fakeFirestore.collection('high_schools').doc('hs-2').set({
          'ten_truong': 'THPT Nguyễn Du',
          'ten_xa_phuong': 'Phường 2',
          'ten_tinh_tp': 'TP. Hồ Chí Minh',
          'dia_chi': '456 XYZ',
          'loai_hinh': 'Công lập',
        });

        final result = await service.fetchHighSchoolsByCommuneName('Phường 1');

        expect(result.length, 1);
        expect(result.first.tenTruong, 'THPT Chuyên Lê Hồng Phong');
      });

      test('filters by province name', () async {
        await fakeFirestore.collection('high_schools').doc('hs-1').set({
          'ten_truong': 'THPT A',
          'ten_xa_phuong': 'Phường 1',
          'ten_tinh_tp': 'TP. Hồ Chí Minh',
          'dia_chi': '123',
          'loai_hinh': 'Công lập',
        });
        await fakeFirestore.collection('high_schools').doc('hs-2').set({
          'ten_truong': 'THPT B',
          'ten_xa_phuong': 'Phường 1',
          'ten_tinh_tp': 'Hà Nội',
          'dia_chi': '456',
          'loai_hinh': 'Công lập',
        });

        final result = await service.fetchHighSchoolsByCommuneName(
          'Phường 1',
          provinceName: 'TP. Hồ Chí Minh',
        );

        expect(result.length, 1);
        expect(result.first.tenTruong, 'THPT A');
      });

      test('uses fallback query with stripped prefix', () async {
        await fakeFirestore.collection('high_schools').doc('hs-1').set({
          'ten_truong': 'THPT C',
          'ten_xa_phuong': 'Phường 1',
          'ten_tinh_tp': 'TP. Hồ Chí Minh',
          'dia_chi': '789',
          'loai_hinh': 'Công lập',
        });

        final result = await service.fetchHighSchoolsByCommuneName('Phường 1');

        expect(result.length, 1);
        expect(result.first.tenTruong, 'THPT C');
      });
    });

    group('searchLocations', () {
      test('returns search results matching query', () async {
        await fakeFirestore.collection('provinces').doc('79').set({
          'name': 'TP. Hồ Chí Minh',
          'code': '79',
        });
        await fakeFirestore.collection('special_zones').doc('sz-1').set({
          'name': 'Khu kinh tế Dung Quất',
          'code': 'SZ01',
        });

        final result = await service.searchLocations('Hồ Chí Minh');

        expect(result.isNotEmpty, isTrue);
        expect(result.any((r) => r.type == 'province'), isTrue);
      });

      test('returns empty list for empty query', () async {
        final result = await service.searchLocations('');

        expect(result, isEmpty);
      });

      test('returns empty list for whitespace query', () async {
        final result = await service.searchLocations('   ');

        expect(result, isEmpty);
      });
    });

    group('fetchDistinctNeighborhoods', () {
      test('returns sorted unique neighborhoods', () async {
        await fakeFirestore.collection('households').doc('h-1').set({
          'neighborhood': 'Khu phố 2',
        });
        await fakeFirestore.collection('households').doc('h-2').set({
          'neighborhood': 'Khu phố 1',
        });
        await fakeFirestore.collection('households').doc('h-3').set({
          'neighborhood': 'Khu phố 2',
        });

        final result = await service.fetchDistinctNeighborhoods();

        expect(result, ['Khu phố 1', 'Khu phố 2']);
      });

      test('returns empty list when no households', () async {
        final result = await service.fetchDistinctNeighborhoods();

        expect(result, isEmpty);
      });
    });

    group('fetchDistinctWards', () {
      test('returns sorted ward names', () async {
        await fakeFirestore.collection('communes').doc('c-2').set({
          'name': 'Phường 2',
        });
        await fakeFirestore.collection('communes').doc('c-1').set({
          'name': 'Phường 1',
        });

        final result = await service.fetchDistinctWards();

        expect(result, ['Phường 1', 'Phường 2']);
      });
    });

    group('fetchCommunesForProvinceName', () {
      test('returns communes matching province name', () async {
        await fakeFirestore.collection('communes').doc('c-1').set({
          'name': 'Phường 1',
          'parent_name': 'TP. Hồ Chí Minh',
          'parent_ten': 'TP. Hồ Chí Minh',
        });
        await fakeFirestore.collection('communes').doc('c-2').set({
          'name': 'Phường 2',
          'parent_name': 'Hà Nội',
          'parent_ten': 'Hà Nội',
        });

        final result = await service.fetchCommunesForProvinceName(
          'TP. Hồ Chí Minh',
        );

        expect(result, ['Phường 1']);
      });
    });

    group('fetchDistinctDistricts / fetchDistinctCities', () {
      test('fetchDistinctDistricts returns sorted districts', () async {
        // Note: service queries households collection, not communes
        await fakeFirestore.collection('households').doc('h-1').set({
          'district': 'Quận 2',
        });
        await fakeFirestore.collection('households').doc('h-2').set({
          'district': 'Quận 1',
        });

        final result = await service.fetchDistinctDistricts();

        expect(result, ['Quận 1', 'Quận 2']);
      });

      test('fetchDistinctCities returns sorted cities', () async {
        // Note: service queries provinces collection
        await fakeFirestore.collection('provinces').doc('79').set({
          'code': '79',
          'name': 'TP. Hồ Chí Minh',
        });

        final result = await service.fetchDistinctCities();

        expect(result.isNotEmpty, isTrue);
        expect(result.first['name'], 'TP. Hồ Chí Minh');
      });
    });

    group('fetchCommunesForParentCode', () {
      test('returns communes for a given parent code', () async {
        await fakeFirestore.collection('communes').doc('c-1').set({
          'name': 'Phường 1',
          'parent_code': '79',
        });
        await fakeFirestore.collection('communes').doc('c-2').set({
          'name': 'Phường 2',
          'parent_code': '79',
        });
        await fakeFirestore.collection('communes').doc('c-3').set({
          'name': 'Phường Khác',
          'parent_code': '01',
        });

        final result = await service.fetchCommunesForParentCode('79');

        expect(result.length, 2);
        expect(result, contains('Phường 1'));
      });
    });

    group('fetchNeighborhoodList', () {
      test('returns list of neighborhoods', () async {
        await fakeFirestore.collection('households').doc('h-1').set({
          'neighborhood': 'Khu phố 1',
        });
        await fakeFirestore.collection('households').doc('h-2').set({
          'neighborhood': 'Khu phố 2',
        });

        final result = await service.fetchNeighborhoodList();

        expect(result, ['Khu phố 1', 'Khu phố 2']);
      });
    });
  });
}
