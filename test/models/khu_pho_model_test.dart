import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/khu_pho_model.dart';

void main() {
  group('KhuPhoModel.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'id': 1,
        'ten_khu_pho': 'Khu phố 3',
        'mo_ta': 'Khu vực trung tâm',
        'dia_chi': '123 Đường Lê Lợi',
        'parent_ten': 'Phường Bến Thành',
        'created_at': '2024-01-15T10:00:00.000',
        'updated_at': '2024-01-16T10:00:00.000',
      };

      final model = KhuPhoModel.fromJson(json);

      expect(model.id, 1);
      expect(model.tenKhuPho, 'Khu phố 3');
      expect(model.moTa, 'Khu vực trung tâm');
      expect(model.diaChi, '123 Đường Lê Lợi');
      expect(model.parentTen, 'Phường Bến Thành');
      expect(model.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
      expect(model.updatedAt, DateTime(2024, 1, 16, 10, 0, 0));
    });

    test('should parse int id correctly', () {
      final json = {'id': 99, 'ten_khu_pho': 'Test'};

      final model = KhuPhoModel.fromJson(json);

      expect(model.id, 99);
    });

    test('should default tenKhuPho to empty string when not provided', () {
      final json = <String, dynamic>{};

      final model = KhuPhoModel.fromJson(json);

      expect(model.tenKhuPho, '');
    });

    test('should handle null optional fields', () {
      final json = {'ten_khu_pho': 'Test'};

      final model = KhuPhoModel.fromJson(json);

      expect(model.id, isNull);
      expect(model.moTa, isNull);
      expect(model.diaChi, isNull);
      expect(model.parentTen, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('should parse date from invalid string as null', () {
      final json = {
        'ten_khu_pho': 'Test',
        'created_at': 'invalid-date',
        'updated_at': 'invalid-date',
      };

      final model = KhuPhoModel.fromJson(json);

      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });
  });

  group('KhuPhoModel.toJson', () {
    test('should convert to JSON correctly', () {
      final model = KhuPhoModel(
        id: 1,
        tenKhuPho: 'Khu phố 3',
        moTa: 'Khu vực trung tâm',
        diaChi: '123 Đường Lê Lợi',
        parentTen: 'Phường Bến Thành',
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['ten_khu_pho'], 'Khu phố 3');
      expect(json['mo_ta'], 'Khu vực trung tâm');
      expect(json['dia_chi'], '123 Đường Lê Lợi');
      expect(json['parent_ten'], 'Phường Bến Thành');
    });

    test('should not include null id', () {
      final model = KhuPhoModel(tenKhuPho: 'Test');

      final json = model.toJson();

      expect(json.containsKey('id'), isFalse);
    });

    test('should include null optional fields as null', () {
      final model = KhuPhoModel(tenKhuPho: 'Test');

      final json = model.toJson();

      expect(json['mo_ta'], isNull);
      expect(json['dia_chi'], isNull);
      expect(json['parent_ten'], isNull);
    });

    test('should not include createdAt, updatedAt', () {
      final model = KhuPhoModel(
        tenKhuPho: 'Test',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
      );

      final json = model.toJson();

      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });
  });
}
