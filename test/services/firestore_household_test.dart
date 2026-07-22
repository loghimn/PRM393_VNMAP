import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/services/firestore_service.dart';

import 'mock_helper.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = createTestFirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService — Households', () {
    group('fetchHouseholdList', () {
      test('returns list of households', () async {
        await fakeFirestore.collection('households').doc('1').set({
          'id': 1,
          'household_code': 'HGD-0001',
          'house_number': '123',
          'street': 'Nguyễn Huệ',
          'head_of_household': 'Nguyễn Văn A',
          'phone': '0909123456',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchHouseholdList();

        expect(result.length, 1);
        expect(result.first.houseNumber, '123');
        expect(result.first.headOfHousehold, 'Nguyễn Văn A');
      });

      test('applies pagination with limit and offset', () async {
        for (int i = 0; i < 5; i++) {
          await fakeFirestore.collection('households').doc('$i').set({
            'id': i,
            'household_code': 'HGD-${(i + 1).toString().padLeft(4, '0')}',
            'house_number': '$i',
            'street': 'Street',
            'head_of_household': 'Owner $i',
            'phone': '090900000$i',
            'neighborhood': 'Khu phố 1',
            'created_at': '2024-01-0${i + 1}T00:00:00.000',
          });
        }

        final result = await service.fetchHouseholdList(limit: 3);

        expect(result.length, 3);
      });

      test('filters by neighborhood', () async {
        await fakeFirestore.collection('households').doc('1').set({
          'id': 1,
          'household_code': 'HGD-0001',
          'house_number': 'A',
          'street': 'Street',
          'head_of_household': 'Owner A',
          'phone': '0909000001',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('households').doc('2').set({
          'id': 2,
          'household_code': 'HGD-0002',
          'house_number': 'B',
          'street': 'Street',
          'head_of_household': 'Owner B',
          'phone': '0909000002',
          'neighborhood': 'Khu phố 2',
          'created_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchHouseholdList(
          neighborhood: 'Khu phố 1',
        );

        expect(result.length, 1);
        expect(result.first.headOfHousehold, 'Owner A');
      });

      test('filters by search query', () async {
        await fakeFirestore.collection('households').doc('1').set({
          'id': 1,
          'household_code': 'HGD-0001',
          'house_number': '123',
          'street': 'Street',
          'head_of_household': 'Nguyễn Văn A',
          'phone': '0909123456',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchHouseholdList(
          searchQuery: 'Nguyễn Văn',
        );

        expect(result.length, 1);
      });
    });

    group('fetchHouseholdById', () {
      test('returns household when found', () async {
        await fakeFirestore.collection('households').doc('42').set({
          'id': 42,
          'household_code': 'HGD-0042',
          'house_number': '42',
          'street': 'Life',
          'head_of_household': 'Answer',
          'phone': '0909000042',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchHouseholdById(42);

        expect(result, isNotNull);
        expect(result!.headOfHousehold, 'Answer');
      });

      test('returns null when not found', () async {
        final result = await service.fetchHouseholdById(999);

        expect(result, isNull);
      });
    });

    group('createHousehold', () {
      test('creates a household and returns it', () async {
        final household = Household(
          householdCode: 'HGD-TEMP',
          headOfHousehold: 'Trần Thị B',
          houseNumber: '456',
          street: 'Lê Lợi',
          phone: '0909987654',
          neighborhood: 'Khu phố 2',
        );

        final created = await service.createHousehold(household);

        expect(created.id, greaterThan(0));
        expect(created.houseNumber, '456');
        expect(created.headOfHousehold, 'Trần Thị B');
        expect(created.householdCode, startsWith('HGD-'));

        // Verify it was persisted
        final snap = await fakeFirestore.collection('households').get();
        expect(snap.docs.length, 1);
      });
    });

    group('updateHousehold', () {
      test('updates an existing household', () async {
        await fakeFirestore.collection('households').doc('1').set({
          'id': 1,
          'household_code': 'HGD-0001',
          'house_number': '789',
          'street': 'Hai Bà Trưng',
          'head_of_household': 'Lê Văn C',
          'phone': '0909555666',
          'neighborhood': 'Khu phố 3',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final updated = await service.updateHousehold(
          Household(
            id: 1,
            householdCode: 'HGD-0001',
            houseNumber: '789',
            street: 'Hai Bà Trưng',
            headOfHousehold: 'Lê Văn C (Updated)',
            phone: '0909555666',
            neighborhood: 'Khu phố 3',
          ),
        );

        expect(updated.headOfHousehold, 'Lê Văn C (Updated)');
        expect(updated.houseNumber, '789');
      });
    });

    group('deleteHousehold', () {
      test('deletes a household', () async {
        await fakeFirestore.collection('households').doc('101').set({
          'id': 101,
          'household_code': 'HGD-0101',
          'house_number': '101',
          'street': 'Test',
          'head_of_household': 'Test',
          'phone': '0909000000',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });

        await service.deleteHousehold(101);

        final snap = await fakeFirestore.collection('households').get();
        expect(snap.docs.length, 0);
      });
    });

    group('fetchHouseholdsByCommuneName', () {
      test('returns households in a ward/commune', () async {
        await fakeFirestore.collection('households').doc('1').set({
          'id': 1,
          'household_code': 'HGD-0001',
          'house_number': '1',
          'street': 'A',
          'head_of_household': 'Owner A',
          'phone': '0909000001',
          'neighborhood': 'Khu phố 1',
          'ward': 'Phường 1',
          'created_at': '2024-01-01T00:00:00.000',
        });
        await fakeFirestore.collection('households').doc('2').set({
          'id': 2,
          'household_code': 'HGD-0002',
          'house_number': '2',
          'street': 'B',
          'head_of_household': 'Owner B',
          'phone': '0909000002',
          'neighborhood': 'Khu phố 2',
          'ward': 'Phường 2',
          'created_at': '2024-01-02T00:00:00.000',
        });

        final result = await service.fetchHouseholdsByCommuneName('Phường 1');

        expect(result.length, 1);
        expect(result.first.headOfHousehold, 'Owner A');
      });

      test('returns empty for unknown ward', () async {
        final result = await service.fetchHouseholdsByCommuneName(
          'NonExistent',
        );

        expect(result, isEmpty);
      });
    });

    group('fetchHouseholdsByWard', () {
      test('delegates to fetchHouseholdsByCommuneName', () async {
        await fakeFirestore.collection('households').doc('1').set({
          'id': 1,
          'household_code': 'HGD-0001',
          'house_number': '1',
          'street': 'A',
          'head_of_household': 'Owner A',
          'phone': '0909000001',
          'neighborhood': 'Khu phố 1',
          'ward': 'Phường 1',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchHouseholdsByWard('Phường 1');

        expect(result.length, 1);
      });
    });

    group('fetchHouseholdByPhone', () {
      test('returns household by phone', () async {
        await fakeFirestore.collection('households').doc('1').set({
          'id': 1,
          'household_code': 'HGD-0001',
          'house_number': '123',
          'street': 'Street',
          'head_of_household': 'Owner',
          'phone': '0909123456',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final result = await service.fetchHouseholdByPhone('0909123456');

        expect(result, isNotNull);
        expect(result!.headOfHousehold, 'Owner');
      });

      test('returns null for empty phone', () async {
        final result = await service.fetchHouseholdByPhone('');

        expect(result, isNull);
      });

      test('returns null when not found', () async {
        final result = await service.fetchHouseholdByPhone('0000000000');

        expect(result, isNull);
      });
    });

    group('generateHouseholdCode', () {
      test('generates first code when no households exist', () async {
        final code = await service.generateHouseholdCode();

        expect(code, 'HGD-0001');
      });

      test('generates incremented code', () async {
        await fakeFirestore.collection('households').doc('1').set({
          'id': 1,
          'household_code': 'HGD-0005',
          'house_number': '1',
          'street': 'Street',
          'head_of_household': 'Owner',
          'neighborhood': 'Khu phố 1',
          'created_at': '2024-01-01T00:00:00.000',
        });

        final code = await service.generateHouseholdCode();

        expect(code, 'HGD-0006');
      });
    });
  });
}
