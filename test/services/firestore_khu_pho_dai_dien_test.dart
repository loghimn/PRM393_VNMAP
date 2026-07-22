import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = createTestFirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService — KhuPho', () {
    group('fetchKhuPhos', () {
      test('returns list of khu pho', () async {
        await fakeFirestore.collection('khu_pho').doc('1').set({
          'id': 1,
          'ten_khu_pho': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('khu_pho').doc('2').set({
          'id': 2,
          'ten_khu_pho': 'Khu phố 2',
          'created_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchKhuPhos();

        expect(result.length, 2);
        expect(result.first.tenKhuPho, 'Khu phố 1');
      });

      test('returns empty list when none exist', () async {
        final result = await service.fetchKhuPhos();

        expect(result, isEmpty);
      });
    });

    group('fetchKhuPhoById', () {
      test('returns khu pho when found', () async {
        await fakeFirestore.collection('khu_pho').doc('5').set({
          'id': 5,
          'ten_khu_pho': 'Khu phố 5',
          'created_at': '2024-01-05T00:00:00.000',
        });

        final result = await service.fetchKhuPhoById(5);

        expect(result, isNotNull);
        expect(result!.tenKhuPho, 'Khu phố 5');
      });

      test('returns null when not found', () async {
        final result = await service.fetchKhuPhoById(999);

        expect(result, isNull);
      });
    });

    group('createKhuPho', () {
      test('creates and returns a khu pho', () async {
        final model = KhuPhoModel(tenKhuPho: 'Khu phố Mới');

        final created = await service.createKhuPho(model);

        expect(created.id, greaterThan(0));
        expect(created.tenKhuPho, 'Khu phố Mới');

        final snap = await fakeFirestore.collection('khu_pho').get();
        expect(snap.docs.length, 1);
      });
    });

    group('updateKhuPho', () {
      test('updates an existing khu pho', () async {
        await fakeFirestore.collection('khu_pho').doc('3').set({
          'id': 3,
          'ten_khu_pho': 'Old Name',
          'created_at': '2024-01-03T00:00:00.000',
        });

        final updated = await service.updateKhuPho(
          KhuPhoModel(id: 3, tenKhuPho: 'Updated Name'),
        );

        expect(updated.tenKhuPho, 'Updated Name');
      });
    });

    group('deleteKhuPho', () {
      test('deletes a khu pho and its dai diens', () async {
        await fakeFirestore.collection('khu_pho').doc('10').set({
          'id': 10,
          'ten_khu_pho': 'Khu phố 10',
          'created_at': '2024-01-10T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('1').set({
          'id': 1,
          'ho_ten': 'Nguyễn Văn A',
          'khu_pho_id': 10,
          'created_at': '2024-01-10T00:00:00.000',
        });

        await service.deleteKhuPho(10);

        final kpSnap = await fakeFirestore.collection('khu_pho').get();
        expect(kpSnap.docs.length, 0);

        final ddSnap = await fakeFirestore.collection('dai_dien_khu_pho').get();
        expect(ddSnap.docs.length, 0);
      });
    });
  });

  group('FirestoreService — DaiDienKhuPho', () {
    group('fetchDaiDiens', () {
      test('returns list of dai dien', () async {
        // Need khu_pho doc because fetchDaiDiens looks up ten_khu_pho
        await fakeFirestore.collection('khu_pho').doc('1').set({
          'id': 1,
          'ten_khu_pho': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('1').set({
          'id': 1,
          'ho_ten': 'Nguyễn Văn A',
          'so_dien_thoai': '0901234567',
          'email': 'a@example.com',
          'khu_pho_id': 1,
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('2').set({
          'id': 2,
          'ho_ten': 'Trần Thị B',
          'khu_pho_id': 1,
          'created_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchDaiDiens();

        expect(result.length, 2);
        expect(result.first.hoTen, 'Nguyễn Văn A');
        expect(result.first.khuPhoId, 1);
        expect(result.first.tenKhuPho, 'Khu phố 1');
      });

      test('returns empty list when none exist', () async {
        final result = await service.fetchDaiDiens();

        expect(result, isEmpty);
      });
    });

    group('fetchDaiDiensByKhuPho', () {
      test('returns dai diens filtered by khu_pho_id', () async {
        await fakeFirestore.collection('khu_pho').doc('1').set({
          'id': 1,
          'ten_khu_pho': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('1').set({
          'id': 1,
          'ho_ten': 'Nguyễn Văn A',
          'khu_pho_id': 1,
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('2').set({
          'id': 2,
          'ho_ten': 'Trần Thị B',
          'khu_pho_id': 2,
          'created_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchDaiDiensByKhuPho(1);

        expect(result.length, 1);
        expect(result.first.hoTen, 'Nguyễn Văn A');
      });
    });

    group('fetchDaiDienById', () {
      test('returns dai dien when found', () async {
        await fakeFirestore.collection('khu_pho').doc('1').set({
          'id': 1,
          'ten_khu_pho': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('5').set({
          'id': 5,
          'ho_ten': 'Lê Văn C',
          'khu_pho_id': 1,
          'created_at': '2024-01-05T00:00:00.000',
        });

        final result = await service.fetchDaiDienById(5);

        expect(result, isNotNull);
        expect(result!.hoTen, 'Lê Văn C');
        expect(result!.tenKhuPho, 'Khu phố 1');
      });

      test('returns null when not found', () async {
        final result = await service.fetchDaiDienById(999);

        expect(result, isNull);
      });
    });

    group('createDaiDien', () {
      test('creates and returns a dai dien', () async {
        await fakeFirestore.collection('khu_pho').doc('2').set({
          'id': 2,
          'ten_khu_pho': 'Khu phố 2',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final model = DaiDienModel(
          hoTen: 'Phạm Thị D',
          soDienThoai: '0912345678',
          khuPhoId: 2,
        );

        final created = await service.createDaiDien(model);

        expect(created.id, greaterThan(0));
        expect(created.hoTen, 'Phạm Thị D');

        final snap = await fakeFirestore.collection('dai_dien_khu_pho').get();
        expect(snap.docs.length, 1);
      });
    });

    group('updateDaiDien', () {
      test('updates an existing dai dien', () async {
        await fakeFirestore.collection('khu_pho').doc('3').set({
          'id': 3,
          'ten_khu_pho': 'Khu phố 3',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('6').set({
          'id': 6,
          'ho_ten': 'Old Name',
          'so_dien_thoai': '0900000000',
          'khu_pho_id': 3,
          'created_at': '2024-01-06T00:00:00.000',
          'updated_at': '2024-01-06T00:00:00.000',
        });

        final updated = await service.updateDaiDien(
          DaiDienModel(
            id: 6,
            hoTen: 'Updated Name',
            soDienThoai: '0999999999',
            khuPhoId: 3,
          ),
        );

        expect(updated.hoTen, 'Updated Name');
        expect(updated.soDienThoai, '0999999999');
      });
    });

    group('deleteDaiDien', () {
      test('deletes a dai dien', () async {
        await fakeFirestore.collection('dai_dien_khu_pho').doc('7').set({
          'id': 7,
          'ho_ten': 'To Delete',
          'created_at': '2024-01-07T00:00:00.000',
        });

        await service.deleteDaiDien(7);

        final snap = await fakeFirestore.collection('dai_dien_khu_pho').get();
        expect(snap.docs.length, 0);
      });
    });

    group('searchDaiDiens', () {
      test('returns empty list for empty query', () async {
        final result = await service.searchDaiDiens('');

        expect(result, isEmpty);
      });

      test('searches by ho_ten', () async {
        await fakeFirestore.collection('khu_pho').doc('1').set({
          'id': 1,
          'ten_khu_pho': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('1').set({
          'id': 1,
          'ho_ten': 'Nguyễn Văn A',
          'khu_pho_id': 1,
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('dai_dien_khu_pho').doc('2').set({
          'id': 2,
          'ho_ten': 'Trần Thị B',
          'khu_pho_id': 1,
          'created_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.searchDaiDiens('Văn A');

        expect(result.length, 1);
        expect(result.first.hoTen, 'Nguyễn Văn A');
      });

      test('searches by so_dien_thoai', () async {
        await fakeFirestore.collection('dai_dien_khu_pho').doc('1').set({
          'id': 1,
          'ho_ten': 'Nguyễn Văn A',
          'so_dien_thoai': '0901234567',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.searchDaiDiens('0901234567');

        expect(result.length, 1);
      });
    });
  });
}
