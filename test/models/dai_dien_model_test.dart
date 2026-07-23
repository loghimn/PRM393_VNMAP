import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/dai_dien_model.dart';

void main() {
  group('DaiDienModel.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'id': 1,
        'ho_ten': 'Nguyễn Văn A',
        'so_dien_thoai': '0909123456',
        'email': 'a@gmail.com',
        'dia_chi': '123 Đường Lê Lợi',
        'khu_pho_id': 5,
        'ten_khu_pho': 'Khu phố 3',
        'created_at': '2024-01-15T10:00:00.000',
        'updated_at': '2024-01-16T10:00:00.000',
      };

      final model = DaiDienModel.fromJson(json);

      expect(model.id, 1);
      expect(model.hoTen, 'Nguyễn Văn A');
      expect(model.soDienThoai, '0909123456');
      expect(model.email, 'a@gmail.com');
      expect(model.diaChi, '123 Đường Lê Lợi');
      expect(model.khuPhoId, 5);
      expect(model.tenKhuPho, 'Khu phố 3');
      expect(model.createdAt, DateTime(2024, 1, 15, 10, 0, 0));
      expect(model.updatedAt, DateTime(2024, 1, 16, 10, 0, 0));
    });

    test('should parse int id correctly', () {
      final json = {
        'id': 99,
        'ho_ten': 'Test',
        'created_at': '2024-01-15T10:00:00.000',
      };

      final model = DaiDienModel.fromJson(json);

      expect(model.id, 99);
    });

    test('should default hoTen to empty string when not provided', () {
      final json = <String, dynamic>{};

      final model = DaiDienModel.fromJson(json);

      expect(model.hoTen, '');
    });

    test('should handle null optional fields', () {
      final json = {'ho_ten': 'Test'};

      final model = DaiDienModel.fromJson(json);

      expect(model.id, isNull);
      expect(model.soDienThoai, isNull);
      expect(model.email, isNull);
      expect(model.diaChi, isNull);
      expect(model.khuPhoId, isNull);
      expect(model.tenKhuPho, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('should parse date from empty string as null', () {
      final json = {
        'ho_ten': 'Test',
        'created_at': 'invalid-date',
        'updated_at': 'invalid-date',
      };

      final model = DaiDienModel.fromJson(json);

      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });
  });

  group('DaiDienModel.toJson', () {
    test('should convert to JSON correctly', () {
      final model = DaiDienModel(
        id: 1,
        hoTen: 'Nguyễn Văn A',
        soDienThoai: '0909123456',
        email: 'a@gmail.com',
        diaChi: '123 Đường Lê Lợi',
        khuPhoId: 5,
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['ho_ten'], 'Nguyễn Văn A');
      expect(json['so_dien_thoai'], '0909123456');
      expect(json['email'], 'a@gmail.com');
      expect(json['dia_chi'], '123 Đường Lê Lợi');
      expect(json['khu_pho_id'], 5);
    });

    test('should not include null id', () {
      final model = DaiDienModel(hoTen: 'Test');

      final json = model.toJson();

      expect(json.containsKey('id'), isFalse);
    });

    test('should include null optional fields as null', () {
      final model = DaiDienModel(hoTen: 'Test');

      final json = model.toJson();

      expect(json['so_dien_thoai'], isNull);
      expect(json['email'], isNull);
      expect(json['dia_chi'], isNull);
      expect(json['khu_pho_id'], isNull);
    });

    test('should not include tenKhuPho, createdAt, updatedAt', () {
      final model = DaiDienModel(
        hoTen: 'Test',
        tenKhuPho: 'Khu phố 3',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
      );

      final json = model.toJson();

      expect(json.containsKey('ten_khu_pho'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });
  });
}
