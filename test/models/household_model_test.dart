import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';

void main() {
  group('Household.fromJson', () {
    test('should parse household with full JSON data', () {
      final json = {
        'id': 1,
        'household_code': 'HGD-0001',
        'head_of_household': 'Nguyễn Văn A',
        'house_number': '123',
        'street': 'Nguyễn Huệ',
        'neighborhood': 'Khu phố 1',
        'ward': 'Phường Bến Nghé',
        'district': 'Quận 1',
        'city': 'Hồ Chí Minh',
        'phone': '0909123456',
        'email': 'a@gmail.com',
        'population': 4,
        'notes': 'Ghi chú',
        'longitude': 106.7,
        'latitude': 10.78,
        'created_by': 1,
        'created_at': '2024-01-15T10:00:00.000',
        'updated_at': '2024-01-16T10:00:00.000',
        'document_urls': ['url1', 'url2'],
      };

      final household = Household.fromJson(json);

      expect(household.id, 1);
      expect(household.householdCode, 'HGD-0001');
      expect(household.headOfHousehold, 'Nguyễn Văn A');
      expect(household.houseNumber, '123');
      expect(household.street, 'Nguyễn Huệ');
      expect(household.neighborhood, 'Khu phố 1');
      expect(household.ward, 'Phường Bến Nghé');
      expect(household.district, 'Quận 1');
      expect(household.city, 'Hồ Chí Minh');
      expect(household.phone, '0909123456');
      expect(household.email, 'a@gmail.com');
      expect(household.population, 4);
      expect(household.notes, 'Ghi chú');
      expect(household.longitude, 106.7);
      expect(household.latitude, 10.78);
      expect(household.createdBy, 1);
      expect(household.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
      expect(household.updatedAt, DateTime(2024, 1, 16, 10, 0, 0));
      expect(household.documentUrls, ['url1', 'url2']);
    });

    test('should handle id as string', () {
      final json = {
        'id': '42',
        'household_code': 'HGD-0042',
        'head_of_household': 'Nguyễn Văn B',
      };

      final household = Household.fromJson(json);

      expect(household.id, 42);
    });

    test('should handle null id', () {
      final json = {
        'household_code': 'HGD-0002',
        'head_of_household': 'Nguyễn Văn C',
      };

      final household = Household.fromJson(json);

      expect(household.id, isNull);
    });

    test('should handle empty strings for missing fields', () {
      final json = <String, dynamic>{};

      final household = Household.fromJson(json);

      expect(household.householdCode, '');
      expect(household.headOfHousehold, '');
      expect(household.documentUrls, []);
    });

    test('should handle population as string', () {
      final json = {
        'household_code': 'HGD-0003',
        'head_of_household': 'Test',
        'population': '5',
      };

      final household = Household.fromJson(json);

      expect(household.population, 5);
    });

    test('should handle longitude/latitude as string', () {
      final json = {
        'household_code': 'HGD-0004',
        'head_of_household': 'Test',
        'longitude': '106.5',
        'latitude': '10.5',
      };

      final household = Household.fromJson(json);

      expect(household.longitude, 106.5);
      expect(household.latitude, 10.5);
    });

    test('should handle non-list document_urls', () {
      final json = {
        'household_code': 'HGD-0005',
        'head_of_household': 'Test',
        'document_urls': 'not_a_list',
      };

      final household = Household.fromJson(json);

      expect(household.documentUrls, []);
    });
  });

  group('Household.fullAddress', () {
    test('should build full address from all parts', () {
      final household = Household(
        householdCode: 'HGD-0001',
        headOfHousehold: 'Test',
        houseNumber: '123',
        street: 'Nguyễn Huệ',
        neighborhood: 'Khu phố 1',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        city: 'Hồ Chí Minh',
      );

      expect(
        household.fullAddress,
        '123, Nguyễn Huệ, NB Khu phố 1, Phường Bến Nghé, Quận 1, Hồ Chí Minh',
      );
    });

    test('should handle missing parts', () {
      final household = Household(
        householdCode: 'HGD-0002',
        headOfHousehold: 'Test',
        ward: 'Phường 1',
        district: 'Quận 1',
      );

      expect(household.fullAddress, 'Phường 1, Quận 1');
    });

    test('should return empty string when all parts missing', () {
      final household = Household(
        householdCode: 'HGD-0003',
        headOfHousehold: 'Test',
      );

      expect(household.fullAddress, '');
    });

    test('should not include empty strings', () {
      final household = Household(
        householdCode: 'HGD-0004',
        headOfHousehold: 'Test',
        houseNumber: '10',
        street: '',
        ward: 'Phường 1',
      );

      expect(household.fullAddress, '10, Phường 1');
    });
  });

  group('Household.toJson', () {
    test('should convert to JSON correctly', () {
      final household = Household(
        id: 1,
        householdCode: 'HGD-0001',
        headOfHousehold: 'Nguyễn Văn A',
        houseNumber: '123',
        street: 'Nguyễn Huệ',
        population: 4,
        longitude: 106.7,
        latitude: 10.78,
        documentUrls: ['url1'],
      );

      final json = household.toJson();

      expect(json['id'], 1);
      expect(json['household_code'], 'HGD-0001');
      expect(json['head_of_household'], 'Nguyễn Văn A');
      expect(json['population'], 4);
      expect(json['longitude'], 106.7);
      expect(json['latitude'], 10.78);
      expect(json['document_urls'], ['url1']);
    });

    test('should not include null id', () {
      final household = Household(
        householdCode: 'HGD-0002',
        headOfHousehold: 'Test',
      );

      final json = household.toJson();

      expect(json.containsKey('id'), isFalse);
    });
  });

  group('Household.toDbMap', () {
    test('should convert to DB map correctly', () {
      final household = Household(
        id: 1,
        householdCode: 'HGD-0001',
        headOfHousehold: 'Nguyễn Văn A',
        city: 'Hồ Chí Minh',
      );

      final dbMap = household.toDbMap();

      expect(dbMap['id'], 1);
      expect(dbMap['household_code'], 'HGD-0001');
      expect(dbMap['head_of_household'], 'Nguyễn Văn A');
      expect(dbMap['city'], 'Hồ Chí Minh');
    });
  });
}
