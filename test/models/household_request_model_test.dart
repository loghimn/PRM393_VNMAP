import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/household_request_model.dart';

void main() {
  group('HouseholdRequest.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'id': 1,
        'user_id': 42,
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
        'status': 'approved',
        'admin_note': 'Đã duyệt',
        'created_at': '2024-01-15T10:00:00.000',
        'updated_at': '2024-01-16T10:00:00.000',
        'image_urls': ['url1.jpg', 'url2.jpg'],
      };

      final request = HouseholdRequest.fromJson(json);

      expect(request.id, 1);
      expect(request.userId, 42);
      expect(request.headOfHousehold, 'Nguyễn Văn A');
      expect(request.houseNumber, '123');
      expect(request.street, 'Nguyễn Huệ');
      expect(request.neighborhood, 'Khu phố 1');
      expect(request.ward, 'Phường Bến Nghé');
      expect(request.district, 'Quận 1');
      expect(request.city, 'Hồ Chí Minh');
      expect(request.phone, '0909123456');
      expect(request.email, 'a@gmail.com');
      expect(request.population, 4);
      expect(request.notes, 'Ghi chú');
      expect(request.status, 'approved');
      expect(request.adminNote, 'Đã duyệt');
      expect(request.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
      expect(request.updatedAt, DateTime(2024, 1, 16, 10, 0, 0));
      expect(request.imageUrls, ['url1.jpg', 'url2.jpg']);
    });

    test('should handle id as string', () {
      final json = {
        'id': '42',
        'user_id': 1,
        'head_of_household': 'Nguyễn Văn B',
        'phone': '0909123456',
      };

      final request = HouseholdRequest.fromJson(json);

      expect(request.id, 42);
    });

    test('should handle null id', () {
      final json = {
        'user_id': 1,
        'head_of_household': 'Nguyễn Văn C',
        'phone': '0909123456',
      };

      final request = HouseholdRequest.fromJson(json);

      expect(request.id, isNull);
    });

    test('should handle missing optional fields with defaults', () {
      final json = <String, dynamic>{
        'user_id': 1,
        'head_of_household': 'Nguyễn Văn D',
        'phone': '0909123456',
      };

      final request = HouseholdRequest.fromJson(json);

      expect(request.userId, 1);
      expect(request.headOfHousehold, 'Nguyễn Văn D');
      expect(request.phone, '0909123456');
      expect(request.status, 'pending');
      expect(request.imageUrls, []);
    });

    test('should handle population as string', () {
      final json = {
        'user_id': 1,
        'head_of_household': 'Test',
        'phone': '0909123456',
        'population': '5',
      };

      final request = HouseholdRequest.fromJson(json);

      expect(request.population, 5);
    });

    test('should handle user_id as string', () {
      final json = {
        'user_id': '10',
        'head_of_household': 'Test',
        'phone': '0909123456',
      };

      final request = HouseholdRequest.fromJson(json);

      expect(request.userId, 10);
    });
  });

  group('HouseholdRequest.toJson', () {
    test('should convert to JSON correctly', () {
      final request = HouseholdRequest(
        userId: 1,
        headOfHousehold: 'Nguyễn Văn A',
        phone: '0909123456',
        houseNumber: '123',
        city: 'Hồ Chí Minh',
        status: 'approved',
        imageUrls: ['url1.jpg'],
      );

      final json = request.toJson();

      expect(json['user_id'], 1);
      expect(json['head_of_household'], 'Nguyễn Văn A');
      expect(json['phone'], '0909123456');
      expect(json['house_number'], '123');
      expect(json['city'], 'Hồ Chí Minh');
      expect(json['status'], 'approved');
      expect(json['image_urls'], ['url1.jpg']);
    });

    test('should not include null id', () {
      final request = HouseholdRequest(
        userId: 1,
        headOfHousehold: 'Test',
        phone: '0909123456',
      );

      final json = request.toJson();

      expect(json.containsKey('id'), isFalse);
    });
  });

  group('HouseholdRequest.toDbMap', () {
    test('should convert to DB map correctly', () {
      final request = HouseholdRequest(
        userId: 1,
        headOfHousehold: 'Nguyễn Văn A',
        phone: '0909123456',
        city: 'Hồ Chí Minh',
      );

      final dbMap = request.toDbMap();

      expect(dbMap['user_id'], 1);
      expect(dbMap['head_of_household'], 'Nguyễn Văn A');
      expect(dbMap['phone'], '0909123456');
      expect(dbMap['city'], 'Hồ Chí Minh');
    });
  });

  group('HouseholdRequest.fullAddress', () {
    test('should build full address from all parts', () {
      final request = HouseholdRequest(
        userId: 1,
        headOfHousehold: 'Test',
        phone: '0909123456',
        houseNumber: '123',
        street: 'Nguyễn Huệ',
        neighborhood: 'Khu phố 1',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        city: 'Hồ Chí Minh',
      );

      expect(
        request.fullAddress,
        '123, Nguyễn Huệ, Khu phố 1, Phường Bến Nghé, Quận 1, Hồ Chí Minh',
      );
    });

    test('should handle missing parts', () {
      final request = HouseholdRequest(
        userId: 1,
        headOfHousehold: 'Test',
        phone: '0909123456',
        ward: 'Phường 1',
        district: 'Quận 1',
      );

      expect(request.fullAddress, 'Phường 1, Quận 1');
    });

    test('should return empty string when all parts missing', () {
      final request = HouseholdRequest(
        userId: 1,
        headOfHousehold: 'Test',
        phone: '0909123456',
      );

      expect(request.fullAddress, '');
    });

    test('should not include empty strings', () {
      final request = HouseholdRequest(
        userId: 1,
        headOfHousehold: 'Test',
        phone: '0909123456',
        houseNumber: '10',
        street: '',
        ward: 'Phường 1',
      );

      expect(request.fullAddress, '10, Phường 1');
    });
  });
}
