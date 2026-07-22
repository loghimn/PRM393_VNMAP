import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnam_geo_dashboard/models/dia_diem_lich_su_model.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = createTestFirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService — DiaDiemLichSu', () {
    group('fetchDiaDiemLichSuList', () {
      test('returns list of historical sites', () async {
        await fakeFirestore.collection('dia_diem_lich_su').doc('1').set({
          'id': 1,
          'ten': 'Chùa Một Cột',
          'loai_di_tich': 'Chùa',
          'dia_chi': 'Hà Nội',
          'thoi_ky': 'Lý',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchDiaDiemLichSuList();

        expect(result.length, 1);
        expect(result.first.ten, 'Chùa Một Cột');
      });

      test('filters by search query on name', () async {
        await fakeFirestore.collection('dia_diem_lich_su').doc('1').set({
          'id': 1,
          'ten': 'Chùa Một Cột',
          'loai_di_tich': 'Chùa',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dia_diem_lich_su').doc('2').set({
          'id': 2,
          'ten': 'Văn Miếu',
          'loai_di_tich': 'Di tích',
          'created_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchDiaDiemLichSuList(
          searchQuery: 'Chùa',
        );

        expect(result.length, 1);
        expect(result.first.ten, 'Chùa Một Cột');
      });

      test('filters by search query on loaiDiTich', () async {
        await fakeFirestore.collection('dia_diem_lich_su').doc('1').set({
          'id': 1,
          'ten': 'Đền Hùng',
          'loai_di_tich': 'Đền',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchDiaDiemLichSuList(searchQuery: 'Đền');

        expect(result.length, 1);
      });

      test('returns empty list when no match', () async {
        await fakeFirestore.collection('dia_diem_lich_su').doc('1').set({
          'id': 1,
          'ten': 'Chùa Một Cột',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchDiaDiemLichSuList(
          searchQuery: 'NonExistent',
        );

        expect(result, isEmpty);
      });
    });

    group('fetchDiaDiemLichSuById', () {
      test('returns site when found', () async {
        await fakeFirestore.collection('dia_diem_lich_su').doc('3').set({
          'id': 3,
          'ten': 'Hoàng Thành Thăng Long',
          'loai_di_tich': 'Di tích',
          'created_at': '2024-01-03T00:00:00.000',
        });

        final result = await service.fetchDiaDiemLichSuById(3);

        expect(result, isNotNull);
        expect(result!.ten, 'Hoàng Thành Thăng Long');
      });

      test('returns null when not found', () async {
        final result = await service.fetchDiaDiemLichSuById(999);

        expect(result, isNull);
      });
    });

    group('createDiaDiemLichSu', () {
      test('creates a historical site and returns it', () async {
        final item = DiaDiemLichSu(
          ten: 'Chùa Bái Đính',
          loaiDiTich: 'Chùa',
          diaChi: 'Ninh Bình',
        );

        final created = await service.createDiaDiemLichSu(item);

        expect(created.id, greaterThan(0));
        expect(created.ten, 'Chùa Bái Đính');
        expect(created.loaiDiTich, 'Chùa');

        // Verify it was persisted
        final snap = await fakeFirestore.collection('dia_diem_lich_su').get();
        expect(snap.docs.length, 1);
      });
    });

    group('updateDiaDiemLichSu', () {
      test('updates an existing site', () async {
        await fakeFirestore.collection('dia_diem_lich_su').doc('5').set({
          'id': 5,
          'ten': 'Old Name',
          'loai_di_tich': 'Di tích',
          'created_at': '2024-01-05T00:00:00.000',
        });

        final updated = await service.updateDiaDiemLichSu(
          DiaDiemLichSu(
            id: 5,
            ten: 'Updated Name',
            loaiDiTich: 'Di tích quốc gia',
          ),
        );

        expect(updated.ten, 'Updated Name');
        expect(updated.loaiDiTich, 'Di tích quốc gia');
      });
    });

    group('deleteDiaDiemLichSu', () {
      test('deletes a site', () async {
        await fakeFirestore.collection('dia_diem_lich_su').doc('7').set({
          'id': 7,
          'ten': 'To Delete',
          'created_at': '2024-01-07T00:00:00.000',
        });

        await service.deleteDiaDiemLichSu(7);

        final snap = await fakeFirestore.collection('dia_diem_lich_su').get();
        expect(snap.docs.length, 0);
      });
    });
  });
}
