import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';

void main() {
  group('IncidentStatus', () {
    group('fromString', () {
      test('should parse "processing"', () {
        expect(
          IncidentStatus.fromString('processing'),
          IncidentStatus.processing,
        );
      });

      test('should parse "completed"', () {
        expect(
          IncidentStatus.fromString('completed'),
          IncidentStatus.completed,
        );
      });

      test('should parse "cancelled"', () {
        expect(
          IncidentStatus.fromString('cancelled'),
          IncidentStatus.cancelled,
        );
      });

      test('should default to received for unknown value', () {
        expect(IncidentStatus.fromString('unknown'), IncidentStatus.received);
      });

      test('should default to received for null', () {
        expect(IncidentStatus.fromString(null), IncidentStatus.received);
      });
    });

    group('displayName', () {
      test('should return "Received" for received', () {
        expect(IncidentStatus.received.displayName, 'Received');
      });

      test('should return "Processing" for processing', () {
        expect(IncidentStatus.processing.displayName, 'Processing');
      });

      test('should return "Completed" for completed', () {
        expect(IncidentStatus.completed.displayName, 'Completed');
      });

      test('should return "Cancelled" for cancelled', () {
        expect(IncidentStatus.cancelled.displayName, 'Cancelled');
      });
    });

    group('shortName', () {
      test('should return "New" for received', () {
        expect(IncidentStatus.received.shortName, 'New');
      });

      test('should return "Processing" for processing', () {
        expect(IncidentStatus.processing.shortName, 'Processing');
      });

      test('should return "Completed" for completed', () {
        expect(IncidentStatus.completed.shortName, 'Completed');
      });

      test('should return "Cancelled" for cancelled', () {
        expect(IncidentStatus.cancelled.shortName, 'Cancelled');
      });
    });

    group('dbValue', () {
      test('should return "received" for received', () {
        expect(IncidentStatus.received.dbValue, 'received');
      });

      test('should return "processing" for processing', () {
        expect(IncidentStatus.processing.dbValue, 'processing');
      });

      test('should return "completed" for completed', () {
        expect(IncidentStatus.completed.dbValue, 'completed');
      });

      test('should return "cancelled" for cancelled', () {
        expect(IncidentStatus.cancelled.dbValue, 'cancelled');
      });
    });
  });

  group('Incident.fromJson', () {
    test('should parse incident with full JSON data', () {
      final json = {
        'id': 1,
        'incident_code': 'SV-0001',
        'title': 'Sự cố 1',
        'description': 'Mô tả chi tiết',
        'address': '123 Nguyễn Huệ',
        'incident_address': 'Địa chỉ sự cố',
        'neighborhood': 'Khu phố 1',
        'ward': 'Phường Bến Nghé',
        'district': 'Quận 1',
        'city': 'Hồ Chí Minh',
        'longitude': 106.7,
        'latitude': 10.78,
        'household_id': 42,
        'head_of_household': 'Nguyễn Văn A',
        'phone': '0909123456',
        'status': 'completed',
        'handler': 'Admin',
        'notes': 'Ghi chú xử lý',
        'created_by': 1,
        'image_urls': ['img1.jpg', 'img2.jpg'],
        'created_at': '2024-01-15T10:00:00.000',
        'updated_at': '2024-01-16T10:00:00.000',
        'completed_date': '2024-01-17T10:00:00.000',
      };

      final incident = Incident.fromJson(json);

      expect(incident.id, 1);
      expect(incident.incidentCode, 'SV-0001');
      expect(incident.title, 'Sự cố 1');
      expect(incident.description, 'Mô tả chi tiết');
      expect(incident.address, '123 Nguyễn Huệ');
      expect(incident.incidentAddress, 'Địa chỉ sự cố');
      expect(incident.neighborhood, 'Khu phố 1');
      expect(incident.ward, 'Phường Bến Nghé');
      expect(incident.district, 'Quận 1');
      expect(incident.city, 'Hồ Chí Minh');
      expect(incident.longitude, 106.7);
      expect(incident.latitude, 10.78);
      expect(incident.householdId, 42);
      expect(incident.headOfHousehold, 'Nguyễn Văn A');
      expect(incident.phone, '0909123456');
      expect(incident.status, IncidentStatus.completed);
      expect(incident.handler, 'Admin');
      expect(incident.notes, 'Ghi chú xử lý');
      expect(incident.createdBy, 1);
      expect(incident.imageUrls, ['img1.jpg', 'img2.jpg']);
      expect(incident.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
      expect(incident.updatedAt, DateTime(2024, 1, 16, 10, 0, 0));
      expect(incident.completedDate, DateTime(2024, 1, 17, 10, 0, 0));
    });

    test('should handle id as string', () {
      final json = {'id': '99', 'incident_code': 'SV-0099', 'title': 'Test'};

      final incident = Incident.fromJson(json);

      expect(incident.id, 99);
    });

    test('should handle status as "processing"', () {
      final json = {
        'incident_code': 'SV-0002',
        'title': 'Test',
        'status': 'processing',
      };

      final incident = Incident.fromJson(json);

      expect(incident.status, IncidentStatus.processing);
    });

    test('should default to received status when not provided', () {
      final json = {'incident_code': 'SV-0003', 'title': 'Test'};

      final incident = Incident.fromJson(json);

      expect(incident.status, IncidentStatus.received);
    });

    test('should handle null long/lat', () {
      final json = {'incident_code': 'SV-0004', 'title': 'Test'};

      final incident = Incident.fromJson(json);

      expect(incident.longitude, isNull);
      expect(incident.latitude, isNull);
    });

    test('should handle empty image urls when field missing', () {
      final json = {'incident_code': 'SV-0005', 'title': 'Test'};

      final incident = Incident.fromJson(json);

      expect(incident.imageUrls, []);
    });
  });

  group('Incident.toDbMap', () {
    test('should convert to DB map correctly', () {
      final incident = Incident(
        id: 1,
        incidentCode: 'SV-0001',
        title: 'Sự cố 1',
        description: 'Mô tả',
        address: '123 Nguyễn Huệ',
        incidentAddress: 'Địa chỉ sự cố',
        neighborhood: 'Khu phố 1',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        city: 'Hồ Chí Minh',
        longitude: 106.7,
        latitude: 10.78,
        householdId: 42,
        headOfHousehold: 'Nguyễn Văn A',
        phone: '0909123456',
        status: IncidentStatus.completed,
        handler: 'Admin',
        notes: 'Ghi chú',
        createdBy: 1,
        imageUrls: ['img1.jpg'],
        completedDate: DateTime(2024, 1, 17),
      );

      final dbMap = incident.toDbMap();

      expect(dbMap['id'], 1);
      expect(dbMap['incident_code'], 'SV-0001');
      expect(dbMap['title'], 'Sự cố 1');
      expect(dbMap['description'], 'Mô tả');
      expect(dbMap['address'], '123 Nguyễn Huệ');
      expect(dbMap['incident_address'], 'Địa chỉ sự cố');
      expect(dbMap['neighborhood'], 'Khu phố 1');
      expect(dbMap['ward'], 'Phường Bến Nghé');
      expect(dbMap['district'], 'Quận 1');
      expect(dbMap['city'], 'Hồ Chí Minh');
      expect(dbMap['longitude'], 106.7);
      expect(dbMap['latitude'], 10.78);
      expect(dbMap['household_id'], 42);
      expect(dbMap['head_of_household'], 'Nguyễn Văn A');
      expect(dbMap['phone'], '0909123456');
      expect(dbMap['status'], 'completed');
      expect(dbMap['handler'], 'Admin');
      expect(dbMap['notes'], 'Ghi chú');
      expect(dbMap['created_by'], 1);
      expect(dbMap['image_urls'], ['img1.jpg']);
      expect(dbMap['completed_date'], '2024-01-17T00:00:00.000');
    });

    test('should not include id when null', () {
      final incident = Incident(incidentCode: 'SV-0002', title: 'Test');

      final dbMap = incident.toDbMap();

      expect(dbMap.containsKey('id'), isFalse);
    });

    test('should not include image_urls when empty', () {
      final incident = Incident(incidentCode: 'SV-0003', title: 'Test');

      final dbMap = incident.toDbMap();

      expect(dbMap.containsKey('image_urls'), isFalse);
    });

    test('should not include completed_date when null', () {
      final incident = Incident(incidentCode: 'SV-0004', title: 'Test');

      final dbMap = incident.toDbMap();

      expect(dbMap.containsKey('completed_date'), isFalse);
    });
  });

  group('Incident.fullAddress', () {
    test('should build address from components with NB prefix', () {
      final incident = Incident(
        incidentCode: 'SV-0001',
        title: 'Test',
        address: '123 Nguyễn Huệ',
        neighborhood: 'Khu phố 1',
        ward: 'Phường Bến Nghé',
        district: 'Quận 1',
        city: 'Hồ Chí Minh',
      );

      expect(
        incident.fullAddress,
        '123 Nguyễn Huệ, NB Khu phố 1, Phường Bến Nghé, Quận 1, Hồ Chí Minh',
      );
    });

    test('should handle missing parts', () {
      final incident = Incident(
        incidentCode: 'SV-0002',
        title: 'Test',
        ward: 'Phường 1',
        district: 'Quận 1',
      );

      expect(incident.fullAddress, 'Phường 1, Quận 1');
    });

    test('should return empty when no address data', () {
      final incident = Incident(incidentCode: 'SV-0003', title: 'Test');

      expect(incident.fullAddress, '');
    });
  });
}
