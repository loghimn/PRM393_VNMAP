import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/high_school_model.dart';

void main() {
  group('HighSchool.fromJson', () {
    test('should parse full JSON data', () {
      final json = {
        'stt': 1,
        'ma_tinh_tp': '01',
        'ten_tinh_tp': 'Hà Nội',
        'ma_xa_phuong': '001',
        'ten_xa_phuong': 'Phường Tràng Tiền',
        'ma_truong': 'THPT01',
        'ten_truong': 'Trường THPT Trần Phú',
        'dia_chi': '123 Đường Lê Duẩn',
        'khu_vuc': 'Khu vực 1',
      };

      final model = HighSchool.fromJson(json);

      expect(model.stt, 1);
      expect(model.maTinhTp, '01');
      expect(model.tenTinhTp, 'Hà Nội');
      expect(model.maXaPhuong, '001');
      expect(model.tenXaPhuong, 'Phường Tràng Tiền');
      expect(model.maTruong, 'THPT01');
      expect(model.tenTruong, 'Trường THPT Trần Phú');
      expect(model.address, '123 Đường Lê Duẩn');
      expect(model.khuVuc, 'Khu vực 1');
    });

    test('should parse stt from int', () {
      final json = {'stt': 5};

      final model = HighSchool.fromJson(json);

      expect(model.stt, 5);
    });

    test('should parse stt from string', () {
      final json = {'stt': '10'};

      final model = HighSchool.fromJson(json);

      expect(model.stt, 10);
    });

    test('should parse stt from invalid string as null', () {
      final json = {'stt': 'abc'};

      final model = HighSchool.fromJson(json);

      expect(model.stt, isNull);
    });

    test('should handle null stt', () {
      final json = <String, dynamic>{};

      final model = HighSchool.fromJson(json);

      expect(model.stt, isNull);
    });

    test('should handle null optional fields', () {
      final json = <String, dynamic>{};

      final model = HighSchool.fromJson(json);

      expect(model.maTinhTp, isNull);
      expect(model.tenTinhTp, isNull);
      expect(model.maXaPhuong, isNull);
      expect(model.tenXaPhuong, isNull);
      expect(model.maTruong, isNull);
      expect(model.tenTruong, isNull);
      expect(model.address, isNull);
      expect(model.khuVuc, isNull);
    });
  });
}
